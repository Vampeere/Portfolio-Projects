-- Data Cleaning

-- This is the process of cleaning the data and putting it in a more usable format to ensure that there is no issue 
-- when using it for visualizations or using it, it is useful and has no issues with it

SELECT *
FROM layoffs;


-- 1. Remove Duplicates
-- 2. Standardizze the Data
-- 3. Null Values or Blank Values
-- 4. Remove Unnecessary Columns and Rows


-- First we create a duplicate of the dataset, just incase there's any mihaps or errors where we end up messing with the original data
-- This step creates all the rows in the layoffs dataset and insert them into the layoffs_staging one
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

-- This will insert all the data from layoffs dataset and insert into the layoffs_staging dataset we created
INSERT layoffs_staging
SELECT * 
FROM layoffs;



-- 1. Remove Duplicates
# First let's check for duplicates
-- We'll make a row number and match it to the columns in the table

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, total_laid_off, 'date',
percentage_laid_off,industry, source, stage, funds_raised, 
country, 'date_added') AS row_num
FROM layoffs_staging;


-- Next we wanna filter where the row number is greater than 2. If it has 2 or above, there's an issue/duplicate


WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, total_laid_off, 'date',
percentage_laid_off,industry, source, stage, funds_raised, 
country, 'date_added') AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


SELECT *
FROM layoffs_staging
WHERE company = 'Bolt';



-- Since we're unable to just delete the duplicates automatically, we'll create a duplicate of the layoff_staging, 
-- Create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column

-- We can right click on the layoffs staging table, copy the create statement to clipboard, paste it, rename the new table
-- 
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` text,
  `country` text,
  `date_added` text,
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- This inserts everything in the layoffs_staging into the layoffs_staging2
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location, total_laid_off, 'date',
percentage_laid_off,industry, source, stage, funds_raised, 
country, 'date_added') AS row_num
FROM layoffs_staging;

-- This deletes the dupes from the table
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;


-- Here we check to make sure everything is deleted
SELECT * 
FROM layoffs_staging2;



-- 2. Standardizing Data
-- This means to find issues in your data, and fixing it

-- We'll start by trimming the tables. TRIM is used to remove the white spaces in the beginning and
-- end of the tables

SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Then we update the company to be the same as the Trimmed version
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Next we'll look at the industry to make sure there aren't any multiple industries with the same name
-- but spelt different or arranged differently and so on. 

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

-- If there are columns that are similar but spelt wrongly, we can fix it. Using Crypto as an example, lets 
-- say that there was multiple columns spelt the same where one was "Crypto" and others were "Crypto Currency",
-- we fix it by;

-- Below will scan to check for columns that are spelt as Crypto or start with Crypto
-- SELECT *
-- FROM layoffs_staging2
-- WHERE company LIKE 'Crypto%';

-- After finding the errors, we then update it by:
-- UPDATE layoffs_staging2
-- SET industry = Crypto
-- WHERE industry LIKE 'Crypto%';

-- IF there's a column where a variable doesn't have a dead space at the end but some sort of symbol, we can fix
-- that by TRIM TRAILING. For example, lets say we have (Brazil) and (Brazil-) in the same column

-- Find  first. 
-- SELECT DISTINCT(country)
-- FROM layoffs_staging2
-- ORDER BY 1;

-- After finding it, we need to TRIM TRAIL it
-- SELECT DISTINCT country, TRIM(TRAILING '-' FROM country)
-- FROM layoffs_staging2;

-- Then update the table 
-- UPDATE layoffs_staging2
-- SET country = TRIM(TRAILING '-' FROM country
-- WHERE country LIKE 'Brazil%';


SELECT *
FROM layoffs_staging2;

-- To change the date column from text column to a date column, we can do it like this; 

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update the table
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); 


SELECT `date_added`,
STR_TO_DATE(`date_added`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update the table
UPDATE layoffs_staging2
SET `date_added` = STR_TO_DATE(`date_added`, '%m/%d/%Y'); 


-- After that, we can change them to date columns (only on staging table, never on raw table)
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date_added` DATE;

SELECT *
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL ;


SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '' ;

SELECT *
FROM layoffs_staging2
WHERE company = 'Appsmith';


-- 3. Look at Null Values
-- First we change all the blank values to NULL values for easier calculations and updates
SELECT *
FROM layoffs_staging2;


UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = '';

-- This updates multiple columns at the same time
UPDATE layoffs_staging2
SET 
    company = NULLIF(TRIM(company), ''),
	location = NULLIF(TRIM(location), ''),
	percentage_laid_off = NULLIF(TRIM(percentage_laid_off), ''),
	industry = NULLIF(TRIM(industry), ''),
    funds_raised = NULLIF(TRIM(funds_raised), '')
WHERE 
    TRIM(company) = ''
    OR TRIM(location) = ''
    OR TRIM(percentage_laid_off) = ''
    OR TRIM(industry) = ''
	OR TRIM(funds_raised) = '';



SELECT *
FROM layoffs_staging2
WHERE total_laid_off = ''; 

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry is NULL
OR Industry = '';


SELECT *
FROM layoffs_staging2
WHERE company = 'Product Hunt' ; 

SELECT *
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL
ORDER BY 1;



-- We're deleting these columns because although they said that they had layoffs, there's no data showing that they did. 
-- If they had a total number of employees and percentage laid off, we could calculate the total laid off. 
-- So for that reason, since we'll be working with total_laid_off and percentage_laid_off columns, I've opted to delete them.
DELETE 
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

SELECT *
FROM layoffs_staging2;

-- Next is to drop the row_num column as we won't be needing it for the upcoming calculations
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


SELECT *
FROM layoffs_staging2;



