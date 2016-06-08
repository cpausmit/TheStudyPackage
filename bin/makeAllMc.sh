#!/bin/bash
#===================================================================================================
#
# Execute one job on the grid or interactively.
#
#===================================================================================================
# command line arguments
export CONFIG="$1"
export VERSION="$2"
export TASK="$3"
export GPACK="$4"

# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz; rm default.tgz )        # make sure to cleanup right away
export BASEDIR=`pwd`
source ./bin/helpers.sh

# load all parameters relevant to this task
echo " Initialize package"
source $BASEDIR/$VERSION/${TASK}.env

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

# initialize LHE step
setupCmssw $GEN_CMSSW_VERSION $GEN_PY

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

# initialize GEN step
setupCmssw $GEN_CMSSW_VERSION $GEN_PY
executeCmd time cmsRun ${GEN_PY}.py
if ! [ -e "${TASK}_${GPACK}_gen.root" ]
then
  echo " ERROR -- generation failed. No output file: ${TASK}_${GPACK}_gen.root"
  echo "          EXIT now because there is no GEN file."
  exit 1
fi

showDiskSpace

####################################################################################################
# Making the AODSIM step
####################################################################################################

if [ "$CONFIG" == "fastsm" ]
then

  # using fastsim
  ###############

  # initialize
  setupCmssw $FSM_CMSSW_VERSION $FSM_PY
  executeCmd time cmsRun ${FSM_PY}.py
  if ! [ -e "${TASK}_${GPACK}_aodsim.root" ]
  then
    echo " ERROR -- fast simulation failed. No output file: ${TASK}_${GPACK}_aodsim.root"
    echo "          EXIT now because there is no AODSIM file."
    exit 1
  fi

  showDiskSpace

  # now aodsim is available, time to cleanup LHE and gen

  exeCmd rm $WORKDIR/${TASK}_${GPACK}.lhe $WORKDIR/${TASK}_${GPACK}_gen.root

elif [ "$CONFIG" == "fullsm" ]
then

  # using fullsim
  ###############

  # gen->sim

  # initialize
  setupCmssw $SIM_CMSSW_VERSION $SIM_PY
  executeCmd time cmsRun ${SIM_PY}.py
  if ! [ -e "${TASK}_${GPACK}_gensim.root" ]
  then
    echo " ERROR -- simulation step failed. No output file: ${TASK}_${GPACK}_gensim.root"
    echo "          EXIT now because there is no SIM file."
    exit 1
  fi

  # sim->simraw

  # initialize
  setupCmssw $SMR_CMSSW_VERSION $SMR_PY
  executeCmd time cmsRun ${SMR_PY}.py
  if ! [ -e "${TASK}_${GPACK}_simraw.root" ]
  then
    echo " ERROR -- simraw step failed. No output file: ${TASK}_${GPACK}_simraw.root"
    echo "          EXIT now because there is no SIMRAW file."
    exit 1
  fi

  # simraw->aodsim
  
  # initialize
  setupCmssw $DGR_CMSSW_VERSION $DGR_PY
  executeCmd time cmsRun ${DGR_PY}.py
  if ! [ -e "${TASK}_${GPACK}_aodsim.root" ]
  then
    echo " ERROR -- digireco failed. No output file: ${TASK}_${GPACK}_aodsim.root"
    echo "          EXIT now because there is no AODSIM file."
    exit 1
  fi

  showDiskSpace

  # now aodsim is available, time to cleanup LHE and gen
  exeCmd rm $WORKDIR/${TASK}_${GPACK}.lhe $WORKDIR/${TASK}_${GPACK}_gen.root \
            $WORKDIR/${TASK}_${GPACK}_gensim.root $WORKDIR/${TASK}_${GPACK}_simraw.root
  

else

  # unknown config
  ################

  echo " ERROR -- config: $CONFIGURE not known."
  exit 1

fi


####################################################################################################
# miniaodsim step
####################################################################################################

# initialize MINIAOD step
setupCmssw $MIN_CMSSW_VERSION $MIN_PY
executeCmd time cmsRun ${MIN_PY}.py
if ! [ -e "${TASK}_${GPACK}_miniaodsim.root" ]
then
  echo " ERROR -- miniaodsim failed. No output file: ${TASK}_${GPACK}_miniaodsim.root"
  echo "          EXIT now because there is no MINIAODSIM file."
  exit 1
fi

showDiskSpace

###########################################################################################
# initialize BAMBU
####################################################################################################
# bambu step

setupCmssw $BAM_CMSSW_VERSION $BAM_PY

# unpack the additional tar
cd CMSSW_$BAM_CMSSW_VERSION
executeCmd tar fzx $BASEDIR/$VERSION/tgz/bambu_${BAM_CMSSW_VERSION}.tgz
cd $WORKDIR

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
REMOTE_USER_DIR="/user/paus/$CONFIG/$VERSION"

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
  executeCmd rm -rf $WORKDIR *.root bin/ generators/ html/ LICENSE  $VERSION/ README root/ tgz/
fi

# create the pickup output file for condor

echo " ---- D O N E ----" > $BASEDIR/${TASK}_${GPACK}.empty

pwd
ls -lhrt
echo " ---- D O N E ----"

exit 0
