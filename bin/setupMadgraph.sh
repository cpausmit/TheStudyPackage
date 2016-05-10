#!/bin/bash
#===================================================================================================
#
# Setup the specific MadGraph generator for our TASK from the generic packages.
#
# Called when we are already in the working directory. General MadGraph is already unpacked.
#
#===================================================================================================
TASK="$1"
GPACK="$2"
# make sure we are locked and loaded
source $BASEDIR/bin/helpers.sh
source $BASEDIR/config/${TASK}.env

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

# start madgraph business
export MG_BASE=`echo MG5_*`
cd $MG_BASE

echo "set auto_update 0"                 > config.$$
echo "set automatic_html_opening False" >> config.$$
echo "set lhapdf $LHAPDFCONFIG"         >> config.$$
echo "set run_mode 0"                   >> config.$$
echo "save options"                     >> config.$$
cat config.$$
./bin/mg5_aMC config.$$

# now we need to get all relevant models 
cd models/
sed 's:#.*$::g' $BASEDIR/config/${TASK}/template_extramodels.dat | while read model
do
  echo Model: $model
  if [ -e "$BASEDIR/tgz/$model" ]
  then
    cp $BASEDIR/tgz/$model ./
  else
    ##wget --no-check-certificate $MG_SOURCE/$model
    echo " MODEL NOT FOUND"
  fi
  tar xzf $model
  dir=`tar fzt $model | head -1`
  rm $model

  # fine tuning of the parameters
  if [ -e "$dir/parameters.py" ]
  then
    # adjust model defaults -- irrelevant numbers for now
    echo " cat $dir/parameters.py | sed $sedString > tmp.py "
    cat $dir/parameters.py | sed $sedString > tmp.py
    mv tmp.py $dir/parameters.py
    cd $dir/
    python write_param_card.py
  else
    echo "  !!!! FAILED !!!!  "
    sleep 20
    exit 1
  fi

done
cd -

# finally we build the generator
cd $WORKDIR
./$MG_BASE/bin/mg5_aMC $BASEDIR/config/${TASK}/template_proc_card.dat

# copy our run card into the default location
cp $BASEDIR/config/${TASK}/template_run_card.dat madgraph-generator/Cards/run_card.dat

# change the name to our task
mv madgraph-generator madgraph-${TASK}

exit 0
