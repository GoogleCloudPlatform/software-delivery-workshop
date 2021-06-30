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

#gsutil cp gs://config-management-release/released/latest/config-management-operator.yaml config-management-operator.yaml
gcloud builds submit \
    --substitutions=_CLUSTER_CONFIG_REPO="$GIT_BASE_URL/$CLUSTER_CONFIG_REPO",_BRANCH="main",_DEV_PATH="dev",_STAGE_PATH="stage",_PROD_PATH="prod"
