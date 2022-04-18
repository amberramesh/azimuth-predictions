source("../pipeline/analysis.R", chdir = TRUE)
library(R.utils)

files.dir <- "data"
reference <- readRDS("../reference-data/human-kidney.Rds")
if (!dir.exists("prediction_scores/")) {
  dir.create("prediction_scores/")
}
if (!dir.exists("dataset_scores/")) {
  dir.create("dataset_scores/")
  scores.df <- data.frame(
    Dataset.Name = character(),
    Percent.Anchors = double(),
    Cluster.Preservation.Score = double(),
    stringsAsFactors = FALSE
  )
  write.csv(scores.df, file.path("dataset_scores", "HuBMAP_Kidney_scores.csv"), row.names = FALSE)
}
dataset.scores <- read.csv(file.path("dataset_scores", "HuBMAP_Kidney_scores.csv"))
datasets <- list.dirs(recursive = FALSE, full.names = FALSE, path = files.dir)

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
    query <- tryCatch(
      RunPredictionPipeline(reference = reference, query = query),
      error = function(err) {
        print(err)
        print(paste0("Error in running complete pipeline for ", data.dir))
        return(NA)
      }
    )
    if (!is.na(query)) {
      # Compute QC stats
      max.dims <- as.double(length(slot(reference, "reductions")$refDR))
      clusterpreservation.qc <- round(ClusterPreservationScore(query, 5000, max.dims), digits = 2)
      percent.anchors <- query$percent.anchors[1]
      # print(paste0("Query cells with anchors: ", percent.anchors, "%"))
      # print(paste0("Cluster Preservation Score: ", clusterpreservation.qc, "/5"))
      dataset.scores[nrow(dataset.scores) + 1, ] <- c(data.dir, percent.anchors, clusterpreservation.qc)

      # Save cell level scores
      write.csv(query@meta.data, file = paste0("./prediction_scores/", data.dir, ".csv"))
      # Save dataset level scores
      write.csv(dataset.scores, file.path("./dataset_scores", "HuBMAP_Kidney_scores.csv"), row.names = FALSE)
      print(paste0("Generated predictions for ", data.dir, "."))
    }
  }
}
