# backup/backup.sh
#!/bin/bash
set -e
mkdir -p /backups

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backups/db_${TIMESTAMP}.sql.gz"

# 데이터베이스 백업
echo "Backing up database $DB_NAME from $DB_HOST as user $DB_USER"
export PGPASSWORD=$DB_PASSWORD
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v -F c | gzip > $BACKUP_FILE
chmod 600 $BACKUP_FILE
unset PGPASSWORD


# 로그 출력
echo "Backup completed: $BACKUP_FILE"

# 선택적: 외부 스토리지로 백업 전송 (S3 등)
if [ ! -z "$S3_BUCKET" ]; then
    echo "Uploading backup to S3 bucket: $S3_BUCKET"
    aws s3 cp $BACKUP_FILE s3://$S3_BUCKET/backups/
fi

# 오래된 백업 삭제 (30일 이상)
echo "Cleanup completed. Removed backups older than 30 days."
find /backups -type f -name "*.sql.gz" -mtime +30 -delete

echo "Backup process completed successfully at $(date)"