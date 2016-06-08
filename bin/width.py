#!/usr/bin/env python

import sys,os,time
currentdir = os.getcwd()

print "Leptonic=1 or Hadronic=2 ?"
allowed_answers=['1','2']
answer=""
while answer not in allowed_answers:
    answer=raw_input("Answer : ")
if answer=='1':
    leptonic=True
else:
    leptonic=False

njets=1
print "Which model would you like S* ? 1,2,3,4"
allowed_answers=['1','2','3','4']
answer=""
while answer not in allowed_answers:
    answer=raw_input("Answer : ")
    answer=answer.lower()
model = int(answer)

if model==1 or model==2:
    print "Mass of the resonant particle ? "
    good_answer=False
    while not good_answer:
        answer=raw_input("Answer : ")
        try:
            mass_res=float(answer)
        except:
            continue
        if mass_res<=0:
            continue
        good_answer=True

print "Mass of the invisible particle ? "
good_answer=False
while not good_answer:
    answer=raw_input("Answer : ")
    try:
        mass_chi=float(answer)
    except:
        continue
    if mass_chi<=0:
        continue
    good_answer=True

if model==1 or model==2:
    mass_res_word=str(mass_res)
    mass_res_word=mass_res_word.replace('.','p')

mass_chi_word=str(mass_chi)
mass_chi_word=mass_chi_word.replace('.','p')

if model==1 or model==2:
    print "Phase space possible ? "
    if (mass_chi+172)>mass_res:
        print "Sorry: phase space impossible"
        sys.exit()
    else:
        print "OK"

if model==1 or model==2:
    workdir = "prod_S"+str(model)+"_mres"+mass_res_word+"_mchi"+mass_chi_word
else:
    workdir = "prod_S"+str(model)+"_mchi"+mass_chi_word

dir_scenario = "Prod_S"+str(model)+'/'

print "Creating folder "+currentdir+'/'+dir_scenario+workdir+" ..."     
if os.path.isdir(currentdir+'/'+dir_scenario+workdir):
    os.system("rm -rf "+currentdir+'/'+dir_scenario+workdir)
os.system("mkdir -p "+currentdir+'/'+dir_scenario+workdir)

print "Copying run_card.dat ..."
os.system('cp '+currentdir+'/run_card.dat '+currentdir+'/'+dir_scenario+workdir+'/')

print "Creating different run_card.dat with a different seed ..."
for njet in range(0,njets):

    timestamp = 999999999
    while timestamp > (30081*30081):
        print "seed failed : "+str(timestamp)+" . Test new one"
        timestamp = int(round(time.time(),0))
        print "timestamp ="+ str(timestamp)
        timestamp_word = str(timestamp)
        timestamp_word = timestamp_word[-9:]
        timestamp = int(timestamp_word)
    print " --> seed = "+timestamp_word
    
    input = open(currentdir+'/run_card.dat','r')
    output = open(currentdir+'/'+dir_scenario+workdir+'/run_card_'+str(njet)+'.dat','w')
    for line in input:
        line2=line.rstrip()
        line2=line2.lstrip()
        words = line2.split()
        if len(words)>=3:
#            if words[1].lower()=='block' and words[2].lower()=='iseed':
            if 'iseed' in line:
                output.write(timestamp_word+' = iseed\n')
            else:
                output.write(line)
        else:
            output.write(line)
    input.close()
    output.close()

