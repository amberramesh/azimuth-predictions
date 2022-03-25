#!/bin/bash

#SBATCH -J predictions-hubmap-hca-liver
#SBATCH -p general
#SBATCH -o logs/out_%j.log
#SBATCH -e logs/err_%j.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=amramesh@iu.edu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=0:10:00
#SBATCH --mem=2G

module load singularity
singularity exec -B /N/slate/amramesh/azimuth-predictions/ singularity/seurat_4.1.0.sif Rscript hubmap-kidney/run_pipeline.R

# conda create -y -n condaforge
# conda activate condaforge
# conda install -y seaborn scikit-learn statsmodels numba pytables
# conda install -y -c conda-forge python-igraph leidenalg

module load singularity
singularity shell -B /N/slate/amramesh/azimuth-predictions/ singularity/scanpy_1.4.sif python read_cell_metadata.py
