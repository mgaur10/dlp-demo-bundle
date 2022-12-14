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

provider "google" {
}

provider "google" {
  alias                       = "service"
  impersonate_service_account = google_service_account.def_ser_acc.email
  region                      = var.network_region
}


/*

terraform {
  required_providers {
    google = {
      version = "=4.16.0"
    }
    google-beta = {
      version = "=4.16.0"
    }
  }
}


*/