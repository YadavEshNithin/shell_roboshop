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



dnf module disable nginx -y
VALIDATE $? "disabling nginx"

dnf module enable nginx:1.24 -y
VALIDATE $? "enabling nginx"

dnf install nginx -y
VALIDATE $? "installing nginx"



systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/* 
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "downloading  code frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "unzipping frontend"


cp $SCRIPT_DIR/nginx.config /etc/nginx/nginx.conf
VALIDATE $? "nginx config frontend added"


systemctl restart nginx 
VALIDATE $? "restarting nginx frontend"


