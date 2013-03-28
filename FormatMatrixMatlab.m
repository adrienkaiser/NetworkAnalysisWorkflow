function FormatMatrixMatlab(OutputFolder)

%OutputFolder
ComputeMatricesFolder=[OutputFolder '/4_ComputeMatrices']

%% Load Matrix
Cost66 = load([ComputeMatricesFolder '/MatrixCOST.txt']); % '/home/akaiser/Networking/COST/TestSampleValues/66/MatrixMin.txt'
FSL = load([ComputeMatricesFolder '/MatrixFSL.txt']); % '/NIRAL/work/akaiser/Projects/NetworkAnalysis_09-19-12/FSL_Matrix_NoNorm.txt' % old FSL: FSL_Matrix.txt
FA =  load('/NIRAL/work/akaiser/Projects/NetworkAnalysis_09-19-12/Tracts_Matrix_NoNorm.txt');

%% Remove WM and wrong labels

% For old FSL matrix (FSL_Matrix.txt) : remove lateral, 3rd and 4th ventricles
% for i= [19 10 9 1]
%     FSL(i,:) = [];
%     FSL(:,i) = [];
% end

% 107 labels (in Label Map) -> 86 correct labels 
for i= [73 38 37 36 35 34 33 32 31 30 29 28 27 17 16 15 14 11 8 2 1]
    Cost66(i,:) = [];
    Cost66(:,i) = [];
    FSL(i,:) = [];
    FSL(:,i) = [];
    FA(i,:) = [];
    FA(:,i) = [];
end

NbLabels=length(Cost66) % idem for all methods

%% Threshold & Normalize

% Cost: Threshold + find min/max
thresholdCost=0.15
Cost66Thresholded = Cost66;
minConnecCost=100000000;
maxConnecCost=-1;
for i=1:NbLabels
    for j=1:NbLabels
        if Cost66Thresholded(i,j)>thresholdCost
            Cost66Thresholded(i,j)=0;
        elseif i==j
            Cost66Thresholded(i,j)=0;
        else
            Cost66Thresholded(i,j)=1-Cost66Thresholded(i,j); % cost -> connectivity % 1/(1+exp(Cost66Thresholded(i,j)))
            if Cost66Thresholded(i,j) < minConnecCost
                minConnecCost = Cost66Thresholded(i,j);
            end
            if Cost66Thresholded(i,j) > maxConnecCost
                maxConnecCost = Cost66Thresholded(i,j);
            end
        end
    end
end
% Replace all zeros by the min connectivity in the whole matrix
minConnecCost
minCost=1-minConnecCost % log( (1/minConnecCost) -1 )
maxConnecCost
maxCost=1-maxConnecCost % log( (1/maxConnecCost) -1 )
Cost66Thresholded( Cost66Thresholded==0 ) =minConnecCost;

% FA: find min/max
FAThresholded = FA;
minConnecFA=100000000;
maxConnecFA=-1;
for i=1:NbLabels
    for j=1:NbLabels
        if FAThresholded(i,j) < minConnecFA
            minConnecFA = FAThresholded(i,j);
        end
        if FAThresholded(i,j) > maxConnecFA
            maxConnecFA = FAThresholded(i,j);
        end
    end
end
minConnecFA
maxConnecFA

% Normalize matrix in [0;1]
Cost66ThresholdedNorm= (Cost66Thresholded - minConnecCost)./ (maxConnecCost - minConnecCost);
FSL= FSL ./ max(max(FSL));
FAThresholdedNorm= (FAThresholded - minConnecFA)./ (maxConnecFA - minConnecFA);

%% Display functions for Cost/Connec conversion:
% 1/(1+e^x)
% 1/e^x
% 1/(1+x)
% 1-x

% figure;
% x=0:0.01:0.15; % Cost values between 0 and 0.15 (=threshold)
% Func1=1./(1+exp(x));
% Func2=1./exp(x);
% Func3=1./(1+x);
% Func4=1-x;
% 
% plot(x,Func1,'r',x,Func2,'k',x,Func3,'b',x,Func4,'g');
% title('Red: 1/(1+e^x) | Black: 1/e^x | Blue: 1/(1+x) | Green: 1-x');

%% Display and Write out matrix images
% figure;
% imagesc(Cost66ThresholdedNorm);
% title(['Cost66 thresholded + norm: ' num2str(thresholdCost)]);
% colorbar;
% axis equal;
% 
% xlabel('X (region is target)');
% ylabel('Y (region is source)');

% figure;
% imagesc(FSL);
% title('FSL');
% colorbar;
% axis equal;
% 
% xlabel('X (region is target)');
% ylabel('Y (region is source)');

% figure;
% imagesc(FAThresholdedNorm);
% title('FAThresholdedNorm');
% colorbar;
% axis equal;
% 
% xlabel('X (region is target)');
% ylabel('Y (region is source)');

CostImageFile=[ComputeMatricesFolder '/MatrixCostImage.png'] % '/NIRAL/work/akaiser/Networking/MatrixCostImage.png'
FslImageFile=[ComputeMatricesFolder '/MatrixFSLImage.png'] % '/NIRAL/work/akaiser/Networking/MatrixFSLImage.png'
FAImageFile=[ComputeMatricesFolder '/MatrixFAImage.png'] % '/NIRAL/work/akaiser/Networking/MatrixFAImage.png'
imwrite(round(100*Cost66ThresholdedNorm),jet,CostImageFile,'png'); % jet is the name of the colormap % !! matrices need to be integer
imwrite(round(100*FSL),jet,FslImageFile,'png');
imwrite(round(100*FAThresholdedNorm),jet,FAImageFile,'png');

