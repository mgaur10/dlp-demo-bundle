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



organization_id = "XXXXXXXXX"
billing_account = "XXXXXX-XXXXX-XXXXXXX"
folder_name     = "DLP Demo Bundle "
demo_project_id = "dlp-demo-"



network_region   = "us-central1"
vpc_network_name = "dlp-network"
network_zone     = "us-central1-b"


crypto_key_name = "udf_key"
keyring_name    = "dlp_key_ring"
vmode           = "mode"
vaction         = "decryption"

pubsub_topic_name        = "dlp-demo-pubsub"
pubsub_subscription_name = "dlp-demo-pubsub-topic"

