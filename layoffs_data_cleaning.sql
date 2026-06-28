-- ============================================================
-- Project  : Layoffs Data Cleaning
-- Dataset  : layoffs (tech industry layoffs 2020–2023)
-- ============================================================
-- Objectives:
--   1. Create a staging table to preserve raw data
--   2. Remove duplicate records
--   3. Standardize inconsistent data values
--   4. Handle NULL and blank values
--   5. Drop unnecessary columns
-- ============================================================


-- ============================================================
-- STEP 0: Explore the Raw Data
-- ============================================================

SELECT *
FROM layoffs;


-- ============================================================
-- STEP 1: Create a Staging Table
-- ============================================================
-- Always work on a staging copy — never modify the raw data.
-- This ensures we can recover the original at any point.

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- Verify the staging table was populated correctly
SELECT *
FROM layoffs_staging;


-- ============================================================
-- STEP 2: Remove Duplicate Records
-- ============================================================

-- Identify duplicates using ROW_NUMBER().
-- Any row with rn > 1 is a duplicate of an earlier record.

SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, country,
                     total_laid_off, percentage_laid_off,
                     `date`, stage, funds_raised_millions
    ) AS rn
FROM layoffs_staging;

-- Preview duplicate records before removing them
WITH duplicates_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, country,
                         total_laid_off, percentage_laid_off,
                         `date`, stage, funds_raised_millions
        ) AS rn
    FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE rn > 1;

-- Example: verify a specific company appears more than once
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Note: MySQL does not support DELETE directly from a CTE.
-- Solution: create a second staging table that includes the row number,
-- then delete rows where row_num > 1.

CREATE TABLE layoffs_staging2 (
    company               TEXT,
    location              TEXT,
    industry              TEXT,
    total_laid_off        INT         DEFAULT NULL,
    percentage_laid_off   TEXT,
    `date`                TEXT,
    stage                 TEXT,
    country               TEXT,
    funds_raised_millions INT         DEFAULT NULL,
    row_num               INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Populate staging2 with row numbers assigned per duplicate group
INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, country,
                     total_laid_off, percentage_laid_off,
                     `date`, stage, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

-- Confirm duplicates are identifiable in the new table
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete all duplicate rows (keep only the first occurrence)
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Validate: this query should return 0 rows after deletion
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Record count after deduplication
SELECT COUNT(*) AS total_records
FROM layoffs_staging2;


-- ============================================================
-- STEP 3: Standardize Data Values
-- ============================================================

-- -- 3.1 Company Names 
-- Remove leading and trailing whitespace from company names

SELECT company, TRIM(company) AS company_trimmed
FROM layoffs_staging2
ORDER BY company;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- -- 3.2 Location 
-- Inspect distinct location values for inconsistencies

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

-- -- 3.3 Industry 
-- Inspect distinct industry values

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Found: 'Crypto', 'Crypto Currency', 'CryptoCurrency' — all refer to the same industry
SELECT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Normalize all Crypto-related variants to a single value
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- -- 3.4 Country 
-- Inspect distinct country values

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- Found: 'United States' and 'United States.' (trailing period)
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- Remove trailing periods from country names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Verify no remaining entries with trailing periods
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE '%.';

-- -- 3.5 Stage 
-- Inspect distinct funding stage values

SELECT DISTINCT stage
FROM layoffs_staging2
ORDER BY stage;

-- -- 3.6 Date 
-- The `date` column is stored as TEXT in MM/DD/YYYY format.
-- Convert it to a proper DATE type.

-- Preview the conversion before applying it
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y') AS parsed_date
FROM layoffs_staging2;

-- Check for any values that fail to parse (would result in NULL)
SELECT `date`
FROM layoffs_staging2
WHERE STR_TO_DATE(`date`, '%m/%d/%Y') IS NULL
  AND `date` IS NOT NULL;

-- Apply the conversion
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change the column data type from TEXT to DATE
ALTER TABLE layoffs_staging2
MODIFY `date` DATE;


-- ============================================================
-- STEP 4: Handle NULL and Blank Values
-- ============================================================

-- -- 4.1 Identify NULL/Blank Values 

-- Rows where both layoff metrics are missing (no useful data)
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Rows where industry is missing or blank
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';

-- Example: check all records for Airbnb to understand the pattern
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- -- 4.2 Convert Blank Strings to NULL 
-- Standardize empty strings to NULL across relevant columns
-- for consistent and easier handling downstream.

UPDATE layoffs_staging2
SET
    industry = NULLIF(industry, ''),
    stage    = NULLIF(stage, ''),
    country  = NULLIF(country, '');

-- -- 4.3 Impute Missing Industry Values 
-- If a company appears multiple times and one record has a known
-- industry, use it to fill in the missing value in other records.

-- Preview which rows can be imputed via self-join
SELECT t1.company, t1.industry AS missing, t2.industry AS available
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON  t1.company  = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Fill missing industry values from matching company + location records
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON  t1.company  = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Verify: Bally's had a NULL industry — confirm it is now filled
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- -- 4.4 Remove Unrecoverable Rows 
-- Rows where both total_laid_off and percentage_laid_off are NULL
-- provide no analytical value and cannot be imputed — remove them.

-- Count rows to be deleted
SELECT COUNT(*) AS rows_to_delete
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Confirm no such rows remain
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- ============================================================
-- STEP 5: Remove Unnecessary Columns
-- ============================================================
-- The `row_num` column was only needed for deduplication.
-- Drop it now that it has served its purpose.

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- ============================================================
-- Final Check: Review the Cleaned Dataset
-- ============================================================

SELECT *
FROM layoffs_staging2;

SELECT COUNT(*) AS final_record_count
FROM layoffs_staging2;
