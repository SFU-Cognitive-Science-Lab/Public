%% Feedback analysis workflow
%
% Author: Jordan B.
% Date: Jan, 2019
%
% Linear Mixed-Effect (LME) Models are generalizations of linear regression 
% models for data that is collected and summarized in groups. Linear Mixed-
% Effects models offer a flexible framework for analyzing grouped data 
% while accounting for the within group correlation often present in such 
% data.
%
% credit: https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/
% submissions/46515/versions/7/previews/html/MixedEffects_Introduction.html


%% Get data

ExperimentName='Feedback3';
subjectTableAllFB3 = ExpAnalysisTable(ExperimentName, 24);

ExperimentName='Feedback2';
subjectTableAllFB2 = ExpAnalysisTable(ExperimentName, 24);

subjectTableAllCombinedFB = [subjectTableAllFB2;subjectTableAllFB3];
% save('subjectTableAllCombinedFB.mat','subjectTableAllCombinedFB');


%% Process data

% Convert Accuracy from categorial to logical
subjectTableAllCombinedFB.Accuracy = logical(str2double(string(subjectTableAllCombinedFB.Accuracy)));

% Only learners
subjectTableLearners = subjectTableAllCombinedFB(subjectTableAllCombinedFB.Learner==1,:);

% Cut the last p4 fixation on each trial to avoid truncations.

TrialChangePoints = ([diff(subjectTableLearners.Trial);1] & subjectTableLearners.TrialPhase==4);
subjectTableAllCombinedFB = subjectTableLearners(~TrialChangePoints,:);

save('subjectTableAllCombinedFB_binSize24_LastFixationCut.mat','subjectTableAllCombinedFB');


% Optional processing

subjectTableAllCombinedFB = subjectTableAllCombinedFB(subjectTableAllCombinedFB.TrialBin<11,:);


subjectTableAllCombinedFB.Accuracy = double(subjectTableAllCombinedFB.Accuracy);
subjectTableAllCombinedFB.TrialPhase = categorical(subjectTableAllCombinedFB.TrialPhase);

subjectTableAllCombinedFB2 = subjectTableAllCombinedFB(subjectTableAllCombinedFB.ExperimentName == 'Feedback2',:);
subjectTableAllCombinedFB3 = subjectTableAllCombinedFB(subjectTableAllCombinedFB.ExperimentName == 'Feedback3',:);

subjectTableAllCombinedFB2P4 = subjectTableAllCombinedFB(subjectTableAllCombinedFB.TrialPhase == '4',:);
subjectTableAllCombinedFB3P4 = subjectTableAllCombinedFB(subjectTableAllCombinedFB.TrialPhase == '4',:);


%% Create TrialBin level averages

groupedSubjects = grpstats(subjectTableAllCombinedFB,...
     {'Subject','Condition','TrialBin','ExperimentName'},{'mean','predci','gname'},'datavars',{'Accuracy','AbsoluteExperimentTimeET','OptimizationP2','OptimizationP4'});

groupedSubjectsFB2 = grpstats(subjectTableAllCombinedFB2,...
     {'Subject','Condition','TrialBin','ExperimentName'},{'mean','predci','gname'},'datavars',{'Accuracy','AbsoluteExperimentTimeET','OptimizationP2','OptimizationP4'});

groupedSubjectsFB3 = grpstats(subjectTableAllCombinedFB3,...
     {'Subject','Condition','TrialBin','ExperimentName'},{'mean','predci','gname'},'datavars',{'Accuracy','AbsoluteExperimentTimeET','OptimizationP2','OptimizationP4'});

 
 
%% Assumptions

% Residuals of an LME model should be normally distributed, but homogeneity
% of variance in the data is not required.

% Optionally plot the data intervals by subject.
% figure
% plotIntervals(groupedSubjects,'mean_Accuracy ~ 1 + TrialBin + Condition + ExperimentName','Subject')



%% Stats

% Could use mean_AbsoluteExperimentTimeFixStart or Condition for
% interaction with TrialBin.

% Predicting accuracy

% Exp 1

