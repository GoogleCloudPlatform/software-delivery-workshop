# Hydrating with Kustomize 

Kustomize is a tool that introduces a template-free way to customize application configuration, simplifying the use of off-the-shelf applications. It's available as a stand alone utility and is built into kubectl through `kubectl apply -k` of can be used as a stand alone CLI. For additional details read more at [kustomize.io](https://kustomize.io/).
## Objectives

In this tutorial you work through some of the core concepts of Kustomize and use it to manage variations in the applications and environments. 

You will:

-  Utilize kustomize command line client
-  Override common elements
-  Patch larger yaml structures
-  Utilize multiple layers of overlays 

## Preparing your workspace

1. Open Cloud Shell editor by visiting the following url 

```
https://ide.cloud.google.com
```

2. In the terminal window create a working directory for this tutorial 

```
mkdir kustomize-lab
```

3. Change into the directory and set the IDE workspace 

```
cd kustomize-lab && cloudshell workspace .
```

## Utilizing kustomize command line client

The power of kustomize comes from the ability to overlay and modify base Kubernetes yamls with custom values. In order to do this kustomize requires a base file with instructions on where the files are and what to override. Kustomize is included in the Kubernetes ecosystem and can be executed through various methods. 

In this section you will create a base kustomize configuration and process the files with the stand alone kustomize command line client. 

1. To start, you will create a folder to hold your base configuration files

```
mkdir -p chat-app/base
```

2. Create a simple kubernetes ``deployment.yaml`` in the base folder 

```
cat <<EOF > chat-app/base/deployment.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: app
spec:
  template:
    metadata:
      name: chat-app
    spec:
      containers:
      - name: chat-app
        image: chat-app-image
EOF
```

3. Create the base `kustomization.yaml`

   Kustomize looks for a file called kustomization.yaml as an entry point. This file contains references to the various base and override files as well as specific override values. 

   Create a `kustomization.yaml` file that references the `deployment.yaml` as the base resources. 
```
cat <<EOF > chat-app/base/kustomization.yaml
bases:
  - deployment.yaml
EOF
```

4. Run the kustomize command on the base folder. Doing so outputs the deployment YAML files with no changes, which is expected since you haven't included any variations yet.

```
kustomize build chat-app/base
```

This standalone client can be combined with the kubectl client to apply the output directly as in the following example. Doing so streams the output of the build command directly into the kubectl apply command. 

(Do Not Execute - Included for reference only)

<pre>
kustomize build chat-app/base | kubectl apply -f -
</pre>

This technique is useful if a specific version of the kustomize client is needed.  

Alternatively kustomize can be executed with the tooling integrated within kubectl itself. As in the following example.

(Do Not Execute - Included for reference only)

<pre>
kubectl apply -k chat-app/base
</pre>

## Overriding common elements

Now that your workspace is configured and you verified kustomize is working, it's time to override some of the base values. 

Images, namespaces and labels are very commonly customized for each application and environment. Since they are commonly changed, Kustomize lets you declare them directly in the `kustomize.yaml`, eliminating the need to create many patches for these common scenarios.

This technique is often used to create a specific instance of a template. One base set of resources can now be used for multiple implementations by simply changing the name and its namespace. 

In this example, you will add a namespace, name prefix and add some labels to your `kustomization.yaml`.

1. Update the `kustomization.yaml` file to include common labels and namespaces.

   Copy and execute the following commands in your terminal

```
cat <<EOF > chat-app/base/kustomization.yaml
bases:
  - deployment.yaml

namespace: my-namespace
nameprefix: my-
commonLabels:
  app: my-app

EOF
```

2. Execute the build command

   Executing the build at this point shows that the resulting YAML file now contains the namespace, labels and prefixed names in both the service and deployment definitions.

```
kustomize build chat-app/base
```

Note how the output contains labels and namespaces that are not in the deployment YAML file. Note also how the name was changed from `chat-app` to `my-chat-app`

(Output do not copy)
<pre>
kind: Deployment
metadata:
  labels:
    app: my-app
  name: my-chat-app
  namespace: my-namespace
