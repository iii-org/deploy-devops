#!/bin/bash

WORK_DIR=$HOME
LOGFILE=$WORK_DIR/log/docker_install.log
mkdir $WORK_DIR/log
touch $LOGFILE

sudo apt-get update -y &>> $LOGFILE
sudo apt-get install     apt-transport-https     ca-certificates     curl  gnupg-agent   software-properties-common -y &>> $LOGFILE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable" &>> $LOGFILE
apt-get update -y &>> $LOGFILE 
apt-get install docker-ce docker-ce-cli containerd.io -y &>> $LOGFILE
usermod -aG docker $SUDO_USER &>> $LOGFILE