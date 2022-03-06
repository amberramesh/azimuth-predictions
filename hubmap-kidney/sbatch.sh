#!/bin/bash

#SBATCH -J azimuth-predictions-hubmap-kidney
#SBATCH -p general
#SBATCH -o logs/out_%j.log
#SBATCH -e logs/err_%j.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=amramesh@iu.edu
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=2:00:00
#SBATCH --mem=16G

module load singularity
singularity exec -B /N/slate/amramesh/azimuth-predictions/ singularity/seurat_4.1.0.sif Rscript hubmap-kidney/run_pipeline.R
