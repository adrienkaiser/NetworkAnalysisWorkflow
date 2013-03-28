#!/bin/bash

################################################################
################################################################
##   Script to generate the NIRAL Network Analysis Workflow   ##
##                                                            ##
##          Adrien Kaiser, NIRAL, UNC Chapel Hill             ##
##              (akaiser [at] unc [dot] edu)                  ##
##            Last modification: March 18, 2013               ##
##                                                            ##
## ## Usage:                                                  ##
## Please use: ./0_MainScript.sh [steps]                      ##
## Example to run steps 1 and 3: ./0_MainScript.sh 1 3        ##
## 1: Freesurfer                                              ##
## 2: FSL                                                     ##
## 3: COST                                                    ##
## 4: Compute Matrices                                        ##
## 5: Network Properties                                      ##
## 6: Circos                                                  ##
##                                                            ##
## ## Please set the variables before running the script      ##
##                                                            ##
## ## If not executable:                                      ##
## chmod u+x [script]                                         ##
##                                                            ##
## ## If using the cluster:                                   ##
## module rm gcc python                                       ##
## module add python gcc                                      ##
##                                                            ##
################################################################
################################################################

###########################
##   Variables to Set    ##
###########################
## Original Data
DataFolder=/NIRAL/work/akaiser/Networking/from_Utah/Data
DWI=$DataFolder/b1000.nhdr
FA=$DataFolder/b1000_fa.nrrd
T1=$DataFolder/phantom_penelope_t1.nrrd

## Options
OutputFolder=/NIRAL/work/akaiser/Networking/TestFullPenelope # This folder will be created if it does not exist
#KDbsubCommand="" # !! if given as arg and empty !! # "bsub -M 10"  # -M = memory limit (GB) : needs to be increased because the process takes a lot of memory when a lot of samples ( > 50 ) : max = 10GB for 100 samples (default = 4GB)
COSTNbOfSamplesOnHemi=66 # 6 18 38 66 102 146 198 258 # 20 23 26 29 32 35 38 41 44 47 50 53 56 59 62 65 68 71 74 77 80 83 86 89 92 95 98 101 104 107 110 113 116 119 122 125 # {20..125..3}

## External Tools
# 1
FreeSurferHome=/NIRAL/devel/linux/freesurfer_v5.1
ReconAllCmd=$FreeSurferHome/bin/recon-all
SetupFreeSurferScript=$FreeSurferHome/SetUpFreeSurfer
mriconvertCmd=$FreeSurferHome/bin/mri_convert
ResampleVolume2Cmd=/tools/bin_linux64/ResampleVolume2
BRAINSFitCmd=/tools/Slicer3/Slicer3-3.6.3-2011-03-04-linux-x86_64/lib/Slicer3/Plugins/BRAINSFit
ImageMathCmd=/tools/bin_linux64/ImageMath
# 2
FSLHome=/NIRAL/tools/FSL/fsl
BEDPOSTXCmd=$FSLHome/bin/bedpostx
PROBTRACKXCmd=$FSLHome/bin/probtrackx
betCmd=$FSLHome/bin/bet
DWIConvertCmd=/tools/bin_linux64/DWIConvert
ConvertCmd=/NIRAL/work/akaiser/Networking/FSL/Convert
unuCmd=/tools/Slicer4/Slicer-4.2.0-linux-amd64/bin/unu
# 3
ODFEstimationCmd=/NIRAL/work/oguz/connectivity/HardiRsh-build/lib/Slicer3/Plugins/DiffusionODFEstimation
COSTCmd=/NIRAL/work/akaiser/Networking/COST/COST-newfinsler-build/COST
# 4
GetMatrixCmd=/NIRAL/work/akaiser/Projects/NetworkAnalysis_09-19-12/GetMatrix-build/GetMatrix
# 5
NetworkAnalysisCmd=/NIRAL/work/akaiser/Projects/NetworkAnalysis_09-19-12/bin/NetworkAnalysis
MatlabCmd=/tools/Matlab2011a/bin/matlab
# 6
PythonCmd=/usr/bin/python

###########################
##    Other Variables    ##
###########################
ScriptFolder=$(dirname $0) # $0 is the command ran -> get the path (dirname cmd only on unix)
if [ $ScriptFolder == "" ] ; then
  ScriptFolder=.
fi

# Matrices
MatrixFSL=$OutputFolder/4_ComputeMatrices/MatrixFSL.txt
MatrixCOST=$OutputFolder/4_ComputeMatrices/MatrixCOST.txt

