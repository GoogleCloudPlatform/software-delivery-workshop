/**
 * Copyright 2021 Google LLC
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

provider "google" {
  project = var.project_id
}

resource "google_compute_network" "delivery-platform" {
  name                    = "delivery-platform"
  auto_create_subnetworks = false
  depends_on              = [module.project-services.project_id]
}

resource "google_compute_subnetwork" "delivery-platform-central1" {
  name          = "delivery-platform-central1"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.delivery-platform.self_link

  secondary_ip_range {
    range_name    = "delivery-platform-pods-prod"
    ip_cidr_range = "172.16.0.0/16"
  }
  secondary_ip_range {
    range_name    = "delivery-platform-services-prod"
    ip_cidr_range = "192.168.2.0/24"
  }
}

resource "google_compute_subnetwork" "delivery-platform-west1" {
  name          = "delivery-platform-west1"
  ip_cidr_range = "10.4.0.0/16"
  region        = "us-west1"
  network       = google_compute_network.delivery-platform.self_link

  secondary_ip_range {
    range_name    = "delivery-platform-pods-dev"
    ip_cidr_range = "172.18.0.0/16"
  }
  secondary_ip_range {
    range_name    = "delivery-platform-services-dev"
    ip_cidr_range = "192.168.4.0/24"
  }
}

resource "google_compute_subnetwork" "delivery-platform-west2" {
  name          = "delivery-platform-west2"
  ip_cidr_range = "10.5.0.0/16"
  region        = "us-west2"
  network       = google_compute_network.delivery-platform.self_link

  secondary_ip_range {
    range_name    = "delivery-platform-pods-staging"
    ip_cidr_range = "172.19.0.0/16"
  }
  secondary_ip_range {
    range_name    = "delivery-platform-services-staging"
    ip_cidr_range = "192.168.5.0/24"
  }
}
