#!/bin/bash
#===================================================================================================
#
# Execute one job on the grid or interactively.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
source ./bin/helpers.sh

# command line arguments
TASK="$1"
GPACK="$2"
# load all parameters relevant to this task
source ./config/${TASK}.env

# tell us the initial state
initialState $*

# make a working area
workDir=$PWD

# get our gridpack (this depends on interactive or not)
if [ -d "./tar.xz" ]
then
  mkdir -p $GPACK
  cd       $GPACK
  executeCmd cp ../tar.xz/$GPACK.tar.xz .
fi

# ready to start
executeCmd unxz $GPACK.tar.xz
executeCmd tar  xvf $GPACK.tar > untar.log

# setup CMSSW if needed (this depends on interactive or not)
if ! [ -d "$LHAPATH" ]
then
  source /cvmfs/cms.cern.ch/cmsset_default.sh
  scram project CMSSW CMSSW_7_1_15_patch1
  cd  CMSSW_7_1_15_patch1/src/
  eval  `scram runtime -sh`
  cd -
  if ! [ -d "$LHAPATH" ]
  then
    echo " CMSSW failed to setup correctly: LHAPATH=$LHAPATH"
    exit 1
  fi
fi

# make the LHE file
executeCmd ./runcmsgrid.sh $NEVENTS $RANDOM 1

# copy LHE file to properly named file
mv cmsgrid_final.lhe ${GPACK}.lhe

exit 0
