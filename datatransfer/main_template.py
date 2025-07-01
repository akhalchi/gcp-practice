import os
import csv
import tempfile
import pandas as pd
from google.cloud import storage, bigquery

def clean_csv(input_path):
    df = pd.read_csv(input_path)

    cleaned_path = input_path.replace(".csv", "_cleaned.csv")
    df.to_csv(
        cleaned_path,
        index=False,
        header=True,
        quoting=csv.QUOTE_ALL
    )
    return cleaned_path

def main(event, context):
    project_id = "__PROJECT_ID__"
    dataset_name = "__BQ_DATASET_NAME__"
    bucket_name = "__BUCKET_NAME__"
    csv_file_name = "__CSV_FILENAME__"

    storage_client = storage.Client(project=project_id)
    bq_client = bigquery.Client(project=project_id)
    bucket = storage_client.bucket(bucket_name)


    blobs = list(bucket.list_blobs())
    last_updated = max(blob.updated for blob in blobs) if blobs else None
    print(f"Last updated date: {last_updated}")

    print("Files in bucket:")
    for blob in blobs:
        print(blob.name)


    blob = bucket.blob(csv_file_name)
    if not blob.exists():
        print(f"File {csv_file_name} not found in bucket {bucket_name}.")
        return


    with tempfile.TemporaryDirectory() as tmpdir:
        local_path = os.path.join(tmpdir, csv_file_name)
        blob.download_to_filename(local_path)
        print(f"Downloaded CSV to {local_path}")

        cleaned_path = clean_csv(local_path)
        cleaned_blob_name = csv_file_name.replace(".csv", "_cleaned.csv")
        cleaned_blob = bucket.blob(cleaned_blob_name)
        cleaned_blob.upload_from_filename(cleaned_path)
        print(f"Uploaded cleaned CSV as {cleaned_blob_name}")


    dataset_ref = bq_client.dataset(dataset_name)
    table_ref = dataset_ref.table(cleaned_blob_name.replace(".csv", ""))

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE
    )

    uri = f"gs://{bucket_name}/{cleaned_blob_name}"
    load_job = bq_client.load_table_from_uri(uri, table_ref, job_config=job_config)
    load_job.result()

    print(f"Loaded {cleaned_blob_name} into BigQuery table {dataset_name}.{table_ref.table_id}.")

