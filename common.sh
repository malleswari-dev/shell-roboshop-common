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
MYSQL_HOST=mysql.malleswari.fun
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

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
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

catalogue_setup () {
    cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
    VALIDATE $? "copy mongo repo"

    dnf install mongodb-mongosh -y &>>$LOG_FILE
    VALIDATE $? "install mongodb client"

    INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
    if [ $INDEX -le 0 ]; then
        mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
        VALIDATE $? "Load catalogue products"
    else
        echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
    fi
    #mongosh --host $MONGODB_HOST </app/db/master-data.js &>> LOG_FILE
    #VALIDATE $? "load catalogue products"
}
mongodb_setup () {
    cp mongo.repo /etc/yum.repos.d/mongo.repo
    VALIDATE $? "Adding Mongo repo"

    dnf install mongodb-org -y &>>$LOG_FILE
    VALIDATE $? "Installing MongoDB"

    systemctl enable mongod &>>$LOG_FILE
    VALIDATE $? "Enable MongoDB"

    systemctl start mongod 
    VALIDATE $? "Start MongoDB"

    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
    VALIDATE $? "Allowing remote connections to MongoDB"
}

redis_setup () {
    dnf module disable redis -y  &>>$LOG_FILE
    VALIDATE $? "disabling redis"

    dnf module enable redis:7 -y &>>$LOG_FILE
    VALIDATE $? "enabling redis 7"

    dnf install redis -y &>>$LOG_FILE
    VALIDATE $? "install redis"

    sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
    VALIDATE $? "allowing remote connections to redis"

    systemctl enable redis &>>$LOG_FILE
    VALIDATE $? "enable redis"

    systemctl start redis &>>$LOG_FILE
    VALIDATE $? "start redis"
}

mysql_setup () {
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "install mysql"

    systemctl enable mysqld &>>$LOG_FILE
    VALIDATE $? "enable mysql"

    systemctl start mysqld &>>$LOG_FILE
    VALIDATE $? "start mysql"
    mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
    VALIDATE $? "set password"
}

java_setup () {
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "install maven"
    mvn clean package &>>$LOG_FILE
    VALIDATE $? "cleaning package"

    mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
    VALIDATE $? "moving to shipping.jar"
}

rabbitmq_setup () {
    cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
    VALIDATE $? "copy systemd service"

    dnf install rabbitmq-server -y &>>$LOG_FILE
    VALIDATE $? "install rabbitmq"

    systemctl enable rabbitmq-server &>>$LOG_FILE
    VALIDATE $? "enable rabbitmq"

    systemctl start rabbitmq-server &>>$LOG_FILE
    VALIDATE $? "start rabbitmq"
    rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
    #VALIDATE $? "add user"
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
    VALIDATE $? "rabbitmq permissions"
}

python_setup () {
    dnf install python3 gcc python3-devel -y &>>$LOG_FILE
    VALIDATE $? "install python3"

    pip3 install -r requirements.txt  &>>$LOG_FILE
    VALIDATE $? "install pip3"
}

nginx_setup () {
    dnf module disable nginx -y &>>$LOG_FILE
    VALIDATE $? "disable nginx"

    dnf module enable nginx:1.24 -y &>>$LOG_FILE
    VALIDATE $? "enable nginx:1.24"

    dnf install nginx -y &>>$LOG_FILE
    VALIDATE $? "install nginx"
}
app_restart () {
    systemctl restart $app_name
    VALIDATE $? "restart $app_name"
}
print_total_time () {
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME))
    echo -e "script executed in:$Y  $TOTAL_TIME seconds $N"
}