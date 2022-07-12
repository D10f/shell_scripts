#!/bin/bash

# backups.sh - A utility script to archive files into a single directory for easier backup management.

# TODO:
#   - [ ] Set variable verbosity levels
#   - [ ] Support for multiple compression algorithms
#   - [ ] Support for encryption
#   - [ ] Proper use of "ls" to get file list

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
  local SRC_DIR=$2
  shift 2
  tar -C "${SRC_DIR}" -cjf "${ARCHIVE_NAME}" ${@} >/dev/null 2>&1
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

  local SSH_FILES=$(ls ${SSH_SRC_DIR})

  info "Archiving SSH keys in: ${SSH_BACKUP_DIR}"
  create_archive $ARCHIVE_NAME ${SSH_SRC_DIR} $SSH_FILES
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

  local PROFILE_FILES=$(cat ${FF_PROFILES} \
  | grep "Path=" \
  | grep -v "default-release" \
  | cut -d '=' -f2)

  info "Archiving Firefox profiles in: ${FF_BACKUP_DIR}"
  create_archive $ARCHIVE_NAME $FF_SRC_DIR $PROFILE_FILES
}


#
# creates an archive containing the neovim configuration files
##
function archive_neovim() {
  local NVIM_SRC_DIR="${HOME}/.config/nvim"
  local NVIM_BACKUP_DIR="${BACKUP_DIR}/nvim"
  local ARCHIVE_NAME="${NVIM_BACKUP_DIR}/nvim_${CURRENT_DATE}.tar.bz2"
  
  dir_exists $NVIM_SRC_DIR
  ensure_dir_exists $NVIM_BACKUP_DIR

  local NVIM_FILES=$(ls ${NVIM_SRC_DIR})

  info "Archiving nevovim configuration files in: ${NVIM_BACKUP_DIR}"
  create_archive $ARCHIVE_NAME ${NVIM_SRC_DIR} $NVIM_FILES
}


#
## creates an archive with bash profile configuration files
###
function archive_bash_files() {
  local BASH_BACKUP_DIR="${BACKUP_DIR}/bash"
  local ARCHIVE_NAME="${BASH_BACKUP_DIR}/bash_${CURRENT_DATE}.tar.bz2"

  ensure_dir_exists $BASH_BACKUP_DIR

  local BASH_FILES=".bashrc .bash_aliases .bash_profile"

  info "Archiving bash configuration files in: ${BASH_BACKUP_DIR}"
  create_archive $ARCHIVE_NAME $HOME $BASH_FILES
}

#
## creates insert description here
###
function archive_user_files() {
  local FILES_BACKUP_DIR="${BACKUP_DIR}/user"
  local BACKUP_DIRECTORIES="Documents Pictures Videos Public"

  ensure_dir_exists $FILES_BACKUP_DIR
  info "Archiving personal files..."

  for dir in $BACKUP_DIRECTORIES; do
    local DIR_BACKUP_DIR="${FILES_BACKUP_DIR}/${dir}"
    local ARCHIVE_NAME="${DIR_BACKUP_DIR}/${dir}_${CURRENT_DATE}.tar.bz2"

    ensure_dir_exists $DIR_BACKUP_DIR

    local DIR_FILES=$(ls $HOME/$dir)

    info "  ...Archiving ${dir} in ${DIR_BACKUP_DIR}"
    

    create_archive $ARCHIVE_NAME ${HOME}/${dir} $DIR_FILES
  done
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
  archive_neovim
  archive_bash_files
  archive_user_files

  info "-------------------------------------"
  info "Archive finished. Updating permissions..."
  
  update_permissions

  info "All done!"
}


main
