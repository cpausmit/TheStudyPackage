#!/bin/bash
#===================================================================================================
#
# Execute one job on the grid or interactively.
#
#===================================================================================================
# command line arguments
export TASK="$1"
export GPACK="$2"
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz; rm default.tgz )        # make sure to cleanup right away
export BASEDIR=`pwd`
source ./bin/helpers.sh

# load all parameters relevant to this task
echo " Initialize package"
source $BASEDIR/config/${TASK}.env

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

# initialize LHE/GEN step
setupCmssw $GEN_CMSSW_VERSION $GEN_PY
export PYTHONPATH="${PYTHONPATH}:$BASEDIR/python"

# start clean by removing copies of existing generator
executeCmd rm -rf $GENERATOR

# get our fresh generator tar ball
executeCmd tar fzx $BASEDIR/generators/$GENERATOR.tgz

####################################################################################################
# C H O O S E   T H E   G E N E R A T O R  [and run it]
####################################################################################################
echo " INFO -- using generator type: $GENERATOR_TYPE"
if   [ "$GENERATOR_TYPE" == "powheg" ]
then
  executeCmd time $BASEDIR/bin/runPowheg.sh $TASK $GPACK
elif [ "$GENERATOR_TYPE" == "madgraph" ]
then
  executeCmd time $BASEDIR/bin/runMadgraph.sh $TASK $GPACK
elif [ "$GENERATOR_TYPE" == "jhu" ]
then
  executeCmd time $BASEDIR/bin/runJHU.sh $TASK $GPACK
else
  echo " ERROR -- generator type is not known (\$GENERATOR_TYPE=$GENERATOR_TYPE)"
  echo "          EXIT now because there is no LHE file."
  exit 1
fi

showDiskSpace

####################################################################################################
# hadronize step
####################################################################################################

cd $WORKDIR
pwd
ls -lhrt

# already done
echo " Initialize CMSSW for Gen - $GEN_CMSSW_VERSION -> $GEN_PY"

# prepare the python config from the given templates
cat $BASEDIR/python/${GEN_PY}.py-template \
    | sed "s@XX-SEED-XX@$SEED@g" \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${GEN_PY}.py

executeCmd time cmsRun ${GEN_PY}.py

if ! [ -e "${TASK}_${GPACK}_gen.root" ]
then
  echo " ERROR -- generation failed. No output file: ${TASK}_${GPACK}_gen.root"
  echo "          EXIT now because there is no GEN file."
  exit 1
fi

showDiskSpace

####################################################################################################
# fastsim step
####################################################################################################

cd $WORKDIR
pwd
ls -lhrt

# initialize FASTSIM step
setupCmssw $SIM_CMSSW_VERSION $SIM_PY

# prepare the python config from the given templates
cat $BASEDIR/python/${SIM_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${SIM_PY}.py

executeCmd time cmsRun ${SIM_PY}.py

if ! [ -e "${TASK}_${GPACK}_aodsim.root" ]
then
  echo " ERROR -- simulation failed. No output file: ${TASK}_${GPACK}_aodsim.root"
  echo "          EXIT now because there is no AODSIM file."
  exit 1
fi

showDiskSpace

# now aodsim is available, time to cleanup LHE and gen
exeCmd rm $WORKDIR/${TASK}_${GPACK}.lhe $WORKDIR/${TASK}_${GPACK}_gen.root

####################################################################################################
# miniaodsim step
####################################################################################################

cd $WORKDIR
pwd
ls -lhrt

# initialize MINIAOD step
setupCmssw $MIN_CMSSW_VERSION $MIN_PY

# prepare the python config from the given templates
cat $BASEDIR/python/${MIN_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${MIN_PY}.py

executeCmd time cmsRun ${MIN_PY}.py

if ! [ -e "${TASK}_${GPACK}_miniaodsim.root" ]
then
  echo " ERROR -- miniaodsim failed. No output file: ${TASK}_${GPACK}_miniaodsim.root"
  echo "          EXIT now because there is no MINIAODSIM file."
  exit 1
fi

showDiskSpace

####################################################################################################
# initialize BAMBU
####################################################################################################
# bambu step

cd $WORKDIR
pwd
ls -lhrt

setupCmssw $BAM_CMSSW_VERSION $BAM_PY
export PYTHONPATH="${PYTHONPATH}:$BASEDIR/python"

# unpack the tar
cd CMSSW_$BAM_CMSSW_VERSION
executeCmd tar fzx $BASEDIR/tgz/bambu043.tgz
cd $WORKDIR

# prepare the python config from the given templates
cat $BASEDIR/python/${BAM_PY}.py-template \
    | sed "s@XX-HADRONIZER-XX@$HADRONIZER@g" \
    | sed "s@XX-FILE_TRUNC-XX@${TASK}_${GPACK}@g" \
    > ${BAM_PY}.py

executeCmd time cmsRun ${BAM_PY}.py
# this is a little naming issue that has to be fixed
mv ${TASK}_${GPACK}_bambu*  ${TASK}_${GPACK}_bambu.root

if ! [ -e "${TASK}_${GPACK}_bambu.root" ]
then
  echo " ERROR -- bambu production failed. No output file: ${TASK}_${GPACK}_bambu.root"
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
REMOTE_USER_DIR="/user/paus/fastsm/043"

sample=`echo $GPACK | sed 's/\(.*\)_nev.*/\1/'`

# this is somewhat overkill but works very reliably, I suppose
setupCmssw 7_6_3 cmscp.py
tar fzx $BASEDIR/tgz/copy.tgz
pwd=`pwd`
# always first show the proxy
voms-proxy-info -all
for file in `echo ${TASK}_${GPACK}_bambu* ${TASK}_${GPACK}_miniaodsim*`
do
  # now do the copy
  executeCmd time ./cmscp.py \
    --middleware OSG --PNN $REMOTE_SERVER --se_name $REMOTE_SERVER \
    --inputFileList $pwd/${file} \
    --destination srm://$REMOTE_SERVER:8443/${REMOTE_BASE}${REMOTE_USER_DIR}/${TASK}_${sample} \
    --for_lfn ${REMOTE_USER_DIR}/${TASK}_${sample}
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
           --source /cms/store${REMOTE_USER_DIR}/${TASK}_${sample}
for file in `echo ${TASK}_${GPACK}_bambu* ${TASK}_${GPACK}_miniaodsim*`
do
  # now do the copy
  executeCmd python ./PyCox/pycox.py --action up --source $file \
                        --target /cms/store${REMOTE_USER_DIR}/${TASK}_${sample}/${file}
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
