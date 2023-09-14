function [output] = FitData_prototype_NREP() %% PROTOTYPE NREP Data Fitting. 
% This code fits the exmplar model to the REP learning data for both CF and
% EF patterns. 

global x0
global fitW
global OptimizeYes
global GraphsYes
global PrintPredictedValuesYes
global options

%% SEARCH FOR OPTIMAL PARAMETERS
% This calls the fit function below, which in turn calls the two sets of
% model calculations. 
close all;

Seeds = x0;
FitWeights = fitW;

if OptimizeYes
    [x,fval,exitflag,output] = fminsearchbnd(@Fit_ProtoNREP,x0,[.01,.01,.01,.01],[5,5,100,100000],options); 
    FitWeights = fitW
else
    fval = Fit_ExemplarNREP(x0) ;
    FitWeights = fitW ;%weights of cf ef trans and rec for fit.
    x = x0 ;
end


output = [fval, x, Seeds, FitWeights]


% Learning Model/Human
ProbA_CF = ProtoNREP_CF_Learning(x);
ProbA_EF = ProtoNREP_EF_Learning(x);

NREP_CF_LearningData = round([0.445567, 0.478382, 0.539524, 0.552225, 0.594001, ...
    0.642258, 0.638179, 0.633971, 0.681023, 0.703317, ...	
    0.679348, 0.714127, 0.665793, 0.689984, 0.702759, ...	
    0.7357, 0.7746, 0.7514, 0.7911, 0.7411]',4) ;
NREP_CF_LearningData = NREP_CF_LearningData(2:20) ; % cuts off first block


NREP_EF_LearningData = round([0.288547, 0.301171, 0.216192, 0.211841, 0.113439, ...
    0.185006, 0.136671, 0.19099, 0.217499, 0.150618, ...
    0.158073, 0.132908, 0.144409, 0.156295, 0.179882, ...
    0.122, 0.14, 0.048, 0.177333, 0.104]',4) ;
NREP_EF_LearningData = NREP_EF_LearningData(2:20) ; % cuts off first block

% Transfer  Model/Human  % Proto, Low, Med, High
ProbA_Trans = ProtoNREP_Trans(x);
NRep_TransferData = [0.914, 0.904, 0.884, 0.763];

% Recognition  Model/Human
Predictions_Rec = ProtoNREP_Rec(x);
% Human Data        1(Old-cf),2(Old-ef),3(New),4(Proto),5(Foil)
NRep_Recognition = [0.68,   0.697,     0.692, 0.909,   0.263] ;
 
if PrintPredictedValuesYes
    CfModelHuman = [ProbA_CF, NREP_CF_LearningData]
    EfModelHuman = [ProbA_EF, NREP_EF_LearningData ]
    TransModelHuman = [ProbA_Trans', NRep_TransferData' ]
    RecModelHuman = [Predictions_Rec', NRep_Recognition']
end

%%%
% Graphs

if GraphsYes

Block = 2:20;
plot(Block,ProbA_CF,'r--', Block,ProbA_EF,'b--', Block,NREP_CF_LearningData,'r-o', Block,NREP_EF_LearningData,'b-o', 'LineWidth', 2)
legend('Predicted CF','Predicted EF', 'REP Actual CF', 'REP Actual EF', 'Location', 'Northwest');
title('PROTOTYPE Learning Data and Predictions');


figure
bar([NRep_TransferData; ProbA_Trans]')
legend('Human Data','Model Predictions')
title('NREP PROTOTYPE Transfer Data and Predictions')
set(gca,'XTick',[1 2 3 4],'XTickLabel',...
    {'Prototype','Low','Med','High'});



figure
bar([NRep_Recognition; Predictions_Rec]')
legend('Human Data','Model Predictions')
title('NREP PROTOTYPE Recognition Data and Predictions')
set(gca,'XTick',[1 2 3 4 5],'XTickLabel',...
    {'Old CF','Old EF','New','Proto','Foil'});

end


% Display fit output, RMSE, and Best fitting parameter values. 

disp('       c  Gamma  Beta  Theta')
x

disp('FitWeights = CF EF Trans Rec')
fitW

disp('wRMSE')
disp(fval)



%% Models and FitVal Functions %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Proto PREDICTIONS CORRECT FB %%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ProbA_CF = ProtoNREP_CF_Learning(x)

Sens = x(1);
Gamma = x(2);
Beta = x(3);


% we will not use all these, but this is easiest to copy/paste
D_Self = 0 ;
D_Proto_Low = .24 ;
D_Proto_Med = .45 ;
D_Proto_High = .82 ;
D_Low_Med = .5 ;
D_Med_Med = .72 ;
D_High_Med = .86  ;
D_Other = 1.6  ; 
    
NumBlocks = [2:20]' ;    
    
%  proto to med
EvidenceForA = ( (NumBlocks-1) * (exp(-D_Proto_Med*Sens)) + Beta) .^Gamma ;

% other
EvidenceForB = ( (NumBlocks-1) * (exp(-D_Other*Sens)) + Beta) .^Gamma ;

% other
EvidenceForC = ( (NumBlocks-1) * (exp(-D_Other*Sens)) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_CF = EvidenceForA ./ TotalEvidence ;
% ProbA_CF(1) = .3333 ; % Makes first block prediction chance instead of NaN

end 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Proto PREDICTIONS ERRONEOUS FB %%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ProbA_EF = ProtoNREP_EF_Learning(x)
% This function produces predictions for learning. 

Sens = x(1);
Gamma = x(2);
Beta = x(3);



% we will not use all these, but this is easiest to copy/paste
D_Self = 0 ;
D_Proto_Low = .24 ;
D_Proto_Med = .45 ;
D_Proto_High = .82 ;
D_Low_Med = .5 ;
D_Med_Med = .72 ;
D_High_Med = .86  ;
D_Other = 1.6  ; 
    
NumBlocks = [2:20]' ;    
    
%  proto to other (ef pattern, wrong proto)
EvidenceForA = ( (NumBlocks-1) * (exp(-D_Other*Sens)) + Beta) .^Gamma ;

% other
EvidenceForB = ( (NumBlocks-1) * (exp(-D_Other*Sens)) + Beta) .^Gamma ;

% proto to  med
EvidenceForC = ( (NumBlocks-1) * (exp(-D_Proto_Med*Sens)) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_EF = EvidenceForA ./ TotalEvidence ;
% ProbA_EF(1) = .3333 ; % Makes first block prediction chance instead of NaN

end 


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Proto PREDICTIONS TRANSFER %%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ProbA_Trans = ProtoNREP_Trans(x)
% This function produces predictions for Transfer
Sens = x(1);
Gamma = x(2);
Beta = x(3);


% we will not use all these, but this is easiest to copy/paste
D_Self = 0 ;
D_Proto_Low = .24 ;
D_Proto_Med = .45 ;
D_Proto_High = .82 ;
D_Low_Med = .5 ;
D_Med_Med = .72 ;
D_High_Med = .86  ;
D_Other = 1.6  ; 
    
NumBlocks = 20 ;

% NumBlocks no longer n-1 because we are at the end of the experiment. 
% Beta set above.

% PROTOTPE
% proto 
EvidenceForA = (NumBlocks * exp(-D_Self*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_Proto_REP_T = EvidenceForA / TotalEvidence ;



% LOW
% low 
EvidenceForA = (NumBlocks * exp(-D_Proto_Low*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_Low_REP_T= EvidenceForA / TotalEvidence ;



% MED
% Med 
EvidenceForA = (NumBlocks * exp(-D_Proto_Med*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_Med_REP_T = EvidenceForA / TotalEvidence ;



% HIGH
EvidenceForA = (NumBlocks * exp(-D_Proto_High*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_High_REP_T = EvidenceForA / TotalEvidence ;

ProbA_Trans = [ProbA_Proto_REP_T, ProbA_Low_REP_T, ProbA_Med_REP_T, ProbA_High_REP_T] ;

end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Proto PREDICTIONS RECOGNITON %%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Predictions_Rec = ProtoNREP_Rec(x)
% This Function Produces predictions for Recognition
Sens = x(1);
Gamma = x(2);
Beta = x(3);
Theta = x(4);



% we will not use all these, but this easiest to copy/paste
D_Self = 0 ;
D_Proto_Low = .24 ;
D_Proto_Med = .45 ;
D_Proto_High = .82 ;
D_Low_Med = .5 ;
D_Med_Med = .72 ;
D_High_Med = .86  ;
D_Other = 1.6  ; 
    
NumBlocks = 20 ; 

% OLD %%%%%%%%%%%%%%%%%%%%%
% 1  medium
EvidenceForA = (NumBlocks * exp(-D_Proto_Med*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ; 

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Old = TotalEvidence / (Theta + TotalEvidence) ;


% PROTO %%%%%%%%%%%%%%%%%%%%%
% 1  self
EvidenceForA = (NumBlocks * exp(-D_Self*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ; 

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Proto = TotalEvidence / (Theta + TotalEvidence) ; 


% MED %%%%%%%%%%%%%%%%%%%%%
% 1  med
EvidenceForA = (NumBlocks * exp(-D_Proto_Med*Sens) + Beta) .^Gamma ;

% other
EvidenceForB = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% other 
EvidenceForC = (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ; 

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Med = TotalEvidence / (Theta + TotalEvidence) ; 


% FOIL %%%%%%%%%%%%%%%%%%%%%
% 15 other patterns
TotalEvidence =  (NumBlocks * exp(-D_Other*Sens) + Beta) .^Gamma ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Foil = TotalEvidence / (Theta + TotalEvidence) ; 

% OldCf, OldEF (same), Medium (New), Proto, Foil
Predictions_Rec = [P_old_Old,P_old_Old, P_old_Med, P_old_Proto, P_old_Foil ];

end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Produce goodness of fit values %%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function wRMSE = Fit_ProtoNREP(x)

if min(x) < 0 ; % keep parameters positive
    wRMSE = 10 ;
    return
end


% %%%% Learning RMSE calculations %%%%%%%%%%%

% Model Predictions CF
ProbA_CF = ProtoNREP_CF_Learning(x);

% Human data
NREP_CF_LearningData = round([0.445567, 0.478382, 0.539524, 0.552225, 0.594001, ...
    0.642258, 0.638179, 0.633971, 0.681023, 0.703317, ...	
    0.679348, 0.714127, 0.665793, 0.689984, 0.702759, ...	
    0.7357, 0.7746, 0.7514, 0.7911, 0.7411]',4) ;

NREP_CF_LearningData = NREP_CF_LearningData(2:20) ; % cuts off first block

% Error
RMSE_CF_Learning = (sum([ProbA_CF-NREP_CF_LearningData].^2)/length(NREP_CF_LearningData))^.5;

% Model Prediction EF
ProbA_EF = ProtoNREP_EF_Learning(x);

% Human Data
NREP_EF_LearningData = round([0.288547, 0.301171, 0.216192, 0.211841, 0.113439, ...
    0.185006, 0.136671, 0.19099, 0.217499, 0.150618, ...
    0.158073, 0.132908, 0.144409, 0.156295, 0.179882, ...
    0.122, 0.14, 0.048, 0.177333, 0.104]',4) ;

NREP_EF_LearningData = NREP_EF_LearningData(2:20) ; % cuts off first block

% Error
RMSE_EF_Learning = (sum([NREP_EF_LearningData-ProbA_EF].^2)/length(NREP_EF_LearningData))^.5;

% %%%% Transfer RMSE calculations %%%%%%%%%%%

% ModelPredictions
ProbA_Trans = ProtoNREP_Trans(x);

% Human Data
NRep_TransferData = [0.914, 0.904, 0.884, 0.763] ;% Proto, Low, Med, High
%Rep_TransferData = [0.853, 0.864, 0.793, 0.751] ;% Proto, Low, Med, High

% Error
RMSE_Transfer = (sum([NRep_TransferData-ProbA_Trans].^2)/length(NRep_TransferData))^.5;

% %%%% Recognition  RMSE calculations %%%%%%%%%%%

% Model Predictions
Predictions_Rec = ProtoNREP_Rec(x);

% Human Data    1(Old-cf),2(Old-ef),3(Med/New),4(Proto), 5(Foil)
NRep_Recognition = [0.68,   0.697,   0.692,     0.909,   0.263] ;
%Rep_Recognition =  [0.909,  0.904,   0.56,      0.828,   0.144] ;

% Error
RMSE_Rec = (sum([Predictions_Rec-NRep_Recognition].^2)/length(Predictions_Rec))^.5;

% Weighted RMSE calculations %%%%%%%%%%%%%%

wRMSE = (fitW(1) * RMSE_CF_Learning + fitW(2) * RMSE_EF_Learning + fitW(3) * RMSE_Transfer + fitW(4) * RMSE_Rec) /sum(fitW) ;

end


end
