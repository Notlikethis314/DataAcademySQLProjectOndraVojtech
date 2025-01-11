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