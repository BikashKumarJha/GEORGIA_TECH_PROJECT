import os
import requests
import zipfile
import io
import pandas as pd
from sqlalchemy import create_engine

VERBOSE = True

def vprint(msg):
    if VERBOSE:
        print(msg)

ETL_DIR = os.path.dirname(__file__)
CSV_FILES = [
    os.path.join(ETL_DIR, "Food Access Research Atlas.csv"),
    os.path.join(ETL_DIR, "ReadMe.csv"),
    os.path.join(ETL_DIR, "VariableLookup.csv")
]
CENTROID_FILE = os.path.join(ETL_DIR, "us_county_coordinates_with_region.csv")

def download_and_extract():
    if all(os.path.exists(f) for f in CSV_FILES):
        vprint("CSV files already exist. Skipping download.")
        return

    zip_url = "https://ers.usda.gov/sites/default/files/_laserfiche/DataFiles/80591/2019%20Food%20Access%20Research%20Atlas%20Data.zip?v=69075"
    response = requests.get(zip_url)
    if response.status_code == 200:
        vprint("Download complete. Extracting files...")
        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            z.extractall(ETL_DIR)
        vprint("Extraction complete.")
    else:
        raise Exception(f"Failed to download data. Status code: {response.status_code}")

def load_data():
    return (
        pd.read_csv(CSV_FILES[0], low_memory=False),
        pd.read_csv(CSV_FILES[1], low_memory=False),
        pd.read_csv(CSV_FILES[2], low_memory=False),
        pd.read_csv(CENTROID_FILE)
    )

def rename_columns(df, lookup_df):
    lookup = {k.lower(): v for k, v in lookup_df.set_index('Field')['LongName'].to_dict().items()}
    df.rename(columns={col: lookup.get(col.lower(), col) for col in df.columns}, inplace=True)
    return df

def clean_data(df):
    desert_cols = [
        "Low income and low access tract measured at 1 mile for urban areas and 10 miles for rural areas",
        "Low income and low access tract measured at 1/2 mile for urban areas and 10 miles for rural areas",
        "Low income and low access tract measured at 1 mile for urban areas and 20 miles for rural areas",
        "Low income and low access tract using vehicle access or low income and low access tract measured at 20 miles"
    ]
    cols = [col for col in desert_cols if col in df.columns]
    if cols:
        df[cols] = df[cols].apply(pd.to_numeric, errors='coerce')
        df['is_food_desert'] = df[cols].max(axis=1).fillna(0).astype(int)
    else:
        df['is_food_desert'] = 0

    if "Population, tract total" in df.columns:
        df["Population, tract total"] = pd.to_numeric(df["Population, tract total"], errors='coerce')

    return df

def aggregate_by_county(df):
    return df.groupby(['State', 'County']).agg({
        "Population, tract total": "sum",
        "is_food_desert": "mean",
        "Tract housing units receiving SNAP benefits, number": "sum",
        "Tract housing units without a vehicle, number": "sum"
    }).reset_index()

def enrich_with_centroids(df, centroids):
    centroids.columns = [col.strip() for col in centroids.columns]
    centroids.rename(columns={'state': 'State', 'county': 'County'}, inplace=True)
    if 'cfips' in centroids.columns:
        centroids['cfips'] = centroids['cfips'].astype(int)
    return pd.merge(df, centroids, on=['State', 'County'], how='left')

def export_to_json(df, path='public/food_insecurity_county_data.json'):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    df = df.rename(columns={
        "Population, tract total": "Total Population",
        "is_food_desert": "Food Desert Score",
        "Tract housing units receiving SNAP benefits, number": "Total SNAP Households",
        "Tract housing units without a vehicle, number": "Households Without Vehicle"
    })
    if 'cfips' in df.columns:
        df['cfips'] = df['cfips'].astype('Int64')
    df.to_json(path, orient='records', indent=2)
    vprint(f"Exported to JSON: {path}")

def save_to_sqlite(df, table='food_deserts_data'):
    engine = create_engine('sqlite:///food_deserts.db')
    df.to_sql(table, engine, if_exists='replace', index=False)
    vprint(f"Saved to SQLite table '{table}'")
    return engine

def main():
    download_and_extract()
    atlas_df, readme_df, var_lookup_df, centroid_df = load_data()
    vprint("📄 Loaded raw data.")
    atlas_df = rename_columns(atlas_df, var_lookup_df)
    atlas_df = clean_data(atlas_df)
    enriched_df = enrich_with_centroids(aggregate_by_county(atlas_df), centroid_df)
    vprint("🧹 Cleaned and enriched data.")
    export_to_json(enriched_df)
    save_to_sqlite(enriched_df)

if __name__ == '__main__':
    main()