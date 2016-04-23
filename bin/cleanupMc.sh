#!/bin/bash
#===================================================================================================
#
# Cleanup the job logs for all successfully completed requests.
#
#                                                                           v0 - March 2016 - C.Paus
#===================================================================================================
TASK=$1; OUTDIR=$2; LOGDIR=$3; MAKETAGS=$4
if [ "$#" -gt 3 ]
then
  echo ""
  echo -n " Remaking all tag files. Are you sure? "
  read 
  MAKETAGS=$4
fi


# make tag files
if [ "$MAKETAGS" != "" ]
then
  # remove all existing tags
  echo " Removing all existing tags."
  rm -f $OUTDIR/$TASK/*.empty

  echo " Updating the tag files."
  echo " ---- D O N E ----" > /tmp/tag.empty
  completedFiles=`list /cms/store/user/paus/fastsm/043/${TASK}_* | grep _bambu.root | cut -d' ' -f2`
  
  for file in $completedFiles
  do
  
    # create tag file
    file=`echo $file | sed -e 's@_bambu.root@.empty@'`
    cp /tmp/tag.empty $OUTDIR/$TASK/$file
  
  done
fi

# go through the existing log files
echo " Removing not needed log files."
completionFiles=`ls -1 $OUTDIR/$TASK | grep empty`
cd $LOGDIR/$TASK
for file in $completionFiles
do

  # remove the not needed logs
  pattern=`echo $file | sed -e 's@.empty@@' -e "s@^${TASK}_@@"`
  deletion=`echo *$pattern*`
  [ "$deletion" !=  "*$pattern*" ] && \
    ( echo " Deleting: rm -f $LOGDIR/$TASK/*$pattern*"; rm -f $LOGDIR/$TASK/*$pattern* )

done
#
# find ~/cms/logs/monojet -cmin +300 -size +1k -print -exec rm {} \;
#
exit 0
