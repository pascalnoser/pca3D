test_that("animate_pca3d writes a gif file and returns its path", {
  skip_on_cran()

  pca <- prcomp(iris[, 1:4], scale. = TRUE)
  out_file <- withr::local_tempfile(fileext = ".gif")

  result <- animate_pca3d(
    pca,
    metadata = iris,
    color_by = Species,
    n_frames = 4,
    fps = 4,
    width = 200,
    height = 200,
    file = out_file
  )

  expect_equal(result, out_file)
  expect_true(file.exists(out_file))
  expect_gt(file.size(out_file), 0)
})

test_that("animate_pca3d accepts a custom color_scale", {
  skip_on_cran()

  pca <- prcomp(iris[, 1:4], scale. = TRUE)
  out_file <- withr::local_tempfile(fileext = ".gif")

  result <- animate_pca3d(
    pca,
    metadata = iris,
    color_by = Species,
    n_frames = 4,
    fps = 4,
    width = 200,
    height = 200,
    file = out_file,
    color_scale = ggplot2::scale_color_brewer(palette = "Set1")
  )

  expect_equal(result, out_file)
  expect_true(file.exists(out_file))
  expect_gt(file.size(out_file), 0)
})

test_that("animate_pca3d rejects a color_scale that isn't a ggplot2 scale", {
  pca <- prcomp(iris[, 1:4], scale. = TRUE)
  expect_error(
    animate_pca3d(
      pca,
      metadata = iris,
      color_by = Species,
      color_scale = "nope",
      file = withr::local_tempfile(fileext = ".gif")
    ),
    class = "rlang_error"
  )
})
