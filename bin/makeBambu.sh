#!/bin/bash
#===================================================================================================
#
# Execute one job on the grid or interactively.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz; rm default.tgz )          # make sure to cleanup right away
export BASEDIR=`pwd`
source ./bin/helpers.sh

# command line arguments
VERSION="$1"
TASK="$2"
GPACK="$3"
CRAB="$4"

# load all parameters relevant to this task
echo " Initialize package"
source $BASEDIR/$VERSION/bambu.env
# fine tuning for the python config ... data needs different config
if [ "`echo $TASK | grep AOD$`" == "$TASK" ]
then
  # this is data
  export BAM_PY=BambuData
  echo " Bambu python config is set to data: $BAM_PY"
fi

# make sure to contain file mess
mkdir ./work
cd    ./work
export WORKDIR=`pwd`

# this might be an issue with root
export HOME=$WORKDIR

# tell us the initial state
initialState $*

# make a working area
echo " Start to work now"
pwd
ls -lhrt

# make sure site is configured, if not, configure it (for DB access, not needed for lhe/gen)
configureSite

####################################################################################################
# initialize BAMBU
####################################################################################################

# setting up the software
setupCmssw $BAM_CMSSW_VERSION empty
# prepare the python config from the given templates
cat $BASEDIR/$VERSION/python/${BAM_PY}.py-template \
    | sed "s@XX-LFN-XX@$lfn@g" \
    | sed "s@XX-GPACK-XX@$GPACK@g" \
    > ${BAM_PY}.py

# getting our input (important: xrdcp needs cvmfs to be setup)
lfn=`grep $GPACK $BASEDIR/$VERSION/${TASK}.list`
voms-proxy-info -all
echo ""
echo " Make local copy of the root file with LFN: $lfn"
executeCmd xrdcp -s root://cmsxrootd.fnal.gov/$lfn ./$GPACK.root

if [ -e "./$GPACK.root" ]
then
  ls -lhrt ./$GPACK.root
else
  echo " ERROR -- input file file does not exist. Copy failed!"
  echo "          EXIT now because there is no AOD* file to process."
  exit 1
fi

# unpack the tar
cd CMSSW_$BAM_CMSSW_VERSION
executeCmd tar fzx $BASEDIR/$VERSION/tgz/bambu_${BAM_CMSSW_VERSION}.tgz
cd $WORKDIR

# run bambu making
executeCmd time cmsRun ${BAM_PY}.py

# this is a little naming issue that has to be fixed
mv bambu-output-file-tmp*.root  ${GPACK}_tmp.root

# cleanup the input
rm -f ./$GPACK.root

if ! [ -e "${GPACK}_tmp.root" ]
then
  echo " ERROR -- bambu production failed. No output file: ${GPACK}_tmp.root"
  echo "          EXIT now because there is no BAMBU file."
  exit 1
fi

showDiskSpace

####################################################################################################
# push our files out to the Tier-2 / Dropbox
####################################################################################################

cd $WORKDIR
pwd
ls -lhrt

# define base output location
REMOTE_SERVER="se01.cmsaf.mit.edu"
REMOTE_BASE="srm/v2/server?SFN=/mnt/hadoop/cms/store"
REMOTE_USER_DIR="/user/paus/filefi/$VERSION"

sample=`echo $GPACK | sed 's/\(.*\)_nev.*/\1/'`

# this is somewhat overkill but works very reliably, I suppose
setupCmssw 7_6_3 cmscp.py
tar fzx $BASEDIR/tgz/copy.tgz
pwd=`pwd`
for file in `echo ${GPACK}*`
do
  # always first show the proxy
  voms-proxy-info -all
  # now do the copy
  executeCmd time ./cmscp.py \
    --middleware OSG --PNN $REMOTE_SERVER --se_name $REMOTE_SERVER \
    --inputFileList $pwd/${file} \
    --destination srm://$REMOTE_SERVER:8443/${REMOTE_BASE}${REMOTE_USER_DIR}/${TASK}/${CRAB} \
    --for_lfn ${REMOTE_USER_DIR}/${TASK}/${CRAB}
done

# make condor happy because it also might want some of the files
executeCmd mv $WORKDIR/*.root $BASEDIR/

# leave the worker super clean

testBatch
if [ "$?" == "1" ]
then
  cd $BASEDIR
  executeCmd rm -rf $WORKDIR *.root bin/ $VERSION/ generators/ html/ tgz/
fi

# create the pickup output file for condor

echo " ---- D O N E ----" > $BASEDIR/${TASK}_${GPACK}.empty


pwd
ls -lhrt
echo " ---- D O N E ----"

exit 0
