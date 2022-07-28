---- [THIS PROJECT FOCUSES ON THE CLEANING OF 3 DIFFERENT DATASETS WHICH IS GOING TO BE LATER USE FOR DATA EXPLORATION, MODEL DEVELOPMENT AND INTERPRETATION]

----------------------------------------IMPORTING TABLE----------------------------------------
--In this case we are using the bulk insert method to import the excel table into the Database

-------------------[1]-Importing table for Transactions Table
USE Modify
GO

CREATE TABLE Transactions
(
transaction_id int,	product_id int,	customer_id int, transaction_date date,	online_order varchar(256), order_status varchar(256),
brand varchar(256), product_line varchar(256),	product_class varchar(256),	product_size varchar(256),	list_price float, standard_cost varchar(256),	
product_first_sold_date int
)
GO

BULK INSERT Transactions 
FROM 'C:\Users\Mubaraq\Downloads\Transactions.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW=2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
)
GO

--getting a preview of the table
SELECT * 
FROM Transactions

-------------------[2]-Importing table for CustomerDemographic Table
USE Modify
GO

CREATE TABLE CustomerDemographic
(
customer_id int, first_name varchar(256), last_name varchar(256), gender varchar(256), past_3_years_bike_related_purchases int,	DOB nvarchar(256),
job_title varchar(256),	job_industry_category varchar(256),	wealth_segment varchar(256), deceased_indicator varchar(256),	
owns_car varchar(256), tenure int

)
GO

BULK INSERT CustomerDemographic 
FROM 'C:\Users\Mubaraq\Downloads\CustomerDemographic.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW=2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'

)
GO

--getting a preview of the table
SELECT * 
FROM CustomerDemographic


-------------------[3]-Importing table for CustomerAddress Table
USE Modify
GO

CREATE TABLE CustomerAddress
(
customer_id int, address varchar(256),	postcode int, state varchar(256), country varchar(256),	property_valuation int

)
GO

BULK INSERT CustomerAddress
FROM 'C:\Users\Mubaraq\Downloads\CustomerAddress.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW=2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'

)
GO

--Previewing the table 
SELECT * 
FROM CustomerAddress

--------------------------------------------------------DATA CLEANING PROCESS--------------------------------------------------------


SELECT *
FROM CustomerDemographic

-------------------[1]-Converting Y to Yes and N to No in the CustomerDemographic table to ensure consistency
SELECT *
FROM Transactions
ORDER BY customer_id

SELECT deceased_indicator
,CASE
	WHEN deceased_indicator = 'N' THEN 'No'
	WHEN deceased_indicator = 'Y' THEN 'Yes'
	ELSE deceased_indicator 
	END AS DeceasedIndicator
FROM CustomerDemographic
JOIN CustomerAddress
	ON CustomerDemographic.customer_id=CustomerAddress.customer_id
WHERE deceased_indicator <> 'N'

--Altering table
ALTER TABLE CustomerDemographic
ADD  DeceasedIndicator varchar(256)

--Updating table
UPDATE CustomerDemographic
SET DeceasedIndicator = CASE
	WHEN deceased_indicator = 'N' THEN 'No'
	WHEN deceased_indicator = 'Y' THEN 'Yes'
	ELSE deceased_indicator 
	END 
FROM CustomerDemographic
JOIN CustomerAddress
	ON CustomerDemographic.customer_id=CustomerAddress.customer_id

--Previewing the table 
SELECT *
FROM [Modify]..[CustomerDemographic]

SELECT deceasedindicator, ISNULL(DeceasedIndicator,'No') 
FROM CustomerDemographic
WHERE deceasedindicator IS NULL

-------------------[2]-Replacing the null cells in the deceased indicator column under the CustomerDemographic table
--Updating table
UPDATE [Modify]..[CustomerDemographic]
SET deceasedindicator = 'No'
WHERE deceasedindicator IS NULL


-------------------[3]-Expanding the abbreviated states in the CustomerAddress table to ensure consistency
SELECT state
,CASE
	WHEN state =  'VIC' THEN 'Victoria'
	WHEN state =  'NSW' THEN 'New South Wales'
	WHEN state =  'QLD' THEN 'QueensLand'
	ELSE state
END AS states
FROM CustomerAddress

ALTER TABLE CustomerAddress
ADD states varchar(256)

--Updating table
UPDATE CustomerAddress
SET  states = CASE
	WHEN state =  'VIC' THEN 'Victoria'
	WHEN state =  'NSW' THEN 'New South Wales'
	WHEN state =  'QLD' THEN 'QueensLand'
	ELSE state
END 
FROM CustomerAddress

SELECT *
FROM CustomerAddress

-------------------[4]-Making a correction to the mistake of having 1843 in the CustomerDemographic Table to 1943 under the DOB column
SELECT DOB
FROM CustomerDemographic
WHERE DOB NOT LIKE '%/%'

--Updating table
UPDATE CustomerDemographic
SET DOB = 21/12/1943
FROM CustomerDemographic
WHERE DOB NOT LIKE '%/%'

--Deleting the rows in the DOB table having values to be zero
DELETE FROM CustomerDemographic
WHERE DOB = '0'


-------------------[5]-Creating the age column from it's meta data - DOB column 
SELECT 2022 - SUBSTRING(DOB,7,4) as AGE
FROM CustomerDemographic

--Altering table
ALTER TABLE CustomerDemographic
ADD AGE int

