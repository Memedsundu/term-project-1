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
  Countrycodes VARCHAR(250),
  FOREIGN KEY (Family_ID) REFERENCES Families(Family_ID)
    ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (Genus_ID) REFERENCES Genera(Genus_ID)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;
