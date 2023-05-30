# Understanding Skaffold

[Skaffold](https://skaffold.dev/) is a tool that handles the workflow for
building, pushing and deploying your application. You can use Skaffold to
easily configure a local development workspace, streamline your inner
development loop, and integrate with other tools such as
[Kustomize](kustomize.dev) and [Helm](https://helm.sh/) to help manage your
Kubernetes manifests.

## Objectives

In this tutorial you work through some of the core concepts of Skaffold, use it
to automate your inner development loop, then deploy an application.

You will:

- Configure and enable Skaffold for local development
- Build and run a simple golang application
- Manage local application deployment with Skaffold
- Render manifests and deploy your application

## Preparing your workspace

1. Open the Cloud Shell editor by visiting the following url:

```
https://shell.cloud.google.com
```

2. If you have not done so already, in the terminal window clone the application source with the following command:

```
git clone https://github.com/GoogleCloudPlatform/software-delivery-workshop.git
```

3. Change into the cloned repository directory:

```
cd software-delivery-workshop/labs/understanding-skaffold/getting-started
```

4. Set your Cloud Shell workspace to the current directory by running the following command:

```
cloudshell workspace .
```

## Preparing your project

1. Ensure your Google Cloud project is set correctly by running the following command:

```
gcloud config set project {{project-id}}
```

## Getting started with Skaffold

1. Run the following command to create the top-level Skaffold configuration file, `skaffold.yaml`:

```
cat <<EOF > skaffold.yaml
apiVersion: skaffold/v2beta21
kind: Config
metadata:
  name: getting-started-kustomize
build:
  tagPolicy:
    gitCommit:
      ignoreChanges: true
  artifacts:
  - image: skaffold-kustomize
    context: app
    docker:
      dockerfile: Dockerfile
deploy:
  kustomize:
    paths:
    - overlays/dev
profiles:
- name: staging
  deploy:
    kustomize:
      paths:
      - overlays/staging
- name: prod
  deploy:
    kustomize:
      paths:
      - overlays/prod
EOF
```

2. Open the file `skaffold.yaml` in the IDE pane. This is the top-level configuration file that defines the tSkaffold pipeline.

Notice the Kubernetes-like YAML format and the following sections in the YAML:

  - `build`
  - `deploy`
  - `profiles`

These sections define how the application should be built and deployed, as well as profiles for each deployment target.

You can read more about the full list of Skaffold stages in the Skaffold Pipeline Stages [documentation](https://skaffold.dev/docs/pipeline-stages).

# Build

The `build` section contains configuration that defines how the application
should be built. In this case you can see configuration for how `git` tags
should be handled, as well as an `artifacts` section that defines the container
images, that comprise the application.

As well as this, in this section you can see the reference to the `Dockerfile`
to be used to build the images. Skaffold additionally supports other build
tools such as `Jib`, `Maven`, `Gradle`, Cloud-native `Buildpacks`, `Bazel` and
custom scripts. You can read more about this configuration in the [Skaffold
Build documentation]().

# Deploy

The `deploy` section contains configuration that defines how the application
should be deployed. In this case you can see an example for a default
deployment that configures Skaffold to use the the
[`Kustomize`](https://kustomize.io/) tool.

The `Kustomize` tool provides functionality for generating Kubernetes manifests
by combining a set of common component YAML files (under the `base` directory)
with a one or more "overlays" that typically correspond to one or more
deployment targets -- typically *dev*, *test*, *staging* and *production* or
similar.

In this example you can see two overlays for three targets, *dev*, *staging*
and *prod*. The *dev* overlay will be used during local development and the
*staging* and *prod* overlays for when deploying using Skaffold.

# Profiles

The `profiles` section contains configuration that defines build, test and
deployment configurations for different contexts. Different contexts are
typically different environments in your application deployment pipeline, like
`staging` or `prod` in this example. This means that you can easily manage
manifests whose contents need to differ for different target environments,
without repeating boilerplate configuration.

Configuration in the `profiles` sectionm can replace or patch any items from
the main configuration (i.e. the `build`, `test` or `deploy` sections, for
example).

As an example of this, open the file `overlays > prod > deployment.yaml`.
Notice that the number of replicas for the application is configured here to be
three, overriding the base configuration.

# Navigating the application source code.

1. Open the following file `app > main.go` in the IDE pane. This is a simple
   golang application that writes a string to `stdout` every second.

2. Notice that the application also outputs the name of the Kubernetes pod in which it it running.

# Viewing the Dockerfile

1. Open the file `app > Dockerfile` in the IDE pane. This file contains a
   sequence of directives to build the application container image for the
   `main.go` file, and is referenced in the top-level `skaffold.yaml` file.

## Configuring your Kubernetes environment

1. Run the following command to ensure your local Kubernetes cluster is running and configured:

```
minikube start
```

The may take several minutes. You should see the following output if the cluster has started successfully:
```
Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

2. Run the following command to create Kubernetes namespaces for `dev`, `staging` and `prod`:

```
kubectl apply -f namespaces.yaml
```

You should see the following output:

```
namespace/dev created
namespace/staging created
namespace/prod created
```

## Using Skaffold for local development

1. Run the following command to build the application and deploy it to a local Kubernetes cluster running in Cloud Shell:

```
skaffold dev
```

You should see the application container build process run, which may take a
minute, and then the application output repeating every second:

```
[skaffold-kustomize] Hello world from pod skaffold-kustomize-dev-xxxxxxxxx-xxxxx
```

Note that the exact pod name will vary from the generic output given above.

## Making changes to the application

Now that the application is running in your local Kubernetes cluster, you can
make changes to the code, and Skaffold will automatically rebuild and redeploy
the application to the cluster.

1.  Open the file `app > main.go` in the IDE pane, and change the output string:

```
"Hello world from pod %s!\n"
```

  to:

```
"Hello Skaffold world from pod %s!\n"
```

When you have made the change you should see Skaffold rebuild the image and redeploy it to the cluster, with the change in output visibile in the terminal window.

2. Now, also in the file "app > main.go" in the IDE pane, change the line:

```
time.Sleep(time.Second * 1)
```

  to

```
time.Sleep(time.Second * 10)
```

Again you should see the application rebuilt and redeployed, with the output line appearing once every 10 seconds.

## Making changes to the Kubernetes config

Next you will make a change to the Kubernetes config, and once more Skaffold will automatically redeploy.

1. Open the file `base > deployment.yaml` in the IDE and change the line:

```
replicas: 1
```

to

```
replicas: 2
```

Once the application has been redeployed, you should see two pods running -- each will have a different name.

2. Now, change the same line in the file `base > deployment.yaml` back to:

```
replicas: 1
```

You should see one of the pods removed from service so that only one is remaining.

3. Finally, press `Ctrl-C` in the terminal window to stop Skaffold local development.

## Cutting a release

Next, you will create a release by building a release image, and deploying it to a cluster.

1. Run the following command to build the release:

```
skaffold build --file-output artifacts.json
```

This command will build the final image (if necessary) and output the release details to the `artifacts.json` file.

If you wanted to use a tool like Cloud Deploy to deploy to your clusters, this
file contains the release information. This means that the artifact(s) are
immutable on the route to live.

2. Run the following command to view the contents of the `artifacts.json` file:

```
cat artifacts.json | jq
```

Notice that the file contains the reference to the image that will be used in the final deployment. 

## Deploying to staging

1. Run the following command to deploy the release using the `staging` profile:

```
skaffold deploy --profile staging --build-artifacts artifacts.json --tail
```

Once deployment is complete you should see output from three pods similar to the following:

```
[skaffold-kustomize] Hello world from pod skaffold-kustomize-staging-xxxxxxxxxx-xxxxx!
```

2. Press Ctrl-C in the terminal window to stop Skaffold output.

3. Run the following command to observe your application up and running in the cluster:

```
kubectl get all --namespace staging
```

You should see two distinct pod names, because the `staging` profile for the application specifies there should be two replicas in the deployment.

## Deploying to production

1. Now run the following command to deploy the release using the `prod` profile:

```
skaffold deploy --profile prod --build-artifacts artifacts.json --tail
```

Once deployment is complete you should see output from three pods similar to the following:

```
[skaffold-kustomize] Hello world from pod skaffold-kustomize-prod-xxxxxxxxxx-xxxxx!
```

2. Press Ctrl-C in the terminal window to stop Skaffold output.

You should see three distinct pod names, because the `prod` profile for the application specifies there should be three replicas in the deployment.

3. Run the following command to observe your application up and running in the cluster:

```
kubectl get all --namespace prod
```

You should see output that contains lines similar to the following that show the prod deployment:

```
NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/skaffold-kustomize-prod   3/3     3            3           16m
```

You should also see three application pods running.

```
NAME                                           READY   STATUS    RESTARTS   AGE
pod/skaffold-kustomize-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          10m
pod/skaffold-kustomize-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          10m
pod/skaffold-kustomize-prod-xxxxxxxxxx-xxxxx   1/1     Running   0          10m
```

## Cleaning up

1. Run the following command to shut down the local cluster:

```
minikube delete
```

## Finishing up

Congratulations! You have completed the `Understanding Skaffold` lab and have learned how to configure and use Skaffold for local development and application deployment.

