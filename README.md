# StackOverflow-Analysis-2025
# Stack Overflow Developer Survey 2025 Analysis

![Python](https://img.shields.io/badge/Python-pandas-blue?style=for-the-badge&logo=python)
![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-red?style=for-the-badge&logo=microsoftsqlserver)
![Excel](https://img.shields.io/badge/Excel-Validation-green?style=for-the-badge&logo=microsoftexcel)
![Power BI](https://img.shields.io/badge/Tools-Power%20BI-yellow?style=for-the-badge&logo=powerbi)
![Status](https://img.shields.io/badge/Status-Completed-green?style=for-the-badge)

---

## 📌 1. Project Overview

This project analyzes the **Stack Overflow Developer Survey 2025**, one of the largest annual surveys of software developers. The dataset contains **49,191 respondents** from **176 countries** and **172 columns** covering technologies used, job roles, experience, salary, job satisfaction and AI tool adoption.

The analysis follows a full workflow with four tools:
*   **Python (pandas):** data cleaning and reshaping.
*   **SQL Server (T-SQL):** data storage and analytical queries.
*   **Excel:** validation of record counts and averages with pivot tables.
*   **Power BI:** an interactive 4-page dashboard.

### 🎯 Requirements & Objectives
The objective is to turn raw survey data into a dashboard that shows which technologies and roles matter most for developers today, how pay varies by experience and country, and how AI tools are being adopted.

---

## 📊 2. Key Metrics & Analysis Focus

*   **Respondents:** number of unique survey participants.
*   **Technology usage (% of answerers):** share of people who answered a question and use a given technology.
*   **Want-to-use rate:** share of people who want to use a technology next.
*   **Median yearly salary (USD):** median converted compensation, outliers removed.
*   **Average job satisfaction:** mean score on the 0 to 10 scale.
*   **Daily AI usage %:** share of respondents using AI tools every day.
*   **AI sentiment:** distribution from very favorable to very unfavorable.

### 🔍 Core Business Questions to Answer
*   Which languages, databases and platforms are most used, and which are developers most eager to adopt?
*   How does median salary change with years of experience, developer role and country?
*   Who uses AI tools daily, and how do developers feel about them?

---

## 🛠️ 3. Step-by-Step Process

### Step 1: Business Understanding
*   Reviewed the survey structure and defined the questions above.
*   Chose to report percentages among **respondents who answered each question**, because many people skip questions.

### Step 2: Data Cleaning with Python
*   Loaded `survey_results_public.csv` (49,191 rows, 172 columns) with pandas and kept the 16 columns needed for the analysis.
*   Shortened long labels (for example "United States of America" became "USA") and standardized education and employment categories.
*   Built **experience bands** (0-2, 3-5, 6-10, 11-20, 20+ years) and an age sort helper.
*   **Salary outliers:** kept `ConvertedCompYearly` values from $1,000 up to the IQR upper bound of **$244,234**, which leaves **22,161** of 23,947 salary rows in `CompClean`.
*   Split multi-select answers (languages, databases, platforms, web frameworks, developer roles) separated by `;` into long tables, one row per respondent and item.
*   Exported three clean tables: `respondents` (49,191 rows), `tech_long` (921,671 rows) and `roles_long` (43,680 rows).

### Step 3: SQL Server Loading
*   Created the three tables in a `so2025` database with all survey columns nullable, because blanks are legitimate skipped answers.
*   Loaded the cleaned CSVs with `BULK INSERT` and verified the row counts.
*   Added indexes on `ResponseId` and on the technology category columns for faster joins.

### Step 4: SQL Analysis
Nine queries (Q1 to Q9) covering:
1.  Dataset size and salary coverage.
2.  Top 10 languages, as a % of respondents who answered.
3.  Used vs wanted gap by language.
4.  Top databases and platforms.
5.  Median salary by country (countries with at least 100 salary responses).
6.  Job satisfaction by experience band.
7.  Daily AI use by age group.
8.  Average salary by language.
9.  Top roles among professional developers.

### Step 5: Excel Validation
*   Opened `respondents.csv` in Excel and built pivot tables for record counts and average job satisfaction by experience band.
*   Compared them with the SQL results to confirm the pipeline was consistent.

### Step 6: Data Modeling and DAX in Power BI
*   Connected Power BI to the three tables. `respondents` is the central table with one-to-many relationships to `tech_long` and `roles_long` (the role relationship filters in both directions so salary can be split by role).
*   Created DAX measures: `Respondents`, `Median Salary`, `Salary Rows`, `Median Salary Min100` (blank when a group has fewer than 100 salary responses), `Avg Job Sat`, `Tech Users`, `Tech Answerers`, `% of Answerers` and `Daily AI %`.

### Step 7: Dashboard Design & Visualization
Designed and completed 4 dashboard pages in Power BI:
1.  **Overview:** KPI cards (respondents, median salary, average job satisfaction), top 10 countries by respondents, and slicers for age, experience and country.
2.  **Technology Trends:** used vs wanted comparison for the top 10 technologies with a category slicer (language, database, platform, web framework), plus a table of the most wanted technologies.
3.  **Compensation:** median salary by country, by developer role and by years of experience.
4.  **AI Adoption:** daily AI use by age group, a summary card, and sentiment toward AI tools.

---

## 💡 4. Key Findings

*   **Most used languages:** JavaScript (66.3%), HTML/CSS (62.2%), SQL (58.8%) and Python (58.1%).
*   **Most wanted languages:** Python (45.9%) and SQL (41.6%) lead the list.
*   **Rising interest:** Rust is used by 14.9% but wanted by 34.2%, and Go is used by 16.5% but wanted by 27.4%.
*   **Databases:** PostgreSQL (14,529 users), MySQL (10,581) and SQLite (9,798) lead.
*   **Salary:** the overall median is **$74,249**. The USA ($139K), Israel ($137.7K) and Switzerland ($136.4K) have the highest medians among countries with at least 100 salary responses.
*   **Experience:** median salary rises from **$25.3K** (0-2 years) to **$104.4K** (20+ years).
*   **Roles:** engineering managers ($116.9K), senior executives ($115.5K) and product managers ($100K) have the highest median salaries.
*   **AI usage:** **47.1%** of respondents use AI tools daily, peaking at **51.1%** among ages 25 to 34 and falling to **22.3%** for ages 65 and over.
*   **AI sentiment:** about 60% of respondents who answered are favorable or very favorable toward AI tools, and about 20% are unfavorable or very unfavorable.
*   **Job satisfaction:** the average is **7.20** out of 10.

### Recommendations
*   Prioritize Python, SQL and TypeScript for training, since they combine high usage with high want-to-use rates.
*   Track Rust and Go as emerging skills, because their desired share is well above their current usage.
*   Include AI tool literacy in developer skills programs, given daily use by nearly half of respondents.

---

## ⚠️ 5. Limitations
*   The survey is self-selected and self-reported, so it doesn't represent all developers worldwide.
*   Many respondents skip questions, so every percentage uses only respondents who answered that question.
*   Respondents can select several roles and technologies, so category percentages overlap and don't add up to 100%.
*   Salary is converted to USD and excludes values below $1,000 and above $244,234. Country comparisons include only countries with at least 100 salary responses.

---

## 📂 6. Project Directory Structure

```text
├── data/                  # Download link for the raw survey (file not included, over 100 MB)
├── python/                # 01_clean_stackoverflow_2025.py
├── sql/                   # Table creation, BULK INSERT and T-SQL analysis queries
├── excel/                 # Validation pivot table screenshot
├── powerbi/               # so2025_dashboard.pbix
├── outcome/               # Visual captures of the 4 dashboard pages
└── README.md              # Project documentation
```

**Data source:** [Stack Overflow Annual Developer Survey](https://survey.stackoverflow.co/). Download the 2025 results and rename the CSV to `survey_results_public.csv` before running the Python script.
