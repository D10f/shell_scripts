#!/bin/bash

# Manage instances hosted on Scaleway. Assumes scw utility has been setup: 
# https://github.com/scaleway/scaleway-cli/blob/master/docs/commands/instance.md

# Scaleway account related variables
ACCOUNT_ZONE="nl-ams-1"
ACCOUNT_PRIVATE_NET_ID="ebde321f-bfab-473f-bbca-8904b995c76a"

# Server related variables
INSTANCE_TYPE="DEV1-S"
INSTANCE_IMAGE="ubuntu_focal"

# Command options
BIND_MOUNT="${HOME}/.config/scw:/root/.config/scw"
IMAGE="scaleway/cli:v2.4.0"
FULL_COMMAND="docker run -it --rm -v ${BIND_MOUNT} ${IMAGE} ${OPTIONS}"

if [[ "${UID}" -ne 1000 ]]
then
  echo "User \"${USER}\" is not allowed to run this script!";
  exit 1
fi

