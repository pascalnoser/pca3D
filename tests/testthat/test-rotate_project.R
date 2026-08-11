test_that("theta = 0, phi = 0 is the identity transform", {
  coords <- matrix(c(1, 2, 3, -1, 0.5, 4), ncol = 3, byrow = TRUE)
  colnames(coords) <- c("x", "y", "z")

  rp <- rotate_project(coords, theta = 0, phi = 0)

  expect_equal(rp$x, coords[, "x"])
  expect_equal(rp$y, coords[, "y"])
  expect_equal(rp$depth, coords[, "z"])
})

test_that("a full 360 degree azimuth rotation returns to the start", {
  coords <- matrix(c(1, 2, 3, -1, 0.5, 4), ncol = 3, byrow = TRUE)
  colnames(coords) <- c("x", "y", "z")

  rp0 <- rotate_project(coords, theta = 0, phi = 20)
  rp360 <- rotate_project(coords, theta = 360, phi = 20)

  expect_equal(rp360, rp0, tolerance = 1e-10)
})

test_that("rotation preserves distance from the origin (orthonormal)", {
  set.seed(2451)
  coords <- matrix(rnorm(30), ncol = 3)
  colnames(coords) <- c("x", "y", "z")

  original_norms <- sqrt(rowSums(coords^2))

  rp <- rotate_project(coords, theta = 47, phi = 13)
  rotated_norms <- sqrt(rp$x^2 + rp$y^2 + rp$depth^2)

  expect_equal(rotated_norms, original_norms, tolerance = 1e-10)
})
