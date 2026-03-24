-- EDA Exploratory Data Analysis

-- Here we are just going to explore the data and find trends or patterns or anything interesting like outliers

-- Normally when you start the EDA process you have some idea of what you're looking for

-- With this info we are just going to look around and see what we find!

SELECT *
FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;


-- Here, I'm updating the "percentage_laid_off" column to INT by removing the % signs
UPDATE layoffs_staging2
SET percentage_laid_off = REPLACE(percentage_laid_off, '%', '')
WHERE percentage_laid_off LIKE '%';

-- Convert column type from TEXT → DECIMAL
ALTER TABLE layoffs_staging2
MODIFY COLUMN percentage_laid_off DECIMAL(5,2);


SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 100
ORDER BY total_laid_off DESC;

-- Here I'm altering the table and changing it's type to numeric
ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off INT;


SELECT *
FROM layoffs_staging2
ORDER BY 1;

SELECT company, location, total_laid_off, date, percentage_laid_off,
       industry, source, stage, funds_raised, country, date_added,
       COUNT(*) AS duplicate_count
FROM layoffs_staging2
GROUP BY company, location, total_laid_off, date, percentage_laid_off,
         industry, source, stage, funds_raised, country, date_added
HAVING COUNT(*) > 1;


SELECT *,
       ROW_NUMBER() OVER (
         PARTITION BY company, location, total_laid_off, date, percentage_laid_off,
                      industry, source, stage, funds_raised, country, date_added
         ORDER BY company
       ) AS rn
FROM layoffs_staging2;


DELETE FROM layoffs_staging2
WHERE (
    company,
    location,
    total_laid_off,
    date,
    percentage_laid_off,
    industry,
    source,
    stage,
    funds_raised,
    country,
    date_added
) IN (
    SELECT company, location, total_laid_off, date, percentage_laid_off,
           industry, source, stage, funds_raised, country, date_added
    FROM (
        SELECT 
            company,
            location,
            total_laid_off,
            date,
            percentage_laid_off,
            industry,
            source,
            stage,
            funds_raised,
            country,
            date_added,
            ROW_NUMBER() OVER (
                PARTITION BY company, location, total_laid_off, date, percentage_laid_off,
                             industry, source, stage, funds_raised, country, date_added
                ORDER BY company
            ) AS row_num
        FROM layoffs_staging2
    ) t
    WHERE t.row_num > 1
);

SELECT *
FROM layoffs_staging2;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 100
ORDER BY funds_raised DESC;

-- This shows the total amount of people that got laid off in every company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;


-- Next we check the date range of the layoffs
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- This shows what industry got hit the most during the layoffs
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


SELECT *
FROM layoffs_staging2;


-- This shows the total amount of people that got laid off in every country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- This shows the total amount of people that got laid off in every year from 2023-2025
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- This shows the total amount of people that got laid off in every stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- This shows the percentage laid off amount of people that got laid off in every country
SELECT country, AVG(percentage_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;



-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(date,1,7) AS `MONTH`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(date,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;


With Rolling_Total AS
(
SELECT SUBSTRING(date,1,7) AS `MONTH`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(date,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)

SELECT `MONTH`, total_laid_off,
SUM(total_laid_off) OVER(ORDER BY `MONTH` )
FROM Rolling_Total;

-- This shows the companies that laid off, the year and the sum (total laid off)
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, `date`
ORDER BY 3 DESC;

-- Next we create CTE to rank the various total laid off by the most amount of laid offs
WITH Company_Year (Company, Years, Total_Laid_Off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS ( 
SELECT *,
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years is NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
;


