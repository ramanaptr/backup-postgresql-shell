#!/bin/bash
set -e

# ===============================================================
# ==== 🔥 @AUHTOR: https://www.linkedin.com/in/ramanaptr 🔥 =====
# ================ Created since 27-Aug-2023 ====================
# ===============================================================
# Please prepare "zip", "expect", "aws cli", and "sendemail" on your server to run this script 👍
# Remember to change of path "psql_path" and "pg_dump_path"

# Path to the fullchain.pem file from Certbot
# certbot_fullchain=""

# Default Get the current timestamp
timestamp=$(date +'%d-%m-%Y_%H_%M_%S')
timestamp_only_date=$(date +'%d-%m-%Y')
uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Default Set the base filename and extension
folder_name="backup-database-production"
base_filename="backup"
extension=".sql"
zip_name="$folder_name-$timestamp.zip"
zip_password="your_password"
backup_dir="./$folder_name"

# ===============================================================
# ======================= VARIABLE AREA =========================
# ===============================================================

# CENTOS 7 ENV FOR PSQL PATH
# pg_dump_path="/usr/bin/pg_dump"
# psql_path="/usr/bin/psql"

# MAC ENV FOR PSQL PATH
psql_path="/usr/local/bin/psql"
pg_dump_path="/usr/local/Cellar/postgresql@14/14.9/bin/pg_dump"

# Database connection details
backup_all=false # false is mean backup will split per-schema
db_host="http://localhost"
db_port="5432"
db_username="postgres"
db_name="your_db"
db_password="your_db_password"

# Sender Email
smtp_host="smtp.gmail.com"
smtp_port="587"
smtp_use_tls="-S smtp-use-starttls"
smtp_auth="-S smtp-auth=login"
smtp_user="yourmail@gmail.com"
smtp_password="your_mail_password"

# Recipient Email
recipient_email="yourmail@gmail.com"

# AWS credentials
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""

# S3 bucket details
zip_file="./$zip_name"
s3_bucket=""
s3_key="$folder_name/$uuid-$(basename ${zip_file})"

# ===============================================================
# ======================= PRE BACKUP AREA =======================
# ===============================================================

mkdir -p "$backup_dir"

# ===============================================================
# ======================= BACKUP AREA ===========================
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
# =================== ZIP AND SEND FILE AREA ====================
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
echo "I'm glad you use the tool I made. Hope you always happy 😊"
echo ""

echo "Are you already install \"brew install awscli\" ?"
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

# Use sendmail to send the email
echo ""
echo "Are you already install \"brew install sendemail\" ?"
echo -e "$email_data" | sendemail -f $smtp_user -t $recipient_email -u $email_subject -m $email_body -s $smtp_host:$smtp_port -xu $smtp_user -xp $smtp_password -o tls=yes

echo ""
echo "🚀 Congratulations! 🚀"
echo "Job all done and Email sent successfully."
echo ""

# ===============================================================
# =========================== DONE ==============================
# ===============================================================
