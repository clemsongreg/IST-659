/*	Production History Database
	Gregory Richardson
	IST 659 Project
	Spring 2019

	This database houses the shift production records for Palmetto Synthetics.  All information contained within is proprietary and confidential.

*/

-- Part 1: Table Creation

-- Creating Production Time table
-- This table is a lookup table housing the 2 unique daily shifts - Day and Night
CREATE TABLE production_time (
	production_time_id int identity PRIMARY KEY,
	production_time varchar(5) not null UNIQUE
)

-- Creating Shift Name table
-- This table is lookup table housing the unique shift names (A, B, C, and D)
CREATE TABLE shift_name (
	shift_name_id int identity PRIMARY KEY,
	shift_name varchar(5) not null UNIQUE
)

-- Creating Machine Type table
-- This table is lookup table housing the unique Machine Types (Spinning, Finishing)
CREATE TABLE machine_type (
	machine_type_id int identity PRIMARY KEY,
	machine_type varchar(15) not null UNIQUE
)

-- Creating Product Type table
-- This table is lookup table housing the unique Product Types (Fine Denier, Heavy Denier)
CREATE TABLE product_type (
	product_type_id int identity PRIMARY KEY,
	product_type varchar(15) not null UNIQUE
)

-- Creating Customer table
-- This table houses the names (and potentially other information in the future) of our customers who order product
CREATE TABLE customer (
	customer_id int identity PRIMARY KEY,
	customer_name varchar(20) not null
)

/* 
	Creating Machine table
	- This table houses the information (including name and type) of all of our production machines
	- Each machine entry also includes an id referencing whether it is Spinning or Finishing
	- There is a Unique constraint for entries based on Name AND type.  ie - There can be 2
	Machine #2's, but only one Machine #2 that is for Spinning
*/
CREATE TABLE machine (
	machine_id int identity PRIMARY KEY,
	machine_name varchar(15) not null,
	machine_type_id int not null FOREIGN KEY REFERENCES machine_type(machine_type_id),
	CONSTRAINT u1_machine UNIQUE (machine_name, machine_type_id)
)

/*
	Creating Product table
	- This table houses information regarding our products - including the product code and product type
	- Each entry also includes an id referencing its Product Type (Fine or Heavy Denier)
	- Each item name is a combination of Denier, Product Code, and Product Length, and that combination
	of 3 items is Unique.
*/
CREATE TABLE product (
	product_id int identity PRIMARY KEY,
	product_denier varchar(5) not null,
	product_code varchar(10) not null,
	product_length varchar(5) not null,
	product_type_id int not null FOREIGN KEY REFERENCES product_type(product_type_id),
	CONSTRAINT U1_product UNIQUE (product_denier, product_code, product_length)
)

/*
	Creating Shift Date table
	- This table houses records of which shift was working a specific day and time
	- Each entry includes an id referencing whether the shift is Day or Night
	- Each entry includes an id referencing the Shift working (A, B, C or D)
	- There is a constraint here that says only 1 Shift can work a specific Day/Shift combo.
	That is - A and B shifts cannot BOTH work 1/1/2019 Day Shift...
*/
CREATE TABLE shift_date (
	shift_date_id int identity PRIMARY KEY,
	production_date date not null,
	production_time_id int not null FOREIGN KEY REFERENCES production_time(production_time_id),
	shift_name_id int not null FOREIGN KEY REFERENCES shift_name(shift_name_id),
	CONSTRAINT U1_shift_date UNIQUE (production_date, production_time_id)
)

/*
	Creating Product Customer table
	- This table lists the products ordered by a specific customer
	- Each customer can have multiple products and each product can have
	multiple customers, but a specific customer/product combination can only
	appear in this list once.
*/
CREATE TABLE product_customer_list (
	product_customer_id int identity PRIMARY KEY,
	product_id int not null FOREIGN KEY REFERENCES product(product_id),
	customer_id int not null FOREIGN KEY REFERENCES customer(customer_id),
	CONSTRAINT U1_product_customer UNIQUE (product_id, customer_id)
)

