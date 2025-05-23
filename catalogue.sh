#!/bin/bash
Userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $Userid -ne 0 ]
then
    echo "error no root access, please go with root access"
    exit 1
else
    echo "you are having root access"
fi


VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling catalogue"


dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling catalogue"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing catalogue"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "user CREATING catalogue"
else
    echo -e "user already created...$Y SKIPPING THIS STEP $N"
fi


mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "tmp dowmloaded catalogue"

rm -rf /app/*
cd /app 

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "added in app folder catalogue code"


cd /app 
npm install  &>>$LOG_FILE
VALIDATE $? "npm installed"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service




systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "starting catalogue"



cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installed client"

STATUS=$(mongosh --host mongodb.rshopdaws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.rshopdaws84s.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi



