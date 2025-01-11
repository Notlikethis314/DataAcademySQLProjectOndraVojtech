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
	
-- 2. Výzkumná otázka:
-- Díky vytvořenému sloupci 'table_flag' jsem schopen rozlišit,
-- jestli se jedná o data o mzdách nebo o potravinách. To využiji
-- k propojení dat ze stejné tabluky. 
-- K tabulce mezd za první a poslední sledované období jsem propojil
-- obdobná data pro Mléko a Chleba a pak vypočítal, kolik je možno 
-- koupit potraviny za celou průměrnou mzdu.