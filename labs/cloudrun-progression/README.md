# Canary Deployments with Cloud Run and Cloud Build

## Overview

This document shows you how to implement a deployment pipeline for Cloud Run that implements progression of code from developer branches to production with automated canary testing and percentage based traffic management. It is intended for platform administrators who are responsible for creating and managing CI/CD pipelines to Google Kubernetes Engine (GKE). This document assumes that you have a basic understanding of Git, Cloud Run, and CI/CD pipeline concepts. 

Cloud Run lets you deploy and run your applications with little overhead or effort. Many organizations use robust release pipelines to move code into production. Cloud Run provides unique traffic management capabilities that let you implement advanced release management techniques with little effort.

### Objectives 

-   Create your Cloud Run service
-   Enable developer branch
-   Implement canary testing
-   Rollout safely to production

### Costs

This tutorial uses billable components of Google Cloud, including:

-   [Cloud Run](https://cloud.google.com/run/pricing)
-   [Cloud Build](https://cloud.google.com/build/pricing)

Use the [Pricing Calculator](https://cloud.google.com/products/calculator) to generate a cost estimate based on your projected usage.

### Before you begin

1.  Create a Google Cloud project.

[GO TO THE MANAGE RESOURCES PAGE](https://console.cloud.google.com/cloud-resource-manager)

2.  Enable billing for your project.

[ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

3.  In Cloud Console, go to [Cloud Shell](https://cloud.google.com/shell/docs/how-cloud-shell-works) to execute the commands listed in this tutorial.

[GO TO CLOUD](https://console.cloud.google.com/?cloudshell=true&_ga=2.130021388.-1258454239.1533315939&_gac=1.201996835.1554234100.CKPetZmVsuECFUfNDQodJ-UGUQ) SHELL

At the bottom of the Cloud Console, a [Cloud Shell](https://cloud.google.com/shell/docs/how-cloud-shell-works) session opens and displays a command-line prompt. Cloud Shell is a shell environment with the Cloud SDK already installed, including the [gcloud](https://cloud.google.com/sdk/gcloud) command-line tool, and with values already set for your current project. It can take a few seconds for the session to initialize.

When you finish this tutorial, you can avoid continued billing by deleting the resources you created. See [Cleaning up](https://docs.google.com/document/d/1yCbt_zPaWJ7u59xWgd1KuxMlNr1juBjjYo7WASIQeL0/edit?resourcekey=0-a--Q0cYLuCdecVW6PKWmJg#heading=h.mlrdlgcohh7k) for more detail.


## Preparing Your Environment

### Set Project Variables
1.  In Cloud Shell, create environment variables to use throughout this tutorial:    

```sh
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```


### Enable APIs

Enable the following APIs on your project

-   Cloud Resource Manager
-   Cloud Build
-   Container Registry
-   Cloud Run

```sh
gcloud services enable \
cloudresourcemanager.googleapis.com \
container.googleapis.com \
secretmanager.googleapis.com \
cloudbuild.googleapis.com \
containerregistry.googleapis.com \
run.googleapis.com
```  


### Grant Rights
Grant the Cloud Run Admin role (roles/run.admin) to the Cloud Build service account:

```sh
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
--role=roles/run.admin
```
  
Grant the IAM Service Account User role (`roles/iam.serviceAccountUser`) to the Cloud Build service account for the Cloud Run runtime service account:

```sh
gcloud iam service-accounts add-iam-policy-binding \
$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
--member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
--role=roles/iam.serviceAccountUser
```




### Set Git values

If you haven't used Git in Cloud Shell previously, set the `user.name` and `user.email` values that you want to use:

```sh
git config --global user.email "[YOUR_EMAIL_ADDRESS]"
git config --global user.name "[YOUR_USERNAME]"
git config --global credential.helper store
```

If you're using MFA with GitHub, create a personal access token and use it as your password when interacting with GitHub through the command-line
- Follow [this link to create an access token](https://github.com/settings/tokens/new?scopes=repo%2Cread%3Auser%2Cread%3Aorg%2Cuser%3Aemail%2Cwrite&description=Cloud%20Run%20Tutorial)
- Leave the tab open 

Store your GitHub ID in an environment variable for easier access

```sh
export GH_USER=<YOUR ID>
```

### Fork the project repo

First fork the sample repo into your GitHub account [through the GitHub UI](https://github.com/GoogleCloudPlatform/software-delivery-workshop/fork).

### Clone The Project Repo

Clone and prepare the sample repository:
   
```sh
git clone https://github.com/$GH_USER/software-delivery-workshop.git cloudrun-progression

cd cloudrun-progression/labs/cloudrun-progression
```
  



## Connecting Your Git Repo

Cloud Build enables you to create and manage connections to source code repositories using the Google Cloud console. You can [create and manage connections](https://cloud.google.com/build/docs/repositories) using Cloud Build repositories (1st gen) or Cloud Build repositories (2nd gen). For this tutorial you will utilize Cloud Build repositories (2nd gen) to connect your GitHub repo and access a the sample source repo. 

### Grant Required  Permissions

To connect your GitHub host, grant the Cloud Build Connection Admin (`roles/cloudbuild.connectionAdmin`) role to your user account
```sh
PN=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
CLOUD_BUILD_SERVICE_AGENT="service-${PN}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:${CLOUD_BUILD_SERVICE_AGENT}" \
 --role="roles/secretmanager.admin"
```

### Create the Host connection

Configure the Cloud Build Repository connection by running the command below. 

```sh
gcloud alpha builds connections create github $GH_USER --region=us-central1
```

Click the link provided in the output and follow the onscreen instructions to complete the connection. 


Verify the installation of your GitHub connection by running the following command:

```
gcloud alpha builds connections describe $GH_USER --region=us-central1
```

### Link the specific repository

Using the host connection you just configured, link in the sample repo you forked

```sh
 gcloud alpha builds repositories create cloudrun-progression \
     --remote-uri=https://github.com/$GH_USER/software-delivery-workshop.git \
     --connection=$GH_USER \
     --region=us-central1
```

### Set Repository Name variable

Store the Repository name for later use

```sh
export REPO_NAME=projects/$PROJECT_ID/locations/us-central1/connections/$GH_USER/repositories/cloudrun-progression
```


## Deploying Your Cloud Run Service

In this section, you build and deploy the initial production application that you use throughout this tutorial.

### Deploy the service
1.  In Cloud Shell, build and deploy the application, including a service that requires authentication. To make a public service use the --allow-unauthenticated flag as [noted in the documentation](https://cloud.google.com/run/docs/authenticating/public).

```sh
gcloud builds submit --tag gcr.io/$PROJECT_ID/hello-cloudrun 

gcloud run deploy hello-cloudrun \
--image gcr.io/$PROJECT_ID/hello-cloudrun \
--platform managed \
--region us-central1 \
--tag=prod -q
```



The output looks like the following:

  ```
  Deploying container to Cloud Run service [hello-cloudrun] in project [sdw-mvp6] region [us-central1]
✓ Deploying new service... Done.                                                           
  ✓ Creating Revision...
  ✓ Routing traffic...
Done.
Service [hello-cloudrun] revision [hello-cloudrun-00001-tar] has been deployed and is serving 100 percent of traffic.
Service URL: https://hello-cloudrun-apwaaxltma-uc.a.run.app
The revision can be reached directly at https://prod---hello-cloudrun-apwaaxltma-uc.a.run.app
```
 
The output includes the service URL and a unique URL for the revision. Your values will differ slightly from what's indicated here. 

### Validate the deploy
2.  After the deployment is complete, view the newly deployed service on the [Revisions page](https://console.cloud.google.com/run/detail/us-central1/hello-cloudrun/revisions) in the Cloud Console.

4.  In Cloud Shell, view the authenticated service response:

  ```sh
PROD_URL=$(gcloud run services describe hello-cloudrun --platform managed --region us-central1 --format=json | jq --raw-output ".status.url")

echo $PROD_URL

curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_URL
```


## Enabling Branch Deployments

### Setup Branch Trigger

In this section, you enable developers with a unique URL for development branches in Git. Each branch is represented by a URL identified by the branch name. Commits to the branch trigger a deployment, and the updates are accessible at that same URL.  

1.  In Cloud Shell, set up the trigger:
```sh
gcloud alpha builds triggers create github \
--name=branchtrigger \
--repository=$REPO_NAME \
--branch-pattern='[^(?!.*main)].*' \
--build-config=labs/cloudrun-progression/branch-cloudbuild.yaml \
--region=us-central1
```
  
2.  To review the trigger, go to the [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers;region=us-central1) in the Cloud Console:

### Create changes on a branch
1.  In Cloud Shell, create a new branch:
```sh
git checkout -b new-feature-1
```

4.  Open the sample application using your favorite editor or using the Cloud Shell IDE:
```sh
edit app.py
```

5.  In the sample application, modify line 24 to indicate v1.1 instead of v1.0:
```python
@app.route('/')

def hello_world():
    return 'Hello World v1.1'

```

6.  To return to your terminal, click Open Terminal.

### Execute the branch trigger 
1.  In Cloud Shell, commit the change and push to the remote repository:

```sh
git add . && git commit -m "updated" && git push origin new-feature-1
```

> NOTE: Use the personal access token you created earlier for the password if you have 2FA enabled on GitHub

1.  To review the build in progress, go to the [Cloud Build Builds page](https://console.cloud.google.com/cloud-build/builds) in the Cloud Console.
2.  After the build completes, to review the new revision, go to the [Cloud Run Revisions page](https://console.cloud.google.com/run/detail/us-central1/hello-cloudrun/revisions) in the Cloud Console:
3.  In Cloud Shell, get the unique URL for this branch:
```sh
BRANCH_URL=$(gcloud run services describe hello-cloudrun --platform managed --region us-central1 --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"new-feature-1\")|.url")

echo $BRANCH_URL
```
 

11.  Access the authenticated URL:
```sh
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BRANCH_URL
```

The updated response output looks like the following:

```
Hello World v1.1
```
  


# Automating Canary Testing

When code is released to production, it's common to release code to a small subset of live traffic before migrating all traffic to the new code base. 

In this section, you implement a trigger that is activated when code is committed to the main branch. The trigger deploys the code to a unique canary URL and it routes 10% of all live traffic to the new revision. 

1.  In Cloud Shell, set up the branch trigger:
```sh
gcloud alpha builds triggers create github \
  --name=maintrigger \
  --repository=$REPO_NAME \
  --branch-pattern=main \
  --build-config=labs/cloudrun-progression/main-cloudbuild.yaml \
  --region=us-central1
```

2.  To review the new trigger, go to the [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers) in the Cloud Console.
3.  In Cloud Shell, merge the branch to the main line and push to the remote repository:
```sh
git checkout main
git merge new-feature-1
git push origin main
```


4.  To review the build in progress, go to the [Cloud Build Builds page](https://console.cloud.google.com/cloud-build/builds) in the Cloud Console.
5.  After the build is complete, to review the new revision, go to the [Cloud Run Revisions page](https://console.cloud.google.com/run/detail/us-central1/hello-cloudrun/revisions) in the Cloud Console. Note that 90% of the traffic is routed to prod, 10% to canary, and 0% to the branch revisions.



Review the key lines of `main-cloudbuild.yaml` that implement the logic for the canary deploy.

Lines 39-45 deploy the new revision and use the tag flag to route traffic from the unique canary URL:
```
gcloud run deploy ${_SERVICE_NAME} \
--platform managed \
--region ${_REGION} \
--image gcr.io/${PROJECT_ID}/${_SERVICE_NAME} \
--tag=canary \
--no-traffic
```


Line 61 adds a static tag to the revision that notes the Git short SHA of the deployment:
```
gcloud beta run services update-traffic  ${_SERVICE_NAME} --update-tags=sha-$SHORT_SHA=$${CANARY}  --platform managed  --region ${_REGION}
```
 
  Line 62 updates the traffic to route 90% to production and 10% to canary:
```
gcloud run services update-traffic  ${_SERVICE_NAME} --to-revisions=$${PROD}=90,$${CANARY}=10  --platform managed  --region ${_REGION}
```
  

1.  In Cloud Shell, get the unique URL for the canary revision:   

```sh
CANARY_URL=$(gcloud run services describe hello-cloudrun --platform managed --region us-central1 --format=json | jq --raw-output ".status.traffic[] | select (.tag==\"canary\")|.url")

echo $CANARY_URL
```

8.  Review the canary endpoint directly:

```sh
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $CANARY_URL
``` 

9.  To see percentage-based responses, make a series of requests:
```sh
LIVE_URL=$(gcloud run services describe hello-cloudrun --platform managed --region us-central1 --format=json | jq --raw-output ".status.url")
for i in {0..20};do
	curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $LIVE_URL; echo \n
done
```


# Releasing to Production

After the canary deployment is validated with a small subset of traffic, you release the deployment to the remainder of the live traffic. 

In this section, you set up a trigger that is activated when you create a tag in the repository. The trigger migrates 100% of traffic to the already deployed revision based on the commit SHA of the tag. Using the commit sha ensures the revision validated with canary traffic is the revision utilized for the remainder of production traffic. 

1.  In Cloud Shell, set up the tag trigger:
```sh
gcloud alpha builds triggers create github \
	--name=tagtrigger \
	--repository=$REPO_NAME \
	--tag-pattern=. \
	--build-config=labs/cloudrun-progression/tag-cloudbuild.yaml \
	--region=us-central1
```  
 
2.  To review the new trigger, go to the [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers) in the Cloud Console.
3.  In Cloud Shell, create a new tag and push to the remote repository:
```sh
git tag 1.1
git push origin 1.1
```
 
4.  To review the build in progress, go to the [Cloud Build Builds page](https://console.cloud.google.com/cloud-build/builds) in the Cloud Console.

5.  After the build is complete, to review the new revision, go to the [Cloud Run Revisions page](https://console.cloud.google.com/run/detail/us-central1/hello-cloudrun/revisions) in the Cloud Console. Note that the revision is updated to indicate the prod tag and it is serving 100% of live traffic.



6.  In Cloud Shell, to see percentage-based responses, make a series of requests:

```sh
LIVE_URL=$(gcloud run services describe hello-cloudrun --platform managed --region us-central1 --format=json | jq --raw-output ".status.url")

for i in {0..20};do
	curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" $LIVE_URL; echo \n
done
```


7.  Review the key lines of `tag-cloudbuild.yaml` that implement the production deployment logic. 

Line 37 updates the canary revision adding the prod tag. The deployed revision is now tagged for both prod and canary:

```
gcloud beta run services update-traffic  ${_SERVICE_NAME} --update-tags=prod=$${CANARY}  --platform managed  --region ${_REGION}
```
  
Line 39 updates the traffic for the base service URL to route 100% of traffic to the revision tagged as prod:

```
gcloud run services update-traffic  ${_SERVICE_NAME} --to-revisions=$${NEW_PROD}=100  --platform managed  --region ${_REGION}
```


# Cleaning up

To avoid incurring charges to your Google Cloud Platform account for the resources used in this tutorial:

### Delete the project

The easiest way to eliminate billing is to delete the project you created for the tutorial.

Caution: Deleting a project has the following effects:

-   Everything in the project is deleted. If you used an existing project for this tutorial, when you delete it, you also delete any other work you've done in the project.
-   Custom project IDs are lost. When you created this project, you might have created a custom project ID that you want to use in the future. To preserve the URLs that use the project ID, such as an appspot.com URL, delete selected resources inside the project instead of deleting the whole project.

If you plan to explore multiple tutorials and quickstarts, reusing projects can help you avoid exceeding project quota limits.

1.  In the Cloud Console, go to the Manage resources page.  
    [Go to the Manage resources page](https://console.cloud.google.com/iam-admin/projects)
2.  In the project list, select the project that you want to delete and then click Delete ![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADQAAABGCAYAAACDkrchAAAAAXNSR0IArs4c6QAAAe9JREFUaEPtWctKQlEUXdcH+BnVT1SD1LRxeiUoatCwbvgbEQVmFASJEUFEX1GNKkPKhg6tT3DiAzSuEGgonu095yKyznjt11p7b6/nWN1ut4sZOhYLmnI1qdCUCwQqRIV8ZoAt5zPh4nBUSEyZzwZUyGfCxeGokJgynw2okM+Ei8MZUajZbMJxsnh8eh6bUCQSQeHqEtHoylisCmCigtx/7a1Wa6j/RqOB/YMsXl/eVOL3MOFwGOcXZ0jEY0NtgsEgQqGQkr+JCqpUvpC2N5QC6ADF4lHc3lwruWJBLk1USKlZRoOMt5zH/IyaTzRDfxl1Oh20221jCQYCgd4GlBxPBZVK79jc2pHEE2GXlhfxcH8nsmFB/XRRIVHzAGw5wNvNKVuOLce1zRkamAIuBS4FLgUuBS4F4R4YgPPjlB+n//qHP6zCgeIMcYZmfYZqtRpi8TXhZKjD7fQ68vmcuoHXlnPfiWKrSXzXfkRBVcGnuRNkMrYqvIfzdNHoOiiXy9je2R35ACbKpg+cTMRRLBZgWZbIheeC3GjVahWHR8f4/KigXq+LEugHu3fZ8wtzsFMpOM4e3Jc76dFSkDSoSTwLMsmuDt9USAeLJn1QIZPs6vBNhXSwaNIHFTLJrg7fVEgHiyZ9UCGT7OrwPXMK/QL+cgFNd5b6egAAAABJRU5ErkJggg==).
3. In the dialog, type the project ID and then click Shut down to delete the project.

# What's next

- Review [Managing Revisions with Cloud Run](https://cloud.google.com/run/docs/managing/revisions).
- Review Cloud Run [Rollbacks, gradual rollouts, and traffic migration](https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration)
- Review [Using tags for accessing revisions](https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration#tags).
- Review [Creating and managing build triggers](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers) in Cloud Build.