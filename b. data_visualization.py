# data_visualization.py
# This script performs data visualization for language endangerment analysis.

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import folium

# ------------------------------------------------
# 1. Bar Chart for Top 10 Genera by Endangerment Rate
# ------------------------------------------------
# Load the exported CSV from analysis
df = pd.read_csv('/path/to/endangerment_rates_per_family_genus.csv')

# Rename columns for clarity
df.columns = ['Family_Name', 'Genus_Name', 'Total_Languages', 'Endangered_Languages', 'Endangerment_Rate_Percentage']

# Select top 10 genera
top_10 = df.head(10)

# Create bar chart
plt.figure(figsize=(12, 8))
sns.barplot(x='Endangerment_Rate_Percentage', y='Genus_Name', data=top_10, palette='Reds_r')
plt.title('Top 10 Genera by Language Endangerment Rate')
plt.xlabel('Endangerment Rate (%)')
plt.ylabel('Genus Name')
plt.tight_layout()
plt.savefig('/path/to/results/top_10_genera_endangerment_rate.png')
plt.show()

print("Bar chart saved as 'top_10_genera_endangerment_rate.png'")

# ------------------------------------------------
# 2. Interactive Map of Language Endangerment
# ------------------------------------------------
# Load language data with geographical coordinates
column_names = [
    'Language_ID', 'Language_Name', 'Family_Name', 'Genus_Name',
    'Status', 'Macroarea', 'Latitude', 'Longitude'
]
data = pd.read_csv('/path/to/language_endangerment_data.csv', header=None, names=column_names)

# Convert latitude and longitude to numeric
data['Latitude'] = pd.to_numeric(data['Latitude'], errors='coerce')
data['Longitude'] = pd.to_numeric(data['Longitude'], errors='coerce')

# Create a base map
m = folium.Map(location=[0, 0], zoom_start=2)

# Add markers to the map
for _, row in data.iterrows():
    if pd.notnull(row['Latitude']) and pd.notnull(row['Longitude']):
        folium.CircleMarker(
            location=[row['Latitude'], row['Longitude']],
            radius=3,
            popup=folium.Popup(
                f"<strong>Language:</strong> {row['Language_Name']}<br>"
                f"<strong>Family:</strong> {row['Family_Name']}<br>"
                f"<strong>Genus:</strong> {row['Genus_Name']}<br>"
                f"<strong>Status:</strong> {row['Status']}<br>"
                f"<strong>Macroarea:</strong> {row['Macroarea']}",
                max_width=250
            ),
            color='red' if 'endangered' in row['Status'] else 'blue',
            fill=True,
            fill_opacity=0.7
        ).add_to(m)

# Save the map to an HTML file
m.save('/path/to/results/language_endangerment_map.html')
print("Map has been saved as 'language_endangerment_map.html'")