mdl1a = fitlme(subjectTableAllCombinedFB2,'Accuracy ~ 1 + Trial*Condition')
mdl11 = fitlme(subjectTableAllCombinedFB2,'Accuracy ~ 1 + Trial*Condition + (1 + Trial|Subject)')
compare(mdl1a,mdl11)


% New method

mdl11 = fitlme(groupedSubjectsFB2,'mean_Accuracy ~ 1 + TrialBin + Condition + TrialBin:Condition + (1 + TrialBin|Subject)')
mdl1b = fitlme(groupedSubjectsFB2,'mean_Accuracy ~ 1 + TrialBin + Condition + (1 + TrialBin|Subject)')
mdl1a = fitlme(groupedSubjectsFB2,'mean_Accuracy ~ 1 + TrialBin + (1 + TrialBin|Subject)')
compare(mdl1b,mdl11)
compare(mdl1a,mdl1b)



% Exp 2
mdl2a = fitlme(subjectTableAllCombinedFB,'Accuracy ~ 1 + Trial*Condition + ExperimentName')
mdl21 = fitlme(subjectTableAllCombinedFB,'Accuracy ~ 1 + Trial*Condition + ExperimentName + (1 + Trial|Subject)')
compare(mdl2a,mdl21)
mdl21 = fitlme(subjectTableAllCombinedFB3,'Accuracy ~ 1 + Trial*Condition + (1 + Trial|Subject)')

% New method

mdl21 = fitlme(groupedSubjectsFB3,'mean_Accuracy ~ 1 + TrialBin + Condition + TrialBin:Condition + (1 + TrialBin|Subject)')
mdl2b = fitlme(groupedSubjectsFB3,'mean_Accuracy ~ 1 + TrialBin + Condition + (1 + TrialBin|Subject)')
mdl2a = fitlme(groupedSubjectsFB3,'mean_Accuracy ~ 1 + TrialBin + (1 + TrialBin|Subject)')
compare(mdl2b,mdl21)
compare(mdl2a,mdl2b)

mdl221 = fitlme(groupedSubjects,'mean_Accuracy ~ 1 + TrialBin + ExperimentName + TrialBin:ExperimentName + (1 + TrialBin|Subject)')
mdl22b = fitlme(groupedSubjects,'mean_Accuracy ~ 1 + TrialBin + ExperimentName + (1 + TrialBin|Subject)')
mdl22a = fitlme(groupedSubjects,'mean_Accuracy ~ 1 + TrialBin + (1 + TrialBin|Subject)')
compare(mdl22b,mdl221)
compare(mdl22a,mdl22b)


% Predicting optimization

% Exp 1

mdl3a = fitlme(subjectTableAllCombinedFB2,'OptimizationP2 ~ 1 + Trial*Condition')
mdl31 = fitlme(subjectTableAllCombinedFB2,'OptimizationP2 ~ 1 + Trial*Condition + (1 + Trial|Subject)')
compare(mdl3a,mdl31)


% New method

mdl31 = fitlme(groupedSubjectsFB2,'mean_OptimizationP2 ~ 1 + TrialBin + Condition + TrialBin:Condition + (1 + TrialBin|Subject)')
mdl3b = fitlme(groupedSubjectsFB2,'mean_OptimizationP2 ~ 1 + TrialBin + Condition + (1 + TrialBin|Subject)')
mdl3a = fitlme(groupedSubjectsFB2,'mean_OptimizationP2 ~ 1 + TrialBin + (1 + TrialBin|Subject)')
compare(mdl3b,mdl31)
compare(mdl3a,mdl3b)


% Exp 2

mdl4a = fitlme(subjectTableAllCombinedFB,'OptimizationP2 ~ 1 + Trial*Condition + ExperimentName')
mdl41 = fitlme(subjectTableAllCombinedFB,'OptimizationP2 ~ 1 + Trial*Condition + ExperimentName + (1 + Trial|Subject)')
compare(mdl4a,mdl41)


% New method

mdl41 = fitlme(groupedSubjectsFB3,'mean_OptimizationP2 ~ 1 + TrialBin + Condition + TrialBin:Condition + (1 + TrialBin|Subject)')
mdl4b = fitlme(groupedSubjectsFB3,'mean_OptimizationP2 ~ 1 + TrialBin + Condition + (1 + TrialBin|Subject)')
mdl4a = fitlme(groupedSubjectsFB3,'mean_OptimizationP2 ~ 1 + TrialBin + (1 + TrialBin|Subject)')
compare(mdl4b,mdl41)
compare(mdl4a,mdl4b)

