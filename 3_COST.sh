#!/bin/bash

echo "###########################"
echo "## 3       COST          ##"
echo "###########################"

# Cmd line args
OutputFolder=$1
ODFEstimationCmd=$2
COSTCmd=$3
sample=$4
DWI=$5
FA=$6
Labels=$7

LabelsFolder=$OutputFolder/1_Freesurfer/subjects/Penelope/Labels
WMmask=$OutputFolder/1_Freesurfer/subjects/Penelope/mri/wm_mask_dilated.nrrd
COSTFolder=$OutputFolder/3_Cost

###########################
##   Create Directories  ##
###########################
if [ ! -d $COSTFolder ]; then
  echo "3> mkdir: $COSTFolder"
  mkdir $COSTFolder
fi
if [ ! -d $COSTFolder/Labels ]; then
  echo "3> mkdir: $COSTFolder/Labels"
  mkdir $COSTFolder/Labels
fi

###########################
##     Compute ODF       ##
###########################
ODF=$COSTFolder/odf.nrrd
Baseline=$COSTFolder/odf_Baseline.nrrd
Mask=$COSTFolder/odf_Mask.nrrd

if [ ! -e $ODF ]; then
  echo "3> Computing ODF"
  $ODFEstimationCmd $DWI $ODF $Baseline $Mask
  if [ ! $? -eq 0 ] ; then
    echo "3> Last command failed. Abort."
    exit 1
  fi
fi

###########################
##        Run COST       ##
###########################

IFS="," # IFS is the bash variable for separator
for label in $Labels
do
  OutBase=$COSTFolder/Labels/$label # _cost.nrrd
  Source=$LabelsFolder/$label"_resampled.nrrd"

  # Run COST for each label
  if [ ! -e $OutBase"_cost.nrrd" ]; then
    echo "3> COST: label $label"

    $COSTCmd --numberOfSamplesOnHemisphere $sample --alpha 1 $ODF $FA $OutBase $Source $WMmask

    if [ ! $? -eq 0 ] ; then
      echo "3> Last command failed. Abort."
      exit 1
    fi

  fi
done

##########################
# # Use COST on Killdevil
# !! Run COST once on perso computer to check no fail !!
#
# $ scp fa.nrrd killdevil.unc.edu
# $ scp odf.nrrd killdevil.unc.edu
# $ scp mask.nrrd killdevil.unc.edu
# $ scp -r Labels killdevil.unc.edu
#
# $ ssh killdevil.unc.edu -XC
# $ cp COSTdata/RunCOST.sh COSTNFG
# $ cp COSTdata/RunCOSTLabelsSamplesKD.sh COSTNFG
# $ mkdir /lustre/scr/a/k/akaiser/COSTNFG
# $ gedit COSTNFG/RunCOST.sh COSTNFG/RunCOSTLabelsSamplesKD.sh &
#
# $ bsub -q day -Ip -n 2 -R "span[hosts=1]" /bin/bash
# $ module rm gcc python
# $ module add python gcc
# $ ./COSTNFG/RunCOSTLabelsSamplesKD.sh
#
# $ scp -r killdevil.unc.edu:/lustre/scr/a/k/akaiser/COSTNFG/ ./
###############

exit 0