/*
	Creating Shift Production 
	- This table houses the yield measurements for a given production shift, machine, and product
	- Each entry must include: an id for the Shift/Date that created it, the id for the machine producing it,
	and an id for the product produced and customer it was produced for.
	- There are optional fields for inputting the pounds created, as well as various off-grade pounds.  
	- There is an additional required field for "Excluded".  Some products are R&D products that are not included in
	Production calculations.  This will help filter them out when doing those views.
	- There is a constraint on this table that a product can only appear on a machine once in a specific date/shift.  This is
	to avoid potential duplication/accidental separation of data.
*/
CREATE TABLE shift_production (
	shift_production_id int identity PRIMARY KEY,
	shift_date_id int not null FOREIGN KEY REFERENCES shift_date(shift_date_id),
	spinning_total_pounds int,
	finished_Q1_pounds int,
	waste_pounds int DEFAULT 0,
	mix_pounds int,
	off_grade_pounds int,
	excluded bit not null,
	machine_id int not null FOREIGN KEY REFERENCES machine(machine_id),
	product_customer_id int not null FOREIGN KEY REFERENCES product_customer_list(product_customer_id),
	CONSTRAINT U1_shift_production UNIQUE (shift_date_id, machine_id, product_customer_id)
)


/*	Part 2
	Part 2A : Adding Basic Information to Lookup Tables
	Tables: Machine Type, Product Type, Shift Name, Machine
*/

-- The Machine Type table is a lookup table including only 2 values - Spinning and Finishing. 
INSERT INTO machine_type
	(machine_type)
VALUES
	('Spinning'),
	('Finishing')

-- The Product Type table is a lookup table including only 2 values - Fine Denier and Heavy Denier
INSERT INTO product_type
	(product_type)
VALUES
	('Fine Denier'),
	('Heavy Denier')

-- The Shift Name table includes the names of the 4 working shifts - A, B, C, and D
INSERT INTO shift_name
	(shift_name)
VALUES
	('A'),
	('B'),
	('C'),
	('D')

-- The Production Time table is a lookup table including only 2 values - 'Day' and 'Night'
INSERT INTO production_time
	(production_time)
VALUES
	('Day'),
	('Night')

-- There are 3 Spinning machines (labeled 1, 2, and 3) and 4 Finishing machines (labeled 1,2,3, and 4).  
INSERT INTO machine
	(machine_name, machine_type_id)
