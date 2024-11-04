{
    "type": "MySQLNotebook",
    "version": "1.0",
    "caption": "DB Notebook",
    "content": "\\about\n-- create_database.sql\n-- This script creates the LanguageEndangermentDB database.\n\nDROP DATABASE IF EXISTS LanguageEndangermentDB;\nCREATE DATABASE LanguageEndangermentDB;\nUSE LanguageEndangermentDB;\n-- create_tables.sql\n-- This script creates the operational tables: Families, Genera, Languages.\n\nUSE LanguageEndangermentDB;\n\n-- Create Families table\nDROP TABLE IF EXISTS Families;\nCREATE TABLE Families (\n  Family_ID INT AUTO_INCREMENT PRIMARY KEY,\n  Family_Name VARCHAR(255) NOT NULL UNIQUE\n) ENGINE=InnoDB;\n\n-- Create Genera table\nDROP TABLE IF EXISTS Genera;\nCREATE TABLE Genera (\n  Genus_ID INT AUTO_INCREMENT PRIMARY KEY,\n  Genus_Name VARCHAR(255) NOT NULL,\n  Family_ID INT NOT NULL,\n  FOREIGN KEY (Family_ID) REFERENCES Families(Family_ID)\n    ON DELETE CASCADE ON UPDATE CASCADE\n) ENGINE=InnoDB;\n\n-- Create Languages table\nDROP TABLE IF EXISTS Languages;\nCREATE TABLE Languages (\n  Language_ID VARCHAR(50) PRIMARY KEY,\n  Language_Name VARCHAR(255),\n  ISO_Code VARCHAR(10),\n  Family_ID INT,\n  Genus_ID INT,\n  Status VARCHAR(255),\n  Macroarea VARCHAR(50),\n  Latitude DECIMAL(9,6),\n  Longitude DECIMAL(9,6),\n  Countrycodes VARCHAR(50),\n  FOREIGN KEY (Family_ID) REFERENCES Families(Family_ID)\n    ON DELETE SET NULL ON UPDATE CASCADE,\n  FOREIGN KEY (Genus_ID) REFERENCES Genera(Genus_ID)\n    ON DELETE SET NULL ON UPDATE CASCADE\n) ENGINE=InnoDB;\n-- import_data.sql\n-- This script imports data from CSV files into the operational tables.\n\nUSE LanguageEndangermentDB;\n\n-- Adjust the file paths based on your secure_file_priv directory\n-- Check secure_file_priv value\nSHOW VARIABLES LIKE 'secure_file_priv';\n\n-- Import Families data\nLOAD DATA INFILE  '/Users/mehmetsundu/mysql_files/cleaned_data/Families.csv'\nINTO TABLE Families\nFIELDS TERMINATED BY ','\nENCLOSED BY '\"'\nLINES TERMINATED BY '\\n'\nIGNORE 1 ROWS\n(Family_ID, Family_Name);\n\n-- Import Genera data\nLOAD DATA INFILE '/Users/mehmetsundu/mysql_files/cleaned_data/Genera.csv'\nINTO TABLE Genera\nFIELDS TERMINATED BY ','\nENCLOSED BY '\"'\nLINES TERMINATED BY '\\n'\nIGNORE 1 ROWS\n(Genus_ID, Genus_Name, Family_ID);\n\n-- Import Languages data\nALTER TABLE Languages MODIFY COLUMN Countrycodes VARCHAR(255);\n\nLOAD DATA INFILE '/Users/mehmetsundu/mysql_files/cleaned_data/Languages.csv'\nINTO TABLE Languages\nFIELDS TERMINATED BY ','\nENCLOSED BY '\"'\nLINES TERMINATED BY '\\n'\nIGNORE 1 ROWS\n(Language_ID, Language_Name, ISO_Code, Family_ID, Genus_ID, Status, Macroarea, Latitude, Longitude, Countrycodes)\nSET Countrycodes = SUBSTRING(@Countrycodes, 1, 100);\n-- create_etl_procedures.sql\n-- This script creates stored procedures for the ETL process.\n\nUSE LanguageEndangermentDB;\n\nDELIMITER //\n\n-- Procedure to perform ETL for LanguageEndangerment table\nCREATE PROCEDURE ETL_LanguageEndangerment()\nBEGIN\n  -- Create the analytical table if it doesn't exist\n  CREATE TABLE IF NOT EXISTS LanguageEndangerment (\n    Language_ID VARCHAR(50) PRIMARY KEY,\n    Language_Name VARCHAR(255),\n    ISO_Code VARCHAR(10),\n    Family_Name VARCHAR(255),\n    Genus_Name VARCHAR(255),\n    Status VARCHAR(255),\n    Macroarea VARCHAR(50),\n    Latitude DECIMAL(9,6),\n    Longitude DECIMAL(9,6),\n    Countrycodes VARCHAR(50)\n  ) ENGINE=InnoDB;\n\n  -- Clear existing data\n  TRUNCATE TABLE LanguageEndangerment;\n\n  -- Insert transformed data\n  INSERT INTO LanguageEndangerment (\n    Language_ID, Language_Name, ISO_Code, Family_Name, Genus_Name, Status,\n    Macroarea, Latitude, Longitude, Countrycodes\n  )\n  SELECT\n    l.Language_ID,\n    l.Language_Name,\n    l.ISO_Code,\n    f.Family_Name,\n    g.Genus_Name,\n    LOWER(TRIM(REPLACE(REPLACE(l.Status, '\\n', ''), '''', ''))) AS Status,\n    l.Macroarea,\n    l.Latitude,\n    l.Longitude,\n    l.Countrycodes\n  FROM Languages l\n  LEFT JOIN Families f ON l.Family_ID = f.Family_ID\n  LEFT JOIN Genera g ON l.Genus_ID = g.Genus_ID;\nEND //\n\nDELIMITER ;\n-- create_triggers.sql\n-- This script creates triggers to automate the ETL process upon data changes.\n\nUSE LanguageEndangermentDB;\n\nDELIMITER //\n\n-- Trigger after INSERT on Languages\nCREATE TRIGGER trg_after_insert_languages\nAFTER INSERT ON Languages\nFOR EACH ROW\nBEGIN\n  CALL ETL_LanguageEndangerment();\nEND //\n\n-- Trigger after UPDATE on Languages\nCREATE TRIGGER trg_after_update_languages\nAFTER UPDATE ON Languages\nFOR EACH ROW\nBEGIN\n  CALL ETL_LanguageEndangerment();\nEND //\n\n-- Trigger after DELETE on Languages\nCREATE TRIGGER trg_after_delete_languages\nAFTER DELETE ON Languages\nFOR EACH ROW\nBEGIN\n  CALL ETL_LanguageEndangerment();\nEND //\n\nDELIMITER ;\n-- create_views.sql\n-- This script creates views as data marts for analytical queries.\n\nUSE LanguageEndangermentDB;\n\n-- View for Family Endangerment Data Mart\nCREATE OR REPLACE VIEW FamilyEndangermentDataMart AS\nSELECT\n  Family_Name,\n  COUNT(Language_ID) AS Total_Languages,\n  SUM(CASE WHEN Status IN (\n    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',\n    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'\n  ) THEN 1 ELSE 0 END) AS Endangered_Languages,\n  ROUND((SUM(CASE WHEN Status IN (\n    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',\n    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'\n  ) THEN 1 ELSE 0 END) / COUNT(Language_ID)) * 100, 2) AS Endangerment_Rate_Percentage\nFROM\n  LanguageEndangerment\nGROUP BY\n  Family_Name;\n\n-- View for Genus Endangerment Data Mart\nCREATE OR REPLACE VIEW GenusEndangermentDataMart AS\nSELECT\n  Family_Name,\n  Genus_Name,\n  COUNT(Language_ID) AS Total_Languages,\n  SUM(CASE WHEN Status IN (\n    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',\n    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'\n  ) THEN 1 ELSE 0 END) AS Endangered_Languages,\n  ROUND((SUM(CASE WHEN Status IN (\n    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',\n    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'\n  ) THEN 1 ELSE 0 END) / COUNT(Language_ID)) * 100, 2) AS Endangerment_Rate_Percentage\nFROM\n  LanguageEndangerment\nGROUP BY\n  Family_Name, Genus_Name;\n\n-- View for Macroarea Endangerment Data Mart\nCREATE OR REPLACE VIEW MacroareaEndangermentDataMart AS\nSELECT\n  Macroarea,\n  COUNT(Language_ID) AS Total_Languages,\n  SUM(CASE WHEN Status IN (\n    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',\n    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'\n  ) THEN 1 ELSE 0 END) AS Endangered_Languages,\n  ROUND((SUM(CASE WHEN Status IN (\n    'endangered', 'nearly extinct', 'moribund', 'critically endangered', 'extinct',\n    'definitely endangered', 'severely endangered', 'vulnerable', 'threatened'\n  ) THEN 1 ELSE 0 END) / COUNT(Language_ID)) * 100, 2) AS Endangerment_Rate_Percentage\nFROM\n  LanguageEndangerment\nGROUP BY\n  Macroarea;\nUSE LanguageEndangermentDB;  -- Ensure you're using the correct database\nCALL ETL_LanguageEndangerment();\n\nUSE LanguageEndangermentDB;\nSHOW TABLES LIKE 'LanguageEndangerment';\n\n-- analysis_queries.sql\n-- This script contains SQL queries used for data analysis.\n\nUSE LanguageEndangermentDB;\n\n-- Query: Endangerment Rates per Family\nSELECT * FROM FamilyEndangermentDataMart\nORDER BY Endangerment_Rate_Percentage DESC;\n\n-- Query: Endangerment Rates per Genus\nSELECT * FROM GenusEndangermentDataMart\nWHERE Total_Languages >= 5\nORDER BY Endangerment_Rate_Percentage DESC;\n\n-- Query: High-Risk Families (Endangerment Rate > 50%)\nSELECT * FROM FamilyEndangermentDataMart\nWHERE Endangerment_Rate_Percentage > 50\nORDER BY Endangerment_Rate_Percentage DESC;\n\n-- Query: Endangerment Rates per Macroarea\nSELECT * FROM MacroareaEndangermentDataMart\nORDER BY Endangerment_Rate_Percentage DESC;\n-- Drop existing materialized table if any\nDROP TABLE IF EXISTS MaterializedFamilyEndangerment;\n\n-- Create the materialized view table\nCREATE TABLE MaterializedFamilyEndangerment AS\nSELECT * FROM FamilyEndangermentDataMart;\n\n-- Enable the event scheduler\nSET GLOBAL event_scheduler = ON;\n\n-- Change the delimiter\nDELIMITER //\n\n-- Create the event\nCREATE EVENT RefreshMaterializedFamilyEndangerment\nON SCHEDULE EVERY 1 DAY\nDO\nBEGIN\n  TRUNCATE TABLE MaterializedFamilyEndangerment;\n  INSERT INTO MaterializedFamilyEndangerment\n  SELECT * FROM FamilyEndangermentDataMart;\nEND//\n\n-- Reset the delimiter\nDELIMITER ;\n\n",
    "options": {
        "tabSize": 4,
        "insertSpaces": true,
        "indentSize": 4,
        "defaultEOL": "LF",
        "trimAutoWhitespace": true
    },
    "viewState": {
        "cursorState": [
            {
                "inSelectionMode": false,
                "selectionStart": {
                    "lineNumber": 280,
                    "column": 1
                },
                "position": {
                    "lineNumber": 280,
                    "column": 1
                }
            }
        ],
        "viewState": {
            "scrollLeft": 0,
            "firstPosition": {
                "lineNumber": 241,
                "column": 1
            },
            "firstPositionDeltaTop": 0
        },
        "contributionsState": {
            "editor.contrib.folding": {},
            "editor.contrib.wordHighlighter": false
        }
    },
    "contexts": [
        {
            "state": {
                "start": 1,
                "end": 1,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 2,
                            "content": "Welcome to the MySQL Shell - DB Notebook.\n\nPress Cmd+Enter to execute the code block.\n\nExecute \\sql to switch to SQL, \\js to JavaScript and \\ts to TypeScript mode.\nExecute \\help or \\? for help;",
                            "language": "ansi"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 6
                        },
                        "contentStart": 0,
                        "state": 0
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 2,
                "end": 7,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "3e3b68b5-18a0-45d0-81ed-fca336cdf48f",
                            "content": "OK, 3 rows affected in 66.73ms"
                        },
                        {
                            "type": 4,
                            "index": 1,
                            "resultId": "dfbdfca9-f50c-4825-f1bc-5e933995148a",
                            "content": "OK, 1 row affected in 3.492ms"
                        },
                        {
                            "type": 4,
                            "index": 2,
                            "resultId": "aa162f30-0f8e-48ba-cd80-8d2d416926cd",
                            "content": "OK, 0 records retrieved in 0.584ms"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 131
                        },
                        "contentStart": 85,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 131,
                            "length": 40
                        },
                        "contentStart": 132,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 171,
                            "length": 28
                        },
                        "contentStart": 172,
                        "state": 0
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 8,
                "end": 47,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "2f8ce295-55cb-41f1-a889-ba1ed4956dbb",
                            "content": "OK, 0 records retrieved in 1.446ms"
                        },
                        {
                            "type": 4,
                            "index": 1,
                            "resultId": "d2c49f1f-6b0a-4176-bd17-dff16a478fef",
                            "content": "OK, 0 records retrieved in 10.951ms"
                        },
                        {
                            "type": 4,
                            "index": 2,
                            "resultId": "c842b407-180b-4847-b78b-2f3ce5f1494a",
                            "content": "OK, 0 records retrieved in 39.824ms"
                        },
                        {
                            "type": 4,
                            "index": 3,
                            "resultId": "7c7f19ff-52e9-422a-be3b-18034867f6b8",
                            "content": "OK, 0 records retrieved in 1.199ms"
                        },
                        {
                            "type": 4,
                            "index": 4,
                            "resultId": "795236b1-14cd-4779-b8eb-db1de28db47c",
                            "content": "OK, 0 records retrieved in 13.748ms"
                        },
                        {
                            "type": 4,
                            "index": 5,
                            "resultId": "f6c06114-a5ee-4bf6-d23f-56ce43b2f949",
                            "content": "OK, 0 records retrieved in 1.087ms"
                        },
                        {
                            "type": 4,
                            "index": 6,
                            "resultId": "2608e821-4eea-4054-fc5f-3281bd462d13",
                            "content": "OK, 0 records retrieved in 19.316ms"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 125
                        },
                        "contentStart": 98,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 125,
                            "length": 57
                        },
                        "contentStart": 153,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 182,
                            "length": 128
                        },
                        "contentStart": 183,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 310,
                            "length": 53
                        },
                        "contentStart": 336,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 363,
                            "length": 241
                        },
                        "contentStart": 364,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 604,
                            "length": 59
                        },
                        "contentStart": 633,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 663,
                            "length": 488
                        },
                        "contentStart": 664,
                        "state": 0
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 48,
                "end": 85,
                "language": "mysql",
                "result": {
                    "type": "resultIds",
                    "list": [
                        "06c54175-28cb-461a-94d5-5f60848fc14e",
                        "d9da37c8-712b-46d7-b19f-ca446adb403e",
                        "e8ae81e2-edd3-44a7-a7f9-b60d8f528b88",
                        "7d572a7b-b013-477b-8583-28f8845b4eea",
                        "d6429eb1-737e-4ca3-f678-cde3ca1cc948",
                        "8c92c51f-aeac-458f-9e4d-337defaaea73"
                    ]
                },
                "currentHeight": 113,
                "currentSet": 0,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 119
                        },
                        "contentStart": 92,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 119,
                            "length": 139
                        },
                        "contentStart": 219,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 258,
                            "length": 228
                        },
                        "contentStart": 284,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 486,
                            "length": 230
                        },
                        "contentStart": 510,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 716,
                            "length": 89
                        },
                        "contentStart": 743,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 805,
                            "length": 346
                        },
                        "contentStart": 807,
                        "state": 0
                    }
                ]
            },
            "data": [
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "06c54175-28cb-461a-94d5-5f60848fc14e",
                    "rows": [
                        {
                            "0": "secure_file_priv",
                            "1": "/Users/mehmetsundu/mysql_files/"
                        }
                    ],
                    "columns": [
                        {
                            "title": "Variable_name",
                            "field": "0",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Value",
                            "field": "1",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        }
                    ],
                    "executionInfo": {
                        "text": "OK, 1 record retrieved in 10.641ms"
                    },
                    "totalRowCount": 1,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 1,
                    "sql": "\n\n-- Adjust the file paths based on your secure_file_priv directory\n-- Check secure_file_priv value\nSHOW VARIABLES LIKE 'secure_file_priv'",
                    "updatable": false
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "d9da37c8-712b-46d7-b19f-ca446adb403e",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 0 records retrieved in 8.255ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 0,
                    "sql": "-- import_data.sql\n-- This script imports data from CSV files into the operational tables.\n\nUSE LanguageEndangermentDB",
                    "updatable": false
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "e8ae81e2-edd3-44a7-a7f9-b60d8f528b88",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 254 rows affected in 13.03ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 2,
                    "sql": "\n\n-- Import Families data\nLOAD DATA INFILE  '/Users/mehmetsundu/mysql_files/cleaned_data/Families.csv'\nINTO TABLE Families\nFIELDS TERMINATED BY ','\nENCLOSED BY '\"'\nLINES TERMINATED BY '\\n'\nIGNORE 1 ROWS\n(Family_ID, Family_Name)",
                    "updatable": false
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "7d572a7b-b013-477b-8583-28f8845b4eea",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 542 rows affected in 19.093ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 3,
                    "sql": "\n\n-- Import Genera data\nLOAD DATA INFILE '/Users/mehmetsundu/mysql_files/cleaned_data/Genera.csv'\nINTO TABLE Genera\nFIELDS TERMINATED BY ','\nENCLOSED BY '\"'\nLINES TERMINATED BY '\\n'\nIGNORE 1 ROWS\n(Genus_ID, Genus_Name, Family_ID)",
                    "updatable": false
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "d6429eb1-737e-4ca3-f678-cde3ca1cc948",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 0 records retrieved in 14.177ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 4,
                    "sql": "\n\n-- Import Languages data\nALTER TABLE Languages MODIFY COLUMN Countrycodes VARCHAR(255)",
                    "updatable": false
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "8c92c51f-aeac-458f-9e4d-337defaaea73",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 2462 rows affected in 58.267ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 5,
                    "sql": "\n\nLOAD DATA INFILE '/Users/mehmetsundu/mysql_files/cleaned_data/Languages.csv'\nINTO TABLE Languages\nFIELDS TERMINATED BY ','\nENCLOSED BY '\"'\nLINES TERMINATED BY '\\n'\nIGNORE 1 ROWS\n(Language_ID, Language_Name, ISO_Code, Family_ID, Genus_ID, Status, Macroarea, Latitude, Longitude, Countrycodes)\nSET Countrycodes = SUBSTRING(@Countrycodes, 1, 100)",
                    "updatable": false
                }
            ]
        },
        {
            "state": {
                "start": 86,
                "end": 134,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "9b25fe16-d788-41bd-c325-8941aab7a0f4",
                            "content": "OK, 0 records retrieved in 1.918ms"
                        },
                        {
                            "type": 4,
                            "index": 2,
                            "resultId": "95e3b0c8-90c8-4400-fcb1-d6c11f834d31",
                            "content": "OK, 0 records retrieved in 13.794ms"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 119
                        },
                        "contentStart": 92,
                        "state": 0
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 119,
                            "length": 14
                        },
                        "contentStart": 121,
                        "state": 4
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 133,
                            "length": 1161
                        },
                        "contentStart": 194,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 1294,
                            "length": 13
                        },
                        "contentStart": 1296,
                        "state": 4
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 135,
                "end": 166,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "377bae7a-c7f4-46f4-c0a6-cb60a287b8cb",
                            "content": "OK, 0 records retrieved in 1.02ms"
                        },
                        {
                            "type": 4,
                            "index": 2,
                            "resultId": "20649b32-d0af-4727-8830-cdb1716fdf22",
                            "content": "OK, 0 records retrieved in 14.296ms"
                        },
                        {
                            "type": 4,
                            "index": 3,
                            "resultId": "093ff16a-20f1-457e-8e51-a973759b25a8",
                            "content": "OK, 0 records retrieved in 7.259ms"
                        },
                        {
                            "type": 4,
                            "index": 4,
                            "resultId": "e6ce12a2-4f73-4e92-9e93-43c23a156de5",
                            "content": "OK, 0 records retrieved in 5.84ms"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 130
                        },
                        "contentStart": 103,
                        "state": 0
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 130,
                            "length": 14
                        },
                        "contentStart": 132,
                        "state": 4
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 144,
                            "length": 167
                        },
                        "contentStart": 183,
                        "state": 0
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 311,
                            "length": 167
                        },
                        "contentStart": 350,
                        "state": 0
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 478,
                            "length": 167
                        },
                        "contentStart": 517,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 645,
                            "length": 13
                        },
                        "contentStart": 647,
                        "state": 4
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 167,
                "end": 225,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "6ac5fa85-fea5-46ca-b5dc-5f3cc32be47d",
                            "content": "OK, 0 records retrieved in 51.666ms"
                        },
                        {
                            "type": 4,
                            "index": 1,
                            "resultId": "9e1bb283-adcc-4282-93ca-97a552da360e",
                            "content": "OK, 0 records retrieved in 72.047ms"
                        },
                        {
                            "type": 4,
                            "index": 2,
                            "resultId": "e74b2361-0f2a-4275-ebe8-f154432b38ee",
                            "content": "OK, 0 records retrieved in 3.506ms"
                        },
                        {
                            "type": 4,
                            "index": 3,
                            "resultId": "700fd3a0-ed2d-4593-bc8d-754ea9805f60",
                            "content": "OK, 0 records retrieved in 4.736ms"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 115
                        },
                        "contentStart": 88,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 115,
                            "length": 735
                        },
                        "contentStart": 159,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 850,
                            "length": 759
                        },
                        "contentStart": 893,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 1609,
                            "length": 737
                        },
                        "contentStart": 1656,
                        "state": 0
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 226,
                "end": 228,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "2d273956-e1c1-446c-d7c7-b33aade7c6a0",
                            "content": "OK, 0 records retrieved in 1.365ms"
                        },
                        {
                            "type": 4,
                            "index": 1,
                            "resultId": "4bbc0a2e-e458-4760-b2d7-7c0478fd1a51",
                            "content": "OK, 2462 rows affected in 69.964ms",
                            "subIndex": 0
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 27
                        },
                        "contentStart": 0,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 27,
                            "length": 78
                        },
                        "contentStart": 73,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 105,
                            "length": 1
                        },
                        "contentStart": 104,
                        "state": 3
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 229,
                "end": 231,
                "language": "mysql",
                "result": {
                    "type": "resultIds",
                    "list": [
                        "af7e19c3-d285-4ce4-b8be-06a2abf84573",
                        "db9a0b1c-ed43-433b-d1fc-fdc2adba3fc5"
                    ]
                },
                "currentHeight": 36,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 27
                        },
                        "contentStart": 0,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 27,
                            "length": 41
                        },
                        "contentStart": 28,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 68,
                            "length": 1
                        },
                        "contentStart": 67,
                        "state": 3
                    }
                ]
            },
            "data": [
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "af7e19c3-d285-4ce4-b8be-06a2abf84573",
                    "rows": [
                        {
                            "0": "LanguageEndangerment"
                        }
                    ],
                    "columns": [
                        {
                            "title": "Tables_in_languageendangermentdb (LanguageEndangerment)",
                            "field": "0",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        }
                    ],
                    "executionInfo": {
                        "text": "OK, 1 record retrieved in 15.116ms"
                    },
                    "totalRowCount": 1,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 1,
                    "sql": "\nSHOW TABLES LIKE 'LanguageEndangerment'",
                    "updatable": false
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "db9a0b1c-ed43-433b-d1fc-fdc2adba3fc5",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 0 records retrieved in 1.206ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 0,
                    "sql": "USE LanguageEndangermentDB",
                    "updatable": false
                }
            ]
        },
        {
            "state": {
                "start": 232,
                "end": 253,
                "language": "mysql",
                "result": {
                    "type": "resultIds",
                    "list": [
                        "6b9521fa-e0ab-42a9-b59b-bde9f9945d65",
                        "249732e0-5479-44ff-d785-4f6a4e9204d6",
                        "42127f68-9f7c-4602-890d-bf204f310201",
                        "e00cb330-5b15-46fc-e3d0-0a169488f29f",
                        "222722cc-cd06-4206-a470-30f5872512bb"
                    ]
                },
                "currentHeight": 352,
                "currentSet": 4,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 112
                        },
                        "contentStart": 85,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 112,
                            "length": 126
                        },
                        "contentStart": 154,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 238,
                            "length": 151
                        },
                        "contentStart": 279,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 389,
                            "length": 181
                        },
                        "contentStart": 446,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 570,
                            "length": 132
                        },
                        "contentStart": 615,
                        "state": 0
                    }
                ]
            },
            "data": [
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "6b9521fa-e0ab-42a9-b59b-bde9f9945d65",
                    "rows": [
                        {
                            "0": "aikaná",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "great andamanese",
                            "1": 4,
                            "2": "4",
                            "3": "100.00"
                        },
                        {
                            "0": "huarpe",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "harakmbet",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "andoke",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "zaparoan",
                            "1": 3,
                            "2": "3",
                            "3": "100.00"
                        },
                        {
                            "0": "tacanan",
                            "1": 4,
                            "2": "4",
                            "3": "100.00"
                        },
                        {
                            "0": "tacame",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "atakapa",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "barbacoan",
                            "1": 4,
                            "2": "4",
                            "3": "100.00"
                        },
                        {
                            "0": "zamucoan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chumash",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "beothuk",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "betoi",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "bororoan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "bunuban",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "camsá",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "cayuvava",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "aymaran",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "cholon",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chitimacha",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "coahuiltecan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "comecrudan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "cuitlatec",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "jabutí",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "choco",
                            "1": 5,
                            "2": "5",
                            "3": "100.00"
                        },
                        {
                            "0": "esselen",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "guató",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "hadza",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "itonama",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "iwaidjan",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "kalapuyan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "eastern daly",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "katukinan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kapixana",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "karankawa",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "karok",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yeniseian",
                            "1": 3,
                            "2": "3",
                            "3": "100.00"
                        },
                        {
                            "0": "jarrakan",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "kunza",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kuot",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kutenai",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kwaza",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "leko",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "lule",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "máku",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chimúan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "moraori",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "mosetenan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "movima",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "northern daly",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "natchez",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "nahali",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yukaghir",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "chon",
                            "1": 3,
                            "2": "3",
                            "3": "100.00"
                        },
                        {
                            "0": "sáliban",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "puinave",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yaruro",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "puquina",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tarascan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "alacalufan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "salinan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "huavean",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "shabo",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "sulung",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "gapun",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "takelma",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "taushiro",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "ticuna",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "timote-cuica",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "timucua",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tiwian",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tol",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tonkawa",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "trumai",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tunica",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "urarina",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "wagiman",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "waorani",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "warao",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yangmanic",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chapacura-wanham",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "washo",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tu",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "peba-yaguan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yámana",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yuchi",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yurimangí",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "zuni",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "na-dene",
                            "1": 24,
                            "2": "23",
                            "3": "95.83"
                        },
                        {
                            "0": "gunwinyguan",
                            "1": 9,
                            "2": "8",
                            "3": "88.89"
                        },
                        {
                            "0": "totonacan",
                            "1": 6,
                            "2": "5",
                            "3": "83.33"
                        },
                        {
                            "0": "wakashan",
                            "1": 5,
                            "2": "4",
                            "3": "80.00"
                        },
                        {
                            "0": "arawakan",
                            "1": 28,
                            "2": "22",
                            "3": "78.57"
                        },
                        {
                            "0": "macro-ge",
                            "1": 13,
                            "2": "10",
                            "3": "76.92"
                        },
                        {
                            "0": "jivaroan",
                            "1": 4,
                            "2": "3",
                            "3": "75.00"
                        },
                        {
                            "0": "mangarrayi-maran",
                            "1": 4,
                            "2": "3",
                            "3": "75.00"
                        },
                        {
                            "0": "iroquoian",
                            "1": 8,
                            "2": "6",
                            "3": "75.00"
                        },
                        {
                            "0": "cariban",
                            "1": 17,
                            "2": "12",
                            "3": "70.59"
                        },
                        {
                            "0": "hokan",
                            "1": 18,
                            "2": "12",
                            "3": "66.67"
                        },
                        {
                            "0": "muskogean",
                            "1": 6,
                            "2": "4",
                            "3": "66.67"
                        },
                        {
                            "0": "oregon coast",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "tucanoan",
                            "1": 18,
                            "2": "12",
                            "3": "66.67"
                        },
                        {
                            "0": "nadahup",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "mirndi",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "tangkic",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "tupian",
                            "1": 22,
                            "2": "14",
                            "3": "63.64"
                        },
                        {
                            "0": "chibchan",
                            "1": 16,
                            "2": "10",
                            "3": "62.50"
                        },
                        {
                            "0": "siouan",
                            "1": 13,
                            "2": "8",
                            "3": "61.54"
                        },
                        {
                            "0": "guaicuruan",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "caddoan",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "guahiban",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "kiowa-tanoan",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "algic",
                            "1": 30,
                            "2": "17",
                            "3": "56.67"
                        },
                        {
                            "0": "panoan",
                            "1": 11,
                            "2": "6",
                            "3": "54.55"
                        },
                        {
                            "0": "penutian",
                            "1": 22,
                            "2": "12",
                            "3": "54.55"
                        },
                        {
                            "0": "pama-nyungan",
                            "1": 107,
                            "2": "58",
                            "3": "54.21"
                        },
                        {
                            "0": "mangrida",
                            "1": 4,
                            "2": "2",
                            "3": "50.00"
                        },
                        {
                            "0": "cacua-nukak",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "cahuapanan",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "chimakuan",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "uru-chipaya",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "matacoan",
                            "1": 4,
                            "2": "2",
                            "3": "50.00"
                        },
                        {
                            "0": "arauan",
                            "1": 4,
                            "2": "2",
                            "3": "50.00"
                        },
                        {
                            "0": "ijoid",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "keresan",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "haida",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "tequistlatecan",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "south andamanese",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "kadu",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "darwin region",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "wappo-yukian",
                            "1": 2,
                            "2": "1",
                            "3": "50.00"
                        },
                        {
                            "0": "salishan",
                            "1": 19,
                            "2": "9",
                            "3": "47.37"
                        },
                        {
                            "0": "uto-aztecan",
                            "1": 38,
                            "2": "18",
                            "3": "47.37"
                        },
                        {
                            "0": "quechuan",
                            "1": 11,
                            "2": "5",
                            "3": "45.45"
                        },
                        {
                            "0": "nakh-daghestanian",
                            "1": 28,
                            "2": "12",
                            "3": "42.86"
                        },
                        {
                            "0": "northwest caucasian",
                            "1": 5,
                            "2": "2",
                            "3": "40.00"
                        },
                        {
                            "0": "nyulnyulan",
                            "1": 5,
                            "2": "2",
                            "3": "40.00"
                        },
                        {
                            "0": "lakes plain",
                            "1": 5,
                            "2": "2",
                            "3": "40.00"
                        },
                        {
                            "0": "dravidian",
                            "1": 22,
                            "2": "8",
                            "3": "36.36"
                        },
                        {
                            "0": "khoe-kwadi",
                            "1": 6,
                            "2": "2",
                            "3": "33.33"
                        },
                        {
                            "0": "solomons east papuan",
                            "1": 3,
                            "2": "1",
                            "3": "33.33"
                        },
                        {
                            "0": "kxa",
                            "1": 3,
                            "2": "1",
                            "3": "33.33"
                        },
                        {
                            "0": "eleman",
                            "1": 3,
                            "2": "1",
                            "3": "33.33"
                        },
                        {
                            "0": "baining-taulil",
                            "1": 3,
                            "2": "1",
                            "3": "33.33"
                        },
                        {
                            "0": "eskimo-aleut",
                            "1": 10,
                            "2": "3",
                            "3": "30.00"
                        },
                        {
                            "0": "mayan",
                            "1": 34,
                            "2": "10",
                            "3": "29.41"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": 126,
                            "2": "37",
                            "3": "29.37"
                        },
                        {
                            "0": "western daly",
                            "1": 4,
                            "2": "1",
                            "3": "25.00"
                        },
                        {
                            "0": "kordofanian",
                            "1": 8,
                            "2": "2",
                            "3": "25.00"
                        },
                        {
                            "0": "kartvelian",
                            "1": 4,
                            "2": "1",
                            "3": "25.00"
                        },
                        {
                            "0": "uralic",
                            "1": 25,
                            "2": "6",
                            "3": "24.00"
                        },
                        {
                            "0": "oto-manguean",
                            "1": 53,
                            "2": "12",
                            "3": "22.64"
                        },
                        {
                            "0": "lower sepik-ramu",
                            "1": 9,
                            "2": "2",
                            "3": "22.22"
                        },
                        {
                            "0": "tai-kadai",
                            "1": 18,
                            "2": "4",
                            "3": "22.22"
                        },
                        {
                            "0": "border",
                            "1": 5,
                            "2": "1",
                            "3": "20.00"
                        },
                        {
                            "0": "hmong-mien",
                            "1": 5,
                            "2": "1",
                            "3": "20.00"
                        },
                        {
                            "0": "austro-asiatic",
                            "1": 47,
                            "2": "8",
                            "3": "17.02"
                        },
                        {
                            "0": "altaic",
                            "1": 53,
                            "2": "9",
                            "3": "16.98"
                        },
                        {
                            "0": "huitotoan",
                            "1": 6,
                            "2": "1",
                            "3": "16.67"
                        },
                        {
                            "0": "skou",
                            "1": 6,
                            "2": "1",
                            "3": "16.67"
                        },
                        {
                            "0": "eastern sudanic",
                            "1": 43,
                            "2": "6",
                            "3": "13.95"
                        },
                        {
                            "0": "indo-european",
                            "1": 139,
                            "2": "19",
                            "3": "13.67"
                        },
                        {
                            "0": "austronesian",
                            "1": 316,
                            "2": "38",
                            "3": "12.03"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": 130,
                            "2": "14",
                            "3": "10.77"
                        },
                        {
                            "0": "mixe-zoque",
                            "1": 10,
                            "2": "1",
                            "3": "10.00"
                        },
                        {
                            "0": "other",
                            "1": 67,
                            "2": "3",
                            "3": "4.48"
                        },
                        {
                            "0": "central sudanic",
                            "1": 25,
                            "2": "1",
                            "3": "4.00"
                        },
                        {
                            "0": "niger-congo",
                            "1": 312,
                            "2": "12",
                            "3": "3.85"
                        },
                        {
                            "0": "mande",
                            "1": 27,
                            "2": "1",
                            "3": "3.70"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": 86,
                            "2": "2",
                            "3": "2.33"
                        },
                        {
                            "0": "torricelli",
                            "1": 13,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "sepik",
                            "1": 16,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "timor-alor-pantar",
                            "1": 7,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "west papuan",
                            "1": 13,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "awin-pare",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "ainu",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "chukotko-kamchatkan",
                            "1": 5,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "left may",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "anêm",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "senagi",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "marind",
                            "1": 6,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "morehead and upper maro rivers",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "west bomberai",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "bangime",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "basque",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "east geelvink bay",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "tor-orya",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "berta",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "burushaski",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "candoshi",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "saharan",
                            "1": 4,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "japanese",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "chiquito",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "cofán",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "teberan-pawaian",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "dagan",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "dogon",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "bosavi",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "morwap",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kwomtari-baibai",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yatê",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "fur",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "gaagudju",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "garrwan",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "nivkh",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "gogodala-suki",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "mascoian",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "gumuz",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "piawi",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "iranxe",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kwerba",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kariri",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "karkar-yuri",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kaure",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "nimboran",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kolopom",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "koman",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "korean",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "songhay",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kunama",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kusunda",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "worrorran",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "laal",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "maban",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "bulaka river",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "east bird's head",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "araucanian",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "western fly",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "misumalpan",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "southern daly",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "east bougainville",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yanomam",
                            "1": 3,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "mombum",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yawa",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "monumbo",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "sentani",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "oksapmin",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "páezan",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "mura",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "west bougainville",
                            "1": 2,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "turama-kikorian",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "east strickland",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "sandawe",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "shompen",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kiwaian",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "nambikuaran",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "sulka",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "kayagar",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "anson bay",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yale",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yareban",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yele",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        },
                        {
                            "0": "yuracare",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        }
                    ],
                    "columns": [
                        {
                            "title": "Family_Name",
                            "field": "0",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Total_Languages",
                            "field": "1",
                            "dataType": {
                                "type": 4,
                                "flags": [
                                    "SIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 10,
                                "parameterFormatType": "OneOrZero",
                                "synonyms": [
                                    "INTEGER",
                                    "INT4"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangered_Languages",
                            "field": "2",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangerment_Rate_Percentage",
                            "field": "3",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        }
                    ],
                    "executionInfo": {
                        "text": "OK, 254 records retrieved in 10.72ms"
                    },
                    "totalRowCount": 254,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 1,
                    "sql": "\n\n-- Query: Endangerment Rates per Family\nSELECT * FROM FamilyEndangermentDataMart\nORDER BY Endangerment_Rate_Percentage DESC",
                    "updatable": false,
                    "fullTableName": "FamilyEndangermentDataMart"
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "249732e0-5479-44ff-d785-4f6a4e9204d6",
                    "rows": [
                        {
                            "0": "choco",
                            "1": "choco",
                            "2": 5,
                            "3": "5",
                            "4": "100.00"
                        },
                        {
                            "0": "na-dene",
                            "1": "athapaskan",
                            "2": 22,
                            "3": "21",
                            "4": "95.45"
                        },
                        {
                            "0": "iroquoian",
                            "1": "northern iroquoian",
                            "2": 7,
                            "3": "6",
                            "4": "85.71"
                        },
                        {
                            "0": "hokan",
                            "1": "yuman",
                            "2": 7,
                            "3": "6",
                            "4": "85.71"
                        },
                        {
                            "0": "totonacan",
                            "1": "totonacan",
                            "2": 6,
                            "3": "5",
                            "4": "83.33"
                        },
                        {
                            "0": "uto-aztecan",
                            "1": "california uto-aztecan",
                            "2": 5,
                            "3": "4",
                            "4": "80.00"
                        },
                        {
                            "0": "oto-manguean",
                            "1": "otomian",
                            "2": 5,
                            "3": "4",
                            "4": "80.00"
                        },
                        {
                            "0": "arawakan",
                            "1": "inland northern arawakan",
                            "2": 8,
                            "3": "6",
                            "4": "75.00"
                        },
                        {
                            "0": "pama-nyungan",
                            "1": "northern pama-nyungan",
                            "2": 32,
                            "3": "23",
                            "4": "71.88"
                        },
                        {
                            "0": "cariban",
                            "1": "cariban",
                            "2": 17,
                            "3": "12",
                            "4": "70.59"
                        },
                        {
                            "0": "muskogean",
                            "1": "muskogean",
                            "2": 6,
                            "3": "4",
                            "4": "66.67"
                        },
                        {
                            "0": "macro-ge",
                            "1": "ge-kaingang",
                            "2": 9,
                            "3": "6",
                            "4": "66.67"
                        },
                        {
                            "0": "tucanoan",
                            "1": "tucanoan",
                            "2": 18,
                            "3": "12",
                            "4": "66.67"
                        },
                        {
                            "0": "penutian",
                            "1": "miwok",
                            "2": 6,
                            "3": "4",
                            "4": "66.67"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "tani",
                            "2": 5,
                            "3": "3",
                            "4": "60.00"
                        },
                        {
                            "0": "caddoan",
                            "1": "caddoan",
                            "2": 5,
                            "3": "3",
                            "4": "60.00"
                        },
                        {
                            "0": "guahiban",
                            "1": "guahiban",
                            "2": 5,
                            "3": "3",
                            "4": "60.00"
                        },
                        {
                            "0": "kiowa-tanoan",
                            "1": "kiowa-tanoan",
                            "2": 5,
                            "3": "3",
                            "4": "60.00"
                        },
                        {
                            "0": "tupian",
                            "1": "tupi-guaraní",
                            "2": 17,
                            "3": "10",
                            "4": "58.82"
                        },
                        {
                            "0": "pama-nyungan",
                            "1": "southeastern pama-nyungan",
                            "2": 17,
                            "3": "10",
                            "4": "58.82"
                        },
                        {
                            "0": "siouan",
                            "1": "core siouan",
                            "2": 12,
                            "3": "7",
                            "4": "58.33"
                        },
                        {
                            "0": "oto-manguean",
                            "1": "popolocan",
                            "2": 7,
                            "3": "4",
                            "4": "57.14"
                        },
                        {
                            "0": "uto-aztecan",
                            "1": "numic",
                            "2": 7,
                            "3": "4",
                            "4": "57.14"
                        },
                        {
                            "0": "dravidian",
                            "1": "southern dravidian",
                            "2": 9,
                            "3": "5",
                            "4": "55.56"
                        },
                        {
                            "0": "panoan",
                            "1": "panoan",
                            "2": 11,
                            "3": "6",
                            "4": "54.55"
                        },
                        {
                            "0": "nakh-daghestanian",
                            "1": "avar-andic-tsezic",
                            "2": 13,
                            "3": "7",
                            "4": "53.85"
                        },
                        {
                            "0": "algic",
                            "1": "algonquian",
                            "2": 28,
                            "3": "15",
                            "4": "53.57"
                        },
                        {
                            "0": "pama-nyungan",
                            "1": "central pama-nyungan",
                            "2": 15,
                            "3": "8",
                            "4": "53.33"
                        },
                        {
                            "0": "salishan",
                            "1": "interior salish",
                            "2": 8,
                            "3": "4",
                            "4": "50.00"
                        },
                        {
                            "0": "quechuan",
                            "1": "quechuan",
                            "2": 11,
                            "3": "5",
                            "4": "45.45"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "bodic",
                            "2": 31,
                            "3": "13",
                            "4": "41.94"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "mahakiranti",
                            "2": 17,
                            "3": "7",
                            "4": "41.18"
                        },
                        {
                            "0": "northwest caucasian",
                            "1": "northwest caucasian",
                            "2": 5,
                            "3": "2",
                            "4": "40.00"
                        },
                        {
                            "0": "nyulnyulan",
                            "1": "nyulnyulan",
                            "2": 5,
                            "3": "2",
                            "4": "40.00"
                        },
                        {
                            "0": "lakes plain",
                            "1": "lakes plain",
                            "2": 5,
                            "3": "2",
                            "4": "40.00"
                        },
                        {
                            "0": "pama-nyungan",
                            "1": "western pama-nyungan",
                            "2": 43,
                            "3": "17",
                            "4": "39.53"
                        },
                        {
                            "0": "khoe-kwadi",
                            "1": "khoe-kwadi",
                            "2": 6,
                            "3": "2",
                            "4": "33.33"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "bodo-garo",
                            "2": 6,
                            "3": "2",
                            "4": "33.33"
                        },
                        {
                            "0": "indo-european",
                            "1": "celtic",
                            "2": 6,
                            "3": "2",
                            "4": "33.33"
                        },
                        {
                            "0": "eskimo-aleut",
                            "1": "eskimo",
                            "2": 9,
                            "3": "3",
                            "4": "33.33"
                        },
                        {
                            "0": "nakh-daghestanian",
                            "1": "lezgic",
                            "2": 10,
                            "3": "3",
                            "4": "30.00"
                        },
                        {
                            "0": "mayan",
                            "1": "mayan",
                            "2": 34,
                            "3": "10",
                            "4": "29.41"
                        },
                        {
                            "0": "uto-aztecan",
                            "1": "aztecan",
                            "2": 11,
                            "3": "3",
                            "4": "27.27"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "berber",
                            "2": 11,
                            "3": "3",
                            "4": "27.27"
                        },
                        {
                            "0": "austronesian",
                            "1": "celebic",
                            "2": 12,
                            "3": "3",
                            "4": "25.00"
                        },
                        {
                            "0": "indo-european",
                            "1": "slavic",
                            "2": 16,
                            "3": "4",
                            "4": "25.00"
                        },
                        {
                            "0": "salishan",
                            "1": "central salish",
                            "2": 8,
                            "3": "2",
                            "4": "25.00"
                        },
                        {
                            "0": "indo-european",
                            "1": "germanic",
                            "2": 21,
                            "3": "5",
                            "4": "23.81"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "lowland east cushitic",
                            "2": 13,
                            "3": "3",
                            "4": "23.08"
                        },
                        {
                            "0": "austro-asiatic",
                            "1": "munda",
                            "2": 9,
                            "3": "2",
                            "4": "22.22"
                        },
                        {
                            "0": "eastern sudanic",
                            "1": "surmic",
                            "2": 9,
                            "3": "2",
                            "4": "22.22"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "kuki-chin",
                            "2": 23,
                            "3": "5",
                            "4": "21.74"
                        },
                        {
                            "0": "austronesian",
                            "1": "malayo-sumbawan",
                            "2": 20,
                            "3": "4",
                            "4": "20.00"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "southern cushitic",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "border",
                            "1": "border",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "niger-congo",
                            "1": "mel",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "austro-asiatic",
                            "1": "aslian",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "binanderean",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "hokan",
                            "1": "pomoan",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "altaic",
                            "1": "tungusic",
                            "2": 10,
                            "3": "2",
                            "4": "20.00"
                        },
                        {
                            "0": "hmong-mien",
                            "1": "hmong-mien",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "austro-asiatic",
                            "1": "palaung-khmuic",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "uto-aztecan",
                            "1": "tepiman",
                            "2": 5,
                            "3": "1",
                            "4": "20.00"
                        },
                        {
                            "0": "altaic",
                            "1": "turkic",
                            "2": 33,
                            "3": "6",
                            "4": "18.18"
                        },
                        {
                            "0": "austronesian",
                            "1": "oceanic",
                            "2": 147,
                            "3": "24",
                            "4": "16.33"
                        },
                        {
                            "0": "dravidian",
                            "1": "south-central dravidian",
                            "2": 7,
                            "3": "1",
                            "4": "14.29"
                        },
                        {
                            "0": "indo-european",
                            "1": "indic",
                            "2": 47,
                            "3": "6",
                            "4": "12.77"
                        },
                        {
                            "0": "niger-congo",
                            "1": "platoid",
                            "2": 8,
                            "3": "1",
                            "4": "12.50"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "semitic",
                            "2": 33,
                            "3": "4",
                            "4": "12.12"
                        },
                        {
                            "0": "niger-congo",
                            "1": "northern atlantic",
                            "2": 18,
                            "3": "2",
                            "4": "11.11"
                        },
                        {
                            "0": "austronesian",
                            "1": "greater central philippine",
                            "2": 20,
                            "3": "2",
                            "4": "10.00"
                        },
                        {
                            "0": "altaic",
                            "1": "mongolic",
                            "2": 10,
                            "3": "1",
                            "4": "10.00"
                        },
                        {
                            "0": "mixe-zoque",
                            "1": "mixe-zoque",
                            "2": 10,
                            "3": "1",
                            "4": "10.00"
                        },
                        {
                            "0": "indo-european",
                            "1": "iranian",
                            "2": 24,
                            "3": "2",
                            "4": "8.33"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "burmese-lolo",
                            "2": 13,
                            "3": "1",
                            "4": "7.69"
                        },
                        {
                            "0": "tai-kadai",
                            "1": "kam-tai",
                            "2": 13,
                            "3": "1",
                            "4": "7.69"
                        },
                        {
                            "0": "niger-congo",
                            "1": "adamawa",
                            "2": 13,
                            "3": "1",
                            "4": "7.69"
                        },
                        {
                            "0": "oto-manguean",
                            "1": "zapotecan",
                            "2": 13,
                            "3": "1",
                            "4": "7.69"
                        },
                        {
                            "0": "other",
                            "1": "creoles and pidgins",
                            "2": 28,
                            "3": "2",
                            "4": "7.14"
                        },
                        {
                            "0": "mande",
                            "1": "western mande",
                            "2": 19,
                            "3": "1",
                            "4": "5.26"
                        },
                        {
                            "0": "niger-congo",
                            "1": "kwa",
                            "2": 20,
                            "3": "1",
                            "4": "5.00"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "biu-mandara",
                            "2": 24,
                            "3": "1",
                            "4": "4.17"
                        },
                        {
                            "0": "austronesian",
                            "1": "central malayo-polynesian",
                            "2": 28,
                            "3": "1",
                            "4": "3.57"
                        },
                        {
                            "0": "niger-congo",
                            "1": "bantoid",
                            "2": 153,
                            "3": "5",
                            "4": "3.27"
                        },
                        {
                            "0": "niger-congo",
                            "1": "gur",
                            "2": 34,
                            "3": "1",
                            "4": "2.94"
                        },
                        {
                            "0": "other",
                            "1": "sign languages",
                            "2": 39,
                            "3": "1",
                            "4": "2.56"
                        },
                        {
                            "0": "eastern sudanic",
                            "1": "nilotic",
                            "2": 18,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "eastern highlands",
                            "2": 13,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "awju-dumut",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "oto-manguean",
                            "1": "mixtecan",
                            "2": 16,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austronesian",
                            "1": "south halmahera - west new guinea",
                            "2": 10,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "sepik",
                            "1": "middle sepik",
                            "2": 6,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "madang",
                            "2": 13,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "angan",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "niger-congo",
                            "1": "kru",
                            "2": 10,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austronesian",
                            "1": "south sulawesi",
                            "2": 10,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "indo-european",
                            "1": "romance",
                            "2": 17,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "torricelli",
                            "1": "wapei-palei",
                            "2": 6,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "central sudanic",
                            "1": "moru-ma'di",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "west chadic",
                            "2": 14,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "central sudanic",
                            "1": "bongo-bagirmi",
                            "2": 13,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austro-asiatic",
                            "1": "bahnaric",
                            "2": 15,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "niger-congo",
                            "1": "ubangi",
                            "2": 17,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austronesian",
                            "1": "northern luzon",
                            "2": 11,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austronesian",
                            "1": "sama-bajaw",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austronesian",
                            "1": "north borneo",
                            "2": 10,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "koiarian",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "austronesian",
                            "1": "northwest sumatra-barrier islands",
                            "2": 8,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "north omotic",
                            "2": 9,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "mande",
                            "1": "eastern mande",
                            "2": 8,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "afro-asiatic",
                            "1": "east chadic",
                            "2": 7,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "niger-congo",
                            "1": "edoid",
                            "2": 8,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "finisterre-huon",
                            "2": 8,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "karen",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "trans-new guinea",
                            "1": "chimbu",
                            "2": 8,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "oto-manguean",
                            "1": "chinantecan",
                            "2": 7,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "niger-congo",
                            "1": "cross river",
                            "2": 9,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "uralic",
                            "1": "samoyedic",
                            "2": 5,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "uralic",
                            "1": "finnic",
                            "2": 7,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "west papuan",
                            "1": "north halmaheran",
                            "2": 8,
                            "3": "0",
                            "4": "0.00"
                        },
                        {
                            "0": "sino-tibetan",
                            "1": "chinese",
                            "2": 6,
                            "3": "0",
                            "4": "0.00"
                        }
                    ],
                    "columns": [
                        {
                            "title": "Family_Name",
                            "field": "0",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Genus_Name",
                            "field": "1",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Total_Languages",
                            "field": "2",
                            "dataType": {
                                "type": 4,
                                "flags": [
                                    "SIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 10,
                                "parameterFormatType": "OneOrZero",
                                "synonyms": [
                                    "INTEGER",
                                    "INT4"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangered_Languages",
                            "field": "3",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangerment_Rate_Percentage",
                            "field": "4",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        }
                    ],
                    "executionInfo": {
                        "text": "OK, 121 records retrieved in 15.947ms"
                    },
                    "totalRowCount": 121,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 2,
                    "sql": "\n\n-- Query: Endangerment Rates per Genus\nSELECT * FROM GenusEndangermentDataMart\nWHERE Total_Languages >= 5\nORDER BY Endangerment_Rate_Percentage DESC",
                    "updatable": false,
                    "fullTableName": "GenusEndangermentDataMart"
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "42127f68-9f7c-4602-890d-bf204f310201",
                    "rows": [
                        {
                            "0": "aikaná",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "great andamanese",
                            "1": 4,
                            "2": "4",
                            "3": "100.00"
                        },
                        {
                            "0": "huarpe",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "harakmbet",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "andoke",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "zaparoan",
                            "1": 3,
                            "2": "3",
                            "3": "100.00"
                        },
                        {
                            "0": "tacanan",
                            "1": 4,
                            "2": "4",
                            "3": "100.00"
                        },
                        {
                            "0": "tacame",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "atakapa",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "barbacoan",
                            "1": 4,
                            "2": "4",
                            "3": "100.00"
                        },
                        {
                            "0": "zamucoan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chumash",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "beothuk",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "betoi",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "bororoan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "bunuban",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "camsá",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "cayuvava",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "aymaran",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "cholon",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chitimacha",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "coahuiltecan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "comecrudan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "cuitlatec",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "jabutí",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "choco",
                            "1": 5,
                            "2": "5",
                            "3": "100.00"
                        },
                        {
                            "0": "esselen",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "guató",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "hadza",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "itonama",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "iwaidjan",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "kalapuyan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "eastern daly",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "katukinan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kapixana",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "karankawa",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "karok",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yeniseian",
                            "1": 3,
                            "2": "3",
                            "3": "100.00"
                        },
                        {
                            "0": "jarrakan",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "kunza",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kuot",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kutenai",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "kwaza",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "leko",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "lule",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "máku",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chimúan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "moraori",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "mosetenan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "movima",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "northern daly",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "natchez",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "nahali",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yukaghir",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "chon",
                            "1": 3,
                            "2": "3",
                            "3": "100.00"
                        },
                        {
                            "0": "sáliban",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "puinave",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yaruro",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "puquina",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tarascan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "alacalufan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "salinan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "huavean",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "shabo",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "sulung",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "gapun",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "takelma",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "taushiro",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "ticuna",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "timote-cuica",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "timucua",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tiwian",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tol",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tonkawa",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "trumai",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tunica",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "urarina",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "wagiman",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "waorani",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "warao",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yangmanic",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "chapacura-wanham",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "washo",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "tu",
                            "1": 2,
                            "2": "2",
                            "3": "100.00"
                        },
                        {
                            "0": "peba-yaguan",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yámana",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yuchi",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "yurimangí",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "zuni",
                            "1": 1,
                            "2": "1",
                            "3": "100.00"
                        },
                        {
                            "0": "na-dene",
                            "1": 24,
                            "2": "23",
                            "3": "95.83"
                        },
                        {
                            "0": "gunwinyguan",
                            "1": 9,
                            "2": "8",
                            "3": "88.89"
                        },
                        {
                            "0": "totonacan",
                            "1": 6,
                            "2": "5",
                            "3": "83.33"
                        },
                        {
                            "0": "wakashan",
                            "1": 5,
                            "2": "4",
                            "3": "80.00"
                        },
                        {
                            "0": "arawakan",
                            "1": 28,
                            "2": "22",
                            "3": "78.57"
                        },
                        {
                            "0": "macro-ge",
                            "1": 13,
                            "2": "10",
                            "3": "76.92"
                        },
                        {
                            "0": "jivaroan",
                            "1": 4,
                            "2": "3",
                            "3": "75.00"
                        },
                        {
                            "0": "mangarrayi-maran",
                            "1": 4,
                            "2": "3",
                            "3": "75.00"
                        },
                        {
                            "0": "iroquoian",
                            "1": 8,
                            "2": "6",
                            "3": "75.00"
                        },
                        {
                            "0": "cariban",
                            "1": 17,
                            "2": "12",
                            "3": "70.59"
                        },
                        {
                            "0": "hokan",
                            "1": 18,
                            "2": "12",
                            "3": "66.67"
                        },
                        {
                            "0": "muskogean",
                            "1": 6,
                            "2": "4",
                            "3": "66.67"
                        },
                        {
                            "0": "oregon coast",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "tucanoan",
                            "1": 18,
                            "2": "12",
                            "3": "66.67"
                        },
                        {
                            "0": "nadahup",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "mirndi",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "tangkic",
                            "1": 3,
                            "2": "2",
                            "3": "66.67"
                        },
                        {
                            "0": "tupian",
                            "1": 22,
                            "2": "14",
                            "3": "63.64"
                        },
                        {
                            "0": "chibchan",
                            "1": 16,
                            "2": "10",
                            "3": "62.50"
                        },
                        {
                            "0": "siouan",
                            "1": 13,
                            "2": "8",
                            "3": "61.54"
                        },
                        {
                            "0": "guaicuruan",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "caddoan",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "guahiban",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "kiowa-tanoan",
                            "1": 5,
                            "2": "3",
                            "3": "60.00"
                        },
                        {
                            "0": "algic",
                            "1": 30,
                            "2": "17",
                            "3": "56.67"
                        },
                        {
                            "0": "panoan",
                            "1": 11,
                            "2": "6",
                            "3": "54.55"
                        },
                        {
                            "0": "penutian",
                            "1": 22,
                            "2": "12",
                            "3": "54.55"
                        },
                        {
                            "0": "pama-nyungan",
                            "1": 107,
                            "2": "58",
                            "3": "54.21"
                        }
                    ],
                    "columns": [
                        {
                            "title": "Family_Name",
                            "field": "0",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Total_Languages",
                            "field": "1",
                            "dataType": {
                                "type": 4,
                                "flags": [
                                    "SIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 10,
                                "parameterFormatType": "OneOrZero",
                                "synonyms": [
                                    "INTEGER",
                                    "INT4"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangered_Languages",
                            "field": "2",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangerment_Rate_Percentage",
                            "field": "3",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        }
                    ],
                    "executionInfo": {
                        "text": "OK, 117 records retrieved in 6.057ms"
                    },
                    "totalRowCount": 117,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 3,
                    "sql": "\n\n-- Query: High-Risk Families (Endangerment Rate > 50%)\nSELECT * FROM FamilyEndangermentDataMart\nWHERE Endangerment_Rate_Percentage > 50\nORDER BY Endangerment_Rate_Percentage DESC",
                    "updatable": false,
                    "fullTableName": "FamilyEndangermentDataMart"
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "e00cb330-5b15-46fc-e3d0-0a169488f29f",
                    "rows": [
                        {
                            "0": "South America",
                            "1": 249,
                            "2": "170",
                            "3": "68.27"
                        },
                        {
                            "0": "Australia",
                            "1": 164,
                            "2": "91",
                            "3": "55.49"
                        },
                        {
                            "0": "North America",
                            "1": 361,
                            "2": "183",
                            "3": "50.69"
                        },
                        {
                            "0": "Eurasia",
                            "1": 562,
                            "2": "130",
                            "3": "23.13"
                        },
                        {
                            "0": "Papunesia",
                            "1": 549,
                            "2": "49",
                            "3": "8.93"
                        },
                        {
                            "0": "Africa",
                            "1": 576,
                            "2": "42",
                            "3": "7.29"
                        },
                        {
                            "0": "",
                            "1": 1,
                            "2": "0",
                            "3": "0.00"
                        }
                    ],
                    "columns": [
                        {
                            "title": "Macroarea",
                            "field": "0",
                            "dataType": {
                                "type": 17,
                                "characterMaximumLength": 65535,
                                "flags": [
                                    "BINARY",
                                    "ASCII",
                                    "UNICODE"
                                ],
                                "needsQuotes": true,
                                "parameterFormatType": "OneOrZero"
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Total_Languages",
                            "field": "1",
                            "dataType": {
                                "type": 4,
                                "flags": [
                                    "SIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 10,
                                "parameterFormatType": "OneOrZero",
                                "synonyms": [
                                    "INTEGER",
                                    "INT4"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangered_Languages",
                            "field": "2",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        },
                        {
                            "title": "Endangerment_Rate_Percentage",
                            "field": "3",
                            "dataType": {
                                "type": 10,
                                "flags": [
                                    "UNSIGNED",
                                    "ZEROFILL"
                                ],
                                "numericPrecision": 65,
                                "numericScale": 30,
                                "parameterFormatType": "TwoOrOneOrZero",
                                "synonyms": [
                                    "FIXED",
                                    "NUMERIC",
                                    "DEC"
                                ]
                            },
                            "inPK": false,
                            "nullable": false,
                            "autoIncrement": false
                        }
                    ],
                    "executionInfo": {
                        "text": "OK, 7 records retrieved in 12.966ms"
                    },
                    "totalRowCount": 7,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 4,
                    "sql": "\n\n-- Query: Endangerment Rates per Macroarea\nSELECT * FROM MacroareaEndangermentDataMart\nORDER BY Endangerment_Rate_Percentage DESC",
                    "updatable": false,
                    "fullTableName": "MacroareaEndangermentDataMart"
                },
                {
                    "tabId": "f05e2b5f-35c1-4979-da63-8f119fbb0e24",
                    "resultId": "222722cc-cd06-4206-a470-30f5872512bb",
                    "rows": [],
                    "executionInfo": {
                        "text": "OK, 0 records retrieved in 7.35ms",
                        "type": 4
                    },
                    "totalRowCount": 0,
                    "hasMoreRows": false,
                    "currentPage": 0,
                    "index": 0,
                    "sql": "-- analysis_queries.sql\n-- This script contains SQL queries used for data analysis.\n\nUSE LanguageEndangermentDB",
                    "updatable": false
                }
            ]
        },
        {
            "state": {
                "start": 254,
                "end": 279,
                "language": "mysql",
                "result": {
                    "type": "text",
                    "text": [
                        {
                            "type": 4,
                            "index": 0,
                            "resultId": "268c7369-601c-4c66-9aa6-5359c8a2855d",
                            "content": "OK, 0 records retrieved in 93.938ms"
                        },
                        {
                            "type": 4,
                            "index": 1,
                            "resultId": "67ff33b4-2849-4582-be19-38d3feddc443",
                            "content": "OK, 254 rows affected in 53.205ms"
                        },
                        {
                            "type": 4,
                            "index": 2,
                            "resultId": "9fd7ac38-3658-4a4d-f0bd-a0098f3a6f01",
                            "content": "OK, 0 records retrieved in 1.964ms"
                        },
                        {
                            "type": 4,
                            "index": 4,
                            "resultId": "4bb9f2c5-06f3-4156-ef25-c62896964e95",
                            "content": "OK, 0 records retrieved in 4.692ms"
                        }
                    ]
                },
                "currentHeight": 28,
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 95
                        },
                        "contentStart": 44,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 95,
                            "length": 128
                        },
                        "contentStart": 135,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 223,
                            "length": 64
                        },
                        "contentStart": 255,
                        "state": 0
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 287,
                            "length": 38
                        },
                        "contentStart": 313,
                        "state": 4
                    },
                    {
                        "delimiter": "//",
                        "span": {
                            "start": 325,
                            "length": 249
                        },
                        "contentStart": 347,
                        "state": 0
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 574,
                            "length": 36
                        },
                        "contentStart": 599,
                        "state": 4
                    },
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 610,
                            "length": 1
                        },
                        "contentStart": 609,
                        "state": 3
                    }
                ]
            },
            "data": []
        },
        {
            "state": {
                "start": 280,
                "end": 280,
                "language": "mysql",
                "currentSet": 1,
                "statements": [
                    {
                        "delimiter": ";",
                        "span": {
                            "start": 0,
                            "length": 0
                        },
                        "contentStart": 0,
                        "state": 0
                    }
                ]
            },
            "data": []
        }
    ]
}