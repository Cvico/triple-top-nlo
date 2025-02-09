if [[ ! -d CMSSW_12_4_11_patch3 ]]; then cmsrel CMSSW_12_4_11_patch3; fi
cd CMSSW_12_4_11_patch3
cmsenv
cd -

# Export libraries
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cvmfs/cms.cern.ch/slc7_amd64_gcc12/external/lhapdf/6.4.0-fccef38e2654e6e08a1bb6a483817484/lib

