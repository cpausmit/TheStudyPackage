#!/bin/bash
#===================================================================================================
#
# Execute one job on the grid or interactively.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
export BASEDIR=`pwd`
source ./bin/helpers.sh
setupProxy

# command line arguments
TASK="$1"
GPACK="$2"


mkdir ./work
cd    ./work
export WORKDIR=`pwd`

# make sure site is configured, if not, configure it (for DB access, not needed for lhe/gen)
configureSite

# make a test file
echo "Hello my darling. We should have a cup of tea and discuss this proposal." > testCopy.root
echo "Cheers, CP"                                                              >> testCopy.root
echo ""                                                                        >> testCopy.root
executeCmd mv  testCopy.root ${TASK}_${GPACK}.copy
ls -lhrt

# define base output location
SERVER="se01.cmsaf.mit.edu"
BASE="srm/v2/server?SFN=/mnt/hadoop/cms/store"
USER_DIR="/user/paus/study"

# to Tier-2
setupCmssw 7_6_3 test
tar fzx ../tgz/copy.tgz
executeCmd ./cmscp.py \
  --debug \
  --destination srm://$SERVER:8443/${BASE}$USER_DIR/$TASK \
  --inputFileList $WORKDIR/${TASK}_${GPACK}.copy \
  --middleware OSG \
  --PNN $SERVER \
  --se_name $SERVER \
  --for_lfn ${USER_DIR}/${TASK}

# to Dropbox
tar fzx $BASEDIR/tgz/PyCox.tgz
cd PyCox
./install.sh
source setup.sh
# put config in the default spot
mv $BASEDIR/.pycox.cfg pycox.cfg
cd -
pwd=`pwd`

# make sure directory exists
executeCmd time python ./PyCox/pycox.py --action mkdir --source /cms/store$USER_DIR/${TASK}
executeCmd time python ./PyCox/pycox.py --action up --source ${TASK}_${GPACK}.copy \
                        --target /cms/store$USER_DIR/${TASK}/${TASK}_${GPACK}.copy

executeCmd mv ${TASK}_${GPACK}.copy ../

exit 0
