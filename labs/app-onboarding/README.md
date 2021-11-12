# App Onboarding

In this lab you will

* Utilize predefined & custom app templates  
* Create a new instance of an application  
* Implement Build, Package and Deploy logic  
* Configure automated pipeline execution   
* Bundle onboarding logic for simple app creation

## Preparing your workspace

1. Open Cloud Shell editor by visiting the following url 

```
https://ide.cloud.google.com
```

2. Ensure your project name is set in CLI

```
gcloud config set project {{project-id}}
```

3. Enable APIs

```
gcloud services enable \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com 
  
```

4. In the terminal window clone the application source with the following command: 

```
git clone https://github.com/GoogleCloudPlatform/software-delivery-workshop.git 
```

5. Change into the directory and set the IDE workspace to the repo root

```
cd software-delivery-workshop && rm -rf .git
cd delivery-platform && cloudshell workspace .
```

## Utilizing predefined & custom app templates

Developers should be able to choose from a set of templates commonly used within the organization.  The onboarding process will create a centralized set of template repositories stored in your GitHub account. In later steps these template repositories will be copied and modified for use as the base for new applications.  For this lab you will seed your template repository with a sample structure provided here. You can add your own templates by adding additional folders modeled after the sample. 

In this step you will create your own repository to hold app templates, from the example files provided. A helper script is provided to simplify the interactions with GitHub. 

These are one time steps used to populate your template repositories. Future steps will reused these repositories. 

### Configure GitHub Access

The steps in this tutorial call the GitHub API to create and configure repositories. Your GitHub username and a personal access token are required at various points that follow. The script below will help you acquire the values and store them as local variables for later use. 

```
source ./onboard-env.sh
```

### Create App Template Repository

Sample application templates are provided along with this lab as an example of how you might integrate your own base templates. In this step you create your own copy of these files in a repo called `mcd-app-templates` in your GitHub account. 

1. Copy the template to the working directory

```
cp -R $BASE_DIR/resources/repos/app-templates $WORK_DIR
cd $WORK_DIR/app-templates
```

2. Create an empty remote repository in your GitHub account

```
$BASE_DIR/scripts/git/gh.sh create mcd-app-templates 
```

3. Push the template repository to your remote repository

```
git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
git remote add origin $GIT_BASE_URL/mcd-app-templates
git push origin main
```

4. Clean up the working directory

```
cd $BASE_DIR
rm -rf $WORK_DIR/app-templates
```

### Create Shared Base Configs Repository

This tutorial utilizes a tool called Kustomize that uses base configuration files shared by multiple teams then overlays application specific configurations over top. This enables platform teams to scale across many teams and environments. 

In this step you create the shared configuration repository called `mcd-shared_kustomize `from the samples provided

1. Copy the template to the working directory

```
cp -R $BASE_DIR/resources/repos/shared-kustomize $WORK_DIR
cd $WORK_DIR/shared-kustomize
```

2. Create an empty remote repository in your GitHub account

```
$BASE_DIR/scripts/git/gh.sh create mcd-shared_kustomize 
```

3. Push the template repository to your remote repository

```
git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
git remote add origin $GIT_BASE_URL/mcd-shared_kustomize
git push origin main
```

4. Clean up the working directory

```
cd $BASE_DIR
rm -rf $WORK_DIR/shared-kustomize
```

With your template repositories created you're ready to use them to create an app instance

## Creating a new instance of an application

Creating a new application from a template often requires that placeholder variables be swapped out with real values across multiple files in the template structure. Once the substitution is completed a new repository is created for the new app instance. It is this app instance repository that the developers will clone and work with in their day to day development.

In this step you will substitute values in an app template and post the resulting files to a new repository. 

### Define a name for the new application

```
export APP_NAME=my-app
```

### Retrieve the Golang template repository

```
cd $WORK_DIR/
git clone -b main $GIT_BASE_URL/mcd-app-templates app-templates
rm -rf app-templates/.git
cd app-templates/golang
```

### Substitute placeholder values

One of the most common needs for onboarding is swapping out variables in templates for actual instances used in the application. For example providing the application name. The following command creates instances of all .tmpl files with the values stored in environment variables.  

```
for template in $(find . -name '*.tmpl'); do envsubst < ${template} > ${template%.*}; done
```

### Create a new repo and store the updated files

1. Create an empty remote repository in your GitHub account

```
$BASE_DIR/scripts/git/gh.sh create ${APP_NAME}
```

2. Push the template repository to your remote repository

```
git init && git symbolic-ref HEAD refs/heads/main && git add . && git commit -m "initial commit"
git remote add origin $GIT_BASE_URL/${APP_NAME}
git push origin main
```

Now that the app instance has been created it's time to implement continuous builds.   
 

## Configuring automated pipeline execution 

The central part of a Continuous Integration system is the ability to execute the pipeline logic based on the events originating in the source control system. When a developer commits code in their repository events are fired that can be configured to trigger processes in other systems. 

In this step you will configure GitHub to call Google Cloud Build and execute your pipeline, whenever users commit or tag code in their repository. 

### Enable Secure Access

You will need 2 elements to configure secure access to your application pipeline. An API key and a secret unique to the pipeline. 

#### API Key

