#' Timeline theme presets
#'
#' @param style Theme name: `"minimal"`, `"nature"`, or `"dark"`.
#' @param ... Passed to [ggplot2::theme()].
#' @return A ggplot2 theme object.
#' @export
#' @examples
#' \dontrun{
#' ggtimeline(...) + theme_timeline("nature")
#' }
theme_timeline <- function(style = c("minimal", "nature", "dark"), ...) {
  style <- match.arg(style)
  base <- switch(
    style,
    minimal = ggplot2::theme_void(base_family = "sans") +
      ggplot2::theme(
        plot.background = ggplot2::element_rect(fill = "white", colour = NA),
        panel.background = ggplot2::element_rect(fill = "white", colour = NA),
        plot.title = ggplot2::element_text(face = "bold", size = 14, hjust = 0.5),
        plot.subtitle = ggplot2::element_text(size = 10, hjust = 0.5, colour = "#555555"),
        legend.position = "bottom",
        legend.title = ggplot2::element_text(face = "bold", size = 9),
        legend.text = ggplot2::element_text(size = 8),
        plot.margin = ggplot2::margin(8, 12, 8, 12)
      ),
    nature = ggplot2::theme_void(base_family = "Helvetica") +
      ggplot2::theme(
        plot.background = ggplot2::element_rect(fill = "white", colour = NA),
        panel.background = ggplot2::element_rect(fill = "white", colour = NA),
        plot.title = ggplot2::element_text(
          face = "bold", size = 9, hjust = 0, colour = "black"
        ),
        plot.subtitle = ggplot2::element_text(size = 7, hjust = 0, colour = "#333333"),
        legend.position = "bottom",
        legend.title = ggplot2::element_text(face = "bold", size = 7),
        legend.text = ggplot2::element_text(size = 7),
        legend.key.size = grid::unit(0.3, "cm"),
        plot.margin = ggplot2::margin(4, 6, 4, 6)
      ),
    dark = ggplot2::theme_void(base_family = "sans") +
      ggplot2::theme(
        plot.background = ggplot2::element_rect(fill = "#1B1B1B", colour = NA),
        panel.background = ggplot2::element_rect(fill = "#1B1B1B", colour = NA),
        plot.title = ggplot2::element_text(
          face = "bold", size = 14, hjust = 0.5, colour = "#F2F2F2"
        ),
        plot.subtitle = ggplot2::element_text(
          size = 10, hjust = 0.5, colour = "#B0B0B0"
        ),
        legend.position = "bottom",
        legend.title = ggplot2::element_text(face = "bold", size = 9, colour = "#F2F2F2"),
        legend.text = ggplot2::element_text(size = 8, colour = "#D0D0D0"),
        legend.background = ggplot2::element_rect(fill = "#1B1B1B", colour = NA),
        legend.key = ggplot2::element_rect(fill = "#1B1B1B", colour = NA),
        text = ggplot2::element_text(colour = "#F2F2F2"),
        plot.margin = ggplot2::margin(8, 12, 8, 12)
      )
  )
  base + ggplot2::theme(...)
}
