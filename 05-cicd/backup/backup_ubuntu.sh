#!/bin/bash
DB_HOST=$DB_HOST
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

S3_BUCKET=$S3_BUCKET
BACKUP_PREFIX=cronjob

# Create a timestamped backup filename
BACKUP_FILENAME="${BACKUP_PREFIX}_$(date +%Y%m%d_%H%M%S).sql"

# Create the database backup
PGPASSWORD="$DB_PASSWORD" pg_dump -U civo -h $DB_HOST $DB_NAME > ./$BACKUP_FILENAME

# configure aws cli
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region ap-northeast-2

# Upload the backup to S3
# aws --endpoint-url <https://objectstore.lon1.civo.com> s3 cp $BACKUP_FILENAME s3://$S3_BUCKET
aws s3 cp $BACKUP_FILENAME s3://$S3_BUCKET

# Cleanup (optional)
rm $BACKUP_FILENAME