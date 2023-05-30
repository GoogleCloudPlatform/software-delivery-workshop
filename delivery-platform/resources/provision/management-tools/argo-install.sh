#!/usr/bin/env bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARGOCD_VERSION="v1.8.7"

gcloud container clusters get-credentials dev --region us-west1-a --project $PROJECT_ID
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml
echo Waiting for Argo install...
kubectl wait --for=condition=ready pod -n argocd -l app.kubernetes.io/name=argocd-server --timeout=60s

curl -sSL -o ${WORK_DIR}/bin/argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64
chmod 755 ${WORK_DIR}/bin/argocd

USER=admin
PASSWORD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
PORT_FWD_PID=$!

# Argo UI http://localhost:8080
argocd login localhost:8080 --insecure --username=$USER --password=$PASSWORD

argocd cluster add dev
argocd cluster add stage
argocd cluster add prod
kill $PORT_FWD_PID

echo --- Note: some errors are seen in argo install output. 
echo     You can ignore the following
echo         FATA[0000] dial tcp [::1]:8080: connect: connection refused
echo         FATA[0001] rpc error: code = Unauthenticated desc = invalid session: token signature is invalid 
echo 
echo Argo install completed
