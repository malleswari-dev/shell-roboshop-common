#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.malleswari.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
# /var/log/shell-practice/16-logs/log
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "script started executed at:$(date)"  | tee -a $LOG_FILE

check_root () {
    if [ $USERID -ne 0 ]; then
        echo "ERROR:please run this script with root privilage"
        exit 1 # failure is othher than 0
    fi
}
     

     
# functions receives inputs through args like shell script args.
VALIDATE () { 
    if [ $1 -ne 0 ] ; then
        echo -e "  $2 is $R failure $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e " $2 is $G success $N"  | tee -a $LOG_FILE
    fi
}

nodejs_setup() {
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "disable nodejs"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "enable nodejs"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "install nodejs"

    npm install &>>$LOG_FILE
    VALIDATE $? "install dependencies"
}

app_setup () {
    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
        VALIDATE $? "creating system user" &>>$LOG_FILE
    else
        echo -e " user is already exist ... $Y SKIPPING $N"
    fi

    mkdir -p /app 
    VALIDATE $? "creating app directory"

    curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    VALIDATE $? "download code"
    cd /app
    VALIDATE $? "changing app directory" 

    rm -rf /app/*
    VALIDATE $? "remove old code"

    unzip /tmp/$app_name.zip &>>$LOG_FILE
    VALIDATE $? "unzip code"
}

systemd_setup () {
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service &>>$LOG_FILE
    VALIDATE $? "copy systemctl service"

    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $app_name &>>$LOG_FILE
    VALIDATE $? "enable $app_name" 

    systemctl start $app_name
    VALIDATE $? "start $app_name"  
}

systemctl_restart () {
    systemctl restart $app_name
    VALIDATE $? "restart $app_name"
}
print_total_time () {
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME))
    echo -e "script executed in:$Y  $TOTAL_TIME seconds $N"
}