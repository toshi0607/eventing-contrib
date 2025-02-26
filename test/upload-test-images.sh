#!/usr/bin/env bash
#
# Copyright 2018 The Knative Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# If gcloud is not available make it a no-op, not an error.
which gcloud &> /dev/null || gcloud() { echo "[ignore-gcloud $*]" 1>&2; }

set -o errexit

function upload_test_images() {
  echo ">> Publishing test images"
  local image_dirs="$(find $(dirname $0)/test_images -mindepth 1 -maxdepth 1 -type d)"
  local docker_tag=$1

  for image_dir in ${image_dirs}; do
      local image_name="$(basename ${image_dir})"
      local image="knative.dev/eventing-contrib/test/test_images/${image_name}"
      ko publish -B ${image}
      if [ -n "$docker_tag" ]; then
          image=$KO_DOCKER_REPO/${image_name}
          local digest=$(gcloud container images list-tags --filter="tags:latest" --format='get(digest)' ${image})
          echo "Tagging ${image}@${digest} with $docker_tag"
          gcloud -q container images add-tag ${image}@${digest} ${image}:$docker_tag
      fi
  done
}

: ${KO_DOCKER_REPO:?"You must set 'KO_DOCKER_REPO', see DEVELOPMENT.md"}

upload_test_images $@
