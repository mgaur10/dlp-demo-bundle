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
resource "google_project" "demo_project_bq" {
  project_id      = "${var.demo_project_id}${var.bq_dlp_tag}${var.random_string}"
  name            = "DLP BQ Findings Export"
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
    "compute.googleapis.com",
    "iap.googleapis.com",
    "bigquery.googleapis.com",

    "datacatalog.googleapis.com",
    "dataproc.googleapis.com",
    "metastore.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudresourcemanager.googleapis.com", # findings push to SCC
    "eventarc.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "containerregistry.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
  ])

  service = each.key

  project            = google_project.demo_project_bq.project_id
  disable_on_destroy = true
  disable_dependent_services = true
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service" {
  depends_on = [google_project_service.dlp_api_service]
  create_duration = "100s"
  destroy_duration = "100s"
}


#Create the service Account
resource "google_service_account" "def_ser_acc" {
   project = google_project.demo_project_bq.project_id
   account_id   = "appengine-service-account"
   display_name = "AppEngine Service Account"
 }


  # Add required roles to the service accounts for eventrac
  resource "google_project_iam_member" "eventarc_receiver" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/eventarc.eventReceiver"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }


  # Add required roles to the service accounts for eventrac agent
  resource "google_project_iam_member" "eventarc_agent" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/eventarc.serviceAgent"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

   # Add required roles to the service accounts for eventrac
  resource "google_project_iam_member" "eventarc_admin" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/eventarc.admin"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

  # Add required roles to the service accounts
  resource "google_project_iam_member" "service_dlp_admin" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/dlp.admin"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }


# Add required roles to the service accounts for data catalog
  resource "google_project_iam_member" "data_catalog_owner" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/datacatalog.tagTemplateOwner"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

  # Add required roles to the service accounts for data catalog
  resource "google_project_iam_member" "secuity_c_admin" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/securitycenter.admin"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

  # Add required roles to the service accounts for data catalog
  resource "google_project_iam_member" "dlp_jon_editor" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/dlp.jobsEditor"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

# Add required roles to the service accounts 
  resource "google_project_iam_member" "func_invoker" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/cloudfunctions.invoker"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }


# Add required roles to the service accounts 
  resource "google_project_iam_member" "run_invoker" {
   project = google_project.demo_project_bq.project_id
   role    = "roles/run.invoker"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }



## BigQuery DataSet
#Creating  storage bucket
resource "google_storage_bucket" "bq_storage_bucket_name" {
  name          = "bq-upload-${var.bq_dlp_tag}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_bq.project_id
  uniform_bucket_level_access = true
  depends_on              = [time_sleep.wait_enable_service]
}

# Add a sample file to the storage bucket
resource "google_storage_bucket_object" "clear_data_file" {
  name   = "clear-data"
  bucket = google_storage_bucket.bq_storage_bucket_name.name
  source = "sample_data/bqtestdata.csv"
  depends_on              = [google_storage_bucket.bq_storage_bucket_name]
}



# Create dataset in bigquery
resource "google_bigquery_dataset" "clear_dataset" {
  dataset_id = "clear_dataset_${var.random_string}"
  location   = var.network_region
  project       = google_project.demo_project_bq.project_id
  depends_on              = [time_sleep.wait_enable_service]
}





# Create table in bigquery
resource "google_bigquery_table" "clear_table" {
  dataset_id          = google_bigquery_dataset.clear_dataset.dataset_id
  project             = google_project.demo_project_bq.project_id
  table_id            = "clear-data"
  description         = "This table contain clear text sensitive data"
  deletion_protection = false
  depends_on              = [google_bigquery_dataset.clear_dataset]
}








# Creates zip file of function code & requirments.txt
data "archive_file" "source_bq" {
    type        = "zip"
    source_dir  = "${path.module}/application"
    output_path = "${path.module}/dlp-bq-function.zip"
    depends_on = [time_sleep.wait_enable_service]
}

#Creating the bucket for python source code
resource "google_storage_bucket" "application_bq" {
  name     = "application-bq-${var.demo_project_id}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_bq.project_id
  uniform_bucket_level_access = true
  depends_on = [data.archive_file.source_bq]
}

# Add zip file to the Cloud Function's source code bucket
resource "google_storage_bucket_object" "python_code_bq" {
  name   = "dlpfunction.zip"
  bucket = google_storage_bucket.application_bq.name
  source = "${path.module}/dlp-bq-function.zip"
  depends_on = [google_storage_bucket.application_bq]
}

resource "google_pubsub_topic" "pubsub_topic_bq" {
  name = "bq-${var.pubsub_topic_name}"
  project = google_project.demo_project_bq.project_id
  depends_on = [time_sleep.wait_enable_service]
  }

