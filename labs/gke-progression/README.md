# Continuous deployment to Google Kubernetes Engine (GKE) with Cloud Build




## Overview


In this lab, you'll learn to set up a continuous delivery pipeline for GKE with Cloud Build. You'll complete the following steps:

* Create the GKE Application
* Automate deployments for git branches
* Automate deployments for git main branch
* Automating deployments for git tags


## Preparing your environment

1.  In Cloud Shell, create environment variables to use throughout this tutorial:

    ```sh
    export PROJECT_ID=$(gcloud config get-value project)
    export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')


    export ZONE=us-central1-b
    export CLUSTER=gke-progression-cluster
    export APP_NAME=myapp
    ```

2.  Enable the following APIs:

    - Resource Manager
    - GKE
    - Cloud Source Repositories
    - Cloud Build
    - Container Registry



    ```sh
    gcloud services enable \
        cloudresourcemanager.googleapis.com \
        container.googleapis.com \
        sourcerepo.googleapis.com \
        cloudbuild.googleapis.com \
        containerregistry.googleapis.com \
        --async
    ```


3.  Clone the sample source:

    ```sh
    git clone https://github.com/GoogleCloudPlatform/software-delivery-workshop.git gke-progression

    cd gke-progression/labs/gke-progression
    rm -rf ../../.git
    ```

4.  Replace placeholder values in the sample repository with your `PROJECT_ID`:

    ```sh
    for template in $(find . -name '*.tmpl'); do envsubst '${PROJECT_ID} ${ZONE} ${CLUSTER} ${APP_NAME}' < ${template} > ${template%.*}; done
    ```

5.  Store the code from the sample repository in CSR:

    ```sh
    gcloud source repos create gke-progression
    git init
    git config credential.helper gcloud.sh
    git remote add gcp https://source.developers.google.com/p/$PROJECT_ID/r/gke-progression
    git branch -m main
    git add . && git commit -m "initial commit"
    git push gcp main
    ```

6. Create your GKE cluster.

    ```sh
    gcloud container clusters create ${CLUSTER} \
        --project=${PROJECT_ID} \
        --zone=${ZONE} 
    ```


7. Give Cloud Build rights to your cluster.
    ```sh
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
        --role=roles/container.developer
    ```

Your environment is ready!


## Creating your GKE Application

In this section, you build and deploy the initial production application that you use throughout this tutorial.

1.  Build the application with Cloud Build:

    ```sh
    gcloud builds submit --tag gcr.io/$PROJECT_ID/$APP_NAME:1.0.0 src/
    ```

2.  Manually deploy to Canary and Production environments:


    Create the production and canary deployments and services using the `kubectl apply` commands.

    ```console
    kubectl create ns production
    kubectl apply -f k8s/deployments/prod -n production
    kubectl apply -f k8s/deployments/canary -n production
    kubectl apply -f k8s/services -n production
    ```


3. Review number of running pods

    Confirm that you have four Pods running for the frontend, including three for production traffic and one for canary releases. That means that changes to your canary release will only affect 1 out of 4 (25%) of users. 


    ```console
    kubectl get pods -n production -l app=$APP_NAME -l role=frontend
    ```


4. Retrieve the external IP address for the production services.
    
    > **Note:** It can take several minutes before you see the load balancer external IP address.
    
    ```sh
    kubectl get service $APP_NAME -n production
    ```
    
    Once the load balancer returns the IP address continue to the next step

5. Store the external IP for later use.
    
    ```sh
    export PRODUCTION_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services $APP_NAME)
    ```

6. Review the application 
    
    Check the version output of the service. It should read Hello World v1.0

    ```sh
    curl http://$PRODUCTION_IP
    ```

Congratulations! You deployed the sample app! Next, you'll set up a pipeline for continuously and deploying your changes.





## Automating deployments for git branches

1.  Set up the trigger:

    ```sh
    gcloud beta builds triggers create cloud-source-repositories \
      --trigger-config build/branch-trigger.json
    ```

