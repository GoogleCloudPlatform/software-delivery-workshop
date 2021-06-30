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


action=$1
repo=$2
base=https://source.developers.google.com/p/${PROJECT_ID}/r/

if [[ $action == 'create' ]]; then
    # Create
    gcloud source repos create ${repo}
    echo "Created ${repo}"
fi

if [[ $action == 'delete' ]]; then
    # Delete
    echo "Deleting https://source.developers.google.com/p/${PROJECT_ID}/r/${repo}"
    gcloud source repos delete ${repo} --quiet
    echo "Deleted ${repo}"
fi


