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
resource "google_project" "demo_project_bq_udf" {
  project_id      = "${var.demo_project_id}${var.udf_dlp_tag}${var.random_string}"
  name            = "DLP Bigquery UDF"
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
    "cloudkms.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquery.googleapis.com",
  ])

  service = each.key

  project            = google_project.demo_project_bq_udf.project_id
  disable_on_destroy = true
  disable_dependent_services = true
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service" {
  depends_on = [google_project_service.dlp_api_service]
  create_duration = "100s"
  destroy_duration = "100s"
}


# Create a kms key ring and key
      resource "google_kms_key_ring" "keyring" {
    project = google_project.demo_project_bq_udf.project_id
    name     = var.keyring_name
    location = "global"
    depends_on = [time_sleep.wait_enable_service]
  } 
  
  resource "google_kms_crypto_key" "kms_key" {
    name            = var.crypto_key_name
    key_ring        = google_kms_key_ring.keyring.id
    rotation_period = "100000s"

    lifecycle {
      prevent_destroy = false
    }
    depends_on = [google_kms_key_ring.keyring]
  }  


resource "null_resource" "kms_key" {
  depends_on = [google_kms_crypto_key.kms_key]
  triggers = {
  #  dlp_template = "${google_data_loss_prevention_deidentify_template.deid_template}"
  data_set = "${google_kms_crypto_key.kms_key.name}"
  }

  provisioner "local-exec" {
     command = <<EOT
     openssl rand 32 >> ${path.module}/secret.txt;
     gcloud kms encrypt --location "global" --project ${google_project.demo_project_bq_udf.project_id} --keyring ${google_kms_key_ring.keyring.name} --key ${google_kms_crypto_key.kms_key.name} --plaintext-file ${path.module}/secret.txt --ciphertext-file ${path.module}/mysecret.txt.encrypted;
     base64 ${path.module}/mysecret.txt.encrypted >> ${path.module}/wrapped_key;
EOT
 }

 provisioner "local-exec" {
    when        = destroy
  command     = <<EOT
  rm wrapped_key
  rm mysecret.txt.encrypted
  rm secret.txt
  rm dlpfunction-udf.zip
  EOT
  working_dir = path.module
 }
 }


#Creating the bucket for wrapped key
resource "google_storage_bucket" "wrapped_key_udf" {
  name     = "wrapped-key-udf-${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_bq_udf.project_id
  uniform_bucket_level_access = true
  depends_on = [time_sleep.wait_enable_service]
}

# Add zip file to the Cloud Function's source code bucket
resource "google_storage_bucket_object" "wrapped_key_udf" {
  name   = "wrapped_key"
  bucket = google_storage_bucket.wrapped_key_udf.name
  source = "${path.module}/wrapped_key"
  depends_on = [
      google_storage_bucket.wrapped_key_udf,
      null_resource.kms_key,
      ]
}



# Creates zip file of function code & requirments.txt
data "archive_file" "udf_source" {
    type        = "zip"
    source_dir  = "${path.module}/application"
    output_path = "${path.module}/dlpfunction-udf.zip"
    depends_on = [time_sleep.wait_enable_service]
}

#Creating the bucket for python source code
resource "google_storage_bucket" "application_udf" {
  name     = "application-udf-${var.demo_project_id}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_bq_udf.project_id
  uniform_bucket_level_access = true
  depends_on = [time_sleep.wait_enable_service]
}

# Add zip file to the Cloud Function's source code bucket
resource "google_storage_bucket_object" "python_code_udf" {
  name   = "dlpfunction-udf.zip"
  bucket = google_storage_bucket.application_udf.name
  source = "${path.module}/dlpfunction-udf.zip"
  depends_on = [time_sleep.wait_enable_service]
}



resource "google_pubsub_topic" "pubsub_topic_udf" {
  name = "udf-${var.pubsub_topic_name}"
  project = google_project.demo_project_bq_udf.project_id
  }

resource "google_pubsub_subscription" "pubsub_subscription_udf" {
  name  = "udf-${var.pubsub_subscription_name}"
  project = google_project.demo_project_bq_udf.project_id
  topic = google_pubsub_topic.pubsub_topic_udf.name
  
}





