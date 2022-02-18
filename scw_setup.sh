#!/bin/bash

# Assumes SCW CLI has been configured previously through docker
# 

ACC_ZONE="nl-ams-1"
ACC_PNET="ebde321f-bfab-473f-bbca-8904b995c76a"
INS_TYPE="DEV1-S"
INS_IMAGE="ubuntu_focal"
DCK_IMAGE="scaleway/cli:v2.4.0"
CMD_BASE="docker run -it --rm -v ${HOME}/.config/scw:/root/.config/scw ${DCK_IMAGE} instance"

# Checks if input to create new instances is greater than this value.
# This prevents long-running scripts and unnecessary charges from your provider
MAX_INSTANCES=3

if [[ "${UID}" -ne 1000 ]]
then
  echo "User \"${USER}\" is not allowed to run this script!";
  exit 1
fi

function usage() {
  echo "Usage: ${0} [list | create | delete]" >&2
  echo "Manage your account with this wrapper for the official SCW CLI tool."
  exit 1
}

function check_max_instances() {
  if [[ "${1}" -gt "${MAX_INSTANCES}" ]]
  then
    echo "CAUTION!"
    read -p "Are you sure you want to create ${$1} instances? Type CONFIRM to proceed: " ANSWER
    
    if [[ "${ANSWER}" != 'CONFIRM' ]]
    then
      echo "Not confirmed: exiting program..."
      exit 1
    fi

    echo "Confirmed: creating ${NEW_INSTANCES} instances..."
  fi
}

function list_instances() {
  local CMD="${CMD_BASE} server list zone=${ACC_ZONE}"
  $CMD
}

function create_instances() {
  read -p "How many instances would you like to create? " NEW_INSTANCES

  check_max_instances ${NEW_INSTANCES}

  START=1
  while [[ "${START}" -le "${NEW_INSTANCES}" ]]
  do
    echo "Creating instance #${START}"
    # local CMD="${CMD_BASE} server create type=${INS_TYPE} image=${INS_IMAGE} zone=${ACC_ZONE}"
    # $CMD
    (( START++ ))
  done
}


function delete_instances() {
  echo "you called the delete function!"
}

case "${1}" in
  list)
    list_instances
    ;;
  create)
    create_instances
    ;;
  delete|remove)
    delete_instances
    ;;
  *)
    usage
    ;;
esac
