#!/bin/bash
#===================================================================================================
#
# Prepare an exiting bambu request for local production.
#
#===================================================================================================
source ./bin/helpers.sh
[ -z "$T2TOOLS_BASE" ] && source ~/Work/T2Tools/setup.sh

VERSION=$1
if [ "$VERSION" == "" ]
then
  echo ""
  echo " ERROR - please specify desired version"
  echo ""
  exit 1
fi
TASK=$2
if [ "$TASK" == "" ]
then
  echo ""
  echo " ERROR - please specify desired task"
  echo ""
  exit 1
fi

# find out the lastest CMSSW software release used in bambu
latestCmssw=`ls -1 ~cmsprod/cms/cmssw/${VERSION}  2>/dev/null |grep 'CMSSW'|tail -1|sed 's@CMSSW_@@'`

# Define our work directory
WORKDIR=$PWD

# Make sure we have the bambu tar ball
if ! [ -z "$latestCmssw" ] && ! [ -e "$WORKDIR/${VERSION}/tgz/bambu_${latestCmssw}.tgz" ]
then
  echo ""
  echo -n " Make latest bambu tarball ($WORKDIR/${VERSION}/tgz/bambu_${latestCmssw}.tgz). Ok? [return - OK, Ctrl-C - stop] "
  read
  cd ~cmsprod/cms/cmssw/${VERSION}/CMSSW_${latestCmssw}
  echo " tar fzc $WORKDIR/$VERSION/tgz/bambu_${latestCmssw}.tgz lib/ python/ src/"
  tar fzc $WORKDIR/$VERSION/tgz/bambu_${latestCmssw}.tgz lib/ python/ src/
  cd -
fi

# Get the configuration
if ! [ -e "$WORKDIR/$VERSION/${TASK}.list" ]
then
  if [ -e "/home/cmsprod/cms/jobs/lfns/${TASK}.lfns" ]
  then
    cat /home/cmsprod/cms/jobs/lfns/${TASK}.lfns | tr -s ' ' | cut -d' ' -f2 \
        > $WORKDIR/$VERSION/${TASK}.list
  else
    #echo " ERROR - production does not have lfns"
    #echo " > ~cmsprod/cms/jobs/lfns/"
    #echo " > ${TASK}.lfns"
    #echo ""
    echo "$TASK"
  fi
else
  #echo " INFO - Config file exists already"
  #echo " > $WORKDIR/$VERSION/"
  #echo " > ${TASK}.list"
  echo " exists $TASK"
  echo -n ""
fi
