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

locals {
  cluster_type = "regional"
}

provider "google" {
  project = var.project_id
}

data "google_compute_network" "delivery-platform" {
  name = "delivery-platform"
}

data "google_compute_subnetwork" "delivery-platform-west1" {
  name   = "delivery-platform-west1"
  region = "us-west1"
}

data "google_compute_subnetwork" "delivery-platform-west2" {
  name   = "delivery-platform-west2"
  region = "us-west2"
}

data "google_compute_subnetwork" "delivery-platform-central1" {
  name   = "delivery-platform-central1"
  region = "us-central1"
}

module "delivery-platform-dev" {
  source            = "./modules/platform-cluster"
  project_id        = var.project_id
  name              = "dev"
  region            = "us-west1"
  network           = data.google_compute_network.delivery-platform.name
  subnetwork        = data.google_compute_subnetwork.delivery-platform-west1.name
  ip_range_pods     = "delivery-platform-pods-dev"
  ip_range_services = "delivery-platform-services-dev"
  release_channel   = "STABLE"
  zones             = ["us-west1-a"]
}

module "delivery-platform-staging" {
  source            = "./modules/platform-cluster"
  project_id        = var.project_id
  name              = "stage"
  region            = "us-west2"
  network           = data.google_compute_network.delivery-platform.name
  subnetwork        = data.google_compute_subnetwork.delivery-platform-west2.name
  ip_range_pods     = "delivery-platform-pods-staging"
  ip_range_services = "delivery-platform-services-staging"
  release_channel   = "STABLE"
  zones             = ["us-west2-a"]
}

module "delivery-platform-prod" {
  source            = "./modules/platform-cluster"
  project_id        = var.project_id
  name              = "prod"
  region            = "us-central1"
  network           = data.google_compute_network.delivery-platform.name
  subnetwork        = data.google_compute_subnetwork.delivery-platform-central1.name
  ip_range_pods     = "delivery-platform-pods-prod"
  ip_range_services = "delivery-platform-services-prod"
  release_channel   = "STABLE"
  zones             = ["us-central1-a"]
}

