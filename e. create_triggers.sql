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
