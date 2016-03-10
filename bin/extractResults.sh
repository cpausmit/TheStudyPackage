#!/bin/bash
#===================================================================================================
#
# Go through all log files and root summary files to extract plots and numbers and publish them.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
source ./bin/helpers.sh

echo " "
echo "Starting data processing with arguments:"
echo "  --> $*"

# read command line arguments
TASK="$1"
OUTDIR="$2"
LOGDIR="$3"
# load all parameters relevant to this task
source ./config/${TASK}.env

# create the list of gridpacks
gpacks=`cat ./config/${TASK}.list`

# work directory
workDir=$PWD

#---------------------------------------------------------------------------------------------------
# Remake the potentially missing root files
#---------------------------------------------------------------------------------------------------

# loop over the relevant files
echo " Check whether all compact root outputs are ready and make the missing ones."
cd $OUTDIR/$TASK
for gpack in $gpacks
do
  # execute the root macro
  executeCmd $workDir/bin/runRoot.sh $TASK $gpack
done

#---------------------------------------------------------------------------------------------------
# Produce the high level output
#---------------------------------------------------------------------------------------------------

# need this public directory
mkdir -p ${WWWDIR}/$TASK

# copy the config parameters
cd $workDir
cp ./html/index.php                   ${WWWDIR}/$TASK
cp ./config/${TASK}.env               ${WWWDIR}/$TASK
cp ./python/${HADRONIZER}.py-template ${WWWDIR}/$TASK
cp ./python/${PRODPY}.py-template     ${WWWDIR}/$TASK

# make the cut variation plots - loop over the relevant files
echo " Create all plots."
cd $OUTDIR/$TASK
for gpack in $gpacks
do
  for hist in $HISTS
  do
    # execute the root macro
    executeCmd root -l -b -q $workDir/root/qCutVariation.C\(\"${gpack}\",\"${hist}\"\)
    mv /tmp/${gpack}*${hist}.png ${WWWDIR}/$TASK
  done
done

# matching efficiencies - loop over the relevant files
cd $workDir
meFile="./CrossSectionsAndMatching.txt"
rm -f $meFile
touch $meFile 
echo " Extract cross sections and matching efficiencies."
for gpack in $gpacks
do
  # extracting the matching efficiency numbers
  ./bin/matchingEfficiency.sh $LOGDIR/$TASK/$gpack*${SELECTEDQCUT}.out >> $meFile
done
mv $meFile ${WWWDIR}/$TASK
