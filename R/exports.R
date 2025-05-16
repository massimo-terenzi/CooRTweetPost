#' Full pipeline to post-process CooRTweet results and export CSV summaries
#'
#' This function performs post-processing on the outputs of CooRTweet by enriching
#' the coordination graph with community detection, generating summary tables, and exporting
#' them as CSV files, ready for further use (e.g., in a web-based post-processor).
#'
#' @param coordinated_groups A data frame resulting from CooRTweet's `detect_groups()` function
#' @param network_graph An igraph object returned by `generate_coordinated_network()`
#' @param output_dir Directory where the output files will be saved (default: "output")
#'
#' @return No return value. Outputs are written to disk.
#' @export
export_all_results <- function(coordinated_groups, network_graph, output_dir = "output") {
  stopifnot(igraph::is_igraph(network_graph))

  cat("\n🔄 Starting post-processing...\n")

  # Ensure vertex names exist
  if (is.null(igraph::V(network_graph)$name)) {
    igraph::V(network_graph)$name <- as.character(seq_len(igraph::vcount(network_graph)))
    cat("ℹ️  Vertex names not found — default names assigned.\n")
  }

  # Apply Louvain clustering if graph is valid
  if (igraph::vcount(network_graph) > 1 && igraph::ecount(network_graph) > 0) {
    com <- igraph::cluster_louvain(network_graph)
    igraph::V(network_graph)$community <- igraph::membership(com)
    cat("✅ Community detection completed (Louvain method).\n")
  } else {
    igraph::V(network_graph)$community <- NA_integer_
    cat("⚠️  Graph is too small — community detection skipped.\n")
  }

  # Create output folder
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  cat("📁 Output directory created (or already exists):", normalizePath(output_dir), "\n")

  # Generate summaries
  cat("📊 Generating summary tables...\n")
  accounts_summary <- create_vertex_summary_table(coordinated_groups, network_graph)
  communities_summary <- create_community_summary_table(coordinated_groups, network_graph)
  objects_output <- create_object_summary_table(coordinated_groups, network_graph)

  # Write CSVs
  data.table::fwrite(accounts_summary, file.path(output_dir, "coordinated_accounts.csv"))
  data.table::fwrite(communities_summary, file.path(output_dir, "coordinated_communities.csv"))
  data.table::fwrite(objects_output$object_summary, file.path(output_dir, "coordinated_objects.csv"))
  data.table::fwrite(objects_output$object_community_long, file.path(output_dir, "coordinated_objects_by_community.csv"))
  cat("📦 CSV files saved.\n")

  # Final status
  cat("\n✅ Post-processing complete.\n")
  cat("📌 Nodes:", igraph::vcount(network_graph),
      "| Edges:", igraph::ecount(network_graph),
      "| Communities:", length(unique(igraph::V(network_graph)$community)), "\n")
}
