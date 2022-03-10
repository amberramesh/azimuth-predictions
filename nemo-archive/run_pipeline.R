source("../pipeline/analysis.R", chdir = TRUE)
library(R.utils)

files.dir <- "data"
reference <- readRDS("../reference-data/human-motor-cortex.Rds")
mex.archives <- list.files(pattern = "\\.mex.tar.gz$", path = files.dir)
if (!dir.exists("prediction_scores/")) {
  dir.create("prediction_scores/")
}

for (file.name in mex.archives) {
  data.dir <- gsub("\\..*", "", file.name)
  if (file.exists(paste0("./prediction_scores/", data.dir, ".csv"))) {
    print(paste0("Scores found for ", data.dir, ". Skipping..."))
    next
  }

  mex.files <- untar(file.name, list = TRUE)
  untar(file.name, verbose = TRUE)
  lapply(mex.files, gzip, overwrite = TRUE, remove = TRUE)
  if (!dir.exists(data.dir)) {
    print(paste0("Archive directory '", data.dir, "' does not exist."))
    next
  }
  if (file.exists(file.path(data.dir, "genes.tsv.gz"))) {
    file.rename(file.path(data.dir, "genes.tsv.gz"), file.path(data.dir, "features.tsv.gz"))
  }
  query <- Read10X(data.dir)
  unlink(data.dir, recursive = TRUE)

  query <- CreateSeuratObject(query)
  query <- RunPredictionPipeline(reference = reference, query = query)

  write.csv(query@meta.data, file = paste0("prediction_scores/", data.dir, ".csv"))
  print(paste0("Generated predictions for ", data.dir, "."))
}