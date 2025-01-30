-- Exploratory Data Analysis

SELECT * FROM layoffs_staging2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off) FROM layoffs_staging2;
SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

SELECT `date`, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY `date`
ORDER BY 1 DESC;

SELECT YEAR(`date`), sum(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT Stage, sum(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

SELECT SUBSTRING(`date`,1,7) `Month`, sum(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1;

SELECT SUBSTRING(`date`,1,7) `Month`, sum(total_laid_off) OVER (PARTITION BY SUBSTRING(`date`,1,7))
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL;
-- GROUP BY `Month`
-- ORDER BY 1;

WITH rolling_sum AS
(SELECT SUBSTRING(`date`,1,7) `Month`, sum(total_laid_off) as total_laid
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1)

SELECT `Month`,total_laid, sum(total_laid) OVER(ORDER BY `Month`) AS rolling_total
FROM rolling_sum;

SELECT 
    SUBSTRING(`date`, 1, 7) AS `Month`,
    SUM(total_laid_off) AS total_laid,
    SUM(SUM(total_laid_off)) OVER (ORDER BY SUBSTRING(`date`, 1, 7)) AS rolling_total
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`;

SELECT 
    SUBSTRING(`date`, 1, 7) AS `Month`,
    SUM(SUM(total_laid_off)) OVER (PARTITION BY SUBSTRING(`date`, 1, 7) ORDER BY SUBSTRING(`date`, 1, 7)) AS rolling_total
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL;

with company_rank AS (
SELECT company, year(`date`) AS years, sum(total_laid_off) AS total_laid
FROM layoffs_staging2
GROUP BY company, year(`date`)
ORDER BY 3 DESC),
company_ranking AS 
(SELECT company, years, total_laid, 
DENSE_RANK() OVER(partition by years ORDER BY total_laid DESC) AS ranking
FROM company_rank
WHERE years IS NOT NULL)
SELECT * FROM company_ranking
WHERE ranking <= 5
;