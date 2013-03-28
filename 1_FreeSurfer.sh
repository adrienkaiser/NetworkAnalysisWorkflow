#!/bin/bash

echo "###########################"
echo "## 1     Freesurfer      ##"
echo "###########################"

# Cmd line args
OutputFolder=$1
ReconAllCmd=$2
SetupFreeSurferScript=$3
ResampleVolume2Cmd=$4
mriconvertCmd=$5
BRAINSFitCmd=$6
ImageMathCmd=$7
FA=$8
T1=$9

FreesurferFolder=$OutputFolder/1_Freesurfer
subjectID=ConnecSubject

MRIFolder=$FreesurferFolder/MRI
subjectsFolder=$FreesurferFolder/subjects
subjectFolder=$subjectsFolder/$subjectID
MRIsubjectFolder=$MRIFolder/$subjectID

###########################
##   Create Directories  ##
###########################
if [ ! -d $FreesurferFolder ]; then
  echo "1> mkdir: $FreesurferFolder"
  mkdir $FreesurferFolder
fi

###########################
##     Run recon-all     ##
###########################
# Creates all useful folders in the directory, takes from 20-40 hrs

# Setup Freesurfer
#tcsh ???
source $SetupFreeSurferScript
setenv SUBJECTS_DIR $subjectsFolder # does not work -> to do manually
cd $subjectsFolder

# Converting Nrrd to Nii
$ResampleVolume2Cmd $T1 $MRIsubjectFolder/T1.nii

# Launch Reconstruction with Freesurfer
echo "1> Running recon-all"

$ReconAllCmd -s $subjectID -i $MRIsubjectFolder/T1.nii  # Setup folder

$ReconAllCmd -autorecon-all -subjid $subjectID  # Reconstruction => 20->40hrs !!!

###########################
## Register Parcellation ##
###########################
## !!! need to have the Freesurfer reconstruction done before running

echo "1> Converting Parcellation: MGZ -> NII -> NRRD"
$mriconvertCmd $subjectFolder/mri/aparc+aseg.mgz $subjectFolder/mri/aparc+aseg.nii
$ResampleVolume2Cmd $subjectFolder/mri/aparc+aseg.nii $subjectFolder/mri/aparc+aseg.nrrd

echo "1> Converting Brain: MGZ -> NII -> NRRD"
$mriconvertCmd $subjectFolder/mri/brainmask.mgz $subjectFolder/mri/brainmask.nii
$ResampleVolume2Cmd $subjectFolder/mri/brainmask.nii $subjectFolder/mri/brainmask.nrrd

echo "1> Registering T1 to DWI Space"
$BRAINSFitCmd --movingVolume $subjectFolder/mri/brainmask.nrrd --fixedVolume $FA --outputVolume $subjectFolder/mri/brainmask_resampled.nrrd --outputTransform $subjectFolder/mri/T1ToDWI_Rigid+Affine_tfm.txt --transformType Rigid,Affine,BSpline --initializeTransformMode useCenterOfHeadAlign

echo "1> Applying transformations to Parcellation"
$ResampleVolume2Cmd $subjectFolder/mri/aparc+aseg.nrrd $subjectFolder/mri/aparc+aseg_resampled.nrrd --interpolation nn --transformationFile $subjectFolder/mri/T1ToDWI_Rigid+Affine_tfm.txt --Reference $FA
# reference important for spacing, size, orientation, direction.. # !! interp=nn because labels -> no made up values

###########################
##     ExtractLabels     ##
###########################
for n in $Labels
do
  Label=$SubjectFolder/Labels/$n"_resampled.nrrd"
  Nii=$SubjectFolder/Labels/$n"_resampled.nii.gz"

  echo "1> Extracting Label $n"
  $ImageMathCmd $SubjectFolder/mri/aparc+aseg_resampled.nrrd -outfile $Label -extractLabel $n

  echo "1> Converting Label $n to Nifti format"
  $ResampleVolume2Cmd $Label $Nii
