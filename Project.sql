-- czechia payroll - Main table
SELECT
	*
FROM czechia_payroll cp ;

SELECT 
*
FROM czechia_payroll_calculation cpc ;

SELECT 
*
FROM czechia_payroll_industry_branch cpib ;

SELECT 
*
FROM czechia_payroll_unit cpu ;

SELECT 
*
FROM czechia_payroll_value_type cpvt ;

SELECT
	cpib."name" AS industry,
	avg(cp.value) AS avg_payroll_per_year,
	cp.payroll_year AS payroll_year 
FROM czechia_payroll cp 
JOIN czechia_payroll_industry_branch cpib ON (cp.industry_branch_code = cpib.code)
WHERE cp.value_type_code = 5958 AND cp.calculation_code = 200
GROUP BY cpib."name", cp.payroll_year 
ORDER BY avg_payroll_per_year DESC;
-- Insights:
-- value_type_code = 5958 -> jedna se o průměrnou mzdu
-- calculation_code = 200 -> Údaje o počtu zaměstnanců a průměrných mzdách jsou publikovány za celou populaci 
-- podniků se zvýšeným důrazem na průměrné mzdy zaměstnanců přepočtené na plně zaměstnané, které zohledňují délku pracovního úvazku.
-- price

SELECT 
	cpc."name" ,
	cp.category_code,
	avg(cp.value) AS avg_price,
	date_part('year', date_from) AS year_from
	--date_part('year', date_to) AS year_to
FROM czechia_price cp 
JOIN czechia_price_category cpc ON (cp.category_code=cpc.code)
WHERE cp.category_code =112704 AND cp.region_code IS NULL
GROUP BY cp.category_code , date_part('year', date_from), cpc.name
ORDER BY year_from;

-------------------
-- TABLE 1 CREATION
(SELECT
	cpib."name" AS name,
	cp.industry_branch_code AS code,
	avg(cp.value) AS avg_value,
	cp.payroll_year AS "year",
	'payroll' AS table_flag
FROM
	czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib ON
	(cp.industry_branch_code = cpib.code)
WHERE
	cp.value_type_code = 5958
	AND cp.calculation_code = 200
	AND cp.payroll_year IN (
	SELECT
		DISTINCT date_part('year',
		date_from) AS year_from
	FROM
		czechia_price cp2)
GROUP BY
	cpib."name",
	cp.payroll_year ,
	cp.industry_branch_code
ORDER BY
	cp.payroll_year )	
UNION ALL
(SELECT 
	cpc."name" AS name,
	cp.category_code AS code,
	avg(cp.value) AS avg_value,
	date_part('year', date_from) AS "year",
	'goods_price' AS table_flag
FROM czechia_price cp 
JOIN czechia_price_category cpc ON (cp.category_code=cpc.code)
WHERE cp.category_code =112704 AND cp.region_code IS NULL
GROUP BY cp.category_code , "year", cpc.name
ORDER BY "year");

CREATE TEMP TABLE t_vojtech_ondra_project_sql_primary_final AS (
SELECT
	cpib."name" AS name,
	cp.industry_branch_code AS code,
	avg(cp.value) AS avg_value,
	cp.payroll_year AS "year",
	'payroll' AS table_flag
FROM
	czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib ON
	(cp.industry_branch_code = cpib.code)
WHERE
	cp.value_type_code = 5958
	AND cp.calculation_code = 200
	AND cp.payroll_year IN (
	SELECT
		DISTINCT date_part('year',
		date_from)
	FROM
		czechia_price cp2
     )
GROUP BY
	cpib."name",
	cp.payroll_year,
	cp.industry_branch_code
UNION ALL
 SELECT
	cpc."name" AS name,
	cp.category_code::TEXT AS code,
	avg(cp.value) AS avg_value,
	date_part('year',
	date_from) AS "year",
	'goods_price' AS table_flag
FROM
	czechia_price cp
JOIN czechia_price_category cpc ON
	(cp.category_code = cpc.code)
WHERE
	cp.region_code IS NULL
GROUP BY
	cp.category_code,
	"year",
	cpc.name
ORDER BY
	table_flag,
	"year");
