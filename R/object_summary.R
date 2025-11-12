#' Create summary table by object
#'
#' Creates summary tables for coordinated objects (shared content) in the network.
#' Includes content_id tracking to link objects to their source posts.
#'
#' @param coordinated_groups A data frame of coordinated groups from detect_groups()
#' @param network_graph An igraph object from generate_coordinated_network()
#'
#' @return A list with two data frames: object_summary and object_community_long
#' @export
create_object_summary_table <- function(coordinated_groups, network_graph) {
  if (!igraph::is_igraph(network_graph)) {
    stop("Invalid graph object. Please provide a valid igraph object.")
  }

  coordinated_vertices <- igraph::V(network_graph)$name

  vert <- igraph::as_data_frame(network_graph, what = "vertices") %>%
    dplyr::select(name, community) %>%
    dplyr::rename(account_id = name) %>%
    dplyr::mutate(community = as.integer(community))

  edges <- coordinated_groups %>%
    dplyr::filter(account_id %in% coordinated_vertices,
                  account_id_y %in% coordinated_vertices)

  object_long_base <- edges %>%
    dplyr::select(account_id, account_id_y, object_id, content_id, time_delta) %>%
    dplyr::filter(!is.na(object_id)) %>%
    tidyr::pivot_longer(cols = c(account_id, account_id_y), names_to = "position", values_to = "account_id") %>%
    dplyr::left_join(vert, by = "account_id")

  object_summary <- object_long_base %>%
    dplyr::group_by(object_id) %>%
    dplyr::summarise(
      unique_vertices = dplyr::n_distinct(account_id),
      unique_communities = dplyr::n_distinct(community),
      community_list = paste(sort(unique(community)), collapse = ","),
      unique_contents = dplyr::n_distinct(content_id),
      content_ids = paste(sort(unique(content_id)), collapse = ","),
      avg_time_delta = mean(time_delta, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~ifelse(is.na(.), 0, .)))

  object_community_long <- object_long_base %>%
    dplyr::select(object_id, community, content_id) %>%
    dplyr::filter(!is.na(object_id), !is.na(community)) %>%
    dplyr::distinct()

  cat("✅ Oggetti analizzati:", nrow(object_summary), "\n")
  return(list(
    object_summary = object_summary,
    object_community_long = object_community_long
  ))
}
