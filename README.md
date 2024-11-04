# term-project-1
# Language Endangerment Analysis Project

## Overview

This project aims to analyze patterns of language endangerment across different language families and genera. The analysis identifies high-risk families and genera, examines geographical patterns, and provides insights for language preservation efforts.

## Table of Contents

- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
  - [1. Data Preparation](#1-data-preparation)
  - [2. Database Setup](#2-database-setup)
  - [3. ETL Process](#3-etl-process)
  - [4. Data Marts Creation](#4-data-marts-creation)
  - [5. Data Analysis](#5-data-analysis)
  - [6. Visualization](#6-visualization)
- [Project Details](#project-details)
  - [Entity-Relationship Diagram](#entity-relationship-diagram)
  - [Data Cleaning Process](#data-cleaning-process)
  - [ETL Pipeline](#etl-pipeline)
  - [Data Marts](#data-marts)
- [Reproducibility](#reproducibility)
- [Contact](#contact)

---

## Project Structure

Term1/
├── data/
│   ├── Families.csv
│   ├── Genera.csv
│   ├── Languages.csv
├── sql_scripts/
│   ├── create_database.sql
│   ├── create_tables.sql
│   ├── import_data.sql
│   ├── create_etl_procedures.sql
│   ├── create_triggers.sql
│   ├── create_views.sql
│   ├── analysis_queries.sql
│   └── create_materialized_views.sql
├── python_scripts/
│   ├── data_cleaning.py
│   └── data_visualization.py
├── docs/
│   └── README.md
├── results/
│   ├── endangerment_rates_per_family_genus.csv
│   ├── language_endangerment_map.html
└── .git/



## Prerequisites

- **Python 3.x** installed on your system.
- **MySQL Server** installed and running.
- **Required Python Libraries**:
  - pandas
  - numpy
  - matplotlib
  - seaborn
  - folium
- **Raw Data Files** from Glottolog:
  - `languoid.csv`
  - `language.csv`
  - `languages-and-dialects-geo.csv`

## Setup Instructions

### 1. Data Preparation

#### a. Data Cleaning

- **Purpose**: Clean and preprocess raw data files for import into MySQL.
- **Steps**:
  1. Place the raw data files in a directory (update the file paths in the script accordingly).
     - `languoid.csv`
     - `language.csv`
     - `languages-and-dialects-geo.csv`
  2. Navigate to the `python_scripts/` directory.
  3. Open `data_cleaning.py` and update the file paths to match your directory structure.
  4. Run the script:
     ```bash
     python data_cleaning.py
     ```
  5. The cleaned data files (`Families.csv`, `Genera.csv`, `Languages.csv`) will be exported to the `data/` directory.

### 2. Database Setup

#### a. Create the Database

- **Purpose**: Set up the MySQL database to store the operational data.
- **Steps**:
  1. Open a MySQL client (e.g., MySQL Command Line, MySQL Workbench).
  2. Navigate to the `sql_scripts/` directory.
  3. Execute `create_database.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/create_database.sql;
     ```
  4. This will create the `LanguageEndangermentDB` database.

#### b. Create Operational Tables

- **Purpose**: Create the normalized tables for storing families, genera, and languages.
- **Steps**:
  1. Execute `create_tables.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/create_tables.sql;
     ```

### 3. ETL Process

#### a. Import Data into Operational Tables

- **Purpose**: Load the cleaned data into the operational tables.
- **Steps**:
  1. **Check `secure_file_priv` Variable**:
     ```sql
     SHOW VARIABLES LIKE 'secure_file_priv';
     ```
     - This will show the directory from which MySQL can read files.
     - Place your cleaned CSV files in this directory.
  2. Open `import_data.sql` and update the file paths to point to the CSV files in the `secure_file_priv` directory.
  3. Execute `import_data.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/import_data.sql;
     ```

#### b. Create ETL Stored Procedures

- **Purpose**: Create procedures to extract, transform, and load data into the analytical table.
- **Steps**:
  1. Execute `create_etl_procedures.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/create_etl_procedures.sql;
     ```

#### c. Set Up Triggers

- **Purpose**: Automate the ETL process whenever data changes occur.
- **Steps**:
  1. Execute `create_triggers.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/create_triggers.sql;
     ```

### 4. Data Marts Creation

#### a. Create Views

- **Purpose**: Create views to serve as data marts for analytical queries.
- **Steps**:
  1. Execute `create_views.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/create_views.sql;
     ```

#### b. Optional: Create Materialized Views

- **Purpose**: Create materialized views for performance optimization.
- **Steps**:
  1. Ensure the event scheduler is enabled:
     ```sql
     SET GLOBAL event_scheduler = ON;
     ```
  2. Execute `create_materialized_views.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/create_materialized_views.sql;
     ```

### 5. Data Analysis

- **Purpose**: Perform analytical queries to extract insights.
- **Steps**:
  1. Execute `analysis_queries.sql`:
     ```sql
     SOURCE /path/to/sql_scripts/analysis_queries.sql;
     ```
  2. Export query results as needed (e.g., to CSV files for visualization).
     - Use `INTO OUTFILE` clause in SQL or export functionality in your MySQL client.

### 6. Visualization

#### a. Generate Visualizations

- **Purpose**: Create visual representations of the analysis results.
- **Steps**:
  1. Navigate to the `python_scripts/` directory.
  2. Ensure the CSV files for visualization are in place (e.g., `endangerment_rates_per_family_genus.csv`).
  3. Open `data_visualization.py` and update file paths if necessary.
  4. Run the script:
     ```bash
     python data_visualization.py
     ```
  5. Visualizations will be saved in the `results/` directory:
     - Bar charts (e.g., `top_10_genera_endangerment_rate.png`)
     - Interactive map (`language_endangerment_map.html`)

#### b. View Results

- Open the HTML map file (`language_endangerment_map.html`) in a web browser to interact with the map.
- View the generated charts using an image viewer or within your development environment.

---

## Project Details

### Entity-Relationship Diagram

The database schema consists of three main tables with the following relationships:

- **Families**:
  - `Family_ID` (Primary Key)
  - `Family_Name`
- **Genera**:
  - `Genus_ID` (Primary Key)
  - `Genus_Name`
  - `Family_ID` (Foreign Key referencing `Families(Family_ID)`)
- **Languages**:
  - `Language_ID` (Primary Key)
  - `Language_Name`
  - `ISO_Code`
  - `Family_ID` (Foreign Key referencing `Families(Family_ID)`)
  - `Genus_ID` (Foreign Key referencing `Genera(Genus_ID)`)
  - Other attributes: `Status`, `Macroarea`, `Latitude`, `Longitude`, `Countrycodes`

**Relationships**:

- One `Family` can have many `Genera` (One-to-Many).
- One `Genus` can have many `Languages` (One-to-Many).
- Each `Language` belongs to one `Genus` and one `Family`.

### Data Cleaning Process

- **Standardized Quotes**: Preprocessed CSV files to ensure consistent quoting styles.
- **Error Handling**: Implemented logging to capture and handle bad lines during CSV loading.
- **Data Normalization**: Cleaned fields by trimming whitespace and converting text to lowercase.
- **Duplicate Removal**: Identified and removed duplicate records based on `Glottocode`.
- **Data Merging**: Merged datasets on `Glottocode` to consolidate information.
- **Final Preparation**: Assigned unique IDs, handled missing values, and structured data for database import.

### ETL Pipeline

- **Extract**: Retrieved data from operational tables (`Families`, `Genera`, `Languages`).
- **Transform**:
  - Cleaned and standardized the `Status` field.
  - Joined tables to gather all necessary attributes.
- **Load**: Inserted transformed data into the analytical table `LanguageEndangerment`.
- **Automation**: Used stored procedures and triggers to automate the ETL process upon data changes.

### Data Marts

- **Views Created**:
  - `FamilyEndangermentDataMart`: Aggregated data at the family level.
  - `GenusEndangermentDataMart`: Aggregated data at the genus level.
  - `MacroareaEndangermentDataMart`: Aggregated data by geographical macroarea.
- **Materialized Views**:
  - Created for performance optimization.
  - Scheduled to refresh periodically using MySQL events.

---

## Reproducibility

- **Scripts**: All SQL and Python scripts are provided with comments and instructions.
- **Data Files**: Cleaned data files are generated by the `data_cleaning.py` script.
- **Instructions**: Follow the step-by-step setup instructions to reproduce the project.
- **Version Control**: The project uses Git for version control, ensuring consistency across environments.

---

## Contact

For any questions, issues, or contributions, please contact:

- **Name**: Mehmet Sundu
- **Email**: veysel.sundu@gmail.com
- **GitHub**: [https://github.com/Memedsundu/Term1](https://github.com/Memedsundu/Term1)

---

## Additional Notes

- **Permissions**: Ensure your MySQL user has the necessary permissions to execute all scripts.
- **File Paths**: Update all file paths in the scripts to match your local directory structure.
- **MySQL Configuration**:
  - Check the `secure_file_priv` variable for data import/export.
  - Enable the event scheduler for materialized views:
    ```sql
    SET GLOBAL event_scheduler = ON;
    ```
- **Data Source Acknowledgment**: Data used in this project is sourced from World Language Family Map and World Atlas of Language Structures
 databases.

---

## References

- **World Language Family Map**: https://www.kaggle.com/datasets/rtatman/world-language-family-map/data
- **World Atlas of Language Structures**: [[https://wals.info/](https://wals.info/)](https://www.kaggle.com/datasets/rtatman/world-atlas-of-language-structures?select=wals-data.csv)
- **MySQL Documentation**: [https://dev.mysql.com/doc/](https://dev.mysql.com/doc/)
- **Pandas Documentation**: [https://pandas.pydata.org/docs/](https://pandas.pydata.org/docs/)
- **Folium Documentation**: [https://python-visualization.github.io/folium/](https://python-visualization.github.io/folium/)

---

*Prepared by Mehmet Sundu, for the Term Project of Data Engineering 1, 04/11/2024*

