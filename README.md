# Automated MariaDB Database Backup to AWS S3 Pipeline

A production-grade, zero-cost automated backup solution that dumps a MariaDB database on an AWS EC2 instance (Amazon Linux 2023), compresses the schema and data via `gzip`, and securely transfers the output to an AWS S3 bucket using temporary IAM Role permissions.

---

## 📌 Architecture Overview

1. **AWS EC2 (Amazon Linux 2023):** Hosts the MariaDB database engine (`company_db`).
2. **Bash Shell Script (`backup_s3.sh`):** Handles database dumps, `gzip` compression, validation, S3 sync, and 7-day retention cleanup.
3. **AWS IAM Role (`EC2-S3-Access-Role`):** Grants passwordless, keyless temporary access permissions from EC2 to S3.
4. **AWS S3 Bucket:** Serves as the central, durable backup storage (`devops-db-backups-srithi123`).

---

## 🛠️ Implementation Steps

### 1. Database Setup
```bash
sudo yum install mariadb105-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Create sample database and data
sudo mysql -u root -e "CREATE DATABASE company_db;"
sudo mysql -u root -e "USE company_db; CREATE TABLE users (id INT, name VARCHAR(50)); INSERT INTO users VALUES (1, 'Srithi DevOps');"

2. IAM Role & Security
Provisioned an IAM Role with AmazonS3FullAccess policy and attached it directly to the EC2 instance.

Adhered to security best practices by avoiding hardcoded AWS access keys (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY).

3. Backup Script (backup_s3.sh)
Bash
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

Proof of Execution
1. Terminal Log Execution
The bash script executed cleanly, recorded detailed timestamps, and generated the compressed .sql.gz database archive:

Plaintext
[Tue Oct 20 10:41:24 UTC 2026] SUCCESS: Database dumped successfully.
upload: db_backups/db_backup_2026-10-20_10-41-24.sql.gz to s3://devops-db-backups-srithi123/db_backup_2026-10-20_10-41-24.sql.gz
[Tue Oct 20 10:41:25 UTC 2026] SUCCESS: Backup uploaded to S3 bucket s3://devops-db-backups-srithi123

2. S3 Object Storage Verification
AWS S3 Console verification displaying the uploaded compressed archive (db_backup_2026-10-20_10-41-24.sql.gz) stored in the target bucket:
