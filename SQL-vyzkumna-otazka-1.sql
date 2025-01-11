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
   
-- 1. Výzkumná otázka:
-- Nejprve jsem si vypočítal percentuální nárůst/pokles mzdy z předešlého roku
-- ze kterého jsem následně vypočetl průměr. Ten můžeme použít jako indikátor,
-- zdali mzda pro dané dovětví napříč sledovanému období klesá nebo roste.
-- Z výsledku jde vidět, že pro každé odvětví mzda v průměru roste.