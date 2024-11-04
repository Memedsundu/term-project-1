-- import_data.sql
-- This script imports data from CSV files into the operational tables.

USE LanguageEndangermentDB;

-- Adjust the file paths based on your secure_file_priv directory
-- Check secure_file_priv value
-- SHOW VARIABLES LIKE 'secure_file_priv';

-- Import Families data
LOAD DATA INFILE '/path/to/secure_file_priv/Families.csv'
INTO TABLE Families
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Family_ID, Family_Name);

-- Import Genera data
LOAD DATA INFILE '/path/to/secure_file_priv/Genera.csv'
INTO TABLE Genera
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Genus_ID, Genus_Name, Family_ID);

-- Import Languages data
LOAD DATA INFILE '/path/to/secure_file_priv/Languages.csv'
INTO TABLE Languages
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Language_ID, Language_Name, ISO_Code, Family_ID, Genus_ID, Status, Macroarea, Latitude, Longitude, Countrycodes);
