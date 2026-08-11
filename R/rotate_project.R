# Rotate a set of 3D coordinates and project them onto 2D.
#
# `coords` must be a matrix or data frame with columns `x`, `y`, `z`
# (the three selected PC scores). Applies a fixed elevation tilt (`phi`,
# around the horizontal x-axis) followed by an azimuth rotation (`theta`,
# around the vertical y-axis) that varies per animation frame. Returns a
# data frame with the projected `x`, `y` and the dropped `depth` (rotated
# z), which callers use to drive depth cueing (point size/alpha).
#
# theta = 0, phi = 0 is the identity transform: x, y are unchanged and
# depth equals the original z.
rotate_project <- function(coords, theta = 0, phi = 20) {
  theta_r <- theta * pi / 180
  phi_r <- phi * pi / 180

  x <- coords[, "x"]
  y <- coords[, "y"]
  z <- coords[, "z"]

  # Elevation tilt around the horizontal (x) axis, fixed across frames
  y1 <- y * cos(phi_r) - z * sin(phi_r)
  z1 <- y * sin(phi_r) + z * cos(phi_r)
  x1 <- x

  # Azimuth rotation around the vertical (y) axis, varies per frame
  x2 <- x1 * cos(theta_r) + z1 * sin(theta_r)
  z2 <- -x1 * sin(theta_r) + z1 * cos(theta_r)
  y2 <- y1

  data.frame(x = x2, y = y2, depth = z2)
}
