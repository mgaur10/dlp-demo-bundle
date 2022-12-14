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

locals {
  app_suffix            = "-${var.suffix}"
  app_suffix_underscore = "_${var.suffix}"
}


### If using an existing project update "${var.demo_project_id}${var.dlp_pdf_tag}${var.random_string}" with "var.demo_project_id"

# Create the Project. ### Comment this resource If using an existing project
resource "google_project" "demo_project_pdf" {
  project_id      = "${var.demo_project_id}${var.dlp_pdf_tag}${var.random_string}"
  name            = "DLP PDF Redaction"
  billing_account = var.billing_account
  folder_id = var.folder_id
  }

# Enable the necessary API services
resource "google_project_service" "api_service" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "run.googleapis.com",
    "bigquery.googleapis.com",
    "dlp.googleapis.com",
    "workflows.googleapis.com",
    "cloudfunctions.googleapis.com",
    ])

  service = each.key

  project            = google_project.demo_project_pdf.project_id
  disable_on_destroy = true
  disable_dependent_services = true
  depends_on = [google_project.demo_project_pdf] ### Comment this line If using an existing project
}

resource "time_sleep" "wait_enable_service" {
  depends_on = [google_project_service.api_service]
  create_duration = "30s"
  destroy_duration = "30s"
}


# build submit
resource "null_resource" "build_image" {
 
  triggers = {
    data_set = "${google_project.demo_project_pdf.project_id}"
  }

  provisioner "local-exec" {
     command = <<EOT
  gcloud builds submit --config ./mod-pdf-redaction/build-app-images.yaml --project ${google_project.demo_project_pdf.project_id}
  EOT
 }
 depends_on = [
  time_sleep.wait_enable_service
 ]
 }


resource "time_sleep" "wait_build_image" {
  depends_on = [null_resource.build_image]
  create_duration = "15s"
  destroy_duration = "15s"
}