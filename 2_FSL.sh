#!/bin/bash

echo "###########################"
echo "## 2        FSL          ##"
echo "###########################"

# Cmd line args
OutputFolder=$1
BEDPOSTXCmd=$2
PROBTRACKXCmd=$3
DWIConvertCmd=$4
ConvertCmd=$5
unuCmd=$6
ResampleVolume2Cmd=$7
betCmd=$8
DWI=$9

FSLOutDir=$OutputFolder/2_FSL
LabelsFolder=$OutputFolder/1_Freesurfer/subjects/Penelope/Labels

###########################
##   Create Directories  ##
###########################
if [ ! -d $FSLOutDir ]; then
  echo "2> mkdir: $FSLOutDir"
  mkdir $FSLOutDir
fi


###########################
##       BEDPOSTX        ##
###########################

# Setup the folders
BedpostXFolder=$FSLOutDir/BEDPOSTX
echo "2> mkdir: $BedpostXFolder"
if [ -d $BedpostXFolder ]; then
    mkdir $BedpostXFolder
fi

# Prepare bedpostx directory
echo "2> Converting data to FSL format"
$DWIConvertCmd --conversionMode NrrdToFSL --inputVolume $DWI --outputVolume $BedpostXFolder/data.nii.gz --outputBVectors bvecs --outputBValues bvals
$ConvertCmd bvecs $BedpostXFolder/bvecs $BedpostXFolder/bvals # homemade program

echo "2> Getting B0 and converting to nii"
$unuCmd slice -a 3 -p 0 -i $DWI | $unuCmd save -e gzip -f nrrd -o $BedpostXFolder/b0.nrrd
$ResampleVolume2Cmd $BedpostXFolder/b0.nrrd $BedpostXFolder/b0.nii.gz
mv b0.nii.gz $BedpostXFolder/nodif.nii.gz

echo "2> Creating brain mask for B0"
$betCmd $BedpostXFolder/nodif.nii.gz $BedpostXFolder/nodif_brain.nii.gz -m # to extract the brain and create a mask

# Launch BEDPOSTX
# bedpostx_datacheck /home/akaiser/Networking/FSL/BEDPOSTX # to check the directory
echo "2> Launch BEDPOSTX"
$BEDPOSTXCmd $BedpostXFolder -n 2 -w 1  -b 1000 # takes a long time !!

###########################
##      PROBTRACKX       ##
###########################

BEDPOSTXdir=$FSLOutDir/BEDPOSTX/BEDPOSTX.bedpostX/merged
Mask=$FSLOutDir/BEDPOSTX/BEDPOSTX.bedpostX/nodif_brain_mask
OutputDir=$FSLOutDir/PROBTRACKX/Labels

for label in $Labels
do
  LabelImage=$LabelsFolder/$label"_resampled.nii.gz"
  LabelOutputDir=$OutputDir/$label

  echo "2> PROBTRACKX: label $label"
  $PROBTRACKXCmd --mode=seedmask -x $LabelImage -l -c 0.2 -S 2000 --steplength=0.5 -P 5000 --forcedir --opd -s $BEDPOSTXdir -m $Mask --dir=$LabelOutputDir
done

exit 0

