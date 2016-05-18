# ---------------------------------------------------------------------------------------------------
# Basic script to run the JHU geenrator.
#
# env: BASEDIR, WORKDIR
#
#                                                                        Ch.Paus (v0 - Mar 17, 2016)
#---------------------------------------------------------------------------------------------------
# read commend line parameters
TASK="$1"
GPACK="$2"

# generate all generator parameter settings from the GPACK string
params=`echo $GPACK |sed "s/-/=/g"| sed "s/_/ /g"`
echo " PARAMETERS: $params"
for param in $params
do
  tag=`  echo $param| tr [a-z] [A-Z]| cut -d'=' -f1`
  value=`echo $param| cut -d'=' -f2`
  echo " par: $param --> tag: $tag / value: $value"

  # find 'PROC' and 'MED' values
  if [ "$tag" == "PROC" ]
  then
    proc="$value"
  elif [ "$tag" == "MED" ]
  then
    mass="$value"
  fi
done

## \
## \mass=$1
## \proc=$2
## \filename=$3
## \cp /afs/cern.ch/work/p/pharris/public/bacon/Darkmatter/JHUGenerator_13TeV_v1.tgz .
## \tar xzvf JHUGenerator_13TeV_v1.tgz

# go to the generator directory
cd JHUGenerator

# get a clean start
rm -f *.root *.dat *.lhe

# initialize the scalar (proc=805)
cp mod_Parameters_805.F90 mod_Parameters.F90
make clean
make
./JHUGen Collider=1 Process=50 DecayMode1=11 Unweighted=0 VegasNc0=100000 VegasNc2=50000 MReso=$mass DataFile=W > WxsS.dat
./JHUGen Collider=1 Process=50 DecayMode1=9  Unweighted=0 VegasNc0=100000 VegasNc2=50000 MReso=$mass DataFile=Z > ZxsS.dat

# now use what is requested (proc)
cp mod_Parameters_${proc}.F90 mod_Parameters.F90
make clean
make
./JHUGen Collider=1 Process=50 DecayMode1=11 Unweighted=0 VegasNc0=100000 VegasNc2=50000 MReso=$mass DataFile=W > WxsX.dat
./JHUGen Collider=1 Process=50 DecayMode1=9  Unweighted=0 VegasNc0=100000 VegasNc2=50000 MReso=$mass DataFile=Z > ZxsX.dat
./JHUGen Collider=1 Process=50 DecayMode1=11 Unweighted=1 VegasNc0=10000  VegasNc2=50000 MReso=$mass DataFile=W
./JHUGen Collider=1 Process=50 DecayMode1=9  Unweighted=1 VegasNc0=10000  VegasNc2=50000 MReso=$mass DataFile=Z

exit

## \scramv1 project CMSSW CMSSW_7_1_20
## \cd CMSSW_7_1_20/src/
## \eval `scramv1 runtime -sh`
## \cd -

cmsRun LHEProd_W.py
cmsRun LHEProd_Z.py

cd /afs/cern.ch/user/p/pharris/pharris/public/bacon/prod/CMSSW_7_4_12_patch1/src/BaconAnalyzer/
eval `scramv1 runtime -sh`
cd -
cmsRun makingBacon_LHE_Gen_W.py
cmsRun makingBacon_LHE_Gen_Z.py
WxsS=`cat WxsS.dat   | grep integral | tail -1 | awk '{print $4}'`
ZxsS=`cat ZxsS.dat   | grep integral | tail -1 | awk '{print $4}'`
WxsX=`cat WxsX.dat   | grep integral | tail -1 | awk '{print $4}'`
ZxsX=`cat ZxsX.dat   | grep integral | tail -1 | awk '{print $4}'`
echo "W SF : "$WxsX" -- Z SF : "$ZxsX
Wxs=`echo $WxsX $WxsS | awk '{print $1/$2}'`
Zxs=`echo $ZxsX $ZxsS | awk '{print $1/$2}'`
echo "W SF : "$Wxs" -- Z SF : "$Zxs
runGen -1 test_W.root $Wxs 
mv Output.root Output_v0.root
runGen -1 test_Z.root $Zxs 
mv Output.root Output_v1.root
hadd Output.root Output_v0.root Output_v1.root

mv Output.root ../$filename
cd ../