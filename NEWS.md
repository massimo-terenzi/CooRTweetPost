# CooRTweetPost 0.3.0

## New Features

* **Content ID tracking**: All summary functions now track and export `content_id` information
  - `create_vertex_summary_table()` now includes `unique_contents` and `content_ids` columns
  - `create_community_summary_table()` now includes `unique_contents` and `content_ids` columns
  - `create_object_summary_table()` now includes `unique_contents` and `content_ids` in both `object_summary` and `object_community_long` outputs
  
* Enhanced traceability: Users can now track the relationship between coordinated behavior, shared objects, and original content sources across all aggregation levels (accounts, communities, objects)

* **Function exports**: All summary functions are now properly exported and accessible after loading the package

## Bug Fixes

* Fixed missing pipe operator `%>%` by adding `magrittr` to imports
* Added proper `@export` tags to all summary functions
* Updated NAMESPACE to include all function exports

## Technical Details

The `content_id` column (typically the post URL or unique identifier) is now:
- Aggregated and counted at the vertex level (per account)
- Aggregated and counted at the community level
- Linked to objects in both summary and long-format outputs
- Preserved as comma-separated lists for easy reference

This enables more detailed analysis of content propagation patterns and coordinated sharing strategies.

## Dependencies

* Added `magrittr` to Imports for pipe operator support

---

# CooRTweetPost 0.2.0

* Initial public release
* Core functionality for processing CooRTweet outputs
* Graph enrichment and community detection
* CSV export capabilities for accounts, communities, and objects
