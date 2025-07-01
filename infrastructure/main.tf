provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "main" {
  account_id   = var.sa_id
  display_name = var.sa_display_name
}

resource "google_project_iam_member" "storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "storage_user" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "bq_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_project_iam_member" "cloudfunctions_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_bigquery_dataset" "main_dataset" {
  dataset_id                  = var.bq_dataset_name
  project                    = var.project_id
  location                   = var.region
  description                = "Dataset for platform project"
}