resource "google_pubsub_subscription" "pubsub_subscription_bq" {
  name  = "bq-${var.pubsub_subscription_name}"
  project = google_project.demo_project_bq.project_id
  topic = google_pubsub_topic.pubsub_topic_bq.name
  depends_on = [google_pubsub_topic.pubsub_topic_bq]
}


resource "time_sleep" "wait_eventrac_srv_agent" {
  depends_on = [
    google_project_iam_member.eventarc_agent,
    ]
  create_duration = "16m"
  destroy_duration = "7m"
}


/*
resource "google_eventarc_trigger" "event_job_complete" {
    name = "event-trigger"
    location = var.network_region
    matching_criteria {
      attribute = "serviceName"
      value = "bigquery.googleapis.com"
    }
    matching_criteria {
      attribute = "methodName"
      value = "jobservice.jobcompleted"
    }
    matching_criteria {
      attribute = "resourceName"
      value = "projects/${google_project.demo_project_bq.project_id}/jobs/job_import_${var.random_string}" # Path pattern selects all 
      operator = "match-path-pattern" # This allows path patterns to be used in the value field
    }
    
    destination {
        cloud_function {
            service = ggoogle_cloudfunctions2_function.create_DLP_job_bq.name
            region = var.network_region
        }
    }
    depends_on = [
    time_sleep.wait_eventrac_srv_agent,
    ]
}
*/




# Create the DLP Functions
resource "google_cloudfunctions2_function" "create_DLP_job_bq" {
  name        = "create-dlp-job-bq"
  description = "Create BigQuery DLP Job"
  project     = google_project.demo_project_bq.project_id
  location      = var.network_region
  
 build_config {
    runtime     = "python310"
    entry_point = "inspect_bigquery" # Set the entry point in the code
    environment_variables = {
    PROJ_ID      = google_project.demo_project_bq.project_id
    DATASET_ID    = google_bigquery_dataset.clear_dataset.dataset_id
    TABLE_ID  = google_bigquery_table.clear_table.table_id
    PB_SB_TOP    = "bq-${var.pubsub_topic_name}"
    SUB_ID = "bq-${var.pubsub_subscription_name}"
    }
    
    source {
      storage_source {
        bucket = google_storage_bucket.application_bq.name
        object = google_storage_bucket_object.python_code_bq.name
      }
    }
  }

service_config {
    max_instance_count  = 3
    min_instance_count = 1
    available_memory    = "1024M"
    timeout_seconds     = 60
    environment_variables = {
    PROJ_ID      = google_project.demo_project_bq.project_id
    DATASET_ID    = google_bigquery_dataset.clear_dataset.dataset_id
    TABLE_ID  = google_bigquery_table.clear_table.table_id
    PB_SB_TOP    = "bq-${var.pubsub_topic_name}"
    SUB_ID = "bq-${var.pubsub_subscription_name}"
    }
    ingress_settings = "ALLOW_INTERNAL_AND_GCLB"
    all_traffic_on_latest_revision = true
    service_account_email = "${google_service_account.def_ser_acc.email}"
  }

  event_trigger {
    trigger_region = var.network_region # The trigger must be in the same location as the bucket
    event_type = "google.cloud.audit.log.v1.written"
    retry_policy = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = "${google_service_account.def_ser_acc.email}"
    event_filters {
      attribute = "serviceName"
      value = "bigquery.googleapis.com"
    }
    event_filters {
      attribute = "methodName"
      value = "jobservice.jobcompleted"
    }
    
    event_filters {
      attribute = "resourceName"
      value = "projects/${google_project.demo_project_bq.project_id}/jobs/job_import_${var.random_string}" # Path pattern selects all 
    }
  } 

  depends_on = [
    time_sleep.wait_eventrac_srv_agent,
    ]


}


resource "time_sleep" "wait_bq_job" {
  depends_on = [google_cloudfunctions2_function.create_DLP_job_bq]
  create_duration = "15s"
}




# Import data in the BigQuery table 
resource "google_bigquery_job" "import_job_bq" {
    project             = google_project.demo_project_bq.project_id
  job_id   = "job_import_${var.random_string}"
  location = var.network_region

  labels = {
    "my_job" = "load"
  }

  load {
    source_uris = [
      "gs://${google_storage_bucket.bq_storage_bucket_name.name}/${google_storage_bucket_object.clear_data_file.name}",
    ]

    destination_table {
      project_id = google_bigquery_table.clear_table.project
      dataset_id = google_bigquery_table.clear_table.dataset_id
      table_id   = google_bigquery_table.clear_table.table_id
    }
    skip_leading_rows = 0
    autodetect        = true

  }
    depends_on = [time_sleep.wait_bq_job]
 }



/*




*/

