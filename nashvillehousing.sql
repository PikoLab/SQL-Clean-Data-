/*
Cleaning Data by SQL Query
Including Data Manipulation Language(DML): ALTER, UPDATE, DELETE 

1. Standardize data format
2. Split the value and extract useful information 
3. Fill in missing value
4. Drop duplicates 


*/


-- Create Table and Import Data
CREATE TABLE IF NOT EXISTS NashvilleHousing(
	UniqueID INT,
	ParcelID VARCHAR(50),
	LandUse VARCHAR(50),
	PropertyAddress VARCHAR(250),
	SaleDate DATE,
	SalePrice VARCHAR(100),
	LegalReference VARCHAR(50),
	SoldAsVacant VARCHAR(50),
	OwnerName VARCHAR(250),
	OwnerAddress VARCHAR(250),
	Acreage DECIMAL,
	TaxDistrict VARCHAR(100),
	LandValue DECIMAL,
	BuildingValue DECIMAL,
	TotalValue  DECIMAL,
	YearBuilt DECIMAL,
	Bedrooms INT,
	FullBath INT,
	HalfBath INT
);	


COPY public.nashvillehousing FROM 'C:\csv_filepath' DELIMITER ',' csv HEADER;


-- Overview the table

SELECT * FROM nashvillehousing;

SELECT COUNT(*) FROM nashvillehousing;


-- Standardize SalePrice Format and Change Data Type as 'Numeric'

SELECT REPLACE(REPLACE(saleprice,'$',''),',','') AS new_saleprice
FROM nashvillehousing
WHERE saleprice not SIMILAR TO '[0-9]*';

UPDATE nashvillehousing
SET saleprice=REPLACE(REPLACE(saleprice,'$',''),',','') 
WHERE saleprice not SIMILAR TO '[0-9]*'
RETURNING saleprice;

ALTER TABLE nashvillehousing
ADD COLUMN saleprice_revised DECIMAL;

UPDATE nashvillehousing
SET saleprice_revised=CAST(saleprice AS NUMERIC);


-- Fill in Missing Value of Column "Property Address"

SELECT * 
FROM nashvillehousing
WHERE propertyaddress IS NULL;

SELECT A.parcelid, A.propertyaddress, B.parcelid, B.propertyaddress, COALESCE(A.propertyaddress,B.propertyaddress) 
FROM nashvillehousing A
JOIN nashvillehousing B
ON A.parcelid=B.parcelid AND A.uniqueid<>B.uniqueid
WHERE A.propertyaddress IS NULL;

UPDATE nashvillehousing 
SET propertyaddress=COALESCE(A.propertyaddress,B.propertyaddress) 
FROM nashvillehousing A
JOIN nashvillehousing B
ON A.parcelid=B.parcelid AND A.uniqueid<>B.uniqueid
WHERE A.propertyaddress IS NULL;


-- Split PropertyAddress and OwnerAddress into street,City, and State.

SELECT propertyaddress,
	   SUBSTRING(propertyaddress,1, STRPOS(propertyaddress,',')-1) AS propertyaddress_street,
	   SUBSTRING(propertyaddress, STRPOS(propertyaddress,',')+1,LENGTH(propertyaddress)) AS propertyaddress_city
FROM nashvillehousing;


SELECT owneraddress,
	   SPLIT_PART(owneraddress,',',1) AS owneraddress_street,
	   SPLIT_PART(owneraddress,',',2) AS owneraddress_city,
	   SPLIT_PART(owneraddress,',',3) AS owneraddress_state
FROM nashvillehousing;


ALTER TABLE nashvillehousing
ADD COLUMN propertyaddress_street VARCHAR(100),
ADD COLUMN propertyaddress_city VARCHAR(100),
ADD COLUMN owneraddress_street VARCHAR(100), 
ADD COLUMN owneraddress_city VARCHAR(100),
ADD COLUMN owneraddress_state VARCHAR(100);


UPDATE nashvillehousing
SET propertyaddress_street=SUBSTRING(propertyaddress,1, STRPOS(propertyaddress,',')-1),
	propertyaddress_city=SUBSTRING(propertyaddress, STRPOS(propertyaddress,',')+1,LENGTH(propertyaddress)),
	owneraddress_street=SPLIT_PART(owneraddress,',',1), 
	owneraddress_city=SPLIT_PART(owneraddress,',',2), 
	owneraddress_state=SPLIT_PART(owneraddress,',',3); 


-- Standardize Soldasvacant Format

SELECT DISTINCT soldasvacant, COUNT(*) AS counter
FROM nashvillehousing
GROUP BY soldasvacant
ORDER BY counter;

SELECT soldasvacant,
	   CASE WHEN soldasvacant='Y' THEN 'Yes'
			WHEN soldasvacant='N' THEN 'No'
			ELSE soldasvacant END AS soldasvacant_revised
FROM nashvillehousing;


UPDATE nashvillehousing
SET soldasvacant=CASE WHEN soldasvacant='Y' THEN 'Yes'
					  WHEN soldasvacant='N' THEN 'No'
					  ELSE soldasvacant END
RETURNING soldasvacant;


-- Remove Duplicates 

WITH CTE AS (SELECT *, 
			 ROW_NUMBER()OVER(PARTITION BY parcelid, propertyaddress,saledate,saleprice,LegalReference 
			 				  ORDER BY uniqueid) AS row_num
			 FROM nashvillehousing)
SELECT * 
FROM CTE
WHERE row_num>1
ORDER BY uniqueid;


DELETE
FROM nashvillehousing 
WHERE uniqueid IN (SELECT uniqueid 
				   FROM
				 	   (SELECT *, 
					    ROW_NUMBER()OVER(PARTITION BY parcelid, propertyaddress,saledate,saleprice,LegalReference 
			 				  		  ORDER BY uniqueid) AS row_num
			 		    FROM nashvillehousing) temp
			       WHERE row_num>1);

-- Delete Unsued Columns

ALTER TABLE nashvillehousing 
DROP COLUMN taxdistrict 
