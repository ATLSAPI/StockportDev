#!/usr/bin/env bash

trap '[ "$?" -eq 0 ] || read -p "Looks like something went wrong in step ´$STEP´... Press return key to continue..."' EXIT

VM=${DOCKER_MACHINE_NAME-default}

BLUE='\033[1;34m'
GREEN='\033[0;32m'
NC='\033[0m'

VBoxManage list vms | grep \""${VM}"\" &> /dev/null
VM_EXISTS_CODE=$?

set -e

STEP="Checking if machine $VM exists"
if [ $VM_EXISTS_CODE -eq 1 ]; then
  docker-machine rm -f "${VM}" &> /dev/null || :
  rm -rf ~/.docker/machine/machines/"${VM}"

  #set proxy variables if they exists
  if [ -n "${DOCKER_HTTP_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTP_PROXY=$DOCKER_HTTP_PROXY"
  elif [ -n "${HTTP_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTP_PROXY=$HTTP_PROXY"
  fi

  if [ -n "${DOCKER_HTTPS_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTPS_PROXY=$DOCKER_HTTPS_PROXY"
  elif [ -n "${HTTPS_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env HTTP_PROXY=$HTTPS_PROXY"
  fi

  if [ -n "${DOCKER_NO_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env NO_PROXY=$DOCKER_NO_PROXY"
  elif [ -n "${NO_PROXY}" ]; then
    PROXY_ENV="$PROXY_ENV --engine-env NO_PROXY=$NO_PROXY"
  fi

  docker-machine create -d virtualbox $PROXY_ENV "${VM}"

fi

STEP="Checking status on $VM"
VM_STATUS="$(docker-machine status ${VM} 2>&1)"
if [ "${VM_STATUS}" != "Running" ]; then
  docker-machine start "${VM}"
  yes | docker-machine regenerate-certs "${VM}"
fi

STEP="Setting env"
eval "$(docker-machine env --shell=bash ${VM})"

STEP="Checking working directory"
pwd | grep -q $HOME
if [ "$?" != "0" ] ; then
  VBoxManage sharedfolder add ${VM} --name "workspace" --hostpath "$(pwd)"
fi

STEP="Finalize"
clear
cat << EOF


                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

EOF
echo -e "${BLUE}docker${NC} is configured to use the ${GREEN}${VM}${NC} machine with IP ${GREEN}$(docker-machine ip ${VM})${NC}"
echo "For help getting started, check out the docs at https://docs.docker.com"
echo

docker () {
  MSYS_NO_PATHCONV=1 docker.exe "$@"
}
export -f docker

bash --init-file <(echo 'eval $(docker-machine env)')
