source("helpers.R")

# Ensure Seurat v4.0 or higher is installed
if (packageVersion(pkg = "Seurat") < package_version(x = "4.0.0")) {
  stop("Mapping datasets requires Seurat v4 or higher.", call. = FALSE)
}

# Ensure glmGamPoi is installed
if (!requireNamespace("glmGamPoi", quietly = TRUE)) {
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    BiocManager::install("glmGamPoi")
  }
}

library(Seurat)
library(SeuratDisk)
library(ggplot2)
library(patchwork)
library(stringr)
library(hdf5r)
library(shiny)

RunPredictionPipeline <- function(reference, query) {
  max.dims <- as.double(length(slot(reference, "reductions")$refDR))
  meta.data.columns <- colnames(reference@meta.data)
  annotation.columns <- c()
  for (i in grep("[.]l[1-3]", meta.data.columns)) {
    annotation.columns <- c(annotation.columns, meta.data.columns[i])
  }
  if (length(annotation.columns) == 0) {
    annotation.columns <- c("class", "subclass", "cluster", "cross_species_cluster")
  }

  query <- DietSeurat(
    query,
    assays = "RNA"
  )

  query <- ConvertGeneNames(
    object = query,
    reference.names = rownames(x = reference),
    homolog.table = "https://seurat.nygenome.org/azimuth/references/homologs.rds"
  )

  # Calculate nCount_RNA and nFeature_RNA if the query does not
  # contain them already
  if (!all(c("nCount_RNA", "nFeature_RNA") %in% c(colnames(x = query[[]])))) {
    calcn <- as.data.frame(x = Seurat:::CalcN(object = query))
    colnames(x = calcn) <- paste(
      colnames(x = calcn),
      "RNA",
      sep = "_"
    )
    query <- AddMetaData(
      object = query,
      metadata = calcn
    )
    rm(calcn)
  }

  # Calculate percent mitochondrial genes if the query contains genes
  # matching the regular expression "^MT-"
  if (any(grepl(pattern = "^MT-", x = rownames(x = query)))) {
    query <- PercentageFeatureSet(
      object = query,
      pattern = "^MT-",
      col.name = "percent.mt",
      assay = "RNA"
    )
  }

  query <- SCTransform(
    object = query,
    assay = "RNA",
    new.assay.name = "refAssay",
    residual.features = rownames(x = reference),
    reference.SCT.model = reference[["refAssay"]]@SCTModel.list$refmodel,
    method = "glmGamPoi",
    do.correct.umi = FALSE,
    do.scale = FALSE,
    do.center = TRUE
  )

  anchors <- FindTransferAnchors(
    reference = reference,
    query = query,
    k.filter = NA,
    reference.neighbors = "refdr.annoy.neighbors",
    reference.assay = "refAssay",
    query.assay = "refAssay",
    reference.reduction = "refDR",
    normalization.method = "SCT",
    features = intersect(rownames(x = reference), VariableFeatures(object = query)),
    dims = 1:max.dims,
    n.trees = 20,
    mapping.score.k = 100,
    verbose = TRUE,
  )
  query.unique <- length(x = unique(x = slot(object = anchors, name = "anchors")[, "cell2"]))
  query$percent.anchors <- round(x = query.unique / ncol(x = query) * 100, digits = 2)

  # Transfer cell type labels and impute protein expression
  #
  # Transferred labels are in metadata columns named "predicted.*"
  # The maximum prediction score is in a metadata column named "predicted.*.score"
  # The prediction scores for each class are in an assay named "prediction.score.*"
  # The imputed assay is named "impADT" if computed

  refdata <- lapply(X = annotation.columns, function(x) {
    reference[[x, drop = TRUE]]
  })
  names(x = refdata) <- annotation.columns
  if (FALSE) {
    refdata[["impADT"]] <- GetAssayData(
      object = reference[["ADT"]],
      slot = "data"
    )
  }

  query <- TransferData(
    reference = reference,
    query = query,
    dims = 1:max.dims,
    anchorset = anchors,
    refdata = refdata,
    n.trees = 20,
    store.weights = TRUE
  )

  # Calculate the embeddings of the query data on the reference SPCA
  query <- IntegrateEmbeddings(
    anchorset = anchors,
    reference = reference,
    query = query,
    reductions = "pcaproject",
    reuse.weights.matrix = TRUE
  )

  # Calculate the query neighbors in the reference
  # with respect to the integrated embeddings
  query[["query_ref.nn"]] <- FindNeighbors(
    object = Embeddings(reference[["refDR"]]),
    query = Embeddings(query[["integrated_dr"]]),
    return.neighbor = TRUE,
    l2.norm = TRUE
  )

  # The reference used in the app is downsampled compared to the reference on which
  # the UMAP model was computed. This step, using the helper function NNTransform,
  # corrects the Neighbors to account for the downsampling.
  query <- NNTransform(
    object = query,
    meta.data = reference[[]]
  )

  # Project the query to the reference UMAP.
  query[["proj.umap"]] <- RunUMAP(
    object = query[["query_ref.nn"]],
    reduction.model = reference[["refUMAP"]],
    reduction.key = "UMAP_"
  )

  # Calculate mapping score and add to metadata
  query <- AddMetaData(
    object = query,
    metadata = MappingScore(anchors = anchors, ndim = max.dims),
    col.name = "mapping.score"
  )

  return(query)
}
