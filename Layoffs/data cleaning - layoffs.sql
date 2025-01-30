-- DATA CLEANING

SELECT * FROM layoffs;

create table layoffs_staging LIKE layoffs; -- CREATE A TABLE WITH SAME Str. as of layoffs

SELECT * FROM layoffs_staging;
INSERT layoffs_staging SELECT * FROM layoffs;

SELECT *, 
row_number() OVER(partition by company,industry, total_laid_off, percentage_laid_off, 'date') as row_num
FROM layoffs_staging;

with duplicate_cte as (
SELECT *, 
row_number() OVER(partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT * FROM duplicate_cte
where row_num > 1;

with duplicate_cte as (
SELECT *, 
row_number() OVER(partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
DELETE FROM duplicate_cte -- cannot update a CTE
where row_num > 1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;
INSERT INTO layoffs_staging2
SELECT *, 
row_number() OVER(partition by company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

SELECT * FROM layoffs_staging2
WHERE row_num > 1;

DELETE FROM layoffs_staging2
WHERE row_num > 1;


-- Standardizing Data

SELECT company, trim(company) FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = trim(company);

SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Check each column and overlook all of them to check if they have any error in them.
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
SELECT DISTINCT TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States% ';
ROLLBACK;

-- To perform or implement time series date should not be in text format
SELECT `date` FROM layoffs_staging2;
SELECT `date`, STR_TO_DATE(`date`,'%m/%d/%Y/')
FROM layoffs_staging2;
UPDATE  layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y/');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` date;

-- Handling NULL and BLANK values

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; -- These records are of no use
-- So we can remove them, but thats step 4

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = "";

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'
OR company = 'Carvana'
OR company = 'Juul'
OR company = 'Bally''s Interactive';

SELECT * FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE ( t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

SELECT t1.industry, t2.industry FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE ( t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE ( t1.industry IS NULL)
AND t2.industry IS NOT NULL;

-- REMOVE column or row that is not required

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * FROM layoffs_staging2;