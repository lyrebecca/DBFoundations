--*************************************************************************--
-- Title: Assignment06
-- Author: RebeccaLy
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2020-08-12,RebeccaLy,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_RebeccaLy')
	 Begin 
	  Alter Database [Assignment06DB_RebeccaLy] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_RebeccaLy;
	 End
	Create Database Assignment06DB_RebeccaLy;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_RebeccaLy;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Union
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, ABS(CHECKSUM(NewId())) % 100 as RandomValue
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
--NOTES------------------------------------------------------------------------------------ 
 --1) You can use any name you like for you views, but be descriptive and consistent
 --2) You can use your working code from assignment 5 for much of this assignment
 --3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5 pts): How can you create BACIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
Create View vCategories
WITH SCHEMABINDING
AS
 Select CategoryID, CategoryName From dbo.Categories;
Go

--Creates a view called 'vEmployees' using columns from the 'Employees' table
Create View vEmployees
WITH SCHEMABINDING
AS
	Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID
	From dbo.Employees;
Go

--Creates a view called 'vInventories' using columns from 'Inventories' table
Create View vInventories
WITH SCHEMABINDING
AS
	Select InventoryID, InventoryDate, EmployeeID, ProductID, Count
	From dbo.Inventories;
Go

--Creates a view called 'vProducts' using columns from 'Products' table
Create View vProducts
WITH SCHEMABINDING
AS
	Select ProductID, ProductName, CategoryID, UnitPrice
	From dbo.Products
Go

