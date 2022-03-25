## HuBMAP HCA Liver

### Downloading Datasets

Datasets listed in `datasets.csv` must be retrieved from the HuBMAP portal. This file contains a list of HuBMAP IDs with their corresponding dataset UUIDs which can be used to request datasets using the HuBMAP Assets API.

The `download.py` script reads the above CSV to download the datasets into the `data` directory. At the time of writing, the datasets have protected access (and may continue to do so) and hence an authorized HuBMAP account is required. This account's access key *must* either be set as the environment variable `HUBMAP_TOKEN` before running the script or provided as an argument to the script. The script enables downloading multiple matrices for a dataset, which can be specified using `target_files` within the script.

### Reading metadata
The script `read_cell_metadata.py` is provided to read the `obs` slot from available AnnData. In current state, this returns `n_genes`,`n_counts`,`leiden` and `umap_density` for all the cells.

### Running the pipeline
Currently there is no reference available for Liver. All datasets in this collection include samples taken from human livers.
