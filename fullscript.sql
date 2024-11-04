\about
-- create_database.sql
-- This script creates the LanguageEndangermentDB database.

DROP DATABASE IF EXISTS LanguageEndangermentDB;
CREATE DATABASE LanguageEndangermentDB;
USE LanguageEndangermentDB;
-- create_tables.sql
-- This script creates the operational tables: Families, Genera, Languages.

USE LanguageEndangermentDB;

-- Create Families table
DROP TABLE IF EXISTS Families;
CREATE TABLE Families (
  Family_ID INT AUTO_INCREMENT PRIMARY KEY,
  Family_Name VARCHAR(255) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- Create Genera table
DROP TABLE IF EXISTS Genera;
CREATE TABLE Genera (
  Genus_ID INT AUTO_INCREMENT PRIMARY KEY,
  Genus_Name VARCHAR(255) NOT NULL,
  Family_ID INT NOT NULL,
  FOREIGN KEY (Family_ID) REFERENCES Families(Family_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Create Languages table
DROP TABLE IF EXISTS Languages;
CREATE TABLE Languages (
  Language_ID VARCHAR(50) PRIMARY KEY,
  Language_Name VARCHAR(255),
  ISO_Code VARCHAR(10),
  Family_ID INT,
  Genus_ID INT,
  Status VARCHAR(255),
  Macroarea VARCHAR(50),
  Latitude DECIMAL(9,6),
  Longitude DECIMAL(9,6),
  Countrycodes VARCHAR(50),
  FOREIGN KEY (Family_ID) REFERENCES Families(Family_ID)
    ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (Genus_ID) REFERENCES Genera(Genus_ID)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;
-- import_data.sql
-- This script imports data from CSV files into the operational tables.

USE LanguageEndangermentDB;

-- Adjust the file paths based on your secure_file_priv directory
-- Check secure_file_priv value
SHOW VARIABLES LIKE 'secure_file_priv';

-- Import Families data
LOAD DATA INFILE  '/Users/mehmetsundu/mysql_files/cleaned_data/Families.csv'
INTO TABLE Families
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Family_ID, Family_Name);

-- Import Genera data
LOAD DATA INFILE '/Users/mehmetsundu/mysql_files/cleaned_data/Genera.csv'
INTO TABLE Genera
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Genus_ID, Genus_Name, Family_ID);

-- Import Languages data
ALTER TABLE Languages MODIFY COLUMN Countrycodes VARCHAR(255);

LOAD DATA INFILE '/Users/mehmetsundu/mysql_files/cleaned_data/Languages.csv'
INTO TABLE Languages
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Language_ID, Language_Name, ISO_Code, Family_ID, Genus_ID, Status, Macroarea, Latitude, Longitude, Countrycodes)
SET Countrycodes = SUBSTRING(@Countrycodes, 1, 100);
-- create_etl_procedures.sql
-- This script creates stored procedures for the ETL process.

USE LanguageEndangermentDB;

DELIMITER //

-- Procedure to perform ETL for LanguageEndangerment table
CREATE PROCEDURE ETL_LanguageEndangerment()
BEGIN
  -- Create the analytical table if it doesn't exist
  CREATE TABLE IF NOT EXISTS LanguageEndangerment (
    Language_ID VARCHAR(50) PRIMARY KEY,
    Language_Name VARCHAR(255),
    ISO_Code VARCHAR(10),
    Family_Name VARCHAR(255),
    Genus_Name VARCHAR(255),
    Status VARCHAR(255),
    Macroarea VARCHAR(50),
    Latitude DECIMAL(9,6),
    Longitude DECIMAL(9,6),
    Countrycodes VARCHAR(50)
  ) ENGINE=InnoDB;

  -- Clear existing data
  TRUNCATE TABLE LanguageEndangerment;

  -- Insert transformed data
  INSERT INTO LanguageEndangerment (
    Language_ID, Language_Name, ISO_Code, Family_Name, Genus_Name, Status,
    Macroarea, Latitude, Longitude, Countrycodes
  )
  SELECT
    l.Language_ID,
    l.Language_Name,
    l.ISO_Code,
    f.Family_Name,
    g.Genus_Name,
    LOWER(TRIM(REPLACE(REPLACE(l.Status, '\n', ''), '''', ''))) AS Status,
    l.Macroarea,
    l.Latitude,
    l.Longitude,
    l.Countrycodes
  FROM Languages l
  LEFT JOIN Families f ON l.Family_ID = f.Family_ID
  LEFT JOIN Genera g ON l.Genus_ID = g.Genus_ID;
END //

DELIMITER ;
-- create_triggers.sql
-- This script creates triggers to automate the ETL process upon data changes.

USE LanguageEndangermentDB;

DELIMITER //

-- Trigger after INSERT on Languages
CREATE TRIGGER trg_after_insert_languages
AFTER INSERT ON Languages
FOR EACH ROW
BEGIN
  CALL ETL_LanguageEndangerment();
END //

-- Trigger after UPDATE on Languages
CREATE TRIGGER trg_after_update_languages
AFTER UPDATE ON Languages
FOR EACH ROW
BEGIN
  CALL ETL_LanguageEndangerment();
END //

-- Trigger after DELETE on Languages
CREATE TRIGGER trg_after_delete_languages
AFTER DELETE ON Languages
FOR EACH ROW
BEGIN
  CALL ETL_LanguageEndangerment();
END //

DELIMITER ;
-- create_views.sql
-- This script creates views as data marts for analytical queries.

USE LanguageEndangermentDB;

-- View for Family Endangerment Data Mart
CREATE OR REPLACE VIEW FamilyEndangermentDataMart AS
SELECT
  Family_Name,
  COUNT(Language_ID) AS Total_Languages,
  SUM(CASE WHEN Status IN (
    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',
    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'
  ) THEN 1 ELSE 0 END) AS Endangered_Languages,
  ROUND((SUM(CASE WHEN Status IN (
    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',
    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'
  ) THEN 1 ELSE 0 END) / COUNT(Language_ID)) * 100, 2) AS Endangerment_Rate_Percentage
FROM
  LanguageEndangerment
GROUP BY
  Family_Name;

-- View for Genus Endangerment Data Mart
CREATE OR REPLACE VIEW GenusEndangermentDataMart AS
SELECT
  Family_Name,
  Genus_Name,
  COUNT(Language_ID) AS Total_Languages,
  SUM(CASE WHEN Status IN (
    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',
    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'
  ) THEN 1 ELSE 0 END) AS Endangered_Languages,
  ROUND((SUM(CASE WHEN Status IN (
    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',
    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'
  ) THEN 1 ELSE 0 END) / COUNT(Language_ID)) * 100, 2) AS Endangerment_Rate_Percentage
FROM
  LanguageEndangerment
GROUP BY
  Family_Name, Genus_Name;

-- View for Macroarea Endangerment Data Mart
CREATE OR REPLACE VIEW MacroareaEndangermentDataMart AS
SELECT
  Macroarea,
  COUNT(Language_ID) AS Total_Languages,
  SUM(CASE WHEN Status IN (
    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',
    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'
  ) THEN 1 ELSE 0 END) AS Endangered_Languages,
  ROUND((SUM(CASE WHEN Status IN (
    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',
    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'
  ) THEN 1 ELSE 0 END) / COUNT(Language_ID)) * 100, 2) AS Endangerment_Rate_Percentage
FROM
  LanguageEndangerment
GROUP BY
  Macroarea;
USE LanguageEndangermentDB;  -- Ensure you're using the correct database
CALL ETL_LanguageEndangerment();

USE LanguageEndangermentDB;
SHOW TABLES LIKE 'LanguageEndangerment';

-- analysis_queries.sql
-- This script contains SQL queries used for data analysis.

USE LanguageEndangermentDB;

-- Query: Endangerment Rates per Family
SELECT * FROM FamilyEndangermentDataMart
ORDER BY Endangerment_Rate_Percentage DESC;

-- Query: Endangerment Rates per Genus
SELECT * FROM GenusEndangermentDataMart
WHERE Total_Languages >= 5
ORDER BY Endangerment_Rate_Percentage DESC;

-- Query: High-Risk Families (Endangerment Rate > 50%)
SELECT * FROM FamilyEndangermentDataMart
WHERE Endangerment_Rate_Percentage > 50
ORDER BY Endangerment_Rate_Percentage DESC;

-- Query: Endangerment Rates per Macroarea
SELECT * FROM MacroareaEndangermentDataMart
ORDER BY Endangerment_Rate_Percentage DESC;
-- Drop existing materialized table if any
DROP TABLE IF EXISTS MaterializedFamilyEndangerment;

-- Create the materialized view table
CREATE TABLE MaterializedFamilyEndangerment AS
SELECT * FROM FamilyEndangermentDataMart;

-- Enable the event scheduler
SET GLOBAL event_scheduler = ON;

-- Change the delimiter
DELIMITER //

-- Create the event
CREATE EVENT RefreshMaterializedFamilyEndangerment
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  TRUNCATE TABLE MaterializedFamilyEndangerment;
  INSERT INTO MaterializedFamilyEndangerment
  SELECT * FROM FamilyEndangermentDataMart;
END//

-- Reset the delimiter
DELIMITER ;

