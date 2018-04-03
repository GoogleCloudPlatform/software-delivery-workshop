# GKE Deployments with Cloud Builder

The included scripts are intended to demonstrate how to use Google Cloud Container Builder as a continuous integration system deploying code to GKE. 

The example here follows a pattern where:
- developers use cloud servers during local development
- all lower lifecycle testing occurs on branches other than master
- merges to master indicate a readiness for a canary (beta) deployment in production
- a tagged release indicates the canary deploy is fully signed off and rolled out to all remaining servers


There are 5 scripts included as part of the demo:
- cloudbuild-local.yaml - used by developers to compile and push local code to cloud servers
- cloudbuild-dev.yaml - used to deploy any branch to branch namespaces
- cloudbuild-canary.yaml - used to deploy the master branch to canary servers
- cloudbuild-prod.yaml - used to push repo tags to remaining production servers
- cloudbuild.yaml - an all in one script that can be used for branches, master and tags with one configuration







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


## Build in the cloud


For `kubectl` commands against GKE youll need to give Container Builder Service Account container.developer role access on your clusters [details](https://github.com/GoogleCloudPlatform/cloud-builders/tree/master/kubectl).

```
PROJECT_NUMBER="$(gcloud projects describe \
    $(gcloud config get-value core/project -q) --format='get(projectNumber)')"

gcloud projects add-iam-policy-binding ${PROJECT} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer

```


### Build & Deploy of local content

The following submits a build to cloud builder and deploys the results to a user's namespace.

```
gcloud container builds submit \
    --config cloudbuild-local.yaml \
    --substitutions=_VERSION=someversion,_USER=$(whoami),_CLOUDSDK_COMPUTE_ZONE=${ZONE},_CLOUDSDK_CONTAINER_CLUSTER=${CLUSTER} .


```

## Build & Deploy of Branch Push

This trigger will deploy any branch other than master to its own namespace. 

- Open the [Container registry page](https://console.cloud.google.com/gcr)
- Select your project and click Open.
- In the left nav, click Build triggers.
- Click Create trigger.
- Select **Github**
- Select select the repository, then click Continue.

Enter the following trigger settings:
- Trigger Name: An optional name for your trigger.
- Trigger Type: **Branch** 
- Branch (regex): `[^(?!.*master)].*`

Build configuration select **cloudbuild.yaml**
- Enter `cloudbuild-dev.yaml` for the value

Substitution variables
- Click add item and input
    - Variable: `_CLOUDSDK_COMPUTE_ZONE`  
    - Value: `us-central1-a` (or whatever zone you used above)
- Click add item again and input
    - Variable: `_CLOUDSDK_CONTAINER_CLUSTER`
    - Value: `gke-deploy-example-cluster`

Click Create Trigger

Test it: To the right of the entry you just created click Run Trigger, and select a branch
View progress on the [Build History Page](https://console.cloud.google.com/gcr/builds) 


## Cloud Build & Deploy of Master Commit

This trigger will deploy commits to master to a canary server in production. 
 
Follow the above instructions but use:

- Trigger Type: **Branch**
    - Branch (regex): `master`
Build configuration select **cloudbuild.yaml**
- Enter `cloudbuild-canary.yaml` for the value

## Cloud Build & Deploy of a Tag
This trigger will deploy repository Tags to live servers in production
 
Follow the above instructions but use:

- Trigger Type: **Tag** 
    - Branch (regex): `.*`
Build configuration select **cloudbuild.yaml**
- Enter `cloudbuild-prod.yaml` for the value



