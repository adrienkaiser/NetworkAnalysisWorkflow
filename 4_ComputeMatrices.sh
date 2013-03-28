#!/bin/bash

echo "###########################"
echo "## 4  Compute Matrices   ##"
echo "###########################"

# Cmd line args
OutputFolder=$1
ScriptFolder=$2
GetMatrixCmd=$3
MatlabCmd=$4
MatrixFSL=$5
MatrixCOST=$6
Labels=$7

LabelMap=$OutputFolder/1_Freesurfer/subjects/Penelope/mri/aparc+aseg_resampled_noWMnoCSF.nrrd
ComputeMatricesFolder=$OutputFolder/4_ComputeMatrices

###########################
##   Create Directories  ##
###########################
if [ ! -d $ComputeMatricesFolder ]; then
  echo "4> mkdir: $ComputeMatricesFolder"
  mkdir $ComputeMatricesFolder
fi

###########################
##   Create CSV files    ##
###########################
csvFileFSL=$ComputeMatricesFolder/FSLMaps.csv
csvFileCost=$ComputeMatricesFolder/CostMaps.csv
if [ -e $csvFileFSL ]; then
  rm $csvFileFSL # if computed previously
fi
if [ -e $csvFileCost ]; then
  rm $csvFileCost # if computed previously
fi

IFS="," # IFS is the bash variable for separator
for label in $Labels
do
  costMapFSL=$OutputFolder/2_FSL/$label/"fdt_paths.nii.gz"
  echo $costMapFSL >> $csvFileFSL

  costMapCost=$OutputFolder/3_Cost/Labels/$label"_cost.nrrd"
  echo $costMapCost >> $csvFileCost
done

###########################
##   Generate Matrices   ##
###########################
if [ ! -e $MatrixFSL ]; then
  echo "4> Generate FSL Matrix"
  $GetMatrixCmd --connecMapsFile $csvFileFSL --labelMap $LabelMap --matrixFile $MatrixFSL --matrixMetric Mean --connecMapsFileIndex 1 --useRegionBoundary
  if [ ! $? -eq 0 ] ; then
    echo "4> Last command failed. Abort."
    exit 1
  fi
fi

if [ ! -e $MatrixCOST ]; then
  echo "4> Generate Cost Matrix"
  $GetMatrixCmd --connecMapsFile $csvFileCost --labelMap $LabelMap --matrixFile $MatrixCOST --matrixMetric Minimum --connecMapsFileIndex 1 --useRegionBoundary
  if [ ! $? -eq 0 ] ; then
    echo "4> Last command failed. Abort."
    exit 1
  fi
fi

###########################
## Generate Matrix Image ##
###########################
## + create Circos matrix with names
if [ ! -e $ComputeMatricesFolder/MatrixCostCircos.txt ] || [ ! -e $ComputeMatricesFolder/MatrixFSLCircos.txt ] || [ ! -e $ComputeMatricesFolder/MatrixFACircos.txt ]; then
  echo "4> Run matlab script"
  $MatlabCmd -nodisplay -logfile $ComputeMatricesFolder/FormatMatrixMatlab.log -r "addpath('$ScriptFolder'); FormatMatrixMatlab('$OutputFolder')" # < $ScriptFolder/FormatMatrixMatlab.m
  if [ ! $? -eq 0 ] ; then
    echo "4> Last command failed. Abort."
    exit 1
  fi
fi
exit 0

