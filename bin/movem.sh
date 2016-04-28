#!/bin/bash
# sequence to generate the move command for the tmp files

list --long=1 /cms/store/user/paus/filefi/043/\*/\*_tmp.root | cut -d' ' -f2 | sed -e 's@\(/.*root\)@\1 \1@' -e 's@_tmp.root$@.root@' -e 's@^@move @' \
  | tee move.src

source move.src

exit 0
