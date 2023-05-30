
# Delivery Platform Demo


## Prerequisites

From the `delivery-platform` directory run the following commands

```shell
gcloud config set project <your_project>
source ./env.sh
export APP_NAME="hello-web"
export TARGET_ENV=dev

```


### Create a new app

This process covers the app onboarding process. In this case it includes copying a template repo to a new app repo, enables policy management for the app in ACM.

This step:
- Copies code from a sample repo
- Updates the name and unique references 
- Creates a new repo for the app team
- Adds entries into ACM for dev, stage, prod
- Performs initial code push and deploys to environments

```shell
./scripts/app.sh create ${APP_NAME} golang
```


### Checkout new app to make changes. 


Clone Repos & open editor
```

git clone -b main $GIT_BASE_URL/${APP_NAME} $WORK_DIR/${APP_NAME}
git clone -b main $GIT_BASE_URL/${SHARED_KUSTOMIZE_REPO} $WORK_DIR/kustomize-base

cd $WORK_DIR/${APP_NAME}
cloudshell workspace $WORK_DIR/${APP_NAME}
```

## Debug on GKE in Cloud Code

In the editor use ctrl/cmd+shift+p to open the command palet and type `Cloud Code: Run on GKE'
Choose the default profile
Choose/type the `dev` cluster for deployment (any will do)
Accept the default image registry `gcr.io/{project}`
Switch to the output tab to watch progress
Click the URL when complete to see the web page

Make a change to line 31 of main.go 
Save and warch the build / deploy complete
Check the web page again

This process can be done locally with minikube instead of GKE as well simply by switching the cluster used


## Deploy to stage

### Review the initial state of stage

open a tunnel
```
kubectx stage \
 && kubectl port-forward --namespace hello-web $(kubectl get pod --namespace hello-web --selector="app=hello-web,role=backend" --output jsonpath='{.items[0].metadata.name}') 8080:8080
```

Review the web page
use the web page preview in the top right of the browser just to the left of your profile. select preview on port 8080

Exit the tunnel
use `ctrl+c` to exit the tunnel


### Commit the code to `main` to trigger the deploy to `stage`

```
git add . 
git commit -m "Updating to V2"
git push origin main
```

review the job progress in the [the build history page](https://console.cloud.google.com/cloud-build/builds)


### Review the changes
open a tunnel
```
kubectx stage \
 && kubectl port-forward --namespace hello-web $(kubectl get pod --namespace hello-web --selector="app=hello-web,role=backend" --output jsonpath='{.items[0].metadata.name}') 8080:8080
```

Review the web page
use the web page preview in the top right of the browser just to the left of your profile. select preview on port 8080

Exit the tunnel
use `ctrl+c` to exit the tunnel


## Release code to prod
Create a release by executing the following command

```bash
git tag v2
git push origin v2
```
Again review the latest job progress in the [the build history page](https://console.cloud.google.com/cloud-build/builds)

When complete review the page live by creating your tunnel


```bash
kubectx prod \
 && kubectl port-forward --namespace hello-web $(kubectl get pod --namespace hello-web --selector="app=hello-web,role=backend" --output jsonpath='{.items[0].metadata.name}') 8080:8080
 ```

And again utilizing the web preview in the top right

When you're done use `ctrl+c` in the terminal to exit out of the tunnel



## Reset

To reset the demo and start over delete the application with the following commands

```
cd $BASE_DIR
cloudshell workspace .
rm -rf $WORK_DIR/hello-web
./scripts/app.sh delete ${APP_NAME} 

```

## Example repo reset
The provision process creates new repos in your git provider for the workshop. In order to use the lastest versions you will need to pull the latest to this local directory then recreate the remote repos using the following commands


```
./resources/provision/repos/teardown.sh
./resources/provision/repos/create-config-repo.sh
./resources/provision/repos/create-template-repos.sh
```

## Complete Teardown
Run the following comand to delete all the infrastructure

```
./resources/provision/teardown-all.sh
```
