#!/bin/bash
#===================================================================================================
#
# Publish the data in a proper location. This is temporary.
#
#===================================================================================================
export BASEDIR=`pwd`
source ./bin/helpers.sh
# tell us the initial state
initialState $*

BASE=/mnt/hadoop/cms/store/user/paus
CORE=fastsm/043

TASK=$1
PROD=study/$TASK

# Prepare environment
echo " "
echo " Process:  TASK=$TASK"
echo " "

# Make a record of completed jobs and directories
glexec ls -1 $BASE/$CORE/${TASK}_* > /tmp/done.$$

# loop over the relevant files
for gpack in `cat ./config/${TASK}.list|sed 's/\(.*\)_nev.*$/\1/'|sort -u`
do

  # extract the relevant parameters for publication
  glexec ls -1 $BASE/$PROD/${TASK}_${gpack}*bambu.root | grep root > /tmp/move.$$

  for file in `cat /tmp/move.$$`
  do
     file=`basename $file`
     
     exists=`grep $file /tmp/done.$$`
     if [ "$exists" == "" ]
     then
       echo " Moving file: $file"
       exeCmd \
         glexec "mkdir -p $BASE/$CORE/${TASK}_$gpack;
                 chmod a+rwx $BASE/$CORE/${TASK}_$gpack;
                 mv $BASE/$PROD/$file $BASE/$CORE/${TASK}_$gpack/"
     else
       echo " DONE ALREADY -- ReMoving file: $file"
       exeCmd \
         glexec "rm $BASE/$PROD/$file"
     fi
  
  done
done

exit 0
