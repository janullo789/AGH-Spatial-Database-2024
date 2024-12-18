#!/usr/bin/env bash

#######################################################################
# Changelog:
# v1.0 - 2024-12-18 - Initial creation of script for exercise 10
# Description:
# This script downloads a ZIP file, validates and processes data,
# loads into MySQL, exports results, and logs all steps.
#######################################################################

########################
# Configuration
########################

STUDENT_INDEX="405014"
TIMESTAMP=$(date +%m%d%Y)
LOG_DIR="PROCESSED"
LOG_FILE="${LOG_DIR}/script_${TIMESTAMP}.log"

URL="http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"
ZIP_PASS_B64="YmRwMmFnaAo="
ZIP_PASS=$(echo "$ZIP_PASS_B64" | base64 --decode)

# MySQL credentials
SQL_HOST="localhost"
SQL_USER="root"
SQL_PASS_B64=$(echo "cm9vdAo=" | base64 --decode)

DB_NAME="testdb"
TABLE_NAME="CUSTOMER_${STUDENT_INDEX}"

# Files
DOWNLOAD_FILE="InternetSales_new.zip"

mkdir -p "$LOG_DIR"

########################
# Functions
########################

log() {
    local MESSAGE="$1"
    local DATESTR=$(date +%Y%m%d%H%M%S)
    
    echo "${DATESTR} - ${MESSAGE}" >> "$LOG_FILE"
    echo "${DATESTR} - ${MESSAGE}"
}

check_success() {
    local RESULT="$1"

    if [ $? -eq 0 ]; then
        log "${RESULT} - Successfull"
    else
        log "${RESULT} - Failed"
        exit 1
    fi
}

################################
# 1.1 Download the file
################################

log "Downloading file"
wget -q "$URL" -O "$DOWNLOAD_FILE"
check_success "Download step"