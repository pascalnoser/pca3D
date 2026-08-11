make_coords <- function() {
  coords <- matrix(c(3, 4, 0, -2, 1, 5, 0, -3, 2), ncol = 3, byrow = TRUE)
  colnames(coords) <- c("x", "y", "z")
  coords
}

test_that("full style: arrows originate at the origin", {
  coords <- make_coords()
  geom <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 0,
    phi = 0,
    style = "full"
  )

  expect_equal(geom$segments$x, rep(0, 3))
  expect_equal(geom$segments$y, rep(0, 3))
})

test_that("full style at theta = phi = 0: PC3 (depth) arrow is foreshortened to zero", {
  coords <- make_coords()
  geom <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 0,
    phi = 0,
    style = "full"
  )

  radius <- stats::quantile(sqrt(rowSums(coords^2)), 0.75, names = FALSE)
  expected_length <- 0.9 * radius

  # PC1 and PC2 arrows lie along the raw x/y axes
  expect_equal(geom$segments$xend[1], expected_length, tolerance = 1e-10)
  expect_equal(geom$segments$yend[1], 0, tolerance = 1e-10)
  expect_equal(geom$segments$xend[2], 0, tolerance = 1e-10)
  expect_equal(geom$segments$yend[2], expected_length, tolerance = 1e-10)

  # PC3 (mapped to depth) foreshortens to (0, 0)
  expect_equal(geom$segments$xend[3], 0, tolerance = 1e-10)
  expect_equal(geom$segments$yend[3], 0, tolerance = 1e-10)
})

test_that("gizmo style: all arrows share a fixed corner base, independent of theta", {
  coords <- make_coords()
  geom0 <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 0,
    phi = 20,
    style = "gizmo"
  )
  geom90 <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 90,
    phi = 20,
    style = "gizmo"
  )

  expect_equal(length(unique(geom0$segments$x)), 1)
  expect_equal(length(unique(geom0$segments$y)), 1)
  expect_equal(geom0$segments$x[1], geom90$segments$x[1])
  expect_equal(geom0$segments$y[1], geom90$segments$y[1])
})

test_that("labels reflect the actual selected dims", {
  coords <- make_coords()
  geom <- pca3d_axis_geometry(
    coords,
    dims = c(1, 2, 4),
    theta = 30,
    phi = 20,
    style = "full"
  )

  expect_equal(geom$segments$label, c("PC1", "PC2", "PC4"))
  expect_equal(geom$labels$label, c("PC1", "PC2", "PC4"))
})

test_that("a full 360 degree rotation returns to the starting geometry", {
  coords <- make_coords()
  geom0 <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 0,
    phi = 20,
    style = "full"
  )
  geom360 <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 360,
    phi = 20,
    style = "full"
  )

  expect_equal(geom360, geom0, tolerance = 1e-10)
})

test_that("gizmo placement is robust to a single distant outlier", {
  set.seed(9143)
  n <- 40
  base_coords <- matrix(rnorm(n * 3, sd = 1), ncol = 3)
  colnames(base_coords) <- c("x", "y", "z")

  outlier_coords <- rbind(base_coords, c(x = 60, y = 60, z = 0))

  geom_base <- pca3d_axis_geometry(
    base_coords,
    dims = 1:3,
    theta = 10,
    phi = 20,
    style = "gizmo"
  )
  geom_outlier <- pca3d_axis_geometry(
    outlier_coords,
    dims = 1:3,
    theta = 10,
    phi = 20,
    style = "gizmo"
  )

  # A single far-flung outlier shouldn't drag the gizmo's corner away from
  # where it would sit for the bulk of the (non-outlier) data.
  expect_equal(
    geom_outlier$segments$x[1],
    geom_base$segments$x[1],
    tolerance = 0.5
  )
  expect_equal(
    geom_outlier$segments$y[1],
    geom_base$segments$y[1],
    tolerance = 0.5
  )
})

test_that("label positions sit beyond the arrow tips", {
  coords <- make_coords()
  geom <- pca3d_axis_geometry(
    coords,
    dims = 1:3,
    theta = 25,
    phi = 15,
    style = "gizmo"
  )

  tip_dist <- sqrt(
    (geom$segments$xend - geom$segments$x)^2 +
      (geom$segments$yend - geom$segments$y)^2
  )
  label_dist <- sqrt(
    (geom$labels$x - geom$segments$x)^2 + (geom$labels$y - geom$segments$y)^2
  )

  expect_true(all(label_dist > tip_dist))
})
