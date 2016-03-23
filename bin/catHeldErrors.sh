#!/bin/bash
#
NLINES="$1"

holdReason=`condor_q -l -constraint "HoldReasonCode==13" -format "%s\n" LastRemoteHost -format "%s\n" HoldReason`
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

errorFiles=`condor_q $USER  -constraint "HoldReasonCode==13" -format "%s" ClusterId -format ":%s\n" Err`
for error in $errorFiles
do

  clusterId=`echo $error | cut -d: -f1`
  errFile=`echo $error | cut -d: -f2`
  outFile=`echo $errFile | sed "s@.err@.out@"`
  logFile=`echo $errFile | sed "s@.err@.log@"`

  node=`grep 'running on' $outFile`
  glidein=`egrep 'GLIDEIN_SEs|GLIDEIN_ResourceName' $outFile`

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo "ERROR FILE: $errFile"
  echo " $node --> $glidein"
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  if [ -z "$NLINES" ]
  then
    cat $errFile
  else
    head -$NLINES $errFile
  fi

  echo " Remove this held job? [N/y] "
  read remove
  if [ "$remove" == "y" ]
  then
    echo " Removing this job."
    echo " rm $logFile $outFile $errFile; condor_rm $clusterId"
    rm $logFile $outFile $errFile
    condor_rm $clusterId
  fi

done