VALUES
	(1, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Spinning')),
	(2, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Spinning')),
	(3, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Spinning')),
	(1, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Finishing')),
	(2, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Finishing')),
	(3, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Finishing')),
	(4, (SELECT machine_type_id FROM machine_type WHERE machine_type LIKE 'Finishing'))

/* 
	Part 2B : Adding Data From Imported Files
	Tables: Product, Customer, Product_Customer_List, Shift_Date, and Shift_Production
	Initial data was cleaned and made ready for the database in Excel.  Data was imported into temporary tables. 
	This section is for inserting the data from the temporary tables to the live tables and then removing the temp tables
*/

-- Inputting Product information from a cleaned Excel spreadsheet.  The spreadsheet lists the Product Type (Fine or Heavy), so I used
-- subquery to input the appropriate type id into the Product table.
INSERT INTO product (product_denier, product_code, product_length, product_type_id)
	SELECT Denier, Product1, Cut_Length, (SELECT product_type_id FROM product_type WHERE product_type LIKE Product$.Type) FROM Product$

-- Inserting a list of Customer names from a cleaned Excel spreadsheet imported into a temporary table.
INSERT INTO customer (customer_name)
	SELECT Customer FROM Customer$

-- Inserting a list of Products and their Customers from a cleaned Excel Spreadsheet imported into a temporary table.
-- 2 subqueries were used - one to get the product ID from the Product table, using the 3-part Product Code in the temporary table
-- The second subquery returns the Customer ID matching the appropriate customer in the Customer table.
INSERT INTO product_customer_list (product_id, customer_id)
	SELECT 
		(SELECT product_id FROM product WHERE product_denier LIKE productCustomer$.Denier AND product_code LIKE ProductCustomer$.Product1 AND product_length LIKE ProductCustomer$.Code),
		(SELECT customer_id FROM customer WHERE customer_name LIKE ProductCustomer$.Customer)
	FROM ProductCustomer$
	
-- Inserting a list of Shifts worked on selected days.  There are 2 shifts per day, each worked by 1 of 4 shifts.  
-- 2 subqueries used to insert the data into to the Shift_Date table.  The first gets the Shift Name id from the 
-- Shift_Name table matching the appropriate Shift Name
-- The second subquery returns the Production Time Id from its lookup table that matches the appropriate Production Time.
INSERT INTO shift_date (production_date, shift_name_id, production_time_id)
	SELECT date,
		(SELECT shift_name_id FROM shift_name WHERE shift_name LIKE ShiftDate$.Shift),
		(SELECT production_time_id FROM production_time WHERE production_time LIKE ShiftDate$.Time)
	FROM ShiftDate$

/*
	Inserting SPINNING data into the Shift Production table.  This table is where the magic happens.  
	There are 2 files which were brought in to temporary tables.  One for Spinning and one for Finishing.  The first INSERT
	will bring in the data from Spinning.  Several subqueries will be required.  One to get the appropriate Shift Date ID
	from the Date/Shift data in the table.  Another subquery will get the appropriate Product/Customer id, and another to return
	the appropriate Machine ID.  
	
	For Spinning, the fields required will be Spinning Total Pounds, Waste, and Mix.  All items are included, so this will be a 1. 
	All other entries will be Null.
*/
INSERT INTO shift_production (shift_date_id, machine_id, product_customer_id, spinning_total_pounds, mix_pounds, waste_pounds, excluded)
	SELECT 
		(SELECT shift_date_id FROM shift_date JOIN production_time ON production_time.production_time_id = shift_date.production_time_id 
			WHERE production_date = Spinning$.Date AND Spinning$.Time LIKE production_time.production_time),
		(SELECT machine_id FROM machine WHERE machine_name LIKE Spinning$.Tower AND machine_type_id = 1),
		(SELECT product_customer_id FROM product_customer_list 
			JOIN product ON product.product_id = product_customer_list.product_id 
			JOIN customer ON customer.customer_id = product_customer_list.customer_id
			WHERE product_denier LIKE Spinning$.Denier AND product_code LIKE Spinning$.Product1 
			AND product_length LIKE Spinning$.CutLength AND customer_name LIKE Spinning$.Customer),
		TotalPounds,
		Mix,
		Waste,
		0
	FROM Spinning$	  

/* The following statement will add data from the Finishing temporary table.  This is much the same as the Spinning table, 
	except here, the Spinning Pounds and Mix fields will be NULL.  
*/
INSERT INTO shift_production (shift_date_id, machine_id, product_customer_id, finished_Q1_pounds, off_grade_pounds, waste_pounds, excluded)
	SELECT 
		(SELECT shift_date_id FROM shift_date JOIN production_time ON production_time.production_time_id = shift_date.production_time_id 
			WHERE production_date = Finishing$.Date AND Finishing$.Time LIKE production_time.production_time),
		(SELECT machine_id FROM machine WHERE machine_name LIKE Finishing$.Location AND machine_type_id = 2),
		(SELECT product_customer_id FROM product_customer_list 
			JOIN product ON product.product_id = product_customer_list.product_id 
			JOIN customer ON customer.customer_id = product_customer_list.customer_id
			WHERE product_denier LIKE Finishing$.Denier AND product_code LIKE Finishing$.Code 
			AND product_length LIKE Finishing$.CutLength AND customer_name LIKE Finishing$.Customer),
		FinishingPounds,
		ISNULL(SubPounds, 0),
		ISNULL(Waste, 0),
		0
	FROM Finishing$

-- Dropping temporary tables from the Database
DROP TABLE Customer$
DROP TABLE Finishing$
DROP TABLE Product$
DROP TABLE ProductCustomer$
DROP TABLE ShiftDate$
DROP TABLE Spinning$

/* 
		PART 3
	Creating Functions for quickly recalling certain data and running common calculations.  These functions include recalling
	a Product ID given its component parts.  There is also a function for summarizing data for Q1 calculations - the most basic use
	of this database.  An additional function takes the summarized table data and returns a Q1% metric for a given time period.  
	
	Creating Stored Procedures for inserting new data into relevant tables.  These tables include:
	New Shift/Date pairs, New Products, New Customers, New Product/Customer Pairs, and New Shift Production
	Another Stored Procedure is created for Updating Waste on a specific Shift Production, as this tends to be done 
	at a later point than the intitial data entry.
*/

-- Creating a Function for recalling a Product ID.  The Function takes in the Denier, Code, and Cut Length and returns the
-- appropriate Product ID.
GO
CREATE FUNCTION ProdID (@denier varchar(5), @code varchar(10), @length varchar(5))
	RETURNS int AS
	BEGIN
		DECLARE @prod AS int = 0
		SET @prod = (SELECT product_id FROM product WHERE product_denier LIKE @denier AND product_code LIKE @code AND product_length LIKE @length)
	RETURN @prod
END	

-- Creating a Function to recall Date/Shift ID.  Function takes in the Production Date and the Shift and returns the Shift_Date ID.
GO
CREATE FUNCTION DateID (@date date, @shift varchar(5))
	RETURNS int AS
	BEGIN
		DECLARE @dateID AS int=0
		SET @dateID = (
			SELECT shift_date_id FROM shift_date 
			JOIN shift_name ON shift_date.shift_name_id = shift_name.shift_name_id
			WHERE production_date = @date 
			AND @shift LIKE shift_name
			)
		RETURN @dateID
END

-- Creating a Function to recall Machine ID.  Function takes in Machine Name and Type and returns the Machine ID.
GO
CREATE FUNCTION MachID (@machine varchar(5), @type varchar(10))
	RETURNS int AS
	BEGIN
		DECLARE @machid AS int = 0
		SET @machid = (
			SELECT machine_id 
			FROM machine 
			JOIN machine_type ON machine.machine_type_id = machine_type.machine_type_id
			WHERE machine_name LIKE @machine 
			AND	@type LIKE machine_type)
		RETURN @machid
	END

-- Creating a Stored Procedure for adding new date/shift information.  Function returns the identity of newly created row.
GO
CREATE PROCEDURE AddShift (@date AS varchar(10), @shift AS char(1), @time AS varchar(5))
	AS
	BEGIN
		INSERT INTO shift_date (production_date, shift_name_id, production_time_id)
		VALUES (
			(SELECT CONVERT (date, @date)),
			(SELECT shift_name_id FROM shift_name WHERE shift_name LIKE @shift),
			(SELECT production_time_id FROM production_time WHERE production_time LIKE @time)
		)
	RETURN @@identity
END
GO

EXEC AddShift '06/13/2019', 'A', 'Day'
SELECT * FROM shift_date WHERE shift_date_id = @@IDENTITY

-- Creating a Stored Procedure for creating a new product.  Function returns the identity of the newly created row.
GO
CREATE PROCEDURE AddProduct (@denier varchar(5), @code varchar(10), @length varchar(5), @type varchar (20))
	AS
	BEGIN
		INSERT INTO product (product_denier, product_code, product_length, product_type_id)
		VALUES (@denier, @code, @length,
			(SELECT product_type_id FROM product_type WHERE product_type LIKE @type)
		)
	RETURN @@IDENTITY
END
GO

EXEC AddProduct '18.0', 'PN1163', '2.25', 'Fine Denier'
SELECT * FROM product WHERE product_id = @@IDENTITY
GO	
-- Creating a Stored Procedure for creating a new customer.  Function returns the identity of the newly created row.
CREATE PROCEDURE AddCustomer (@name varchar(40))
	AS
	BEGIN
		INSERT INTO customer (customer_name)
		VALUES (@name)
	RETURN @@IDENTITY
END

EXEC AddCustomer 'Mirka'
SELECT * FROM customer where customer_id = @@IDENTITY
GO

-- Creating a Stored Procedure for linking a product and customer.  Function returns the identity of newly created row.
CREATE PROCEDURE AddProdCust (@denier varchar(5), @code varchar(10), @length varchar(5), @cust varchar(40))
	AS
	BEGIN
		DECLARE @prod AS int = 0,
			 @custid AS int = 0

		SET @prod = (dbo.ProdID(@denier, @code, @length))
		SET @custid = (SELECT customer_id FROM customer WHERE customer_name LIKE @cust)
		
		INSERT INTO product_customer_list (product_id, customer_id)
			VALUES (@prod, @custid)
	RETURN @@IDENTITY
END

EXEC AddProdCust '18.0', 'PN1163', '2.25', 'Mirka'
SELECT * FROM product_customer_list WHERE product_customer_id = @@IDENTITY

/* 
	Creating a Stored Procedure for inserting new Shift Production data.  There are two different types of Production 
	data - Spinning and Finishing.  Though similar, they have different data.  For instance, in Spinning, we input the total
	amount of pounds spun, as well as Waste and Mix lbs.  In Finishing, we input the total amount of good production made, as well
	as Waste and Off-Grade.  This procedure uses flow control to determine which fields to input and which to leave NULL.  Inputs 
	for the procedure are the date, shift, product code, customer, machine, machine type, total pounds (Spinning or Finishing), (Mix or Off-Grade), Waste,
	whether or not product is Excluded.  The procedure returns the id for the newly created entry.
*/
GO
CREATE PROCEDURE AddProdData (@date date, @shift varchar(5), @denier varchar(5), @code varchar(10), @length varchar(5), @customer varchar(40), 
	@machine varchar(5), @machType varchar(10), @pounds int, @sub int, @waste int, @excluded bit)
	AS
	BEGIN
		DECLARE @dateshift AS int = 0,
			@prod AS int=0,
			@line AS int = 0

		SET @dateshift = dbo.DateID (@date, @shift)
		SET @prod = (SELECT product_customer_id 
					FROM product_customer_list 
					JOIN customer ON product_customer_list.customer_id = customer.customer_id
					WHERE product_id = dbo.ProdID (@denier, @code, @length) 
					AND customer_name LIKE @customer)
		SET @line = dbo.MachID (@machine, @machType)
		
		IF @machType = 'Spinning'
		BEGIN
			INSERT INTO shift_production (shift_date_id, product_customer_id, machine_id, spinning_total_pounds, mix_pounds, waste_pounds, excluded)
			VALUES (@dateshift, @prod, @line, @pounds, @sub, @waste, @excluded)
		END
		ELSE
		BEGIN
			INSERT INTO shift_production (shift_date_id, product_customer_id, machine_id, finished_Q1_pounds, off_grade_pounds, waste_pounds, excluded)
			VALUES (@dateshift, @prod, @line, @pounds, @sub, @waste, @excluded)
		END
	RETURN @@IDENTITY
END

EXEC AddProdData '6/13/2019', 'A', '18.0', 'PN1163', '2.25', 'Mirka', '1', 'Spinning', 10000, 100, 300, 0
SELECT * FROM shift_production WHERE shift_production_id = @@IDENTITY

EXEC AddProdData '6/13/2019', 'A', '18.0', 'PN1163', '2.25', 'Mirka', '4', 'Finishing', 6000, 100, 240,0
SELECT * FROM shift_production WHERE shift_production_id = @@IDENTITY

/*
	Creating a function to summarize yield information for a given set of time.  The function takes in a start
	and end date, and returns a table with the following columns: the sum total of Finished Q1 pounds, Waste, and Sub.  
	There is another column which returns the total amount of Mix products baled in Finishing.  To do this, a subquery 
	was written b/c this value is ONLY from "Finishing" machines.  There is Mix tracked via Spinning, but that amount
	does not go into the final yield calculation (this would be double counting, as the Mix from Spinning is processed into
	Mix in Finishing.) The function also removes any excluded (R&D) products from the calculation. 
	
	This function is a critical first step for calculating Q1 Yield.  This function returns a table of the key values which 
	can be taken by an outside service to run the yield calculation.  There is also another created SQL function to return the yield 
	value.
*/
GO
CREATE FUNCTION yield_summary (@start date, @end date)
RETURNS TABLE AS 
RETURN (
	SELECT SUM(finished_Q1_pounds) AS q1,
		SUM(off_grade_pounds) sub,
		SUM(waste_pounds) waste,
		(SELECT SUM(mix_pounds)
			FROM shift_production
			JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
			JOIN machine ON shift_production.machine_id = machine.machine_id
			JOIN machine_type ON machine.machine_type_id = machine_type.machine_type_id
			WHERE production_date BETWEEN @start AND @end
			AND excluded = 0
			AND machine_type LIKE 'Finishing') AS mix
	FROM shift_production
	JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
	WHERE production_date BETWEEN @start AND @end
	AND excluded = 0
)

SELECT q1 FROM dbo.yield_summary ('5/1/2019', '5/8/2019')

/* 
	Creating a function to return the Q1% for a given time period.  This is the most basic yield value we use, and while most likely
	these calculations should be done by an external software retrieving the data from the yield_summary function, I wanted to provide
	a function for doing it within SQL.  This function takes in 2 dates, runs the yield_summary function to get the summarized yield data
	and then returns a calculated Q1% value.  This value is (using column names from the yield_summary function)
			
			Q1% = (q1 / (waste + sub + mix + q1)) * 100
		
	One complication when initially creating this function is that, since all the values are integers, the calculation would return only 0.  To 
	beat this, I cast the values as floats for the calculation and return a decimal value (with 2  decimal places of precision) 
*/
GO
CREATE FUNCTION q1_calc (@start date, @end date)
RETURNS decimal(5,2) AS
BEGIN
	DECLARE @q1 AS decimal(5,2)
	SET @q1 = (SELECT CAST(q1 AS float) / CAST(q1 + mix + waste + sub AS float) * 100
				FROM dbo.yield_summary(@start,@end))
	RETURN @q1
END

SELECT dbo.q1_calc('5/1/2019', '5/2/2019')	

-- Quick function for calculating a % of the total given the appropriate values
GO
CREATE FUNCTION percentcalc (@num int, @denom1 int, @denom2 int, @denom3 int)
RETURNS decimal (5,2) AS
BEGIN
	DECLARE @q AS decimal(5,2)
	SET @q = CAST(@num AS float) / CAST(@num + @denom1 + @denom2 + @denom3 AS float) * 100
	RETURN @q
END

SELECT q1, sub, waste, mix, 
	dbo.percentcalc(waste, sub, q1, mix)
FROM dbo.yield_summary('5/1/2019', '5/31/2019')

/* 
	Creating a stored procedure to update the Waste for a given shift_production field.
	The procedure takes in the date and shift for the update, as well as the product/customer 
	and machine.  It also takes in the value (in pounds) of waste to be added to the specific field.  
	The waste is added to the current value in waste, not simply replacing the value in there.
*/
GO
CREATE PROCEDURE AddWaste (@date date, @shift varchar(5), @denier varchar(5), @code varchar(10), @length varchar(5), @customer varchar(40), 
	@machine varchar(5), @machType varchar(10), @waste int)
AS
BEGIN
	DECLARE @dateshift AS int = 0,
			@prod AS int=0,
			@line AS int = 0

	SET @dateshift = dbo.DateID (@date, @shift)
	SET @prod = (SELECT product_customer_id 
				FROM product_customer_list 
				JOIN customer ON product_customer_list.customer_id = customer.customer_id
				WHERE product_id = dbo.ProdID (@denier, @code, @length) 
				AND customer_name LIKE @customer)
	SET @line = dbo.MachID (@machine, @machType)
	UPDATE shift_production
	SET waste_pounds = waste_pounds + @waste
	WHERE shift_date_id = @dateshift
	AND product_customer_id = @prod
END

EXEC AddWaste'6/13/2019', 'A', '18.0', 'PN1163', '2.25', 'Mirka', '1', 'Spinning', 100

/*	Part 4 - Answering Data Questions
	In this section we answer the questions posed at the start of the project descriptions.  
*/

/*
	The first data question - and the most commonly accessed - is a look at plant performance for
	a given time period - typically Year-To-Date and Month-To-Date.  We want to know what the total 
	pounds of Q1 product, Waste, Mix, and off-grade; as well as the % of the total each is.  We will
	create 2 views for this - one for YTD and one for MTD.  As stated above in the Q1 calculation function,
	this view sums all Finishing, Waste, and Off-Grade totals, but only totals the Mix from Finishing, in order
	to avoid double-counting.
*/
GO		
CREATE VIEW YTDView	AS
SELECT q1 AS 'Q1 Pounds',
	sub AS 'Off-Grade Pounds',
	waste AS 'Waste Pounds',
	mix AS 'Mix Pounds',
	dbo.q1_calc(DATEFROMPARTS(DATEPART(year, GETDATE()),1,1), GETDATE()) AS 'Q1 %',
	cast(cast(waste AS float) / cast(q1 + sub + waste + mix AS float) *100 AS decimal(5,2)) AS 'Waste %',
	cast(cast(sub AS float) / cast(q1 + sub + waste + mix AS float) *100 AS decimal(5,2)) AS 'Off-Grade %',
	cast(cast(mix AS float) / cast(q1 + sub + waste + mix AS float) *100 AS decimal(5,2)) AS 'Mix %'
FROM dbo.yield_summary(DATEFROMPARTS(DATEPART(year, GETDATE()),1,1), GETDATE())

CREATE VIEW MTDView	AS
SELECT q1 AS 'Q1 Pounds',
	sub AS 'Off-Grade Pounds',
	waste AS 'Waste Pounds',
	mix AS 'Mix Pounds',
	dbo.q1_calc(DATEFROMPARTS(DATEPART(year, GETDATE()),DATEPART(month, GETDATE()),1), GETDATE()) AS 'Q1 %',
	cast(cast(waste AS float) / cast(q1 + sub + waste + mix AS float) *100 AS decimal(5,2)) AS 'Waste %',
	cast(cast(sub AS float) / cast(q1 + sub + waste + mix AS float) *100 AS decimal(5,2)) AS 'Off-Grade %',
	cast(cast(mix AS float) / cast(q1 + sub + waste + mix AS float) *100 AS decimal(5,2)) AS 'Mix %'
FROM dbo.yield_summary(DATEFROMPARTS(DATEPART(year, GETDATE()),DATEPART(month,GETDATE()),1), GETDATE())

/* The second data question is what are the specific yields (pounds and %'s) for a given Machine/Machine Type for a given
time period.  Again, this information is often looked at on a MTD and YTD basis.  The created view sums the total pounds for the specific
machine and also calculates %'s of the total for each category.  There is one view for MTD and one view for YTD.

Because of the way production pounds are measured, there are 2 different methods of calculating the total percents.  In Spinning, we measure
the total amount of production that was produced (ie - INPUT pounds), and from that we must subtract the amount of Waste and Mix created to find
the Q1 %.  In Finishing, we measure the total amount of good pounds produced (ie - OUTPUT pounds) along with the amount of Waste, Mix, and Off-Grade
produced.  In order to display the correct % values for both types in the same view, I used several CASE statements - with one equation if calculating
for Spinning and one statement if calculating for Finishing.
*/
GO
CREATE VIEW MachineYTD AS
SELECT machine_type + ' ' + machine_name AS 'Machine Name',
	SUM(spinning_total_pounds) AS 'Total Spun Pounds' ,
	SUM(finished_Q1_pounds) AS 'Finished Q1 Pounds',
	SUM(waste_pounds) AS 'Waste Pounds',
	SUM(mix_pounds) AS 'Mix Pounds',
	SUM(off_grade_pounds) AS 'Off-Grade Pounds',
	CASE
		WHEN machine_type LIKE 'Spinning' THEN cast(cast(SUM(spinning_total_pounds) - SUM(waste_pounds) - SUM(mix_pounds) AS float)/cast(SUM(spinning_total_pounds) AS float) * 100 AS decimal(5,2))
		WHEN machine_type LIKE 'Finishing' THEN cast(cast(SUM(finished_q1_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2))
	END AS 'Q1 %',
	CASE
		WHEN machine_type LIKE 'Spinning' THEN cast(cast(SUM(waste_pounds) AS float)/cast(SUM(spinning_total_pounds) AS float) * 100 AS decimal(5,2))
		WHEN machine_type LIKE 'Finishing' THEN cast(cast(SUM(waste_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2))
	END AS 'Waste %',
	CASE
		WHEN machine_type LIKE 'Spinning' THEN cast(cast(SUM(mix_pounds) AS float)/cast(SUM(spinning_total_pounds) AS float) * 100 AS decimal(5,2))
		WHEN machine_type LIKE 'Finishing' THEN cast(cast(SUM(mix_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2))
	END AS 'Mix %',
	cast(cast(SUM(off_grade_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2)) AS 'Sub %'
FROM shift_production
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
JOIN machine ON shift_production.machine_id = machine.machine_id
JOIN machine_type ON machine.machine_type_id = machine_type.machine_type_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),1,1) AND GETDATE()
GROUP BY machine_type, machine_name

GO
CREATE VIEW MachineMTD AS
SELECT machine_type + ' ' + machine_name AS 'Machine Name',
	SUM(spinning_total_pounds) AS 'Total Spun Pounds' ,
	SUM(finished_Q1_pounds) AS 'Finished Q1 Pounds',
	SUM(waste_pounds) AS 'Waste Pounds',
	SUM(mix_pounds) AS 'Mix Pounds',
	SUM(off_grade_pounds) AS 'Off-Grade Pounds',
	CASE
		WHEN machine_type LIKE 'Spinning' THEN cast(cast(SUM(spinning_total_pounds) - SUM(waste_pounds) - SUM(mix_pounds) AS float)/cast(SUM(spinning_total_pounds) AS float) * 100 AS decimal(5,2))
		WHEN machine_type LIKE 'Finishing' THEN cast(cast(SUM(finished_q1_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2))
	END AS 'Q1 %',
	CASE
		WHEN machine_type LIKE 'Spinning' THEN cast(cast(SUM(waste_pounds) AS float)/cast(SUM(spinning_total_pounds) AS float) * 100 AS decimal(5,2))
		WHEN machine_type LIKE 'Finishing' THEN cast(cast(SUM(waste_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2))
	END AS 'Waste %',
	CASE
		WHEN machine_type LIKE 'Spinning' THEN cast(cast(SUM(mix_pounds) AS float)/cast(SUM(spinning_total_pounds) AS float) * 100 AS decimal(5,2))
		WHEN machine_type LIKE 'Finishing' THEN cast(cast(SUM(mix_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2))
	END AS 'Mix %',
	cast(cast(SUM(off_grade_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(mix_pounds) + SUM(off_grade_pounds) AS float)*100 AS decimal(5,2)) AS 'Sub %'
FROM shift_production
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
JOIN machine ON shift_production.machine_id = machine.machine_id
JOIN machine_type ON machine.machine_type_id = machine_type.machine_type_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),DATEPART(month, GETDATE()),1) AND GETDATE()
GROUP BY machine_type, machine_name

/*
	One question we look at regularly is what are our Best and Worst performing products.  Two views are created which look at the Top 10
	and Bottom 10 products in terms of Q1% YTD.  
*/
GO
CREATE VIEW Bottom10 AS
SELECT TOP 10
	product_denier + '-' + product_code + '-' + product_length AS 'Product',
	CAST(CAST(SUM(finished_q1_pounds) AS float)/CAST(SUM(finished_q1_pounds)+SUM(waste_pounds)+SUM(mix_pounds)+SUM(off_grade_pounds) AS float)*100 AS decimal(5,2)) AS 'Q1%'
FROM shift_production
JOIN product_customer_list ON shift_production.product_customer_id = product_customer_list.product_customer_id
JOIN product ON product_customer_list.product_id = product.product_id
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),1,1) AND GETDATE()
GROUP BY product_denier, product_code, product_length
HAVING SUM(finished_q1_pounds) | SUM(waste_pounds) | SUM(mix_pounds) | SUM(off_grade_pounds) IS NOT NULL
ORDER BY [Q1%] ASC

GO
CREATE VIEW Top10 AS
SELECT TOP 10
	product_denier + '-' + product_code + '-' + product_length AS 'Product',
	CAST(CAST(SUM(finished_q1_pounds) AS float)/CAST(SUM(finished_q1_pounds)+SUM(waste_pounds)+SUM(mix_pounds)+SUM(off_grade_pounds) AS float)*100 AS decimal(5,2)) AS 'Q1%'
FROM shift_production
JOIN product_customer_list ON shift_production.product_customer_id = product_customer_list.product_customer_id
JOIN product ON product_customer_list.product_id = product.product_id
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),1,1) AND GETDATE()
GROUP BY product_denier, product_code, product_length
HAVING SUM(finished_q1_pounds) | SUM(waste_pounds) | SUM(mix_pounds) | SUM(off_grade_pounds) IS NOT NULL
ORDER BY [Q1%] DESC

/* 
	The next data question this database will allow us to answer is - who are our most valuable customers (in terms of volume)?  This view looks at
	the Top 10 Customers and their volumes YTD.
*/
GO
CREATE VIEW TopCustomers AS
SELECT TOP 10
	customer_name AS 'Customer Name',
	SUM(finished_q1_pounds) AS 'Total Volume'
FROM shift_production
JOIN product_customer_list ON shift_production.product_customer_id = product_customer_list.product_customer_id
JOIN customer ON product_customer_list.customer_id = customer.customer_id
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),1,1) AND GETDATE()
GROUP BY customer_name
ORDER BY [Total Volume] DESC

/*
	We also often want to know how many unique products we ran in a given month.  This view returns the count of distinct
	products (not product-customer pairs, just distinct prodcuts) run MTD.
*/
GO	
CREATE VIEW MonthlyProductCount AS	
SELECT COUNT (DISTINCT product_id) AS 'Count of Products Run'
FROM shift_production
JOIN product_customer_list ON shift_production.product_customer_id = product_customer_list.product_customer_id
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),DATEPART(month, GETDATE()),1) AND GETDATE()

/* 
	The final question we want to answer (here at least) is what is the Production Q1% Yield for a given
	Product Type.  That is - What is the Yield for Fine Denier and Heavy Denier products in a given time period - 
	in this case, MTD.

	As before in our Q1 calculations, we have to account for Mix showing up in both the Spinning stages and the Finishing stages.
	An additional wrinkle emerges here - The "Heavy Denier" products are a 1-stage product - meaning they ONLY go through 
	Finishing (and do not generate Mix).  All products run on the "Spinning" step are "Fine Denier" products, and so all Mix must be attributed
	only to them.  To solve this problem, I created another CASE statement, with 2 different equations for Q1% depending on whether the product
	is Fine Denier or Heavy Denier.
*/
GO
CREATE VIEW ProductTypeYield AS
SELECT product_type AS 'Product Type',
	SUM(finished_Q1_pounds) AS 'Total Pounds',
	CASE
	WHEN product_type LIKE 'Fine Denier'
	THEN cast(cast(SUM(finished_q1_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(off_grade_pounds) + 
			(SELECT SUM(mix_pounds)
			FROM shift_production
			JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
			JOIN machine ON shift_production.machine_id = machine.machine_id
			JOIN machine_type ON machine.machine_type_id = machine_type.machine_type_id
			WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),DATEPART(month, GETDATE()),1) AND GETDATE()
			AND machine_type LIKE 'Finishing') AS float) * 100 AS decimal(5,2))
	WHEN product_type LIKE 'Heavy Denier'
	THEN cast(cast(SUM(finished_q1_pounds) AS float)/cast(SUM(finished_q1_pounds) + SUM(waste_pounds) + SUM(off_grade_pounds) AS float) * 100 AS decimal(5,2))
	END AS 'Q1%'
FROM shift_production
JOIN product_customer_list ON shift_production.product_customer_id = product_customer_list.product_customer_id
JOIN product ON product_customer_list.product_id = product.product_id	
JOIN product_type ON product.product_type_id = product_type.product_type_id
JOIN shift_date ON shift_production.shift_date_id = shift_date.shift_date_id
WHERE production_date BETWEEN DATEFROMPARTS(DATEPART(year, GETDATE()),DATEPART(month, GETDATE()),1) AND GETDATE()
GROUP BY product_type

SELECT * FROM ProductTypeYield

