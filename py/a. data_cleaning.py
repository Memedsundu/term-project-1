# data_cleaning.py
# This script cleans and prepares the data for import into MySQL.

import pandas as pd
import numpy as np
import os
import csv

# ------------------------------------------------
# 1. Define File Paths
# ------------------------------------------------
LANGUOID_CSV = '/path/to/languoid.csv'
LANGUAGE_CSV = '/path/to/language.csv'
LANGUAGES_AND_DIALECTS_GEO_CSV = '/path/to/languages-and-dialects-geo.csv'

# Output directory for cleaned data
CLEANED_DATA_DIR = '/path/to/cleaned_data'
os.makedirs(CLEANED_DATA_DIR, exist_ok=True)

# ------------------------------------------------
# 2. Preprocess CSV Files to Standardize Quotes
# ------------------------------------------------
def preprocess_csv(input_path, output_path):
    """
    Preprocesses a CSV file by standardizing quotes and escaping delimiters.
    """
    with open(input_path, 'r', encoding='utf-8') as infile, \
         open(output_path, 'w', encoding='utf-8', newline='') as outfile:
        reader = csv.reader(infile, delimiter=',', quotechar="'", escapechar='\\')
        writer = csv.writer(outfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        for row in reader:
            writer.writerow(row)

# Preprocess each CSV file
preprocess_csv(LANGUOID_CSV, os.path.join(CLEANED_DATA_DIR, 'preprocessed_languoid.csv'))
preprocess_csv(LANGUAGE_CSV, os.path.join(CLEANED_DATA_DIR, 'preprocessed_language.csv'))
preprocess_csv(LANGUAGES_AND_DIALECTS_GEO_CSV, os.path.join(CLEANED_DATA_DIR, 'preprocessed_languages_and_dialects_geo.csv'))

print("Preprocessing of CSV files completed.")

# Update file paths to preprocessed files
PREPROCESSED_LANGUOID_CSV = os.path.join(CLEANED_DATA_DIR, 'preprocessed_languoid.csv')
PREPROCESSED_LANGUAGE_CSV = os.path.join(CLEANED_DATA_DIR, 'preprocessed_language.csv')
PREPROCESSED_LANGUAGES_AND_DIALECTS_GEO_CSV = os.path.join(CLEANED_DATA_DIR, 'preprocessed_languages_and_dialects_geo.csv')

# ------------------------------------------------
# 3. Read Preprocessed CSV Files with Enhanced Error Handling
# ------------------------------------------------
def read_csv_with_logging(path, **kwargs):
    bad_lines = []

    def bad_line_handler(bad_line):
        bad_lines.append(bad_line)
        return None  # Skip the bad line

    df = pd.read_csv(
        path,
        sep=',',
        quotechar='"',
        escapechar='\\',
        encoding='utf-8',
        engine='python',
        on_bad_lines=bad_line_handler,
        **kwargs
    )
    return df, bad_lines

# Read preprocessed_languoid.csv
languoid_df, languoid_bad = read_csv_with_logging(
    PREPROCESSED_LANGUOID_CSV,
    dtype=str,
    na_values=['', 'NULL', 'NaN']
)
print("Successfully loaded preprocessed_languoid.csv")
if languoid_bad:
    print(f"Found {len(languoid_bad)} bad lines in preprocessed_languoid.csv.")

# Read preprocessed_language.csv
language_df, language_bad = read_csv_with_logging(
    PREPROCESSED_LANGUAGE_CSV,
    dtype=str,
    na_values=['', 'NULL', 'NaN']
)
print("Successfully loaded preprocessed_language.csv")
if language_bad:
    print(f"Found {len(language_bad)} bad lines in preprocessed_language.csv.")

# Read preprocessed_languages-and-dialects-geo.csv
languages_geo_df, languages_geo_bad = read_csv_with_logging(
    PREPROCESSED_LANGUAGES_AND_DIALECTS_GEO_CSV,
    dtype=str,
    na_values=['', 'NULL', 'NaN']
)
print("Successfully loaded preprocessed_languages-and-dialects-geo.csv")
if languages_geo_bad:
    print(f"Found {len(languages_geo_bad)} bad lines in preprocessed_languages-and-dialects-geo.csv.")

# ------------------------------------------------
# 4. Clean and Standardize Data
# ------------------------------------------------
# Clean 'status' field in languoid_df
def clean_status(status):
    if pd.isnull(status):
        return 'unknown'
    return status.replace("'", "").replace("\n", "").strip().lower()

languoid_df['status_cleaned'] = languoid_df['status'].apply(clean_status)

# Clean 'family' and 'genus' in language_df
language_df['family'] = language_df['family'].str.strip().str.lower()
language_df['genus'] = language_df['genus'].str.strip().str.lower()

# Clean 'name' fields
languoid_df['name'] = languoid_df['name'].str.strip()
language_df['Name'] = language_df['Name'].str.strip()
languages_geo_df['name'] = languages_geo_df['name'].str.strip()

# Remove duplicates
languoid_df = languoid_df.drop_duplicates(subset='id')
language_df = language_df.drop_duplicates(subset='glottocode')
languages_geo_df = languages_geo_df.drop_duplicates(subset='glottocode')

# ------------------------------------------------
# 5. Merge Datasets on Glottocode
# ------------------------------------------------
# Merge language_df with languoid_df
merged_df = pd.merge(
    language_df,
    languoid_df[['id', 'status_cleaned']],
    how='left',
    left_on='glottocode',
    right_on='id'
)

# Merge with languages_geo_df
merged_df = pd.merge(
    merged_df,
    languages_geo_df[['glottocode', 'latitude', 'longitude', 'macroarea']],
    how='left',
    on='glottocode'
)

# ------------------------------------------------
# 6. Final Cleaning and Preparation
# ------------------------------------------------
# Fill missing 'status_cleaned'
merged_df['status_cleaned'] = merged_df['status_cleaned'].fillna('unknown')

# Rename and select columns
final_df = merged_df.rename(columns={
    'glottocode': 'Language_ID',
    'Name': 'Language_Name',
    'iso_code': 'ISO_Code',
    'family': 'Family_Name',
    'genus': 'Genus_Name',
    'status_cleaned': 'Status',
    'macroarea': 'Macroarea',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
    'countrycodes': 'Countrycodes'
})

# Handle missing values
final_df['Family_Name'] = final_df['Family_Name'].fillna('unknown')
final_df['Genus_Name'] = final_df['Genus_Name'].fillna('unknown')

# ------------------------------------------------
# 7. Extract Families and Genera Tables
# ------------------------------------------------
# Families
families_df = final_df[['Family_Name']].drop_duplicates().reset_index(drop=True)
families_df['Family_ID'] = families_df.index + 1

# Genera
genera_df = final_df[['Genus_Name', 'Family_Name']].drop_duplicates().reset_index(drop=True)
genera_df = pd.merge(genera_df, families_df, on='Family_Name', how='left')
genera_df['Genus_ID'] = genera_df.index + 1

# Assign IDs to Languages
final_df = pd.merge(final_df, families_df, on='Family_Name', how='left')
final_df = pd.merge(final_df, genera_df[['Genus_Name', 'Genus_ID']], on='Genus_Name', how='left')

# ------------------------------------------------
# 8. Export Cleaned Data to CSV
# ------------------------------------------------
# Export Families
families_df.to_csv(os.path.join(CLEANED_DATA_DIR, 'Families.csv'), index=False, columns=['Family_ID', 'Family_Name'])
print("Exported Families.csv")

# Export Genera
genera_df.to_csv(os.path.join(CLEANED_DATA_DIR, 'Genera.csv'), index=False, columns=['Genus_ID', 'Genus_Name', 'Family_ID'])
print("Exported Genera.csv")

# Export Languages
languages_export_df = final_df[['Language_ID', 'Language_Name', 'ISO_Code', 'Family_ID', 'Genus_ID', 'Status', 'Macroarea', 'Latitude', 'Longitude', 'Countrycodes']]
languages_export_df.to_csv(os.path.join(CLEANED_DATA_DIR, 'Languages.csv'), index=False)
print("Exported Languages.csv")

print("\nData Cleaning Process Completed Successfully!")
print(f"Cleaned data exported to directory: {CLEANED_DATA_DIR}")
