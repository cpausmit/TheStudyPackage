#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Basic script to configure powheg according to the given GPACK settings. Run scripts always start
# in the work directory. The environment has to be setup before, this is the driver that does it.
#
# env: WORKDIR, HADRONIZER, HADRONIZER_NLO
#                                                                        Ch.Paus (v0 - Mar 17, 2016)
#---------------------------------------------------------------------------------------------------
# read command line parameters
TASK="$1"
GPACK="$2"

# select the right program to run
if [[ $GPACK == *"proc-805"* ]] || [[ $GPACK == *"proc-806"* ]] || [[ $GPACK == *"proc-807"* ]]
then
  echo " Use: POWHEG-BOX-V2/DMS_tloop"
  cd POWHEG-BOX-V2/DMS_tloop
else
  echo " Use: POWHEG-BOX-V2/DMV"
  cd POWHEG-BOX-V2/DMV
  export HADRONIZER=$HADRONIZER_NLO
fi

# translate the GPACK name into our parameters
params=`echo $GPACK |sed "s/-/=/g"| sed "s/^/--/"| sed "s/_/ --/g"`

# now we run the generator
./run.py $params

# fix the lhe file is needed
#  - some particle Ids (+-1000021 -> 1000022) need to be changed for later hadronization (hack)
#  - add cross section in right spot (CP - seems to be wrong anyway, but pythia needs non zero xs?!)
xs0=`cat ./pwg-stat.dat | grep Total | awk '{print $4}'`
xs1=`cat ./pwg-stat.dat | grep Total | awk '{print $6}'`
oldLine=" -1.00000E+00 -1.00000E+00  1.00000E+00  10001"
newLine=" $xs0 $xs1 1.00000000000E-00 100"
cat pwgevents.lhe \
    | sed "s/^ \(#.*\)/<!-- \1 -->/" \
    | sed "s@1000021@1000022@g" | sed "s@-1000022@1000022@g" | sed "s@$oldLine@$newLine@" \
    > cmsgrid_final.lhe

mv cmsgrid_final.lhe $WORKDIR/${TASK}_${GPACK}.lhe

# return to where we started
cd $WORKDIR

exit
