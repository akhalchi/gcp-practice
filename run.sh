#!/bin/bash

# Load env variables
source .env

# export envs for terraform
export TF_VAR_project_id="$PROJECT_ID"
export TF_VAR_region="$REGION"
export TF_VAR_sa_id="$SA_ID"
export TF_VAR_sa_display_name="$SA_DISPLAY_NAME"
export TF_VAR_bq_dataset_name="$BQ_DATASET_NAME"
export TF_VAR_bucket_name="$BUCKET_NAME"
export TF_VAR_bucket_region="$BUCKET_REGION"
export TF_VAR_csv_filename="$CSV_FILENAME"
export TF_VAR_cloud_function_name="$CLOUD_FUNCTION_NAME"
export TF_VAR_pubsub_topic_name="$PUBSUB_TOPIC_NAME"
export TF_VAR_schedule_cron="$SCHEDULE_CRON"

export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"


gcloud config set project $PROJECT_ID
gcloud config set account $ADMIN_ACCOUNT

# 1. Deploy infrastructure
echo "=== Deploying Infrastructure ==="
(cd infrastructure && terraform init && terraform apply -auto-approve)

# 2. Deploy function
echo "=== Deploying Function ==="
( cd datatransfer && \
  cp main_template.py main.py && \
  sed -i "s|__PROJECT_ID__|$PROJECT_ID|g" main.py && \
  sed -i "s|__BQ_DATASET_NAME__|$BQ_DATASET_NAME|g" main.py && \
  sed -i "s|__BUCKET_NAME__|$BUCKET_NAME|g" main.py && \
  sed -i "s|__CSV_FILENAME__|$CSV_FILENAME|g" main.py
)

gcloud pubsub topics describe "$FUNCTION_TRIGGER_TOPIC" >/dev/null 2>&1 || \
gcloud pubsub topics create "$FUNCTION_TRIGGER_TOPIC"

(cd datatransfer && gcloud functions deploy "$FUNCTION_NAME" \
  --runtime python311 \
  --region "$FUNCTION_REGION" \
  --source . \
  --entry-point main \
  --memory 512MB \
  --service-account "$SA_EMAIL" \
  --trigger-topic "$FUNCTION_TRIGGER_TOPIC" \
  --set-env-vars GOOGLE_CLOUD_PROJECT="$PROJECT_ID")

gcloud run services add-iam-policy-binding "$FUNCTION_NAME" \
  --region=europe-west4 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/run.invoker"

#gcloud config set account $SA_EMAIL
gcloud pubsub topics publish platform_rm_topic --message='{"filename":"ga4_public_dataset.csv"}'

# 3. Deploy sqlview
#(cd sqlview && terraform init && terraform apply -auto-approve)

# 4. Deploy Scheduler
export TF_VAR_scheduler_region="$SCHEDULER_REGION"
(cd automation && terraform init && terraform apply -auto-approve)

# 5. Deploy Monitoring
#(cd monitoring && terraform init && terraform apply -auto-approve)