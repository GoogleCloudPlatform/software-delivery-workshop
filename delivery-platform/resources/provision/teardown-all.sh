#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd ${BASE_DIR}/resources/provision/clusters/tf
gcloud builds submit --config cloudbuild-destroy.yaml
cd ${BASE_DIR}

cd ${BASE_DIR}/resources/provision/foundation/tf
gcloud builds submit --config cloudbuild-destroy.yaml
cd ${BASE_DIR}

# Base Repos
cd ${BASE_DIR}/resources/provision/repos
./teardown.sh
cd ${BASE_DIR}/

# Delete git secret
gcloud secrets delete gh_token

# Delete contexts
kubectl config delete-context dev
kubectl config delete-context stage
kubectl config delete-context prod

# remove tfstate to avoid conflict with reprovision
gsutil rm gs://${PROJECT_ID}-delivery-platform-tf-state/**.tfstate
