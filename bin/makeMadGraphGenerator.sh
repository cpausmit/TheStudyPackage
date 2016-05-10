#!/bin/bash
#===================================================================================================
#
# Construct the specific MadGraph generator for our TASK from the generic packages.
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
source ./bin/helpers.sh
baseDir=`pwd`

# madgraph source
MG=MG5_aMC_v2.3.3.tar.gz
MG_SOURCE=https://cms-project-generators.web.cern.ch/cms-project-generators/

# command line arguments and corresponding environment
TASK="$1"
source ./config/${TASK}.env

if ! [ -e "./work" ]
then
  mkdir -p ./work
else
  rm -rf ./work/*
fi
cd ./work
workDir=`pwd`

wget --no-check-certificate ${MG_SOURCE}/${MG}
tar xzf ${MG}
rm $MG
export MG_BASE=`echo MG5_*`
cd $MG_BASE

# patch -l -p0 -i $PRODHOME/patches/mgfixes.patch
# patch -l -p0 -i $PRODHOME/patches/models.patch

echo "set auto_update 0"                 > config.$$
echo "set automatic_html_opening False" >> config.$$
echo "set lhapdf $LHAPDFCONFIG"         >> config.$$
echo "set run_mode 0"                   >> config.$$
echo "save options"                     >> config.$$
cat config.$$
./bin/mg5_aMC config.$$

# now we need to get all relevant models 
cd models/
sed 's:#.*$::g' $baseDir/config/${TASK}/template_extramodels.dat | while read model
do
  echo Model: $model
  if [ -e "$baseDir/tgz/$model" ]
  then
    cp $baseDir/tgz/$model ./
  else
    ##wget --no-check-certificate $MG_SOURCE/$model
    echo " MODEL NOT FOUND"
  fi
  tar xzf $model
  dir=`tar fzt $model | head -1`
  rm $model

##  # fine tuning of the parameters
##  if [ "$model" == "DMAxial_monow012j.tgz" ] 
##  then
##     # adjust model defaults -- irrelevant numbers for now
##    cat $dir/parameters.py | sed -e 's@XX-MED-XX@10@' -e 's@XX-DM-XX@1@' > tmp.py
##    mv tmp.py $dir/parameters.py
##  fi
##
done
cd -

# finally we build the generator
cd $workDir
./$MG_BASE/bin/mg5_aMC $baseDir/config/${TASK}/template_proc_card.dat

# copy our run card into the default location
cp $baseDir/config/${TASK}/template_run_card.dat madgraph-generator/Cards/run_card.dat

# change the name to our task
mv madgraph-generator madgraph-${TASK}

# tar it, and move the generator ready to be shipped for production
tar fzc madgraph-${TASK}.tgz madgraph-${TASK} $MG_BASE
mv madgraph-${TASK}.tgz $baseDir/generators/

# do some cleanup
cd $baseDir
rm -rf ./work/*

exit 0
