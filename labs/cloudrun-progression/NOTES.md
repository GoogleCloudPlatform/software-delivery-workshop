
# Tutorial Flow

- Create your CloudRun Service
- Enable Dynamic Developer Deployments
- Automate Canary Testing
- Release to Production

Working Doc: https://docs.google.com/document/d/1jSqtX7uLpAQD7ZqVdaU62v1Q_yUo3boJvYEalaaNf_8/edit

CloudRun Proxy: https://github.com/sethvargo/cloud-run-proxy

# Notes

## Setup
git config --global user.email "[EMAIL_ADDRESS]"
git config --global user.name "[USERNAME]"

PROJECT_ID=$(gcloud config get-value project)

## Create your CloudRun Service
What are we going to deploy?



Do Some git stuff
```shell

# Clone & remove Git
#git clone https://github.com/GoogleCloudPlatform/cicd-workshop 
git clone git@github.com:cgrant/cicd-workshop.git -b cloudrun-progression 
cd cicd-workshop && 
cd labs/cloudrun-progression
git init && git add . && git commit -m "initial commit"
#cd cloud-run-helloworld-python/

git config credential.helper gcloud.sh
gcloud source repos create cloudrun-progression
git remote add gcp https://source.developers.google.com/p/$PROJECT_ID/r/cloudrun-progression
git branch -m master
git push gcp master
```

Build & Deploy

```shell

gcloud builds submit --tag gcr.io/$PROJECT_ID/hello-cloudrun
gcloud run deploy hello-cloudrun \
    --image gcr.io/$PROJECT_ID/hello-cloudrun \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated 


```


## Enable Dynamic Developer Deployments

- Trigger on branch name

gcloud beta builds triggers create cloud-source-repositories --trigger-config trigger.json



=================
TODO:
- Update above command for branches instead of master
- Write deploy yaml & trigger json for branch
    - utilize beta run command below 
    - need to pass in branch name variable for tag
    - output Branch URL in build output
- User: Switch to branch, make a change, push to branch
- User: Wait for build to complete
- Update user command below to get branch name dynamically 
- Implement the same for canary and prod


- Deploy to label
```
gcloud beta run deploy helloworld \
    --image gcr.io/$PROJECT_ID/helloworld \
    --region us-central1 \
    --no-traffic \
    --tag=branchanme
```

Get the URL of the service
BRANCH_URL=$(gcloud run services describe helloworld --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"branchanme\")|.url")
echo $BRANCH_URL
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BRANCH_URL



## Automate Canary Testing
## Release to Production







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

- Get current "canary" revision
```shell
    CANARY=$(gcloud run services describe hello --format=json | jq --raw-output ".spec.traffic[] | select (.tag==\"canary\")|.revisionName")
```

- Get current "prod" revision
```shell
    PROD=$(gcloud run services describe hello --format=json | jq --raw-output ".spec.traffic[] | select (.tag==\"prod\")|.revisionName")
```
- update traffic
```shell
    gcloud run services update-traffic hello --to-revisions=$PROD=90,$CANARY=10
```

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