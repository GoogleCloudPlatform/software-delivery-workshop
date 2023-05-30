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


###
#
# Used for app oboarding and termination.
# App creation clones the templates repo then copies the 
# desierd template folder to a temporary workspace. The script 
# then substitutes place holder values for actual values creates a 
# new remote remote and pushes the initial version. 
# Additonally if ACM is in use this script adds appropriate namespace
# configurations to ensure the app is managed by ACM. 
# 
# USAGE:
#   app.sh <create|delete> <app_name> <template_name>
#
###


create () {
    APP_NAME=${1:-"my-app"} 
    APP_LANG=${2:-"golang"} 


    # Ensure the git vendor script is set
    if [[ -z "$GIT_CMD" ]]; then
        echo "GIT_CMD not set - exiting" 1>&2
        exit 1
    fi
    # Ensure the git token is set
    if [[ -z "$GIT_TOKEN" ]]; then
        echo "GIT_TOKEN not set - exiting" 1>&2
        exit 1
    fi
    

    printf 'Creating application: %s \n' $APP_NAME

    # Create an instance of the template.
    rm -rf $WORK_DIR/app-templates
    cd $WORK_DIR/
    git clone -b main $GIT_BASE_URL/$APP_TEMPLATES_REPO app-templates
    rm -rf app-templates/.git
    cd app-templates/${APP_LANG}

    ## Insert name of new app
    for template in $(find . -name '*.tmpl'); do envsubst < ${template} > ${template%.*}; done

   
    ## Create and push to new repo
    git init
    git checkout -b main
    git symbolic-ref HEAD refs/heads/main
    $BASE_DIR/scripts/git/${GIT_CMD} create ${APP_NAME}
    git remote add origin $GIT_BASE_URL/${APP_NAME}
    git add . && git commit -m "initial commit" 
    git push origin main
    # Auth fails intermittetly on the very first client call for some reason
    #   Adding a retry to ensure the source is pushed. 
    git push origin main
    

    # Configure Pipeline 
    create_cloudbuild_trigger ${APP_NAME}
    
    # Initial deploy
    cd $WORK_DIR/app-templates/${APP_LANG}
    git pull origin main
    echo "v1" > version.txt
    git add . && git commit -m "v1" 
    git push origin main
    sleep 10
    git pull origin main
    git tag v1
    git push origin v1

    # Cleanup
    cd $BASE_DIR
    rm -rf $WORK_DIR/app-templates
}



delete () {
   echo 'Destroy Application'
   APP_NAME=${1:-"my-app"} 

   $BASE_DIR/scripts/git/${GIT_CMD} delete $APP_NAME 

   # Remove any orphaned hydrated directories from other processes 
   rm -rf $WORK_DIR/$APP_NAME-hydrated
   

    #Also delete CD pipelines. Pipelines are in us-central1
    gcloud alpha deploy delivery-pipelines delete ${APP_NAME} --region="us-central1" --force -q || true


    # Delete secret
    SECRET_NAME=${APP_NAME}-webhook-trigger-cd-secret
    gcloud secrets delete ${SECRET_NAME} -q
  

    # Delete trigger
    TRIGGER_NAME=${APP_NAME}-clouddeploy-webhook-trigger
    gcloud alpha builds triggers delete ${TRIGGER_NAME} -q

}


create_cloudbuild_trigger () {
    APP_NAME=${1:-"my-app"}
    ## Project variables
    if [[ ${PROJECT_ID} == "" ]]; then
        echo "PROJECT_ID env variable is not set"
        exit -1
    fi
    if [[ ${PROJECT_NUMBER} == "" ]]; then
        echo "PROJECT_NUMBER env variable is not set"
        exit -1
    fi

    ## API Key
    if [[ ${APP_LANG} == "" ]]; then
        echo "APP_LANG env variable is not set"
        exit -1
    fi

    ## API Key
    if [[ ${API_KEY_VALUE} == "" ]]; then
        echo "API_KEY_VALUE env variable is not set"
        exit -1
    fi


    ## Create Secret
    SECRET_NAME=${APP_NAME}-webhook-trigger-cd-secret
    SECRET_VALUE=$(sed "s/[^a-zA-Z0-9]//g" <<< $(openssl rand -base64 15))
    SECRET_PATH=projects/${PROJECT_NUMBER}/secrets/${SECRET_NAME}/versions/1
    printf ${SECRET_VALUE} | gcloud secrets create ${SECRET_NAME} --data-file=-
    gcloud secrets add-iam-policy-binding ${SECRET_NAME} \
        --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com \
        --role='roles/secretmanager.secretAccessor'

    ## Create CloudBuild Webhook Endpoint
    REPO_LOCATION=https://github.com/${GIT_USERNAME}/${APP_NAME}

    TRIGGER_NAME=${APP_NAME}-clouddeploy-webhook-trigger
    BUILD_YAML_PATH=$WORK_DIR/app-templates/${APP_LANG}/build/cloudbuild-build-only.yaml

    ## Setup Trigger & Webhook
    gcloud alpha builds triggers create webhook \
        --name=${TRIGGER_NAME} \
        --substitutions='_APP_NAME='${APP_NAME}',_APP_REPO=$(body.repository.git_url),_CONFIG_REPO='${GIT_BASE_URL}'/'${CLUSTER_CONFIG_REPO}',_DEFAULT_IMAGE_REPO='${IMAGE_REPO}',_KUSTOMIZE_REPO='${GIT_BASE_URL}'/'${SHARED_KUSTOMIZE_REPO}',_REF=$(body.ref)' \
        --inline-config=$BUILD_YAML_PATH \
        --secret=${SECRET_PATH}

    ## Retrieve the URL
    WEBHOOK_URL="https://cloudbuild.googleapis.com/v1/projects/${PROJECT_ID}/triggers/${TRIGGER_NAME}:webhook?key=${API_KEY_VALUE}&secret=${SECRET_VALUE}"

    ## Create Github Webhook
    $BASE_DIR/scripts/git/${GIT_CMD} create_webhook ${APP_NAME} $WEBHOOK_URL

}

# execute function matching first arg and pass rest of args through
$1 $2 $3 $4 $5 $6
