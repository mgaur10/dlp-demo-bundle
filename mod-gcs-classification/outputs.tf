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



output "automatic_gcs_classification_project_id" {
  value = google_project.demo_project_gcs.project_id
}


output "automatic_gcs_classification_input_qa_bucket" {
  value = google_storage_bucket.cloud_qa_storage_bucket_name.name
}



output "automatic_gcs_classification_output_sesitive_bucket" {
  value = google_storage_bucket.cloud_sens_storage_bucket_name.name
}


output "automatic_gcs_classification__output_non_sesitive_bucket"  {
  value = google_storage_bucket.cloud_nonsens_storage_bucket_name.name 
}


output "automatic_gcs_classification_upload_command" {
  value = "gsutil cp sample_data/*sample_* gs://${google_storage_bucket.cloud_qa_storage_bucket_name.name}"
}