--Updating the table
UPDATE CustomerDemographic
SET AGE = 2022 - SUBSTRING(DOB,7,4) 

--previewing the table
SELECT *
FROM CustomerDemographic

-------------------[6]-Deleting the rows having 'U' under the gender column which have corresponding NULL values in the other columns
DELETE FROM CustomerDemographic
WHERE gender = 'U'


-------------------[7]-Converting F to Female and M to Male in the CustomerDemographic table and Updating it to ensure consistency
SELECT *
,CASE
		WHEN gender = 'F' THEN 'Female'
		WHEN gender = 'Femal' THEN 'Female'
		WHEN gender = 'M' THEN 'Male'
		ELSE gender 
END AS Genders
FROM CustomerDemographic
WHERE gender <> 'Female'
AND gender <> 'Male'

--Updating table
UPDATE CustomerDemographic
SET gender = CASE
		WHEN gender = 'F' THEN 'Female'
		WHEN gender = 'Femal' THEN 'Female'
		WHEN gender = 'M' THEN 'Male'
		ELSE gender 
END
FROM CustomerDemographic



-------------------[8]-Removing null cells in job_title columns under the CustomerDemographic Table

DELETE FROM CustomerDemographic
WHERE job_title IS NULL


-------------------[9]-Renaming the 'n/a' cell in job_industry_category column by updating to improve context 

SELECT job_industry_category
,CASE
	WHEN job_industry_category='n/a' THEN 'Not Specified'
	ELSE job_industry_category
END 
FROM CustomerDemographic

--Updating table
UPDATE CustomerDemographic
SET job_industry_category = CASE
	WHEN job_industry_category='n/a' THEN 'Not Specified'
	ELSE job_industry_category
END 
FROM CustomerDemographic


-------------------[10]-Checking for duplicate values in CustomerDemographic table, CustomerAddress table & Transactions table
--Previewing the table
SELECT *
FROM CustomerDemographic

--Using Common table expression to check for duplicates in the CustomerDemographic table
WITH CTE AS
(
SELECT * ,ROW_NUMBER ()  OVER(PARTITION BY first_name, last_name,DOB ORDER BY customer_id ) as rownum
FROM CustomerDemographic
)
SELECT *
FROM CTE
WHERE rownum >1

--Previewing the table
SELECT *
FROM CustomerAddress

--Using Common table expression to check for duplicates in the CustomerAddress table
WITH CTE AS
(
SELECT * ,ROW_NUMBER ()  OVER(PARTITION BY address,postcode ORDER BY customer_id ) as rownum
FROM CustomerAddress
)
SELECT *
FROM CTE
WHERE rownum >1



--Using Common table expression to check for duplicates in the Transactions table
WITH CTE AS
(
SELECT * ,ROW_NUMBER ()  OVER(PARTITION BY transaction_id,transaction_date,brand,product_class,product_size ORDER BY customer_id ) as rownum
FROM Transactions
)
SELECT *
FROM CTE
WHERE rownum >1

------------- :no duplicates value found in the 3 tables



-------------------[11]-Deriving the no. of transactions made in the Transactions column by creating a new table and merging it the CustomerAddress Table and CustomerDemographic Table
--Altering the table
ALTER TABLE CustomerAddress
ADD No_Of_Transactions varchar(256)


SELECT customer_id,COUNT(customer_id) AS NoOfTransactions
FROM Transactions
GROUP BY customer_id
ORDER BY customer_id

SELECT *
FROM Transactions


SELECT *
FROM CustomerDemographic
JOIN CustomerAddress
	ON CustomerDemographic.customer_id=CustomerAddress.customer_id


-------------------[12]-Creating a new table from the transaction table to join to the customer address table and customer demographics table
-------------------New table is called TransactionTable 
CREATE TABLE TransactionTable
(customer_id int,
NoOfTransaction int,
)

INSERT INTO TransactionTable 
SELECT customer_id,COUNT(customer_id) AS NoOfTransactions
FROM Modify..Transactions
GROUP BY customer_id
ORDER BY customer_id

SELECT *
FROM TransactionTable
ORDER BY customer_id

-------------------[13]-Deleting null values in TransactionsTable i.e. for product id of zero
DELETE FROM Transactions
WHERE brand IS NULL


-------------------[14]-Deleting null values for online orders in TransactionsTable
DELETE FROM Transactions
WHERE online_order IS NULL


-------------------[15]-Deleting the unused columns
SELECT * FROM CustomerDemographic
--dropping unused columns
ALTER TABLE CustomerDemographic
DROP COLUMN deceased_indicator

SELECT * 
FROM CustomerAddress
--dropping unused columns
ALTER TABLE CustomerAddress
DROP COLUMN state


 --------------------------------------BELOW ARE CLEANED TABLES THAT WOULD BE USED FOR MODEL ANALYSIS, DATA EXPLORATION, AND DATA VISUALIZATION--------------------------------------

----TABLE 1: CustomerDemographics & CustomerAddress
SELECT * 
FROM CustomerDemographic
JOIN CustomerAddress
	ON CustomerDemographic.customer_id = CustomerAddress.customer_id 


----TABLE 2: CustomerDemographics, CustomerAddress & TransactionTable
SELECT * 
FROM CustomerDemographic
JOIN CustomerAddress
	ON CustomerDemographic.customer_id = CustomerAddress.customer_id 
JOIN TransactionTable
    ON CustomerDemographic.customer_id = TransactionTable.customer_id 

	
----TABLE 3: Transactions
SELECT * 
FROM Transactions