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


####### Module PDF Redaction #################
/*
output "_module_pdf_redaction_01_project_id" {
  value = module.pdf_redaction.pdf_redaction_project_id
}

output "_module_pdf_redaction_04_infotypes" {
  value = module.pdf_redaction.pdf_redaction_infotypes
}


output "_module_pdf_redaction_01_input_bucket" {
  value = module.pdf_redaction.pdf_redaction_input_bucket
}



output "_module_pdf_redaction_02_output_bucket" {
  value = module.pdf_redaction.pdf_redaction_output_bucket
}

*/



output "_module_dlp_pdf_redaction_03_upload_command" {
  value = module.pdf_redaction.pdf_redaction_upload_command
}


############ DLP API Calls on a Server ################

/*
output "_module_dlp_api_dlp_dir_change_command" {
  value = module.dlp_api.dlp_api_dir_change_command
}

output "_module_dlp_api_01_project_id" {
  value = module.dlp_api.dlp_api_project_id
}



output "_module_dlp_api_test_script_inspect_file" {
  value = module.dlp_api.dlp_api_test_script_inspect_file
}
*/
output "_module_dlp_api_01_iap_ssh_tunnel_dlp_instance" {
  value = module.dlp_api.dlp_api_iap_ssh_tunnel_dlp_instance
}


output "_module_dlp_api_02_test_script_inspect_text" {
  value = module.dlp_api.dlp_api_test_script_inspect_text
}

output "_module_dlp_api_03_test_script_inspect_file" {
  value = module.dlp_api.dlp_api_test_script_inspect_file
}

output "_module_dlp_api_04_test_script_masking" {
  value = module.dlp_api.dlp_api_test_script_masking
}

output "_module_dlp_api_05_test_script_redaction" {
  value = module.dlp_api.dlp_api_test_script_redaction
}



############ DLP GCS Automatic Classification ################


/*
output "_module_automatic_gcs_classification_01__project_id" {
  value = module.gcs_classification.automatic_gcs_classification_project_id
}


output "_module_dlp_automatic_gcs_classification_00_input_qa_bucket" {
  value = module.gcs_classification.automatic_gcs_classification_input_qa_bucket
}



output "_module_dlp_automatic_gcs_classification_02_output_sesitive_bucket" {
  value = module.gcs_classification.automatic_gcs_classification_output_sesitive_bucket
}


output "_module_dlp_automatic_gcs_classification_03_output_non_sesitive_bucket" {
  value = module.gcs_classification.automatic_gcs_classification__output_non_sesitive_bucket
}
*/

output "_module_dlp_automatic_gcs_classification_04_upload_command" {
  value = module.gcs_classification.automatic_gcs_classification_upload_command
}


############ DLP BigQuery UDF ################

/*

output "_module_bigquery_udf_01__project_id" {
  value = module.bq_udf.udf_bq_project_id
}



output "_module_bigquery_udf_02__data_set_id"  {
  value = module.bq_udf.udf_bq_data_set_id
}

output "_module_bigquery_udf_05_udf_bq_reidenitify_step" {
  value = module.bq_udf.udf_bq_reidenitify_step
}

*/

output "_module_dlp_bigquery_udf_01_credit_card_mask_query" {
  value = module.bq_udf.udf_bq_deidenitify_credit_card_query_command
}

output "_module_dlp_bigquery_udf_02_udf_deidentify_query" {
  value = module.bq_udf.udf_bq_deidenitify_query_command
}


output "_module_dlp_bigquery_udf_03_udf_bq_reidenitify_query" {
  value = module.bq_udf.udf_bq_reidenitify_query_command
}
