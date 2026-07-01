-- ============================================================
-- Project  : Layoffs Exploratory Data Analysis (EDA)
-- Dataset  : layoffs_staging2 (cleaned tech layoffs 2020–2023)
-- Author   : Khaled Nabil
-- GitHub   : https://github.com/KhaledNabil10
-- ============================================================
-- Objectives:
--   1. Explore overall layoff magnitudes
--   2. Analyze layoffs by company, industry, country, and stage
--   3. Identify trends over time (monthly + rolling total)
--   4. Rank top companies per year by layoffs
--   5. Explore relationship between funding and layoffs
-- ============================================================


-- ============================================================
-- STEP 0: Preview the Cleaned Dataset
-- ============================================================

SELECT *
FROM layoffs_staging2;


-- ============================================================
-- STEP 1: Overall Layoff Magnitudes
-- ============================================================

-- Top 10 single layoff events by total headcount
SELECT company, total_laid_off, percentage_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC
LIMIT 10;

-- Maximum values for both layoff metrics
SELECT
    MAX(total_laid_off)        AS max_total_laid_off,
    MAX(percentage_laid_off)   AS max_percentage_laid_off
FROM layoffs_staging2;


-- ============================================================
-- STEP 2: Companies That Laid Off 100% of Their Workforce
-- ============================================================

-- Sorted by headcount — shows which large companies shut down completely
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Sorted by funding — shows well-funded companies that still shut down
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- ============================================================
-- STEP 3: Layoffs by Company
-- ============================================================

-- Total layoffs per company (all-time)
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY total_laid_off DESC;


-- ============================================================
-- STEP 4: Date Range of the Dataset
-- ============================================================

SELECT
    MIN(`date`) AS earliest_date,
    MAX(`date`) AS latest_date
FROM layoffs_staging2;


-- ============================================================
-- STEP 5: Layoffs by Industry
-- ============================================================

-- Which industries were hit the hardest?
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY total_laid_off DESC;


-- ============================================================
-- STEP 6: Layoffs by Country
-- ============================================================

-- Total layoffs per country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY total_laid_off DESC;

-- Average layoffs per country
-- Useful to compare impact relative to company size
SELECT country, ROUND(AVG(total_laid_off), 2) AS avg_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY avg_laid_off DESC;


-- ============================================================
-- STEP 7: Layoffs by Year
-- ============================================================

SELECT YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY total_laid_off DESC;


-- ============================================================
-- STEP 8: Layoffs by Funding Stage
-- ============================================================

-- Which funding stages had the most layoffs?
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY total_laid_off DESC;


-- ============================================================
-- STEP 9: Monthly Layoff Trend
-- ============================================================

-- Total layoffs per month — shows seasonality and spikes
SELECT
    DATE_FORMAT(`date`, '%Y-%m') AS `month`,
    SUM(total_laid_off)          AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;


-- ============================================================
-- STEP 10: Rolling Total of Layoffs Over Time
-- ============================================================
-- Cumulative sum month by month — shows the overall growth trend
-- Each month's value includes all layoffs from the start up to that month.

WITH monthly_totals AS (
    SELECT
        DATE_FORMAT(`date`, '%Y-%m') AS `month`,
        SUM(total_laid_off)          AS total_laid_off
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL
    GROUP BY `month`
    ORDER BY `month` ASC
)
SELECT
    `month`,
    total_laid_off,
    SUM(total_laid_off) OVER (ORDER BY `month`) AS rolling_total
FROM monthly_totals;


-- ============================================================
-- STEP 11: Top 5 Companies by Layoffs Per Year
-- ============================================================
-- Uses two CTEs:
--   1. Aggregate total layoffs per company per year
--   2. Rank companies within each year using DENSE_RANK()

WITH company_year AS (
    SELECT
        company,
        YEAR(`date`)            AS `year`,
        SUM(total_laid_off)     AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
company_year_ranking AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY `year`
            ORDER BY total_laid_off DESC
        ) AS ranking
    FROM company_year
    WHERE `year` IS NOT NULL
)
SELECT *
FROM company_year_ranking
WHERE ranking <= 5;


-- ============================================================
-- STEP 12: Funding vs. Layoff Percentage by Company
-- ============================================================
-- Explores whether higher funding correlates with larger layoffs.
-- Companies sorted by total funding raised (descending).

SELECT
    company,
    SUM(funds_raised_millions) AS total_funds_raised,
    ROUND(AVG(percentage_laid_off), 2) AS avg_percentage_laid_off
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
  AND percentage_laid_off IS NOT NULL
GROUP BY company
ORDER BY total_funds_raised DESC, avg_percentage_laid_off ASC;

-- ============================================================
-- STEP 13: Company Survival Rate & Overall Shutdown Stats
-- ============================================================
-- Shows how many companies shut down completely (percentage_laid_off = 1)
-- vs total companies, and the overall average layoff percentage.

SELECT
    COUNT(DISTINCT company) AS total_companies,
    SUM(CASE WHEN percentage_laid_off = 1 THEN 1 ELSE 0 END) AS shutdowns,
    ROUND(AVG(percentage_laid_off) * 100, 2) AS avg_layoff_pct
FROM layoffs_staging2;
