#!/bin/bash
#===================================================================================================
#
# Submit the jobs to generate the MC we specify in the task.
#
#===================================================================================================
# Read the arguments
echo " "
echo "Starting data processing with arguments:"
echo "  --> $*"

SERVER="se01.cmsaf.mit.edu"
BASE="srm/v2/server?SFN="
USER_DIR="/mnt/hadoop/cms/store/user/paus/study"

TASK=$1
OUTDIR=$2
LOGDIR=$3
if [ "$#" -gt 3 ]
then
  echo ""
  echo -n "CLEANING up all potentially exiting files. Are you sure? "
  read 
  CLEANUP=$4
fi

# Define our work directory
workDir=$PWD

# Make the remote directory to hold our data for the long haul
#glexec mkdir -p    /mnt/hadoop/cms/store/user/paus/study/$TASK
#glexec chmod a+rwx /mnt/hadoop/cms/store/user/paus/study/$TASK
echo ssh $SERVER mkdir -p    ${USER_DIR}/$TASK
ssh $SERVER mkdir -p         ${USER_DIR}/$TASK
echo ssh $SERVER chmod a+rwx ${USER_DIR}/$TASK
ssh $SERVER chmod a+rwx      ${USER_DIR}/$TASK

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
tar fzc default.tgz bin/ config/ generators/ python/ root/ tgz/
mv      default.tgz $LOGDIR/$TASK
sleep 4
tar fzt $LOGDIR/$TASK/default.tgz

# Set the script file
script=$workDir/bin/makeCopy.sh

# Make sure there is a globus tickets available
x509File=/tmp/x509up_u`id -u`

# Make a record of ongoing jobs
condor_q -global $USER -format "%s " Cmd -format "%s \n" Args | grep makeLhe > /tmp/condorQueue.$$

# Looping through each single fileset and submitting the condor jobs
echo ""
echo "# Submitting jobs to condor"
echo ""

# loop over the relevant files
for gpack in `cat ./config/${TASK}.list`
do

  inQueue=`grep "$gpack" /tmp/condorQueue.$$`
  if [ "$inQueue" != "" ]
  then
    echo " Queued: $gpack"
    continue
  fi

  outputFiles=${TASK}_${gpack}.copy

  # see whether the files are already there

  complete=1
  for output in `echo $outputFiles | tr ',' ' '`
  do
    # test every required file for existence and non-null length
    size=0
    if [ -e "$OUTDIR/$TASK/$output" ]
    then
      size=`stat --printf="%s" $OUTDIR/$TASK/$output`
      #echo " Output: $output - $size"
    fi
    # break out of the loop of one file missing or incomplete
    if [ "$size" == "0" ]
    then
      complete=0
      break
    fi  
  done

  # make decision of submission
  if [ "$complete" == "0" ]
  then
    echo " Submit: $gpack     <<===="
  else
    echo " Done:   $gpack"
    continue
  fi
 
cat > submit.cmd <<EOF
Universe                = vanilla
Environment             = "HOSTNAME=$HOSTNAME"
Requirements            = (isUndefined(IS_GLIDEIN) || OSGVO_OS_STRING == "RHEL 6") && \
                          Arch == "X86_64" && \
                          Disk >= DiskUsage && (Memory * 1024) >= ImageSize && HasFileTransfer &&  \
                          Disk >= (10000 * 1024) && \
                          Machine != "t3btch039.mit.edu" && Machine != "t3btch008.mit.edu"
Notification            = Error
Executable              = $script
Arguments               = $TASK $gpack
Rank                    = Mips
GetEnv                  = False
Input                   = /dev/null
Output                  = $LOGDIR/${TASK}/${gpack}.lhe.out
Error                   = $LOGDIR/${TASK}/${gpack}.lhe.err
Log                     = $LOGDIR/${TASK}/${gpack}.lhe.log
transfer_input_files    = $x509File,$LOGDIR/$TASK/default.tgz
Initialdir              = $OUTDIR/$TASK
transfer_output_files   = $outputFiles
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT
+AccountingGroup        = "group_cmsuser.$USER"
+ProjectName            = "CpDarkMatterSimulation"
Queue
EOF

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

exit 0
