# docker-go-sample


A simple hello world application to use in deployment demos


Docker Image Build

```
    $ docker build . -t temp/hello-go
    $ docker run -d --rm -p 8080:80 temp/hello-go
    $ open http://localhost:8080

```


Cleanup

```
    $ docker stop $(docker ps -a -q -f "ancestor=temp/hello-go")
    $ docker rmi temp/hello-go
```

---

# GKE



## Set Variables

```
 
    export PROJECT=[[YOUR PROJECT NAME]]
    # On Cloudshell
    # export PROJECT=$(gcloud info --format='value(config.project)')
    export CLUSTER=gke-deploy-example-cluster
    export ZONE=us-central1-a

    gcloud config set compute/zone $ZONE

```
## Create Cluster

```

    gcloud container clusters create ${CLUSTER} \
    --project=${PROJECT} \
    --zone=${ZONE} \
    --quiet

```


## Get Credentials

```
    gcloud container clusters get-credentials ${CLUSTER} \
    --project=${PROJECT} \
    --zone=${ZONE}

```

# Cloud Builder


## Local Cloud Builder

Install the local builder
```
gcloud components install container-builder-local
```

Build locally
```


container-builder-local --config cloudbuild-cli.yaml \
    --dryrun=false  \
    --write-workspace=build_assets  \
    --substitutions=_CLOUDSDK_COMPUTE_ZONE=${ZONE},_CLOUDSDK_CONTAINER_CLUSTER=${CLUSTER},_TAG_NAME=18 \
    .
```



## Build in the cloud


For `kubectl` commands against GKE youll need to give Container Builder Service Account container.developer role access on your clusters [details](https://github.com/GoogleCloudPlatform/cloud-builders/tree/master/kubectl).

```
PROJECT_NUMBER="$(gcloud projects describe \
    $(gcloud config get-value core/project -q) --format='get(projectNumber)')"

gcloud projects add-iam-policy-binding ${PROJECT} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer

```


### Cloud Build & Deploy of local content

The following submits a build to cloud builder and deploys the results to a user's namespace.

```
gcloud container builds submit \
    --config cloudbuild-local.yaml \
    --substitutions=_VERSION=someversion,_USER=$(whoami),_CLOUDSDK_COMPUTE_ZONE=${ZONE},_CLOUDSDK_CONTAINER_CLUSTER=${CLUSTER} .


```

Deploy to GKE from a Github Push



Setup Triggers

gcloud auth application-default login








Trigger setup instructions: https://cloud.google.com/container-builder/docs/running-builds/automate-builds


Container registry page
https://console.cloud.google.com/gcr?_ga=2.177339745.-595360065.1522415212
Select your project and click Open.
In the left nav, click Build triggers.
Click Create trigger.
Select Github
Select select the repository, then click Continue.

Enter the following trigger settings:
- Trigger Name: An optional name for your trigger.
- Trigger Type: Branch (You can setup Tag separatly later)

Build configuration select cloudbuild.yaml
- Enter cloudbuild.yaml for the value

Substitution variables
- Click add item and input
    - Variable: _CLOUDSDK_COMPUTE_ZONE  
    - Value: us-central1-a (or whatever zone you used above)
- Click add item again and input
    - Variable: _CLOUDSDK_CONTAINER_CLUSTER
    - Value: gke-deploy-example-cluster

Click Create Trigger

Test it: To the right of the entry you just created click Run Trigger, and select Master
View progress on the Builds Page: https://console.cloud.google.com/gcr/builds






---
### Notes

gcloud config unset container/use_client_certificate
gcloud container clusters get-credentials ${CLUSTER}     --project=${PROJECT}     --zone=${ZONE}