-- Question 2 (5 pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?
-- Denies public access to the main tables but grants access to the public for the views
Deny Select On Categories to Public;
Grant Select On dbo.vCategories to Public;

Deny Select On Employees to Public;
Grant Select On dbo.vEmployees to Public;

Deny Select On Inventories to Public;
Grant Select On dbo.vInventories to Public;

Deny Select On Products to Public;
Grant Select On dbo.vProducts to Public;

-- Question 3 (10 pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

-- Creates a new view to show Products by Category Name using the 'Categories' and 'Products' table
Create View vProductsByCategories
AS
	Select TOP 1000000
	c.CategoryName, p.ProductName, p.UnitPrice
	From Categories as c 
	Join Products as p 
	On c.CategoryID = p.CategoryID
	Order By c.CategoryName, p.ProductName;
Go
--Drop View vProductsByCategories

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,UnitPrice
-- Beverages,Chai,18.00
-- Beverages,Chang,19.00
-- Beverages,Chartreuse verte,18.00

-- Question 4 (10 pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!
-- Creates a view to show Products Name by Inventory Date and Count using the 'Products' and 'Inventories' table
Create View vInventoriesByProductsByDates
AS
	Select TOP 1000000
	p.ProductName, inv.InventoryDate, inv.Count
	From Products As p
	Join Inventories as inv
	On p.ProductID = inv.ProductID
	Order By p.ProductName, inv.InventoryDate, inv.Count;
Go

-- Here is an example of some rows selected from the view:
--ProductName,InventoryDate,Count
--Alice Mutton,2017-01-01,15
--Alice Mutton,2017-02-01,78
--Alice Mutton,2017-03-01,83

-- Question 5 (10 pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!
-- Creates a view showing Inventory Date and the Employee who took the count using the 'Inventories' and 'Employees' table
Create View vInventoriesByEmployeesByDates
AS
	Select TOP 1000000 --Way to allow an order by statement
	inv.InventoryDate, [Employee Name] = emp.EmployeeFirstName + ' ' + emp.EmployeeLastName --Concatenates the Employee's First Name and Last Name
	From Inventories As inv --Alias for inventory table
	Join Employees As emp --Alias for Employee table
	On inv.EmployeeID = emp.EmployeeID
	Group by inv.InventoryDate, emp.EmployeeFirstName, emp.EmployeeLastName
	Order By inv.InventoryDate, [Employee Name];
Go

-- Here is an example of some rows selected from the view:
-- InventoryDate,EmployeeName
-- 2017-01-01,Steven Buchanan
-- 2017-02-01,Robert King
-- 2017-03-01,Anne Dodsworth


-- Question 6 (10 pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

--Creates a view to show Products by Categories by Inventory Date and Count using the 'Products', 'Inventories', and 'Categories' table
Create View vInventoriesByProductsByCategories
AS
	Select TOP 1000000
	c.CategoryName, p.ProductName, inv.InventoryDate, inv.Count
	From Categories As C
	Join Products As p
	On c.CategoryID = p.CategoryID
	Join Inventories as inv
	On p.ProductID = inv.ProductID
	Order by 1,2,3,4;
Go

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count
-- Beverages,Chai,2017-01-01,72
-- Beverages,Chai,2017-02-01,52
-- Beverages,Chai,2017-03-01,54


-- Question 7 (10 pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

-- Creates a view to show Category Name, Product Name, and Inventory Name as well as the Count and Employee who took the count
Create View vInventoriesByProductsByEmployees
AS
	Select Top 1000000
	c.CategoryName, p.ProductName, inv.InventoryDate, inv.Count, [Employee Name] = emp.EmployeeFirstName + ' ' + emp.EmployeeLastName
	From Categories As c
	Join Products As p
	On c.CategoryID = p.CategoryID
	Join Inventories As inv
	On p.ProductID = inv.ProductID
	Join Employees As emp
	On inv.EmployeeID = emp.EmployeeID
	Order By inv.InventoryDate, c.CategoryName, p.ProductName, [Employee Name]
Go

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count,EmployeeName
-- Beverages,Chai,2017-01-01,72,Steven Buchanan
-- Beverages,Chang,2017-01-01,46,Steven Buchanan
-- Beverages,Chartreuse verte,2017-01-01,61,Steven Buchanan


-- Question 8 (10 pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 

Create View vInventoriesForChaiAndChangByEmployees
AS
	Select Top 1000000
	c.CategoryName, p.ProductName, inv.InventoryDate, inv.Count, [Employee Name] = emp.EmployeeFirstName + ' ' + emp.EmployeeLastName
	From Categories As c
	Join Products As p
	On c.CategoryID = p.CategoryID
	Join Inventories As inv
	On p.ProductID = inv.ProductID
	Join Employees As emp
	On inv.EmployeeID = emp.EmployeeID
	Where p.ProductName = 'Chai' OR p.ProductName = 'Chang'
	Order By inv.InventoryDate, c.CategoryName, p.ProductName, [Employee Name]
Go

-- Here is an example of some rows selected from the view:
-- CategoryName,ProductName,InventoryDate,Count,EmployeeName
-- Beverages,Chai,2017-01-01,72,Steven Buchanan
-- Beverages,Chang,2017-01-01,46,Steven Buchanan
-- Beverages,Chai,2017-02-01,52,Robert King


-- Question 9 (10 pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

Create View vEmployeesByManager
AS
	SELECT Top 1000000
	mgr.EmployeeFirstName + ' ' + mgr.EmployeeLastName AS [Manager], emp.EmployeeFirstName + ' ' + emp.EmployeeLastName AS [Employee]
	FROM Employees emp -- Alias for Employee table
	--Self join to look up the ManagerID in the EmployeeID column to bring over the first and last name column
	LEFT JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID
	ORDER BY 1,2
Go

-- Here is an example of some rows selected from the view:
-- Manager,Employee
-- Andrew Fuller,Andrew Fuller
-- Andrew Fuller,Janet Leverling
-- Andrew Fuller,Laura Callahan


-- Question 10 (10 pts): How can you create one view to show all the data from all four 
-- BASIC Views?

--Creates a view to join all the views together in one view
Create View vInventoriesByProductsByCategoriesByEmployees
AS
	Select Top 1000000
	c.CategoryID, c.CategoryName, p.ProductID, 
	p.ProductName, p.UnitPrice, 
	inv.InventoryID, inv.InventoryDate, inv.Count, 
	emp.EmployeeID, emp.EmployeeFirstName + ' ' + emp.EmployeeLastName AS [Employee], mgr.EmployeeFirstName + ' ' + mgr.EmployeeLastName AS [Manager]
	From vCategories As c --Alias for Categories view
	Join vProducts As p --Alias for Products view
	On c.CategoryID = p.CategoryID
	Join vInventories As inv --Alias for Inventories view
	On p.ProductID = inv.ProductID
	Join vEmployees As emp --Alias for employee view
	On inv.EmployeeID = emp.EmployeeID
	LEFT JOIN Employees mgr ON emp.ManagerID = mgr.EmployeeID --Self join to get manager's name
	Order By 1,2,3,4
Go

-- Here is an example of some rows selected from the view:
-- CategoryID,CategoryName,ProductID,ProductName,UnitPrice,InventoryID,InventoryDate,Count,EmployeeID,Employee,Manager
-- 1,Beverages,1,Chai,18.00,1,2017-01-01,72,5,Steven Buchanan,Andrew Fuller
-- 1,Beverages,1,Chai,18.00,78,2017-02-01,52,7,Robert King,Steven Buchanan
-- 1,Beverages,1,Chai,18.00,155,2017-03-01,54,9,Anne Dodsworth,Steven Buchanan

-- Test your Views (NOTE: You must change the names to match yours as needed!)
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByDates]
Select * From [dbo].[vInventoriesByEmployeesByDates]
Select * From [dbo].[vInventoriesByProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByEmployees]
Select * From [dbo].[vInventoriesForChaiAndChangByEmployees]
Select * From [dbo].[vEmployeesByManager]
Select * From [dbo].[vInventoriesByProductsByCategoriesByEmployees]
/***************************************************************************************/