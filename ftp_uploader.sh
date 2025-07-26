#!/bin/bash

#
# Script to upload folders to ETSI site
#

####################
# Input variables
####################

FTP_SERVER=${FTP_SERVER:-"ftp://osm-download.etsi.org"}
LOCAL_BASE_FOLDER=${LOCAL_BASE_FOLDER:-"."}
REMOTE_BASE_FOLDER=${REMOTE_BASE_FOLDER:-"analytics"}
SOURCE_FOLDER=${SOURCE_FOLDER:-"${1}"}
TARGET_FOLDER=${TARGET_FOLDER:-"${2}"}
SOURCE_KEY_FILE=${SOURCE_KEY_FILE:-"${3}"}  # Optional parameter
FTP_OPTS=${FTP_OPTS:-""}

# Current dir
dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

# Prints relevant information
echo "FTP server: ${FTP_SERVER}"
echo "Current local working directory: ${dir}"
echo "Local base folder: ${LOCAL_BASE_FOLDER}"
echo "Remote base folder: ${REMOTE_BASE_FOLDER}"
echo "Source folder to copy: ${SOURCE_FOLDER}"
echo "Name for the folder at destination: ${TARGET_FOLDER}"


#####################
# Gets credentials
#####################

# If not in the container...
if [[ -z "${IN_CONTAINER}" ]]; then
    # If defined a file with credentials, it will be sourced
    if [ ! -z ${ENV_FILE} ]; then
        if [ -f ${ENV_FILE} ]; then
            echo source ${ENV_FILE}
        else
            echo "The specified environment file \"${ENV_FILE}\" does not exist. Exiting..."
            exit 1
        fi
    fi

    # Checks if env vars with credentials are defined. If not, asks for them
    if [ -z ${FTP_USERNAME+x} ] || [ -z ${FTP_PASSWORD+x} ]; then
        echo "FTP credentials are required for ${FTP_SERVER}:"
        read -p  "Username: " FTP_USERNAME
        read -sp "Password: " FTP_PASSWORD
        echo
    else
        echo "FTP username: ${FTP_USERNAME}"
    fi
fi

####################################
# Uploads the folder to the server
####################################

# Uploads the full folder using the timestamp as name
lftp ${FTP_OPTS} -u ${FTP_USERNAME},${FTP_PASSWORD} ${FTP_SERVER} << !
   set ftp:ssl-allow no
   lcd "${LOCAL_BASE_FOLDER}"
   cd "${REMOTE_BASE_FOLDER}"

   mirror -R "${SOURCE_FOLDER}" "${TARGET_FOLDER}"
   bye
!

# If `SOURCE_KEY_FILE` is defined, it also copies a key file to the base folder
[ ! -z ${SOURCE_KEY_FILE} ] && echo "Uploading latest key file..." && lftp ${FTP_OPTS} -u ${FTP_USERNAME},${FTP_PASSWORD} ${FTP_SERVER} << !
   set ftp:ssl-allow no
   lcd "${LOCAL_BASE_FOLDER}"
   cd "${REMOTE_BASE_FOLDER}"

   put "${SOURCE_FOLDER}"/"${SOURCE_KEY_FILE}"

   bye
!
