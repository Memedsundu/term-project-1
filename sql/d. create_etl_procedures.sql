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
