#!/bin/bash
set -e

# ===============================================================
# ==== 🔥 @AUHTOR: https://www.linkedin.com/in/ramanaptr 🔥 =====
# ================ Created since 27-Aug-2023 ====================
# ===============================================================
# Please prepare "zip", "expect", "aws cli", and "sendemail" on your server to run this script 👍
# Remember to change of path "psql_path" and "pg_dump_path" if which command is not working


# ===============================================================
# ==================== DEFAULT VARIABLE AREA ====================
# ===============================================================

# Default Get the current timestamp
timestamp=$(date +'%d-%m-%Y_%H_%M_%S')
timestamp_only_date=$(date +'%d-%m-%Y')
uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Default Set the base filename and extension
folder_name="backup-database-production"
base_filename="backup"
extension=".sql"
zip_name="$folder_name-$timestamp.zip"
backup_dir="./$folder_name"
zip_file="./$zip_name"

# Default Set PSQL and PG DUMP
psql_path=$(which psql)
pg_dump_path=$(which pg_dump)

# Default Set For SMTP
smtp_use_tls="-S smtp-use-starttls"
smtp_auth="-S smtp-auth=login"

# Default S3 Storage
s3_key="$folder_name/$uuid-$(basename ${zip_file})"

# ===============================================================
# ================= CHANGEABLE VARIABLE AREA ====================
# ===============================================================

# ZIP Configuration
zip_password="your_password"

# Database connection details
backup_all=false # false means backup will split per-schema
db_host="http://localhost"
db_port="5432"
db_username="db_username"
db_name="db_name"
db_password="db_password"

# Sender Email
smtp_user="yourmail@gmail.com"
smtp_password="your_mail_password"
smtp_host="smtp.gmail.com"
smtp_port="587"

# Recipient Email Where do you want to send the link to the S3 storage
recipient_email="yourmail@gmail.com"

# AWS credentials
export AWS_ACCESS_KEY_ID="aws_key"
export AWS_SECRET_ACCESS_KEY="aws_secret_key"
export AWS_DEFAULT_REGION="aws_region"

# S3 bucket details
s3_bucket="your_bucket_storage"

# ===============================================================
# ======================= PRE BACKUP AREA =======================
# ===============================================================

mkdir -p "$backup_dir"

# ===============================================================
# ================== BACKUP PROCESS AREA ========================
# ===============================================================

# Set the PostgreSQL password
export PGPASSWORD=$db_password

if $backup_all; then

  # Generate the pg_dump command to backup all schemas
  pg_dump_cmd="$pg_dump_path --verbose --host=$db_host --port=$db_port --username=$db_username --format=p --inserts --file $backup_filename $db_name"
  
  # Execute the pg_dump command
  eval ${pg_dump_cmd}

else 
  # Retrieve the list of all schemas from the database
  schemas=($($psql_path -h $db_host -p $db_port -U $db_username -d $db_name -t -c "SELECT schema_name FROM information_schema.schemata where schema_owner = '$db_username'"))

  #  Exe Loop Schema
  for schema in "${schemas[@]}"; do
    backup_file="${backup_dir}/${base_filename}_${schema}_${timestamp}.sql"
    pg_dump_cmd="$pg_dump_path --verbose --host=$db_host --port=$db_port --username=$db_username --format=p --inserts --file $backup_file --schema="$schema" $db_name"

    # Execute the pg_dump command
    eval ${pg_dump_cmd}
  done
fi

# Unset the PostgreSQL password
unset PGPASSWORD

# ===============================================================
# ================ ZIP, UPLOAD AND SEND FILE AREA ===============
# ===============================================================

# Use expect to automate/bypass entering the zip password
expect << EOD
spawn zip -er $zip_name $backup_dir
expect "Enter password:"
send "$zip_password\r"
expect "Verify password:"
send "$zip_password\r"
expect eof
EOD

# Upload backup to S3
echo ""
echo "Created by https://www.linkedin.com/in/ramanaptr"
echo "I'm glad you use the tool I made. Hope you are always happy 😊"
echo ""

echo "Have you already installed \"brew install awscli\" ?"
aws s3 cp ${zip_file} s3://${s3_bucket}/${s3_key} --acl public-read
echo "Removing $zip_file and $backup_dir"
rm -rf $zip_file
rm -rf $backup_dir

# Send email with S3 link
# Email details

email_subject="Backup SQL of $db_name $timestamp_only_date"
email_body="Message from the server! The link for downloading the ${db_name} SQL files backup at $timestamp_only_date: https://${s3_bucket}.s3.amazonaws.com/${s3_key} the password is: <CONTACT YOUR DEV-OPS!>"
email_content="From: $smtp_user\nTo: $recipient_email\nSubject: $email_subject\n\n$email_body"

# Construct the email headers
email_headers="MIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8\n"

# Construct the email data
email_data="$email_headers\n$email_content"

# Use sendemail to send the email
echo ""
echo "Have you already installed \"brew install sendemail\" ?"
echo -e "$email_data" | sendemail -f $smtp_user -t $recipient_email -u $email_subject -m $email_body -s $smtp_host:$smtp_port -xu $smtp_user -xp $smtp_password -o tls=yes

echo ""
echo "🚀 Congratulations! 🚀"
echo "Job all done and Email sent successfully."
echo ""

# ===============================================================
# =========================== DONE ==============================
# ===============================================================