## BigQuery DataSet
#Creating  storage bucket
resource "google_storage_bucket" "bq_storage_bucket_name" {
  name          = "bq-upload-${var.udf_dlp_tag}${var.random_string}"
  location      = var.network_region
  force_destroy = true
  project       = google_project.demo_project_bq_udf.project_id
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
  project       = google_project.demo_project_bq_udf.project_id
  depends_on              = [time_sleep.wait_enable_service]
  delete_contents_on_destroy = true
}





# Create table in bigquery
resource "google_bigquery_table" "clear_table" {
  dataset_id          = google_bigquery_dataset.clear_dataset.dataset_id
  project             = google_project.demo_project_bq_udf.project_id
  table_id            = "clear-data"
  description         = "This table contain clear text sensitive data"
  deletion_protection = false
  depends_on              = [google_bigquery_dataset.clear_dataset]
}




#Create the service Account
resource "google_service_account" "def_ser_acc" {
   project = google_project.demo_project_bq_udf.project_id
   account_id   = "appengine-service-account"
   display_name = "AppEngine Service Account"
 }


# Add required roles to the service accounts
  resource "google_project_iam_member" "service_dlp_admin" {
   project = google_project.demo_project_bq_udf.project_id
   role    = "roles/dlp.admin"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }


  resource "google_project_iam_member" "ser_agent" {
    project = google_project.demo_project_bq_udf.project_id
    role    = "roles/dlp.serviceAgent"
    member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
    depends_on = [google_service_account.def_ser_acc]
  }

/*
 # Add required roles to the service accounts
  resource "google_project_iam_member" "proj_editor" {
   project = google_project.demo_project_bq_udf.project_id
   role    = "roles/editor"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }
*/


# Create the DLP Functions
resource "google_cloudfunctions_function" "udf_demo" {
  name        = "UDF-Demo"
  description = "UDF-Demo"
  runtime     = "python37"
  project     = google_project.demo_project_bq_udf.project_id
  region      = var.network_region
  ingress_settings = "ALLOW_INTERNAL_AND_GCLB"
  timeout       = 540
#  max_instances = 10
#  min_instances = 1
  


  available_memory_mb   = 1024
  source_archive_bucket = google_storage_bucket.application_udf.name
  source_archive_object = google_storage_bucket_object.python_code_udf.name
   entry_point           = "remote_security"
  service_account_email = "${google_service_account.def_ser_acc.email}"
  

  trigger_http                 = true
#  https_trigger_security_level = "SECURE_ALWAYS"

  depends_on = [
      time_sleep.wait_enable_service,
      google_bigquery_table.clear_table,
      google_storage_bucket_object.wrapped_key_udf,
      google_kms_crypto_key.kms_key,
  ]

  environment_variables = {
   PROJECT_ID      = "${google_project.demo_project_bq_udf.project_id}"
   BUCKET_NAME = "${google_storage_bucket.wrapped_key_udf.name}"
   BLOB_NAME = "${google_storage_bucket_object.wrapped_key_udf.name}"
   KEY_NAME = "projects/${google_project.demo_project_bq_udf.project_id}/locations/global/keyRings/${google_kms_key_ring.keyring.name}/cryptoKeys/${google_kms_crypto_key.kms_key.name}"
   } 
}


data "google_bigquery_default_service_account" "bq_sa" {
      project = google_project.demo_project_bq_udf.project_id
      depends_on = [time_sleep.wait_enable_service]
}





resource "google_kms_crypto_key_iam_member" "key_sa_user" {
  crypto_key_id = google_kms_crypto_key.kms_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_bigquery_default_service_account.bq_sa.email}"
}




resource "google_bigquery_connection" "connection" {
   connection_id = "my-connection"
   project = google_project.demo_project_bq_udf.project_id
   location      = var.network_region
   friendly_name = "hello"
   description   = "a riveting description"
   cloud_resource {
  # service_account_id = "${google_project.demo_project_bq_udf.project_id}@gcp-sa-bigquery-condel.iam.gserviceaccount.com"
   }
   depends_on = [time_sleep.wait_enable_service]
}



# Add required roles to the service accounts 
  resource "google_project_iam_member" "run_invoker" {
   project = google_project.demo_project_bq_udf.project_id
   role    = "roles/run.invoker"
   member  = "serviceAccount:${google_bigquery_connection.connection.cloud_resource.0.service_account_id}"
   depends_on = [google_bigquery_connection.connection]
  }


