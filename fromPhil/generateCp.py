#! /usr/bin/env python
import commands,sys,os,subprocess
from optparse import OptionParser

eos='/afs/cern.ch/project/eos/installation/cms/bin/eos.select'

def parser():
   parser = OptionParser()
   parser.add_option('--override',action='store_true',     dest='override',default=False,help='Use Specified Ntuples') # need a few more options for monoV
   parser.add_option('--dm'   ,action='store',type='float',dest='dm'    ,default=10,  help='Dark Matter Mass')
   parser.add_option('--med'  ,action='store',type='float',dest='med'   ,default=2000,help='Mediator Mass')
   parser.add_option('--width',action='store',type='float',dest='width' ,default=1,   help='Width (in Min width units)')
   parser.add_option('--proc' ,action='store',type='float',dest='proc'  ,default=800, help='Process(800=V,801=A,805=S,806=P)')
   parser.add_option('--gq'   ,action='store',type='float',dest='gq'    ,default=1,   help='coupling to quarks')
   parser.add_option('--gdm'  ,action='store',type='float',dest='gdm'   ,default=1,   help='coupling to dark matter')
   parser.add_option('--label',action='store',type='string',dest='label',default='model3',help='eos label')
   parser.add_option('--monoV'   ,action='store_true',     dest='monov',default=False,help='Run mono V generation') # need a few more options for monoV
   parser.add_option('--bbDM'    ,action='store_true',     dest='bbdm' ,default=False,help='Run bb+DM generation') # need a few more options for monoV
   parser.add_option('--ttDM'    ,action='store_true',     dest='ttdm' ,default=False,help='Run tt+DM generation') # need a few more options for monoV
   parser.add_option('--writeLHE',action='store_true',     dest='lhe'  ,default=False,help='write LHE as well')
   parser.add_option('--hinv'    ,action='store_true',     dest='hinv' ,default=False,help='Higgs Invisible') # need a few more options for monoV
   parser.add_option('--monoJ'   ,action='store_true',     dest='monoJ',default=False,help='Just Monojet') # need a few more options for monoV
   parser.add_option('--mj'      ,action='store',          dest='mj'      ,default='ggH125_signal',help='Monojet Base') # need a few more options for monoV
   parser.add_option('--zh'      ,action='store',          dest='zh'      ,default='ZH125_signal',help='ZH Base') # need a few more options for monoV
   parser.add_option('--wh'      ,action='store',          dest='wh'      ,default='WH125_signal',help='WH Base') # need a few more options for monoV
   (options,args) = parser.parse_args()
   return options

def getGenerator(generator):
   os.system('rm -rf  ' + generator + '; tar fxz generators/' + generator + '.tgz')
   return


def generateMonoJet(mass,med,width,process,gq,gdm,lhe):

   sub_file = open('runpowheg.sh','w')
   sub_file.write('#!/bin/bash\n')
   sub_file.write('scramv1 project CMSSW CMSSW_7_1_19 \n')
   sub_file.write('cd CMSSW_7_1_19/src \n')
   sub_file.write('eval `scramv1 runtime -sh`\n')
   sub_file.write('cd %s \n' % os.getcwd())
   pwg=''

   if process > 799 and process < 805:
      pwg='POWHEG-BOX-V2/DMV'
      sub_file.write('cd POWHEG-BOX-V2/DMV\n')
   if process > 804 and process < 808: 
      pwg='POWHEG-BOX-V2/DMS_tloop'
      sub_file.write('cd POWHEG-BOX-V2/DMS_tloop\n')

   sub_file.write('./run.py --med %d --dm %d --proc %d --g %f \n' %  (med,mass,process,gq))
   sub_file.close()

   print './run.py --med %d --dm %d --proc %d --g %f' % (med,mass,process,gq)

   os.system('chmod +x %s' % os.path.abspath(sub_file.name))
   os.system('%s' % os.path.abspath(sub_file.name))
   os.system('sed "s@1000021@1000022@g"  %s/pwgevents.lhe > test.lhe1' % pwg)
   os.system('sed "s@-1000022@1000022@g" test.lhe1        > test.lhe')
   xs = getPowhegXS(process)
   head = commands.getstatusoutput('cat   test.lhe | grep -in "<init>" | sed "s@:@ @g" | awk \'{print $1+1}\' | tail -1')[1]
   tail = commands.getstatusoutput('wc -l test.lhe | awk -v tmp="%s" \'{print $1-2-tmp}\' ' % head)[1]
   os.system("tail -%s test.lhe                           >  test.lhe_tail" % tail)
   os.system("head -%s test.lhe                           >  test.lhe_F" % head)
   os.system('echo "  %s   %s  1.00000000000E-00 100" >>  test.lhe_F' % (xs[0],xs[1]))
   os.system('echo "</init>"                                           >>  test.lhe_F')
   os.system("cat test.lhe_tail                                        >>  test.lhe_F")
   os.system("mv test.lhe_F test.lhe")
   
   if lhe:
      os.system('mv test.lhe /store/cmst3/group/monojet/mc/lhe/DM_%s_%s_%s_%s_%s_%s.lhe'%(med,mass,width,process,gq,gdm))

   return

