resource "google_bigquery_table" "ga4_analysis_view" {
  project    = var.project_id
  dataset_id = var.bq_dataset_name
  table_id   = "ga4_analysis_view"
  
  view {
    query          = templatefile("${path.module}/view_query.sql", {
                      project_id   = var.project_id,
                      dataset_name = var.bq_dataset_name
                    })
    use_legacy_sql = false
  }
}