2.  To review the trigger, go to the
    [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers)
    in the Console.

    [Go to Triggers](https://console.cloud.google.com/cloud-build/triggers)

3.  Create a new branch:

    ```sh
    git checkout -b new-feature-1
    ```

4.  Modify the code to indicate v1.1 

    Edit `src/app.py` and change the response from 1.0 to 1.1

    ```py
    @app.route('/')
    def hello_world():
        return 'Hello World v1.1'
    ```

5.  Commit the change and push to the remote repository:

    ```sh
    git add . && git commit -m "updated" && git push gcp new-feature-1
    ```


6.  To review the build in progress, go to the
    [Cloud Build Builds page](https://console.cloud.google.com/cloud-build/builds)
    in the Console.

    [Go to Builds](https://console.cloud.google.com/cloud-build/builds)

    Once the build completes continue to the next step

7. Retrieve the external IP address for the newly deployed branch service.
    
    > **Note:** It can take several minutes before you see the load balancer external IP address.
    
    ```sh
    kubectl get service $APP_NAME -n new-feature-1
    ```
    
    Once the load balancer returns the IP address continue to the next step

5. Store the external IP for later use.
    
    ```sh
    export BRANCH_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=new-feature-1 services $APP_NAME)
    ```

6. Review the application 
    
    Check the version output of the service. It should read Hello World v1.0

    ```sh
    curl http://$BRANCH_IP
    ```

## Automate deployments for git main branch


When code is released to production, it's common to release code to a small subset of live traffic before migrating all traffic to the new code base.

In this section, you implement a trigger that is activated when code is committed to the main branch. The trigger deploys the code to a unique canary URL and it routes 10% of all live traffic to the new revision.

1.  Set up the trigger for the main branch:

    ```sh
    gcloud beta builds triggers create cloud-source-repositories \
      --trigger-config build/main-trigger.json
    ```

2.  To review the new trigger, go to the
    [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers)
    in the Console.

    [Go to Triggers](https://console.cloud.google.com/cloud-build/triggers)


3.  Merge the branch to the main line and push to
    the remote repository:

    ```sh
    git checkout main
    git merge new-feature-1
    git push gcp main
    ```

4.  To review the build in progress, go to the
    [Cloud Build Builds page](https://console.cloud.google.com/cloud-build/builds)
    in the Console.

    [Go to Builds](https://console.cloud.google.com/cloud-build/builds)

    Once the build has completed continue to the next step

5. Review mulitple responses from the server

    Run the following command and note that approxomatly 25% of the responses are showing the new response of Hello World v1.1

    ```sh
    while true; do curl -w "\n" http://$PRODUCTION_IP; sleep 1;  done
    ```

    When you're ready to continue pres `Ctrl+c` to exit out of the loop. 


## Automating deployments for git tags

After the canary deployment is validated with a small subset of traffic, you release the deployment to the remainder of the live traffic. 

In this section, you set up a trigger that is activated when you create a tag in the repository. The trigger labels the image with the appropriate tag then deploys the updates to prod ensuring 100% of traffic is accessing the tagged image. 

1.  Set up the tag trigger:

    ```sh
    gcloud beta builds triggers create cloud-source-repositories \
      --trigger-config build/tag-trigger.json
    ```

2.  To review the new trigger, go to the
    [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers)
    in the Console.

    [Go to Triggers](https://console.cloud.google.com/cloud-build/triggers)

3.  Create a new tag and push to the remote repository:

    ```sh
    git tag 1.1
    git push gcp 1.1
    ```
4.  To review the build in progress, go to the
    [Cloud Build Builds page](https://console.cloud.google.com/cloud-build/builds)
    in the Console.

    [Go to Builds](https://console.cloud.google.com/cloud-build/builds)


5. Review mulitple responses from the server

    Run the following command and note that 100% of the responses are showing the new response of Hello World v1.1

    This may take a moment as the new pods are deployed and health checked within GKE

    ```sh
    while true; do curl -w "\n" http://$PRODUCTION_IP; sleep 1;  done
    ```

    When you're ready to continue pres `Ctrl+c` to exit out of the loop. 
    

    Congratulations! You created CI/CD triggers in Cloud Build for branches and tags to deploy your apps to GKE.