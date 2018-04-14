# GKE Deployments with Cloud Builder

The included scripts are intended to demonstrate how to use Google Cloud Container Builder as a continuous integration system deploying code to GKE. This is not an official Google product. 

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


This lab shows you how to setup a continuous delivery pipeline for GKE using Google Cloud Container Builder. We’ll run through the following steps

- Create a GKE Cluster
- Review the application structure
- Manually deploy the application
- Create a repository for our source
- Setup automated triggers in Cloud Builder
- Automatically deploy Branches to custom namespaces
- Automatically deploy Master as a canary
- Automatically deploy Tags to production





## Set Variables

```
 
    export PROJECT=[[YOUR PROJECT NAME]]
    # On Cloudshell
    # export PROJECT=$(gcloud info --format='value(config.project)')
    export CLUSTER=gke-deploy-cluster
    export ZONE=us-central1-a

    gcloud config set compute/zone $ZONE

```
## Enable Services
```
gcloud services enable container.googleapis.com --async
gcloud services enable containerregistry.googleapis.com --async
gcloud services enable cloudbuild.googleapis.com --async
gcloud services enable sourcerepo.googleapis.com --async
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

## Give Cloud Builder Rights

For `kubectl` commands against GKE youll need to give Container Builder Service Account container.developer role access on your clusters [details](https://github.com/GoogleCloudPlatform/cloud-builders/tree/master/kubectl).

```
PROJECT_NUMBER="$(gcloud projects describe \
    $(gcloud config get-value core/project -q) --format='get(projectNumber)')"

gcloud projects add-iam-policy-binding ${PROJECT} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer

```

## Deploy the application manually

```
kubectl create ns production
kubectl apply -f kubernetes/deployments/prod -n production
kubectl apply -f kubernetes/deployments/canary -n production
kubectl apply -f kubernetes/services -n production

kubectl scale deployment gceme-frontend-production -n production --replicas 4

kubectl get pods -n production -l app=gceme -l role=frontend
kubectl get pods -n production -l app=gceme -l role=backend

kubectl get service gceme-frontend -n production

export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services gceme-frontend)

curl http://$FRONTEND_SERVICE_IP/version

```


## Create a repo for the code

```
gcloud alpha source repos create default
git init
git config credential.helper gcloud.sh
git remote add gcp https://source.developers.google.com/p/[PROJECT]/r/default
git add .
git commit -m "Initial Commit"
git push gcp master

```

## Setup triggers
Ensure you have credentials available
```
gcloud auth application-default login

```
**Branches**
```

cat <<EOF > branch-build-trigger.json
{
  "triggerTemplate": {
    "projectId": "${PROJECT}",
    "repoName": "default",
    "branchName": "[^(?!.*master)].*"
  },
  "description": "branch",
  "substitutions": {
    "_CLOUDSDK_COMPUTE_ZONE": "${ZONE}",
    "_CLOUDSDK_CONTAINER_CLUSTER": "${CLUSTER}"
  },
  "filename": "builder/cloudbuild-dev.yaml"
}
EOF


curl -X POST \
    https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    --data-binary @branch-build-trigger.json
```

**Master**
```

cat <<EOF > master-build-trigger.json
{
  "triggerTemplate": {
    "projectId": "${PROJECT}",
    "repoName": "default",
    "branchName": "master"
  },
  "description": "master",
  "substitutions": {
    "_CLOUDSDK_COMPUTE_ZONE": "${ZONE}",
    "_CLOUDSDK_CONTAINER_CLUSTER": "${CLUSTER}"
  },
  "filename": "builder/cloudbuild-canary.yaml"
}
EOF


curl -X POST \
    https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    --data-binary @master-build-trigger.json
```

**Tag**
```

cat <<EOF > tag-build-trigger.json
{
  "triggerTemplate": {
    "projectId": "${PROJECT}",
    "repoName": "default",
    "tagName": ".*"
  },
  "description": "tag",
  "substitutions": {
    "_CLOUDSDK_COMPUTE_ZONE": "${ZONE}",
    "_CLOUDSDK_CONTAINER_CLUSTER": "${CLUSTER}"
  },
  "filename": "builder/cloudbuild-prod.yaml"
}
EOF


