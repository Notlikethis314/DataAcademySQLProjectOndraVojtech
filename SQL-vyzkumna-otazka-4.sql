WITH percent_diff_calculation AS (
    SELECT
        name,
        code,
        "year",
        table_flag,
        avg_value,
        lag(avg_value) OVER (PARTITION BY code ORDER BY "year") AS prev_value,
        CASE
            WHEN lag(avg_value) OVER (PARTITION BY code ORDER BY "year") IS NOT NULL THEN
                (avg_value - lag(avg_value) OVER (PARTITION BY code ORDER BY "year"))
                / lag(avg_value) OVER (PARTITION BY code ORDER BY "year") * 100
            ELSE
                NULL
        END AS percent_diff
    FROM t_vojtech_ondra_project_sql_primary_final
)
SELECT 
    ypc_payroll."year",
    round(avg(ypc_payroll.percent_diff)::NUMERIC, 2) AS avg_perc_diff_payroll,
    round(avg(ypc_goods.percent_diff)::NUMERIC, 2) AS avg_perc_diff_goods,
    round((avg(ypc_goods.percent_diff) - avg(ypc_payroll.percent_diff))::NUMERIC, 2) AS difference_goods_payroll
FROM
    percent_diff_calculation ypc_payroll
JOIN percent_diff_calculation ypc_goods 
    ON
(
	ypc_goods."year" = ypc_payroll."year"
		AND ypc_goods.table_flag = 'goods_price'
)
WHERE
    ypc_payroll.table_flag = 'payroll'
GROUP BY
    ypc_payroll."year"
ORDER BY
    ypc_payroll."year";
    
-- 4. výzkumná otázka
-- První jsem použil odbdobný SQL dotaz jako pro 1. a 3. výzkumnou otázku, avšak
-- s kalkulací jak pro mzdy tak pro potraviny a poté jsem vypočítal průměrnou roční
-- percentuální změnu pro potraviny a mzdy. Pak jsem průměry od sebe odečetl.
   