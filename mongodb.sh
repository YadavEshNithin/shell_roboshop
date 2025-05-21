Userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying repo"

dnf install mongodb-org -y 
VALIDATE $? "installing mongodb"

systemctl enable mongod 
VALIDATE $? "enabling mongodb"

systemctl start mongod 
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "changed config file for remote connections"

systemctl restart mongod 
VALIDATE $? "restarting mongodb"