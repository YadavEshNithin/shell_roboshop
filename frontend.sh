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



dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"



systemctl enable nginx  &>>$LOG_FILE
systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE
VALIDATE $? "removing default nginx content frontend"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$LOG_FILE
VALIDATE $? "downloading  code frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend"


rm -rf /etc/nginx/nginx.confi/ &>>$LOG_FILE
VALIDATE $? "removing default nginx content"

cp $SCRIPT_DIR/nginx.config /etc/nginx/nginx.conf
VALIDATE $? "nginx config frontend added"


systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "restarting nginx frontend"


