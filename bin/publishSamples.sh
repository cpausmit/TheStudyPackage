#!/bin/bash
#===================================================================================================
#
# Publish the data in a proper location. This is temporary.
#
#===================================================================================================
export BASEDIR=`pwd`
source ./bin/helpers.sh
# tell us the initial state
iniState $*

BASE=/mnt/hadoop/cms/store/user/paus
CORE=fastsm/043

TASK=$1
PROD=study/$TASK

# Prepare environment
echo " "
echo " Process:  TASK=$TASK"
echo " "

# Make a record of completed jobs and directories
list --long=1 $BASE/$CORE/${TASK}_* > /tmp/done.$$
echo ""
echo " FILES DONE"
echo ""
cat /tmp/done.$$

# extract the relevant parameters for publication
list --long=1 $BASE/$PROD/${TASK}_*bambu.root | grep root > /tmp/move.$$
echo ""
echo " FILES TO MOVE"
echo ""
cat /tmp/move.$$

for fullFile in `cat /tmp/move.$$`
do
  dir=`dirname $fullFile`
  file=`basename $fullFile`
  gpack=`echo $file | sed "s/${TASK}_//" | sed 's/\(.*\)_nev.*$/\1/'`
  if [ "`grep $file /tmp/done.$$`" == "" ]
  then
    echo " Moving file: $file"
    exeCmd makedir                   $BASE/$CORE/${TASK}_$gpack
    exeCmd changemod --options=a+rwx $BASE/$CORE/${TASK}_$gpack
    exeCmd move            $fullFile $BASE/$CORE/${TASK}_$gpack/
  else
    echo " DONE ALREADY -- ReMoving file: $file"
    exeCmd remove $fullFile
  fi
done

exit 0
