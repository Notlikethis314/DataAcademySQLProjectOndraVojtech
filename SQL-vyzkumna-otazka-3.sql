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

-- 3. výzkumná otázka
-- uplně stejný SQL dotaz jako u 1. výzkumné otázky, ale pouze změněna 'table_flag' na 'goods_price'