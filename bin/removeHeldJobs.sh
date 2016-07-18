#!/bin/bash

# show summary of what we start with
condor_q $USER | grep held

# remove the held jobs
condor_rm -constraint HoldReasonCode!=0
# make sure they disappear quickly
condor_rm -forcex paus;
