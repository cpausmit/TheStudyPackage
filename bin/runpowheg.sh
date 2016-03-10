#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Run powheg with the given parameters.
#
#---------------------------------------------------------------------------------------------------
# input parameters
TASK=$1
GPACK=$2

##MEDIATOR_MASS=$2
##CHI_MASS=$3
##PROCESS_ID=$4
##QUARK_COUPLING=$5

# initialize
echo " Initialize"
source ./config/${TASK}.env
source /cvmfs/cms.cern.ch/cmsset_default.sh
scram project CMSSW CMSSW_$CMSSW_VERS
cd CMSSW_$CMSSW_VERS/src 
eval `scram runtime -sh`
cd -

# select the right program to run
if [[ $GPACK == *"proc-805"* ]] || [[ $GPACK == *"proc-806"* ]] || [[ $GPACK == *"proc-807"* ]]
then
  echo " Use: POWHEG-BOX-V2/DMS_tloop"
  cd POWHEG-BOX-V2/DMS_tloop
else
  echo " Use: POWHEG-BOX-V2/DMv"
  cd POWHEG-BOX-V2/DMV
fi
## if   [ $PROCESS_ID -gt 799 ] && [ $PROCESS_ID -lt 805 ]
## then
##   cd POWHEG-BOX-V2/DMV
## elif [ $PROCESS_ID -gt 804 ] && [ $PROCESS_ID -lt 808 ]
## then
##   cd POWHEG-BOX-V2/DMS_tloop
## else
##   echo ""
##   echo " ERROR -- process id is in an unknown range. EXIT NOW!"
##   echo ""
##   exit 1
## fi

# translate the GPACK name into our parameters
params=`echo $GPACK |sed "s/-/=/g"| sed "s/^/--/"| sed "s/_/ --/g"`
# now we run the generator
echo "./run.py $params"
./run.py $params
##./run.py --med $MEDIATOR_MASS --dm $CHI_MASS --proc $PROCESS_ID --g $QUARK_COUPLING

# fix the lhe file
#  - some particle Ids (+-1000021 -> 1000022) need to be changed for later hadronization (hack)
#  - the cross section needs to be added in the right spot
xs0=`cat ./pwg-stat.dat | grep Total | awk '{print $4}'`
xs1=`cat ./pwg-stat.dat | grep Total | awk '{print $6}'`
oldLine=" -1.00000E+00 -1.00000E+00  1.00000E+00  10001"
newLine=" $xs0 $xs1 1.00000000000E-00 100"
cat pwgevents.lhe \
    | sed "s@1000021@1000022@g" | sed "s@-1000022@1000022@g" | sed "s@$oldLine@$newLine@" \
    > tmp.lhe

# move the lhe file to the final location
##mv test.lhe ../../${TASK}_mm${MEDIATOR_MASS}_dm${CHI_MASS}_pr${PROCESS_ID}_gq${QUARK_COUPLING}.lhe
mv tmp.lhe ../../${TASK}_${GPACK}.lhe

exit 0
