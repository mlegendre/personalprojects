#!/bin/sh

CONFIG_PATH=data/hudson/canvas-lms/config/domain.yml

ip=`curl http://ipecho.net/plain`  

printf "development:\n  domain:$ip\n" > $CONFIG_PATH
printf "production:\n  domain:$ip\n" >> $CONFIG_PATH
printf "  # whether this instance of canvas is served over ssl (https) or not
  # defaults to true for production, false for test/development
  ssl: false
  # files_domain: \"canvasfiles.example.com\"" >> $CONFIG_PATH
