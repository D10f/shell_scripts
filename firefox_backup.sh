#!/bin/bash

# firefox_backup.sh - Creates a backup of your firefox profiles

FF_DIR="${HOME}/.mozilla/firefox"
FF_PROFILES="${FF_DIR}/profiles.ini"
BACKUP_DEST="${HOME}/Backups/firefox_profiles"
ARCHIVE_NAME="firefox_profiles.tar.bz2"


function get_profiles() {
  cat ${FF_PROFILES} \
  | grep "Path=" \
  | grep -v "default-release" \
  | sed "s|Path=|${FF_DIR}/|" # Prefixes filename to output absolute path
}


function archive_profiles() {
  tar -cjf "${BACKUP_DEST}/${ARCHIVE_NAME}" $(get_profiles)
}


if [[ ! -d "${FF_DIR}" ]]
then
  echo "Directory not found: ${FF_DIR}"
  exit 1
fi


if [[ ! -f "${FF_PROFILES}" ]]
then
  echo "File not found: ${FF_PROFILES}"
  exit 1
fi


if [[ ! -d "${BACKUP_DEST}" ]]
then
  mkdir -p ${BACKUP_DEST}
fi


archive_profiles