done

###########################
##     Create WM mask    ##
###########################
# By removing and adding labels

## Remove WM and CSF from parcellation using WM mask : WM = labels 2 and 41 (to check for different images) + CSF = lateral ventricles(4&43) + 3rd(14) and 4th(15) ventricle
$ImageMathCmd $subjectFolder/Labels/2_resampled.nrrd -outfile $subjectFolder/mri/wm_mask.nrrd -add $subjectFolder/Labels/41_resampled.nrrd # add 2 wm labels (left and right) to create a WM mask
$ImageMathCmd $subjectFolder/mri/wm_mask.nrrd    -outfile $subjectFolder/mri/wmcsf_mask.nrrd -add $subjectFolder/Labels/4_resampled.nrrd # lateral vent.
$ImageMathCmd $subjectFolder/mri/wmcsf_mask.nrrd -outfile $subjectFolder/mri/wmcsf_mask.nrrd -add $subjectFolder/Labels/43_resampled.nrrd # lateral vent.
$ImageMathCmd $subjectFolder/mri/wmcsf_mask.nrrd -outfile $subjectFolder/mri/wmcsf_mask.nrrd -add $subjectFolder/Labels/14_resampled.nrrd # 3th vent.
$ImageMathCmd $subjectFolder/mri/wmcsf_mask.nrrd -outfile $subjectFolder/mri/wmcsf_mask.nrrd -add $subjectFolder/Labels/15_resampled.nrrd # 4th vent.
$ImageMathCmd $subjectFolder/mri/wmcsf_mask.nrrd -outfile $subjectFolder/mri/wmcsf_mask_invert.nrrd -extractLabel 0 # invert mask
$ImageMathCmd $subjectFolder/mri/aparc+aseg_resampled.nrrd -outfile $subjectFolder/mri/aparc+aseg_resampled_noWMnoCSF.nrrd -mul $subjectFolder/mri/wmcsf_mask_invert.nrrd # multiply by mask inverted to remove WM and CSF

## Create WM mask for tractography and COST : Dilate WM + add globus pallidus(13&52), putamen(12&51), caudate(11&50), thalamus(9&10&48&49) + remove CSF (lateral ventricles(4&43), 3rd(14) and 4th(15) ventricles)
# see file $subjectFolder/mri/talairach.label_intensities.txt
# add stuff
$ImageMathCmd $subjectFolder/mri/wm_mask.nrrd         -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/13_resampled.nrrd # add globus pallidus(13&52)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/52_resampled.nrrd # add globus pallidus(13&52)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/12_resampled.nrrd # add putamen(12&51)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/51_resampled.nrrd # add putamen(12&51)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/11_resampled.nrrd # add caudate(11&50)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/50_resampled.nrrd # add caudate(11&50)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/10_resampled.nrrd # add thalamus(10&49)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/49_resampled.nrrd # add thalamus(10&49)

# ventricles added so there is no hole when removed (otherwise -> -1 labels)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/4_resampled.nrrd # remove lateral ventricles(4&43)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/43_resampled.nrrd # remove lateral ventricles(4&43)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/14_resampled.nrrd # remove 3rd ventricle (14)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -add $subjectFolder/Labels/15_resampled.nrrd # remove 4th ventricle (15) # 4th already out

# dilate
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -dilate 1,1

# remove CSF
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -sub $subjectFolder/Labels/4_resampled.nrrd # remove lateral ventricles(4&43)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -sub $subjectFolder/Labels/43_resampled.nrrd # remove lateral ventricles(4&43)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -sub $subjectFolder/Labels/14_resampled.nrrd # remove 3rd ventricle (14)
$ImageMathCmd $subjectFolder/mri/wm_mask_dilated.nrrd -outfile $subjectFolder/mri/wm_mask_dilated.nrrd -sub $subjectFolder/Labels/15_resampled.nrrd # remove 4th ventricle (15) # 4th already removed

exit 0

