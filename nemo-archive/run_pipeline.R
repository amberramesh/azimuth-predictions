source("../pipeline/analysis.R", chdir = TRUE)
library(R.utils)

files.dir <- "data"
reference <- readRDS("../reference-data/human-motor-cortex.Rds")
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
  write.csv(scores.df, file.path("dataset_scores", "NeMO_scores.csv"), row.names = FALSE)
}
dataset.scores <- read.csv(file.path("dataset_scores", "NeMO_scores.csv"))
setwd(files.dir)
mex.archives <- list.files(pattern = "\\.mex.tar.gz$")

for (file.name in mex.archives) {
  data.dir <- gsub("\\..*", "", file.name)
  if (file.exists(paste0("../prediction_scores/", data.dir, ".csv"))) {
    print(paste0("Scores found for ", data.dir, ". Skipping..."))
    next
  }

  mex.files <- untar(file.name, list = TRUE)
  mex.files <- grep("\\.(mtx|tsv)$", mex.files, value = TRUE, ignore.case = TRUE)
  untar(file.name, verbose = TRUE)
  lapply(mex.files, gzip, overwrite = TRUE, remove = TRUE)
  if (!dir.exists(data.dir)) {
    print(paste0("Archive directory '", data.dir, "' does not exist."))
    next
  }
  if (file.exists(file.path(data.dir, "genes.tsv.gz"))) {
    file.rename(file.path(data.dir, "genes.tsv.gz"), file.path(data.dir, "features.tsv.gz"))
  }
  if (file.exists(file.path(data.dir, "enes.tsv.gz"))) {
    file.rename(file.path(data.dir, "enes.tsv.gz"), file.path(data.dir, "features.tsv.gz"))
  }
  query <- Read10X(data.dir)
  unlink(data.dir, recursive = TRUE)

  query <- CreateSeuratObject(query)
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
    write.csv(query@meta.data, file = paste0("../prediction_scores/", data.dir, ".csv"))
    # Save dataset level scores
    write.csv(dataset.scores, file.path("../dataset_scores", "NeMO_scores.csv"), row.names = FALSE)
    print(paste0("Generated predictions for ", data.dir, "."))
  }
}
