#!/bin/bash
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [[ ! -d CMSSW_12_4_11_patch3 ]]; then cmsrel CMSSW_12_4_11_patch3; fi
cd CMSSW_12_4_11_patch3
cmsenv
cd -

nevt=${1}
echo "%MSG-MG5 number of events requested = $nevt"

rnum=${2}
echo "%MSG-MG5 random seed used for the run = $rnum"

ncpu=${3}
echo "%MSG-MG5 number of cpus = $ncpu"

LHEWORKDIR=`pwd`
cd $LHEWORKDIR/process

#make sure lhapdf points to local cmssw installation area
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cvmfs/cms.cern.ch/el8_amd64_gcc10/external/lhapdf/6.4.0-68defff11ffd434c73727d03802bfb85/include
LHAPDFCONFIG=`echo "/cvmfs/cms.cern.ch/el8_amd64_gcc10/external/lhapdf/6.4.0-68defff11ffd434c73727d03802bfb85/include"`

# workaround for el8
echo "lhapdf_py3 = $LHAPDFCONFIG" >> ./Cards/amcatnlo_configuration.txt
echo "run_mode = 2" >> ./Cards/amcatnlo_configuration.txt
echo "nb_core = $ncpu" >> ./Cards/amcatnlo_configuration.txt
echo "madspin=OFF" > runscript.dat 
echo "reweight=OFF" >> runscript.dat
echo "done" >> runscript.dat
echo "set nevents $nevt" >> runscript.dat
echo "set iseed $rnum" >> runscript.dat

#set job splitting for worker processes
nevtjob=$[$nevt/$ncpu]
if [ "$nevtjob" -lt "10" ]; then
  nevtjob=10
fi

echo "set nevt_job ${nevtjob}" >> runscript.dat
echo "done" >> runscript.dat

domadspin=0
if [ -f ./Cards/madspin_card.dat ] ;then
  #set random seed for madspin
  rnum2=$(($rnum+1000000))
  echo "$(echo `echo "set seed $rnum2"` | cat - ./Cards/madspin_card.dat)" > ./Cards/madspin_card.dat
  domadspin=1
fi

doreweighting=0
if [ -f ./Cards/reweight_card.dat ]; then
    doreweighting=1
fi

runname=cmsgrid


#generate events

#First check if normal operation with MG5_aMCatNLO events is planned
if [ ! -e $LHEWORKDIR/header_for_madspin.txt ]; then
  
    cat runscript.dat | python3 ./bin/generate_events -ox -n $runname
    runlabel=$runname

    if [ "$doreweighting" -gt "0" ] ; then
        #when REWEIGHT=OFF is applied, mg5_aMC moves reweight_card.dat to .reweight_card.dat
        mv ./Cards/.reweight_card.dat ./Cards/reweight_card.dat
        rwgt_dir="$LHEWORKDIR/process/rwgt"
        export PYTHONPATH=$rwgt_dir:$PYTHONPATH
        echo "0" | ./bin/aMCatNLO --debug reweight $runname
    fi
    gzip -d $LHEWORKDIR/process/Events/${runlabel}/events.lhe 

    if [ "$domadspin" -gt "0" ] ; then
	mv $LHEWORKDIR/process/Events/${runlabel}/events.lhe events.lhe
        # extract header as overwritten by madspin 
	if grep -R "<initrwgt>" events.lhe ; then
	    sed -n '/<initrwgt>/,/<\/initrwgt>/p' events.lhe >  initrwgt.txt
	fi        
        #when MADSPIN=OFF is applied, mg5_aMC moves madspin_card.dat to .madspin_card.dat
        mv ./Cards/.madspin_card.dat ./Cards/madspin_card.dat
        echo "import events.lhe" > madspinrun.dat
        cat ./Cards/madspin_card.dat >> madspinrun.dat
        $LHEWORKDIR/mgbasedir/MadSpin/madspin madspinrun.dat 
        # add header back 
	gzip -d events_decayed.lhe.gz  
	if [ -e initrwgt.txt ]; then
	    sed -i "/<\/header>/ {
             h
             r initrwgt.txt
             g
             N
        }" events_decayed.lhe
	    rm initrwgt.txt
	fi
	runlabel=${runname}_decayed_1
	mkdir -p ./Events/${runlabel}
        
	mv $LHEWORKDIR/process/events_decayed.lhe $LHEWORKDIR/process/Events/${runlabel}/events.lhe
    fi

    pdfsets="325300,316200,306000@0,322500@0,322700@0,322900@0,323100@0,323300@0,323500@0,323700@0,323900@0,305800,303200@0,292200@0,331300,331600,332100,332300@0,332500@0,332700@0,332900@0,333100@0,333300@0,333500@0,333700@0,14000,14066@0,14067@0,14069@0,14070@0,14100,14200@0,14300@0,27400,27500@0,27550@0,93300,61200,42780,315000@0,315200@0,262000@0,263000@0"
    scalevars="--mur=1,2,0.5 --muf=1,2,0.5 --together=muf,mur --dyn=-1"

    echo "systematics $runlabel --start_id=1001 --pdf=$pdfsets $scalevars" | python3 ./bin/aMCatNLO

    cp $LHEWORKDIR/process/Events/${runlabel}/events.lhe $LHEWORKDIR/${runname}_final.lhe

