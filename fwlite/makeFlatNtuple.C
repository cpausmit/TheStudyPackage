// Global Variables
TFile   *output = 0, *input = 0;

TTree   *cpTree = 0;
Float_t evtWeight,mc1Weight,mc2Weight;

void bookTree(TString outputFile = "../flattree.root")
{
  // create a tree (with branches) and file

  output = new TFile(outputFile.Data(),"recreate");

  cpTree = new TTree("Events","flat tree for extrapolating efficicenies and systematics studies");
  cpTree->Branch("evtWeight",&evtWeight,"evtWeight/F");
  cpTree->Branch("mc1Weight",&mc1Weight,"mc1Weight/F");
  cpTree->Branch("mc2Weight",&mc2Weight,"mc2Weight/F");
}

void fillTree()
{
  // fill the tree with given event

  std::cout << " Fill TTree." << std::endl;
  output->cd();
  cpTree->Fill();
  input->cd();
}

void writeTree()
{
  // write the tree to the file

  std::cout << " Write TTree." << std::endl;
  output->cd();
  cpTree->Write();    int i = 0;

  input->cd();
}

void makeFlatNtuple(TString inputFile = "../monojet_med-500_dm-10_proc-805_g-1.0_nev-1000.root")
{
  using namespace reco;

  bookTree();

  input = new TFile(inputFile);
  std::cout << " Open existing TTree." << std::endl;
  gDirectory->pwd();

  if (input) {
    fwlite::Event ev(input);
    
    std::cout << "----------- Accessing by event ----------------" << std::endl;
      
    // get run and luminosity blocks from events as well as associated 
    // products. (This works for both ChainEvent and MultiChainEvent.)
    for (ev.toBegin(); !ev.atEnd(); ++ev) {

      // Reset for each event
      std::cout << " Run ID " << ev.getRun().id()<< std::endl;
      

      // The content of the flat tree is so far complete bogus, it is just a proof of concept


      // Handle to the GenJets collection (we use ak4)
      edm::Handle<std::vector<GenJet> > jets;
      ev.getByLabel(std::string("ak4GenJets"), jets);
      // loop through GenJet collection and fill ntuple
      bool first = true;
      for (std::vector<GenJet>::const_iterator jet=jets->begin(); jet!=jets->end(); ++jet){
	std::cout << " JET pt " << jet->pt() << std::endl;
	if (first) {
	  evtWeight = jet->pt();
	  mc1Weight = jet->pt()*2.;
	  mc2Weight = jet->pt()/0.05;
	  first = false;
	}
      }

      // Fill tree with this event
      fillTree();

    }
  }

  // finally write the tree into the file
  writeTree();

  std::cout << "----------- Completed ----------------" << std::endl;

  // cosing the input and outut files
  output->Close();
  input->Close();
}
