#!/usr/bin/bash

# need to specify python3.8 for CS8, while CS9 has python3.9 as default already
PYTHON=python3
OUTDIR=gen_tttwp
#exec >> ${OUTDIR}.log  2>&1
MG="$PYTHON $PWD/MG5_aMC_v3_4_2/bin/mg5_aMC"

### get model
MODEL=loop_qcd_qed_sm                   # should automatically use 5FS


### get patch
PATCH="--- ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_5.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_5.f    2023-02-21 18:06:27.000000001 +0100
@@ -486,7 +486,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_2(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7
--- ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_gbx_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
@@ -558,7 +558,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_2(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7
--- ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_2.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_2.f    2023-02-21 18:06:27.000000001 +0100
@@ -558,7 +558,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_2(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7
--- ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
+++ ${OUTDIR}/SubProcesses/P0_bxg_ttxtxwp/matrix_6.f    2023-02-21 18:06:27.000000001 +0100
@@ -486,7 +486,8 @@
       CALL FFV1_0(W(1,16),W(1,7),W(1,9),GC_11,AMP(4))
 C     Amplitude(s) for diagram number 5
       CALL FFV1_0(W(1,14),W(1,12),W(1,9),GC_11,AMP(5))
-      CALL FFV2_1(W(1,7),W(1,6),GC_124,DCMPLX(CMASS_MDL_MT),W(1,16))
+      CALL FFV2_2(W(1,7),W(1,6),1.0D-05*GC_124,DCMPLX(173.3,-0.6836),
+     $   W(1,16))
 C     Amplitude(s) for diagram number 6
       CALL FFV1_0(W(1,5),W(1,16),W(1,15),GC_11,AMP(6))
 C     Amplitude(s) for diagram number 7"


for FIXEDSCALE in False True ; do
      for ORDER in NLO LO ; do
            ### generate and apply patch
            echo "set auto_convert_model T          # convert model to python3 automatically
            import model ${MODEL}
            set complex_mass_scheme True            # not actually needed if resonance width hardcoded
            generate p p > t t~ t~ W+ [QCD]
            output ${OUTDIR}
            y# just in case some installation or overwritting is needed
            " > ${OUTDIR}.cmd
            if [[ ! -d "${OUTDIR}" ]] ; then
                  date
                  echo "--- Generate, output and patch"
                  time $MG -f ${OUTDIR}.cmd
                  time patch -p0 <<< "$PATCH"
            fi


            ### launch
            date
            echo "launch ${OUTDIR}
            fixed_order=OFF
            shower=OFF
            order=$ORDER
            done
            set aEWM1 1.289300e+02
            set MZ 91.153509740726733
            set MW 80.351812293789408
            set MT 172.5
            # set MB 4.7                             # invalid for 5FS
            set ptj 10.
            # set ptb 0.                             # no b cut options at NLO
            set etaj -1.
            # set etab -1.
            # set drbj 0.                            # 0.7 corresponds to default jet radius at NLO
            set pdlabel lhapdf
            set lhaid 325300 
            set WW 2.084650                          # don't set WW=0 unless it is hardcoded in patch
            set WT   0.  # 1.36728                   # anyway set to zero by MG as final state particle
            set dynamical_scale_choice -1             # -1 and 3 are the same at MG5_aMC but not in MG5_LO
            set fixed_ren_scale $FIXEDSCALE          # those two actually determine fixed vs dyn scale
            set fixed_fac_scale $FIXEDSCALE          # those two actually determine fixed vs dyn scale
            set mur_ref_fixed 91.112                 # 3*mt = 3*173.3 = 519.9 GeV
            set muf_ref_fixed 91.112
            set mur_over_ref 1.0
            set muf_over_ref 1.0
            set rw_rscale 0.5,1.,2.
            set rw_fscale 0.5,1.,2.
            set reweight_scale False                  # reweight on the fly, but max 8 different scales
            set reweight_PDF False
            set store_rwgt_info True                 # needed for scale/pdf reweighting
            # set use_syst True                      # doesn't exist at NLO, the following is enough:
            set systematics_program systematics
            set systematics_arguments ['--pdf=325300,316200,306000@0,322500@0,322700@0,322900@0,323100@0,323300@0,323500@0,323700@0,323900@0,305800,303200@0,292200@0,331300,331600,332100,332300@0,332500@0,332700@0,332900@0,333100@0,333300@0,333500@0,333700@0,14000,14066@0,14067@0,14069@0,14070@0,14100,14200@0,14300@0,27400,27500@0,27550@0,93300,61200,42780,315000@0,315200@0,262000@0,263000@0', '--start-id=1001','--mur=1,2,0.5', '--muf=1,2,0.5','--together=mur,muf', '--dyn=-1']
            0" > ${OUTDIR}.cmd
            $MG -f ${OUTDIR}.cmd
            date

      done
done

### results should be the following:
## NLO, HT/2
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 5.203e-04 +- 1.5e-06 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 3 (envelope of 9 values): 
#              5.219e-04 pb  +15.4% -14.6%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              5.223e-04 pb  +10.2% -10.2%
#   --------------------------------------------------------------
## LO, HT/2
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 2.913e-04 +- 6.0e-07 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 3 (envelope of 9 values): 
#              2.913e-04 pb  +33.1% -24.1%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              2.915e-04 pb  +7.6% -7.6%
#   --------------------------------------------------------------
## NLO, 3mt+mw
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 5.232e-04 +- 1.5e-06 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 0 (envelope of 9 values): 
#              5.081e-04 pb  +17.3% -15.5%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              5.086e-04 pb  +7.9% -7.9%
#   --------------------------------------------------------------
## LO, 3mt+mw
#   --------------------------------------------------------------
#      Summary:
#      Process p p > t t~ t~ W+ [QCD]
#      Run at p-p collider (6500.0 + 6500.0 GeV)
#      Number of events generated: 10000
#      Total cross section: 2.724e-04 +- 5.6e-07 pb
#   --------------------------------------------------------------
#      Scale variation (computed from LHE events):
#          Dynamical_scale_choice 0 (envelope of 9 values): 
#              2.725e-04 pb  +33.1% -24.0%
#      PDF variation (computed from LHE events):
#          NNPDF23_nlo_as_0118_qed (101 members; using replicas method): 
#              2.728e-04 pb  +7.7% -7.7%
#   --------------------------------------------------------------