---------------------------------------------------------
-- Vyzkumna otazka 1

SELECT 
	name,
	avg(percent_diff) AS avg_percent_diff
FROM (SELECT
	    name,
	    code,
	    "year",
	    table_flag,
	    avg_value,
	    LAG(avg_value) OVER (PARTITION BY code ORDER BY "year") AS prev_value,
	    CASE
	        WHEN LAG(avg_value) OVER (PARTITION BY code ORDER BY "year") IS NOT NULL THEN
	            (avg_value - LAG(avg_value) OVER (PARTITION BY code ORDER BY "year")) 
	            / LAG(avg_value) OVER (PARTITION BY code ORDER BY "year")*100
	        ELSE
	            NULL
	    END AS percent_diff
	FROM
	    t_vojtech_ondra_project_sql_primary_final
	WHERE table_flag = 'payroll'
	ORDER BY
	    code, "year")
GROUP BY name;

----------------------------------------------------------------------------------------------
-- Vyzkumna otazka 2

SELECT 
	payroll.name,
	payroll."year",
	goods.name,
	floor(payroll.avg_value / goods.avg_value) AS number_of_goods
FROM
	t_vojtech_ondra_project_sql_primary_final payroll
JOIN t_vojtech_ondra_project_sql_primary_final goods ON 
	(
		payroll."year" = goods."year"
		AND goods.code IN(
			'111301', '114201'
		)
		AND goods.table_flag = 'goods_price'
	)
WHERE
	payroll."year" IN (
		2006, 2018
	)
	AND payroll.table_flag = 'payroll';

------------------------------------------------------------------------
-- Výzkumná otázka 3
-- 3.Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
SELECT 
	name,
	avg(percent_diff) AS avg_percent_diff
FROM (SELECT
	    name,
	    code,
	    "year",
	    table_flag,
	    avg_value,
	    LAG(avg_value) OVER (PARTITION BY code ORDER BY "year") AS prev_value,
	    CASE
	        WHEN LAG(avg_value) OVER (PARTITION BY code ORDER BY "year") IS NOT NULL THEN
	            (avg_value - LAG(avg_value) OVER (PARTITION BY code ORDER BY "year")) 
	            / LAG(avg_value) OVER (PARTITION BY code ORDER BY "year")*100
	        ELSE
	            NULL
	    END AS percent_diff
	FROM
	    t_vojtech_ondra_project_sql_primary_final
	WHERE table_flag = 'goods_price'
	ORDER BY
	    code, "year")
GROUP BY name;

-------------------------------------------------------------------------------------------
-- 4. výzkumná otázka
-- 4.Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
CREATE TEMP TABLE yearly_perc_changes AS (
SELECT
    name,
    code,
    "year",
    table_flag,
    avg_value,
    LAG(avg_value) OVER (PARTITION BY code ORDER BY "year") AS prev_value,
    CASE
        WHEN LAG(avg_value) OVER (PARTITION BY code ORDER BY "year") IS NOT NULL THEN
            (avg_value - LAG(avg_value) OVER (PARTITION BY code ORDER BY "year")) 
            / LAG(avg_value) OVER (PARTITION BY code ORDER BY "year")*100
        ELSE
            NULL
    END AS percent_diff
FROM
    t_vojtech_ondra_project_sql_primary_final
ORDER BY
	code, "year"
);


SELECT 
	ypc_payroll."year",
	round(avg(ypc_payroll.percent_diff)::NUMERIC, 2) AS avg_perc_diff_payroll,
	round(avg(ypc_goods.percent_diff)::NUMERIC, 2) AS avg_perc_diff_goods,
	round((avg(ypc_goods.percent_diff) - avg(ypc_payroll.percent_diff))::NUMERIC, 2) AS difference_goods_payroll
FROM
	yearly_perc_changes ypc_payroll
JOIN yearly_perc_changes ypc_goods ON
	(
		ypc_goods."year" = ypc_payroll."year"
			AND ypc_goods.table_flag = 'goods_price'
	)
WHERE
	ypc_payroll.table_flag = 'payroll'
GROUP BY
	ypc_payroll."year"
ORDER BY
	ypc_payroll."year"
;

