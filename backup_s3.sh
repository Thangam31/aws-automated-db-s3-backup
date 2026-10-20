#!/bin/bash

# Configuration
DB_NAME="company_db"
BACKUP_DIR="/home/ec2-user/db_backups"
S3_BUCKET="s3://devops-db-backups-srithi123"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
FILE_NAME="db_backup_${DATE}.sql.gz"
LOG_FILE="/home/ec2-user/backup.log"

# Create local backup directory
mkdir -p $BACKUP_DIR

# Perform Dump & Compress
sudo mariadb-dump -u root $DB_NAME | gzip > $BACKUP_DIR/$FILE_NAME

# Check if backup file is created and non-empty
if [ -s "$BACKUP_DIR/$FILE_NAME" ]; then
    echo "[$(date)] SUCCESS: Database dumped successfully." >> $LOG_FILE
    
    # Secure sync to AWS S3
    aws s3 cp $BACKUP_DIR/$FILE_NAME $S3_BUCKET/ >> $LOG_FILE 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] SUCCESS: Backup uploaded to S3 bucket $S3_BUCKET" >> $LOG_FILE
    else
        echo "[$(date)] ERROR: S3 Upload Failed!" >> $LOG_FILE
    fi

    # Cleanup local backups older than 7 days
    find $BACKUP_DIR -type f -name "*.sql.gz" -mtime +7 -delete
else
    echo "[$(date)] ERROR: Backup file is empty or missing!" >> $LOG_FILE
fi
