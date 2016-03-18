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
BASE="srm/v2/server?SFN=/mnt/hadoop/cms/store"
USER_DIR="/user/paus/study"

# command line arguments
TASK="$1"
GPACK="$2"

ls -lhrt
export X509_USER_PROXY=`pwd`/`echo x509*`
env | grep  X509

mkdir ./work
cd    ./work
workDir=`pwd`

# make a test file
echo "Hello my darling. We should have a cup of tea and discuss this proposal." > testCopy.root
echo "Cheers, CP"                                                              >> testCopy.root
echo ""                                                                        >> testCopy.root

ls -lhrt

setupCmssw 7_6_3 test
tar fzx ../tgz/copy.tgz

executeCmd mv  testCopy.root ${TASK}_${GPACK}.copy

ls -lhrt

executeCmd ./cmscp.py \
  --debug \
  --destination srm://$SERVER:8443/${BASE}$USER_DIR/$TASK \
  --inputFileList $workDir/${TASK}_${GPACK}.copy \
  --middleware OSG \
  --PNN $SERVER \
  --se_name $SERVER \
  --for_lfn ${USER_DIR}/${TASK}

executeCmd mv ${TASK}_${GPACK}.copy ../

#// executeCmd \
#//   lcg-cp -D srmv2 -b file://$workDir/testCopy.root \
#//          srm://$SERVER:8443/${BASE}${USER_DIR}/${TASK}/${TASK}_${GPACK}.copy
 
exit 0
