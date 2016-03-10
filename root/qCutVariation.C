const Int_t nQCutValues = 14;
TString qCuts[nQCutValues] = {"20","30","40","50","60","70","80","90","100","110","120","130","140","150"};

void textIt(TString o, double max);
double plotIt(TFile *f, TString n, TString o);

void qCutVariation(TString task = "DMScalar_ttbar01j_mphi_50_mchi_50_gSM_1p0_gDM_1p0_tarball",
		   TString jets = "djr0")
{
  // Looping through all available files of our cut variation study and producing the
  // plots with the cuts.

  Int_t i = 0;

  TCanvas *cv = new TCanvas("CV","CV",1200,1200);
  cv->Divide(3,4);

  //for (Int_t i = 0; i<nQCutValues; i++) {
  for (Int_t i = 0; i<12; i++) {
    TString fileName = task + "-" + qCuts[i] + "-out.root";
    printf("FileName: %s\n",fileName.Data());
    cv->cd(i+1);
    TFile *histos = new TFile(fileName);
    double max = plotIt(histos,"hall_"  +jets,"EHIST");
    plotIt(histos,"hmult0_"+jets,"EHISTSAME");
    plotIt(histos,"hmult1_"+jets,"EHISTSAME");
    plotIt(histos,"hmult2_"+jets,"EHISTSAME");
    plotIt(histos,"hmult3_"+jets,"EHISTSAME");
    plotIt(histos,"hmult4_"+jets,"EHISTSAME");
    textIt(qCuts[i],max);
    histos->Close();
  }
  cv->Print("/tmp/"+task+"_"+jets+".png");
}

double plotIt(TFile *f, TString n, TString o)
{
  TH1D *h = (TH1D*) f->GetObjectUnchecked(n);
  if (h) {
    h->DrawCopy(o);
    return h->GetMaximum();
  }  
  else
    printf(" ERROR histogram %s was empty.\n",n.Data());

  return 0.;
}

void textIt(TString o, double max)
{
  TLatex *t = new TLatex(-0.25,max*1.2,o+" GeV");
  //t->SetNDC(kTRUE);
  t->Draw();
}
