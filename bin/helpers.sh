function executeCmd {
  # provide a nice frame for each command, also allows further steering

  echo " "
  echo " =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo " Executing: $*"
  $*
  echo " Completed: $*"
  echo " =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  echo " "
}  

function testInteractive {
  # implement simple minded/not perfect test to see whether script is called interactively

  interactive=0
  if [ "`echo $PWD | grep $USER`" != "" ]
  then
    interactive=1
  fi
  return $interactive
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

function initialState {
  # provide a summary of where we are when we start the job

  h=`basename $0`
  echo "Script:    $h"
  echo "Arguments: $*"
  
  # some basic printing
  echo " ";
  echo "${h}: Show who and where we are";
  echo " start time    : "`date`
  echo " user executing: "`id`;
  echo " running on    : "`hostname`;
  echo " executing in  : "`pwd`;
  echo " submitted from: $HOSTNAME";
  echo ""
  echo " HOME:" ~/;
  echo " ";
  env
  ls -lhrt
  #find ./
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

function setupProxy {
  # setup the proxy for remote copy and data access etc. (function expects proxy in pwd)

  echo ""
  echo "============================================================"
  echo " Setting up the x509 proxy"
  ls -lhrt
  proxy_name=`echo x509*`
  if [ "$proxy_name" == 'x509*' ]
  then
    echo " ERROR -- there seems to be no proxy. -> $proxy_name"
   fi
  export X509_USER_PROXY=`pwd`/$proxy_name
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
