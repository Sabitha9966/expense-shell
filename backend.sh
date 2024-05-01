#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Please enter DB password:"
read -s mysql_root_password


VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y   &>>$LOGFILE
VALIDATE $? "diabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y  &>>$LOGFILE
VALIDATE $? "Installing nodejs"

id expense   &>>$LOGFILE
if [ $? -ne 0 ] 
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "creating useradd expense"
else
    echo  -e "useradd expense already exists...$Y SKIPPING $N"
fi    

mkdir -p /app   &>>$LOGFILE
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip  &>>$LOGFILE
VALIDATE $? "downloading the app code"

cd /app 
rm -rf /app/*  #if we run repeatedly strcking at unziop,so we use remove command and next unzip
unzip /tmp/backend.zip  &>>$LOGFILE
VALIDATE $? "Extracted backend code"

npm install  &>>$LOGFILE
VALIDATE $? "Installing all dependencies of nodejs"

#absolute path /home/ec2-user/expense-shell
#steps to get absolute path..code pus in gitbash, git pull in super putty, ls -l, pwd...

cp /home/ec2-user/expense-shell/backend.service  /etc/systemd/system/backend.service  &>>$LOGFILE
VALIDATE $? "copied backend service"

systemctl daemon-reload  &>>$LOGFILE
systemctl start backend  &>>$LOGFILE
systemctl enable backend &>>$LOGFILE
VALIDATE $? "starting and enabling backend"

dnf install mysql -y   &>>$LOGFILE
VALIDATE $? "Installing mysql client"

mysql -h db.purvanshi.online -uroot -p-p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Schema loading"

systemctl restart backend  &>>$LOGFILE
VALIDATE $? "Restart backend"
