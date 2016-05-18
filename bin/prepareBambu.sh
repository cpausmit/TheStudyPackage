#!/bin/bash
#===================================================================================================
#
# Prepare an exiting bambu request for local production.
#
#===================================================================================================
source ./bin/helpers.sh
[ -z "$T2TOOLS_BASE" ] && source ~/T2Tools/setup.sh

BASE=/mnt/hadoop/cms/store/user/paus
CORE=filefi/044

version=`echo $CORE | cut -d'/' -f2`

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

# Make sure we have the bambu tar ball
if ! [ -e "$WORKDIR/tgz/bambu${version}.tgz" ]
then
  echo ""
  echo -n " Need to make latest bambu tarball ($WORKDIR/tgz/bambu${version}.tgz). Ok? [return for OK, Ctrl-C to stop] "
  read
  latest=`ls ~cmsprod/cms/cmssw/${version} |grep 'CMSSW'| tail -1`
  cd ~cmsprod/cms/cmssw/${version}/${latest}
  echo " tar fzc $WORKDIR/tgz/bambu${version}.tgz lib/ python/ src/"
  tar fzc $WORKDIR/tgz/bambu${version}.tgz lib/ python/ src/
  cd -
fi

# Get the configuration
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
    echo ""
  fi
else
  echo " INFO - Config file exists already"
  echo " > $WORKDIR/config/"
  echo " > ${TASK}.list"
  echo ""
fi
