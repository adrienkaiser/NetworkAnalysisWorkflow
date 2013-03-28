#!/bin/bash

echo "###########################"
echo "## 6     Circos          ##"
echo "###########################"

# Cmd line args
OutputFolder=$1
ScriptFolder=$2
PythonCmd=$3

CircosFolder=$OutputFolder/6_Circos

###########################
##   Create Directories  ##
###########################
if [ ! -d $CircosFolder ]; then
  echo "6> mkdir: $CircosFolder"
  mkdir $CircosFolder
fi

###########################
##   Run python script   ##
###########################

for method in Cost FSL FA
do
  if [ ! -d $CircosFolder/$method ]; then
    echo "6> mkdir: $CircosFolder/$method"
    mkdir $CircosFolder/$method
  fi

  echo "6> Run circos script for $method"
  cp $ScriptFolder/Matrix.conf $CircosFolder/$method # will be configured in python script with output folder
  $PythonCmd $ScriptFolder/CreateConnectogram.py $CircosFolder/$method $OutputFolder/4_ComputeMatrices/Matrix$method"Circos.txt" # arg for python script is circos output folder and circos matrix file
  if [ ! $? -eq 0 ] ; then
    echo "6> Last command failed. Abort."
    exit 1
  fi

done

exit 0

