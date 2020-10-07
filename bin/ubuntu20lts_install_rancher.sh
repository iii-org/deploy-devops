#!/bin/bash

WORK_DIR=$HOME
LOGFILE=$WORK_DIR/log/rancher_install.log
echo $LOGFILE
if [ ! -d $WORK_DIR/log ]; then
  mkdir $WORK_DIR/log
fi

if [ ! -f $LOGFILE ]; then
  touch $LOGFILE
fi

mkdir $WORK_DIR/rancher &>> $LOGFILE
chmod 755 $WORK_DIR/rancher &>> $LOGFILE
docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v $WORK_DIR/rancher:/var/lib/rancher rancher/rancher:v2.4.5 &>> $LOGFILE

