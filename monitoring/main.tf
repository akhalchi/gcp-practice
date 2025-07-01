resource "google_monitoring_alert_policy" "function_error_alert" {
  display_name = "Cloud Function Errors (upload-to-bq)"
  combiner     = "OR"

  conditions {
    display_name = "Function errors > 0 (last 5m)"
    condition_threshold {
      filter = <<-EOT
        resource.type="cloud_function"
        AND resource.labels.function_name="upload-to-bq"
        AND metric.type="cloudfunctions.googleapis.com/function/execution_count"
        AND metric.labels.status="error"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [var.notification_channel_id]
  enabled               = true
}

resource "google_monitoring_alert_policy" "pubsub_undelivered" {
  display_name = "Pub/Sub Undelivered Messages (platform_rm_topic)"
  combiner     = "OR"

  conditions {
    display_name = "Undelivered messages > 0"
    condition_threshold {
      filter = <<-EOT
        resource.type="pubsub_subscription"
        AND metric.type="pubsub.googleapis.com/subscription/num_undelivered_messages"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [var.notification_channel_id]
  enabled               = true
}

resource "google_monitoring_alert_policy" "scheduler_not_triggered" {
  display_name = "Cloud Scheduler Not Triggered in 24h"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Scheduler job not triggered"
    condition_absent {
      filter = <<-EOT
        resource.type="cloud_scheduler_job"
        AND resource.labels.job_id="daily-csv-loader"
        AND metric.type="cloudscheduler.googleapis.com/job/attempt_count"
      EOT

      duration = "86400s" # 24 hours
    }
  }

  notification_channels = [var.notification_channel_id]
  enabled               = true
}
