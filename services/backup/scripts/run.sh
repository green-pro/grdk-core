#!/bin/bash

DB_HOST=$1
DB_PORT=$2
DB_USER=$3
DB_PASS=$4
DB_NAME=$5

if [[ -z "${DB_HOST}" ]]; then
	echo "No DB_HOST Provided. Exiting."
	exit 1
fi

if [[ -z "${DB_PORT}" ]]; then
	echo "No DB_PORT Provided. Exiting."
	exit 1
fi

if [[ -z "${DB_USER}" ]]; then
	echo "Warning: No DB_USER provided. Assuming 'root'"
	DB_USER="root"
fi

if [[ -z "${DB_PASS}" ]]; then
	echo "No DB_PASS provided. Exiting"
	exit 1
fi

if [[ -z "${DB_NAME}" ]]; then
	echo "No DB_NAME provided. Exiting"
	exit 1
fi

if [[ -z "${BACKUP_DIR}" ]]; then
	echo "Warning: No BACKUP_DIR defined. Using /backups"
	BACKUP_DIR=/backups
fi

if [[ ! -d "${BACKUP_DIR}" ]]; then
	echo "Warning: Creating backup dir: ${BACKUP_DIR}"
	mkdir -p "${BACKUP_DIR}"
fi

BACKUP_FOLDER=${BACKUP_DIR}/${DB_NAME}_$(date +%Y%m%d%H%M%S)

FILENAME=${DB_NAME}_$(date +%Y%m%d%H%M%S).tar.gz

mydumper -c -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p "${DB_PASS}" -B "${DB_NAME}" -o "${BACKUP_FOLDER}"

if [ $? -eq 0 ]; then
	echo "BACKUP OK"
	cd ${BACKUP_FOLDER}
	tar -czvf "${FILENAME}" .
	aws s3 cp ${FILENAME} s3://${AWS_BUCKET}/backups/${DB_NAME}/$(date +%Y)/$(date +%m)/
	if [ $? -eq 0 ]; then
		echo "UPLOAD S3 OK"
		rm -Rf ${BACKUP_FOLDER}
	else
		echo "UPLOAD S3 FAIL"
	fi
else
	echo "BACKUP FAIL"
fi
