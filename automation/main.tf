resource "google_cloud_scheduler_job" "daily_csv_loader" {
  name        = "daily-csv-loader"
  description = "Triggers Cloud Function via platform_rm_topic to load CSV into BigQuery"
  schedule    = "0 7 * * *"  # 7:00 AM daily
  time_zone   = "Europe/Amsterdam"
  region      = var.scheduler_region

  pubsub_target {
    topic_name = "projects/${var.project_id}/topics/platform_rm_topic"
    data       = base64encode(jsonencode({
      filename = "ga4_public_dataset.csv"
    }))
  }
}
