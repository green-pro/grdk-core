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

if [[ -z "${AWS_BUCKET}" ]]; then
	echo "No AWS_BUCKET provided. Exiting"
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

DUMP_DIR=${BACKUP_DIR}/${DB_NAME}_$(date +%Y%m%d%H%M%S)

echo "-------------------"
echo "DB_HOST: ${DB_HOST}"
echo "DB_PORT: ${DB_PORT}"
echo "DB_USER: ${DB_USER}"
echo "DB_PASS: ******"
echo "DB_NAME: ${DB_NAME}"
echo "AWS_BUCKET: ${AWS_BUCKET}"
echo "BACKUP_DIR: ${BACKUP_DIR}"
echo "DUMP_DIR: ${DUMP_DIR}"
echo "-------------------"

mydumper -c -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p "${DB_PASS}" -B "${DB_NAME}" -o "${DUMP_DIR}" --less-locking -v 3

if [ $? -eq 0 ]; then
	echo "BACKUP OK"
	cd ${DUMP_DIR}
	COMPRESS_FILENAME=${DB_NAME}_$(date +%Y%m%d%H%M%S).tar.gz
	tar -czvf "${COMPRESS_FILENAME}" .
	aws s3 cp ${COMPRESS_FILENAME} s3://${AWS_BUCKET}/backups/${DB_HOST}_${DB_PORT}_${DB_NAME}/$(date +%Y)/$(date +%m)/
	if [ $? -eq 0 ]; then
		echo "UPLOAD S3 OK"
		rm -Rf ${DUMP_DIR}
	else
		echo "UPLOAD S3 FAIL"
	fi
else
	echo "BACKUP FAIL"
fi