print "Copying and adapting param_card.dat ..."
input = open('param_card.dat','r')
output = open(currentdir+'/'+dir_scenario+workdir+'/param_card.dat','w')
massblock=False
for line in input:
    line2=line.rstrip()
    line2=line2.lstrip()
    words = line2.split()
    if len(words)>1:
        if words[0].lower()=='block' and words[1].lower()=='mass':
            massblock=True
        elif words[0].lower()=='block' or words[0].lower()=='decay':
            massblock=False
            
    if len(words)>1 and massblock and model==1:
        if words[0].lower()=='9000004':
            output.write('  9000004 %E'%mass_res+' # MSC -CHANGED-\n')
        elif words[0].lower()=='9000003':
            output.write('  9000003 %E'%mass_chi+' # MFM -CHANGED-\n')
        else:
            output.write(line)
    elif len(words)>1 and massblock and model==2:
        if words[0].lower()=='9000005':
            output.write('  9000005 %E'%mass_res+' # MVC -CHANGED-\n')
        elif words[0].lower()=='9000003':
            output.write('  9000003 %E'%mass_chi+' # MFM -CHANGED-\n')
        else:
            output.write(line)
    elif len(words)>1 and massblock and model==3:
        if words[0].lower()=='9000001':
            output.write('  9000001 %E'%mass_chi+' # MFM -CHANGED-\n')
        else:
            output.write(line)
    elif len(words)>1 and massblock and model==4:
        if words[0].lower()=='9000002':
            output.write('  9000002 %E'%mass_chi+' # MFM -CHANGED-\n')
        else:
            output.write(line)
    else:
        output.write(line)

input.close()
output.close()


print "Writing mg5 scripts ..."

if model==1 or model==2:
    mg5 = open(currentdir+'/'+dir_scenario+workdir+'/script_decay.mg5','w')
    mg5.write('import model MonoTops_UFO -modelname\n')
    mg5.write('define tt = t t~\n')
    if model==1:
        mg5.write('generate phic > tt fmet MT1=0 MT2=0 MT3=2 MT4=0\n')
    elif model==2:
        mg5.write('generate vc > tt fmet MT1=0 MT2=0 MT3=0 MT4=2\n')
    mg5.write('output '+currentdir+'/'+dir_scenario+workdir+'/decay\n')
    mg5.write('!cp '+currentdir+'/'+dir_scenario+workdir+'/run_card_0.dat '+currentdir+'/'+dir_scenario+workdir+'/decay/Cards/run_card.dat\n')
    mg5.write('!cp '+currentdir+'/'+dir_scenario+workdir+'/param_card.dat '+currentdir+'/'+dir_scenario+workdir+'/decay/Cards\n')
    mg5.write('launch\n')
    mg5.close()

for njet in range(0,njets):
    mg5 = open(currentdir+'/'+dir_scenario+workdir+'/script_prod_'+str(njet)+'j.mg5','w')
    mg5.write('import model MonoTops_UFO -modelname\n')
    mg5.write('define WW = W+ W-\n')
    mg5.write('define tt = t t~\n')
    mg5.write('define bb = b b~\n')
    mg5.write('define ll = e+ e- mu+ mu- ta+ ta-\n')
    mg5.write('define vv = ve vm vt ve~ vm~ vt~\n')
    mg5.write('define j = g u u~ d d~ c c~ s s~ b b~\n')
    njet_word=""
    for muf in range(0,njet):
        njet_word += 'j '
    if model==1 and leptonic:
        mg5.write('generate p p > tt fmet '+njet_word+' MT1=0 MT2=0 MT3=2 MT4=0, (tt > bb WW, WW > vv ll)\n')
    elif model==2 and leptonic:
        mg5.write('generate p p > tt fmet '+njet_word+' MT1=0 MT2=0 MT3=0 MT4=2, (tt > bb WW, WW > vv ll)\n')
    elif model==3 and leptonic:
        mg5.write('generate p p > tt smet '+njet_word+' MT1=2 MT2=0 MT3=0 MT4=0, (tt > bb WW, WW > vv ll)\n')
    elif model==4 and leptonic:
        mg5.write('generate p p > tt vmet '+njet_word+' MT1=0 MT2=2 MT3=0 MT4=0, (tt > bb WW, WW > vv ll)\n')
    elif model==1 and not leptonic:
        mg5.write('generate p p > tt fmet '+njet_word+' MT1=0 MT2=0 MT3=2 MT4=0, (tt > bb WW, WW > j j)\n')
    elif model==2 and not leptonic:
        mg5.write('generate p p > tt fmet '+njet_word+' MT1=0 MT2=0 MT3=0 MT4=2, (tt > bb WW, WW > j j)\n')
    elif model==3 and not leptonic:
        mg5.write('generate p p > tt smet '+njet_word+' MT1=2 MT2=0 MT3=0 MT4=0, (tt > bb WW, WW > j j)\n')
    elif model==4 and not leptonic:
        mg5.write('generate p p > tt vmet '+njet_word+' MT1=0 MT2=2 MT3=0 MT4=0, (tt > bb WW, WW > j j)\n')
    mg5.write('output '+currentdir+'/'+dir_scenario+workdir+'/prod_'+str(njet)+'j\n')
    mg5.write('!cp '+currentdir+'/'+dir_scenario+workdir+'/run_card_'+str(njet)+'.dat '+currentdir+'/'+dir_scenario+workdir+'/prod_'+str(njet)+'j/Cards/run_card.dat\n')
    mg5.write('!cp '+currentdir+'/'+dir_scenario+workdir+'/param_card.dat '+currentdir+'/'+dir_scenario+workdir+'/prod_'+str(njet)+'j/Cards\n')
