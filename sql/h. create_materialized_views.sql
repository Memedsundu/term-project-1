-- create_materialized_views.sql
-- This script creates materialized views and schedules events to refresh them.

USE LanguageEndangermentDB;

-- Create materialized view table for Family Endangerment
DROP TABLE IF EXISTS MaterializedFamilyEndangerment;
CREATE TABLE MaterializedFamilyEndangerment AS
SELECT * FROM FamilyEndangermentDataMart;

-- Create an event to refresh the materialized view daily
SET GLOBAL event_scheduler = ON;

CREATE EVENT RefreshMaterializedFamilyEndangerment
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  TRUNCATE TABLE MaterializedFamilyEndangerment;
  INSERT INTO MaterializedFamilyEndangerment
  SELECT * FROM FamilyEndangermentDataMart;
END;
