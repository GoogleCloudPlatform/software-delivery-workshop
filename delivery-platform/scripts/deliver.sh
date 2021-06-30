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
#   hydrated_repo_path

APP_NAME=${1:-"my-app"} 
TARGET_ENV=${2:-"dev"} 
HYDRATED_REPO_PATH=${3}


cd $WORK_DIR
git clone -b main $GIT_BASE_URL/${HYDRATED_CONFIG_REPO}
cd ${HYDRATED_CONFIG_REPO}
mkdir -p ${HYDRATED_REPO_PATH}
cp ${WORK_DIR}/${APP_NAME}-hydrated/${TARGET_ENV}/resources.yaml \
    ${WORK_DIR}/${HYDRATED_CONFIG_REPO}/${HYDRATED_REPO_PATH}

git add . && git commit -m "Deploying new image ${IMAGE_ID}"
git push origin main


cd ${BASE_DIR}
rm -rf ${WORK_DIR}/${HYDRATED_CONFIG_REPO}
#rm -rf ${WORK_DIR}/${APP_NAME}-hydrated
