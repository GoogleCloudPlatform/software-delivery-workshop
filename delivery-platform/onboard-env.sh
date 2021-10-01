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

## Set Environment Variables
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
   

# Set Base directory & Working directory variables
export BASE_DIR=$PWD
export WORK_DIR=$BASE_DIR/workdir
export SCRIPTS=$BASE_DIR/scripts
mkdir -p $WORK_DIR/bin

export PATH=$PATH:$WORK_DIR/bin:$SCRIPTS:

export GIT_PROVIDER=GitHub
export GIT_CMD=gh.sh
export CONTINUOUS_DELIVERY_SYSTEM=Clouddeploy

# Load any persisted variables
source $SCRIPTS/common/manage-state.sh
load_state

# Git details
git config --global user.email $(gcloud config get-value account)
git config --global user.name ${USER}
source $SCRIPTS/git/set-git-env.sh

source $SCRIPTS/common/set-apikey-var.sh

# Repo Names
export REPO_PREFIX=mcd
export APP_TEMPLATES_REPO=$REPO_PREFIX-app-templates
export SHARED_KUSTOMIZE_REPO=$REPO_PREFIX-shared_kustomize
export CLUSTER_CONFIG_REPO=$REPO_PREFIX-cluster-config
export HYDRATED_CONFIG_REPO=${CLUSTER_CONFIG_REPO}

# Repository Name
export IMAGE_REPO=gcr.io/${PROJECT_ID}

# variable pass through for access tokens
export GIT_ASKPASS=$SCRIPTS/git/git-ask-pass.sh


# Persist variables for later use
write_state