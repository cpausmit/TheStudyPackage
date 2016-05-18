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
TASK="$1"
GPACK="$2"
CRAB="$3"

# load all parameters relevant to this task
echo " Initialize package"
source $BASEDIR/config/bambu044.env
# fine tuning for the python config ... data needs different config
if [ "`echo $TASK | grep AOD$`" == "$TASK" ]
then
  # this is data
  export BAM_PY=BambuData044
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
# bambu step

cd $WORKDIR
pwd
ls -lhrt

# setting up the software
setupCmssw $BAM_CMSSW_VERSION $BAM_PY
export PYTHONPATH="${PYTHONPATH}:$BASEDIR/python"

# getting our input (important: xrdcp needs cvmfs to be setup)
lfn=`grep $GPACK $BASEDIR/config/${TASK}.list`
voms-proxy-info -all
echo ""; echo " Make local copy of the root file with LFN: $lfn"
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
executeCmd tar fzx $BASEDIR/tgz/bambu044.tgz
cd $WORKDIR

# prepare the python config from the given templates
cat $BASEDIR/python/${BAM_PY}.py-template \
    | sed "s@XX-LFN-XX@$lfn@g" \
    | sed "s@XX-GPACK-XX@$GPACK@g" \
    > ${BAM_PY}.py

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
REMOTE_USER_DIR="/user/paus/filefi/044"

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

#CP# tar fzx $BASEDIR/tgz/PyCox.tgz
#CP# cd PyCox
#CP# ./install.sh
#CP# cat setup.sh
#CP# source setup.sh
#CP# # put config in the default spot
#CP# mv $BASEDIR/.pycox.cfg pycox.cfg
#CP# cd -
#CP# pwd=`pwd`
#CP# 
#CP# # make sure directory exists
#CP# executeCmd python ./PyCox/pycox.py --action mkdir \
#CP#            --source /cms/store${REMOTE_USER_DIR}/${TASK}
#CP# for file in `echo ${GPACK}*`
#CP# do
#CP#   # now do the copy
#CP#   executeCmd python ./PyCox/pycox.py --action up --source $file \
#CP#                         --target /cms/store${REMOTE_USER_DIR}/${TASK}/${file}
#CP# done

# make condor happy because it also might want some of the files
executeCmd mv $WORKDIR/*.root $BASEDIR/

# leave the worker super clean

testBatch
if [ "$?" == "1" ]
then
  cd $BASEDIR
  executeCmd rm -rf $WORKDIR *.root \
                bin/ config/ fromPhil/ fwlite/ generators/ html/ LICENSE  python/ README root/ tgz/
fi

# create the pickup output file for condor

echo " ---- D O N E ----" > $BASEDIR/${TASK}_${GPACK}.empty


pwd
ls -lhrt
echo " ---- D O N E ----"

exit 0
