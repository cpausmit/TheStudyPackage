#!/bin/bash
#==================================================================================================
NLINES="$1"

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

errors=`$cHeld -format "%s" ClusterId -format ":%s\n" Err`
for error in $errors
do
  #echo "analyze: $error"
  clusterId=`echo $error | cut -d: -f1`
  errFile=`  echo $error | cut -d: -f2`

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
  node=`grep 'running on' $outFile`
  #echo " -- location GI $outFile"
  glidein=`egrep 'GLIDEIN_SEs|GLIDEIN_ResourceName' $outFile`
  #echo " -- xrd"
  xrdFail=`egrep 'Failed to open the file|\[ERROR\] Operation expired' $errFile`
  #echo " -- siteconf"
  siteConf=`grep 'Valid site-local-config not found' $errFile`
  frontier=`grep '\[frontier.c:1111\]: No more proxies' $errFile`

  echo ""
  echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo "ERROR FILE: $errFile"
  echo " location: $node -- $glidein"
  echo " xrootd:   $xrdFail"
  echo " siteconf: $siteConf"
  echo " frontier: $frontier"
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
