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
