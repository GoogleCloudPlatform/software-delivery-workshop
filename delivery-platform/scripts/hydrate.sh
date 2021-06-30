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


# inputs
#   app-name
#   target-env
#   

# outputs:
#   ${WORK_DIR}/${APP_NAME}-hydrated/${TARGET_ENV}/resources.yaml

APP_NAME=${1:-"my-app"} 
TARGET_ENV=${2:-"dev"} 


cd $WORK_DIR
git clone -b main $GIT_BASE_URL/${APP_NAME}
git clone -b main $GIT_BASE_URL/${SHARED_KUSTOMIZE_REPO} kustomize-base

### Hydrate
cd ${WORK_DIR}/${APP_NAME}/k8s/${TARGET_ENV}
## use Git Commit sha
COMMIT_SHA=$(git rev-parse --short HEAD)
kustomize edit set image app=${IMAGE_REPO}/${APP_NAME}:${COMMIT_SHA}
IMAGE_ID=${COMMIT_SHA}

## -OR-     use image sha
##docker build --tag ${IMAGE_REPO}/${APP_NAME}:${COMMIT_SHA} .
##docker push ${IMAGE_REPO}/${APP_NAME}:${COMMIT_SHA}
##IMAGE_SHA=$(gcloud container images describe ${IMAGE_REPO}/${APP_NAME}:${COMMIT_SHA} --format='value(image_summary.digest)')
#kustomize edit set image app=${IMAGE_REPO}/${APP_NAME}@${IMAGE_SHA}
#IMAGE_ID=${IMAGE_SHA}

mkdir -p ${WORK_DIR}/${APP_NAME}-hydrated/${TARGET_ENV}
kustomize build . -o ${WORK_DIR}/${APP_NAME}-hydrated/${TARGET_ENV}/resources.yaml


cd ${BASE_DIR}
rm -rf ${WORK_DIR}/${APP_NAME}
rm -rf ${WORK_DIR}/kustomize-base
rm -rf ${WORK_DIR}/${HYDRATED_CONFIG_REPO}



