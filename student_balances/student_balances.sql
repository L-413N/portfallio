WITH 
first_payments AS (
    SELECT
        user_id,
        MIN(transaction_datetime::date)::date AS first_payment_date
    FROM skyeng_db.payments AS s
    WHERE status_name = 'success'
    GROUP BY s.user_id
    ), 
all_dates AS (
    SELECT DISTINCT(class_start_datetime::date) AS dt
    FROM skyeng_db.classes
    WHERE DATE_TRUNC('year', class_start_datetime::date) = '2016-01-01'
    ),
all_dates_by_user AS(
    SELECT 
        user_id, 
        dt 
    FROM all_dates AS ad
    LEFT JOIN first_payments AS fp
        ON ad.dt >= fp.first_payment_date
    ),
payments_by_dates AS (
    SELECT 
        user_id, 
        transaction_datetime::date AS payment_date,
        SUM(classes) AS transaction_balance_change
    FROM skyeng_db.payments
    WHERE status_name = 'success'
    GROUP BY user_id, payment_date
    ),
payments_by_dates_cumsum AS (
    SELECT 
        adbu.user_id,
        adbu.dt,
        transaction_balance_change,
        SUM(pbd.transaction_balance_change) OVER (PARTITION BY adbu.user_id ORDER BY adbu.dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS transaction_balance_change_cs 
    FROM all_dates_by_user AS adbu
    LEFT JOIN payments_by_dates AS pbd
        ON adbu.user_id = pbd.user_id
        AND adbu.dt = pbd.payment_date
    ),
classes_by_dates AS (
    SELECT
        user_id,
        class_start_datetime::date AS class_date,
        COUNT(*) * -1 AS classes
    FROM skyeng_db.classes AS c
    WHERE
        class_type = 'regular'
        AND class_status IN ('success', 'failed_by_student')
    GROUP BY user_id, class_date
    ),
classes_by_dates_dates_cumsum AS (
    SELECT
        adbu.user_id,
        dt,
        classes,
        SUM(classes) OVER (PARTITION BY adbu.user_id ORDER BY dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS classes_cs
    FROM all_dates_by_user AS adbu
    LEFT JOIN classes_by_dates AS cbd
        ON cbd.user_id = adbu.user_id
        AND cbd.class_date = adbu.dt
    ),
balances AS (
    SELECT
        pbdc.user_id,
        pbdc.dt,
        pbdc.transaction_balance_change,
        pbdc.transaction_balance_change_cs,
        cbddc.classes,
        cbddc.classes_cs,
        pbdc.transaction_balance_change_cs + cbddc.classes_cs AS balance
    FROM payments_by_dates_cumsum AS pbdc
    JOIN classes_by_dates_dates_cumsum AS cbddc
        ON pbdc.user_id = cbddc.user_id
        AND pbdc.dt = cbddc.dt
    )
-- TOP 1000 TASK --

-- SELECT *
-- FROM balances
-- ORDER BY user_id, dt
-- LIMIT 1000
SELECT
    dt,
    SUM(transaction_balance_change) AS transaction_balance_change_sum,
    SUM(transaction_balance_change_cs) AS transaction_balance_change_cs_sum,
    SUM(classes) AS classes_sum,
    SUM(classes_cs) AS classes_cs_sum,
    SUM(balance) AS balance_sum
FROM balances
GROUP BY dt
