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
 
module "acm-dev" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/acm"
  version = "14.1.0"
 
  project_id       = var.project_id
  cluster_name     = data.terraform_remote_state.clusters.outputs.dev_name
  location         = data.terraform_remote_state.clusters.outputs.dev_location
  cluster_endpoint = data.terraform_remote_state.clusters.outputs.dev_endpoint

  secret_type      = "ssh"
  sync_repo        = var.acm_repo_location
  sync_branch      = var.acm_branch
  policy_dir       = var.dev_dir
}
module "acm-stage" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/acm"
  version = "14.1.0"

  project_id       = var.project_id
  cluster_name     = data.terraform_remote_state.clusters.outputs.stage_name
  location         = data.terraform_remote_state.clusters.outputs.stage_location
  cluster_endpoint = data.terraform_remote_state.clusters.outputs.stage_endpoint

  secret_type      = "ssh"
  sync_repo        = var.acm_repo_location
  sync_branch      = var.acm_branch
  policy_dir       = var.stage_dir
}
module "acm-prod" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/acm"
  version = "14.1.0"

  project_id       = var.project_id
  cluster_name     = data.terraform_remote_state.clusters.outputs.prod_name
  location         = data.terraform_remote_state.clusters.outputs.prod_location
  cluster_endpoint = data.terraform_remote_state.clusters.outputs.prod_endpoint

  secret_type      = "ssh"
  sync_repo        = var.acm_repo_location
  sync_branch      = var.acm_branch
  policy_dir       = var.prod_dir
}