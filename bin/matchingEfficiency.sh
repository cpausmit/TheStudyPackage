#!/bin/bash
#===================================================================================================
#
# Extract the total and matched cross sections and the resulting matching efficiency.
#
#===================================================================================================
FILE="$1"
base=`basename $FILE | sed 's@_tarball.out@@'`
total=`cat $FILE | grep Total`

xsec=`       echo $total | tr -s ' ' | cut -d' ' -f2,3,4`
xsecMatched=`echo $total | tr -s ' ' | cut -d' ' -f11,12,13`
matchingEff=`echo $total | tr -s ' ' | cut -d' ' -f17,18,19`

echo "$base"
echo " Cross section [pb]: $xsec (tot) -> $xsecMatched (matched) - Matching eff. [%]: $matchingEff"
echo ""

exit 0
