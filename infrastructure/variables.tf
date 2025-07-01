variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west4"
}

variable "sa_id" {
  description = "Service Account ID"
  type        = string
}

variable "sa_display_name" {
  description = "Service Account Display Name"
  type        = string
}

variable "bq_dataset_name" {
  description = "BigQuery dataset name"
  type        = string
}
