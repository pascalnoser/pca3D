#' Create a static 3D-style PCA plot
#'
#' Projects three principal components onto 2D after applying a fixed 3D
#' rotation, giving a single "camera angle" view of the point cloud. Points
#' closer to the viewer can optionally be drawn larger/more opaque
#' (`depth_cue`) to reinforce the 3D effect. Use [animate_pca3d()] to render
#' a full rotating GIF instead of a single view.
#'
#' Because the 2D x/y axes after rotation are a blend of the selected PCs
#' rather than a single PC, axis titles are omitted. When `var_explained =
#' TRUE`, a caption lists the percent variance explained by each of `dims`
#' instead.
#'
#' @param pca A `prcomp` object.
#' @param dims Numeric vector of length 3 giving which principal components
#'   to use, e.g. `1:3` (the default) or `c(1, 2, 4)`.
#' @param metadata Optional data frame of sample metadata with one row per
#'   sample in `pca`, used to colour points via `color_by`. If both `pca$x`
#'   and `metadata` have row names, rows are matched by name; otherwise they
#'   are assumed to be in the same order.
#' @param color_by Optional column in `metadata` to colour points by, as an
#'   unquoted name (e.g. `treatment`) or a string (e.g. `"treatment"`).
#'   Numeric columns are treated as continuous, others as categorical; no
#'   colour scale is applied automatically so you can add your own, e.g.
#'   `plot_pca3d(pca, metadata = md, color_by = group) + scale_color_brewer(palette = "Set1")`.
#' @param var_explained Logical; if `TRUE` (default), add a caption listing
#'   the percent variance explained by each of `dims`.
#' @param theta Azimuth rotation angle in degrees for this view. Default `30`.
#' @param phi Elevation tilt angle in degrees. Default `20`.
#' @param depth_cue Logical; if `TRUE` (default), points closer to the
#'   viewer are drawn larger and more opaque.
#' @param point_size Base point size. Default `3`.
#' @param axes Draw an indicator of which direction each PC axis points.
#'   One of `"none"` (default), `"full"` (arrows through the point cloud
#'   from the origin along each rotated PC direction, labelled `PC<n>` at
#'   the tip), or `"gizmo"` (the same arrows, but short and anchored at a
#'   fixed corner of the plot, independent of data scale, like a small
#'   rotating compass).
#' @param axis_color Colour used for the axis arrows/labels when `axes !=
#'   "none"`. Default `"grey40"`. This is a fixed colour, not mapped to
#'   data, so it won't interfere with `color_by`'s colour scale.
#' @param color_scale Optional `ggplot2` colour scale to apply to
#'   `color_by`, e.g. `scale_color_viridis_c()` or
#'   `scale_color_brewer(palette = "Set1")`. Since [plot_pca3d()] returns a
#'   plain `ggplot` object, this is equivalent to adding the scale yourself
#'   with `+`, but is provided for symmetry with [animate_pca3d()], where a
#'   scale can't be added after the fact.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examples
#' pca <- prcomp(iris[, 1:4], scale. = TRUE)
#' plot_pca3d(pca, metadata = iris, color_by = Species)
#' plot_pca3d(pca, metadata = iris, color_by = Species, axes = "gizmo")
plot_pca3d <- function(
  pca,
  dims = 1:3,
  metadata = NULL,
  color_by = NULL,
  var_explained = TRUE,
  theta = 30,
  phi = 20,
  depth_cue = TRUE,
  point_size = 3,
  axes = c("none", "full", "gizmo"),
  axis_color = "grey40",
  color_scale = NULL
) {
  axes <- match.arg(axes)
  color_quo <- rlang::enquo(color_by)
  color_name <- if (rlang::quo_is_null(color_quo)) {
    NULL
  } else {
    rlang::as_name(color_quo)
  }

  pca3d_validate_color_scale(color_scale, color_name)

  prepared <- pca3d_prepare_data(pca, dims, metadata, color_name)
  rp <- rotate_project(prepared$coords, theta = theta, phi = phi)

  if (!is.null(color_name)) {
    rp[[color_name]] <- prepared$color_values
  }

  caption <- if (var_explained) pca3d_variance_caption(pca, dims) else NULL

  axis_geom <- if (axes != "none") {
    pca3d_axis_geometry(
      prepared$coords,
      dims,
      theta = theta,
      phi = phi,
      style = axes
    )
  } else {
    NULL
  }

  p <- .pca3d_ggplot(
    rp,
    color_by = color_name,
    caption = caption,
    depth_cue = depth_cue,
    point_size = point_size,
    axis_segments = axis_geom$segments,
    axis_labels = axis_geom$labels,
    axis_color = axis_color,
    axis_alpha = if (axes == "full") 0.6 else 1
  )

  if (!is.null(color_scale)) {
    p <- p + color_scale
  }

  p
}
