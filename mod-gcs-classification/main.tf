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





# Create the DLP Project
resource "google_project" "demo_project_gcs" {
  project_id      = "${var.demo_project_id}${var.gcs_dlp_tag}${var.random_string}"
  name            = "DLP Auto GCS Classification"
  billing_account = var.billing_account
  folder_id = var.folder_id
  }



# Enable the necessary API services
resource "google_project_service" "dlp_api_service" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "dlp.googleapis.com",
    "cloudfunctions.googleapis.com",
    "logging.googleapis.com",
    "pubsub.googleapis.com",
  ])

  service = each.key

  project            = google_project.demo_project_gcs.project_id
  disable_on_destroy = true
  disable_dependent_services = true
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service" {
  depends_on = [google_project_service.dlp_api_service]
  create_duration = "45s"
  destroy_duration = "45s"
}

#Creating Staging/QA storage bucket
resource "google_storage_bucket" "cloud_qa_storage_bucket_name" {
  name          = "${var.qa_storage_bucket_name}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_gcs.project_id
  uniform_bucket_level_access = true
}

#Creating storage bucket for sensitive data
resource "google_storage_bucket" "cloud_sens_storage_bucket_name" {
  name          = "${var.sens_storage_bucket_name}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_gcs.project_id
  uniform_bucket_level_access = true
}

#Creating storage bucket for non-sensitive data
resource "google_storage_bucket" "cloud_nonsens_storage_bucket_name" {
  name          = "${var.nonsens_storage_bucket_name}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_gcs.project_id
  uniform_bucket_level_access = true
}

#Create the service Account for DLP function
resource "google_service_account" "def_ser_acc" {
   project = google_project.demo_project_gcs.project_id
   account_id   = "appengine-service-account"
   display_name = "AppEngine Service Account"
   depends_on = [google_project_service.dlp_api_service]
 }


# Add required roles to the service accounts
  resource "google_project_iam_member" "service_dlp_admin" {
   project = google_project.demo_project_gcs.project_id
   role    = "roles/dlp.admin"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

# Add required roles to the service accounts
  resource "google_project_iam_member" "ser_agent" {
    project = google_project.demo_project_gcs.project_id
    role    = "roles/dlp.serviceAgent"
    member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
    depends_on = [google_service_account.def_ser_acc]
  }

  # Add required roles to the service accounts
  resource "google_project_iam_member" "proj_editor" {
   project = google_project.demo_project_gcs.project_id
   role    = "roles/owner"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }


# Creates zip file of function code & requirments.txt
data "archive_file" "source" {
    type        = "zip"
    source_dir  = "${path.module}/application"
    output_path = "${path.module}/dlpfunction.zip"
    depends_on = [google_project_service.dlp_api_service]
}

#Creating the bucket for python source code
resource "google_storage_bucket" "application" {
  name     = "application-${var.demo_project_id}${var.gcs_dlp_tag}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_gcs.project_id
  uniform_bucket_level_access = true
  depends_on = [data.archive_file.source]
}

# Add zip file to the Cloud Function's source code bucket
resource "google_storage_bucket_object" "python_code" {
  name   = "dlpfunction.zip"
  bucket = google_storage_bucket.application.name
  source = "${path.module}/dlpfunction.zip"
  depends_on = [google_storage_bucket.application]
}

#Creating the pubsub topic
resource "google_pubsub_topic" "pubsub_topic" {
  name = var.pubsub_topic_name
  project = google_project.demo_project_gcs.project_id
  }

#Creating the pubsub subscription
resource "google_pubsub_subscription" "pubsub_subscription" {
  name  = var.pubsub_subscription_name
  project = google_project.demo_project_gcs.project_id
  topic = google_pubsub_topic.pubsub_topic.name
  depends_on = [google_pubsub_topic.pubsub_topic]
  
}

# Create the DLP Functions
resource "google_cloudfunctions_function" "create_DLP_job" {
  name        = "create_DLP_job"
  description = "Create DLP Job"
  runtime     = "python37"
  project     = google_project.demo_project_gcs.project_id
  region      = var.network_region
  ingress_settings = "ALLOW_INTERNAL_AND_GCLB"
  
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.application.name
  source_archive_object = google_storage_bucket_object.python_code.name
   entry_point           = "create_DLP_job"
  service_account_email = "${google_service_account.def_ser_acc.email}"
  
  event_trigger {
        event_type = "google.storage.object.finalize"
        resource   = "${var.qa_storage_bucket_name}${var.random_string}"  # quarantine bucket where files are uploaded for processing
    }

  depends_on = [
      time_sleep.wait_enable_service,
      google_storage_bucket_object.python_code,
      ]

  environment_variables = {
    PROJ_ID      = google_project.demo_project_gcs.project_id
    QA_BUCKET    = google_storage_bucket.cloud_qa_storage_bucket_name.name
    SENS_BUCKET  = google_storage_bucket.cloud_sens_storage_bucket_name.name
    NONS_BUCKET  = google_storage_bucket.cloud_nonsens_storage_bucket_name.name
    PB_SB_TOP    = var.pubsub_topic_name
  }
}

resource "google_cloudfunctions_function" "resolve_DLP" {
  name        = "resolve_DLP"
  description = "Resolve DLP"
  runtime     = "python37"
  project     = google_project.demo_project_gcs.project_id
  region      = var.network_region
  ingress_settings = "ALLOW_INTERNAL_AND_GCLB"
  
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.application.name
  source_archive_object = google_storage_bucket_object.python_code.name
  entry_point           = "resolve_DLP"
  service_account_email = "${google_service_account.def_ser_acc.email}"
  
    event_trigger {
        event_type = "google.pubsub.topic.publish"
        resource   = "projects/${google_project.demo_project_gcs.project_id}/topics/${var.pubsub_topic_name}"   
    }
  
  depends_on = [
      time_sleep.wait_enable_service,
      google_storage_bucket_object.python_code,
      ]
      
  environment_variables = {
   PROJ_ID      = google_project.demo_project_gcs.project_id
    QA_BUCKET    = google_storage_bucket.cloud_qa_storage_bucket_name.name
    SENS_BUCKET  = google_storage_bucket.cloud_sens_storage_bucket_name.name
    NONS_BUCKET  = google_storage_bucket.cloud_nonsens_storage_bucket_name.name
    PB_SB_TOP    = var.pubsub_topic_name
     }
}


resource "null_resource" "del_temp_files" {
  depends_on = [google_cloudfunctions_function.resolve_DLP]
  triggers = {
  #  dlp_template = "${google_data_loss_prevention_deidentify_template.deid_template}"
  project_id = "${google_project.demo_project_gcs.project_id}"
  }

 provisioner "local-exec" {
    when        = destroy
  command     = <<EOT
  rm dlpfunction.zip
  EOT
  working_dir = path.module
 }
 }
