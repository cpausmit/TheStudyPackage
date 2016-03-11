#!/bin/bash
#===================================================================================================
#
# Execute one job on the grid or interactively.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
source ./bin/helpers.sh

# define base output location
SERVER="se01.cmsaf.mit.edu"
BASE="srm/v2/server?SFN="
USER_DIR="/mnt/hadoop/cms/store/user/paus/study"

# command line arguments
TASK="$1"
GPACK="$2"

# make sure to contain file mess
mkdir ./work
cd    ./work

# load all parameters relevant to this task
echo " Initialize package"
source ../config/${TASK}.env

# tell us the initial state
initialState $*

# make a working area
workDir=$PWD
pwd
ls -lhrt

# initialize LHE/GEN step
setupCmssw $GEN_CMSSW_VERSION $GEN_PY

# start clean by removing copies of existing generator
executeCmd rm -rf $GENERATOR

# get our fresh generator tar ball
executeCmd tar fzx ../generators/$GENERATOR.tgz

# select the right program to run
if [[ $GPACK == *"proc-805"* ]] || [[ $GPACK == *"proc-806"* ]] || [[ $GPACK == *"proc-807"* ]]
then
  echo " Use: POWHEG-BOX-V2/DMS_tloop"
  cd POWHEG-BOX-V2/DMS_tloop
else
  echo " Use: POWHEG-BOX-V2/DMV"
  cd POWHEG-BOX-V2/DMV
  export HADRONIZER=$HADRONIZER_NLO
fi

# translate the GPACK name into our parameters
params=`echo $GPACK |sed "s/-/=/g"| sed "s/^/--/"| sed "s/_/ --/g"`
# now we run the generator
executeCmd time ./run.py $params

# fix the lhe file
#  - some particle Ids (+-1000021 -> 1000022) need to be changed for later hadronization (hack)
#  - add cross section in right spot (CP - seems to be wrong anyway, but pythia needs non zero xs?!)
xs0=`cat ./pwg-stat.dat | grep Total | awk '{print $4}'`
xs1=`cat ./pwg-stat.dat | grep Total | awk '{print $6}'`
oldLine=" -1.00000E+00 -1.00000E+00  1.00000E+00  10001"
newLine=" $xs0 $xs1 1.00000000000E-00 100"
cat pwgevents.lhe \
    | sed "s/^ \(#.*\)/<!-- \1 -->/" \
    | sed "s@1000021@1000022@g" | sed "s@-1000022@1000022@g" | sed "s@$oldLine@$newLine@" \
    > cmsgrid_final.lhe

executeCmd mv cmsgrid_final.lhe ../../${TASK}_${GPACK}.lhe

# hadronize step

cd $workDir
pwd
ls -lhrt

# already done
echo " Initialize CMSSW for Gen - $GEN_CMSSW_VERSION -> $GEN_PY"

# prepare the python config from the given templates
cat $workDir/../python/${GEN_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${GEN_PY}.py

executeCmd time cmsRun ${GEN_PY}.py

# fastsim step

cd $workDir
pwd
ls -lhrt

# initialize FASTSIM step
setupCmssw $SIM_CMSSW_VERSION $SIM_PY

# prepare the python config from the given templates
cat $workDir/../python/${SIM_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${SIM_PY}.py

executeCmd time cmsRun ${SIM_PY}.py

# miniaod step

cd $workDir
pwd
ls -lhrt

# initialize MINIAOD step
setupCmssw $MIN_CMSSW_VERSION $MIN_PY

# prepare the python config from the given templates
cat $workDir/../python/${MIN_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${MIN_PY}.py

executeCmd time cmsRun ${MIN_PY}.py

# bambu step

cd $workDir
pwd
ls -lhrt

# initialize BAMBU
setupCmssw $BAM_CMSSW_VERSION $BAM_PY
export PYTHONPATH="${PYTHONPATH}:../python"

# unpack the tar
cd CMSSW_$BAM_CMSSW_VERSION
executeCmd time tar fzx ../../tgz/bambu043.tgz
cd $workDir

# prepare the python config from the given templates
cat $workDir/../python/${BAM_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${BAM_PY}.py

executeCmd time cmsRun ${BAM_PY}.py
# this is a little naming issue that has to be fixed
mv ${TASK}_${GPACK}_bambu*  ${TASK}_${GPACK}_bambu.root

# finally, move all files needed to the starting area
executeCmd mv ${TASK}_${GPACK}* $workDir/..


# push our files out to the Tier-2
cd $workDir/..
pwd=`pwd`
for file in `echo ${TASK}_${GPACK}*`
do
  executeCmd time \
    lcg-cp -D srmv2 -b file://$pwd/$file srm://$SERVER:8443/${BASE}${USER_DIR}/${TASK}/$file
done

exit 0
