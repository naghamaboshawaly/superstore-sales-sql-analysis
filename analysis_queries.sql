USE MiniProject0;
-- SECTION 1: EXPLORATORY & AGGREGATION QUERIES
--Order ranked by profit

SELECT   ProductName, Profit
FROM     FactOrderDetails f
JOIN DimProduct p
ON f.ProductID=p.ProductID
ORDER BY Profit DESC;

--Total profit for a single product
SELECT   ProductID,
         SUM(profit) AS [sum of profit]
FROM     FactOrderDetails
WHERE    ProductID = 10000405
GROUP BY ProductID;

--Total profit by customer segment
SELECT   Segment,
         sum(profit) AS [Total Profit]
FROM     DimCustomer AS c
         INNER JOIN
         DimOrders AS o
         ON o.CustomerID = c.CustomerID
         INNER JOIN
         FactOrderDetails AS fo
         ON fo.OrderID = o.OrderID
GROUP BY Segment;

--Total profit by city
SELECT   city,
         sum(profit) AS [Sum of profit by city]
FROM     DimLocation AS loc
         INNER JOIN
         DimOrders AS do
         ON do.LocationID = loc.LocationID
         INNER JOIN
         FactOrderDetails AS fod
         ON fod.OrderID = do.OrderID
GROUP BY city
ORDER BY [Sum of profit by city] DESC;

--Total profit by product category
SELECT   Category,
         sum(profit) AS [Total Profit by category]
FROM     DimProduct AS p
         INNER JOIN
         FactOrderDetails AS fod
         ON fod.ProductID = p.ProductID
GROUP BY Category
ORDER BY [Total Profit by category] DESC;

--Products that have never been ordered
SELECT *
FROM   DimProduct AS p
       LEFT JOIN
       FactOrderDetails AS o
       ON p.ProductID = o.ProductID
WHERE  o.ProductID IS NULL;

--Total profit by customer
SELECT   c.CustomerName,
         sum(profit) AS [sum of profit by customer]
FROM     DimCustomer AS c
         INNER JOIN
         DimOrders AS o
         ON c.CustomerID = o.CustomerID
         INNER JOIN
         FactOrderDetails AS fo
         ON fo.OrderID = o.OrderID
GROUP BY c.Customername
ORDER BY [sum of profit by customer] DESC;

--Orders with average item quantity above 3
SELECT   OrderID,
         AVG(quantity) AS [average quantity]
FROM     FactOrderDetails
GROUP BY OrderID
HAVING   AVG(Quantity) > 3;

--	Maximum discount applied per order
SELECT   OrderID,
         Max(discount) AS [Maximum Discount]
FROM     FactOrderDetails
GROUP BY OrderID;

--Order lines with sales above the average
SELECT *
FROM   FactOrderDetails
WHERE  sales > (SELECT AVG(sales)
                FROM   FactOrderDetails);

--	Orders not yet shipped
SELECT *
FROM   DimOrders
WHERE  ShipDate IS NULL;

-- Orders shipped via Standard Class
SELECT *
FROM   DimOrders
WHERE  ShipMode = 'Standard Class';

--	Average profit by ship mode
SELECT   ShipMode,
         Avg(profit) AS [Average profit for each shipMode]
FROM     DimOrders AS o
         INNER JOIN
         FactOrderDetails AS f
         ON o.OrderID = f.OrderID
GROUP BY ShipMode;

--Product purchase frequency--
SELECT   ProductID,
         count(orderid) AS [ The number of times a product was bought]
FROM     FactOrderDetails
GROUP BY ProductID
ORDER BY count(orderid);

--Delivered orders by region--
SELECT   Region,
         count(locationid) AS [The number of successful deliveries per region]
FROM     DimLocation
GROUP BY Region
ORDER BY count(locationid) DESC;


GO
-- SECTION 2: VIEW
CREATE VIEW AllOrders
AS
SELECT o.*,
       p.productname
FROM   FactOrderDetails AS o
       INNER JOIN
       DimProduct AS p
       ON o.ProductID = p.ProductID;


GO
-- SECTION 3: CTEs
WITH   Top_ten_orders
AS     (SELECT   TOP (10) *
        FROM     FactOrderDetails
        ORDER BY Profit DESC)
SELECT *
FROM   Top_ten_orders;


GO
--CTE
WITH   summary_table
AS     (SELECT c.CustomerName,
               c.Segment,
               o.ShipMode,
               fo.Sales,
               fo.Quantity,
               fo.Profit
        FROM   DimCustomer AS c
               INNER JOIN
               DimOrders AS o
               ON o.CustomerID = c.CustomerID
               INNER JOIN
               FactOrderDetails AS fo
               ON fo.OrderID = o.OrderID)
SELECT *
FROM   summary_table;


GO
-- SECTION 4: STORED PROCEDURE
CREATE PROCEDURE Order_delayed
AS
BEGIN
    SELECT o.*,
           f.Profit,
           f.Quantity,
           f.Sales,
           p.ProductName,
           p.Category
    FROM   DimOrders AS o
           INNER JOIN
           FactOrderDetails AS f
           ON o.OrderID = f.OrderID
           INNER JOIN
           DimProduct AS p
           ON f.ProductID = p.ProductID
    WHERE  ShipDate IS NULL;
END
EXECUTE Order_delayed ;

--Profit Margin--

SELECT   ProductName,
         SUM(profit) AS [Total Profit],
         SUM(sales) AS [Total Sales],
         SUM(profit)/SUM(sales)*100 AS [Profit Margin]

FROM     FactOrderDetails f
JOIN DimProduct p
ON f.ProductID=p.ProductID
GROUP BY ProductName;

