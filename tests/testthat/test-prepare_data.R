make_pca <- function(n = 10, p = 4, rownames_ = NULL) {
  set.seed(3812)
  mat <- matrix(rnorm(n * p), nrow = n, ncol = p)
  if (!is.null(rownames_)) rownames(mat) <- rownames_
  prcomp(mat)
}

test_that("errors if pca is not a prcomp object", {
  expect_error(pca3d_prepare_data(list(), dims = 1:3), class = "rlang_error")
})

test_that("errors if dims isn't length 3", {
  pca <- make_pca()
  expect_error(pca3d_prepare_data(pca, dims = 1:2), class = "rlang_error")
})

test_that("errors if dims exceeds available components", {
  pca <- make_pca(p = 4)
  expect_error(pca3d_prepare_data(pca, dims = c(1, 2, 10)), class = "rlang_error")
})

test_that("returns coords with x, y, z columns for the requested dims", {
  pca <- make_pca()
  out <- pca3d_prepare_data(pca, dims = c(2, 3, 4))
  expect_equal(colnames(out$coords), c("x", "y", "z"))
  expect_equal(unname(out$coords[, "x"]), unname(pca$x[, 2]))
  expect_null(out$color_values)
})

test_that("errors if color_by requested without metadata", {
  pca <- make_pca()
  expect_error(pca3d_prepare_data(pca, dims = 1:3, color_by = "grp"), class = "rlang_error")
})

test_that("errors if metadata row count doesn't match", {
  pca <- make_pca(n = 10)
  metadata <- data.frame(grp = letters[1:5])
  expect_error(
    pca3d_prepare_data(pca, dims = 1:3, metadata = metadata, color_by = "grp"),
    class = "rlang_error"
  )
})

test_that("errors if color_by column not found in metadata", {
  pca <- make_pca(n = 10)
  metadata <- data.frame(grp = letters[1:10])
  expect_error(
    pca3d_prepare_data(pca, dims = 1:3, metadata = metadata, color_by = "nope"),
    class = "rlang_error"
  )
})

test_that("aligns metadata to pca rownames when both have real row names", {
  ids <- paste0("s", 1:10)
  pca <- make_pca(n = 10, rownames_ = ids)
  metadata <- data.frame(grp = ids, val = 1:10, row.names = ids)
  metadata_shuffled <- metadata[sample(nrow(metadata)), , drop = FALSE]

  out <- pca3d_prepare_data(pca, dims = 1:3, metadata = metadata_shuffled, color_by = "val")
  expect_equal(out$color_values, 1:10)
})

test_that("detects continuous vs categorical color_by values", {
  pca <- make_pca(n = 10)
  metadata_num <- data.frame(val = rnorm(10))
  metadata_chr <- data.frame(grp = rep(c("a", "b"), 5))

  out_num <- pca3d_prepare_data(pca, dims = 1:3, metadata = metadata_num, color_by = "val")
  out_chr <- pca3d_prepare_data(pca, dims = 1:3, metadata = metadata_chr, color_by = "grp")

  expect_true(is.numeric(out_num$color_values))
  expect_true(is.character(out_chr$color_values))
})

test_that("variance caption lists percent variance explained for each dim", {
  pca <- make_pca(p = 4)
  caption <- pca3d_variance_caption(pca, dims = 1:3)

  expect_match(caption, "^PC1 \\(\\d+\\.\\d%\\) . PC2 \\(\\d+\\.\\d%\\) . PC3 \\(\\d+\\.\\d%\\)$")
})
