#!/bin/bash
#---------------------------------------------------------------------------------------------------
# Make sure to stay in sync.
#
#---------------------------------------------------------------------------------------------------
export THESTUDYPACKAGE_BASE=$HOME/cms/root/TheStudyPackage
export ENDPOINT=cms/root
export SERVER=ce04.cmsaf.mit.edu

rsync -Cavz $THESTUDYPACKAGE_BASE $SERVER:$ENDPOINT
