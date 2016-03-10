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
OPTION="$3"
# load all parameters relevant to this task
source ./config/${TASK}.env

# tell us the initial state
initialState $*

# if requested just print the outputfiles
if [ "$OPTION" == "outputfiles" ]
then
  printOutputfiles "$GPACK" "$QCUTS"
  exit 0
fi

# make a working area
workDir=$PWD

# get our gridpack (this depends on interactive or not)
if [ -d "./bin" ]
then
  mkdir -p $GPACK
  cd       $GPACK
  executeCmd cp ../tar.xz/${GPACK}.tar.xz ../root/${ROOTMACRO}.C .
else
  executeCmd tar fzx default.tgz
  executeCmd tar fzx ssh.tgz
  executeCmd cp ./root/${ROOTMACRO}.C .
fi

# ready to start
executeCmd unxz ${GPACK}.tar.xz
executeCmd tar  xvf ${GPACK}.tar > untar.log

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

# cleanup as we only need the LHE file from now on
executeCmd df -h ./
executeCmd rm -rf ${GPACK}.tar* process mgbasedir runcmsgrid.sh gridpack_generation.log \
                                syscalc_card.dat events_presys.lhe
executeCmd df -h ./

echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo " Starting loop through qCut values: $QCUTS"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""

for QCUT in $QCUTS
do

  echo " QCUT: $QCUT"

  cat $workDir/python/${PRODPY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-OUTPUT-XX@${GPACK}-${QCUT}@g" \
    > ${PRODPY}.py
  cat $workDir/python/${HADRONIZER}.py-template \
    | sed "s@XX-QCUT-XX@$QCUT@g" \
    > ${HADRONIZER}.py
  
  executeCmd cmsRun ${PRODPY}.py
  executeCmd \
    root -l -b -q ./${ROOTMACRO}.C\(\"${GPACK}-${QCUT}.root\",\"${GPACK}-${QCUT}-out.root\"\)

  # make sure to get ride of our output
  echo "ssh                        t3btch101.mit.edu mkdir -p /mnt/hscratch/paus/$TASK/$GPACK"
  ssh                        t3btch101.mit.edu mkdir -p /mnt/hscratch/paus/$TASK/$GPACK
  echo "scp ${GPACK}-${QCUT}*.root t3btch101.mit.edu:/mnt/hscratch/paus/$TASK/$GPACK"
  scp ${GPACK}-${QCUT}*.root t3btch101.mit.edu:/mnt/hscratch/paus/$TASK/$GPACK

  # delete the remainders
  echo " rm ${GPACK}-${QCUT}*.root"

done

exit 0
