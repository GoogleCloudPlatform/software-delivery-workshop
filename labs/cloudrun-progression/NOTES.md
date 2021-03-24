=================
TODO:
- [x] Commands for branches instead of master
- [x] Write deploy yaml & trigger json for branch
    - [X] utilize beta run command below 
    - [X] need to pass in branch name variable for tag
    - [ ] output Branch URL in build output
- [X] User: Switch to branch, make a change, push to branch
- User: Wait for build to complete
- [X] Update user command below to get branch name dynamically 
- [x] Implement the same for canary and prod
- [x] Add TAG prod to iniitial depoyment
- [x] Updated triggers to use dynamic project ID...currently hard coded
=================

# Tutorial Flow

- [X]Preparing your environment
- [X]Creating your CloudRun Service
- [X]Enabling Dynamic Developer Deployments
- [X]Automating Canary Testing
- [X]Releasing to Production

Working Doc: https://docs.google.com/document/d/1jSqtX7uLpAQD7ZqVdaU62v1Q_yUo3boJvYEalaaNf_8/edit

CloudRun Proxy: https://github.com/sethvargo/cloud-run-proxy


## Preparing your environment

```shell
git config --global user.email "[EMAIL_ADDRESS]"
git config --global user.name "[USERNAME]"

export PROJECT_ID=$(gcloud config get-value project)



cd ../
mkdir workdir && cd workdir

# Clone & remove Git
#git clone https://github.com/GoogleCloudPlatform/software-delivery-workshop 
#git clone git@github.com:cgrant/software-delivery-workshop.git -b cloudrun-progression
git clone git@github.com:cgrant/sdw-private.git -b cloudrun-progression cloudrun-progression 

cd cloudrun-progression/labs/cloudrun-progression
rm -rf ../../.git 

sed "s/PROJECT/${PROJECT_ID}/g" branch-trigger.json-tmpl > branch-trigger.json
sed "s/PROJECT/${PROJECT_ID}/g" master-trigger.json-tmpl > master-trigger.json
sed "s/PROJECT/${PROJECT_ID}/g" tag-trigger.json-tmpl > tag-trigger.json

git init && git add . && git commit -m "initial commit"

git config credential.helper gcloud.sh
gcloud source repos create cloudrun-progression
git remote add gcp https://source.developers.google.com/p/$PROJECT_ID/r/cloudrun-progression
git branch -m master
git push gcp master


gcloud builds submit --tag gcr.io/$PROJECT_ID/hello-cloudrun
gcloud beta run deploy hello-cloudrun \
    --image gcr.io/$PROJECT_ID/hello-cloudrun \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated \
    --tag=prod

open https://pantheon.corp.google.com/run/detail/us-central1/hello-cloudrun/revisions
```


## Enable Dynamic Developer Deployments
Trigger on any branch name

```shell
gcloud beta builds triggers create cloud-source-repositories --trigger-config branch-trigger.json

open https://pantheon.corp.google.com/cloud-build/triggers

git checkout -b foo
touch FOOBAR.md
git add . && git commit -m "updated" && git push gcp foo

open https://pantheon.corp.google.com/cloud-build/builds
open https://pantheon.corp.google.com/run/detail/us-central1/hello-cloudrun/revisions

#Get the URL of the service
BRANCH_URL=$(gcloud run services describe hello-cloudrun --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"foo\")|.url")
echo $BRANCH_URL
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BRANCH_URL

```

## Automate Canary Testing
```
gcloud beta builds triggers create cloud-source-repositories --trigger-config master-trigger.json

open https://pantheon.corp.google.com/cloud-build/triggers

git checkout master
git merge foo
git add . && git commit -m "merge foo"
git push gcp master

open https://pantheon.corp.google.com/cloud-build/builds
open https://pantheon.corp.google.com/run/detail/us-central1/hello-cloudrun/revisions
```


## Release to Production
```
gcloud beta builds triggers create cloud-source-repositories --trigger-config tag-trigger.json

open https://pantheon.corp.google.com/cloud-build/triggers

git tag 1.0 && git push gcp 1.0

open https://pantheon.corp.google.com/cloud-build/builds
open https://pantheon.corp.google.com/run/detail/us-central1/hello-cloudrun/revisions
```















---
Git Triggers

- GITHUB REPO
- Deploying your service with a build trigger (master)
- Creating tokens and configurations
    - Create a GitHub token to allow writing back to a pull request
- new file cloudbuild-preview.yaml
- Create Preview Trigger

My Flow

- Create a Git repository for your source code
- Deploying your service with a build trigger (tag)
- Canary Deploy from master
- Implement feature branch based dev deployments
- Utilize canary deployments to test production traffic
- Finalize production deployments from git tags



# On FR branch or PR
Build & deploy no traffic 
commit service name back to repo

- Delete Trigger??

# On Master 
Build & Deploy Preview
tag with git hash

...todo


# On TAG Build Deploy & Test Canary @ 10%
- Deploy Canary

gcloud beta run deploy hello --image us-docker.pkg.dev/cloudrun/container/hello --platform managed --tag=canary

gcloud run deploy ${_SERVICE_NAME} \
            --platform managed \
            --region ${_REGION} \
            --allow-unauthenticated \
            --image gcr.io/${PROJECT_ID}/${_SERVICE_NAME} \
            --tag=canary,sha$SHORT_SHA \
            --no-traffic
            --update-tags=[$SHORT_SHA=$$CANARY]

- Update Tags
```shell
    gcloud beta run services update-traffic hello --update-tags prod=hello-00001-jub 
    gcloud beta run services update-traffic hello --update-tags canary=hello-00001-jub
```


# Health check

```shell
# Simple URL
export URL=https://googlffe.com
# Revision  URL
export URL=$(gcloud run services describe hello --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"canary\")|.url ")
# Revision URL with path
export URL=$(gcloud run services describe hello --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"canary\")|.url ")/healthz

# Let the canary take traffic for 5 min
sleep 300

# Check Health Status
SECONDS=15
timeout -s TERM ${SECONDS} bash -c \
    'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}''  ${URL})" != "200" ]];\
    do sleep 2;\
    done' ${1} || false
```



# Canary to live