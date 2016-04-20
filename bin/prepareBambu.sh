#!/bin/bash
#===================================================================================================
#
# Prepare an exiting bambu request for local production.
#
#===================================================================================================
source ./bin/helpers.sh
[ -z "$T2TOOLS_BASE" ] && source ~/T2Tools/setup.sh

BASE=/mnt/hadoop/cms/store/user/paus
CORE=filefi/043

TASK=$1
if [ "$TASK" == "" ]
then
  echo ""
  echo " ERROR - please specify desired task"
  echo ""
  exit 1
fi

# Define our work directory
WORKDIR=$PWD

if ! [ -e "$WORKDIR/config/${TASK}.list" ]
then
  if [ -e "/home/cmsprod/cms/jobs/lfns/${TASK}.lfns" ]
  then
    cat /home/cmsprod/cms/jobs/lfns/${TASK}.lfns | tr -s ' ' | cut -d' ' -f2 \
        > $WORKDIR/config/${TASK}.list
  else
    echo " ERROR - production does not have lfns"
    echo " > ~cmsprod/cms/jobs/lfns/"
    echo " > ${TASK}.lfns"
  fi
else
  echo " Config file exists already"
  echo " > $WORKDIR/config/"
  echo " > ${TASK}.list"
fi
