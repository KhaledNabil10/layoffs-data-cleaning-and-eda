# 🧹 Layoffs Data Cleaning & EDA — MySQL

A structured data cleaning and exploratory data analysis project using **MySQL**, applied to a real-world dataset of tech industry layoffs from 2020 to 2023.

---

## 📌 Project Overview

Raw data is rarely analysis-ready. This project covers two phases:

1. **Data Cleaning** — transforming a messy dataset into a clean, reliable one
2. **Exploratory Data Analysis (EDA)** — uncovering trends, patterns, and insights from the cleaned data

---

## 📂 Dataset

- **File:** `layoffs.csv`
- **Source:** [Alex The Analyst](https://www.youtube.com/@AlexTheAnalyst) — YouTube Data Analyst Bootcamp
- **Coverage:** Tech industry layoffs (2020–2023)
- **Fields:** Company, Location, Industry, Total Laid Off, Percentage Laid Off, Date, Stage, Country, Funds Raised (Millions)

---

## 🛠️ Tools Used

| Tool | Purpose |
|------|---------|
| MySQL 8.0 | Data cleaning & analysis |
| SQL (DDL + DML) | Table creation, updates, deletes, queries |

---

## 📁 Project Structure

```
layoffs-data-cleaning-and-eda/
│
├── layoffs.csv                  # Raw dataset
├── layoffs_data_cleaning.sql    # Phase 1: Full cleaning script
├── layoffs_eda.sql              # Phase 2: Exploratory analysis
└── README.md                    # Project documentation
```

---

## 🔄 Phase 1: Data Cleaning Steps

### 1. 🗂️ Create a Staging Table
Preserved the raw data by working entirely on a copy — ensuring the original dataset remains untouched and recoverable.

### 2. 🔍 Remove Duplicate Records
Used `ROW_NUMBER() OVER (PARTITION BY ...)` to identify and remove exact duplicate rows. Since MySQL doesn't support deleting directly from a CTE, a second staging table was created to enable the deletion.

### 3. ✏️ Standardize Data Values
- Trimmed leading/trailing whitespace from company names
- Unified `Crypto`, `Crypto Currency`, and `CryptoCurrency` → `Crypto`
- Removed trailing periods from country names (e.g., `United States.` → `United States`)
- Converted the `date` column from `TEXT` to proper `DATE` type using `STR_TO_DATE()`

### 4. 🔧 Handle NULL and Blank Values
- Converted empty strings to `NULL` using `NULLIF()` for consistent handling
- Used a self-join to impute missing `industry` values from other records with the same company and location
- Deleted rows where both `total_laid_off` and `percentage_laid_off` were `NULL` (no analytical value)

### 5. 🗑️ Remove Unnecessary Columns
Dropped the temporary `row_num` column used during deduplication.

---

## 🔍 Phase 2: Exploratory Data Analysis (EDA)

| # | Analysis |
|---|----------|
| 1 | Top 10 largest single layoff events |
| 2 | Companies that laid off 100% of their workforce |
| 3 | Total layoffs per company (all-time) |
| 4 | Layoffs by industry |
| 5 | Layoffs by country — total & average |
| 6 | Layoffs by year |
| 7 | Layoffs by funding stage |
| 8 | Monthly layoff trend |
| 9 | Rolling cumulative total over time |
| 10 | Top 5 companies by layoffs per year (DENSE_RANK) |
| 11 | Funding raised vs. layoff percentage by company |
| 12 | Overall shutdown rate & average layoff percentage |

---

## 💡 Key SQL Concepts Used

- `ROW_NUMBER()` and `DENSE_RANK()` window functions
- `SUM() OVER()` for rolling totals
- CTEs (Common Table Expressions) — including chained CTEs
- Self JOIN for data imputation
- `STR_TO_DATE()` for type conversion
- `DATE_FORMAT()` for time-based grouping
- `NULLIF()`, `TRIM()`, `TRIM(TRAILING ...)`
- `CASE WHEN` for conditional aggregation
- `ALTER TABLE` / `UPDATE` / `DELETE`

---
