# Software Delivery Workshop


This repository contains resources and materials targeted toward Software Delivery on Google Cloud. In addition to separate stand alone guides, an opinionated yet modular platform is provided to demonstrate software delivery practices. It contains scripts to standup a base platform infrastructure as well as other resources designed to facilitate hands on workshop and standard demo use cases. The platform provisioning resources are structured to be modular in nature supporting various runtime and tooling configurations. Ideally users can utilize their own choice of tooling for: Provisioning, Source Code Management, Templating, Build Engine, Image Storage and Deploy tooling. 


## Usage

This set of resources contains materials to provision the platform, deliver short demonstrations and facilitate hands on workshops. 

### Workshop
The Software Delivery Workshop contains materials for a self led exploration or accompanying instructor led sessions. To get started click the button below to open the resources in Google Cloud Shell. 

[![Software Delivery Workshop](http://www.gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/software-delivery-workshop.git&cloudshell_workspace=.&cloudshell_tutorial=delivery-platform/docs/workshop/1.2-provision.md)


If at any time during the workshop you somehow exit out of the lab instructions, you can relaunch the lab using the related command below:

```
teachme "${BASE_DIR}/docs/workshop/1.2-provision.md"
teachme "${BASE_DIR}/docs/workshop/1.3-kustomize.md"
teachme "${BASE_DIR}/docs/workshop/2.1-app-onboarding.md"
teachme "${BASE_DIR}/docs/workshop/2.2-develop.md"
teachme "${BASE_DIR}/docs/workshop/3.2-release-progression.md"

```

If at anytime you lose your terminal session, ensure you are in the `software-delivery-workshop/delivery-platform` directory then run the following commands to reset your environment variables. 


```shell
gcloud config set project <YOUR_PROJECT>
source ./env.sh
```

### Demo
For a mostly automated experience follow the instructions in the `docs\demo` folder. You will run an automated script to fully provision the platform before your demonstration. A separate guide describes the steps to perform during the demonstration and concludes with instructions how to reset the demo or tear down the infrastructure. 

### Provision

If you just want to install the base platform and run your own exercises and workloads, run the following commands from within the `delivery-platform` directory.

```shell
gcloud config set project <YOUR_PROJECT>
source ./env.sh
${BASE_DIR}/resources/provision/provision-all.sh
```


