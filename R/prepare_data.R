# Validate inputs and assemble the 3D coordinates + colour values used by
# both plot_pca3d() and animate_pca3d().
#
# `color_by` here is already a plain string (or NULL) -- tidy evaluation of
# the user-facing unquoted argument happens in the exported functions.
pca3d_prepare_data <- function(pca, dims, metadata = NULL, color_by = NULL) {
  if (!inherits(pca, "prcomp")) {
    cli::cli_abort("{.arg pca} must be a {.cls prcomp} object, not {.cls {class(pca)}}.")
  }
  if (!is.numeric(dims) || length(dims) != 3) {
    cli::cli_abort("{.arg dims} must be a numeric vector of length 3.")
  }
  if (max(dims) > ncol(pca$x)) {
    cli::cli_abort(
      "{.arg dims} requests PC{max(dims)} but {.arg pca} only has {ncol(pca$x)} components."
    )
  }

  scores <- pca$x[, dims, drop = FALSE]
  colnames(scores) <- c("x", "y", "z")

  color_values <- NULL
  if (!is.null(color_by)) {
    if (is.null(metadata)) {
      cli::cli_abort("{.arg metadata} must be supplied when {.arg color_by} is used.")
    }
    if (nrow(metadata) != nrow(scores)) {
      cli::cli_abort(c(
        "{.arg metadata} must have one row per sample in {.arg pca}.",
        "x" = "{.arg pca} has {nrow(scores)} samples but {.arg metadata} has {nrow(metadata)} rows."
      ))
    }

    scores_rn <- rownames(scores)
    meta_rn <- rownames(metadata)
    has_real_rownames <- function(rn, n) {
      !is.null(rn) && !identical(rn, as.character(seq_len(n)))
    }
    if (has_real_rownames(scores_rn, nrow(scores)) && has_real_rownames(meta_rn, nrow(metadata))) {
      if (!setequal(scores_rn, meta_rn)) {
        cli::cli_abort("Row names of {.arg metadata} do not match sample names in {.arg pca}.")
      }
      metadata <- metadata[scores_rn, , drop = FALSE]
    }

    if (!color_by %in% names(metadata)) {
      cli::cli_abort("{.val {color_by}} not found in {.arg metadata}.")
    }
    color_values <- metadata[[color_by]]
  }

  list(coords = scores, color_values = color_values)
}

# Build the "PC1 (32.1%) · PC2 (20.4%) · PC3 (15.8%)" caption.
pca3d_variance_caption <- function(pca, dims) {
  var_pct <- 100 * pca$sdev^2 / sum(pca$sdev^2)
  parts <- sprintf("PC%d (%.1f%%)", dims, var_pct[dims])
  paste(parts, collapse = " \u00b7 ")
}
