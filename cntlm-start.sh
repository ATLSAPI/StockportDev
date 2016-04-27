#!/bin/bash

echo "Setting ENV variables for cntlm..."
export DOCKER_HTTP_PROXY=http://10.0.2.2:3128
export DOCKER_HTTPS_PROXY=http://10.0.2.2:3128
export DOCKER_NO_PROXY=192.168.99.*,*.local.dev
source ./start.sh