#!/bin/bash
#Global Variables
NAME="marc"

echo "What do you want to do?"
echo "Press 1 to delete your branches and start from scratch"
echo "Press 2 to checkout a commit"
echo "Press 3 to see what commit you are on"
echo "Press 4 to checkout a branch on a plugin"
echo "Press 5 to just update your master branch"
echo "Press 6 to exit"
read choice

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
function start_server() {

print_dash "Stopping and then Starting up your delayed jobs now"

bundle exec script/delayed_job stop
bundle exec script/delayed_job start

print_dash "Starting up your server now"

bundle exec script/server SCRIPT_SERVER_NO_GUARD=1
}

#This function iterates through the different plugins and updates them
#It now takes into account the analytics plugin 
function change_dir() {
cd vendor/plugins
dirs=( "multiple_root_accounts" "instructure_misc_plugin" "migration_tool" "analytics" "demo_site" )

     for i in "${dirs[@]}"
     do
       if [ -e $i ]
         then
             cd $i
             git reset --hard
             git checkout master
             git pull origin master
             git rebase origin/master
             cd ../
         else
           if [ $i == "analytics" ]
             then 
               print_dash "You seem to be missing the $i plugin, I will now install this for you"
               git clone ssh://$NAME@gerrit.instructure.com:29418/canvalytics.git analytics
            else
               print_dash "You seem to be missing the $i plugin, I will now install this for you"
               git clone ssh://$NAME@gerrit.instructure.com:29418/$i.git       
           fi
       fi
      done
}

case $choice in
[1]*)

#Clears out old commits and updates master
print_dash "I am going to remove your old commits and checkout the newest code on master"

git reset --hard
git checkout master
git branch | grep -v 'master$' | xargs git branch -D
git pull origin master

print_dash "I am now going to update your plugins"

change_dir 
cd ../../

print_dash "Running a database migrate and bundle update"

bundle exec rake db:migrate
bundle update
bundle exec rake canvas:compile_assets[false]

print_dash "You are ready to checkout a commit"
;;

[2]*)

print_dash "Would you like to checkout multiple patchsets?"

read multi_patch

if [ "$multi_patch" == "y" ];
then

  print_dash "How many patchsets did you want to checkout?"
  
  read num_patchsets

  git checkout master
  git pull origin master 
  
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

  print_dash "Please give me the commit number that you want to checkout"
  read commit

  git fetch ssh://$NAME@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit
fi

print_dash "I am now going to update your plugins"


change_dir
cd ../../

bundle update
bundle exec rake db:migrate



print_dash "Do you want to generate new API Documents y/n?"
read api_answer


if [ "$api_answer" == "y" ]; 
then
    bundle exec rake canvas:compile_assets
else 
    bundle exec rake canvas:compile_assets[false]
fi

start_server
;;

[3]*)

print_dash "How many commits do you have checked out?"
read num_commits

git log -$num_commits
;;

[4]*)
print_dash "What is the name of the plugin that you are going to checkout?"
read plugin

print_dash "I am going to first update your plugins"

change_dir 

cd $plugin

print_dash "Please give me the commit number that you want to checkout"
read commit

git pull origin master
git fetch ssh://$NAME@gerrit.instructure.com:29418/$plugin refs/changes/$commit && git checkout FETCH_HEAD
git checkout -b $commit




cd ../../../
git checkout master
git pull origin master
bundle update
bundle exec rake db:migrate
bundle exec rake canvas:compile_assets[false]
;;
[5]*)
git checkout master
git pull origin master

print_dash "I am now going to update your plugins"

change_dir 
cd ../../

print_dash "Running a database migrate and bundle update"
bundle update
bundle exec rake db:migrate
bundle exec rake canvas:compile_assets[false] 


start_server
	
;;
esac

