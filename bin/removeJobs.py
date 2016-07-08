#!/usr/bin/env python
#==================================================================================================
import os,sys,subprocess

def findJobsFromDataset(dataset,debug=0):
    # find all jobs from given dataset

    cmd = "condor_q " + os.getenv('USER') + " -format %d: ClusterId -format %s\n Args"
    list = cmd.split(" ")
    
    if debug > 0:
        print " CMD: " + cmd
        print list
    
    p = subprocess.Popen(list,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    (out, err) = p.communicate()
    rc = p.returncode
    
    if debug > 0:
        print "\n RC : " + str(rc)
        print "\n OUT: " + out
        print "\n ERR: " + err
    
    clusterIds = []
    lines = out.split("\n") 
    for line in lines:
        if dataset in line:
            f = line.split(":")
            clusterId = f[0]
            if clusterId in clusterIds:
                continue
            else:
                clusterIds.append(clusterId)

    return clusterIds

#---------------------------------------------------------------------------------------------------
#                                         M A I N
#---------------------------------------------------------------------------------------------------
# read command line
if len(sys.argv) != 2:
    print ' Please specify one argument: dataset'
    sys.exit(1)
dataset = sys.argv[1]

# general parameters
debug = 0

# get the clusterIds to kill
clusterIds = findJobsFromDataset(dataset,debug)

# loop through the job stubs
for clusterId in clusterIds:

    #cmd = ' rm ' + stub + ".*; condor_rm " + clusterId
    cmd = 'condor_rm ' + clusterId
    print cmd
    os.system(cmd)
