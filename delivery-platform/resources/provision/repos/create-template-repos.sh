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


## Create sample repos
echo $GIT_BASE_URL

# Create templates repo
cp -R $BASE_DIR/resources/repos/app-templates $WORK_DIR
cd $WORK_DIR/app-templates
git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
$BASE_DIR/scripts/git/${GIT_CMD} create $APP_TEMPLATES_REPO  
sleep 5
git remote add origin $GIT_BASE_URL/$APP_TEMPLATES_REPO
git push origin main
# Auth fails intermittetly on the very first client call for some reason
    #   Adding a retry to ensure the source is pushed. 
git push origin main
cd $BASE_DIR
rm -rf $WORK_DIR/app-templates


# Create shared kustomize repo
cp -R $BASE_DIR/resources/repos/shared-kustomize $WORK_DIR
cd $WORK_DIR/shared-kustomize
git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
$BASE_DIR/scripts/git/${GIT_CMD} create $SHARED_KUSTOMIZE_REPO  
git remote add origin $GIT_BASE_URL/$SHARED_KUSTOMIZE_REPO
git push origin main
cd $BASE_DIR
rm -rf $WORK_DIR/shared-kustomize

