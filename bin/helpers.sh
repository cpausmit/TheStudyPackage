function exeCmd {
  # provide a small frame for each command, also allows further steering
  echo " Executing: $*"
  $*
}  

function executeCmd {
  # provide a nice frame for each command, also allows further steering

  echo " "
  echo " =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  exeCmd $*
  echo " Completed: $*"
  echo " =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo " "
  
}  

function testBatch {
  # implement simple minded/not perfect test to see whether script is run in batch

  batch=0
  if [ "`echo $PWD | grep $USER`" == "" ]
  then
    batch=1
  fi
  return $batch
}

function printOutputfiles {
  # print out the expected output filelist

  TASK="$1"
  QCUTS="$2"

  list=""
  for QCUT in $QCUTS
  do
    if [ "$list" = "" ]
    then
       list="${TASK}-${QCUT}.root,${TASK}-${QCUT}-out.root"
    else
       list="$list,${TASK}-${QCUT}.root,${TASK}-${QCUT}.root"
    fi
  done
  echo $list
}

function showDiskSpace {
  # implement a simple minded summary of the available disk space and usage

  [ -z $BASEDIR ] && $BASEDIR="./"

  echo ""
  echo " Disk space overview "
  echo " =================== "
  df -h $BASEDIR
  echo ""
  echo " Disk space usage "
  echo " ================ "
  du -sh $BASEDIR/*
}

function iniState {
  # provide a short summary of where we are when we start the job

  h=`basename $0`
  echo "Script:    $h"
  echo "Arguments: $*"
  
  # some basic printing
  echo " "
  echo "${h}: Show who and where we are"
  echo " start time    : "`date`
  echo " user executing: "`id`
  echo " running on    : "`hostname`
  echo " executing in  : "`pwd`
  echo " submitted from: $HOSTNAME"
  echo ""
}  

function initialState {
  # provide a summary of where we are when we start the job

  iniState
  echo ""
  echo " HOME:" ~/
  echo " "
  env
  ls -lhrt
  showDiskSpace
}  

function setupCmssw {
  # setup a specific CMSSW release and add the local python path

  THIS_CMSSW_VERSION="$1"
  THIS_PY="$2"

  echo ""
  echo "============================================================"
  echo " Initialize CMSSW $THIS_CMSSW_VERSION for $THIS_PY"
  source /cvmfs/cms.cern.ch/cmsset_default.sh
  scram project CMSSW CMSSW_$THIS_CMSSW_VERSION
  cd CMSSW_$THIS_CMSSW_VERSION/src 
  eval `scram runtime -sh`
  export PYTHONPATH="${PYTHONPATH}:../python"
  cd -
  echo "============================================================"
  echo ""
}

function configureSite {
  # in case we are not at a CMS site we need to have a configuration

  link="/cvmfs/cms.cern.ch/SITECONF/local"

  if [ -d "`readlink $link`" ]
  then
    echo " Link exists. No action needed. ($link)"
  else
    echo " WARNING -- Link points nowhere! ($link)"
    echo "  -- unpacking private local config to recover"
    executeCmd tar fzx $BASEDIR/tgz/siteconf.tgz
    cd SITECONF
    rm -f local
    ln -s ./T3_US_OSG ./local
    ls -lhrt
    cd -
    # make sure this is the config to be used
    export CMS_PATH=`pwd`
  fi
}

function setupProxy {
  # setup the proxy for remote copy and data access etc. (function expects proxy in pwd)

  echo ""
  echo "============================================================"
  echo " Setting up the x509 proxy"
  ls -lhrt
  proxy_name=`echo x509*`
  if [ "$proxy_name" == 'x509*' ]
  then
    echo " WARNING -- no proxy in this directory -> look in standard places"
    export X509_USER_PROXY=`voms-proxy-info -p`
  else
    export X509_USER_PROXY=`pwd`/$proxy_name    
  fi
  env | grep  X509
  echo "============================================================"
  echo ""
}

function tarMeUp {
  # tar up the present project but be careful

  baseDir=`pwd`
  baseDir=`basename $baseDir`

  if [ "$baseDir" == "TheStudyPackage" ]
  then
    echo " Starting the TAR"
    cd ..
    tar fzc $baseDir.tgz $baseDir
    pwd
    ls -lhrt $baseDir.tgz
    cd -
  else
    echo " ERROR - Tar failed, wrong initial directory: $baseDir -> "`pwd`
  fi
}


function distributeToTier2 {
  # distribute present release to Tier2

  baseDir=`pwd`
  baseDir=`basename $baseDir`

  if [ "$baseDir" == "TheStudyPackage" ] && [ -e "../$baseDir.tgz" ]
  then
    executeCmd scp ../$baseDir.tgz se01.cmsaf.mit.edu:cms/root/$baseDir.tgz
    executeCmd ssh se01.cmsaf.mit.edu "cd cms/root; rm -rf $baseDir; tar fzx $baseDir.tgz; ls -lhrt"
  else
    echo " ERROR - failed, tar ball? and right directory?: $baseDir -> "`pwd`
  fi
}

function split {
  # given raw list with for example 50000 events will be split up into NSEEDS pieces into split file

  FILE="$1"
  NSEEDS="$2"
  SPLIT_FILE="$3"

  rm    $SPLIT_FILE
  touch $SPLIT_FILE

  for line in `cat $FILE`
  do
    core=`echo $line | sed 's/_nev-[0-9]*//'`
    nTotal=`echo $line | sed 's/.*_nev-//'| sed 's/\([0-9]*\)_.*/\1/'`
    nEvents=`echo $nTotal $NSEEDS | awk '{ print $1/$2 }'`

    echo " LINE: $line  -> $core  $nTotal  $nEvents"
    i=0
    while [ $i -lt $NSEEDS ]
    do    
      seed=`echo $i | awk '{ print 1000+$1}'`
      echo "${core}_nev-${nEvents}_seed-${seed}"
      echo "${core}_nev-${nEvents}_seed-${seed}" >> $SPLIT_FILE
      let "i+=1"
    done
  done
}
