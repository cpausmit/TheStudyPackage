#!/bin/bash
#==================================================================================================
NLINES="$1"
if   [ -z "$NLINES" ]
then
  NLINES=20
elif [ "$NLINES" == -1 ]
then
  NLINES=""
fi
PATTERN="$2"

cHeld="condor_q $USER -constraint HoldReasonCode!=0"
holdReason=`$cHeld -format "%s\n" LastRemoteHost -format "%s\n\n" HoldReason`
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "HOLD REASON SUMMARY"
echo ""
echo "$holdReason"
echo ""
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo " "
echo -n " Press <return> to see the error logs. "
read continue

errors=`$cHeld -format "%s" ClusterId -format ":%s" ProcId -format ":%s" Err -format ":%s\n" HoldReason|tr -s ' '|tr ' ' '+' `
for error in $errors
do
  #echo "analyze: $error"
  clusterId=`echo $error | cut -d: -f1`
  procId=`   echo $error | cut -d: -f2`
  errFile=`  echo $error | cut -d: -f3`

  if ! [ -z "$PATTERN" ]
  then
    if [ `echo $errFile | grep $PATTERN` != ''] 
    then
      continue    
    fi
  fi

  holdReason=`echo $error | cut -d: -f3-10`
  outFile=`echo $errFile | sed "s@.err@.out@"`
  logFile=`echo $errFile | sed "s@.err@.log@"`

  # zero size files?
  size=0
  if [ -e "$outFile" ]
  then
    size=`stat --printf="%s" $outFile`
  fi
  # skip if this is zero
  if [ "$size" == "0" ]
  then
    echo " Skipping empty file: $errFile"
    continue
  fi  

  #echo "analyze outfile: $outFile"
  #echo " -- location host $outFile"
  node=`grep 'running on' $outFile | xargs`
  #echo " -- location GI $outFile"
  glidein=`egrep 'GLIDEIN_SEs|GLIDEIN_ResourceName' $outFile|tr '\n' ',' | xargs`
  #echo " -- xrd"
  xrdFail=`egrep 'Failed to open the file|\[ERROR\] Operation expired|\[FATAL\] Redirect limit has been reached|\[ERROR\] Server responded with an error:' $errFile|tr '\n' ','`
  #echo " -- siteconf"
  siteConf=`grep 'Valid site-local-config not found' $errFile | head -1`
  #echo " -- frontier"
  frontier=`grep '\[frontier.c:1111\]: No more proxies' $errFile | head -1`
  #echo " -- coral"
  coral=`grep '::realloc failed ' $errFile` 
  #echo " -- memory"
  memory=`egrep 'std::bad_alloc exception was thrown.|cannot allocate memory' $errFile` 
  #echo " -- diskspace"
  space=`grep 'No space left on device' $errFile`
  #echo " -- io error"
  io=`grep 'Input/output error' $errFile`
  #echo " -- cvmfs not available"
  cvmfs=`grep '/cvmfs/cms.cern.ch/cmsset_default.sh: No such file or director' $errFile`

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo "ERROR FILE: $errFile"
  echo " hold reason: $holdReason"
  echo " location:    $node -- $glidein"
  echo " xrootd:      $xrdFail"
  echo " siteconf:    $siteConf"
  echo " frontier:    $frontier"
  echo " coral:       $coral"
  echo " memory:      $memory"
  echo " space:       $space"
  echo " io:          $io"
  echo " cvmfs:       $cvmfs"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  if [ -z "$NLINES" ]
  then
    cat $errFile
  else
    head -$NLINES $errFile
  fi

  echo ""
  echo " rm $logFile $outFile $errFile; condor_rm $clusterId.$procId"
  echo ""
  echo -n " Remove this held job? [N/y] "
  read remove
  if [ "$remove" == "y" ]
  then
    echo " Removing this job."
    rm $logFile $outFile $errFile
    condor_rm $clusterId.$procId
  fi

done