# Add required roles to the service accounts 
  resource "google_project_iam_member" "func_invoker" {
   project = google_project.demo_project_bq_udf.project_id
   role    = "roles/cloudfunctions.invoker"
   member  = "serviceAccount:${google_bigquery_connection.connection.cloud_resource.0.service_account_id}"
   depends_on = [google_bigquery_connection.connection]
  }




# https://github.com/GoogleCloudPlatform/bigquery-dlp-remote-function/tree/2093dd6ef70269486ee250b5fca3e4836ba6ba92




# Import data in table 
resource "google_bigquery_job" "import_job_bq" {
    project             = google_project.demo_project_bq_udf.project_id
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
    depends_on = [google_bigquery_table.clear_table]
 
}



# BigQuery routine to call UDF
 resource "null_resource" "udf_query_deidentify" {
  depends_on = [google_cloudfunctions_function.udf_demo]
  triggers = {
  #  dlp_template = "${google_data_loss_prevention_deidentify_template.deid_template}"
  data_set = "${google_bigquery_dataset.clear_dataset.dataset_id}"
  }

 provisioner "local-exec" {
  #  interpreter = ["bq", "query", "--use_legacy_sql=false"]
   command = <<EOT
bq query --project_id "${google_project.demo_project_bq_udf.project_id}" --use_legacy_sql=false "CREATE OR REPLACE FUNCTION ${google_bigquery_dataset.clear_dataset.dataset_id}.deidentify(x STRING) RETURNS STRING
REMOTE WITH CONNECTION \`${google_project.demo_project_bq_udf.project_id}.${var.network_region}.${google_bigquery_connection.connection.connection_id}\`
OPTIONS (endpoint = '${google_cloudfunctions_function.udf_demo.https_trigger_url}', user_defined_context = [('mode', 'deidentify')]);"
   EOT
 }
 }


# BigQuery routine to call UDF
 resource "null_resource" "udf_query_reidentify" {
    depends_on = [google_cloudfunctions_function.udf_demo]
  triggers = {
  #  dlp_template = "${google_data_loss_prevention_deidentify_template.deid_template}"
  data_set = "${google_bigquery_dataset.clear_dataset.dataset_id}"
  }

 provisioner "local-exec" {
  #  interpreter = ["bq", "query", "--use_legacy_sql=false"]
   command = <<EOT
bq query --project_id "${google_project.demo_project_bq_udf.project_id}" --use_legacy_sql=false "CREATE OR REPLACE FUNCTION ${google_bigquery_dataset.clear_dataset.dataset_id}.reidentify(x STRING) RETURNS STRING
REMOTE WITH CONNECTION \`${google_project.demo_project_bq_udf.project_id}.${var.network_region}.${google_bigquery_connection.connection.connection_id}\`
OPTIONS (endpoint = '${google_cloudfunctions_function.udf_demo.https_trigger_url}', user_defined_context = [('mode', 'reidentify')]);"
   EOT
 }
 }



 # BigQuery routine to call UDF
  resource "null_resource" "udf_query_deidentify_cc" {
  depends_on = [google_cloudfunctions_function.udf_demo]
  triggers = {
  #  dlp_template = "${google_data_loss_prevention_deidentify_template.deid_template}"
  data_set = "${google_bigquery_dataset.clear_dataset.dataset_id}"
  }

 provisioner "local-exec" {
  #  interpreter = ["bq", "query", "--use_legacy_sql=false"]
   command = <<EOT
bq query --project_id "${google_project.demo_project_bq_udf.project_id}" --use_legacy_sql=false "CREATE OR REPLACE FUNCTION ${google_bigquery_dataset.clear_dataset.dataset_id}.deidentify_cc(x STRING) RETURNS STRING
REMOTE WITH CONNECTION \`${google_project.demo_project_bq_udf.project_id}.${var.network_region}.${google_bigquery_connection.connection.connection_id}\`
OPTIONS (endpoint = '${google_cloudfunctions_function.udf_demo.https_trigger_url}', user_defined_context = [('mode', 'deidentify_cc')]);"
   EOT
 }
}
