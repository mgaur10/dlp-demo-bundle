/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


## NOTE: This provides PoC demo environment for various use cases ##
##  This is not built for production workload ##
## author@manishgaur



output "udf_bq_project_id" {
  value = google_project.demo_project_bq_udf.project_id
}

output "udf_bq_data_set_id" {
  value = google_bigquery_dataset.clear_dataset.dataset_id
}

output "udf_bq_deidenitify_credit_card_query_command" {
  value = "SELECT ${google_bigquery_dataset.clear_dataset.dataset_id}.deidentify_cc(CAST(Card_Number AS STRING)) AS Card_Number,ID,Card_Holder_s_Name FROM `${google_project.demo_project_bq_udf.project_id}.${google_bigquery_dataset.clear_dataset.dataset_id}.${google_bigquery_table.clear_table.table_id}` LIMIT 10;"
}

output "udf_bq_deidenitify_query_command" {
  value = "SELECT ${google_bigquery_dataset.clear_dataset.dataset_id}.deidentify(SSN) AS SSN,ID,Card_Holder_s_Name FROM `${google_project.demo_project_bq_udf.project_id}.${google_bigquery_dataset.clear_dataset.dataset_id}.${google_bigquery_table.clear_table.table_id}` LIMIT 10;"
}



output "udf_bq_reidenitify_step" {
  value = " execute the above deidentify query and export the results in a new table with name udf-deid"
}


output "udf_bq_reidenitify_query_command" {
  value = "SELECT ${google_bigquery_dataset.clear_dataset.dataset_id}.reidentify(SSN) AS SSN,ID,Card_Holder_s_Name FROM `${google_project.demo_project_bq_udf.project_id}.${google_bigquery_dataset.clear_dataset.dataset_id}.udf-deid` LIMIT 10;"
}



/*

output "udf_bq_input_bucket" {
  value = google_storage_bucket.pdf_input_bucket.name
}



output "udf_bq_output_bucket" {
  value = google_storage_bucket.pdf_output_bucket.name
}


output "udf_bq_infotypes" {
  value = "PERSON_NAME, LAST_NAME, FIRST_NAME, PHONE_NUMBER"
}


output "udf_bq_upload_command" {
  value = "gsutil cp sample_data/test_file.pdf gs://${google_storage_bucket.pdf_input_bucket.name}"
}







BigQuery UDF

SELECT clear_dataset_legq.deidentify(SSN) AS SSN,ID,Card_Holder_s_Name FROM `dlp-demo-legq.clear_dataset_legq.cleartext`;


SELECT clear_dataset_legq.reidentify(SSN) AS SSN,ID,Card_Holder_s_Name FROM `dlp-demo-legq.clear_dataset_legq.udf-deid`

*/