# Labels
#Labels="8 10 11 12 13 17 18 26 28 47 49 50 51 52 53 54 58 60 1001 1002 1003 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 2001 2002 2003 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035"
Labels="5,7,8,10,11,12,13,16,17,18,24,26,28,30,31,44,46,47,49,50,51,52,53,54,58,60,62,63,72,77,80,85,251,252,253,254,255,1000,1001,1002,1003,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024,1025,1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,2000,2001,2002,2003,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030,2031,2032,2033,2034,2035"
# Removed in matlab script: 5, 7, 16, 24, 30, 31, 44, 46, 62, 63, 72, 77, 80, 85, 251, 252, 253, 254, 255, 1000, 2000

###########################
##    Cmd Line Parsing   ##
###########################
nbArgs=$# #returns nb of cmd line args (WITHOUT the command ran (==$0))

if [ "$nbArgs" -eq 0 ] ; then
  echo "No steps given. Please use: ./0_MainScript.sh [steps]"
  echo "Example to run steps 1 and 3: ./0_MainScript.sh 1 3"
  echo "1: Freesurfer"
  echo "2: FSL"
  echo "3: COST"
  echo "4: Compute Matrices"
  echo "5: Network Properties"
  echo "6: Circos"

  exit 0
fi

Run1=false
Run2=false
Run3=false
Run4=false
Run5=false
Run6=false
for (( argIndex=1; argIndex<=nbArgs; argIndex++ ))
do
  case "${!argIndex}" in        # the ! is important to get the cmd line arg and not the content of variable "argIndex"
  1) Run1=true
     ;;
  2) Run2=true
     ;;
  3) Run3=true
     ;;
  4) Run4=true
     ;;
  5) Run5=true
     ;;
  6) Run6=true
     ;;
  esac
done

###########################
##   Create Directories  ##
###########################
if [ ! -d $OutputFolder ]; then
  # Test if parent of output folder is writable
  if [ ! -w $(dirname $OutputFolder) ]; then
    echo "0> Output folder parent is not writable. Abort."
    exit 1
  fi

  echo "0> mkdir: $OutputFolder"
  mkdir $OutputFolder

else # Given folder exists: Test if writable
  if [ ! -w $OutputFolder ]; then
    echo "0> Output folder is not writable. Abort"
    exit 1
  fi

fi

###########################
## 1     Freesurfer      ##
###########################
# Segmentation + Parcellation
if $Run1 ; then
  $ScriptFolder/1_FreeSurfer.sh $OutputFolder $ReconAllCmd $SetupFreeSurferScript $ResampleVolume2Cmd $mriconvertCmd $BRAINSFitCmd $ImageMathCmd $FA $T1
  if [ ! $? -eq 0 ] ; then
    echo "0> Freesurfer script (1) failed. Abort."
    exit 1
  fi

  echo "0> Step 1: Freesurfer: DONE"
  echo "0> The script will now exit so you can check the output, and then run next steps (2 -> 6)"
  exit 0
fi

###########################
## 2        FSL          ##
###########################
# Compute connectivity
if $Run2 ; then
  $ScriptFolder/2_FSL.sh $OutputFolder $BEDPOSTXCmd $PROBTRACKXCmd $DWIConvertCmd $ConvertCmd $unuCmd $ResampleVolume2Cmd $betCmd $DWI
  if [ ! $? -eq 0 ] ; then
    echo "0> FSL script (2) failed. Abort."
    exit 1
  fi
fi

###########################
## 3       COST          ##
###########################
# Compute cost
if $Run3 ; then
  $ScriptFolder/3_COST.sh $OutputFolder $ODFEstimationCmd $COSTCmd $COSTNbOfSamplesOnHemi $DWI $FA $Labels
  if [ ! $? -eq 0 ] ; then
    echo "0> COST script (3) failed. Abort."
    exit 1
  fi
fi

###########################
## 4  Compute Matrices   ##
###########################
if $Run4 ; then
  $ScriptFolder/4_ComputeMatrices.sh $OutputFolder $ScriptFolder $GetMatrixCmd $MatlabCmd $MatrixFSL $MatrixCOST $Labels
  if [ ! $? -eq 0 ] ; then
    echo "0> Compute Matrices script (4) failed. Abort."
    exit 1
  fi
fi

###########################
## 5 Network Properties  ##
###########################
if $Run5 ; then
  $ScriptFolder/5_NetworkProperties.sh $OutputFolder $ScriptFolder $NetworkAnalysisCmd $MatlabCmd $MatrixFSL $MatrixCOST
  if [ ! $? -eq 0 ] ; then
    echo "0> Network Properties script (5) failed. Abort."
    exit 1
  fi
fi

###########################
## 6     Circos          ##
###########################
if $Run6 ; then
  $ScriptFolder/6_Circos.sh $OutputFolder $ScriptFolder $PythonCmd
  if [ ! $? -eq 0 ] ; then
    echo "0> Circos script (6) failed. Abort."
    exit 1
  fi
fi

echo ""
echo "0> End of Workflow"
echo "0> Matrix computed with FSL:  $MatrixFSL"
echo "0> Matrix computed with Cost: $MatrixCOST"

exit 0

