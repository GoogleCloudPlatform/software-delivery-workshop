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
# Set continuous delivery system as either ACM or Cloud deploy
if [[ ${CONTINUOUS_DELIVERY_SYSTEM} == "" ]]; then
    PS3="Select a Continuous Delivery system: "
    select provider in ACM Clouddeploy; do
        case $provider in
            "ACM")
                echo "you chose ACM";
                export CONTINUOUS_DELIVERY_SYSTEM="ACM"
                break
                ;;
            "Clouddeploy")
                echo "you chose Clouddeploy";
                export CONTINUOUS_DELIVERY_SYSTEM="Clouddeploy"
                break
                ;;
        esac
    done
fi

write_state
