create_community_summary_table <- function(coordinated_groups, network_graph) {
  if (!igraph::is_igraph(network_graph)) stop("Invalid graph object. Please provide a valid igraph object.")
  coordinated_vertices <- igraph::V(network_graph)$name
  vert <- igraph::as_data_frame(network_graph, what = "vertices")
  vertices <- vert %>% dplyr::select(name, community) %>% dplyr::rename(account_id = name)
  if ("community" %in% colnames(vertices)) {
    vertices$community <- as.integer(vertices$community)
  }

  edges <- coordinated_groups %>%
    dplyr::filter(account_id %in% coordinated_vertices & account_id_y %in% coordinated_vertices) %>%
    dplyr::group_by(from = account_id, to = account_id_y) %>%
    dplyr::summarize(
      avg_time_delta = mean(time_delta, na.rm = TRUE),
      edge_symmetry_score = dplyr::n_distinct(dplyr::if_else(time_delta < 0, "neg", "pos")) / 2,
      weight = dplyr::n(),
      content_ids = paste(unique(content_id), collapse = ","),
      object_ids = list(unique(object_id)),
      .groups = "drop"
    ) %>%
    dplyr::left_join(vertices, by = c("from" = "account_id")) %>%
    dplyr::rename(community_from = community) %>%
    dplyr::left_join(vertices, by = c("to" = "account_id")) %>%
    dplyr::rename(community_to = community)

  community_long <- edges %>%
    tidyr::pivot_longer(cols = c(community_from, community_to), values_to = "community", names_to = "position") %>%
    dplyr::filter(!is.na(community), !is.na(object_ids))

  community_metrics <- community_long %>%
    dplyr::group_by(community) %>%
    dplyr::summarize(
      avg_time_delta = mean(avg_time_delta, na.rm = TRUE),
      avg_edge_symmetry_score = mean(edge_symmetry_score, na.rm = TRUE),
      .groups = "drop"
    )

  community_objects <- community_long %>%
    tidyr::unnest(object_ids) %>%
    dplyr::filter(object_ids != "") %>%
    dplyr::group_by(community) %>%
    dplyr::summarize(unique_objects = dplyr::n_distinct(object_ids), .groups = "drop")

  # Content ID tracking
  community_contents <- community_long %>%
    dplyr::mutate(content_ids_list = strsplit(content_ids, ",")) %>%
    tidyr::unnest(content_ids_list) %>%
    dplyr::filter(content_ids_list != "") %>%
    dplyr::group_by(community) %>%
    dplyr::summarize(
      unique_contents = dplyr::n_distinct(content_ids_list),
      content_ids = paste(sort(unique(content_ids_list)), collapse = ","),
      .groups = "drop"
    )

  vertices_per_community <- vertices %>%
    dplyr::group_by(community) %>%
    dplyr::summarize(unique_vertices = dplyr::n_distinct(account_id), .groups = "drop")

  community_summary <- community_metrics %>%
    dplyr::left_join(community_objects, by = "community") %>%
    dplyr::left_join(community_contents, by = "community") %>%
    dplyr::left_join(vertices_per_community, by = "community") %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~ ifelse(is.na(.), 0, .)))

  cat("Number of communities in summary table:", nrow(community_summary), "\n")
  cat("Number of communities in network graph:", length(unique(igraph::V(network_graph)$community)), "\n")
  return(community_summary)
}
