import pandas as pd
import os

FILES_DIR = "utils/cell_counts"
METADATA_FILES_DIR = "azimuth-predictions/hubmap-kidney"

donor_metadata = pd.read_csv(os.path.join(METADATA_FILES_DIR,"hubmap-donors-metadata.tsv"), sep = "\t")
datasets_metadata = pd.read_csv(os.path.join(METADATA_FILES_DIR,"hubmap-datasets-metadata.tsv"), sep = "\t")

donor_metadata = donor_metadata.drop(0,axis=0)
datasets_metadata = datasets_metadata.drop(0,axis=0)

metadata = datasets_metadata.merge(donor_metadata,left_on="donor.hubmap_id",right_on="hubmap_id",how="left")
metadata = metadata[['hubmap_id_x','donor.hubmap_id','age_value','body_mass_index_value','race','sex']]
metadata = metadata.rename(columns={'hubmap_id_x':'hubmap_id','age_value':'age','body_mass_index_value':'bmi'})

for csvfile in os.listdir(FILES_DIR):
    data = pd.read_csv(os.path.join(FILES_DIR,csvfile))
    row = metadata.loc[metadata['hubmap_id'] == csvfile[:-4]]
    data['donor_id'] = row['donor.hubmap_id'].values[0]
    data['age'] = row['age'].values[0]
    data['bmi'] = row['bmi'].values[0]
    data['sex'] = row['sex'].values[0]
    data['race'] = row['race'].values[0]
    data = data[['cell_type','donor_id','age','bmi','sex','race','count','percentage']]
    data.to_csv(os.path.join(FILES_DIR,csvfile))