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

output "development__cluster-service-account" {
  value       = module.delivery-platform-dev.service_account
  description = "Service account used to create the cluster and node pool(s)"
}

output "staging__cluster-service-account" {
  value       = module.delivery-platform-staging.service_account
  description = "Service account used to create the cluster and node pool(s)"
}

output "dev_name" { value = module.delivery-platform-dev.name }
output "dev_location" { value = module.delivery-platform-dev.location }
output "dev_endpoint" {
  value     = module.delivery-platform-dev.endpoint
  sensitive = true
}

output "stage_name" { value = module.delivery-platform-staging.name }
output "stage_location" { value = module.delivery-platform-staging.location }
output "stage_endpoint" {
  value     = module.delivery-platform-staging.endpoint
  sensitive = true
}

output "prod_name" { value = module.delivery-platform-prod.name }
output "prod_location" { value = module.delivery-platform-prod.location }
output "prod_endpoint" {
  value     = module.delivery-platform-prod.endpoint
  sensitive = true
}
