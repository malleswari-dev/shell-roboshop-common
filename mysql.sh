#!/bin/bash
source ./common.sh

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "install mysql"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enable mysql"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "start mysql"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "set password"

print_total_time