/*

This script demonstrates the use of SQL for cleaning a dataset from the Nashville housing data from https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx
We will convert date, populate NULL values by exploring the dataset, create seperate columns for address; city; and state, and delete duplicate data. 

*/

SELECT *
  FROM portfolio_project.dbo.nashville_housing
 ORDER BY UniqueID

--------------------------------------------------------------------------------------------------------------------------

-- Fixing the date

SELECT SaleDate
  FROM portfolio_project.dbo.nashville_housing  

-- There are useless hour:minute:second:millisecond extensions on every date, cluttering our data.

ALTER TABLE portfolio_project.dbo.nashville_housing 
	ALTER COLUMN SaleDate date

--------------------------------------------------------------------------------------------------------------------------

-- Some property addresses are missing. We have noticed that for some other address listings that have the same parcelId, they all have the same address.
-- We will replace NULL property addresses with ones with the same ParcelID

SELECT ParcelID,
	   PropertyAddress,
	   UniqueID
  FROM portfolio_project.dbo.nashville_housing
 WHERE PropertyAddress IS NULL


-- Listings with the same ParcelID still have a different UniqueID so we will self join using UniqueID not equal to match missing parcels to existing ones

SELECT a.ParcelID,
	   a.PropertyAddress,
	   b.ParcelID,
	   b.PropertyAddress,
	   ISNULL(a.PropertyAddress, b.PropertyAddress)
  FROM portfolio_project.dbo.nashville_housing a
  JOIN portfolio_project.dbo.nashville_housing b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID != b.UniqueID
 WHERE a.PropertyAddress IS NULL

UPDATE a
   SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
  FROM portfolio_project.dbo.nashville_housing a
  JOIN portfolio_project.dbo.nashville_housing b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID != b.UniqueID
 WHERE a.PropertyAddress IS NULL 


--------------------------------------------------------------------------------------------------------------------------

-- Now we will format the address column so that we have seperate columns for city, state, address

SELECT PropertyAddress
  FROM portfolio_project.dbo.nashville_housing
 
-- We will use the fact that all our addresses are of the form: address , city
-- and pick out the address from before the comma and the city after. Our only state is Tennessee

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
       SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
  FROM portfolio_project.dbo.nashville_housing


ALTER TABLE nashville_housing
        ADD PropertySplitAddress NVARCHAR(255);

UPDATE nashville_housing
   SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE nashville_housing
		ADD PropertySplitCity NVARCHAR(255);

UPDATE nashville_housing
   SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


SELECT PropertyAddress,
	   PropertySplitAddress,
	   PropertySplitCity
  FROM portfolio_project.dbo.nashville_housing

--------------------------------------------------------------------------------------------------------------------------

-- Time to delete duplicate rows

-- First we need to check for duplicates

SELECT ParcelID,
       PropertyAddress,
	   SaleDate,
	   LegalReference,
	   COUNT(*) AS cnt
  FROM portfolio_project.dbo.nashville_housing
 GROUP BY ParcelID, PropertyAddress, SaleDate, LegalReference
 HAVING COUNT(*) > 1

-- We chose this many and these specific columns to span the set of possible duplicates given the data

SELECT *
  FROM portfolio_project.dbo.nashville_housing
 WHERE UniqueID NOT IN 
 (
	SELECT MAX(UniqueID)
	  FROM portfolio_project.dbo.nashville_housing
	 GROUP BY ParcelID, PropertyAddress, SaleDate, LegalReference
 )

-- The number of rows matches the number of duplicate data
-- Now we delete

DELETE FROM portfolio_project.dbo.nashville_housing
	  WHERE UniqueID NOT IN 
	  (
		  SELECT MAX(UniqueID)
		    FROM portfolio_project.dbo.nashville_housing
		   GROUP BY ParcelID, PropertyAddress, SaleDate, LegalReference
	  )

-- Running our first query now returns no duplicates