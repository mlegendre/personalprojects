#!/bin/bash
#Global Variables
UP_DIR = cd ..


echo "What do you want to do?"
echo "Press 1 to delete your branches and start from scratch"
echo "Press 2 to checkout a commit"
echo "Press 3 to see what commit you are on"
echo "Press 4 to checkout a branch on a plugin"
echo "Press 5 to just update your master branch"
echo "Press 6 to exit"
read choice

#This function iterates through the different plugins and updates them
function change_dir() {
cd vendor/plugins

dirs=( "multiple_root_accounts" "instructure_misc_plugin" "migration_tool" "analytics" "account_reports" "demo_site" )
 if [ -e $dirs ]
 then
   for i in "${dirs[@]}"
    do
      cd $i
      git checkout master
      git pull origin master
      git rebase origin/master
      cd ../
   done
else 
echo "################################################################"
echo "You seem to be missing plugins, I will now install those for you"
echo "################################################################"
  for i in "${dirs[@]}"
    do
     git clone ssh://marc@gerrit.instructure.com:29418/$i.git
    done

    cd ../../
fi
}

case $choice in
[1]*)

#Clears out old commits and updates master
echo "############################################################################"
echo "I am going to remove your old commits and checkout the newest code on master"
echo "############################################################################"

git checkout master
git branch | grep -v 'master$' | xargs git branch -D
git pull

echo "####################################"
echo "I am now going to update your plugins"
echo "####################################"

change_dir 
cd ../../
echo "############################################"
echo "Running a database migrate and bundle update"
echo "############################################"

bundle exec rake db:migrate
bundle update

echo "##################################"
echo "You are ready to checkout a commit"
echo "##################################"
;;

[2]*)

echo "##############################################"
echo "Would you like to checkout multiple patchsets?"
echo "##############################################"
read multi_patch

if [ "$multi_patch" == "y" ];
then

  echo "############################################"
  echo "How many patchsets did you want to checkout?"
  echo "############################################"
  read num_patchsets

  git checkout master
  git pull
  
  i=1
  while [ $i -le $num_patchsets ]; do
  
   if [ $i == 1 ]
    then  
     echo "#################################################"
     echo "What is the commit number for the first patchset?"
     echo "#################################################"
     read commit
     git fetch ssh://marc@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD  
     git checkout -b $commit 
   else
    echo "###########################################"
    echo "What is the commit number for patchset #$i?"
    echo "###########################################"
    read commit
    git fetch ssh://marc@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git cherry-pick FETCH_HEAD
   
   fi
  ((i ++))
  done
  
  git rebase origin/master
else

  echo "##########################################################"
  echo "Please give me the commit number that you want to checkout"
  echo "##########################################################"
  read commit

  git fetch ssh://marc@gerrit.instructure.com:29418/canvas-lms refs/changes/$commit && git checkout FETCH_HEAD
  git checkout -b $commit
fi

echo "#####################################"
echo "I am now going to update your plugins"
echo "#####################################"

change_dir 
cd ../../

bundle update
bundle exec rake db:migrate



echo "##########################################"
echo "Do you want to generate new API Documents?"
echo "##########################################"
read api_answer

if [ "$api_answer" == "y" ]; 
then
    bundle exec rake canvas:compile_assets
else 
    bundle exec rake canvas:compile_assets[false]
fi


echo "###################################################"
echo "Stopping and then Starting up your delayed jobs now"
echo "###################################################"

bundle exec script/delayed_job stop
bundle exec script/delayed_job start
echo "###########################"
echo "Starting up your server now"
echo "###########################"
bundle exec script/server
;;

[3]*)

echo "#########################################"
echo "How many commits do you have checked out?"
echo "#########################################"
read num_commits

git log -$num_commits
;;

[4]*)
echo "##############################################################"
echo "What is the name of the plugin that you are going to checkout?"
echo "##############################################################"
read plugin

echo "#######################################"
echo "I am going to first update your plugins"
echo "#######################################"

change_dir 

cd vendor/plugins/$plugin

echo "##########################################################"
echo "Please give me the commit number that you want to checkout"
echo "##########################################################"
read commit

git checkout origin master
git fetch ssh://marc@gerrit.instructure.com:29418/$plugin refs/changes/$commit && git checkout FETCH_HEAD
git checkout -b $commit



bundle exec rake db:migrate
bundle update
;;
[5]*)
git checkout master
git pull

echo "####################################"
echo "I am now going to update your plugins"
echo "####################################"

change_dir 

echo "############################################"
echo "Running a database migrate and bundle update"
echo "############################################"

bundle exec rake db:migrate
bundle update

echo "##################################"
echo "You are ready to checkout a commit"
echo "##################################"

	
;;
esac

