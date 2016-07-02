#!/usr/bin/env python
#==================================================================================================
import os,sys,subprocess

def addSite(siteTag,nErrsSites):
    # add a new site to the mix

    if siteTag in nErrsSites:
        nErrsSites[siteTag] += 1
    else:
        nErrsSites[siteTag] = 1
    return nErrsSites

def addErrorAtSite(errorTag,siteTag,nErrsSitesTypes):
    # add one error count for a given error type at a given site

    if errorTag in nErrsSitesTypes:
        nErrsSitesTypes[errorTag] = addSite(siteTag,nErrsSitesTypes[errorTag])
    else:
        # first appearence of error tag
        nErrsSites = {}
        nErrsSites[siteTag] = 1
        nErrsSitesTypes[errorTag] = nErrsSites
 
    return nErrsSitesTypes

def printErrorAtSite(nErrsSitesTypes):

    # find all site tags
    siteTags = []
    for errTag,nErrsSite in nErrsSitesTypes.iteritems():
        for siteTag in nErrsSite:
            if siteTag not in siteTags:
                siteTags.append(siteTag)

    sys.stdout.write(" %-10s "%('=========='))
    for siteTag in siteTags:
        sys.stdout.write("%10s "%siteTag[:10])        


    for errTag,nErrsSite in nErrsSitesTypes.iteritems():
        sys.stdout.write("\n %-10s "%errTag)
        for siteTag in siteTags:
            if siteTag in nErrsSite:
                sys.stdout.write("%10d "%(nErrsSite[siteTag]))
            else:
                sys.stdout.write("%10d "%(0))
    print ''

    return

def findHeldJobStubs(debug=0):
    # find all job file stubs (without .err/.out extensions) to analyze

    cmd = "condor_q " + os.getenv('USER') + " -constrain HoldReasonCode!=0 -format %s: Err"
    list = cmd.split(" ")
    
    if debug > 0:
        print " CMD: " + cmd
        print list
    
    p = subprocess.Popen(list,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    (out, err) = p.communicate()
    rc = p.returncode
    
    if debug > 0:
        print "\n\n RC : " + str(rc)
        print "\n\n OUT: " + out
        print "\n\n ERR: " + err
    
    out = out.replace('.err','')
    stubs = out.split(":") 

    return stubs

def readPatterns(debug=0):
    # read the patterns to search for in error and output files

    with open("./config/heldErrors.db","r") as f:
        input = f.read()
        data = eval(input)
    
    if debug > 0:
        print " PATTERNS: "
        print data

    oPs = data['outPatterns']
    ePs = data['errPatterns']

    return (oPs, ePs)

#---------------------------------------------------------------------------------------------------
#                                         M A I N
#---------------------------------------------------------------------------------------------------

# general parameters
debug = 0

# get the patterns to look for
(outPatterns, errPatterns) = readPatterns(debug)

# keep track of sites showing errors
nErrsSites = {}

# keep track of output file patterns
outCounts = {}
outValues = {}
for tag,value in outPatterns.iteritems():
    outCounts[tag] = 0
    outValues[tag] = ''

# keep track of error file patterns
errCounts = {}
errValues = {}
for tag,value in errPatterns.iteritems():
    errCounts[tag] = 0
    errValues[tag] = ''

nErrsSitesTypes = {}

# get the job file stubs to analyze
stubs = findHeldJobStubs(debug)

# loop through the job stubs
for stub in stubs:

    if stub == '':
        continue

    se  = 'undefined'
    siteName = 'undefined'

    if not os.path.exists(stub+'.out') or  not os.path.exists(stub+'.err'):
        print ' Output/Error file not available: ' + stub
        continue

    if debug > 1:
        print " Open: %s"%(stub+'.out')
    with open(stub+'.out',"r") as f:
        for line in f:
            for tag,value in outPatterns.iteritems():
                if value in line:
                    outCounts[tag] += 1
                    if tag == 'glideinSe':
                        se = line.replace('\n','')                       
                    if tag == 'glidein':
                        siteName = line.replace('\n','')                       
                        siteName = siteName.replace('GLIDEIN_ResourceName=','')
 
    errTag = 'ud'
    lError = False
    if debug > 1:
        print " Open: %s"%(stub+'.err')
    with open(stub+'.err',"r") as f:
        for line in f:
            for tag,value in errPatterns.iteritems():
                if value in line:
                    lError = True
                    errTag = tag
                    errCounts[tag] += 1
                    #errValues[tag] += line

    if siteName in nErrsSites:
        pass
    else:
        nErrsSites[siteName] = 0

    if lError:
        nErrsSites[siteName] += 1

    if errTag != 'ud':
        nErrSitesTypes = addErrorAtSite(errTag,siteName,nErrsSitesTypes)

print ''
print ' ---- ERROR SUMMARY ----'
print '  error tag       count '
print ' ======================='
nTotal = 0
for tag in sorted(errPatterns):
    print '  %-14s: %4d'%(tag,errCounts[tag])
    nTotal += errCounts[tag]
print ' ---------------------------'
print '  %-14s: %4d'%('TOTAL',nTotal)
print ' ==========================='
print ''
print ''
print ' ------ ERROR SUMMARY SITE -------'
print '  site tag                  count '
print ' ================================='
nTotal = 0
for tag in sorted(nErrsSites):
    print '  %-25s: %4d'%(tag,nErrsSites[tag])
    nTotal += nErrsSites[tag]
print ' --------------------------------'
print '  %-25s: %4d'%('TOTAL',nTotal)
print ' ================================'
print ''

print ' Error Matrix'
printErrorAtSite(nErrsSitesTypes)
print ''

if len(sys.argv) < 2:
    print ' End (%d)'%(len(sys.argv))
    print ' A: ' + sys.argv[0]
    sys.exit(0)
elif sys.argv[1] == 'remove':
    pass
else:
    print ' Done (%d)'%(len(sys.argv))
    sys.exit(0)

cmd = "condor_q " + os.getenv('USER') \
    + " -constrain HoldReasonCode!=0 -format %s: ClusterId -format %s: ProcId -format %s\n Err"
list = cmd.split(" ")
p = subprocess.Popen(list,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
(out, err) = p.communicate()
rc = p.returncode

out = out.replace('.err','')
lines = out.split("\n") 
for line in lines:
    f = line.split(":")
    print ' Line: ' + line

    if len(f) < 2:
        continue

    clusterId = f[0]
    procId = f[1]
    stub = f[2]

    cmd = ' rm ' + stub + ".*; condor_rm " + clusterId + "." + procId
    print cmd
    os.system(cmd)
