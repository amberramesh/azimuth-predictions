## NeMO Archive

### Downloading Datasets

**Download the manifest**

Visit the [NeMO data portal](https://portal.nemoarchive.org/) to obtain a manifest file. Suggested file filters for the download are Samples > Organism > Human and Files > Format > MEX. The manifest can be downloaded by adding all the results to the cart and clicking on File Manifest download option on the cart page.

**Set up the IGS portal client**

Instructions for setting up and using the portal client can be found [here](https://github.com/IGS/portal_client). Ensure that the output directory is set as `data` and the TAR files are downloaded to this directory.

### Running the pipeline

The pipeline script largely tries to reproduce the cell cluster annotations observed when a query dataset is uploaded to [Azimuth](https://app.azimuth.hubmapconsortium.org/app/human-motorcortex). Ensure the following R packages are installed before proceeding:
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
