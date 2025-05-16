#' Full pipeline to post-process CooRTweet results and export CSV summaries
#'
#' @param coordinated_groups Output from detect_groups()
#' @param network_graph Output from generate_coordinated_network()
#' @param output_dir Directory to save results
#' @export
export_all_results <- function(coordinated_groups, network_graph, output_dir = "output") {
  stopifnot(igraph::is_igraph(network_graph))

  if (is.null(V(network_graph)$name)) {
    V(network_graph)$name <- as.character(seq_len(vcount(network_graph)))
  }

  if (vcount(network_graph) > 1 && ecount(network_graph) > 0) {
    com <- igraph::cluster_louvain(network_graph)
    V(network_graph)$community <- igraph::membership(com)
  } else {
    V(network_graph)$community <- NA_integer_
  }

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  accounts_summary <- create_vertex_summary_table(coordinated_groups, network_graph)
  communities_summary <- create_community_summary_table(coordinated_groups, network_graph)
  objects_output <- create_object_summary_table(coordinated_groups, network_graph)

  data.table::fwrite(accounts_summary, file.path(output_dir, "coordinated_accounts.csv"))
  data.table::fwrite(communities_summary, file.path(output_dir, "coordinated_communities.csv"))
  data.table::fwrite(objects_output$object_summary, file.path(output_dir, "coordinated_objects.csv"))
  data.table::fwrite(objects_output$object_community_long, file.path(output_dir, "coordinated_objects_by_community.csv"))

  saveRDS(coordinated_groups, file.path(output_dir, "coordinated_groups.rds"))
  saveRDS(network_graph, file.path(output_dir, "network_coordinated.rds"))

  cat("\n✅  Completed\n")
  cat("📌 Nodes:", igraph::vcount(network_graph), " | Edges:", igraph::ecount(network_graph), 
      " | Communities:", length(unique(V(network_graph)$community)), "\n")
}