</pre>

## Patching larger yaml structures

Kustomize also provides the ability to apply patches that overlay the base resources. This technique is often used to provide variability between applications and environments. 

In this step, you will create environment variations for a single application that use the same base resources. 

1. Start by creating folders for the different environments

```
mkdir -p chat-app/dev
mkdir -p chat-app/prod
```



2. Write the stage patch with the following command

```
cat <<EOF > chat-app/dev/deployment.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: chat-app
        env:
        - name: ENVIRONMENT
          value: dev
EOF
```

3. Now Write the prod patch with the following command

```
cat <<EOF > chat-app/prod/deployment.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: chat-app
        env:
        - name: ENVIRONMENT
          value: prod
EOF
```

Notice that the patches above do not contain the container image name. That value is provided in the base/deployment.yaml you created in the previous step. These patches do however contain unique environment variables for dev and prod. 

4. Implement the kustomize YAML files for the base directory 

Rewrite the base kustomization.yaml, remove the namespace and name prefix as this is just the base config with no variation. Those fields will be moved to the environment files in just a moment. 

```
cat <<EOF > chat-app/base/kustomization.yaml
bases:
  - deployment.yaml

commonLabels:
  app: chat-app

EOF
```
5. Implement the kustomize YAML files for the dev directory 

Now implement the variations for dev and prod by executing the following commands in your terminal.

```
cat <<EOF > chat-app/dev/kustomization.yaml
bases:
- ../base

namespace: dev
nameprefix: dev-
commonLabels:
  env: dev

patches:
- deployment.yaml
EOF
```

Note the addition of the `patches`:  section of the file. This indicates that kustomize should overlay those files on top of the base resources. 

6. Implement the kustomize YAML files for the prod directory 

```
cat <<EOF > chat-app/prod/kustomization.yaml
bases:
- ../base

namespace: prod
nameprefix: prod-
commonLabels:
  env: prod

patches:
- deployment.yaml
EOF
```

7. Run kustomize to merge the files
With the base and environment files created, you can execute the kustomize process to patch the base files.

   Run the following command for dev to see the merged result.

```
kustomize build chat-app/dev
```

Note the output contains merged results such as labels from base and dev configurations as well as the container image name from the base and the environment variable from the dev folders. 


## Utilizing multiple layers of overlays

Many organizations have a team that helps support the app teams and manage the platform. Frequently these teams will want to include specific details that are to be included in all apps across all environments, such as a logging agent.  

In this example, you will create a `shared-kustomize` folder and resources which will be included by all applications and regardless of which environment they're deployed. 

1. Create the shared-kustomize folder

```
mkdir shared-kustomize
```

2. Create a simple `deployment.yaml` in the shared folder


```
cat <<EOF > shared-kustomize/deployment.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: logging-agent
        image: logging-agent-image
EOF
```

3. Create a kustomization.yaml in the shared folder

```
cat <<EOF > shared-kustomize/kustomization.yaml
bases:
  - deployment.yaml
EOF
```

4. Reference the shared-kustomize folder from your application

Since you want the `shared-kustomize` folder to be the base for all your applications, you will need to update your `chat-app/base/kustomization.yaml` to use `shared-kustomize` as the base. Then patch its own deployment.yaml on top. The environment folders will then patch again on top of that. 

Copy and execute the following commands in your terminal

```
cat <<EOF > chat-app/base/kustomization.yaml
bases:
  - ../../shared-kustomize

commonLabels:
  app: chat-app

patches:
- deployment.yaml

EOF
```

5. Run kustomize and view the merged results for dev


```
kustomize build chat-app/dev
```

Note the output contains merged results from the app base, the app environment, and the `shared-kustomize` folders. Specifically, you can see in the containers section values from all three locations.

(output do not copy)  
<pre>

```
    containers:
          - env:
            - name: ENVIRONMENT
              value: dev
            name: chat-app
          - image: image
            name: app
          - image: logging-agent-image
            name: logging-agent
```

</pre>


