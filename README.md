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
Cloud Builder

```
export $PROJECT_ID = $PROJECT
gcloud config set core/project $PROJECT_ID



```


Local Cloud Builder

Install the local builder
```
gcloud components install container-builder-local
```

Build locally
```
container-builder-local --config=cloudbuild.yaml --dryrun=false  .

container-builder-local --config cloudbuild-deploy.yaml --dryrun=false  --write-workspace=build_assets  --substitutions=_CLOUDSDK_COMPUTE_ZONE=us-central1-a,_CLOUDSDK_CONTAINER_CLUSTER=cluster-1 .

container-builder-local --config cloudbuild-deploy-patch.yaml --dryrun=false  --write-workspace=build_assets  --substitutions=_CLOUDSDK_COMPUTE_ZONE=us-central1-a,_CLOUDSDK_CONTAINER_CLUSTER=cluster-1,_TAG_NAME=12 .
```



Build in the cloud

```

gcloud container builds submit --config cloudbuild.yaml .

```

For `kubectl` commands against GKE youll need to give Container Builder Service Account container.developer role access on your clusters [details](https://github.com/GoogleCloudPlatform/cloud-builders/tree/master/kubectl).

```
PROJECT="$(gcloud projects describe \
    $(gcloud config get-value core/project -q) --format='get(projectNumber)')"

gcloud projects add-iam-policy-binding $PROJECT \
    --member=serviceAccount:$PROJECT@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer

```


Deploy to GKE

```
gcloud container builds submit --config cloudbuild-deploy.yaml --substitutions=_CLOUDSDK_COMPUTE_ZONE=us-central1-a,_CLOUDSDK_CONTAINER_CLUSTER=cluster-1 .

```

Dev Patch

```
gcloud container builds submit --config cloudbuild-deploy-patch.yaml  --substitutions=_CLOUDSDK_COMPUTE_ZONE=us-central1-a,_CLOUDSDK_CONTAINER_CLUSTER=cluster-1,_TAG_NAME=12 .
```