#    mg5.write('!cp '+currentdir+'/'+workdir+'/pythia_card.dat '+currentdir+'/'+workdir+'/prod_'+str(njet)+'j/Cards\n')
    mg5.write('launch\n')
    mg5.close()

if model==1 or model==2:
    print " #### Computing width for resonant state ..."
    os.system(currentdir+'/MG5_aMC_v2_3_3/bin/mg5_aMC '+currentdir+'/'+dir_scenario+workdir+'/script_decay.mg5')
    print " #### Retrieving width value ...."
    res_width=0
    input = open(currentdir+'/'+dir_scenario+workdir+'/decay/Events/run_01/param_card.dat','r')
    for line in input:
        line2=line.rstrip()
        line2=line2.lstrip()
        words = line2.split()
        if len(words)>=3:
            if words[0].lower()=='decay' and words[1].lower()=='9000004' and model==1:
                res_width=float(words[2])
            elif words[0].lower()=='decay' and words[1].lower()=='9000005' and model==2:
                res_width=float(words[2])                
    input.close()
    print "--> value="+str(res_width)+" GeV"
    if res_width<=0:
        print "Possible ERROR"

    print " #### Updating the param_card.dat ..."
    os.system('cp '+currentdir+'/'+dir_scenario+workdir+'/param_card.dat '+currentdir+'/'+dir_scenario+workdir+'/param_card.save')
    input = open(currentdir+'/'+dir_scenario+workdir+'/param_card.save','r')
    output = open(currentdir+'/'+dir_scenario+workdir+'/param_card.dat','w')
    for line in input:
        line2=line.rstrip()
        line2=line2.lstrip()
        words = line2.split()
        if len(words)>=3:
            if words[0].lower()=='decay' and words[1].lower()=='9000004' and model==1:
                output.write('DECAY 9000004 %E'%res_width+' # WSC -CHANGED-\n')
            elif words[0].lower()=='decay' and words[1].lower()=='9000005' and model==2:
                output.write('DECAY 9000005 %E'%res_width+' # WVC -CHANGED-\n')
                
            else:
                output.write(line)
        else:
            output.write(line)
    input.close()
    output.close()

for njet in range(0,njets):
    print " #### Producing events with "+str(njet)+" additionnal jet ..."
    os.system(currentdir+'/MG5_aMC_v2_3_3/bin/mg5_aMC '+currentdir+'/'+dir_scenario+workdir+'/script_prod_'+str(njet)+'j.mg5')
    os.system('gunzip '+currentdir+'/'+dir_scenario+workdir+'/prod_'+str(njet)+'j/Events/run_01/unweighted_events.lhe.gz')
    os.system('mv '+currentdir+'/'+dir_scenario+workdir+'/prod_'+str(njet)+'j/Events/run_01/unweighted_events.lhe '+currentdir+'/'+dir_scenario+workdir+'/prod_'+str(njet)+'.lhe')

#final rename
os.system('mv '+currentdir+'/'+dir_scenario+workdir+'/prod_0.lhe '+currentdir+'/'+dir_scenario+workdir+'/'+workdir+'.lhe')
