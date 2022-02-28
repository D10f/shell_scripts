#!/bin/bash

# backups.sh - A utility script to archive files into a single directory for easier backup management.

# TODO:
#   - [ ] Set variable verbosity levels
#   - [ ] Support for multiple compression algorithms
#   - [ ] Support for encryption

#
# GLOBAL VARIABLES
##
BACKUP_DIR="${HOME}/Backups"
CURRENT_DATE="$(date +%d-%m-%Y_%H%M)"
VERBOSE=true


#
# usage
##
function usage() {
  echo "Usage: ${0}" >&2
  exit 1
}


#
# prints message to the console if verbosity was specified
##
function info() {
  if [[ "${VERBOSE}" ]]
  then
    echo $1
  fi
}


#
# create an archive file using name $1 out of files $@...
##
function create_archive() {
  local ARCHIVE_NAME=$1
  shift
  tar -cjf "${ARCHIVE_NAME}" ${@} >/dev/null 2>&1
}


#
# checks if directory $1 exists and exits with non-zero status if not
##
function dir_exists() {
  if [[ ! -d "${1}" ]]
  then
    echo "Directory not found: ${1}"
    exit 1
  fi
}


#
# checks if file $1 exists and exits with non-zero status if not
##
function file_exists() {
  if [[ ! -f "${1}" ]]
  then
    echo "Directory not found: ${1}"
    exit 1
  fi
}


#
# similar to dir_exists but it creates the necessary directories instead of exiting
##
function ensure_dir_exists() {
  if [[ ! -d "${1}" ]]
  then
    mkdir -pm 750 ${1}
  fi
}


#
# creates an archive containing the .ssh directory
##
function archive_ssh_keys() {
  local SSH_SRC_DIR="${HOME}/.ssh"
  local SSH_BACKUP_DIR="${BACKUP_DIR}/ssh_keys"
  local ARCHIVE_NAME="${SSH_BACKUP_DIR}/ssh_keys_${CURRENT_DATE}.tar.bz2"
  
  dir_exists $SSH_SRC_DIR
  ensure_dir_exists $SSH_BACKUP_DIR

  info "Archiving SSH keys in: ${SSH_BACKUP_DIR}"
  create_archive $ARCHIVE_NAME $SSH_SRC_DIR
}


#
# creates an archive containing all custom firefox profiles
##
function archive_firefox_profiles() {
  local FF_SRC_DIR="${HOME}/.mozilla/firefox"
  local FF_BACKUP_DIR="${BACKUP_DIR}/firefox_profiles"
  local FF_PROFILES="${FF_SRC_DIR}/profiles.ini"
  local ARCHIVE_NAME="${FF_BACKUP_DIR}/firefox_profiles_${CURRENT_DATE}.tar.bz2"

  dir_exists $FF_SRC_DIR
  file_exists $FF_PROFILES
  ensure_dir_exists $FF_BACKUP_DIR

  PROFILE_FILES=$(cat ${FF_PROFILES} \
  | grep "Path=" \
  | grep -v "default-release" \
  | sed "s|Path=|${FF_SRC_DIR}/|") # Prefixes filename to output absolute path

  info "Archiving Firefox profiles in: ${FF_BACKUP_DIR}"
  create_archive $ARCHIVE_NAME $PROFILE_FILES
}


#
# updates permissions on all archive files found
##
function update_permissions() {
  find $BACKUP_DIR -type d -exec chmod 700 {} \;
  find $BACKUP_DIR -type f -exec chmod 600 {} \;
}


function main() {
  ensure_dir_exists $BACKUP_DIR

  info "-------------------------------------"
  info "Running script start: ${CURRENT_DATE}"
  info "-------------------------------------"

  archive_firefox_profiles
  archive_ssh_keys

  info "Archive finished. Updating permissions..."
  
  update_permissions

  info "All done!"
}


main