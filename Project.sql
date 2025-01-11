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
GROUP BY name
   ;

SELECT 
	t1.name,
	t1."year",
	t1.avg_value
FROM t_vojtech_ondra_project_sql_primary_final t1
JOIN t_vojtech_ondra_project_sql_primary_final t2 ON (t1."year"=t2."year" AND t2.name IN(111301, 114201))
WHERE "year" IN (2006, 2018) AND table_flag = 'payroll';

SELECT 
	t1.name,
	t1.code,
	t1."year",
	t1.avg_value
FROM t_vojtech_ondra_project_sql_primary_final t1