%% Write out normalized matrices for Circos

% see file '/home/akaiser/Networking/COST/TestSampleValues/MatrixLabelsWithNamesNo7and46.csv'
LabelsIndexes=[8 10 11 12 13 17 18 26 28 47 49 50 51 52 53 54 58 60 1001 1002 1003 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 2001 2002 2003 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035];
LabelsNames={'Left_Cerebellum_Cortex' 'Left_Thalamus_Proper' 'Left_Caudate' 'Left_Putamen' 'Left_Pallidum' 'Left_Hippocampus' 'Left_Amygdala' 'Left_Accumbens_area' 'Left_VentralDC' 'Right_Cerebellum_Cortex' 'Right_Thalamus_Proper' 'Right_Caudate' 'Right_Putamen' 'Right_Pallidum' 'Right_Hippocampus' 'Right_Amygdala' 'Right_Accumbens_area' 'Right_VentralDC' 'bankssts' 'caudalanteriorcingulate' 'caudalmiddlefrontal' 'cuneus' 'entorhinal' 'fusiform' 'inferiorparietal' 'inferiortemporal' 'isthmuscingulate' 'lateraloccipital' 'lateralorbitofrontal' 'lingual' 'medialorbitofrontal' 'middletemporal' 'parahippocampal' 'paracentral' 'parsopercularis' 'parsorbitalis' 'parstriangularis' 'pericalcarine' 'postcentral' 'posteriorcingulate' 'precentral' 'precuneus' 'rostralanteriorcingulate' 'rostralmiddlefrontal' 'superiorfrontal' 'superiorparietal' 'superiortemporal' 'supramarginal' 'frontalpole' 'temporalpole' 'transversetemporal' 'insula' 'bankssts' 'caudalanteriorcingulate' 'caudalmiddlefrontal' 'cuneus' 'entorhinal' 'fusiform' 'inferiorparietal' 'inferiortemporal' 'isthmuscingulate' 'lateraloccipital' 'lateralorbitofrontal' 'lingual' 'medialorbitofrontal' 'middletemporal' 'parahippocampal' 'paracentral' 'parsopercularis' 'parsorbitalis' 'parstriangularis' 'pericalcarine' 'postcentral' 'posteriorcingulate' 'precentral' 'precuneus' 'rostralanteriorcingulate' 'rostralmiddlefrontal' 'superiorfrontal' 'superiorparietal' 'superiortemporal' 'supramarginal' 'frontalpole' 'temporalpole' 'transversetemporal' 'insula'};

OutMatrixCircosFile=[ComputeMatricesFolder '/MatrixCostCircos.txt'] % '/NIRAL/work/akaiser/Networking/Circos/TestConnecnoGM/MatrixNames.txt';
OutMatrixFSLCircosFile=[ComputeMatricesFolder '/MatrixFSLCircos.txt'] % '/NIRAL/work/akaiser/Networking/Circos/TestConnecnoGMFSLNew/MatrixNames.txt';
OutMatrixFACircosFile=[ComputeMatricesFolder '/MatrixFACircos.txt'] % '/NIRAL/work/akaiser/Networking/Circos/TestConnecnoGMFA/MatrixNames.txt';

OutMatrixCircos = fopen(OutMatrixCircosFile,'wt');
OutMatrixFSLCircos = fopen(OutMatrixFSLCircosFile,'wt');
OutMatrixFACircos = fopen(OutMatrixFACircosFile,'wt');

fprintf(OutMatrixCircos,'X');
fprintf(OutMatrixFSLCircos,'X');
fprintf(OutMatrixFACircos,'X');
for i=1:NbLabels
    fprintf(OutMatrixCircos,' %d_%s',LabelsIndexes(i),LabelsNames{i});
    fprintf(OutMatrixFSLCircos,' %d_%s',LabelsIndexes(i),LabelsNames{i});
    fprintf(OutMatrixFACircos,' %d_%s',LabelsIndexes(i),LabelsNames{i});
end
fprintf(OutMatrixCircos,'\n');
fprintf(OutMatrixFSLCircos,'\n');
fprintf(OutMatrixFACircos,'\n');

for i=1:NbLabels
    fprintf(OutMatrixCircos,'%d_%s ',LabelsIndexes(i),LabelsNames{i});
    fprintf(OutMatrixFSLCircos,'%d_%s ',LabelsIndexes(i),LabelsNames{i});
    fprintf(OutMatrixFACircos,'%d_%s ',LabelsIndexes(i),LabelsNames{i});
    for j=1:NbLabels
        fprintf(OutMatrixCircos,'%d ',round(100*Cost66ThresholdedNorm(i,j)));
        fprintf(OutMatrixFSLCircos,'%d ',round(100*FSL(i,j)));
        fprintf(OutMatrixFACircos,'%d ',round(100*FAThresholdedNorm(i,j)));
    end
    fprintf(OutMatrixCircos,'\n');
    fprintf(OutMatrixFSLCircos,'\n');
    fprintf(OutMatrixFACircos,'\n');
end

fclose(OutMatrixCircos);
fclose(OutMatrixFSLCircos);
fclose(OutMatrixFACircos);

%%
exit
