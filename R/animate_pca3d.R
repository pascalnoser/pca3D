#' Animate a full rotation of a 3D-style PCA plot and save as a GIF
#'
#' Renders `n_frames` views of the same point cloud spinning through a full
#' 360 degree azimuth rotation (elevation `phi` stays fixed) and saves them
#' as a looping GIF. See [plot_pca3d()] for a single static view, which is
#' also what each frame here looks like.
#'
#' @inheritParams plot_pca3d
#' @param n_frames Number of frames in the full 360 degree rotation. Default `90`.
#' @param fps Frames per second in the output GIF. Default `24`.
#' @param file Path to save the GIF file to. Default `"pca3d.gif"`.
#' @param width,height Pixel dimensions of the output GIF. Default `600` each.
#' @param axes Draw an indicator of which direction each PC axis points,
#'   rotating in sync with the point cloud. One of `"none"` (default),
#'   `"full"` (arrows through the point cloud from the origin along each PC
#'   direction, labelled `PC<n>` at the tip), or `"gizmo"` (the same
#'   arrows, but short and anchored at a fixed corner of the plot,
#'   independent of data scale, like a small rotating compass).
#' @param axis_color Colour used for the axis arrows/labels when `axes !=
#'   "none"`. Default `"grey40"`. This is a fixed colour, not mapped to
#'   data, so it won't interfere with `color_by`'s colour scale.
#' @param color_scale Optional `ggplot2` colour scale to apply to
#'   `color_by`, e.g. `scale_color_viridis_c()` or
#'   `scale_color_brewer(palette = "Set1")`. Because the returned/rendered
#'   result of [animate_pca3d()] is a rendered GIF rather than a `ggplot`
#'   object, you can't customise the colour scale by adding to it
#'   afterwards (as you can with [plot_pca3d()]) -- pass it here instead.
#'
#' @return The path to the saved GIF file, invisibly.
#' @export
#'
#' @examples
#' \donttest{
#' pca <- prcomp(iris[, 1:4], scale. = TRUE)
#' animate_pca3d(
#'   pca,
#'   metadata = iris,
#'   color_by = Species,
#'   n_frames = 12,
#'   file = tempfile(fileext = ".gif")
#' )
#'
#' # Customise the colour scale
#' animate_pca3d(
#'   pca,
#'   metadata = iris,
#'   color_by = Species,
#'   n_frames = 12,
#'   file = tempfile(fileext = ".gif"),
#'   color_scale = ggplot2::scale_color_brewer(palette = "Set1")
#' )
#' }
animate_pca3d <- function(
  pca,
  dims = 1:3,
  metadata = NULL,
  color_by = NULL,
  var_explained = TRUE,
  phi = 20,
  depth_cue = TRUE,
  point_size = 3,
  n_frames = 90,
  fps = 24,
  file = "pca3d.gif",
  width = 600,
  height = 600,
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

  # Exclude 360 so the loop doesn't repeat the starting frame
  thetas <- seq(0, 360, length.out = n_frames + 1)[seq_len(n_frames)]

  frames <- lapply(seq_along(thetas), function(i) {
    rp <- rotate_project(prepared$coords, theta = thetas[i], phi = phi)
    rp$frame <- i
    if (!is.null(color_name)) {
      rp[[color_name]] <- prepared$color_values
    }
    rp
  })
  all_frames <- do.call(rbind, frames)
  all_frames$frame <- factor(all_frames$frame, levels = seq_len(n_frames))

  caption <- if (var_explained) pca3d_variance_caption(pca, dims) else NULL

  axis_segments <- NULL
  axis_labels <- NULL
  if (axes != "none") {
    axis_frames <- lapply(seq_along(thetas), function(i) {
      geom <- pca3d_axis_geometry(
        prepared$coords,
        dims,
        theta = thetas[i],
        phi = phi,
        style = axes
      )
      geom$segments$frame <- i
      geom$labels$frame <- i
      geom
    })
    axis_segments <- do.call(rbind, lapply(axis_frames, `[[`, "segments"))
    axis_labels <- do.call(rbind, lapply(axis_frames, `[[`, "labels"))
    axis_segments$frame <- factor(
      axis_segments$frame,
      levels = seq_len(n_frames)
    )
    axis_labels$frame <- factor(axis_labels$frame, levels = seq_len(n_frames))
  }

  p <- .pca3d_ggplot(
    all_frames,
    color_by = color_name,
    caption = caption,
    depth_cue = depth_cue,
    point_size = point_size,
    axis_segments = axis_segments,
    axis_labels = axis_labels,
    axis_color = axis_color,
    axis_alpha = if (axes == "full") 0.6 else 1
  )

  if (!is.null(color_scale)) {
    p <- p + color_scale
  }

  p <- p + gganimate::transition_manual(frame)

  anim <- gganimate::animate(
    p,
    nframes = n_frames,
    fps = fps,
    width = width,
    height = height,
    renderer = gganimate::gifski_renderer(loop = TRUE)
  )

  gganimate::anim_save(file, animation = anim)
  invisible(file)
}
