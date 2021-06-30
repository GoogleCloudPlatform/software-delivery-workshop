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


# Prerequisites

    source ${BASE_DIR}/scripts/git/set-git-env.sh

    ## Prepare CloudBuild

    ### Enable APIS
    # TODO trim this down... one of these is needed to create the compute service account
    gcloud services enable \
        cloudresourcemanager.googleapis.com \
        container.googleapis.com \
        sourcerepo.googleapis.com \
        cloudbuild.googleapis.com \
        containerregistry.googleapis.com \
        anthosconfigmanagement.googleapis.com \
        run.googleapis.com \
        apikeys.googleapis.com \
        secretmanager.googleapis.com

    ### Grant the Project Editor role to the Cloud Build service account in order to provision project resources

    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
    --role=roles/owner

    ### Grant the IAM Service Account User role to the Cloud Build service account for the Cloud Run runtime service account:

    gcloud iam service-accounts add-iam-policy-binding \
        $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
        --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
        --role=roles/iam.serviceAccountUser

    ### Grant the Storage Object Viewer role to the default Compute service account in order to read GCR.io images

    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role=roles/storage.objectViewer

    ### Create the base image used for provisioning
    cd ${BASE_DIR}/resources/provision/base_image
    gcloud builds submit --tag gcr.io/$PROJECT_ID/delivery-platform-installer
    cd $BASE_DIR

    ### Create GIT secret
    printf ${GIT_TOKEN} | gcloud secrets create gh_token --data-file=-


# Create Template Repos
cd ${BASE_DIR}/resources/provision/repos
./create-template-repos.sh
cd $BASE_DIR 

# Create Config Repos
cd ${BASE_DIR}/resources/provision/repos
./create-config-repo.sh
cd $BASE_DIR

# Provision network and foundational elements
cd ${BASE_DIR}/resources/provision/foundation/tf
gcloud builds submit
cd $BASE_DIR

# Provision the clusters
cd ${BASE_DIR}/resources/provision/clusters/tf
gcloud builds submit
cd $BASE_DIR

# Install ACM 
cd ${BASE_DIR}/resources/provision/management-tools/acm
./acm-install.sh
cd $BASE_DIR

# Install Tekton 
cd ${BASE_DIR}/resources/provision/management-tools
./tekton-install.sh
cd $BASE_DIR

# Install Argo 
cd ${BASE_DIR}/resources/provision/management-tools
./argo-install.sh
cd $BASE_DIR
