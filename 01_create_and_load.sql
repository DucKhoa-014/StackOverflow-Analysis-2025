-- =====================================================================
-- Stack Overflow Developer Survey 2025 - create tables and load data
-- Target: SQL Server (T-SQL), database so2025
-- Input : the 3 CSV files produced by 01_clean_stackoverflow_2025.py
--         (respondents.csv, tech_long.csv, roles_long.csv)
-- =====================================================================

USE so2025;
GO

-- 1. Drop old tables ---------------------------------------------------
DROP TABLE IF EXISTS dbo.respondents;
DROP TABLE IF EXISTS dbo.tech_long;
DROP TABLE IF EXISTS dbo.roles_long;
GO

-- 2. Create tables -----------------------------------------------------
-- Every column except ResponseId allows NULL: blanks are skipped answers.
CREATE TABLE dbo.respondents (
    ResponseId          int           NOT NULL PRIMARY KEY,
    MainBranch          nvarchar(255) NULL,
    Age                 nvarchar(255) NULL,
    EdLevel             nvarchar(255) NULL,
    Employment          nvarchar(255) NULL,
    WorkExp             float         NULL,
    YearsCode           float         NULL,
    OrgSize             nvarchar(255) NULL,
    RemoteWork          nvarchar(255) NULL,
    Industry            nvarchar(255) NULL,
    Country             nvarchar(255) NULL,
    ConvertedCompYearly float         NULL,
    JobSat              float         NULL,
    AISelect            nvarchar(255) NULL,
    AISent              nvarchar(255) NULL,
    AIAcc               nvarchar(255) NULL,
    ExpBand             nvarchar(50)  NULL,
    AgeSort             float         NULL,
    CompOutlier         nvarchar(10)  NULL,
    CompClean           float         NULL
);

CREATE TABLE dbo.tech_long (
    ResponseId int           NOT NULL,
    Category   nvarchar(100) NULL,   -- Language / Database / Platform / Web framework
    Status     nvarchar(50)  NULL,   -- Used / Want
    Technology nvarchar(255) NULL
);

CREATE TABLE dbo.roles_long (
    ResponseId int           NOT NULL,
    Role       nvarchar(255) NULL
);
GO

-- 3. Load the CSV files ------------------------------------------------
BULK INSERT dbo.respondents
FROM 'F:\so2025_project\clean_data\respondents.csv'
WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2, CODEPAGE = '65001', KEEPNULLS);

BULK INSERT dbo.tech_long
FROM 'F:\so2025_project\clean_data\tech_long.csv'
WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2, CODEPAGE = '65001', KEEPNULLS);

BULK INSERT dbo.roles_long
FROM 'F:\so2025_project\clean_data\roles_long.csv'
WITH (FORMAT = 'CSV', FIELDQUOTE = '"', FIRSTROW = 2, CODEPAGE = '65001', KEEPNULLS);
GO

-- 4. Indexes (created after loading, which is faster) ------------------
CREATE INDEX ix_tech_id  ON dbo.tech_long(ResponseId);
CREATE INDEX ix_tech_cat ON dbo.tech_long(Category, Status, Technology) INCLUDE (ResponseId);
CREATE INDEX ix_roles_id ON dbo.roles_long(ResponseId);
GO

-- 5. Verify row counts -------------------------------------------------
SELECT COUNT(*)         AS respondents_rows   FROM dbo.respondents;   -- expect 49191
SELECT COUNT(CompClean) AS clean_salary_rows  FROM dbo.respondents;   -- expect 22161
SELECT COUNT(*)         AS tech_long_rows     FROM dbo.tech_long;     -- expect 921671
SELECT COUNT(*)         AS roles_long_rows    FROM dbo.roles_long;    -- expect 43680
