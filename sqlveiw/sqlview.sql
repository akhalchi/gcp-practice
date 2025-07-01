SELECT
  COUNT(DISTINCT user_pseudo_id) AS total_users,
  FORMAT_TIMESTAMP('%Y-%m', TIMESTAMP_MICROS(event_timestamp)) AS event_month,
  event_name,
  COUNT(*) AS event_count
FROM
  `${project_id}.${dataset_name}.ga4_public_dataset`
GROUP BY
  event_month,
  event_name
ORDER BY
  event_month,
  event_name