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
resource "google_project" "demo_project_dlp_api" {
  project_id      = "${var.demo_project_id}${var.api_dlp_tag}${var.random_string}"
  name            = "DLP API Calls"
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
  ])

  service = each.key

  project            = google_project.demo_project_dlp_api.project_id
  disable_on_destroy = true
  disable_dependent_services = true
}


# Wait delay after enabling APIs
resource "time_sleep" "wait_enable_service" {
  depends_on = [google_project_service.dlp_api_service]
  create_duration = "45s"
  destroy_duration = "45s"
}



# Create the DLP network
resource "google_compute_network" "dlp_network" {
    project                 = google_project.demo_project_dlp_api.project_id
    name                    = var.vpc_network_name
    auto_create_subnetworks = false
    description             = "DLP network"
    depends_on              = [time_sleep.wait_enable_service]
}

# Create DLP Subnetwork

resource "google_compute_subnetwork" "dlp_subnetwork" {
    name          = "dlp-network-${var.network_region}"
    ip_cidr_range = "192.168.0.0/16"
    region        = var.network_region
    project       = google_project.demo_project_dlp_api.project_id
    network       = google_compute_network.dlp_network.self_link
    # Enabling VPC flow logs
    log_config {
        aggregation_interval = "INTERVAL_10_MIN"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
  }
    private_ip_google_access = true 
    depends_on               = [
        google_compute_network.dlp_network,
        ]
}


#Create the service Account
resource "google_service_account" "def_ser_acc" {
   project = google_project.demo_project_dlp_api.project_id
   account_id   = "appengine-service-account"
   display_name = "AppEngine Service Account"
 }


# Add required roles to the service accounts
  resource "google_project_iam_member" "service_dlp_admin" {
   project = google_project.demo_project_dlp_api.project_id
   role    = "roles/dlp.admin"
   member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
   depends_on = [google_service_account.def_ser_acc]
  }

  resource "google_project_iam_member" "ser_agent" {
    project = google_project.demo_project_dlp_api.project_id
    role    = "roles/dlp.serviceAgent"
    member  = "serviceAccount:${google_service_account.def_ser_acc.email}"
    depends_on = [google_service_account.def_ser_acc]
  }


resource "google_compute_firewall" "allow_iap_proxy" {
name = "allow-iap-proxy"
network = google_compute_network.dlp_network.self_link
project = google_project.demo_project_dlp_api.project_id
direction = "INGRESS"
allow {
    protocol = "tcp"
    ports    = ["22"]
    }
source_ranges = ["35.235.240.0/20"]
# Use this soruce range if testing in cloud shell ["35.235.240.0/20"] otherwise use ["0.0.0.0/0"]
target_service_accounts = [
    google_service_account.def_ser_acc.email
  ]
    depends_on = [
        google_compute_network.dlp_network
    ]
}


# Create a CloudRouter
resource "google_compute_router" "router" {
  project = google_project.demo_project_dlp_api.project_id
  name    = "subnet-router"
  region  = google_compute_subnetwork.dlp_subnetwork.region
  network = google_compute_network.dlp_network.id

  bgp {
    asn = 64514
  }
}



# Configure a CloudNAT
resource "google_compute_router_nat" "nats" {
  project = google_project.demo_project_dlp_api.project_id
  name                               = "nat-cloud-dlp-${var.vpc_network_name}"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  depends_on = [google_compute_router.router]
}


# Create Proxy Server Instance (debian)
resource "google_compute_instance" "dlp_demo_server" {
    project      = google_project.demo_project_dlp_api.project_id
    name         = "dlp-demo-server"
    machine_type = "f1-micro"
    zone         = var.network_zone

    shielded_instance_config {
        enable_integrity_monitoring = true
        enable_secure_boot          = true
        enable_vtpm                 = true
    }

  depends_on = [
    time_sleep.wait_enable_service,
    google_compute_router_nat.nats,
    ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
 }

  network_interface {
    network         = google_compute_network.dlp_network.self_link
    subnetwork      = google_compute_subnetwork.dlp_subnetwork.self_link
   
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email                       = google_service_account.def_ser_acc.email
    
    scopes                      = ["cloud-platform"]
  }
    metadata_startup_script     = "sudo apt-get update -y;sudo apt-get install git -y;sudo apt-get install npm -y;sudo git clone https://github.com/googleapis/nodejs-dlp.git /tmp/nodejs-dlp/;cd /tmp/nodejs-dlp/samples;sudo npm install @google-cloud/dlp -y;sudo npm install yargs -y;npm install mime;"

    labels =   {
        asset_type = "prod"
        osshortname = "debian"  
        }
}

