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
