#!/bin/bash
#===================================================================================================
#
# Submit our jobs to run the production: LHE file input and Hadronizer to make GEN root files.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
source ./bin/helpers.sh

function errorAnalysis {
  # analyze the files for failures (needs global variables: TASK, LOGDIR)

  GPACK="$1"
  QCUT="$2" 

  echo "+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+"
  echo ""
  echo " Failed job for gridpack: $GPACK at q-cut: $QCUT"
  echo ""
  if [ -e $LOGDIR/$TASK/${GPACK}-${QCUT}.out ]
  then
    grep 'running on' $LOGDIR/$TASK/${GPACK}-${QCUT}.out
  else
    echo " Output does not exist for this job."
  fi
  echo "+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+_+"
  echo ""
  if [ -e $LOGDIR/$TASK/${GPACK}-${QCUT}.out ]
  then
    cat  $LOGDIR/$TASK/${GPACK}-${QCUT}.err
  fi
}

export TASK=$1
export OUTDIR=$2
export LOGDIR=$3
# load all parameters relevant to this task
source ./config/${TASK}.env

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

# Make sure directories exists
mkdir -p $LOGDIR/$TASK $OUTDIR/$TASK

# Make main tar ball and save it for later
tar fzc default.tgz bin/ config/ python/ root/
mv      default.tgz $LOGDIR/$TASK
sleep 4
tar fzt $LOGDIR/$TASK/default.tgz

# Set the script file
script=$workDir/bin/runOne.sh

# Get a new proxy
newProxy

# Make a record of ongoing jobs
condor_q -global $USER -format "%s " Cmd -format "%s \n" Args > /tmp/condorQueue.$$

# Looping through each single fileset and submitting the condor jobs
echo ""
echo "# Submitting jobs to condor"
echo ""

# loop over the relevant files
for gpack in `cat ./config/${TASK}.list`
do

  if ! [ -e "$OUTDIR/$TASK/${gpack}.lhe" ]
  then
    echo " LHE file does not exist for: $gpack"
    echo "  --> $OUTDIR/$TASK/${gpack}.lhe"
    continue
  else
    size=`stat --printf="%s" $OUTDIR/$TASK/${gpack}.lhe`
    if [ "$size" == "0" ]
    then
      echo " LHE file exists but is empty for: $gpack "
      continue
    fi  
  fi

  for qcut in $QCUTS
  do

    inQueue=`grep "$gpack $qcut" /tmp/condorQueue.$$`
    if [ "$inQueue" != "" ]
    then
      echo " Queued: ${gpack} ${qcut}"
      continue
    fi
  
    outputFiles="${gpack}-${qcut}.root,${gpack}-${qcut}-out.root"
  
    # see whether the files are already there
  
    complete=1 
    for output in `echo $outputFiles | tr ',' ' '`
    do
      # test every required file for existence and non-null length
      size=0
      if [ -e "$OUTDIR/$TASK/$output" ]
      then
        size=`stat --printf="%s" $OUTDIR/$TASK/$output`
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
      errorAnalysis $gpack $qcut
      echo " Submit: $TASK $gpack $qcut  <<===="
    else
      echo " Done:   $TASK $gpack $qcut"
      continue
    fi
 

cat > submit.cmd <<EOF
Universe                = vanilla
Environment             = "HOSTNAME=$HOSTNAME"
Requirements            = (UidDomain == "cmsaf.mit.edu" || UidDomain == "mit.edu") && Arch == "X86_64" && \
                           Disk >= DiskUsage && (Memory * 1024) >= ImageSize && HasFileTransfer &&  \
                           Disk >= (10000 * 1024) && machine != "t3btch039.mit.edu" && machine != "t3btch008.mit.edu"
## && Machine != "t3btch039.mit.edu"
Notification            = Error
Executable              = $script
Arguments               = $TASK $gpack $qcut
Rank                    = Mips
GetEnv                  = False
Input                   = /dev/null
Output                  = $LOGDIR/${TASK}/${gpack}-${qcut}.out
Error                   = $LOGDIR/${TASK}/${gpack}-${qcut}.err
Log                     = $LOGDIR/${TASK}/${gpack}-${qcut}.log
transfer_input_files    = $x509File,$OUTDIR/$TASK/${gpack}.lhe,$LOGDIR/$TASK/default.tgz
Initialdir              = $OUTDIR/$TASK
transfer_output_files   = $outputFiles
should_transfer_files   = YES
when_to_transfer_output = ON_EXIT
use_x509userproxy       = True
+AccountingGroup        = "group_cmsuser.$USER"
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

done

exit 0