The API key is used to identify the client that is calling into a given API. In this case the client will be GitHub. A best practice not covered here is to lock down the scope of the API key to only the specific APIs that client will be accessing. You created the key in a previous step.

1. You can review the key by clicking on [this link]( https://console.cloud.google.com/apis/credentials) 
2. You can ensure the value is set by running the following command

```
echo $API_KEY_VALUE
```

#### Pipeline Secret

The secrets are used to authorize a caller and ensure they have rights to the specific cloud build target job. You may have 2 different repositories in GitHub that should only have access to their own pipelines. While the API_KEY limits which APIs can be utilized by github (in this case the Cloud Build API is being called), the secret limits which Job in the Cloud Build API can be executed by the client. 

1. Define the secret name, location and value

```
SECRET_NAME=${APP_NAME}-webhook-trigger-cd-secret
SECRET_PATH=projects/${PROJECT_NUMBER}/secrets/${SECRET_NAME}/versions/1
SECRET_VALUE=$(sed "s/[^a-zA-Z0-9]//g" <<< $(openssl rand -base64 15))
```

2. Create the secret

```
printf ${SECRET_VALUE} | gcloud secrets create ${SECRET_NAME} --data-file=-
```

3. Allow Cloud Build to read the secret

```
gcloud secrets add-iam-policy-binding ${SECRET_NAME} \
  --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com \
  --role='roles/secretmanager.secretAccessor'
```

### Create Cloud Build Trigger

The Cloud Build Trigger is the configuration that will actually be executing the CICD processes.   
The job requires a few key values to be provided on creation in order to properly configure the trigger. 

1. Define the name of the trigger and where the configuration file can be found

```
export TRIGGER_NAME=${APP_NAME}-clouddeploy-webhook-trigger
export BUILD_YAML_PATH=$WORK_DIR/app-templates/golang/build/cloudbuild-build-only.yaml
```

2. Define the location of the shared base configuration repo. 

```
export KUSTOMIZE_REPO=${GIT_BASE_URL}/mcd-shared_kustomize
```

3. A variable was set in the onboard-env.sh script defining the project's container registry. Review the value with the command below. 

```
echo $IMAGE_REPO
```


5. Create CloudBuild Webhook Trigger using the variables created previously. The application repo location is pulled from the body of the request from GitHub. A value below references the path in the request body where it's located

```
    gcloud alpha builds triggers create webhook \
        --name=${TRIGGER_NAME} \
        --substitutions='_APP_NAME='${APP_NAME}',_APP_REPO=$(body.repository.git_url),_CONFIG_REPO='${GIT_BASE_URL}'/'${CLUSTER_CONFIG_REPO}',_DEFAULT_IMAGE_REPO='${IMAGE_REPO}',_KUSTOMIZE_REPO='${GIT_BASE_URL}'/'${SHARED_KUSTOMIZE_REPO}',_REF=$(body.ref)' \
        --inline-config=$BUILD_YAML_PATH \
        --secret=${SECRET_PATH}
```

6. Review the newly created Cloud Build trigger in the Console by [visiting this link](https://console.cloud.google.com/cloud-build/triggers)



### Configure GitHub Webhook

1. Define a variable for the webhook URL

```
WEBHOOK_URL="https://cloudbuild.googleapis.com/v1/projects/${PROJECT_ID}/triggers/${TRIGGER_NAME}:webhook?key=${API_KEY_VALUE}&secret=${SECRET_VALUE}"
```

2. Configure the webhook in GitHub

```
$BASE_DIR/scripts/git/gh.sh create_webhook ${APP_NAME} $WEBHOOK_URL
 
```

3. Go to the application repo and review the newly configured webhook

```
REPO_URL=${GIT_BASE_URL}/${APP_NAME}/settings/hooks
echo $REPO_URL
```

Now that you've manually performed all the steps needed to create a new application it's time to automate it in a script. 

## Automating all the onboarding steps

In practice it's not feasible to execute each of the above steps for every new application. Instead the logic should be incorporated into a script for easy execution. The steps above have already been included in a script for your use. 

In this step you will use the script provided to create a new application

### Create a new application

1. Ensure you're in the right directory

```
cd $BASE_DIR
```

2. Create a new application

The format is `app.sh create <app-name> <template-dir>`
  
```
./app.sh create demo-app golang
```

All of the steps are executed automatically.

### Review the GitHub Repo

At this point you will be able to review the new repository in Github

1. Retrieve the  GitHub repository URL by executing the following command

```
echo ${GIT_BASE_URL}/${APP_NAME}
```

2. Open the URL with your web browser to review the new application
3. Note examples where the template variables have been replace with instance values as shown in the url below

```
echo ${GIT_BASE_URL}/${APP_NAME}/blob/main/k8s/prod/deployment.yaml#L24
```

4. Review the web hook configured at the url below

```
echo ${GIT_BASE_URL}/${APP_NAME}/settings/hooks
```

### Review the CloudBuild Trigger

The trigger was automatically set up by the script 

1. Review the Cloud Build trigger in the Console by [visiting this link](https://console.cloud.google.com/cloud-build/triggers)
2. Review the build history [on this page](https://console.cloud.google.com/cloud-build/builds)
