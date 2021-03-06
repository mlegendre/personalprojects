#!/bin/bash
# Global Variables
NAME="marc"
ROOT_DIR=$PWD
PROJECT=""

#TODO Find some way to refactor updating plugins so that if you install any plugin it will be updated
# find . -name ".git" -- This will give you all the plugins that are associated with a git repository

# This function asks the user whether they want to generate new api documents
function assets_question(){
  print_dash "Do you want to generate new API Documents y/n?"
  read -t 10 api_answer

  if [ -z "$api_answer" ]
    then
      api_answer="n"
  fi

  if [ "$api_answer" == "y" ];
   then
      bundle exec rake canvas:compile_assets
   else
      bundle exec rake canvas:compile_assets[false]
  fi
}

# This function iterates through the different plugins and updates them
# It now takes into account the qti_migration_tool and analytics plugins
function change_dir() {

  # TODO Refactor this bad boy, maybe something like split out the reading of directories and updating
  # and checking to make sure plugins are installed
  cd vendor/plugins

  print_dash "I am now going to update your plugins"

  dirs=( "qti_migration_tool" "multiple_root_accounts" "instructure_misc_plugin" "migration_tool" "analytics" "demo_site" )

 for i in "${dirs[@]}"
    do
      if [ -e $i ]
       then
        cd $i
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

function check_for_address_in_use(){
  #TODO If the ip address is in use find a way to kill the process and start the server back up

  if [[ "$?" == 1 ]];
   then
     echo "Your server might already be running somewhere, let me check that out for you"

     # kill $(ps aux | grep 'server' | awk '{print $2}')
  fi
}



function check_for_RAILS2(){

  if [[ ! -e "config/RAILS2" ]];
   then
    start_rails3_server
   else
     print_dash "It seems you are running RAILS version 2 would you like to upgrade y/n?"
     read rails_answer

     if [[ $rails_answer == "y" ]]
       then
         rm config/RAILS2
         bundle update
         start_rails3_server
     fi
     start_rails2_server
  fi
}

# This function checks out master and updates the repro
function checkout_master(){
  git reset --hard
  git checkout master
  git fetch
  git rebase origin/master

  rebase_error
}

function checkout_plugin(){

  print_dash "What is the name of the plugin that you are going to checkout?"
  read plugin

  if [ $PWD == $ROOT_DIR ];
   then
     cd $ROOT_DIR/vendor/plugins/$plugin
   else
     cd $plugin
   fi

  print_dash "Please give me the commit number that you want to checkout"
  read commit

  git fetch
  git fetch ssh://$NAME@gerrit.instructure.com:29418/$plugin refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit

  duplicated_patchsets
}

# This fucntion deletes old commits and checkouts out master code
function clear_commits(){
  print_dash "I am going to remove your old commits and checkout the newest code on master"

  git reset --hard
  git checkout master
  git branch | grep -v 'master$' | xargs git branch -D
  git fetch
  git rebase origin/master

  rebase_error
}

# This function asks the user if they would like to do anything else before starting up the server
function continue_on_question(){
  print_dash "Would you like to do anything else?"
  read -t 10 re_menu

  if [ -z "$re_menu" ]
    then
      re_menu="n"
  fi

  if [ "$re_menu" == "y" ];
   then
    cd $ROOT_DIR
    continue_on  
  else
    cd $ROOT_DIR
    update_migrate_compile
    start_delayed_job
  fi
}

# This case statement will let the user continue on to either add more commits or checkout plugin patchsets
function continue_on(){

  until [[ $non_default_menu_answer -eq 1 ]] || [[ $non_default_menu_answer -eq 2 ]]
  do
    echo "########################################"
    echo "Press 1 to checkout a commit(s)"
    echo "Press 2 to checkout a branch on a plugin"
    echo "########################################"
    read non_default_menu_answer
  done

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

function duplicated_patchsets(){
  if [[ "$?" == 128 ]];
   then
     print_dash_warning "There was a duplicate patchset. Removing and adding patchset back in"

     git branch -D $commit

     git checkout -b $commit

     git rebase origin/master

     rebase_error
  fi
}

function error_stop_process(){
  #TODO find a way to stop the script and output the process that failed
  process_problem=$(fc -ln -1)

  if [[ "$?" > 0 ]];
   then
    echo "There was an error, stopping the script. Check $process_problem"
  fi
}

# This function just zeroes out the logs since they are constantly being written and the space adds up
function kill_logs(){
  cd log

  > delayed_job.log
  > development.log
  > production.log

  cd $ROOT_DIR
}

# The menu found at the beginning of the program
function menu(){

  until [[ $choice -le 6 ]] && [[ $choice > 0 ]]
  do
    echo "What do you want to do?"
    echo "Press 1 to delete your branches and start from scratch"
    echo "Press 2 to checkout a commit"
    echo "Press 3 to see what commit you are on and checkout a previous commit"
    echo "Press 4 to checkout a branch on a plugin"
    echo "Press 5 to just update your master branch"
    echo "Press 6 to exit"
    read choice
  done
}

# This method checks out multiple patchsets
function multiple_patchsets(){
  
  print_dash "Would you like to checkout multiple patchsets?"
  read multi_patch
  
  if [ -z "$multi_patch" ]
    then
     multi_patch="n"
  fi

  if [ "$multi_patch" == "y" ];
   then
    print_dash "How many patchsets did you want to checkout?"  
    read num_patchsets

  i=1
  while [ $i -le $num_patchsets ]; do  
   if [ $i == 1 ]
    then  
     
     print_dash "What is the commit number for the first patchset?"
     
     read commit
     git fetch ssh://$NAME@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD  
     git checkout -b $commit

     duplicated_patchsets

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

# This function just prints ### to match whatever text is give to it
function print_dash() {
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
  printf '\e[38;5;46m%-6s\e[m' "$1"
  echo ""
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
}

function print_dash_error() {
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
  printf '\e[38;5;124m%-6s\e[m' "$1"
  echo ""
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
}

function print_dash_warning() {
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
  printf '\e[38;5;226m%-6s\e[m' "$1"
  echo ""
  for (( x=0; x < ${#1}; x++ )); do
    printf "#"
  done
  echo ""
}

function rebase_error(){
  #TODO find out when you have a rebase issue and recover from it

  if [[ "$?" == 1 ]];
   then
    print_dash_error "There was a conflict in your commit, have the developer rebase their commit"
    exit 0
  fi
}

function redis_check(){
  #brew info redis | grep usr/local/Cellar
  redis_launchctl="~/Library/LaunchAgents/homebrew.mxcl.redis.plist"
  redis_install_dir=/usr/local/Cellar/redis

  if [ -d "$redis_install_dir" ];
    then
      if [[ ! -L "$redis_launchctl" ]];
        then

          launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
          launchctl load ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
      else

          ln -sfv /usr/local/opt/redis/*.plist ~/Library/LaunchAgents
          launchctl load ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
      fi
  else
    print_dash "You do not seem to have redis installed, wait while I do that for you"

    brew install redis

    ln -sfv /usr/local/opt/redis/*.plist ~/Library/LaunchAgents

    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.redis.plist

    cp config/cache_store.yml.example config/cache_store.yml

    cp config/redis.yml.example config/redis.yml

    printf "development:
  servers:
    - redis://localhost
  database: 1" >> config/redis.yml

   sed -i.bak 's/# cache_store: redis_store/cache_store: redis_store/' config/cache_store.yml

   rm config/cache_store.yml.bak

  fi
}

# This function just checks out one patchset
function single_checkout(){
  print_dash "Please give me the commit number that you want to checkout"
  read commit

  git fetch ssh://$NAME@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit

  duplicated_patchsets
}

# This function starts up the script/server
function start_delayed_job(){
  print_dash "Stopping and then Starting up your delayed jobs now"

  bundle exec script/delayed_job stop
  bundle exec script/delayed_job start

  check_for_RAILS2
}

function start_rails3_server(){

  print_dash "Starting up your RAILS3 server now"
  print_dash "Would you like to test i18n strings?"
  read -t 10 i18n_answer

  if [ -z "i18n_answer" ];
    then
     i18n_answer="n"
  fi

  if [ "$i18n_answer" == "y" ];
    then
      bundle exec rake RAILS_LOAD_ALL_LOCALES=true
      rake i18n:generate_js
      LOLCALIZE=true USE_OPTIMIZED_JS=true rails s
    else
      rails s 
  fi
}

function start_rails2_server() {

  print_dash "Starting up your RAILS2 server now"
  print_dash "Would you like to test i18n strings?"
  read -t 10 i18n_answer

  if [ -z "i18n_answer" ];
    then
     i18n_answer="n"
  fi

  if [ "$i18n_answer" == "y" ];
    then
      bundle exec rake RAILS_LOAD_ALL_LOCALES=true
      rake i18n:generate_js
      LOLCALIZE=true USE_OPTIMIZED_JS=true bundle exec script/server SCRIPT_SERVER_NO_GUARD=1
    else
      bundle exec script/server SCRIPT_SERVER_NO_GUARD=1
  fi
}

# This function updates gems, migrates the database, and compiles assets
function update_migrate_compile(){
  print_dash "Running a database migrate and compiling your assets"

  bundle update

  if [[ "$?" != 0 ]];
   then
    bundle install
  fi

  bundle exec rake db:migrate

  if [[ "$?" != 0 ]];
   then
    print_dash_error "There was a problem with migrating your database you need to manually figure out what happened"
    exit
  fi
  assets_question
}

####################BEGIN MAIN METHODS###################################

  redis_check

  kill_logs

  menu

  case $choice in
    [1]*)
    #This is the clear old commits and update master option
      clear_commits

      change_dir

      cd $ROOT_DIR

      continue_on_question
    ;;
    [2]*)
    #This is the multiple commits option

      checkout_master

      change_dir

      cd $ROOT_DIR

      multiple_patchsets

      continue_on_question
    ;;
    [3]*)
    #This shows the git log of the most recent commits
      print_dash "How many commits do you have checked out?"

      read num_commits

      git log -$num_commits

      continue_on_quesiton
    ;;
    [4]*)
    #This is the checkout a plugin commit option
      checkout_master

      change_dir

      checkout_plugin

      cd $ROOT_DIR

      continue_on_question
    ;;
    [5]*)
    #This is the update master only option
      checkout_master

      change_dir

      cd $ROOT_DIR

      continue_on_question
    ;;


  esac

