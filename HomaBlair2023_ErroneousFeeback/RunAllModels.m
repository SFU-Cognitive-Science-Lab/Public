% Run all Model fits

clear all

global x0
global fitW
global OptimizeYes
global GraphsYes
global PrintPredictedValuesYes
global options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OptimizeYes = 1 ;
GraphsYes = 0 ;
PrintPredictedValuesYes = 0 ;

PublishOutput = 0;

% x0 = [ 4    4    40  400]; % seed values for Sens, Gamma, Beta, Theta
options = optimset('MaxFunEvals',10000,'MaxIter',10000, 'TolX', .01 );
fitW = [1 1 1 1]; % fits only to CF learning

FitsTable = zeros(100,28);

for i = 1:100
   x0 = [randi([1 5]),randi([1 5]),randi([1 100]),randi([1 5000])];
  
   
   output = FitData_Rep()
    FitsTable(i,1) = output(1);% wRMSE
    FitsTable(i,5:8) = output(2:5); % best params
    clear output
   
   output = FitData_prototype_Rep()
    FitsTable(i,2) = output(1);% wRMSE
    FitsTable(i,9:12) = output(2:5); % best params
    clear output

   
   output = FitData_NREP()
    FitsTable(i,3) = output(1);% wRMSE
    FitsTable(i,13:16) = output(2:5); % best params
    clear output

   
   output =  FitData_prototype_NREP()
    FitsTable(i,4) = output(1); % wRMSE
    FitsTable(i,17:20) = output(2:5) ; % best params

    
    FitsTable(i,21:24) = output(6:9); % add the seeds
    FitsTable(i,25:28) = output(10:13); % add the fit weights
    
    T = array2table(FitsTable);
    T.Properties.VariableNames = {'ERep_wRMSE','PRep_wRMSE','EnREP_wRMSE','PnREP_wRMSE',...
        'ERep_c_best','ERep_gamma_best','ERep_beta_best','ERep_theta_best',...
        'PRep_c_best','PRep_gamma_best','PRep_beta_best','PRep_theta_best',...
        'EnREP_c_best','EnREP_gamma_best','EnREP_beta_best','EnREP_theta_best',...
        'PnREP_c_best','PnREP_gamma_best','PnREP_beta_best','PnREP_theta_best',...
        'c_seed','gamma_seed','beta_seed','theta_seed',...
        'CF_weight','EF_weight','trans_weight','Rec_weight'};



end 

writetable(T,'FitsTable','Delimiter',',')

% 'Display', 'iter'
% fitW = [1 1 2 2] % equally weights datapoints.
% fitW = [19 19 4 5]; % % Weights are for CF, EF, Transfer, and Recgonition

% fitW = [0 0 1 0]; % fits only to trans
% fitW = [0 0 0 1]; % fits only to rec
% fitW = [0 0 1 1]; % fits only to trans and rec


% disp('*****************************************')
% disp('Exemplar Rep')
% disp('*****************************************')
% FitData_Rep
% 
% disp('*****************************************')
% disp('Prototype Rep')
% disp('*****************************************')
% FitData_prototype_Rep
% 
% disp('*****************************************')
% disp('Exemplar NREP')
% disp('*****************************************')
% FitData_NREP
% 
% disp('*****************************************')
% disp('Prototype NREP')
% disp('*****************************************')
% FitData_prototype_NREP


if PublishOutput==1
    publish('FitData_Rep.m', 'pdf');
    publish('FitData_NREP.m','pdf');
    publish('FitData_prototype_Rep.m', 'pdf');
    publish('FitData_prototype_NREP.m', 'pdf');
    clear all
end
