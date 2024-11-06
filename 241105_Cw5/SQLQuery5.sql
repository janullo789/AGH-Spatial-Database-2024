SELECT OrderDate, COUNT(*) AS Orders_cnt
FROM [AdventureWorksDW2022].[dbo].[FactInternetSales]
GROUP BY OrderDate
HAVING COUNT(*) < 100
ORDER BY Orders_cnt DESC;


SELECT OrderDate, ProductKey, UnitPrice
FROM (
    SELECT OrderDate, ProductKey, UnitPrice,
           ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC) AS Rank
    FROM [AdventureWorksDW2022].[dbo].[FactInternetSales]
) AS RankedProducts
WHERE Rank <= 3
ORDER BY OrderDate, UnitPrice DESC;
