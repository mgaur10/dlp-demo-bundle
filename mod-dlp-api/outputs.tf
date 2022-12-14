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



output "dlp_api_project_id" {
  value = google_project.demo_project_dlp_api.project_id
}

output "dlp_api_iap_ssh_tunnel_dlp_instance" {
  value = "gcloud compute ssh ${google_compute_instance.dlp_demo_server.name} --project ${google_project.demo_project_dlp_api.project_id} --zone ${var.network_zone} --tunnel-through-iap"
}

output "dlp_api_dir_change_command" {
  value = "cd /tmp/nodejs-dlp/samples"
}
output "dlp_api_test_script_inspect_text" {
  value = "node /tmp/nodejs-dlp/samples/inspectString.js ${google_project.demo_project_dlp_api.project_id} \"My email address is jenny@somedomain.com and you can call me at 555-867-5309.\""
}

output "dlp_api_test_script_inspect_file" {
  value = "node /tmp/nodejs-dlp/samples/inspectFile.js ${google_project.demo_project_dlp_api.project_id} /tmp/nodejs-dlp/samples/resources/accounts.txt"
}

/*
output "dlp_api_test_script_inspect_file" {
  value = "node inspectFile.js ${google_project.demo_project_dlp_api.project_id} resources/dates.txt"
}

*/

output "dlp_api_test_script_masking" {
  value = "node /tmp/nodejs-dlp/samples/deidentifyWithMask.js ${google_project.demo_project_dlp_api.project_id} \"My phone number is 555-555-5555.\""
}

output "dlp_api_test_script_redaction" {
  value = "node /tmp/nodejs-dlp/samples/redactText.js ${google_project.demo_project_dlp_api.project_id} \"Please refund the purchase to my credit card 4012888888881881.\" "
}
