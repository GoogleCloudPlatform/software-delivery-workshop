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


# Gitea setup

gcloud compute firewall-rules create "allow-http" --allow=tcp:3000
    --source-ranges="0.0.0.0/0" --description="Allow http"

gcloud compute addresses create gitea-ip
export IP_ADDRESS=$(gcloud compute addresses describe gitea-ip --format="value(address)")

export ADMIN_PASS=$(date +%s | sha256sum | base64 | head -c 8 ; echo)

cat <<EOF > vals.yaml
gitea:
  config:
    server:
      DOMAIN: ${IP_ADDRESS}:3000
  admin:
    username: gitea_admin
    password: ${ADMIN_PASS}
    email: "gitea@local.domain"
service:
  http:
    type: LoadBalancer
    loadBalancerIP: ${IP_ADDRESS}
EOF

helm repo add gitea-charts https://dl.gitea.io/charts/
helm upgrade --install -f vals.yaml gitea gitea-charts/gitea

echo "================================"
echo
echo User: gitea_admin
echo Password: ${ADMIN_PASS}
echo Site: http://${IP_ADDRESS}:3000
echo
echo "================================"