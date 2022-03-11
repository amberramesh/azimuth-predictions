## HuBMAP Kidney

### Downloading Datasets

Datasets listed in `datasets.csv` must be retrieved from the HuBMAP portal. This file contains a list of HuBMAP IDs with their corresponding dataset UUIDs which can be used to request datasets using the HuBMAP Assets API.

The `download.py` script reads the above CSV to download the datasets into the `data` directory. At the time of writing, the datasets have protected access (and may continue to do so) and hence an authorized HuBMAP account is required. This account's access key *must* either be set as the environment variable `HUBMAP_TOKEN` before running the script or provided as an argument to the script. The script enables downloading multiple matrices for a dataset, which can be specified using `target_files` within the script.

### Running the pipeline

The pipeline script largely tries to reproduce the cell cluster annotations observed when a query dataset is uploaded to [Azimuth](https://app.azimuth.hubmapconsortium.org/app/human-kidney). Ensure the following R packages are installed before proceeding:
- Seurat
- SeuratDisk
- ggplot2
- patchwork
- stringr
- hdf5r
- shiny

To run the pipeline, use
```
Rscript run_pipeline.R
```
The pipeline functions used here are from the original [Azimuth repository](https://github.com/satijalab/azimuth) to maintain similar workflows. Processing all matrices might require significant time and memory and it is not advisable to run this on computers with less than 16 GB memory.

### Obtaining Predictions
A single CSV file is generated for each processed matrix, and added to the `prediction_scores` directory. Prediction scores are generated for all the annotation levels present in the reference but these columns can be modified.
