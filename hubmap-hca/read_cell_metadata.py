import os
import glob
import scanpy as sc

root_dir = 'data'
output_dir = 'metadata'
data_dirs = os.listdir(root_dir)

os.makedirs(output_dir, exist_ok=True)
for directory in data_dirs:
    matrix_paths = glob.glob(os.path.join(root_dir, directory, '*.h5ad'))
    for path in matrix_paths:
        anndata = sc.read_h5ad(path)
        anndata.obs.to_csv(os.path.join(output_dir, f'{directory}.csv'))
