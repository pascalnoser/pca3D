#' @importFrom rlang .data
#' @importFrom gifski gifski
NULL

# Shared validation for the `color_scale` argument of plot_pca3d() and
# animate_pca3d(): must be a ggplot2 scale (e.g. the result of calling
# scale_color_*()), and only makes sense when color_by is also supplied.
pca3d_validate_color_scale <- function(color_scale, color_name) {
  if (is.null(color_scale)) {
    return(invisible(NULL))
  }
  if (!inherits(color_scale, "Scale")) {
    cli::cli_abort(
      "{.arg color_scale} must be a ggplot2 scale, e.g. the result of
       calling {.fn scale_color_viridis_c} or {.fn scale_color_brewer}."
    )
  }
  if (is.null(color_name)) {
    cli::cli_warn(
      "{.arg color_scale} was supplied but {.arg color_by} is {.code NULL};
       the scale will have no effect."
    )
  }
  invisible(NULL)
}

# `frame` is referenced via NSE in gganimate::transition_manual(frame)
utils::globalVariables("frame")

# Shared ggplot-construction logic used by both plot_pca3d() (a single
# frame) and animate_pca3d() (many frames + gganimate::transition_manual()).
#
# `data` must have columns `x`, `y`, `depth`, and optionally a column named
# after `color_by`. Axis text/ticks are hidden because, once rotated, x/y no
# longer correspond to a single PC -- variance explained is communicated via
# `caption` instead.
#
# `axis_segments`/`axis_labels`, if supplied, are data frames from
# pca3d_axis_geometry() (optionally row-bound across frames with a `frame`
# column) drawn as arrows + text *underneath* the point layer, in a fixed
# `axis_color` that's independent of any data colour mapping. `axis_alpha`
# controls their opacity (the "full" style uses a lower value so the
# arrows read as a subtle reference rather than competing with the data).
.pca3d_ggplot <- function(
  data,
  color_by = NULL,
  caption = NULL,
  depth_cue = TRUE,
  point_size = 3,
  axis_segments = NULL,
  axis_labels = NULL,
  axis_color = "grey40",
  axis_alpha = 1
) {
  mapping <- ggplot2::aes(x = .data$x, y = .data$y)
  if (!is.null(color_by)) {
    mapping$colour <- ggplot2::aes(colour = .data[[color_by]])$colour
  }

  p <- ggplot2::ggplot(data, mapping)

  if (!is.null(axis_segments)) {
    p <- p +
      ggplot2::geom_segment(
        data = axis_segments,
        mapping = ggplot2::aes(
          x = .data$x,
          y = .data$y,
          xend = .data$xend,
          yend = .data$yend
        ),
        colour = axis_color,
        alpha = axis_alpha,
        linewidth = 0.5,
        arrow = grid::arrow(length = grid::unit(0.12, "inches")),
        inherit.aes = FALSE
      )
  }
  if (!is.null(axis_labels)) {
    p <- p +
      ggplot2::geom_text(
        data = axis_labels,
        mapping = ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
        colour = axis_color,
        alpha = axis_alpha,
        size = 3,
        inherit.aes = FALSE
      )
  }

  if (depth_cue) {
    p <- p +
      ggplot2::geom_point(ggplot2::aes(
        size = .data$depth,
        alpha = .data$depth
      )) +
      ggplot2::scale_size_continuous(
        range = point_size * c(0.5, 1.5),
        guide = "none"
      ) +
      ggplot2::scale_alpha_continuous(range = c(0.4, 1), guide = "none")
  } else {
    p <- p + ggplot2::geom_point(size = point_size)
  }

  # The "gizmo" style sits outside the point cloud's bounding box (by
  # design, in a fixed corner), so the panel needs to be expanded to avoid
  # clipping it -- ggplot2 otherwise scales purely to geom_point()'s data.
  if (!is.null(axis_segments)) {
    x_range <- c(data$x, axis_segments$x, axis_segments$xend, axis_labels$x)
    y_range <- c(data$y, axis_segments$y, axis_segments$yend, axis_labels$y)
    p <- p + ggplot2::expand_limits(x = range(x_range), y = range(y_range))
  }

  p +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL, caption = caption) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
}