#else handle external tarball
else
    cd $LHEWORKDIR/external_tarball

    ./runcmsgrid.sh $nevtjob $rnum $ncpu

#splice blocks needed for MadSpin into LHE file
    sed -i "/<init>/ {
         h
         r ../header_for_madspin.txt
         g
         N
     }" cmsgrid_final.lhe

#check if lhe file has reweighting blocks - temporarily save those, because MadSpin later overrides the entire header
    if grep -R "<initrwgt>" cmsgrid_final.lhe; then
        sed -n '/<initrwgt>/,/<\/initrwgt>/p' cmsgrid_final.lhe > ../initrwgt.txt
    fi

    mv cmsgrid_final.lhe ../cmsgrid_predecay.lhe
    cd $LHEWORKDIR
    rm -r external_tarball
    echo "import $LHEWORKDIR/cmsgrid_predecay.lhe" > madspinrun.dat
    echo "set ms_dir $LHEWORKDIR/process/madspingrid" >> madspinrun.dat
    echo "launch" >> madspinrun.dat
    $LHEWORKDIR/mgbasedir/MadSpin/madspin madspinrun.dat
    rm madspinrun.dat
    rm cmsgrid_predecay.lhe.gz
    mv cmsgrid_predecay_decayed.lhe.gz cmsgrid_final.lhe.gz
    gzip -d cmsgrid_final.lhe.gz

    if [ -e initrwgt.txt ];then
	sed -i "/<\/header>/ {
             h
             r initrwgt.txt
             g
             N
        }" cmsgrid_final.lhe
        rm initrwgt.txt
    fi
    
fi

cd $LHEWORKDIR
sed -i -e '/<mgrwgt/,/mgrwgt>/d' ${runname}_final.lhe 

# check lhe output  
mv ${LHEWORKDIR}/${runname}_final.lhe ${LHEWORKDIR}/test.lhe 
echo -e "\nRun xml check" 
xmllint --stream --noout ${LHEWORKDIR}/test.lhe ; test $? -eq 0 || exit 1 
echo "Number of weights that are NaN:" 
grep  NaN  ${LHEWORKDIR}/test.lhe | grep "</wgt>" | wc -l ; test $? -eq 0 || exit 1 
echo -e "All checks passed \n" 

# copy output and print directory 
mv ${LHEWORKDIR}/test.lhe ${LHEWORKDIR}/${runname}_final.lhe
ls -l

# exit 
exit 0
