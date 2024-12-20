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
SQL_HOST="127.0.0.1"
SQL_USER="root"
SQL_PASS_B64="cm9vdAo="
SQL_PASS=$(echo "$SQL_PASS_B64" | base64 --decode)

DB_NAME="testdb"
TABLE_NAME="CUSTOMER_${STUDENT_INDEX}"

TMP_DIR="tmp"

# Files
DOWNLOAD_FILE="InternetSales_new.zip"
RAW_FILE="InternetSales_new.txt"
VALIDATED_FILE="InternetSales_new_validated.txt"
VALIDATED_FILE="InternetSales_new_validated.txt"
BAD_FILE="${LOG_DIR}/InternetSales_new.bad_${TIMESTAMP}"
PROCESSED_CSV="${LOG_DIR}/${TIMESTAMP}_InternetSales_processed.csv"
PROCESSED_ZIP="${PROCESSED_CSV}.zip"

mkdir -p "$LOG_DIR"
mkdir -p "$TMP_DIR"

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
    local EXIT_CODE="$2"

    if [ $EXIT_CODE -eq 0 ]; then
        log "${RESULT} - Successful"
    else
        log "${RESULT} - Failed"
        exit 1
    fi
}

######################################
# 1.1 Download the file
######################################

log "Downloading file"

wget -q "$URL" -O "$TMP_DIR/$DOWNLOAD_FILE"

EXIT_CODE=$?
check_success "Download step" $EXIT_CODE

######################################
# 1.2 Unzip the file
######################################

log "Unzipping file"

unzip -P "$ZIP_PASS" "$TMP_DIR/$DOWNLOAD_FILE" -d "$TMP_DIR" > /dev/null

EXIT_CODE=$?
check_success "Unzipping step" $EXIT_CODE

mv "$TMP_DIR/InternetSales_new.txt" "$RAW_FILE"

######################################
# 1.3 Validation
######################################

log "Validating file"

HEADER=$(head -n 1 "$RAW_FILE")

# Set up header to validated and bad files
echo "$HEADER" > "$VALIDATED_FILE"
echo "$HEADER" > "$BAD_FILE"

# Count numer of colums
HEADER_COL_COUNT=$(echo "$HEADER" | awk -F'|' '{print NF}')

awk -F'|' -v hcc="$HEADER_COL_COUNT" -v bad_file="$BAD_FILE" -v validated_file="$VALIDATED_FILE" -v ofs="|"  '
BEGIN {
    OFS = ofs
    print "ProductKey|CurrencyAlternateKey|FIRST_NAME|LAST_NAME|OrderDateKey|OrderQuantity|UnitPrice|SecretCode" > validated_file
}

# Skip header
NR==1 { next }

{
    line = $0

    # Skip duplicate rows
    if (line in seen) {
        next
    }
    seen[line]

    # Skip empty row
    if (length(line) == 0 ) {
        next
    }

    # Check number of colums
    if (NF != hcc ) {
        print_to_bad()
        next
    }

    # Check OrderQuantity <= 100
    if ($5 > 100) {
        print_to_bad()
        next
    }

    # Check OrderQuantity <= 100
    if (length($7) > 0) {
        print_to_bad()
        next
    }

    # Check last name and first name format
    gsub(/"/, "", $3)
    split($3, namearr, ",")
    if (length(namearr[1]) == 0 || length(namearr[2]) == 0) {
        print_to_bad()
        next
    }

    FIRST_NAME = namearr[2]
    LAST_NAME= namearr[1]

    # Save into validated file
    print $1, $2, FIRST_NAME, LAST_NAME, $4, $5, $6, $7, $8 >> validated_file
}

function print_to_bad() {
    $7 = "" 
    print $0 >> bad_file
}
' "$RAW_FILE"

EXIT_CODE=$?
check_success "Validating file step" $EXIT_CODE

######################################
# 1.4 Create MySQL table
######################################

log "Creating MySQL table $TABLE_NAME"

mysql -h "$SQL_HOST" -u "$SQL_USER" -p"$SQL_PASS" "$DB_NAME" 2>/dev/null <<EOF
DROP TABLE IF EXISTS $TABLE_NAME;
CREATE TABLE $TABLE_NAME (
    ProductKey INT,
    CurrencyAlternateKey VARCHAR(50),
    FIRST_NAME VARCHAR(100),
    LAST_NAME VARCHAR(100),
    OrderDateKey DATE,
    OrderQuantity INT,
    UnitPrice DECIMAL(10,2),
    SecretCode VARCHAR(50)
);
EOF

EXIT_CODE=$?
check_success "Table creation step" $EXIT_CODE

######################################
# 1.5 Load data to MySQL database
######################################

log "Loading data into MySQL table"

mysql --local-infile=1 -h "$SQL_HOST" -u "$SQL_USER" -p"$SQL_PASS" "$DB_NAME" \
 -e "LOAD DATA LOCAL INFILE '$(pwd)/$VALIDATED_FILE' INTO TABLE $TABLE_NAME
FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n' IGNORE 1 LINES
(ProductKey, CurrencyAlternateKey, FIRST_NAME, LAST_NAME, OrderDateKey, OrderQuantity, UnitPrice, SecretCode);" 2>/dev/null

EXIT_CODE=$?
check_success "Load data step" $EXIT_CODE

######################################
# 1.6 Move processed file
######################################

log "Archiving processed file"

mv "$VALIDATED_FILE" "PROCESSED/${TIMESTAMP}_$(basename "$VALIDATED_FILE")"

EXIT_CODE=$?
check_success "Archiving step" $EXIT_CODE

######################################################
# 1.6 Update SecretCode with random string
######################################################

log "Updating SecretCode"

mysql -h "$SQL_HOST" -u "$SQL_USER" -p"$SQL_PASS" "$DB_NAME" 2>/dev/null <<EOF
UPDATE $TABLE_NAME
SET SecretCode = SUBSTRING(MD5(RAND()),1,10);
EOF

EXIT_CODE=$?
check_success "SecretCode update step" $EXIT_CODE

######################################
# 1.7 Export table to CSV
######################################

log "Exporting table to CSV"

mysql -h "$SQL_HOST" -u "$SQL_USER" -p"$SQL_PASS" --skip-column-names -B "$DB_NAME" \
 -e "SELECT * FROM $TABLE_NAME;" > "$PROCESSED_CSV" 2>/dev/null

EXIT_CODE=$?
check_success "Export step" $EXIT_CODE

######################################
# 1.8 Compress CSV
######################################

log "Compressing CSV"

zip "$PROCESSED_ZIP" "$PROCESSED_CSV" > /dev/null

EXIT_CODE=$?
check_success "Compression step" $EXIT_CODE

######################################
# 2. SQLServer query
######################################

# CREATE TABLE dbo.CUSTOMER_405014 (
#     ProductKey INT,
#     CurrencyAlternateKey VARCHAR(50),
#     FIRST_NAME VARCHAR(100),
#     LAST_NAME VARCHAR(100),
#     OrderDateKey DATE,
#     OrderQuantity INT,
#     UnitPrice DECIMAL(10,2),
#     SecretCode VARCHAR(50)
# );

######################################
# 3. BCP comand
######################################
# bcp AdventureWorksDW2022.dbo.CUSTOMER_405014 in "PROCESSED\12202024_InternetSales_processed.csv" -S localhost -T -f "customers_format.fmt"