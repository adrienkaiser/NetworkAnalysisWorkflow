#!/bin/bash

echo "###########################"
echo "## 5 Network Properties  ##"
echo "###########################"

# Cmd line args
OutputFolder=$1
ScriptFolder=$2
NetworkAnalysisCmd=$3
MatlabCmd=$4
MatrixFSL=$5
MatrixCOST=$6

NetworkAnalysisFolder=$OutputFolder/5_NetworkProperties
MatrixFSLAnalysis=$NetworkAnalysisFolder/MatrixFSLAnalysis.txt
MatrixCOSTAnalysis=$NetworkAnalysisFolder/MatrixCOSTAnalysis.txt
if [ -e $MatrixFSLAnalysis ]; then
  rm $MatrixFSLAnalysis # if computed previously
fi
if [ -e $MatrixCOSTAnalysis ]; then
  rm $MatrixCOSTAnalysis # if computed previously
fi

###########################
##   Create Directories  ##
###########################
if [ ! -d $NetworkAnalysisFolder ]; then
  echo "5> mkdir: $NetworkAnalysisFolder"
  mkdir $NetworkAnalysisFolder
fi

###########################
##  Compute properties   ##
###########################

#echo "5> Run homemade program to compute network properties"

#$NetworkAnalysisCmd --matrixFile $MatrixFSL --weighted >> $MatrixFSLAnalysis
if [ ! $? -eq 0 ] ; then
  echo "5> Last command failed. Abort."
  exit 1
fi

#$NetworkAnalysisCmd --matrixFile $MatrixCOST --weighted >> $MatrixCOSTAnalysis
if [ ! $? -eq 0 ] ; then
  echo "5> Last command failed. Abort."
  exit 1
fi

echo "5> Run matlab script to compute network properties"
$MatlabCmd -nodisplay -logfile $NetworkAnalysisFolder/ComputeNetPropertiesMatlab.log -r "addpath('$ScriptFolder'); ComputeNetProperties('$OutputFolder')" # < $ScriptFolder/ComputeNetProperties.m
if [ ! $? -eq 0 ] ; then
  echo "5> Last command failed. Abort."
  exit 1
fi

exit 0

