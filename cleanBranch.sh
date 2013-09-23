#!/bin/bash
# Global Variables
NAME="marc"
ROOT_DIR=$PWD

# The menu found at the beginning of the program
function menu(){
  echo "What do you want to do?"
  echo "Press 1 to delete your branches and start from scratch"
  echo "Press 2 to checkout a commit"
  echo "Press 3 to see what commit you are on and checkout a previous commit"
  echo "Press 4 to checkout a branch on a plugin"
  echo "Press 5 to just update your master branch"
  echo "Press 6 to exit"
  read choice
}

# This function just zeroes out the logs since they are constantly being written and the space adds up
function kill_logs(){
  cd log

  > delayed_job.log
  > development.log
  > production.log

  cd $ROOT_DIR 
}

# This function just prints ### to match whatever text is give to it
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

# This function asks the user whether they want to generate new api documents
function assets_question(){
  print_dash "Do you want to generate new API Documents y/n?"
  read api_answer

  if [ "$api_answer" == "y" ]; 
   then
      bundle exec rake canvas:compile_assets
   else 
      bundle exec rake canvas:compile_assets[false]
  fi
}

# This function starts up the script/server
function start_server() {
  print_dash "Stopping and then Starting up your delayed jobs now"

  bundle exec script/delayed_job stop
  bundle exec script/delayed_job start

  print_dash "Starting up your server now"

  bundle exec script/server SCRIPT_SERVER_NO_GUARD=1
}

# This fucntion deletes old commits and checkouts out master code
function clear_commits(){
  print_dash "I am going to remove your old commits and checkout the newest code on master"

  git reset --hard
  git checkout master
  git branch | grep -v 'master$' | xargs git branch -D
  git fetch
  git rebase origin/master
}

# This function asks the user if they would like to do anything else before starting up the server
function continue_on_question(){
  print_dash "Would you like to do anything else?"
  read re_menu

  if [ "$re_menu" == "y" ];
   then
    continue_on  
  else
    update_migrate_compile
    start_server	
  fi
}

# This case statement will let the user continue on to either add more commits or checkout plugin patchsets
function continue_on(){
  echo "########################################"
  echo "Press 1 to checkout a commit(s)"
  echo "Press 2 to checkout a branch on a plugin"
  echo "########################################"
  read non_default_menu_answer

  case $non_default_menu_answer in
    [1]*)
      multiple_patchsets
      continue_on_question
    ;;
    [2]*)
      checkout_plugin
      continue_on_question
    ;;
  esac	
}

# This function checks out master and updates the repro
function checkout_master(){
  git checkout master
  git fetch
  git rebase origin/master
}

# This function updates gems, migrates the database, and compiles assets 
function update_migrate_compile(){
  print_dash "Running a database migrate and compiling your assets"

  bundle update
  bundle exec rake db:migrate
  bundle exec rake canvas:compile_assets[false]
}

# This method checks out multiple patchsets
multiple_patchsets(){
  print_dash "Would you like to checkout multiple patchsets?"
  read multi_patch

  if [ "$multi_patch" == "y" ];
   then
    print_dash "How many patchsets did you want to checkout?"  
    read num_patchsets

    checkout_master

  i=1
  while [ $i -le $num_patchsets ]; do  
   if [ $i == 1 ]
    then  
     
     print_dash "What is the commit number for the first patchset?"
     
     read commit
     git fetch ssh://$NAME@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD  
     git checkout -b $commit 
   else
    
    print_dash "What is the commit number for patchset #$i?"
    
    read commit
    git fetch ssh://$NAME@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git cherry-pick FETCH_HEAD
   
   fi
  ((i ++))
  done
  
  git rebase origin/master
else

single_checkout

fi
}

# This function just checks out one patchset 
function single_checkout(){
  print_dash "Please give me the commit number that you want to checkout"
  read commit

  git fetch ssh://$NAME@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit
}

function checkout_plugin(){
  print_dash "What is the name of the plugin that you are going to checkout?"
  read plugin

  cd $plugin

  print_dash "Please give me the commit number that you want to checkout"
  read commit

  git fetch
  git fetch ssh://$NAME@gerrit.instructure.com:29418/$plugin refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit
}

# This function iterates through the different plugins and updates them
# It now takes into account the qti_migration_tool and analytics plugins 
# function change_dir() {
function change_dir() {
  cd vendor/plugins

  print_dash "I am now going to update your plugins" 

  dirs=( "qti_migration_tool" "multiple_root_accounts" "instructure_misc_plugin" "migration_tool" "analytics" "demo_site" )

  for i in "${dirs[@]}"
    do
      if [ -e $i ]
       then
        cd $i
        git reset --hard

        checkout_master

        cd ../
      else
        if [ $i == "analytics" -o $i == "qti_migration_tool" ]
         then
           if [ $i == "analytics" ]
            then
             print_dash "You seem to be missing the $i plugin, I will now install this for you"
             git clone ssh://$NAME@gerrit.instructure.com:29418/canvalytics.git analytics
           else
             cd ..
             print_dash "You seem to be missing the $i plugin, I will now install this for you"
             git init
             git clone ssh://$NAME@gerrit.instructure.com:29418/qti_migration_tool.git QTIMigrationTool
             ln -s $ROOT_DIR/vendor/QTIMigrationTool plugins/qti_migration_tool
             cd plugins
           fi
         else
           print_dash "You seem to be missing the $i plugin, I will now install this for you"
           git clone ssh://$NAME@gerrit.instructure.com:29418/$i.git
        fi
      fi
  done
}

  kill_logs

  menu

  case $choice in
    [1]*)

      clear_commits
      
      change_dir 
      
      cd $ROOT_DIR
      
      continue_on_question
    ;;
    [2]*)
      multiple_patchsets
      
      change_dir
      
      cd $ROOT_DIR
      
      continue_on_question

      assets_question
    ;;
    [3]*)

      print_dash "How many commits do you have checked out?"
    
      read num_commits

      git log -$num_commits
    ;;
    [4]*)

      change_dir 

      checkout_plugin

      cd $ROOT_DIR

      checkout_master

      update_migrate_compile
    ;;
    [5]*)

      checkout_master

      change_dir 
      
      cd $ROOT_DIR

      update_migrate_compile

     continue_on_question
    ;;
  esac

