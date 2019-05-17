#!/bin/bash
set -euo pipefail

if [ -v AWS_ACCESS_KEY_ID ]; then
	echo "AWS enabled"
	aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
	aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
	aws configure set default.region sa-east-1
	aws configure set default.output json
else
	echo "AWS disabled"
fi

while IFS=' ' read -r line || [[ -n "$line" ]]; do
	echo "START DB: $line"
	fields=($line)
	echo "${fields[1]} ${fields[0]} * * * /scripts/run.sh ${fields[2]} ${fields[3]} ${fields[4]} ${fields[5]} ${fields[6]}" >> /etc/crontabs/root
done < /scripts/dblist.conf

exec "$@"
