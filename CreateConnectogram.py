#!/usr/bin/python

import os
import sys
## Run the script in an empty output directory

## Tools
Perl="/home/akaiser/Networking/Circos/ActivePerl-5.16/bin/perl"
ParseTable="/NIRAL/work/akaiser/Networking/Circos/circos-tools-0.16-2/tools/tableviewer/bin/parse-table"
MakeConf="/NIRAL/work/akaiser/Networking/Circos/circos-tools-0.16-2/tools/tableviewer/bin/make-conf"
Circos="/NIRAL/work/akaiser/Networking/Circos/circos-0.63-4/bin/circos"

## Variables
if len(sys.argv) < 3 : # sys.argv[1] = 1st arg -> sys.argv[0] is the name of the script ran # "/home/akaiser/Networking/Circos/TestConnecnoGMFSLNew"
#  OutputDir="."
#  print "> No Output Directory given. The current working directory will be used as output."
  print "Usage:"
  print "python ./CreateConnectogram.py [OutputFolder] [Matrix]"
else:
  OutputDir=sys.argv[1]
  Matrix=sys.argv[2]

#Matrix= OutputDir + "/MatrixNames.txt"
MatrixParsed= OutputDir + "/Matrix-parsed.txt"
MatrixConfFile= OutputDir + "/Matrix.conf"
CellsTxtFile= OutputDir + "/cells.txt"
TempTxtFile= OutputDir + "/TempName.txt"
TempCsvFile= OutputDir + "/TempName.csv"
ColorsConfFile= OutputDir + "/colors.conf"
ColorsTranspConfFile= OutputDir + "/colors-transp.conf"
KaryotypeFile= OutputDir + "/karyotype.txt"
KaryotypeOrderedFile= OutputDir + "/karyotype-ordered.txt"
Image= OutputDir + "/Matrix.png"

## Run "parse-table"
ParseTableCmd = Perl + " " + ParseTable + " -file " + Matrix + " > " + MatrixParsed
print "> Running:",ParseTableCmd
if not os.path.isfile(MatrixParsed) :
  os.system(ParseTableCmd)

## Run "make-conf"
MakeConfCmd="cat " + MatrixParsed + " | " + Perl + " " + MakeConf + " -dir " + OutputDir
print "> Running:",MakeConfCmd
if not os.path.isfile(CellsTxtFile) :
  os.system(MakeConfCmd)

## Modify manually cells.txt: remove "_a1"
print "> Correcting cells.txt file"
if os.path.isfile(TempTxtFile) : os.remove(TempTxtFile) # If for any reason it was already here
NewCellsFile = open(TempTxtFile,"a") #open for Append

for line in open(CellsTxtFile):
  line = line.replace("_a1","")
  NewCellsFile.write(line)
NewCellsFile.close()
os.remove(CellsTxtFile)
os.rename(TempTxtFile,CellsTxtFile)

## create colors-transp.conf by adding ,.2 at the end of all lines in colors.conf
print "> Creating colors-transp.conf file"
if not os.path.isfile(ColorsTranspConfFile) :
  NewColorsFile = open(ColorsTranspConfFile,"a") #open for Append

  for line in open(ColorsConfFile):
    line = line.replace("\n",",.2\n")
    NewColorsFile.write(line)
  NewColorsFile.close()

## modify karyotype.txt so it is in the right number order
print "> Ordering karyotype.txt file"
if not os.path.isfile(KaryotypeOrderedFile) :
  TextTable={}
  it=1
  for line in open(KaryotypeFile):
    line = line.replace("- ","-;").replace("_",";")
    TextTable[it] = line.split(";") # Put line in a table
    it += 1

  def SortByLabelId(lineIndex1, lineIndex2):
    if int(TextTable[lineIndex1][1]) > int(TextTable[lineIndex2][1]) :
      return 1
    else :
      return -1

  SortedTableIndex=sorted(TextTable,cmp = SortByLabelId) # returns a table of the sorted indexes from textTable # sort by SortByLabelId fct

  NewKaryotypeFile = open(KaryotypeOrderedFile,"a") # open for Append
  for line in TextTable:
    lineToWrite = ";".join(TextTable[SortedTableIndex[line-1]])         # the ";" is the delimiter
    lineToWrite = lineToWrite.replace("-;","- ").replace(";","_")
    NewKaryotypeFile.write(lineToWrite)
  NewKaryotypeFile.close()

## Configure Matrix.conf with output folder
print "> Configuring Matrix.conf file"
NewMatrixFile = open(TempTxtFile,"a") #open for Append
for line in open(MatrixConfFile):
  line = line.replace("${OutputFolder}",OutputDir)
  NewMatrixFile.write(line)
NewMatrixFile.close()
os.remove(MatrixConfFile)
os.rename(TempTxtFile,MatrixConfFile)

## Run Circos
CircosCmd = Perl + " " + Circos + " -conf " + MatrixConfFile
print "> Running:",CircosCmd
if not os.path.isfile(Image) :
  os.system(CircosCmd)

