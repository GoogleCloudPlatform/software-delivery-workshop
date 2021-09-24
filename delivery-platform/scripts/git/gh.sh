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

## Input Validation
if [[ ${GIT_TOKEN} == "" ]]; then
    echo "GIT_TOKEN variable not set. Please rerun the env script"
    exit -1
fi
if [[ ${GIT_USERNAME} == "" ]]; then
    echo "GIT_USERNAME variable not set. Please rerun the env script"
    exit -1
fi

if [[ $1 == "create_webhook" ]]; then
    if [[ $2 == "" || $3 == ""  ]]; then
        echo "Missing parameters"
        echo "Usage: gh create_webhook <repo> <webhook_url>"
        exit -1
    fi
fi

if [[ $2 == "" || $1 == "" ]]; then
    echo "Usage: gh <create|delete|create_webhook> <repo>  [webhook_url]"
    exit -1
fi

## Local variables
action=$1
repo=$2
WEBHOOK_URL=$3
GIT_API_BASE="https://api.github.com"

export GIT_ASKPASS=$BASE_DIR/common/ghp.sh

## Execution
create_webhook () {
  curl -H "Authorization: token ${GIT_TOKEN}" \
    -d '{"config": {"url": "'${WEBHOOK_URL}'", "content_type": "json"}}' \
    -X POST ${GIT_API_BASE}/repos/${GIT_USERNAME}/${repo}/hooks 
}


if [[ $action == 'create' ]]; then
    # Create
    curl -H "Authorization: token ${GIT_TOKEN}" ${GIT_API_BASE}/user/repos -d '{"name": "'"${repo}"'"}' > /dev/null
    echo "Created ${repo}"

    #TODO: Check if repo exists first
fi

if [[ $action == 'delete' ]]; then
    # Delete
    echo 
    echo "Deleting ${GIT_API_BASE}/repos/${GIT_USERNAME}/${repo}"
    curl -H "Authorization: token ${GIT_TOKEN}" -X "DELETE" ${GIT_API_BASE}/repos/${GIT_USERNAME}/${repo}
    echo "Deleted ${repo}"
fi

if [[ $action == 'create_webhook' ]]; then
    # Webhook 
    create_webhook
fi

