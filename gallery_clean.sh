#!/bin/bash
# Global Variables
NAME="marc"
ROOT_DIR=$PWD
PROJECT="gallery"

function duplicated_patchsets(){
  if [[ "$?" == 128 ]];
   then
     echo "There was a duplicate patchset"

     git branch -D $commit

     git checkout -b $commit

     git rebase origin/master

     rebase_error
  fi
}

# The menu found at the beginning of the program
function menu(){
  echo "What do you want to do?"
  echo "Press 1 to delete your branches and start from scratch"
  echo "Press 2 to checkout a commit"
  echo "Press 3 to see what commit you are on and checkout a previous commit"
  echo "Press 4 to just update your master branch"
  echo "Press 5 to exit"
  read choice
}

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
    multiple_patchsets
    continue_on_question
  else
    cd $ROOT_DIR
    update_migrate_compile

    start_server
  fi
}

function start_server() {
  print_dash "Starting up your server on port 4000 now"

  rails s -p4000

}

# This method checks out multiple patchsets
multiple_patchsets(){

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
     git fetch ssh://$NAME@gerrit.instructure.com:29418/gallery refs/changes/$commit && git checkout FETCH_HEAD
     git checkout -b $commit
     duplicated_patchsets
   else

    print_dash "What is the commit number for patchset #$i?"

    read commit
    git fetch ssh://$NAME@gerrit.instructure.com:29418/gallery refs/changes/$commit && git cherry-pick FETCH_HEAD

   fi
  ((i ++))
  done

  git rebase origin/master

  rebase_error
else

single_checkout

fi
}

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

function rebase_error(){
  if [[ "$?" == 1 ]];
   then
    print_dash "There was a conflict in your commit, have the developer rebase their commit"
    exit
  fi
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

# This function checks out master and updates the repro
function checkout_master(){
  git reset --hard
  git checkout master
  git fetch
  git rebase origin/master
}

# This function updates gems, migrates the database, and compiles assets
function update_migrate_compile(){
  print_dash "Running a database migrate"

  bundle install
  bundle exec rake db:migrate

  if [[ "$?" != 0 ]];
   then
    print_dash "There was a problem with migrating your database you need to manually figure out what happened"
    exit
  fi
}

function single_checkout(){
  print_dash "Please give me the commit number that you want to checkout"
  read commit

  git fetch ssh://$NAME@gerrit.instructure.com:29418/$PROJECT refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit
  duplicated_patchsets

  git rebase origin/master

  rebase_error
}

 kill_logs

  menu

  case $choice in
    [1]*)
    #This is the clear old commits and update master option
      clear_commits



      cd $ROOT_DIR

      continue_on_question
    ;;
    [2]*)
    #This is the multiple commits option

      checkout_master

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
    #This is the update master only option
      checkout_master

      cd $ROOT_DIR

      continue_on_question
    ;;
  esac


