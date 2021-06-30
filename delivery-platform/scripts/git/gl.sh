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



if [[ ${GL_TOKEN} == "" ]]; then
    echo "GL_TOKEN variable not set. Please rerun the env script"
    exit -1
fi
if [[ ${GITLAB_USERNAME} == "" ]]; then
    echo "GITLAB_USERNAME variable not set. Please rerun the env script"
    exit -1
fi
if [[ $2 == "" || $1 == "" ]]; then
    echo "Usage: gl <create|delete> <repo> "
    exit -1
fi
action=$1
repo=$2
user=$GITLAB_USERNAME
token=${GL_TOKEN}
base=https://gitlab.com/api/v4



if [[ $action == 'create' ]]; then
    # Create
    curl -H "Private-Token: ${token}" -H "Content-Type:application/json" ${base}/projects/ -d '{"name":"'$repo'"}'  > /dev/null
    echo "\nCreated ${repo}"

    #TODO: Check if repo exists first
fi

if [[ $action == 'delete' ]]; then
    # Delete
    echo "Deleting ${user}%2f${repo}"
    curl -H "Private-Token: ${token}" -X "DELETE" ${base}/projects/${user}%2f${repo} 
    echo "\nDeleted ${repo}"
fi
