
# Releasing with Cloud Deploy

## Objectives

In this tutorial you will create three GKE clusters named preview, canary and prod. Then, create a Cloud Deploy target corresponding to each cluster and a Cloud Deploy pipeline that will define the sequence of steps to perform deployment in those targets. 

The deployment flow will be triggered by a cloudbuild pipeline that will create Cloud Deploy release and perform the deployment in the preview cluster. After you have verified that the deployment in preview was successful and working as expected, you will manually promote the release in the canary cluster. Promotion of the release in the prod cluster will require approval, you will approve the prod pipeline in Cloud Deploy UI and finally promote it.

The objectives of this tutorial can be broken down into the following steps:

-  Prepare your workspace
-  Define Cloud Deploy targets
-  Define Cloud Deploy pipeline
-  Create a Release
-  Promote a deployment
-  Approve a production release

## Before you begin

For this reference guide, you need a Google Cloud [project](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects). You can create a new one, or select a project you already created:

1. Select or create a Google Cloud project.

[GO TO THE PROJECT SELECTOR PAGE](https://console.corp.google.com/projectselector2/home/dashboard)

1. Enable billing for your project.

[ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

## 

## Platform Setup

### Preparing your workspace 

We will set up our environment here required to run this tutorial. When this step is completed, we will have a GKE cluster created where we can run the deployments.

1. **Set gcloud  config defaults**

```
gcloud config set project <your project>

gcloud config set deploy/region us-central1
```

2. **Clone Repo**

```
git clone https://github.com/gushob21/software-delivery-workshop
cd software-delivery-workshop/labs/cloud-deploy/
cloudshell workspace . 
rm -rf deploy && mkdir deploy
```

3. **Set environment variables**

```
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")
```

4. **Enable APIs**

```
gcloud services enable \
cloudresourcemanager.googleapis.com \
	container.googleapis.com \
	cloudbuild.googleapis.com \
	containerregistry.googleapis.com \
	secretmanager.googleapis.com \
	clouddeploy.googleapis.com 
```

5. **Create GKE clusters**

```
	gcloud container clusters create preview \
--zone=us-central1-a  --async
	gcloud container clusters create canary \
--zone=us-central1-b  --async
	gcloud container clusters create prod \
--zone=us-central1-c
```

### Defining Cloud Deploy Targets

1. **Create a file in the deploy directory named preview.yaml with the following command in cloudshell:**

```
cat <<EOF >deploy/preview.yaml
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: preview
  annotations: {}
  labels: {}
description: Target for preview environment
gke:
  cluster: projects/$PROJECT_ID/locations/us-central1-a/clusters/preview
EOF
```

	As you noticed, the "kind" tag is "Target". It allows us to add some metadata to the target, a description and finally the GKE cluster where the deployment is supposed to happen for this target.

2. **Create a file in the deploy directory named canary.yaml with the following command in cloudshell:**

```
cat <<EOF >deploy/canary.yaml
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: canary
  annotations: {}
  labels: {}
description: Target for canary environment
gke:
  cluster: projects/$PROJECT_ID/locations/us-central1-b/clusters/canary
EOF
```

3. **Create a file in the deploy directory named prod.yaml with the following command in cloudshell:**

```
cat <<EOF >deploy/prod.yaml
apiVersion: deploy.cloud.google.com/v1beta1
kind: Target
metadata:
  name: prod
  annotations: {}
  labels: {}
description: Target for prod environment
requireApproval: true
gke:
  cluster: projects/$PROJECT_ID/locations/us-central1-c/clusters/prod
EOF
```

Notice the tag requireApproval which is set to true. This will not allow promotion into prod target until the approval is granted. You require `roles/clouddeploy.approver `role to approve a release.

4. **Create the Deploy Targets**

```
    	gcloud config set deploy/region us-central1 
gcloud beta deploy apply --file deploy/preview.yaml
gcloud beta deploy apply --file deploy/canary.yaml
gcloud beta deploy apply --file deploy/prod.yaml
```

## App Creation

As part of the creation of a new application the CICD pipeline is typically setup to perform automatic builds, integration testing and deployments. The following steps are considered part of the setup process for a new app. Each new application will have a deployment pipeline configured. 

### Defining Cloud Deploy pipeline

1. **Create a file in the deploy directory named pipeline.yaml with the following command in cloudshell:**

```
cat <<EOF >>deploy/pipeline.yaml
apiVersion: deploy.cloud.google.com/v1beta1
kind: DeliveryPipeline
metadata:
  name: sample-app
  labels:
    app: sample-app
description: delivery pipeline
serialPipeline:
  stages:
  - targetId: preview
    profiles:
    - preview
  - targetId: canary
    profiles:
    - canary
  - targetId: prod
    profiles:
    - prod
EOF
```

**	**  
**	**As you noticed, the "kind" tag is "DeliveryPipeline". It lets you define the metadata for the pipeline, a description and an order of deployment into various targets via serialPipeline tag.

`serialPipeline` tag contains a tag named stages which is a list of all targets to which this delivery pipeline is configured to deploy.

`targetId` identifies the specific target to use for this stage of the delivery pipeline. The value is the metadata.name property from the target definition.

`profiles` is a list of zero or more Skaffold profile names, from skaffold.yaml. Cloud Deploy uses the profile with skaffold render when creating the release.

2. **Apply Pipeline**

```
gcloud beta deploy apply --file deploy/pipeline.yaml
```

## Development Phase

As the applications are developed automated CICD toolchains will build and store assets. The following commands are executed to build the application using skaffold and store assets for deployment with Cloud Deploy. This step would be performed by your CICD process for every application build. 

1. **Build and store the application with  skaffold**

```
skaffold build \
--file-output=artifacts.json \
--default-repo gcr.io/$PROJECT_ID \
--push=true
```

## Release Phase

At the end of your CICD process, typically when the code is Tagged for production, you will initiate the release process by calling the `cloud deploy release` command. Later once the deployment has been validated and approved you'll  move the release through the various target environments by promoting and approving the action through automated processes or manual approvals. 



### Creating a release

We created Cloud Deploy files in this tutorial earlier to get an understanding of how Cloud Deploy works. For the purpose of demo, we have created the same Cloud Deploy files and pushed them to a github repo with a sample go application and we will use Cloud Deploy to do the release of that application.  

```
export REL_TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

gcloud beta deploy releases create \
sample-app-release-${REL_TIMESTAMP} \
--delivery-pipeline=sample-app \
--description="Release demo" \
--build-artifacts=artifacts.json \
--annotations="release-id=rel-${REL_TIMESTAMP}"
```


### Review the release

When a Cloud Deploy release is created, it automatically rolls it out in the first target which is preview.

1. Go to [<Cloud Deploy> in Google cloud console](https://console.cloud.google.com/deploy)
2. Click on "sample-app"

   On this screen you will see a graphic representation of your pipeline. 

3. Confirm a green outline on the left side of the preview box which means that the release has been deployed to that environment.
4. Optionally review additional details about the release by clicking on the release name under Release Details in the lower section of the screen

5. Verify that the release successfully deployed the application, run the following command it cloushell 

```
gcloud container clusters get-credentials preview --zone us-central1-a && kubectl port-forward --namespace default $(kubectl get pod --namespace default --selector="app=cloud-deploy-tutorial" --output jsonpath='{.items[0].metadata.name}') 8080:8080
```

6. Click on the web preview icon in the upper right of the screen. 
7. Select Preview on port 8080

This will take you to a new page which shows the message "Hello World!"

8. Use `ctrl+c` in the terminal to end the port-forward.

### Promoting a release

Now that your  release is deployed to the first target (preview) in the pipeline, you can promote it to the next target (canary). Run the following command to begin the process. 

```
gcloud beta deploy releases promote \
--release=sample-app-release-${REL_TIMESTAMP} \
--delivery-pipeline=sample-app \
--quiet
```

### Review the release promotion

1. Go to the [sample-app pipeline in the Google Cloud console](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/sample-app)
2. Confirm a green outline on the left side of the Canary box which means that the release has been deployed to that environment.

3. Verify the application is deployed correctly by creating a tunnel to it

```
gcloud container clusters get-credentials canary --zone us-central1-b && kubectl port-forward --namespace default $(kubectl get pod --namespace default --selector="app=cloud-deploy-tutorial" --output jsonpath='{.items[0].metadata.name}') 8080:8080
```

4. Click on the web preview icon in the upper right of the screen. 
5. Select Preview on port 8080

This will take you to a new page which shows the message "Hello World!"

6. Use `ctrl+c` in the terminal to end the port-forward.

### Approving a production release

Remember when we created prod target via prod.yaml, we specified the tag requireApproval as true. This will force a requirement of approval for promotion in prod.

1. Promote the canary release to production  with the following command

```
gcloud beta deploy releases promote \
--release=sample-app-release-${REL_TIMESTAMP} \
--delivery-pipeline=sample-app \
--quiet
```

2. Go to the [sample-app pipeline in the Google Cloud console](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/sample-app)

3. Notice the yellow indicator noting "1 pending". 

   This message indicates there is a release queued for deployment to production but requires review and approval. 

4. Click on the "Review" button just below the yellow notice.  
5. In the next screen click "Review" again to access the approval screen for production
6. Optionally review  the Manifest Diff to review the changes. In this case a whole new file.  
7. Click on the "Approve" button 
8. Return to the [sample-app pipeline page](https://console.cloud.google.com/deploy/delivery-pipelines/us-central1/sample-app) where you will see the release to prod in progress.

### Review the production release

As with the other environments you can review the deployment when it completes using the steps below. 

1. Run the following command it cloudshell to create the port-forward

```
gcloud container clusters get-credentials prod --zone us-central1-c && kubectl port-forward --namespace default $(kubectl get pod --namespace default --selector="app=cloud-deploy-tutorial" --output jsonpath='{.items[0].metadata.name}') 8080:8080
```

2. Click on the web preview icon in the upper right of the screen. 
3. Select Preview on port 8080

This will take you to a new page which shows the message "Hello World!"

4. Use `ctrl+c` in the terminal to end the port-forward.