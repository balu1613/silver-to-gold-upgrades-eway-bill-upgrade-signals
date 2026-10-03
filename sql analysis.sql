select * from monthly_usage limit 20;

SELECT
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN is_upgrader THEN 1 ELSE 0 END) AS upgraders,
    ROUND(100.0 * SUM(CASE WHEN is_upgrader THEN 1 ELSE 0 END) / COUNT(*), 1) AS conversion_pct
FROM accounts;

ALTER TABLE accounts
    ADD PRIMARY KEY (account_id);

ALTER TABLE monthly_usage
    ADD PRIMARY KEY (account_id, month);

ALTER TABLE monthly_usage
    ADD CONSTRAINT fk_usage_account
    FOREIGN KEY (account_id) REFERENCES accounts (account_id);


SELECT
    a.is_upgrader,
    ROUND(AVG(m.pct_of_eway_cap)::numeric, 2) AS avg_pct_of_cap
FROM monthly_usage m
JOIN accounts a ON a.account_id = m.account_id
WHERE a.upgrade_date IS NULL OR m.month < a.upgrade_date
GROUP BY a.is_upgrader

-- unique values in each column
select distinct vertical from accounts;
select distinct city_tier from accounts;

-- range of firms_count
select min(firms_count) as min_firm,
       max(firms_count) as max_firm
from accounts;
---we have 6 months of data--
select min(month) as mm, max(month) as mn
from monthly_usage;

select count(distinct(month)) from monthly_usage;
--
select
	a.signup_date - a.upgrade_date as timetaken,
	sum(mu.eway_bills_used) as usedbills
	from monthly_usage mu
join accounts a 
on mu.account_id = a.account_id
where a.plan_tier = "Gold"
group by a.account_id;


select
    a.account_id,
    a.upgrade_date::date - a.signup_date::date as timetaken,
    sum(mu.eway_bills_used) as usedbills
from monthly_usage mu
join accounts a
  on mu.account_id = a.account_id
where a.plan_tier = 'Gold'
group by a.account_id, a.signup_date, a.upgrade_date;


---------------------------------
--days took for each vertical to upgrade from silver to gold
select 
	vertical,
	avg(upgrade_time)
from(
select 
	account_id,
	vertical,
	city_tier,
	upgrade_date::date - signup_date::date as upgrade_time
from accounts
where plan_tier= 'Gold'
)
group by vertical
order by avg(upgrade_time) desc;
---on average for all vertices it took 470 days to get upgrade tier--
select 
	avg(upgrade_date::date - signup_date::date) as avg_upgrade_time
from accounts;
---what are the patterns we notice in the gold tier upgrade accounts
select 
	a.vertical,
	extract(month from mu.month) as monthh,
	sum(mu.eway_bills_used) as bills_used,
	sum(a.support_tickets_last_6mo) as tickets_raised
from monthly_usage mu
join accounts a 
ON  mu.account_id = a.account_id
where a.plan_tier = 'Gold'
group by extract(month from mu.month),a.vertical;

select
    to_char(mu.month, 'FMMonth')          as month_name,
    count(distinct a.account_id)          as accounts_in_month,
    round(avg(mu.eway_bills_used))    as avg_bills,
	avg(a.days_to_upgrade) as days_taken
from monthly_usage mu
join accounts a
  on mu.account_id = a.account_id
where a.is_upgrader = true
  and mu.month < date_trunc('month', a.upgrade_date)
group by  mu.month, to_char(mu.month, 'FMMonth')
order by  mu.month;

select
    a.vertical,
    (extract(year from date_trunc('month', a.upgrade_date)) * 12
       + extract(month from date_trunc('month', a.upgrade_date)))
    - (extract(year from mu.month) * 12 + extract(month from mu.month))
                                              as months_before_upgrade,
    count(distinct a.account_id)              as accounts,
    round(avg(mu.eway_bills_used::int), 1)         as avg_bills
from monthly_usage mu
join accounts a on mu.account_id = a.account_id
where a.is_upgrader = true
  and mu.month < date_trunc('month', a.upgrade_date)
group by a.vertical, months_before_upgrade
order by a.vertical, months_before_upgrade desc;
----------------------------------------------------------------------------------------------
--there are total 500 accounts--
select count(distinct(account_id)) from accounts;
--we have 78 gold tier accounts
select count(distinct(account_id)) from accounts where plan_tier
= 'Gold';
--we have 422 silver accounts
select count(distinct(account_id)) from accounts where plan_tier = 'Silver';

select min(days_to_upgrade), max(days_to_upgrade)
from accounts
where is_upgrader = true;

SELECT 
	count(distinct a.account_id)    as accounts,
	AVG(mu.eway_bills_used) as avg_bills,
	CASE
    WHEN a.days_to_upgrade < 30  THEN '1 month'
    WHEN a.days_to_upgrade < 60  THEN '2 months'
    WHEN a.days_to_upgrade < 90  THEN '3 months'
    WHEN a.days_to_upgrade < 120 THEN '4 months'
    WHEN a.days_to_upgrade < 150 THEN '5 months'
    ELSE '6+ months'
