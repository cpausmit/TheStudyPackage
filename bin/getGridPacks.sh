#!/bin/bash
#===================================================================================================
#
# Download gridpacks specified in the list. The list is assumed to be a valid xrootd location so
# the file can be copied from there to our local area ( ./tar.xz/ ).
#
#===================================================================================================
# make sure we are locked and loaded
[ -d "./bin" ] || ( tar fzx default.tgz )
source ./bin/helpers.sh

function usage {
  echo ""
  echo " No list provided or list does not exist, please specify a valid list file."
  echo ""
  echo "   usage:   $0  <listFile>"
  echo ""
  exit 0
}

LIST="$1"
if [ "$LIST" == "" ] || ! [ -e "$LIST" ]
then
  usage
fi

# quote the input list

echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo " Starting loop over all files in: $LIST"
echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo ""

# loop over each file in the list (just and xrootd file location)

for file in `cat $LIST`
do
  # download the file locally
  executeCmd xrdcp $file ./tar.xz/
done

exit 0;
