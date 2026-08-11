make_iris_pca <- function() {
  prcomp(iris[, 1:4], scale. = TRUE)
}

test_that("plot_pca3d returns a ggplot object", {
  pca <- make_iris_pca()
  p <- plot_pca3d(pca)
  expect_s3_class(p, "ggplot")
})

test_that("plot_pca3d adds a variance-explained caption by default", {
  pca <- make_iris_pca()
  p <- plot_pca3d(pca)
  expect_match(p$labels$caption, "^PC1 \\(")
})

test_that("var_explained = FALSE omits the caption", {
  pca <- make_iris_pca()
  p <- plot_pca3d(pca, var_explained = FALSE)
  expect_null(p$labels$caption)
})

test_that("color_by accepts an unquoted metadata column and maps colour", {
  pca <- make_iris_pca()
  p <- plot_pca3d(pca, metadata = iris, color_by = Species)
  expect_true(
    "colour" %in% names(p$mapping) || "colour" %in% names(p$layers[[1]]$mapping)
  )
})

test_that("color_by accepts a string column name", {
  pca <- make_iris_pca()
  p <- plot_pca3d(pca, metadata = iris, color_by = "Species")
  expect_s3_class(p, "ggplot")
})

test_that("color_scale is added to the returned ggplot object", {
  pca <- make_iris_pca()
  p <- plot_pca3d(
    pca,
    metadata = iris,
    color_by = Species,
    color_scale = ggplot2::scale_color_brewer(palette = "Set1")
  )
  color_scales <- Filter(
    function(s) "colour" %in% s$aesthetics,
    p$scales$scales
  )
  expect_length(color_scales, 1)
})

test_that("color_scale must be a ggplot2 scale", {
  pca <- make_iris_pca()
  expect_error(
    plot_pca3d(pca, metadata = iris, color_by = Species, color_scale = "nope"),
    class = "rlang_error"
  )
})

test_that("color_scale without color_by warns and has no effect", {
  pca <- make_iris_pca()
  expect_warning(
    plot_pca3d(pca, color_scale = ggplot2::scale_color_viridis_c()),
    "color_by"
  )
})

test_that("dims argument selects the requested components", {
  pca <- make_iris_pca()
  p_default <- plot_pca3d(pca, theta = 0, phi = 0)
  p_dims <- plot_pca3d(pca, dims = c(2, 3, 4), theta = 0, phi = 0)

  expect_equal(p_default$data$x, unname(pca$x[, 1]))
  expect_equal(p_dims$data$x, unname(pca$x[, 2]))
})
