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


source ${BASE_DIR}/scripts/common/manage-state.sh
# Set Git provider as either GitHub, GitLab, or Cloud Source Repository
if [[ ${GIT_PROVIDER} == "" ]]; then
    PS3="Select a Git Provider: "
    select provider in GitHub GitLab Cloud-Source-Repository; do
        case $provider in
            "GitHub")
                echo "you chose GitHub";
                export GIT_PROVIDER=GitHub
                export GIT_CMD=gh.sh
                break
                ;;
            "GitLab")
                echo "you chose GitLab";
                export GIT_PROVIDER=GitLab
                export GIT_CMD=gl.sh
                break
                ;;
            "Cloud-Source-Repository")
                echo "you chose Cloud Source Repository";
                export GIT_PROVIDER=Cloud-Source-Repository
                export GIT_CMD=gcsr.sh
                break
                ;;
        esac
    done
fi


# Set Username to use with git
if [[ ${GIT_USERNAME} == "" ]] && [[ ${GIT_PROVIDER} != "Cloud-Source-Repository" ]]; then
    printf "Enter your ${GIT_PROVIDER} username: " && read ghusername
    export GIT_USERNAME=${ghusername}
fi



# Set Personal Access Tokens to use for operations
if [[ ${GIT_TOKEN} == "" ]] && [[ ${GIT_PROVIDER} != "Cloud-Source-Repository" ]]; then

    if [[ ${GIT_PROVIDER} == "GitHub" ]]; then
        echo ""
        echo "No Github token found. Please generate a token from the following URL and paste it below."
        echo "https://github.com/settings/tokens/new?scopes=repo%2Cread%3Auser%2Cread%3Aorg%2Cuser%3Aemail%2Cwrite%3Arepo_hook%2Cdelete_repo"
        printf "Paste your token here and press enter: " && read ghtoken
        export GIT_TOKEN=${ghtoken}
    fi

    if [[ ${GIT_PROVIDER} == "GitLab" ]]; then
        echo ""
        echo "No GitLab token found. Please generate a token from the GitLab UI"
        echo 'Provide a name and choose the "API" scope from the following URL:'
        echo "https://gitlab.com/profile/personal_access_tokens"
        printf "Once completed paste your token here and press enter: " && read ghtoken
        export GIT_TOKEN=${ghtoken}
    fi
fi


# Set Git URL 
if [[ ${GIT_PROVIDER} == "GitHub" ]]; then
    export GIT_BASE_URL=https://${GIT_USERNAME}@github.com/${GIT_USERNAME}
fi

if [[ ${GIT_PROVIDER} == "GitLab" ]]; then
    export GIT_BASE_URL=https://${GIT_USERNAME}@gitlab.com/${GIT_USERNAME}
fi

if [[ ${GIT_PROVIDER} == "Cloud-Source-Repository" ]]; then
    if [[ ${PROJECT_ID} == "" ]]; then
        echo ""
        echo "PROJECT_ID is not set. Please make sure to source the env.sh script."
        exit -1
    fi
    export GIT_BASE_URL=https://source.developers.google.com/p/${PROJECT_ID}/r/
fi

write_state
