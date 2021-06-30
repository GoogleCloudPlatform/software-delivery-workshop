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

# Create config repo
cp -R $BASE_DIR/resources/repos/cluster-config $WORK_DIR
cd $WORK_DIR/cluster-config
git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
$BASE_DIR/scripts/git/${GIT_CMD} create $CLUSTER_CONFIG_REPO  
git remote add origin $GIT_BASE_URL/$CLUSTER_CONFIG_REPO
git push origin main
cd $BASE_DIR
rm -rf $WORK_DIR/cluster-config
