/* =====================================================================
   Superstore_Clean.csv  ->  SQL Server Star Schema
   9,993 rows | 5,009 orders | 793 customers | 632 locations | 1,850 products
   The source file is already clean, so there is no cleaning step here.
   ===================================================================== */
Create Database MiniProject0
Go

Use MiniProject0
Go

/* ---------------------------------------------------------------------
   STEP 1 : Staging table (mirror of the CSV, everything as text)
   --------------------------------------------------------------------- */
CREATE TABLE Staging_Superstore (
    OrderID         VARCHAR(20),
    OrderDate       VARCHAR(20),
    ShipDate        VARCHAR(20),
    ShipMode        VARCHAR(50),
    CustomerID      VARCHAR(20),
    CustomerName    VARCHAR(100),
    Segment         VARCHAR(50),
    CountryRegion   VARCHAR(50),
    City            VARCHAR(50),
    State           VARCHAR(50),
    PostalCode      VARCHAR(10),
    Region          VARCHAR(20),
    ProductID       VARCHAR(20),
    Category        VARCHAR(50),
    SubCategory     VARCHAR(50),
    ProductName     VARCHAR(255),
    Sales           VARCHAR(30),
    Quantity        VARCHAR(20),
    Discount        VARCHAR(20),
    Profit          VARCHAR(30)
);
GO


/* ---------------------------------------------------------------------
   STEP 2 : Load the CSV
   FORMAT = 'CSV' is required: product names contain commas inside quotes.
   On SQL Server 2016 or older: right-click DB > Tasks > Import Flat File
   --------------------------------------------------------------------- */
BULK INSERT Staging_Superstore
FROM 'D:\SQL Mini Project\MiniProject SQL Data.csv'
WITH (
    FORMAT   = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);
GO

-- must return 9993
SELECT COUNT(*) AS RowsLoaded FROM Staging_Superstore;
GO


/* ---------------------------------------------------------------------
   STEP 3 : Create the tables
   --------------------------------------------------------------------- */

CREATE TABLE DimCustomer (
    CustomerID      INT           PRIMARY KEY,
    CustomerName    VARCHAR(100)  NOT NULL,
    Segment         VARCHAR(50)   NOT NULL
);
Go

CREATE TABLE DimProduct (
    ProductID       INT           PRIMARY KEY,
    Category        VARCHAR(50)   NOT NULL,
    SubCategory     VARCHAR(50)   NOT NULL,
    ProductName     VARCHAR(255)  NOT NULL
);
Go

-- LocationID is the only key that does not exist in the CSV
CREATE TABLE DimLocation (
    LocationID      INT IDENTITY(1,1) PRIMARY KEY,
    CountryRegion   VARCHAR(50)   NOT NULL,
    City            VARCHAR(50)   NOT NULL,
    State           VARCHAR(50)   NOT NULL,
    PostalCode      INT           NOT NULL,
    Region          VARCHAR(20)   NOT NULL
);
Go 

CREATE TABLE DimOrders (
    OrderID         INT           PRIMARY KEY,
    OrderDate       DATE          NOT NULL,
    ShipDate        DATE          NOT NULL,
    ShipMode        VARCHAR(50)   NOT NULL,
    CustomerID      INT           NOT NULL,
    LocationID      INT           NOT NULL
);
Go

CREATE TABLE FactOrderDetails (
    OrderID         INT           NOT NULL,
    ProductID       INT           NOT NULL,
    Sales           DECIMAL(18,4) NOT NULL,
    Quantity        INT           NOT NULL,
    Discount        DECIMAL(4,2)  NOT NULL,
    Profit          DECIMAL(18,4) NOT NULL
);
GO


/* ---------------------------------------------------------------------
   STEP 5 : Fill the dimensions first
   --------------------------------------------------------------------- */

-- 793 rows
INSERT INTO DimCustomer (CustomerID, CustomerName, Segment)
SELECT DISTINCT CAST(CustomerID AS INT), CustomerName, Segment
FROM Staging_Superstore;
Go

-- 1850 rows
INSERT INTO DimProduct (ProductID, Category, SubCategory, ProductName)
SELECT DISTINCT CAST(ProductID AS INT), Category, SubCategory, ProductName
FROM Staging_Superstore;
Go

-- 632 rows
INSERT INTO DimLocation (CountryRegion, City, State, PostalCode, Region)
SELECT DISTINCT CountryRegion, City, State, CAST(PostalCode AS INT), Region
FROM Staging_Superstore;
Go

-- 5009 rows
INSERT INTO DimOrders (OrderID, OrderDate, ShipDate, ShipMode, CustomerID, LocationID)
SELECT DISTINCT
        CAST(s.OrderID AS INT),
        CONVERT(DATE, s.OrderDate, 101),   -- 101 = MM/DD/YYYY
        CONVERT(DATE, s.ShipDate,  101),
        s.ShipMode,
        CAST(s.CustomerID AS INT),
        l.LocationID
FROM Staging_Superstore s
INNER JOIN DimLocation l
        ON l.CountryRegion = s.CountryRegion
       AND l.City          = s.City
       AND l.State         = s.State
       AND l.PostalCode    = CAST(s.PostalCode AS INT)
       AND l.Region        = s.Region;
GO


/* ---------------------------------------------------------------------
   STEP 6 : Fill the fact table -> 9993 rows
   --------------------------------------------------------------------- */
INSERT INTO FactOrderDetails (OrderID, ProductID, Sales, Quantity, Discount, Profit)
SELECT  CAST(OrderID   AS INT),
        CAST(ProductID AS INT),
        CAST(Sales     AS DECIMAL(18,4)),
        CAST(Quantity  AS INT),
        CAST(Discount  AS DECIMAL(4,2)),
        CAST(Profit    AS DECIMAL(18,4))
FROM Staging_Superstore;
GO


/* ---------------------------------------------------------------------
   STEP 7 : Foreign keys
   --------------------------------------------------------------------- */
ALTER TABLE DimOrders
    ADD CONSTRAINT FK_Orders_Customer
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID);

ALTER TABLE DimOrders
    ADD CONSTRAINT FK_Orders_Location
    FOREIGN KEY (LocationID) REFERENCES DimLocation(LocationID);

ALTER TABLE FactOrderDetails
    ADD CONSTRAINT FK_Fact_Orders
    FOREIGN KEY (OrderID) REFERENCES DimOrders(OrderID);

ALTER TABLE FactOrderDetails
    ADD CONSTRAINT FK_Fact_Product
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID);
GO

-- full join test: must return 9993 (nothing lost, nothing duplicated)
SELECT COUNT(*) AS JoinedRows
FROM FactOrderDetails f
JOIN DimOrders   o ON o.OrderID    = f.OrderID
JOIN DimProduct  p ON p.ProductID  = f.ProductID
JOIN DimCustomer c ON c.CustomerID = o.CustomerID
JOIN DimLocation l ON l.LocationID = o.LocationID;
GO


-- optional, once verified
-- DROP TABLE Staging_Superstore;