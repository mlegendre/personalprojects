#!/bin/bash


function print_dash() {
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
  printf "$1"
  echo ""
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
 }


    #This function starts up the script/server
 function start_server {

  echo "###################################################"
  echo "Stopping and then Starting up your delayed jobs now"
  echo "###################################################"

  bundle exec script/delayed_job stop
  bundle exec script/delayed_job start
  echo "###########################"
  echo "Starting up your server now"
  echo "###########################"
  bundle exec script/server SCRIPT_SERVER_NO_GUARD=1
 }
