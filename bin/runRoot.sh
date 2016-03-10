#!/bin/bash
#===================================================================================================
#
# Execute root histogram extraction for all cut values on one gridpack.
#
#===================================================================================================
# find our bearings
base=`dirname $0`

# command line arguments
TASK="$1"
GPACK="$2"
# load all parameters relevant to this task
source $base/../config/${TASK}.env

echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo " Starting loop through qCut values: $QCUTS"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""

for QCUT in $QCUTS
do

  echo " QCUT: $QCUT"

  # first check whether the file already exists
  if [ -e "${GPACK}-${QCUT}-out.root" ]
  then
    continue
  fi

  # it does not exist, thus make it
  root -l -b -q \
    $base/../root/${ROOTMACRO}.C\(\"${GPACK}-${QCUT}.root\",\"/tmp/${GPACK}-${QCUT}-out.root\"\)
  mv /tmp/${GPACK}-${QCUT}-out.root ./

  # careful, it takes a while until the file will actually be available in hscratch, there is a delay
  # for hadoop disk space.

done

exit 0