curl -X POST \
    https://cloudbuild.googleapis.com/v1/projects/${PROJECT}/triggers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    --data-binary @tag-build-trigger.json
```

Review triggers are setup on the [Build Triggers Page](https://console.cloud.google.com/gcr/triggers) 




### Build & Deploy of local content (optional)

The following submits a build to cloud builder and deploys the results to a user's namespace.

```
gcloud container builds submit \
    --config builder/cloudbuild-local.yaml \
    --substitutions=_VERSION=someversion,_USER=$(whoami),_CLOUDSDK_COMPUTE_ZONE=${ZONE},_CLOUDSDK_CONTAINER_CLUSTER=${CLUSTER} .


```


## Deploy Branches to Namespaces

Development branches are a set of environments your developers use to test their code changes before submitting them for integration into the live site. These environments are scaled-down versions of your application, but need to be deployed using the same mechanisms as the live environment.

### Create a development branch

To create a development environment from a feature branch, you can push the branch to the Git server and let Cloud Builder deploy your environment. 

Create a development branch and push it to the Git server.

```
git checkout -b new-feature
```


### Modify the site

In order to demonstrate changing the application, you will be change the gceme cards from blue to orange.

**Step 1**
Open html.go and replace the two instances of blue with orange.

**Step 2**
Open main.go and change the version number from 1.0.0 to 2.0.0. The version is defined in this line:

const version string = "2.0.0"

### Kick off deployment

**Step 1**

Commit and push your changes. This will kick off a build of your development environment.

```
git add html.go main.go

git commit -m "Version 2.0.0"

git push gcp new-feature
```

**Step 2**

After the change is pushed to the Git repository, navigate to the [Build History Page](https://console.cloud.google.com/gcr/builds) user interface where you can see that your build started for the new-feature branch 

Click into the build to review the details of the job

**Step 3**

Once that completes, verify that your application is accessible. You should see it respond with 2.0.0, which is the version that is now running.

Retrieve the external IP for the production services.

It can take several minutes before you see the load balancer external IP address.

```
kubectl get service gceme-frontend -n new-feature
```

Once an External-IP is provided store it for later use

```
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}" --namespace=new-feature services gceme-frontend)

curl http://$FRONTEND_SERVICE_IP/version

```


>Congratulations! You've setup a pipeline and deployed code to GKE with cloud builder. 


The rest of this example follows the same pattern but demonstrates the triggers for Master and Tags. 

## Deploy Master to canary

Now that you have verified that your app is running your latest code in the development environment, deploy that code to the canary environment.

**Step 1**
Create a canary branch and push it to the Git server.

```
git checkout master

git merge new-feature

git push gcp master
```

Again after you’ve pushed to the Git repository, navigate to the [Build History Page](https://console.cloud.google.com/gcr/builds) user interface where you can see that your build started for the master branch 

Click into the build to review the details of the job

**Step 2**

Once complete, you can check the service URL to ensure that some of the traffic is being served by your new version. You should see about 1 in 5 requests returning version 2.0.0.

```
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}" --namespace=production services gceme-frontend)

while true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done
```

You can stop this command by pressing `Ctrl-C`.

>Congratulations!
>
>You have deployed a canary release. Next you will deploy the new version to production by creating a tag.


## Deploy Tags to production

Now that your canary release was successful and you haven't heard any customer complaints, you can deploy to the rest of your production fleet. 

**Step 1**
Merge the canary branch and push it to the Git server.

```
git tag v2.0.0

git push gcp v2.0.0
```

Review the job on the the [Build History Page](https://console.cloud.google.com/gcr/builds) user interface where you can see that your build started for the v2.0.0 tag 

Click into the build to review the details of the job

**Step 2**
Once complete, you can check the service URL to ensure that all of the traffic is being served by your new version, 2.0.0. You can also navigate to the site using your browser to see your orange cards.

```
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}" --namespace=production services gceme-frontend)

while true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done
```

You can stop this command by pressing `Ctrl-C`.


>Congratulations!
>
>You have successfully deployed your application to production!

