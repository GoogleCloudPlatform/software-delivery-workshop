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


function load_state() {
    mkdir -p $WORK_DIR
    touch $WORK_DIR/state.env
    source $WORK_DIR/state.env
}

function write_state() {
    mkdir -p $WORK_DIR
    rm -f $WORK_DIR/state.env
    echo "# Updated $(date)" > $WORK_DIR/state.env
    echo "export GIT_PROVIDER=${GIT_PROVIDER}" >> $WORK_DIR/state.env
    echo "export GIT_USERNAME=${GIT_USERNAME}" >> $WORK_DIR/state.env
    echo "export GIT_TOKEN=${GIT_TOKEN}" >> $WORK_DIR/state.env
    echo "export GIT_BASE_URL=${GIT_BASE_URL}" >> $WORK_DIR/state.env
    echo "export GIT_CMD=${GIT_CMD}" >> $WORK_DIR/state.env
    echo "export API_KEY_VALUE=${API_KEY_VALUE}" >> $WORK_DIR/state.env
    echo "export CONTINUOUS_DELIVERY_SYSTEM=${CONTINUOUS_DELIVERY_SYSTEM}" >> $WORK_DIR/state.env
    
}
