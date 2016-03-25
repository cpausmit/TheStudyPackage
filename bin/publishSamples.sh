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

# loop over the relevant files
for gpack in `cat ./config/${TASK}.list|sed 's/\(.*\)_nev.*$/\1/'|sort -u`
do

  # extract the relevant parameters for publication

  executeCmd \
    glexec "mkdir -p    $BASE/$CORE/${TASK}_$gpack;
      chmod a+rwx $BASE/$CORE/${TASK}_$gpack;
      cp          $BASE/$PROD/${TASK}_$gpack*bambu.root \
                  $BASE/$CORE/${TASK}_$gpack/;
      ls -lhrt    $BASE/$CORE/${TASK}_$gpack/"

done

exit 0
