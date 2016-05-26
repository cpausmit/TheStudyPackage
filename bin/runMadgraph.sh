#!/bin/bash
# ---------------------------------------------------------------------------------------------------
# Basic script to take the customizecards for madgraph to be replaced with the specific values for
# the given point and run the madgraph generator with it. Run scripts always start in the work
# directory. The environment has to be setup before, this is the driver that does it.
#
# env: BASEDIR, WORKDIR
#
#                                                                        Ch.Paus (v0 - Mar 17, 2016)
#---------------------------------------------------------------------------------------------------
# read commend line parameters
TASK="$1"
GPACK="$2"

# make sure madgraph is ready
$BASEDIR/bin/setupMadgraph.sh $TASK $GPACK

# find the base for madgraph program
export MG_BASE=`echo MG5_*`

# move into the binary directory
cd madgraph-${TASK}/bin

# copy the customization template
cp $BASEDIR/$VERSION/$TASK/template_customizecards.dat ./

# generate all generator parameter settings from the GPACK string
sedString=''
params=`echo $GPACK |sed "s/-/=/g"| sed "s/_/ /g"`
echo " PARAMETERS: $params"
for param in $params
do
  tag=`  echo $param| tr [a-z] [A-Z]| cut -d'=' -f1`
  value=`echo $param| cut -d'=' -f2`
  echo " par: $param --> tag: $tag / value: $value"
  sedString="$sedString -e s/XX-$tag-XX/$value/g"
done

# customize
if [ -e "$BASEDIR/$VERSION/$TASK/addTag" ]
then
  sedString="$sedString "`$BASEDIR/$VERSION/$TASK/addTag $GPACK`
fi

# translate the template with sed
echo " SED: $sedString"
echo "sed $sedString template_customizecards.dat"
sed $sedString template_customizecards.dat > customizecards.dat
cat customizecards.dat

# make sure to say where the madgraph program is (this string needs to be updated on the worker)
cat  ../Cards/me5_configuration.txt | grep -v mg5_path > ./tmp.$$
mv ./tmp.$$ ../Cards/me5_configuration.txt
echo "mg5_path = $WORKDIR/$MG_BASE" >> ../Cards/me5_configuration.txt

# finally we are ready, run the generator
cat customizecards.dat | ./generate_events

# Take care of the output
#
# the weighted and unweighted events are the same once you include the weights correctly
# statistical significance is the same, so we should go with the unweighted events, there are less
#
# Reference: https://answers.launchpad.net/mg5amcnlo/+question/268332
#
ls -lhrt ../Events/run_01/
gunzip   ../Events/run_01/unweighted_events.lhe.gz
mv       ../Events/run_01/unweighted_events.lhe    $WORKDIR/${TASK}_${GPACK}.lhe

# return to the work directory
cd $WORKDIR

exit
