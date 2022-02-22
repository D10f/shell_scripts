#!/bin/bash

# Assumes SCW CLI has been configured previously through docker

ACC_ZONE="nl-ams-1"
ACC_PNET="ebde321f-bfab-473f-bbca-8904b995c76a"
INS_TYPE="DEV1-S"
INS_IMAGE="ubuntu_focal"
DCK_IMAGE="scaleway/cli:v2.4.0"
CMD_BASE="docker run -it --rm -v ${HOME}/.config/scw:/root/.config/scw ${DCK_IMAGE} instance"

# Checks if input to create new instances is greater than this value.
NEW_INSTANCES=0
MAX_INSTANCES=5
FORCE_SHUTDOWN="false"


######## INIT ########


if [[ "${UID}" -ne 1000 ]]
then
  echo "User \"${USER}\" is not allowed to run this script!";
  exit 1
fi

function usage_general() {
  echo "Usage: ${0} [list | create | delete | up | down | start | stop | nic] [options]..." >&2
  echo "Manage your account with this wrapper for the official SCW CLI tool."
  exit 1
}

function usage_create() {
  echo "Usage: ${0} create  [-v] [-z ACC_ZONE] [-t INS_TYPE] [-i INS_IMAGE] [-n NEW_INSTANCES] [INSTANCE_NAMES]..." >&2
  echo "Launches any number of instances. Each positional argument will be used."
  echo "as the name for the instance."
  echo "  -n  NEW_INSTANCES  Specify the number of instances to create."
  echo "  -z  ACC_ZONE       Server location where the instance will be located."
  echo "  -t  INS_TYPE       Type of server running, default DEV-1."
  echo "  -i  INS_IMAGE      Image to run in the server, defaults to ubuntu 20.04."
  echo "  -v                 Increase verbosity."
  exit 1
}

# TODO: Add more options unique to each of the following subcommands!

function usage_list() {
  echo "Usage: ${0} list [-v] [-z ACC_ZONE] [INSTANCES_IDS]..." >&2
  echo "  -z  ACC_ZONE  Server location of the specified instances."
  echo "  -v            Increase verbosity."
  exit 1
}

function usage_start() {
  echo "Usage: ${0} start [-v] [-z ACC_ZONE] [INS_ID | INS_NAME]..." >&2
  echo "Starts up containers referenced by id or name" >&2
  echo "  -z  ACC_ZONE  Server location of the specified instances."
  echo "  -v            Increase verbosity."
  exit 1
}

function usage_stop() {
  echo "Usage: ${0} stop [-v] [-z ACC_ZONE] [INS_ID | INS_NAME]..." >&2
  echo "Shuts down containers referenced by id or name." >&2
  echo "  -z  ACC_ZONE  Server location of the specified instances."
  echo "  -v            Increase verbosity."
  exit 1
}

function usage_delete() {
  echo "Usage: ${0} delete [-vf] [-z ACC_ZONE] [INS_ID | INS_NAME]..." >&2
  echo "  -z  ACC_ZONE  Server location of the specified instances."
  echo "  -f            Forces instance to shutdown before deleting."
  echo "  -v            Increase verbosity."
  exit 1
}

function usage_nic() {
  echo "Usage: ${0} nic [-v] [-z ACC_ZONE] [-n ACC_PNET] [SERVER_NAME]..." >&2
  echo "  -z  ACC_ZONE  Server location of the specified instances."
  echo "  -n  ACC_PNET  Private Network ID as provided by Scaleway."
  echo "  -v            Increase verbosity."
  exit 1
}

######## UTILITIES ########


function get_instance_id_by_state() {
  local RUNNING_INSTANCES="${CMD_BASE} server list zone=${ACC_ZONE} state=${1}"
  $RUNNING_INSTANCES | grep -v 'STATE' | awk '{print $1}' | (readarray -t ARRAY; IFS=' ' echo "${ARRAY[*]}")
}


function get_instance_id_by_name() {
  local REGEXP=$(echo ${@} | sed s/' '/\|/g)
  local RUNNING_INSTANCES="${CMD_BASE} server list zone=${ACC_ZONE}"
  $RUNNING_INSTANCES | grep -Ei "(${REGEXP})" | awk '{print $1}' | (readarray -t ARRAY; IFS=' ' echo "${ARRAY[*]}")
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

  # Create instances as the largest between -n argument and names provided.
  NAMED_INSTANCES="$(( $# - 1 ))"

  if [[ "${NAMED_INSTANCES}" -gt "${NEW_INSTANCES}" ]]
  then
    NEW_INSTANCES=$NAMED_INSTANCES
  fi

  if [[ "${NEW_INSTANCES}" -le 0 ]]
  then
    echo "You must specify how many instances to create"
    usage_create
    exit 1
  fi

  # Warn if too many instances are specified accidentally to prevent charges
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

    $CMD | grep -E '^ID|Hostname|^CommercialType|^Zone|PublicIP\.Address|Image\.Name'
    (( START++ ))
    shift
  done
}


