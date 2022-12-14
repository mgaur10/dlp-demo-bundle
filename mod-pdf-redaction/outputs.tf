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

output "pdf_redaction_project_id" {
  value = google_project.demo_project_pdf.project_id
}

output "pdf_redaction_input_bucket" {
  value = google_storage_bucket.pdf_input_bucket.name
}



output "pdf_redaction_output_bucket" {
  value = google_storage_bucket.pdf_output_bucket.name
}


output "pdf_redaction_infotypes" {
  value = "PERSON_NAME, LAST_NAME, FIRST_NAME, PHONE_NUMBER"
}


output "pdf_redaction_upload_command" {
  value = "gsutil cp sample_data/test_file.pdf gs://${google_storage_bucket.pdf_input_bucket.name}"
}





