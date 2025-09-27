#!/bin/bash
source ./common.sh
check_root


nginx_setup

systemctl enable nginx  &>>$LOG_FILE
VALIDATE $? "enable nginx"

systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "start nginx"

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE
VALIDATE $? "remove old code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "download app code"

cd /usr/share/nginx/html  &>>$LOG_FILE
VALIDATE $? "changing to directory"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "cp systemd service"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart nginx"

print_total_time