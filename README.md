# 🧹 Layoffs Data Cleaning — MySQL

A structured data cleaning project using **MySQL**, applied to a real-world dataset of tech industry layoffs from 2020 to 2023.

---

## 📌 Project Overview

Raw data is rarely analysis-ready. This project demonstrates a complete data cleaning workflow in SQL, transforming a messy dataset into a clean, reliable one — ready for exploratory analysis or visualization.

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
| MySQL 8.0 | Data cleaning & transformation |
| SQL (DDL + DML) | Table creation, updates, deletes |

---

## 🔄 Cleaning Steps

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

## 📁 Project Structure

```
layoffs-data-cleaning/
│
├── layoffs.csv                  # Raw dataset
├── layoffs_data_cleaning.sql    # Full cleaning script (commented)
└── README.md                    # Project documentation
```

---

## 💡 Key SQL Concepts Used

- `ROW_NUMBER()` window function
- CTEs (Common Table Expressions)
- Self JOIN for data imputation
- `STR_TO_DATE()` for type conversion
- `NULLIF()`, `TRIM()`, `TRIM(TRAILING ...)`
- `ALTER TABLE` / `UPDATE` / `DELETE`

---

## 👤 Author

**Khaled Nabil**
- GitHub: [@KhaledNabil10](https://github.com/KhaledNabil10)
