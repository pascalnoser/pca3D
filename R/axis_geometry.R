# Build rotated axis-arrow geometry for one frame.
#
# `coords` is the same (x, y, z) matrix used for the point cloud (columns
# named x, y, z; one row per sample). `dims` are the actual PC numbers
# selected (used for labels, e.g. "PC1"). `style` is "full" (arrows through
# the data from the origin) or "gizmo" (short arrows anchored at a fixed
# corner, independent of data scale).
#
# Returns a list with:
#   segments: data.frame(x, y, xend, yend, label) -- one row per axis
#   labels:   data.frame(x, y, label) -- label position just beyond each tip
#
# Basis vectors are rotated with the same rotate_project() used for the
# data, so the arrows always stay in sync with the point cloud's rotation.
#
# Arrow/gizmo size and the gizmo's corner offset are all derived from a
# *typical* point radius (the 75th percentile of each sample's distance
# from the origin) rather than the maximum. Using the maximum meant a
# single distant outlier could push the gizmo far away from the bulk of
# the data (and inflate the panel via expand_limits() in .pca3d_ggplot());
# the 75th percentile is still rotation-invariant (so there's no per-frame
# jitter in animations) but is robust to a handful of outlying points.
pca3d_axis_geometry <- function(coords, dims, theta, phi, style = c("full", "gizmo")) {
  style <- match.arg(style)

  distances <- sqrt(rowSums(coords^2))
  radius <- stats::quantile(distances, 0.75, names = FALSE)

  labels <- paste0("PC", dims)

  if (style == "full") {
    length_ <- 0.9 * radius
    base <- c(0, 0)
  } else {
    length_ <- 0.3 * radius
    base <- c(-1.2 * radius, -1.2 * radius)
  }

  basis <- diag(length_, 3)
  colnames(basis) <- c("x", "y", "z")

  tips <- rotate_project(basis, theta = theta, phi = phi)

  segments <- data.frame(
    x = base[1],
    y = base[2],
    xend = base[1] + tips$x,
    yend = base[2] + tips$y,
    label = labels
  )

  labels_df <- data.frame(
    x = base[1] + 1.15 * tips$x,
    y = base[2] + 1.15 * tips$y,
    label = labels
  )

  list(segments = segments, labels = labels_df)
}