def getPowhegXS(process):
   xs=[-1,-1]
   pwg='POWHEG-BOX-V2/DMV'
   if process > 804 and process < 808:
      pwg='POWHEG-BOX-V2/DMS_tloop'

   xs[0] = commands.getstatusoutput("cat %s/pwg-stat.dat | grep Total | awk '{print $4}' "% pwg)[1]
   xs[1] = commands.getstatusoutput("cat %s/pwg-stat.dat | grep Total | awk '{print $6}' "% pwg)[1]

   print xs

   return xs

def generateGen(xs,filename,label,monoV,dty="./python"):
   os.system('cp %s/makingBacon_LHE_Gen.py .'%dty)
   if label.find("800") > -1 or label.find("801") > -1:
      os.system('cp %s/LHEProd_NLO.py             .'%dty)
      os.system('cp %s/Hadronizer_TuneCUETP8M1_13TeV_powhegEmissionVeto_1p_LHE_pythia8_cff.py .'%dty)   
   else:
      os.system('cp %s/LHEProd.py         .'%dty)
      os.system('cp %s/Hadronizer_TuneCUETP8M1_13TeV_generic_LHE_pythia8_cff.py .'%dty)   

   #f = open('makingBacon_LHE_Gen.py')
   with open("makingBacon_LHE_Gen_v1.py", "wt") as fout:
    with open("makingBacon_LHE_Gen.py", "rt") as fin:
       for line in fin:
          fout.write(line.replace('!BBB', filename))
   sub_file = open('runpythia.sh','w')
   sub_file.write('#!/bin/bash\n')
   sub_file.write('scramv1 project CMSSW CMSSW_7_1_19 \n')
   sub_file.write('cd CMSSW_7_1_19/src \n')
   sub_file.write('eval `scramv1 runtime -sh`\n')
   sub_file.write('cd %s \n' % os.getcwd())
   if label.find("800") > -1 or label.find("801") > -1:
      sub_file.write('cmsRun LHEProd_NLO.py \n')
   else:
      sub_file.write('cmsRun LHEProd.py \n')
   sub_file.write('cd %s \n'%dty)
   sub_file.write('eval `scramv1 runtime -sh`\n')
   sub_file.write('cd %s \n' % os.getcwd())
   sub_file.write('cmsRun makingBacon_LHE_Gen_v1.py \n')
   #sub_file.write('cp -r %s/../bin/files . \n' % dty)
   sub_file.write('runGen  -1 %s %s 0 \n' % (filename,xs))
   sub_file.write('mv Output.root %s \n' % filename)
   sub_file.write('%s rm       /store/cmst3/group/monojet/mc/%s/%s \n' %(eos,label,filename))
   sub_file.write('cmsStage %s /store/cmst3/group/monojet/mc/%s/%s \n' %(filename,label,filename))
   #sub_file.write('cmsRm       /store/cmst3/user/pharris/mc/%s/%s \n' %(label,filename))
   #sub_file.write('cmsStage %s /store/cmst3/user/pharris/mc/%s/%s \n' %(filename,label,filename))
   sub_file.close()
   os.system('chmod +x %s' % os.path.abspath(sub_file.name))
   os.system('%s' % os.path.abspath(sub_file.name))

def fileExists(filename,label):
   #cmsStage %s /store/cmst3/group/monojet/mc/%s/%s' %(filename,label,filename)
   sc=None
   print '%s ls eos/cms//store/cmst3/group/monojet/mc/%s/%s | wc -l' %(eos,label,filename)
   exists = commands.getoutput('%s ls eos/cms//store/cmst3/group/monojet/mc/%s/%s | wc -l' %(eos,label,filename)  )
   if len(exists.splitlines()) > 1: 
      exists = exists.splitlines()[1]
   else:
      exists = exists.splitlines()[0]
   print exists
   return int(exists) == 1
            
if __name__ == "__main__":
   options = parser()
   print " OPTIONS: %d %d %d %f"%(options.med,options.dm,options.proc,options.gq)

   print ' UNTAR'
   getGenerator('POWHEG-BOX-V2')
   print ' GENERATE'
   generateMonoJet(options.dm,options.med,options.width,options.proc,options.gq,options.gdm,options.lhe)

   xs = getPowhegXS(options.proc)

   filename = 'MonoJ_'+str(int(options.med))+'_'+str(int(options.dm))+'_'+str(options.gq)+'_'+str(int(options.proc))+'.root'
   print ' Filename: ' + filename

   #generateGen(xs[0],filename,options.label,False)
