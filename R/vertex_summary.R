create_vertex_summary_table <- function(coordinated_groups, network_graph) {
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

  vertices_long <- edges %>%
    tidyr::pivot_longer(cols = c(from, to), values_to = "vertex", names_to = "position") %>%
    dplyr::filter(!is.na(vertex), !is.na(object_ids))

  time_deltas <- vertices_long %>%
    dplyr::group_by(vertex) %>%
    dplyr::summarize(
      avg_time_delta = mean(avg_time_delta, na.rm = TRUE),
      avg_edge_weight = mean(weight, na.rm = TRUE),
      avg_edge_symmetry_score = mean(edge_symmetry_score, na.rm = TRUE),
      .groups = "drop"
    )

  objects_data <- vertices_long %>%
    tidyr::unnest(object_ids) %>%
    dplyr::filter(object_ids != "") %>%
    dplyr::group_by(vertex) %>%
    dplyr::summarize(unique_objects = dplyr::n_distinct(object_ids), .groups = "drop")

  # Content ID tracking
  content_data <- vertices_long %>%
    dplyr::mutate(content_ids_list = strsplit(content_ids, ",")) %>%
    tidyr::unnest(content_ids_list) %>%
    dplyr::filter(content_ids_list != "") %>%
    dplyr::group_by(vertex) %>%
    dplyr::summarize(
      unique_contents = dplyr::n_distinct(content_ids_list),
      content_ids = paste(sort(unique(content_ids_list)), collapse = ","),
      .groups = "drop"
    )

  connections <- edges %>%
    dplyr::bind_rows(dplyr::mutate(edges, from = to, to = from)) %>%
    dplyr::distinct() %>%
    dplyr::group_by(from) %>%
    dplyr::summarize(connected_vertices = dplyr::n_distinct(to), .groups = "drop")

  summary_table <- time_deltas %>%
    dplyr::left_join(objects_data, by = "vertex") %>%
    dplyr::left_join(content_data, by = "vertex") %>%
    dplyr::left_join(connections, by = c("vertex" = "from")) %>%
    dplyr::left_join(vertices, by = c("vertex" = "account_id")) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~ ifelse(is.na(.), 0, .)))

  cat("Number of accounts in summary table:", nrow(summary_table), "\n")
  cat("Number of vertices in network graph:", igraph::vcount(network_graph), "\n")
  return(summary_table)
}
