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

# load all parameters relevant to this task
echo " Initialize package"
source $BASEDIR/config/bambu043.env

# make sure to contain file mess
mkdir ./work
cd    ./work
export WORKDIR=`pwd`

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

lfn=`grep $GPACK $BASEDIR/config/${TASK}.list`

xrdcp root://cmsxrootd.fnal.gov/$lfn /tmp/$GPACK.root

setupCmssw $BAM_CMSSW_VERSION $BAM_PY
export PYTHONPATH="${PYTHONPATH}:$BASEDIR/python"

# unpack the tar
cd CMSSW_$BAM_CMSSW_VERSION
executeCmd tar fzx $BASEDIR/tgz/bambu043.tgz
cd $WORKDIR

# prepare the python config from the given templates
cat $BASEDIR/python/${BAM_PY}.py-template \
    | sed "s@XX-LFN-XX@$lfn@g" \
    | sed "s@XX-GPACK-XX@$GPACK@g" \
    > ${BAM_PY}.py

executeCmd time cmsRun ${BAM_PY}.py
# this is a little naming issue that has to be fixed
mv bambu-output-file-tmp*.root  ${GPACK}_tmp.root

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
REMOTE_USER_DIR="/user/paus/filefi/043"

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
    --destination srm://$REMOTE_SERVER:8443/${REMOTE_BASE}${REMOTE_USER_DIR}/${TASK} \
    --for_lfn ${REMOTE_USER_DIR}/${TASK}
done

tar fzx $BASEDIR/tgz/PyCox.tgz
cd PyCox
./install.sh
cat setup.sh
source setup.sh
# put config in the default spot
mv $BASEDIR/.pycox.cfg pycox.cfg
cd -
pwd=`pwd`

# make sure directory exists
executeCmd python ./PyCox/pycox.py --action mkdir \
           --source /cms/store${REMOTE_USER_DIR}/${TASK}
for file in `echo ${GPACK}*`
do
  # now do the copy
  executeCmd python ./PyCox/pycox.py --action up --source $file \
                        --target /cms/store${REMOTE_USER_DIR}/${TASK}/${file}
done

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
