-- zadanie 8 A)
SELECT OrderDate, COUNT(OrderDate) as Order_cnt FROM AdventureWorksDW2019.dbo.FactInternetSales GROUP BY OrderDate HAVING COUNT(OrderDate) < 100  Order by Order_cnt DESC;

-- zadanie 8 B)
SELECT * FROM ( 
	SELECT 
		OrderDate, 
		ProductKey, 
		UnitPrice, 
		ROW_NUMBER() OVER ( PARTITION BY OrderDate ORDER by UnitPrice DESC) pozycja 
		FROM AdventureWorksDW2019.dbo.FactInternetSales
) as res WHERE pozycja <=3;