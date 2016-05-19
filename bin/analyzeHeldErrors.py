#!/usr/bin/env python
#==================================================================================================
import os,sys,subprocess

with open("./config/heldErrors.db","r") as f:
    input = f.read()
    data = eval(input)

outPatterns = data['outPatterns']
errPatterns = data['errPatterns']

nErrsSites = {}
outCounts = {}
outValues = {}
for tag,value in outPatterns.iteritems():
    outCounts[tag] = 0
    outValues[tag] = ''

errCounts = {}
errValues = {}
for tag,value in errPatterns.iteritems():
    errCounts[tag] = 0
    errValues[tag] = ''

cmd = "condor_q paus -constrain HoldReasonCode!=0 -format %s\n Err"
list = cmd.split(" ")
p = subprocess.Popen(list,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
(out, err) = p.communicate()
rc = p.returncode

out = out.replace('.err','')
files = out.split("\n") 
for stub in files:
    
    if stub == '':
        continue

    se  = ''
    siteName = ''

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

    if siteName == '':
        siteName = se
        continue

 
    lError = False
    with open(stub+'.err',"r") as f:
        for line in f:
            for tag,value in errPatterns.iteritems():
                if value in line:
                    lError = True
                    errCounts[tag] += 1
                    #errValues[tag] += line

    if siteName in nErrsSites:
        pass
    else:
        nErrsSites[siteName] = 0

    if lError:
        nErrsSites[siteName] += 1

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


if len(sys.argv) < 2:
    print ' End (%d)'%(len(sys.argv))
    print ' A: ' + sys.argv[0]
    sys.exit(0)
elif sys.argv[1] == 'remove':
    pass
else:
    print ' Done (%d)'%(len(sys.argv))
    sys.exit(0)

cmd = "condor_q paus -constrain HoldReasonCode!=0 -format %s: clusterId -format %s\n Err"
list = cmd.split(" ")
p = subprocess.Popen(list,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
(out, err) = p.communicate()
rc = p.returncode

out = out.replace('.err','')
lines = out.split("\n") 
for line in lines:
    f = line.split(":")

    if len(f) < 2:
        continue

    clusterId = f[0]
    stub = f[1]

    cmd = ' rm ' + stub + ".*; condor_rm " + clusterId
    print cmd
    os.system(cmd)
    