mdl421 = fitlme(groupedSubjects,'mean_OptimizationP2 ~ 1 + TrialBin + ExperimentName + TrialBin:ExperimentName + (1 + TrialBin|Subject)')
mdl42b = fitlme(groupedSubjects,'mean_OptimizationP2 ~ 1 + TrialBin + ExperimentName + (1 + TrialBin|Subject)')
mdl42a = fitlme(groupedSubjects,'mean_OptimizationP2 ~ 1 + TrialBin + (1 + TrialBin|Subject)')
compare(mdl42b,mdl421)
compare(mdl42a,mdl42b)



% Predicting fixation duration

% Exp 1

mdl5a = fitlme(subjectTableAllCombinedFB2P4,'Duration ~ 1 + Trial*Condition')
mdl51 = fitlme(subjectTableAllCombinedFB2P4,'Duration ~ 1 + Trial*Condition + (1 + Trial|Subject)')
compare(mdl5a,mdl51)
% mdl52 = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial*TrialPhase*Condition + (1 + Trial|Subject)')
% compare(mdl51,mdl52)


% New method

mdl51 = fitlme(subjectTableAllCombinedFB2,'Duration ~ 1 + Trial + Condition + Trial:Condition + (1 + Trial|Subject)')
mdl5b = fitlme(subjectTableAllCombinedFB2,'Duration ~ 1 + Trial + Condition + (1 + Trial|Subject)')
mdl5a = fitlme(subjectTableAllCombinedFB2,'Duration ~ 1 + Trial + (1 + Trial|Subject)')
compare(mdl5b,mdl51)
compare(mdl5a,mdl5b)



% Exp 2

mdl6a = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial*Condition + ExperimentName')
mdl61 = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial*Condition + ExperimentName + (1 + Trial|Subject)')
compare(mdl6a,mdl61)
mdl62 = fitlme(subjectTableAllCombinedFB3,'Duration ~ 1 + Trial*Condition + (1 + Trial|Subject)')


% New method

mdl61 = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial + Condition + Trial:Condition + (1 + Trial|Subject)')
mdl6b = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial + Condition + (1 + Trial|Subject)')
mdl6a = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial + (1 + Trial|Subject)')
compare(mdl6b,mdl61)
compare(mdl6a,mdl6b)

mdl621 = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial + ExperimentName + Trial:ExperimentName + (1 + Trial|Subject)')
mdl62b = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial + ExperimentName + (1 + Trial|Subject)')
mdl62a = fitlme(subjectTableAllCombinedFB,'Duration ~ 1 + Trial + (1 + Trial|Subject)')
compare(mdl62b,mdl621)
compare(mdl62a,mdl62b)



%% Model visuals

% Comparing random effect estimates of model 1 and model 2

% [~,~,rEffects] = randomEffects(mdl1);
% 
% figure
% scatter(rEffects.Estimate(1:2:end),rEffects.Estimate(2:2:end))
% title('Random Effects','FontSize',15)
% xlabel('Intercept','FontSize',15)
% ylabel('Slope','FontSize',15)
% xlim([-1 1]);ylim([-1 1]);

% The estimated column in the random-effects table shows the estimated best
% linear unbiased predictor (BLUP) vector of random effects.

% [~,~,rEffects] = randomEffects(mdl2);
% 
% figure
% scatter(rEffects.Estimate(1:2:end),rEffects.Estimate(2:2:end))
% title('Random Effects','FontSize',15)
% xlabel('Intercept','FontSize',15)
% ylabel('Slope','FontSize',15)
% xlim([-1 1]);ylim([-1 1]);



%% Forecast subjects

% forecastSubjects = {'640','641','3209','3210'};
% unbalancedSubject = {'3212'};
% missingTrialBins = 1:10;
% compareForecasts(groupedSubjects, forecastSubjects, unbalancedSubject, missingTrialBins)
