#!/bin/bash

GRIDPACKXRDLIST="$1"
GRIDPACKLIST="$2"

cat $GRIDPACKXRDLIST | sed 's@root:.*/@@' \
                     | sed 's@.tar.xz@@'  \
                     > $GRIDPACKLIST

exit 0
