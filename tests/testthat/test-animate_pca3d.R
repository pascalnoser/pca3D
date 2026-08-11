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
