#!/bin/bash
#
NLINES="$1"

holdReason=`condor_q -l -constraint "HoldReasonCode==13" -format "%s\n" HoldReason`
echo ""
echo "=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo "HOLD REASON SUMMARY"
echo ""
echo "$holdReason"
echo ""
echo "=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo " "
echo -n " Press <return> to see the error logs. "
read ?

errorFiles=`condor_q -l -constraint "HoldReasonCode==13" | grep ^Err|cut -d \" -f2`
for errorFile in $errorFiles
do

  outputFile=`echo $errorFile | sed "s@.err@.out@"`

  node=`grep 'running on' $outputFile`

  echo ""
  echo "=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo "ERROR FILE: $errorFile"
  echo " $node"
  echo "=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  if [ -z "$NLINES" ]
  then
    cat $errorFile
  else
    head -$NLINES $errorFile
  fi

done