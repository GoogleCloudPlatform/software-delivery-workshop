# Cloud Build Scheduled Jobs

This lab demonstrates how to automate the execution of Cloud Build jobs based on a scheduled frequency. 

This technique is often used to ensure the latest upstream changes are always included in your containers. 

In this example a custom image has been built on top of a base image. To ensure security updates and patches from the base image are always applied to the custom image as well, Cloud Scheduler is used to trigger the build on a regular basis. 


What you will accomplish
- Create Artifact Registry to Store and Scan your custom image
- Configure Github with Google cloud to store your image configurations
- Create a Cloud Build trigger to automate creation of custom image
- Configure Cloud Scheduler to initiate builds on a regular basis
- Review the results of the processes

## Setup and Requirements

### Enable APIs

```sh
gcloud services enable \
        container.googleapis.com \
        cloudbuild.googleapis.com \
        containerregistry.googleapis.com \
        containerscanning.googleapis.com \
        artifactregistry.googleapis.com \
        cloudscheduler.googleapis.com
```


### Set Environment Variables
The following variables will be used multiple times throughout the tutorial. 



```sh
PROJECT_ID=[your project id]
```

```sh
GITHUB_USER=[your github name]
```


```sh
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
REGION=us-central1

```

### Artifact Registry Repository
In this lab you will be using Artifact Registry to store and scan your images. Create the repository with the following command.

```sh
gcloud artifacts repositories create custom-images \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository"
```

Configure docker to utilize your gcloud credentials when accessing Artifact Registry.

```sh
gcloud auth configure-docker $REGION-docker.pkg.dev
```


## Git Repository
In practice you will keep the Dockerfile for your custom images in a git repo. The automated process will access that repo during the build process to pull the relevant configs and Dockerfile. 

### Fork the sample repository

For this tutorial you will fork a sample repo that provides the container definitions used in this lab.

- [Click this link to fork the repo](https://github.com/GoogleCloudPlatform/software-delivery-workshop/fork)


### Connect Cloud Build to GitHub

Next you will connect that repository to Cloud Build using the built in Github connection capability. Follow the link below to the instructions describing how to complete the process.

- [Connect the github repo](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github)



## Cloud Build

```sh
TRIGGER_NAME=custom-image-trigger

gcloud beta builds triggers create manual \
  --region=us-central1 \
  --name=${TRIGGER_NAME} \
  --repo=${GITHUB_USER}/software-delivery-workshop \
  --repo-type=GITHUB \
  --branch=main \
  --build-config=labs/cloudbuild-scheduled-jobs/code-oss-java/cloudbuild.yaml \
  --substitutions=_REGION=us-central1,_AR_REPO_NAME=custom-images,_AR_IMAGE_NAME=code-oss-java,_IMAGE_DIR=labs/cloudbuild-scheduled-jobs/code-oss-java

TRIGGER_ID=$(gcloud beta builds triggers list --region=us-central1 \
   --filter=name="${TRIGGER_NAME}" --format="value(id)")

```

## Cloud Scheduler


```sh
gcloud scheduler jobs create http run-build \
    --schedule='3 * * * *' \
    --uri=https://cloudbuild.googleapis.com/v1/projects/${PROJECT_ID}/locations/us-central1/triggers/${TRIGGER_ID}:run \
    --location=us-central1 \
    --oauth-service-account-email=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --oauth-token-scope=https://www.googleapis.com/auth/cloud-platform
```


Test the initial functionality by running the job [manually from the console](https://console.cloud.google.com/cloudscheduler)
- On the Cloud Scheduler page find the entry you just created called run-build
- Click the three dots for that row under the Actions column
- Click Force a job run to test the system manually


## Review The Results

### Vulnerabilities 
To see the vulnerabilities in an image:
- Open the [Repositories page](https://console.cloud.google.com/artifacts)
- In the repositories list, click a repository.
- Click an image name.
- Vulnerability totals for each image digest are displayed in the Vulnerabilities column.

To view the list of vulnerabilities for an image:
- click the link in the Vulnerabilities column
- The vulnerability list shows the severity, availability of a fix, and the name of the package that contains the vulnerability.

