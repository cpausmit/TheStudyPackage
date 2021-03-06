#!/bin/bash

TARBALL="$1"

tar fzt $TARBALL 1> /dev/null 2> /dev/null
rc=$?

echo "RC: $rc"

if [ "$rc" != "0" ]
then
  echo "rm $TARBALL"
fi

rm WJetsToLNu_HT-2500ToInf_TuneCUETP8M1_13TeV-madgraphMLM-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WJetsToLNu_HT-400To600_TuneCUETP8M1_13TeV-madgraphMLM-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v2+AODSIM/default.tgz
rm WJetsToLNu_HT-800To1200_TuneCUETP8M1_13TeV-madgraphMLM-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3_ext1-v1+AODSIM/default.tgz
rm WJetsToLNu_HT-800To1200_TuneCUETP8M1_13TeV-madgraphMLM-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WJetsToLNu_TuneCUETP8M1_13TeV-amcatnloFXFX-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WpWpJJ_EWK-QCD_TuneCUETP8M1_13TeV-madgraph-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WpWpJJ_QCD_TuneCUETP8M1_13TeV-madgraph-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WWG_TuneCUETP8M1_13TeV-amcatnlo-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3_ext1-v1+AODSIM/default.tgz
rm WWTo2L2Nu_13TeV-powheg-CUETP8M1Down+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WWTo2L2Nu_13TeV-powheg-herwigpp+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WWTo2L2Nu_13TeV-powheg+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WWToLNuQQ_13TeV-powheg+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3_ext1-v1+AODSIM/default.tgz
rm WWToLNuQQ_13TeV-powheg+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WWW_4F_TuneCUETP8M1_13TeV-amcatnlo-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WWZ_TuneCUETP8M1_13TeV-amcatnlo-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WZTo1L1Nu2Q_13TeV_amcatnloFXFX_madspin_pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WZTo1L3Nu_13TeV_amcatnloFXFX_madspin_pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WZTo2L2Q_13TeV_amcatnloFXFX_madspin_pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
rm WZZ_TuneCUETP8M1_13TeV-amcatnlo-pythia8+RunIISpring16DR80-PUSpring16_80X_mcRun2_asymptotic_2016_v3-v1+AODSIM/default.tgz
