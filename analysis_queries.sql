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
