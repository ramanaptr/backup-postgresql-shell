# AUTO BACKUP POSTGRESQL IN SHELL

I've been made auto backup/dumb postgresql per-schema

## Flow of backup_postgresql.sh
1. Auto backup database all or per-schema files
2. Auto zip with password (secure the data first)
3. Auto upload to your S3 Storage
4. Auto send to your email you set

## To achive this, you must install 5 things
### Example for mac using brew 

1. Install zip
```
brew install zip
``` 

2. Install expect
```
brew install expect
``` 

3. Install aws cli
```
brew install awscli
``` 

4. Install aws sendemail
```
brew install sendemail
``` 

## Pre-Final Configuration (Recommend)

1. Change to your **Zip Password**
```
zip_password="your_password"
``` 

2. Change to your **PSQL** Path
```
psql_path="../../psql"
pg_dump_path="../../pg_dump"
``` 

3. Change to your **PSQL Connection**
```
# Database connection details
backup_all=false # false is mean backup will split per-schema
db_host="http://localhost"
db_port="5432"
db_username="postgres"
db_name="your_db"
db_password="your_db_password"
``` 

4. Configure to your **SMTP Credentials**
```
# Sender Email
smtp_host="smtp.gmail.com"
smtp_port="587"
smtp_use_tls="-S smtp-use-starttls"
smtp_auth="-S smtp-auth=login"
smtp_user="yourmail@gmail.com"
smtp_password="your_mail_password"

# Recipient Email
recipient_email="yourmail@gmail.com"
``` 

5. Configure to your **SMTP Credentials**
```
# AWS credentials
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""

s3_bucket=""
s3_key="$folder_name/$uuid-$(basename ${zip_file})"
``` 

## Other configuration (Optional)
1. Change to your **Backup Directory** Path
```
backup_dir="./$folder_name"
```

## Final Configuration
1. Setting your cronjob (Example for Centos 7)
```
crontab -e
```
```
# Script will running every 1 AM
0 1 * * * bash /home/your_user_name/backup_postgresql.sh
```
to exit, esc press : and wq

2. Verify your cronjob settings (Example for Centos 7)
```
crontab -l 
```

## For Test
```
bash backup_postgresql.sh
```

## Made with ❤️ From Bali, Indonesia
### ramanaptr 
```
please to star this if you like and happy 🤙
```