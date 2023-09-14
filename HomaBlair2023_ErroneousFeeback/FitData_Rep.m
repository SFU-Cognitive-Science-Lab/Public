%% REP Data Fitting. 
function [output] = FitData_Rep()

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
    [x,fval,exitflag,output] = fminsearchbnd(@Fit_ExemplarRep,x0,[.01,.01,.01,.01],[5,5,100,100000],options);

    disp('fitting process output')
    disp(output)

else
    fval = Fit_ExemplarRep(x0) ;
    FitWeights = fitW %weights of cf ef trans and rec for fit.
    x = x0 ;
end

output = [fval, x, Seeds, FitWeights]



% Learning Model/Human
ProbA_CF = ExemplarRep_CF_Learning(x) ;
ProbA_EF = ExemplarRep_EF_Learning(x) ;

Rep_CF_LearningData = round([ 0.445332, 0.522321, 0.556602, 0.592037, 0.633967, ...
    0.67123, 0.701757, 0.746669, 0.766182, 0.791311, ...
    0.79822, 0.832528, 0.841583, 0.84705, 0.872449, ... 
    0.92, 0.9289, 0.9318, 0.9379, 0.9261 ]',4) ;
Rep_CF_LearningData = Rep_CF_LearningData(2:20) ; % cuts off first block

Rep_EF_LearningData = round([ 0.297868, 0.28547, 0.336131, 0.369141, 0.320483, ...
    0.464452, 0.404879, 0.463499, 0.494585, 0.560173, ...
   0.583882, 0.590218, 0.656164, 0.656929, 0.705724, ...
    0.7743, 0.7736, 0.8096, 0.8214, 0.8811 ]',4) ;
Rep_EF_LearningData = Rep_EF_LearningData(2:20) ; % cuts off first block

% Transfer Model/Human
ProbA_Trans = ExemplarRep_Trans(x);
Rep_TransferData = [0.853, 0.864, 0.793, 0.751]; % Proto, Low, Med, High

% Recognition Model/Human 1(Old-cf),2(Old-ef),3(New),4(Proto),5(Foil)
Predictions_Rec = ExemplarRep_Rec(x);
Rep_Recognition =  [0.909,  0.904,     0.56,  0.828,   0.144] ;

if PrintPredictedValuesYes
    CfModelHuman = [ProbA_CF, Rep_CF_LearningData]
    EfModelHuman = [ProbA_EF, Rep_EF_LearningData ]
    TransModelHuman = [ProbA_Trans', Rep_TransferData' ]
    RecModelHuman = [Predictions_Rec', Rep_Recognition']
end

%%%
% Graphs

if GraphsYes
    
    figure
    Block = 2:20;
    plot(Block, ProbA_CF','r--', Block, ProbA_EF','b--', Block, Rep_CF_LearningData,'r-o', Block, Rep_EF_LearningData,'b-o', 'LineWidth', 2)
    legend('Predicted CF','Predicted EF', 'Rep Actual CF', 'Rep Actual EF', 'Location', 'Northwest');
    title('Rep Learning Data and Predictions');
    
    figure
    bar([Rep_TransferData; ProbA_Trans]')
    legend('Human Data','Model Predictions')
    title('Rep Transfer Data and Predictions')
    set(gca,'XTick',[1 2 3 4],'XTickLabel',...
        {'Prototype','Low','Med','High'});
    
    figure
    bar([Rep_Recognition; Predictions_Rec]')
    legend('Human Data','Model Predictions')
    title('Rep Recognition Data and Predictions')
    set(gca,'XTick',[1 2 3 4 5],'XTickLabel',...
        {'Old CF','Old EF','New','Proto','Foil'});
end

% Display fit output, RMSE, and Best fitting parameter values. 

disp('       c  Gamma  Beta  Theta')
disp(x)

disp('FitWeights = CF EF Trans Rec')
fitW

disp('wRMSE')
disp(fval)

%% Models and FitVal Functions %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXEMPLAR PREDICTIONS CORRECT FB %%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ProbA_CF = ExemplarRep_CF_Learning(x)

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
    

% One pattern identical, three med Distortions, and one Erroneous Feedback (otherDistance) 
EvidenceForA = ( (NumBlocks-1) * (exp(-D_Self*Sens) + (3 * exp(-D_Med_Med*Sens))...
    + (exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

% Five Other patterns (different prototype)
EvidenceForB = ( (NumBlocks-1) * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% One medium distortion (for EF), and four Other patterns, 
EvidenceForC = ( (NumBlocks-1) * (exp(-D_Med_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_CF = EvidenceForA ./ TotalEvidence ;

end 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXEMPLAR PREDICTIONS ERRONEOUS FB %%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ProbA_EF = ExemplarRep_EF_Learning(x)
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
    
% One pattern identical, four Erroneous Feedback (otherDistance) 
EvidenceForA = ( (NumBlocks-1) * (exp(-D_Self*Sens) + (4* exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

% Five Other patterns (different prototype)
EvidenceForB = ( (NumBlocks-1) * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% One medium distortion (for EF), and four Other patterns, 
EvidenceForC = ( (NumBlocks-1) * (4 * exp(-D_Med_Med*Sens) + (exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_EF = EvidenceForA ./ TotalEvidence ;
%ProbA_EF(1) = .3333 ; % Makes first block prediction chance instead of NaN

end 


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXEMPLAR PREDICTIONS TRANSFER %%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ProbA_Trans = ExemplarRep_Trans(x)
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
% Four low distortions (compared now to the prototype and one Erroneous Feedback (otherDistance) 
EvidenceForA = ( NumBlocks * (4 * exp(-D_Proto_Med*Sens) + (exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

% Five Other patterns (different prototype)
EvidenceForB = ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% One proto distortion (for EF), and four OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_Proto_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_Proto_REP_T = EvidenceForA / TotalEvidence ;



% LOW
% Four low distortions (compared now to the prototype and one Erroneous Feedback (otherDistance) 
EvidenceForA = ( NumBlocks * (4 * exp(-D_Low_Med*Sens) + (exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

% Five Other patterns (different prototype)
EvidenceForB= ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% One low distortion (for EF), and four OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_Low_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_Low_REP_T= EvidenceForA / TotalEvidence ;



% MED
% Four Medium distortions (compared now to the prototype and one Erroneous Feedback (otherDistance) 
EvidenceForA = ( NumBlocks * (4 * exp(-D_Med_Med*Sens) + (exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

% Five Other patterns (different prototype)
EvidenceForB = ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% One medium distortion (for EF), and four OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_Med_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_Med_REP_T = EvidenceForA / TotalEvidence ;



% HIGH
% Four high distortions (compared now to the prototype) and one Erroneous Feedback (otherDistance) 
EvidenceForA = ( NumBlocks * (4 * exp(-D_High_Med*Sens) + (exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

% Five Other patterns (different prototype)
EvidenceForB = ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% One high distortion (for EF), and four OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_High_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;
ProbA_High_REP_T = EvidenceForA / TotalEvidence ;

ProbA_Trans = [ProbA_Proto_REP_T, ProbA_Low_REP_T, ProbA_Med_REP_T, ProbA_High_REP_T] ;

end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXEMPLAR PREDICTIONS RECOGNITON %%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Predictions_Rec = ExemplarRep_Rec(x)
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
% 1 idential pattern, 3 medium, 1 other
EvidenceForA = ( NumBlocks * (exp(-D_Self*Sens)) * ((3 * exp(-D_Med_Med*Sens) + (exp(-D_Other*Sens)) ) + Beta) .^Gamma );

% 5 Other patterns (different prototype)
EvidenceForB = ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% 1 medium distortion (for EF), and 4 OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_Med_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Old = TotalEvidence / (Theta + TotalEvidence) ; 


% PROTO %%%%%%%%%%%%%%%%%%%%%
% 4 proto 1 other
EvidenceForA = ( NumBlocks * (4 * exp(-D_Proto_Med*Sens)) * (exp(-D_Other*Sens) ) + Beta) .^Gamma ;
             
% 5 Other patterns (different prototype)
EvidenceForB = ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% 1 proto distortion (for EF), and 4 OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_Proto_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Proto = TotalEvidence / (Theta + TotalEvidence) ; 


% MED %%%%%%%%%%%%%%%%%%%%%
% 4 Med 1 other
EvidenceForA = ( NumBlocks * (4 * exp(-D_Med_Med*Sens)) * (exp(-D_Other*Sens) ) + Beta) .^Gamma ;

% 5 Other patterns (different prototype)
EvidenceForB = ( NumBlocks * (5 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% 1 Med distortion (for EF), and 4 OtherProto patterns, 
EvidenceForC = ( NumBlocks * ( exp(-D_Med_Med*Sens) + (4 * exp(-D_Other*Sens)) ) + Beta) .^Gamma ;

TotalEvidence = EvidenceForA + EvidenceForB + EvidenceForC ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Med = TotalEvidence / (Theta + TotalEvidence) ; 


% FOIL %%%%%%%%%%%%%%%%%%%%%
% 15 other patterns
TotalEvidence = ( NumBlocks * (15 * exp(-D_Other*Sens)) + Beta) .^Gamma ;

% Evidence for recognition is not based on a single category, like learning or transfer. 
P_old_Foil = TotalEvidence / (Theta + TotalEvidence) ; 


% OldCf, OldEF (same), Medium (New), Proto, Foil
Predictions_Rec = [P_old_Old,P_old_Old, P_old_Med, P_old_Proto, P_old_Foil ];

end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Produce goodness of fit values %%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function wRMSE = Fit_ExemplarRep(x)

if min(x) < 0 ; %keeps Beta from going negative
    wRMSE = 10 ;
    return
end

% %%%% Learning RMSE calculations %%%%%%%%%%%

% Model Predictions
ProbA_CF = ExemplarRep_CF_Learning(x);
% Human data
Rep_CF_LearningData = round([ 0.445332, 0.522321, 0.556602, 0.592037, 0.633967, ...
    0.67123, 0.701757, 0.746669, 0.766182, 0.791311, ...
    0.79822, 0.832528, 0.841583, 0.84705, 0.872449, ... 
    0.92, 0.9289, 0.9318, 0.9379, 0.9261 ]',4) ;
Rep_CF_LearningData = Rep_CF_LearningData(2:20) ; % cuts off first block

RMSE_CF_Learning = (sum([ProbA_CF-Rep_CF_LearningData].^2)/length(Rep_CF_LearningData))^.5;

% Model Prediction
ProbA_EF = ExemplarRep_EF_Learning(x);
% Human Data
Rep_EF_LearningData = round([ 0.297868, 0.28547, 0.336131, 0.369141, 0.320483, ...
    0.464452, 0.404879, 0.463499, 0.494585, 0.560173, ...
   0.583882, 0.590218, 0.656164, 0.656929, 0.705724, ...
    0.7743, 0.7736, 0.8096, 0.8214, 0.8811 ]',4) ;
Rep_EF_LearningData = Rep_EF_LearningData(2:20) ; % cuts off first block

% Error
RMSE_EF_Learning = (sum([Rep_EF_LearningData-ProbA_EF].^2)/length(Rep_EF_LearningData))^.5;

% %%%% Transfer RMSE calculations %%%%%%%%%%%

% ModelPredictions
ProbA_Trans = ExemplarRep_Trans(x);

% Human Data
% NRep_TransferData = [0.914, 0.904, 0.884, 0.763] ;% Proto, Low, Med, High
Rep_TransferData = [0.853, 0.864, 0.793, 0.751] ; % Proto, Low, Med, High

% Error
RMSE_Transfer = (sum([Rep_TransferData-ProbA_Trans].^2)/length(Rep_TransferData))^.5;

% %%%% Recognition  RMSE calculations %%%%%%%%%%%

% Model Predictions
Predictions_Rec = ExemplarRep_Rec(x);

% Human Data    1(Old-cf),2(Old-ef),3(Med/New),4(Proto), 5(Foil)
% NRep_Recognition = [0.68,   0.697,   0.692,     0.909,   0.263] ;
Rep_Recognition =  [0.909,  0.904,   0.56,      0.828,   0.144] ;

% Error
RMSE_Rec = (sum([Predictions_Rec-Rep_Recognition].^2)/length(Predictions_Rec))^.5;

wRMSE = (fitW(1) * RMSE_CF_Learning + fitW(2) * RMSE_EF_Learning + fitW(3) * RMSE_Transfer + fitW(4) * RMSE_Rec) /sum(fitW) ;
end





end

