-- =====================================================================
-- Stack Overflow Developer Survey 2025 - analysis queries (T-SQL)
-- Database: so2025   Tables: respondents, tech_long, roles_long
-- Run one query at a time (highlight it and press F5 in SSMS).
-- Percentages use only respondents who ANSWERED the question.
-- =====================================================================

USE so2025;
GO

-- Q1. Size of the data -------------------------------------------------
-- Result: 49,191 respondents | 22,161 with clean salary | 176 countries
SELECT COUNT(*)                AS respondents,
       COUNT(CompClean)        AS with_clean_salary,
       COUNT(DISTINCT Country) AS countries
FROM dbo.respondents;

-- Q2. Top 10 languages used (% of people who answered) -----------------
-- Result: JavaScript 66.3%, HTML/CSS 62.2%, SQL 58.8%, Python 58.1%
SELECT TOP 10 Technology,
       COUNT(DISTINCT ResponseId) AS users,
       ROUND(100.0 * COUNT(DISTINCT ResponseId) /
             (SELECT COUNT(DISTINCT ResponseId) FROM dbo.tech_long
              WHERE Category = 'Language' AND Status = 'Used'), 1) AS pct_of_answerers
FROM dbo.tech_long
WHERE Category = 'Language' AND Status = 'Used'
GROUP BY Technology
ORDER BY users DESC;

-- Q3. Used vs wanted: which languages are gaining interest? ------------
-- Result: Rust 14.9% used vs 34.2% wanted, Go 16.5% vs 27.4%
WITH base AS (
  SELECT Status, COUNT(DISTINCT ResponseId) AS n
  FROM dbo.tech_long WHERE Category = 'Language' GROUP BY Status
),
counts AS (
  SELECT Technology, Status, COUNT(DISTINCT ResponseId) AS c
  FROM dbo.tech_long WHERE Category = 'Language' GROUP BY Technology, Status
)
SELECT TOP 15 u.Technology,
       ROUND(100.0 * u.c / bu.n, 1)                       AS pct_used,
       ROUND(100.0 * w.c / bw.n, 1)                       AS pct_want,
       ROUND(100.0 * w.c / bw.n - 100.0 * u.c / bu.n, 1)  AS want_minus_used
FROM counts u
JOIN counts w ON w.Technology = u.Technology AND w.Status = 'Want'
JOIN base bu  ON bu.Status = 'Used'
JOIN base bw  ON bw.Status = 'Want'
WHERE u.Status = 'Used' AND u.c >= 500
ORDER BY want_minus_used DESC;

-- Q4. Top databases and platforms used ---------------------------------
-- Result: PostgreSQL 14,529 | MySQL 10,581 | SQLite 9,798
SELECT Category, Technology, COUNT(DISTINCT ResponseId) AS users
FROM dbo.tech_long
WHERE Status = 'Used' AND Category IN ('Database', 'Platform')
GROUP BY Category, Technology
ORDER BY Category, users DESC;

-- Q5. Median yearly salary (USD) by country, at least 100 salary rows --
-- Result: USA $139,000 | Israel $137,659 | Switzerland $136,392
WITH m AS (
  SELECT DISTINCT Country,
         COUNT(*) OVER (PARTITION BY Country) AS salary_rows,
         PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CompClean)
             OVER (PARTITION BY Country) AS median_salary
  FROM dbo.respondents
  WHERE CompClean IS NOT NULL AND Country IS NOT NULL
)
SELECT Country, salary_rows, median_salary
FROM m
WHERE salary_rows >= 100
ORDER BY median_salary DESC;

-- Q6. Job satisfaction by experience band ------------------------------
-- Result: 0-2 yrs 6.96 | 3-5 yrs 6.95 | 6-10 yrs 7.16
SELECT ExpBand, COUNT(JobSat) AS answers, ROUND(AVG(JobSat), 2) AS avg_job_sat
FROM dbo.respondents
WHERE ExpBand IS NOT NULL AND JobSat IS NOT NULL
GROUP BY ExpBand
ORDER BY MIN(WorkExp);

-- Q7. Share of daily AI tool users by age group ------------------------
-- Result: 18-24 47.2% | 25-34 51.1% | 35-44 48.7% | 65+ 22.3%
SELECT Age,
       COUNT(AISelect) AS answers,
       ROUND(100.0 * SUM(CASE WHEN AISelect = 'Yes, I use AI tools daily' THEN 1 ELSE 0 END)
             / COUNT(AISelect), 1) AS pct_daily_ai_users
FROM dbo.respondents
WHERE Age <> 'Prefer not to say'
GROUP BY Age
ORDER BY MIN(AgeSort);

-- Q8. Average clean salary by language used ----------------------------
-- (average for simplicity; groups with at least 500 salary rows)
SELECT TOP 15 t.Technology,
       COUNT(*)                   AS salary_rows,
       ROUND(AVG(r.CompClean), 0) AS avg_clean_salary
FROM dbo.tech_long t
JOIN dbo.respondents r ON r.ResponseId = t.ResponseId
WHERE t.Category = 'Language' AND t.Status = 'Used' AND r.CompClean IS NOT NULL
GROUP BY t.Technology
HAVING COUNT(*) >= 500
ORDER BY avg_clean_salary DESC;

-- Q9. Top roles among professional developers --------------------------
-- Result: Developer, full-stack 11,785 | Developer, back-end 6,252
SELECT TOP 10 ro.Role, COUNT(DISTINCT ro.ResponseId) AS people
FROM dbo.roles_long ro
JOIN dbo.respondents r ON r.ResponseId = ro.ResponseId
WHERE r.MainBranch = 'Professional developer'
GROUP BY ro.Role
ORDER BY people DESC;