END AS timetaken		
FROM monthly_usage mu
JOIN accounts a ON mu.account_id = a.account_id
WHERE  a.is_upgrader = true
AND mu.month < date_trunc('month', a.upgrade_date)
GROUP BY timetaken
ORDER BY avg_bills DESC;

--when account reach 40% cap and sits there couple of months and when it reaches 60-70% thats the sign to 
--target the account and when the account cap reaches 90% it almost too late
SELECT
    (EXTRACT(YEAR FROM a.upgrade_date) - EXTRACT(YEAR FROM mu.month)) * 12
    + (EXTRACT(MONTH FROM a.upgrade_date) - EXTRACT(MONTH FROM mu.month)) AS months_before_upgrade,
    COUNT(DISTINCT a.account_id) AS accounts,
    ROUND(AVG(mu.eway_bills_used)::numeric, 2) AS avg_eway_bills,
    ROUND(AVG(mu.pct_of_eway_cap)::numeric, 2) AS avg_pct_of_cap
FROM monthly_usage mu
JOIN accounts a ON mu.account_id = a.account_id
WHERE a.is_upgrader = true
  AND mu.month < date_trunc('month', a.upgrade_date)
GROUP BY months_before_upgrade
ORDER BY months_before_upgrade DESC;

---which type of vertical and tier do the upgrades happen most to focus on marketing
--focus on vertices groceries and pharmacy in the city tier 2 and 3
SELECT
	a.vertical,
	a.city_tier,
	COUNT(DISTINCT a.account_id) AS accounts,
	ROUND(AVG(mu.pct_of_eway_cap)::numeric, 2) AS avg_pct_of_cap
FROM monthly_usage mu
JOIN accounts a 
ON mu.account_id = a.account_id
WHERE a.is_upgrader = 'True'
Group by a.vertical, a.city_tier
ORDER BY a.vertical asc ,avg_pct_of_cap ;

SELECT
	a.city_tier,
	COUNT(DISTINCT a.account_id) AS accounts,
	ROUND(AVG(mu.pct_of_eway_cap)::numeric, 2) AS avg_pct_of_cap
FROM monthly_usage mu
JOIN accounts a 
ON mu.account_id = a.account_id
WHERE a.is_upgrader = 'True'
Group by a.city_tier
ORDER BY avg_pct_of_cap ;

SELECT
	a.vertical,
	COUNT(DISTINCT a.account_id) AS accounts,
	ROUND(AVG(mu.pct_of_eway_cap)::numeric, 2) AS avg_pct_of_cap
FROM monthly_usage mu
JOIN accounts a 
ON mu.account_id = a.account_id
WHERE a.is_upgrader = 'True'
Group by a.vertical
ORDER BY accounts desc;

SELECT
    city_tier,
    COUNT(*)                                   AS accounts,
    COUNT(*) FILTER (WHERE is_upgrader)        AS upgraders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_upgrader) / COUNT(*), 1) AS conv_rate_pct
FROM accounts
GROUP BY city_tier
ORDER BY conv_rate_pct DESC;

--: Which current Silver accounts look closest to upgrading, and are worth a call now?
SELECT 
	a.vertical,
	COUNT(DISTINCT a.account_id) AS accounts
FROM monthly_usage mu
JOIN accounts a 
ON mu.account_id = a.account_id
WHERE (
	SELECT
		ROUND(AVG(pct_of_eway_cap)::numeric, 2) 
		FROM monthly_usage) > 0.6 
GROUP BY a.vertical;


WITH latest AS (
    -- Step 1: anchor "now" to the data, not the calendar
    SELECT MAX(month) AS latest_month
    FROM monthly_usage
),

recent AS (
    -- Step 2: summarise each Silver account's last 3 months
    SELECT
        a.account_id,
        a.vertical,
        a.city_tier,
        ROUND(AVG(mu.pct_of_eway_cap)::numeric, 2) AS avg_pct_3mo,
        MAX(mu.pct_of_eway_cap)
            FILTER (WHERE mu.month = l.latest_month)  AS latest_pct,
        COUNT(*)
            FILTER (WHERE mu.pct_of_eway_cap >= 0.6)  AS months_at_60_plus
    FROM accounts a
    JOIN monthly_usage mu ON a.account_id = mu.account_id
    CROSS JOIN latest l
    WHERE a.plan_tier = 'Silver'
      AND mu.month >= l.latest_month - INTERVAL '2 months'
    GROUP BY a.account_id, a.vertical, a.city_tier, l.latest_month
)

-- Step 3: apply the rule and label each lead
SELECT
    account_id,
    vertical,
    city_tier,
    avg_pct_3mo,
    latest_pct,
    months_at_60_plus,
    CASE
        WHEN latest_pct >= 0.9 THEN 'Call now: at the cap'
        ELSE 'Warming up: nudge'
    END AS lead_bucket
FROM recent
WHERE months_at_60_plus >= 2
ORDER BY latest_pct DESC, avg_pct_3mo DESC;