######## STOP INSTANCES BY NAME OR ID ########


function get_stop_arguments() {
 while getopts vz: OPTION
  do
    case ${OPTION} in
      v)
        echo "TODO: Enable verbosity"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      ?)
        usage_stop
        ;;
    esac
  done
}

function stop_instances() {
  get_stop_arguments ${@}
  shift "$(( OPTIND - 1 ))"

  if [[ ! "${@}" ]]
  then
    echo "You must provide at least one instance name."
    exit 1
  fi

  local CMD="${CMD_BASE} server stop $(get_instance_id_by_name ${@}) zone=${ACC_ZONE}"
  $CMD
}


######## START INSTANCES BY NAME OR ID ########


function get_start_arguments() {
 while getopts vz: OPTION
  do
    case ${OPTION} in
      v)
        echo "TODO: Enable verbosity"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      ?)
        usage_stop
        ;;
    esac
  done
}

function start_instances() {
  get_start_arguments ${@}
  shift "$(( OPTIND - 1 ))"

  if [[ ! "${@}" ]]
  then
    echo "You must provide at least one instance name."
    exit 1
  fi

  local CMD="${CMD_BASE} server start $(get_instance_id_by_name ${@}) zone=${ACC_ZONE}"
  $CMD
}


######## DELETE INSTANCES BY NAME OR ID ########


function get_delete_arguments() {
 while getopts vfz: OPTION
  do
    case ${OPTION} in
      v)
        echo "TODO: Enable verbosity"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      f)
        FORCE_SHUTDOWN="true"
        ;;
      ?)
        usage_stop
        ;;
    esac
  done
}


function delete_instances() {
  get_delete_arguments ${@}
  shift "$(( OPTIND - 1 ))"

  if [[ ! "${@}" ]]
  then
    echo "You must provide at least one instance name."
    exit 1
  fi

  local CMD="${CMD_BASE} \
  server \
  delete \
  with-ip=true \
  force-shutdown=${FORCE_SHUTDOWN} \
  zone=${ACC_ZONE} \
  $(get_instance_id_by_name ${@})"

  $CMD
}


######## STOP ALL INSTANCES ########


function get_down_arguments() {
 while getopts vz: OPTION
  do
    case ${OPTION} in
      v)
        echo "TODO: Enable verbosity"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      ?)
        usage_stop
        ;;
    esac
  done
}

function down_instances() {
  get_down_arguments ${@}

  local CMD="${CMD_BASE} server stop $(get_instance_id_by_state running) zone=${ACC_ZONE}"
  $CMD
}


######## STARTS ALL INSTANCES ########


function get_up_arguments() {
 while getopts vz: OPTION
  do
    case ${OPTION} in
      v)
        echo "TODO: Enable verbosity"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      ?)
        usage_stop
        ;;
    esac
  done
}


function up_instances() {
  get_up_arguments ${@}

  local CMD="${CMD_BASE} server stop $(get_instance_id_by_state stopped) zone=${ACC_ZONE}"
  $CMD
}


######## LIST INSTANCES ########


function get_list_arguments() {
  while getopts vz: OPTION
  do
    case ${OPTION} in
      z)
        ACC_ZONE="${OPTARG}"
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


######## CREATE NIC ON INSTANCE ########


function get_nic_arguments() {
  while getopts vn:z: OPTION
  do
    case ${OPTION} in
      v)
        echo "Verbosity enabled"
        ;;
      n)
        ACC_PNET="${OPTARG}"
        ;;
      z)
        ACC_ZONE="${OPTARG}"
        ;;
      ?)
        usage_nic
        ;;
    esac
  done
}


function create_nic() {

  get_nic_arguments ${@}
  shift "$(( OPTIND - 1 ))"

  TOTAL_SERVERS="${#}"
  SERVER_IDS="$(get_instance_id_by_name ${@})"

  for SERVER_ID in ${SERVER_IDS}
  do
    local CMD="${CMD_BASE} \
      private-nic \
      create \
      zone=${ACC_ZONE} \
      private-network-id=${ACC_PNET} \
      server-id=$(get_instance_id_by_name ${SERVER_ID})"
  
    $CMD
  done
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
  stop)
    shift
    stop_instances ${@}
    ;;
  start)
    shift
    start_instances ${@}
    ;;
  up)
    shift
    up_instances ${@}
    ;;
  down)
    shift
    down_instances ${@}
    ;;
  delete|remove)
    shift
    delete_instances ${@}
    ;;
  nic)
    shift
    create_nic ${@}
    ;;
  *)
    usage_general
    ;;
esac
