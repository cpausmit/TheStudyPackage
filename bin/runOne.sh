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
QCUT="$3"
# load all paramters relevant to this task
source ./config/${TASK}.env

# tell us the initial state
initialState $*

# make a working area
workDir=$PWD

# get our gridpack (this depends on interactive or not)
if [ -e "${GPACK}.lhe" ]
then
  # we are in batch mode
  ## already done -- executeCmd tar fzx default.tgz
  executeCmd cp ./root/${ROOTMACRO}.C .
  executeCmd mv ${GPACK}.lhe cmsgrid_final.lhe
else
  # we are in interactive mode
  mkdir -p $GPACK
  cd       $GPACK
  executeCmd cp /mnt/hscratch/$USER/cms/hist/${TASK}/${GPACK}.lhe cmsgrid_final.lhe
  executeCmd cp ../root/${ROOTMACRO}.C .
fi

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

# prepare the python config from the given templates
cat $workDir/python/${PRODPY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-OUTPUT-XX@${GPACK}-${QCUT}@g" \
    > ${PRODPY}.py
cat $workDir/python/${HADRONIZER}.py-template \
    | sed "s@XX-QCUT-XX@$QCUT@g" \
    > $HADRONIZER.py
  
executeCmd cmsRun ${PRODPY}.py
executeCmd root -l -b -q ./${ROOTMACRO}.C\(\"${GPACK}-${QCUT}.root\",\"${GPACK}-${QCUT}-out.root\"\)

exit 0
