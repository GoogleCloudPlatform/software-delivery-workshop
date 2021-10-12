# End To End 



## Source

git clone https://github.com/GoogleCloudPlatform/software-delivery-workshop.git 


## Workspace

cd software-delivery-workshop && rm -rf .git
cd delivery-platform && cloudshell workspace .



## Set gcloud defaults

gcloud config set project {{project-id}}

gcloud config set deploy/region us-central1

## APIs

gcloud services enable \
    container.googleapis.com \
    cloudbuild.googleapis.com \
    clouddeploy.googleapis.com \
    containerregistry.googleapis.com \
    secretmanager.googleapis.com \
    cloudresourcemanager.googleapis.com 



## Create Clusters

gcloud container clusters create stage --zone=us-central1-a  --async
gcloud container clusters create preview --zone=us-central1-b  --async
gcloud container clusters create prod --zone=us-central1-c


## Define Deploy Pipeline Targets

envsubst < demo/deploy-targets.yaml.tmpl > demo/deploy-targets.yaml;

gcloud beta deploy apply --file demo/deploy-targets.yaml

## Github Access

source ./onboard-env.sh


## Prep Github sample

./demo/create-template-repos.sh





## New App

cd $BASE_DIR
export APP_NAME=demo-app
./app.sh create ${APP_NAME}


## Get App Src

git clone ${GIT_BASE_URL}/${APP_NAME} ${WORK_DIR}/${APP_NAME}
cd ${WORK_DIR}/${APP_NAME}


## Local development


## Push