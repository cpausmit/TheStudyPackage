#!/bin/bash
#===================================================================================================
#
# Submit the jobs to generate the MC we specify in the task.
#
#                                                                           v0 - March 2016 - C.Paus
#===================================================================================================
source ./bin/helpers.sh
[ -z "$T2TOOLS_BASE" ] && source ~/T2Tools/setup.sh

# Read the arguments
echo " "
echo "Starting data processing with arguments:"
echo "  --> $*"

BASE=/mnt/hadoop/cms/store/user/paus
CORE=fastsm/043

TASK=`echo $1 | cut -d \. -f1`; LIST=`echo $1 | cut -d \. -f2`; OUTDIR=$2; LOGDIR=$3
if [ "$#" -gt 3 ]
then
  echo ""
  echo -n "CLEANING up all potentially exiting output and log files. Are you sure? "
  read 
  CLEANUP=$4
fi

# Define our work directory
workDir=$PWD

# Prepare environment
echo " "
echo " Process:  TASK=$TASK, OUTDIR=$OUTDIR, LOGDIR=$LOGDIR"
echo " "

# Check the directory for the log and root results
if ! [ -d "$LOGDIR" ] || ! [ -d "$OUTDIR" ]
then
  echo " ERROR - one of the relevant production directories does not exist. EXIT."
  echo " -> $LOGDIR $OUTDIR"
  exit 1
fi

# if we start from scratch, remove it all
if [ "$CLEANUP" == "yes" ]
then
  rm -rf -rf $LOGDIR/$TASK $OUTDIR/$TASK
fi

# Make sure local directories (log and output) exist
mkdir -p $LOGDIR/$TASK $OUTDIR/$TASK

# Make main tar ball and save it for later
if ! [ -e "$LOGDIR/$TASK/default.tgz" ]
then
  cp ~/.pycox.cfg ./
  tar fzc default.tgz .pycox.cfg bin/ config/ generators/ python/ root/ tgz/
  rm -f ./.pycox.cfg
  mv default.tgz $LOGDIR/$TASK
else
  echo ""
  echo -n " TAR ball already exists. Using the existing one. Ok? "
  read
fi

# Set the script file
script=$workDir/bin/makeMc.sh

# Make a record of completed jobs and directories
list $BASE/$CORE/${TASK}_* > /tmp/done.$$

## Make the remote directory to hold our data for the long haul (need to analyze how many distinct
## samples we are making)
#echo " Making all directories for the mass storage. This might take a while."
#for sample in `cat ./config/${TASK}.${LIST} | sed 's/\(.*\)_nev.*$/\1/'|sort -u`
#do
#  echo ""
#  echo " New sample: $sample"
#  exists=`grep ${TASK}_${sample} /tmp/done.$$`
#  echo "Exists: $exists --> ${TASK}_${sample} --> /tmp/done.$$"
#  if [ "$exists" == "" ]
#  then
#    exeCmd makedir                   $BASE/$CORE/${TASK}_$sample
#    exeCmd changemod --options=a+rwx $BASE/$CORE/${TASK}_$sample
#  else
#    echo " Directory already exists: $exists"
#  fi
#done

# Make a record of ongoing jobs
condor_q -global $USER -format "%s " Cmd -format "%s \n" Args \
  | grep `basename $script` > /tmp/condorQueue.$$

# Looping through each single fileset and submitting the condor jobs
echo ""
echo "# Submitting jobs to condor"
echo ""

# loop over the relevant files
nD=0; nQ=0; nS=0
for gpack in `cat ./config/${TASK}.${LIST}`
do

  inQueue=`grep "$gpack" /tmp/condorQueue.$$`
  if [ "$inQueue" != "" ]
  then
    echo " Queued: $gpack"
    let "nQ+=1"
    continue
  fi

  # an emtpy tag to trigger a condor error (will be kept in HELD state)
  outputFiles=${TASK}_${gpack}.empty

  exists=`grep ${TASK}_${gpack}_bambu.root /tmp/done.$$`
  complete=1
  if [ "$exists" == "" ]
  then
    complete=0
  fi

  # make decision of submission
  if [ "$complete" == "0" ]
  then
    echo " Submit: $gpack     <<===="
    let "nS+=1"
  else
    echo " Done:   $gpack"
    let "nD+=1"
    continue
  fi
 
cat > submit.cmd <<EOF
Universe                = vanilla
Environment             = "HOSTNAME=$HOSTNAME"
Requirements            = (isUndefined(IS_GLIDEIN) || OSGVO_OS_STRING == "RHEL 6") && \
                          Arch == "X86_64" && \
                          HasFileTransfer && \
                          CVMFS_cms_cern_ch_REVISION > 21811
Request_Memory          = 2.5 GB
Request_Disk            = 5 GB
Notification            = Error
Executable              = $script
Arguments               = $TASK $gpack
Rank                    = Mips
GetEnv                  = False
Input                   = /dev/null
Output                  = $LOGDIR/${TASK}/${gpack}.lhe.out
Error                   = $LOGDIR/${TASK}/${gpack}.lhe.err
Log                     = $LOGDIR/${TASK}/${gpack}.lhe.log
transfer_input_files    = $LOGDIR/$TASK/default.tgz
Initialdir              = $OUTDIR/$TASK
use_x509userproxy       = True
transfer_output_files   = $outputFiles
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT
on_exit_hold            = (ExitBySignal == True) || (ExitCode != 0)
+AccountingGroup        = "group_cmsuser.$USER"
+ProjectName            = "CpDarkMatterSimulation"
Queue
EOF

  #echo "condor_submit submit.cmd >& /dev/null"
  condor_submit submit.cmd >& /dev/null
  
  # make sure it worked
  if [ "$?" != "0" ]
  then
    # show what happened, exit with error and leave the submit file
    condor_submit submit.cmd
    exit 1
  fi
  
  # it worked, so clean up
  rm submit.cmd

done

echo ""
echo " =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "  SUBMISSION SUMMARY -- nDone: $nD -- nQueued: $nQ -- nSubmitted: $nS"
echo " =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""

exit 0
