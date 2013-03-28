function ComputeNetProperties(OutputFolder)

OutputFolder

disp('***************** Network Analysis *****************'); % display in console

%% Use functions from the 'Brain Connectivity Toolbox': http://sites.google.com/site/bctnet/ -> doc about measures
addpath('/NIRAL/work/akaiser/Projects/NetworkAnalysis_09-19-12/Tests/TK/2012-08-14BCT'); % add path to the library so matlab finds the functions
    
%% Load Circos Matrices
Cost=importdata([OutputFolder '/4_ComputeMatrices/MatrixCostCircos.txt']); % '/home/akaiser/Networking/Circos/TestConnecnoGM/MatrixNames.txt' % because row 1 and column 1 are names of labels
Cost=Cost.data; % 'data' contains the matrix
FSL=importdata([OutputFolder '/4_ComputeMatrices/MatrixFSLCircos.txt']); % '/home/akaiser/Networking/Circos/TestConnecnoGMFSLNew/MatrixNames.txt'
FSL=FSL.data;
FA=importdata([OutputFolder '/4_ComputeMatrices/MatrixFACircos.txt']); % '/home/akaiser/Networking/Circos/TestConnecnoGMFA/MatrixNames.txt'
FA=FA.data;

% Normalize matrices between 0 and 1 for analysis with toolbox
Cost=Cost/100;
FSL=FSL/100;
FA=FA/100;

NbLabels=length(Cost) % idem for all methods

%% Display matrices
% figure;
% 
% subplot(1,3,1);
% imagesc(Cost);
% title('Cost');
% axis equal;
% axis([0 NbLabels+1 0 NbLabels+1]);
% xlabel('X (region is target)');
% ylabel('Y (region is source)');
% 
% subplot(1,3,2);
% imagesc(FSL);
% title('FSL');
% axis equal;
% axis([0 NbLabels+1 0 NbLabels+1]);
% xlabel('X (region is target)');
% ylabel('Y (region is source)');
% 
% subplot(1,3,3);
% imagesc(FA);
% title('FA');
% axis equal;
% axis([0 NbLabels+1 0 NbLabels+1]);
% xlabel('X (region is target)');
% ylabel('Y (region is source)');

%colorbar;

%% Compute Network Properties %% !! All matrices are directed and weighted between 0 and 1 !!
%          Cost  FSL  FA
% prop1     X     X    X
% prop2     X     X    X
% prop3     X     X    X
% ...
% ..

% From C++ program:
% % Matrix
% nbNodes=NbLabels;
% nbLinks=GetNbLinks(M);
% % Degree Distribution
% MeanDegree = GetMeanDegree( M );
% Density = MeanDegree/nbNodes;
% % Measures of integration
% CharacteristicPathLength = GetCharacteristicPathLength( M , isWeighted );
% GlobalEfficiency = GetGlobalEfficiency( M , isWeighted );
% % Measures of segregation
% ClusteringCoefficient = GetClusteringCoefficient( M , isWeighted );
% Transivity = GetTransivity( M , isWeighted );
% LocalEfficiency = GetLocalEfficiency( M , isWeighted );
% % Measures of resilience
% AssortativityCoefficient = GetAssortativityCoefficient( M );
% % Other Concepts
% SmallWorldness = GetSmallWorldness( M , isWeighted );

disp('      Cost       FSL        FA'); % display in console

% Density % scalar
Density(:,1) = density_dir(Cost);
Density(:,2) = density_dir(FSL);
Density(:,3) = density_dir(FA);
Density

% Characteristic Path Length
CharacPathLength(:,1) = charpath(Cost);
CharacPathLength(:,2) = charpath(FSL);
CharacPathLength(:,3) = charpath(FA);
CharacPathLength

% Global Efficiency % scalar % Uses Dijkstra algorithm
GlobEff(:,1) = efficiency_wei(Cost);
GlobEff(:,2) = efficiency_wei(FSL);
GlobEff(:,3) = efficiency_wei(FA);
GlobEff

% Clustering Coefficient % vector
ClustCoeff(:,1) = clustering_coef_wd(Cost);
ClustCoeff(:,2) = clustering_coef_wd(FSL);
ClustCoeff(:,3) = clustering_coef_wd(FA);
%ClustCoeff % display vector

% Transivity % scalar
Transivity(:,1) = transitivity_wd(Cost);
Transivity(:,2) = transitivity_wd(FSL);
Transivity(:,3) = transitivity_wd(FA);
Transivity

% Local Efficiency %vector % Uses Dijkstra algorithm % 1 is for local
LocEff(:,1) = efficiency_wei(Cost,1);
LocEff(:,2) = efficiency_wei(FSL,1);
LocEff(:,3) = efficiency_wei(FA,1);
%LocEff % display vector

% Modularity
[Ci Q] = modularity_dir(Cost);
Modularity(:,1) = Q;
[Ci Q] = modularity_dir(FSL);
Modularity(:,2) = Q;
[Ci Q] = modularity_dir(FA);
Modularity(:,3) = Q;
Modularity

% Network Display: This function writes a Pajek .net file from a MATLAB matrix % last param = arcs = 1 for directed network and 0 for an undirected network
% -> Read in Pajek (windows only)
disp('Writing Pajek .net files..'); % display in console
writetoPAJ(Cost,[OutputFolder '/5_NetworkProperties/MatrixCostPajek'],1); % '/home/akaiser/Networking/PajekCost'
writetoPAJ(FSL,[OutputFolder '/5_NetworkProperties/MatrixFSLPajek'],1);  % '/home/akaiser/Networking/PajekFSL'
writetoPAJ(FA,[OutputFolder '/5_NetworkProperties/MatrixFAPajek'],1);  % '/home/akaiser/Networking/PajekFA'

%%
exit
