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

variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "acm_repo_location" {
  description = "The location of the git repo ACM will sync to"
}
variable "acm_branch" {
  description = "The git branch ACM will sync to"
}
variable "acm_dir" {
  description = "The directory in git ACM will sync to"
}

variable "dev_dir" {
  description = "The directory in git Dev ACM will sync to"
}
variable "stage_dir" {
  description = "The directory in git Stage ACM will sync to"
}
variable "prod_dir" {
  description = "The directory in git Prod ACM will sync to"
}