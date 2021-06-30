
# Provision Platform Infrastructure

```shell
gcloud config set project <YOUR_PROJECT>
source ./env.sh
${BASE_DIR}/resources/provision/provision-all.sh
```

# Cleanup

```shell
gcloud config set project <YOUR_PROJECT>
source ./env.sh
${BASE_DIR}/resources/provision/teardown-all.sh
```