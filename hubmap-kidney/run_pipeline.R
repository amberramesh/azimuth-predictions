source("../pipeline/analysis.R", chdir = TRUE)
library(R.utils)

files.dir <- "data"
reference <- readRDS("../reference-data/human-kidney.Rds")
datasets <- list.dirs(recursive = FALSE, full.names = FALSE, path = files.dir)
if (!dir.exists("prediction_scores/")) {
  dir.create("prediction_scores/")
}

for (data.dir in datasets) {
  matrices <- list.files(pattern = "\\.h5ad$", path = file.path(files.dir, data.dir))
  for (matrix in matrices) {
    # Currently only one prediction file per data.dir (dataset)
    # Can be updated to generate one prediction CSV file per matrix
    if (file.exists(paste0("./prediction_scores/", data.dir, ".csv"))) {
      print(paste0("Scores found for ", data.dir, ". Skipping..."))
      next
    }

    query <- LoadFileInput(file.path(files.dir, data.dir, matrix))
    query <- RunPredictionPipeline(reference = reference, query = query)

    write.csv(query@meta.data, file = paste0("prediction_scores/", data.dir, ".csv"))
  }
}
