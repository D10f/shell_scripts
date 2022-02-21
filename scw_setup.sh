#!/bin/bash

# Assumes SCW CLI has been configured previously through docker

ACC_ZONE="nl-ams-1"
ACC_PNET="ebde321f-bfab-473f-bbca-8904b995c76a"
INS_TYPE="DEV1-S"
INS_IMAGE="ubuntu_focal"
DCK_IMAGE="scaleway/cli:v2.4.0"
CMD_BASE="docker run -it --rm -v ${HOME}/.config/scw:/root/.config/scw ${DCK_IMAGE} instance"

# Checks if input to create new instances is greater than this value.
NEW_INSTANCES=1
MAX_INSTANCES=5


######## INIT ########


if [[ "${UID}" -ne 1000 ]]
then
  echo "User \"${USER}\" is not allowed to run this script!";
  exit 1
fi

function usage_general() {
  echo "Usage: ${0} [list | create | delete] [options]..." >&2
  echo "Manage your account with this wrapper for the official SCW CLI tool."
  exit 1
}

function usage_create() {
  echo "Usage: ${0} create [-v] [-n NEW_INSTANCES] [INSTANCE_NAMES]..." >&2
  echo "Launches any number of instances. Each positional argument will be used"
  echo "as the name for the instance."
  echo "  -v                 Increase verbosity."
  echo "  -n  NEW_INSTANCES  Specify the number of instances to create."
  echo "  -z  ACC_ZONE       Server location where the instance will be located."
  echo "  -t  INS_TYPE       Type of server running, default DEV-1."
  echo "  -i  INS_IMAGE      Image to run in the server, defaults to ubuntu 20.04."
  exit 1
}

function usage_delete() {
  echo "Usage: ${0} delete [-v] [INSTANCES_IDS]..." >&2
  echo "  -v                    Increase verbosity."
  exit 1
}

function usage_list() {
  echo "Usage: ${0} list [-v] [INSTANCES_IDS]..." >&2
  echo "  -v                    Increase verbosity."
  exit 1
}


######## CREATE INSTANCES ########


function get_create_arguments() {
  while getopts vn:z:t:i: OPTION
  do
    case ${OPTION} in
      n)
        NEW_INSTANCES="${OPTARG}"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      t)
        INS_TYPE="${OPTARG}"
        ;;
      i)
        INS_IMAGE="${OPTARG}"
        ;;
      v)
        echo "Verbosity enabled"
        ;;
      ?)
        usage_create
        ;;
    esac
  done
}


function check_max_instances() {
  
  NAMED_INSTANCES="$(( $# - 1 ))"

  if [[ "${NAMED_INSTANCES}" -gt "${NEW_INSTANCES}" ]]
  then
    NEW_INSTANCES=$NAMED_INSTANCES
  fi

  if [[ "${NEW_INSTANCES}" -gt "${MAX_INSTANCES}" ]]
  then
    echo "CAUTION!"
    read -p "Are you sure you want to create ${NEW_INSTANCES} instances? (y/n): " ANSWER    
    if [[ "${ANSWER}" != 'y' ]]
    then
      echo "Not confirmed: exiting program..."
      exit 1
    fi

    echo "Confirmed: creating ${NEW_INSTANCES} instances..."
  fi
}


function create_instances() {

  get_create_arguments ${@}
  shift "$(( OPTIND - 1 ))"
  check_max_instances ${NEW_INSTANCES} ${@}

  START=1
  while [[ "${START}" -le "${NEW_INSTANCES}" ]]
  do
    echo "Creating instance #${START} (${1})"
    local CMD="${CMD_BASE} server create type=${INS_TYPE} image=${INS_IMAGE} zone=${ACC_ZONE}"

    if [[ ${1} ]]
    then
      CMD="${CMD} name=${1}"
    fi

    $CMD
    (( START++ ))
    shift
  done
}


######## DELETE INSTANCES ########


function get_delete_arguments() {
  while getopts vi: OPTION
  do
    case ${OPTION} in
      i)
        INSTANCES_IDS="${OPTARG}"
        ;;
      v)
        echo "Verbosity enabled"
        ;;
      ?)
        usage_delete
        ;;
    esac
  done
}


function delete_instances() {

  get_delete_arguments ${@}

  # START=1
  # while [[ "${START}" -le "${INSTANCES_IDS}" ]]
  # do
  #   echo "Creating instance #${START}"
  #   # local CMD="${CMD_BASE} server create type=${INS_TYPE} image=${INS_IMAGE} zone=${ACC_ZONE}"
  #   # $CMD
  #   (( START++ ))
  # done

  echo "you called the delete function!"
  echo "${INSTANCES_IDS}"
}


######## LIST INSTANCES ########

function get_list_arguments() {
  while getopts vi: OPTION
  do
    case ${OPTION} in
      i)
        echo "TEST PASSED"
        ;;
      v)
        echo "Verbosity enabled"
        ;;
      ?)
        usage_list
        ;;
    esac
  done
}


function list_instances() {

  get_list_arguments ${@}

  local CMD="${CMD_BASE} server list zone=${ACC_ZONE}"
  $CMD
}


case "${1}" in
  list)
    shift
    list_instances ${@}
    ;;
  create)
    shift
    create_instances ${@}
    ;;
  delete|remove)
    shift
    delete_instances ${@}
    ;;
  *)
    usage_general
    ;;
esac
