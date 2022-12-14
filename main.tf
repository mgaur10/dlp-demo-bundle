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



# Random id for naming
resource "random_string" "id" {
  length  = 4
  upper   = false
  lower   = true
  number  = true
  special = false
}

# Create Folder in GCP Organization
resource "google_folder" "terraform_solution" {
  display_name = "${var.folder_name}${random_string.id.result}"
  parent       = "organizations/${var.organization_id}"
}



## Credit to https://github.com/GoogleCloudPlatform/dlp-pdf-redaction for base code for the module
module "pdf_redaction" {
  source                = "./mod-pdf-redaction"
  folder_id             = google_folder.terraform_solution.name
  demo_project_id       = var.demo_project_id
  network_region        = var.network_region
  random_string         = random_string.id.result
  dlp_pdf_tag           = "pdf-red-"
  billing_account       = var.billing_account
  organization_id       = var.organization_id
  suffix                = random_string.id.result
  image_dlp_runner      = "gcr.io/${var.demo_project_id}pdf-red-${random_string.id.result}/dlp-runner"
  image_findings_writer = "gcr.io/${var.demo_project_id}pdf-red-${random_string.id.result}/findings-writer"
  image_pdf_merger      = "gcr.io/${var.demo_project_id}pdf-red-${random_string.id.result}/pdf-merger"
  image_pdf_splitter    = "gcr.io/${var.demo_project_id}pdf-red-${random_string.id.result}/pdf-splitter"
}



module "gcs_classification" {
  source          = "./mod-gcs-classification"
  folder_id       = google_folder.terraform_solution.name
  demo_project_id = var.demo_project_id
  organization_id = var.organization_id
  network_region  = var.network_region
  random_string   = random_string.id.result
  gcs_dlp_tag     = "gcs-clas-"

  billing_account             = var.billing_account
  qa_storage_bucket_name      = "dlp-demo-qa-"
  sens_storage_bucket_name    = "dlp-demo-sens-"
  nonsens_storage_bucket_name = "dlp-demo-nonsens-"
  pubsub_topic_name           = "dlp-demo-pubsub"
  pubsub_subscription_name    = "dlp-demo-pubsub-topic"

}



module "dlp_api" {
  source           = "./mod-dlp-api"
  folder_id        = google_folder.terraform_solution.name
  demo_project_id  = var.demo_project_id
  organization_id  = var.organization_id
  network_region   = var.network_region
  network_zone     = var.network_zone
  random_string    = random_string.id.result
  api_dlp_tag      = "dlp-api-"
  vpc_network_name = var.vpc_network_name
  billing_account  = var.billing_account
}


module "bq_udf" {
  source           = "./mod-udf-enc-dec"
  folder_id        = google_folder.terraform_solution.name
  demo_project_id  = var.demo_project_id
  organization_id  = var.organization_id
  network_region   = var.network_region
  network_zone     = var.network_zone
  random_string    = random_string.id.result
  udf_dlp_tag      = "bq-udf-"
  vpc_network_name = var.vpc_network_name
  billing_account  = var.billing_account
  keyring_name     = var.keyring_name
  crypto_key_name  = var.crypto_key_name

  pubsub_topic_name        = "dlp-demo-pubsub"
  pubsub_subscription_name = "dlp-demo-pubsub-topic"

}



module "bq_finding_export" {
  source                   = "./mod-bq-findings"
  folder_id                = google_folder.terraform_solution.name
  demo_project_id          = var.demo_project_id
  organization_id          = var.organization_id
  network_region           = var.network_region
  network_zone             = var.network_zone
  random_string            = random_string.id.result
  bq_dlp_tag               = "bq-exp-"
  vpc_network_name         = var.vpc_network_name
  billing_account          = var.billing_account
  keyring_name             = var.keyring_name
  crypto_key_name          = var.crypto_key_name
  pubsub_topic_name        = "dlp-demo-pubsub"
  pubsub_subscription_name = "dlp-demo-pubsub-topic"

}

