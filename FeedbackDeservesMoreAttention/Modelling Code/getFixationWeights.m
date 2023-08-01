% Author: Tyrus Tracey 
% Date Created: [Feb-16-2021]
% Last Edited: [Oct 24 2021] -- changing to work for ORIS
%
%  Cognitive Science Lab, Simon Fraser University 
%  Originally Created For: Feedback 2021
%
%  Reviewed: Mark Blair 1 April 2021 
%  Verified: Kat Dolguikh 04/15/21
%
%   PURPOSE: 
%  Retrive participant data to be fed into models akin to Leong et al. 2019
%
%   INPUT: 
%  Experiment name string, and subject number of desired participant.   
%
%   OUTPUT: 
%  Table of participant's trial-level data, with the following variables:
%       - Presented stimulus
%       - Correct category
%       - Chosen category
%       - Phase 2 fixation weights (relative time spent on each stimulus feature)
%       - Phase 4 fixation weights (relative time spent on each stimulus feature)
%
%   Additional Scripts Used: 
%  None.

function output = getFixationWeights(experiment, subjectNum)

% Check experiment argument
verifyExperiment(experiment);

% Set directory and read data. Change directory as needed.
dir = [pwd(), '/'];
dir = strcat(dir, experiment);
load(strcat(dir, '/explvl.mat'),'explvl');
load(strcat(dir, '/fixlvl.mat'),'fixlvl');
load(strcat(dir, '/triallvl.mat'),'triallvl');

% Check subject argument
verifySubject(subjectNum, explvl);

% Filter desired subject from data
subjectTrials = triallvl(triallvl.Subject == subjectNum,:);
subjectFixs = fixlvl(fixlvl.Subject == subjectNum,:);
trialCol = subjectTrials.TrialID;

% change variable names for ORIS
if strncmp(experiment, 'oris', 4)
   f1 = 'Location1Value';
   f2 = 'Location2Value';
   f3 = 'Location3Value';
else
   f1 = 'Feature1Value';
   f2 = 'Feature2Value';
   f3 = 'Feature3Value';
end

% Join trial level data with fixation level
subjectData = innerjoin(subjectTrials, subjectFixs,...
    'Keys','TrialID',...
    'LeftVariables',...
        {'TrialID' f1 f2 f3 'CorrectResponse' 'Response'},...
    'RightVariables',...    
        {'TrialPhase' 'funcRelevance' 'Duration'});
    
% Filter fixations only to stimulus features
subjectData = groupfilter(subjectData, 'funcRelevance',@(x)(x > 0 & x < 4), 'funcRelevance');

% Generate groups for splitapply
[Groups, TrialID, TrialPhase, funcRelevance] = findgroups(subjectData.TrialID, subjectData.TrialPhase, subjectData.funcRelevance);

% For each trial's phase 2 and 4, sum the duration spent on each feature
fixAbsolute = splitapply(@sum, subjectData.Duration, Groups);
result = table(TrialID, TrialPhase, funcRelevance, fixAbsolute);

% Split data by phase, and functional relevance
p2Durations = groupfilter(result, 'TrialPhase',@(x) x == 2, 'TrialPhase');
p4Durations = groupfilter(result, 'TrialPhase',@(x) x == 4, 'TrialPhase');
p2Durations = splitFunc(p2Durations, trialCol);
p4Durations = splitFunc(p4Durations, trialCol);

% From raw durations, get the relative time spent on each feature per trial
p2Weights = calcProportions(p2Durations);
p4Weights = calcProportions(p4Durations);

% Get list of trial-level stimulus data to join with feature weight data
stimData = unique(subjectTrials(:,{'TrialID' f1 f2 f3 'CorrectResponse' 'Response'}));

output = outerjoin(stimData, p2Weights,'Keys','TrialID',...
    'RightVariables',{'Func1' 'Func2' 'Func3'});
output = outerjoin(output, p4Weights,'Keys','TrialID',...
    'RightVariables',{'Func1' 'Func2' 'Func3'});

% Rename variables
output.Properties.VariableNames = {'TrialID','Feature1Value','Feature2Value','Feature3Value',...
    'CorrectResponse','Response','P2Func1','P2Func2','P2Func3','P4Func1','P4Func2','P4Func3'};

% Convert category names into vector format for modelling scripts
output.CorrectResponse = cat2Vector(output.CorrectResponse, experiment);
output.Response = cat2Vector(output.Response, experiment);

end


%% HELPER FUNCTIONS %%

% Ensures correct experiment argument
function verifyExperiment(expName)
    explist = {'5to1','asset','sshrcif','oris2','oris3','sato2','sato4'};
    
    if ~ismember(expName, explist)
        ME = MException('MyComponent:noSuchVariable', ...
            'Unrecognized experiment name: %s.', expName);
        throw(ME)
    end

end

% Ensures desired subject exists and has good data
function verifySubject(subject, expTable)
    % Handling of case-inconsistency of 'random' column in some data
    if any(strcmp(expTable.Properties.VariableNames,'random'))
        expTable.Properties.VariableNames{'random'} = 'Random';
    end

    subList = expTable(:,{'Subject','GazeDropper','Random'});
    badSubList = subList(subList.GazeDropper == 1 | subList.Random == 1,:);
    badSubList = badSubList.Subject;
    subList = subList(subList.GazeDropper == 0 & subList.Random == 0,:);
    subList = subList.Subject;

    % Gaze dropper or random
    if ismember(subject, badSubList)
        ME = MException('MyComponent:noSuchVariable', ...
            'ERROR: Subject %s found to have bad data.', num2str(subject));
        throw(ME)
    end
    
    % Does not exist
    if ~ismember(subject, subList)
        ME = MException('MyComponent:noSuchVariable', ...
            'ERROR: Subject %s not found.', num2str(subject));
        throw(ME)
    end
end

% Rearranges fixation-level data such that each feature duration gets its own column
function output = splitFunc(fixTable, TrialID)
    TrialID = table(TrialID);
    Func1 = groupfilter(fixTable, 'funcRelevance', @(x) x == 1, 'funcRelevance');
    Func2 = groupfilter(fixTable, 'funcRelevance', @(x) x == 2, 'funcRelevance');
    Func3 = groupfilter(fixTable, 'funcRelevance', @(x) x == 3, 'funcRelevance');

    output = outerjoin(TrialID, Func1,'Keys','TrialID','RightVariables','fixAbsolute');
    output = outerjoin(output,  Func2,'Keys','TrialID','RightVariables','fixAbsolute');
    output = outerjoin(output,  Func3,'Keys','TrialID','RightVariables','fixAbsolute');
    
    output.Properties.VariableNames = {'TrialID','Func1','Func2','Func3'};
    
    % Fill NaNs from trials where some features had 0 fixation duration
    output = fillmissing(output, 'constant',0);
end

% Returns table of proportional fixation durations
function output = calcProportions(fixTable)
    trialSums =  sum(fixTable{:, 2:end}, 2);
    fixTable.Func1 = fixTable.Func1./trialSums;
    fixTable.Func2 = fixTable.Func2./trialSums;
    fixTable.Func3 = fixTable.Func3./trialSums;

    % Fill NaNs arising from division by 0
    output = fillmissing(fixTable, 'constant',0);
end

% Converts category string values into a binary vector
% Sato values overlap with sshrcif (CLPS, QRST) so they are handled
% separately
% E.g. {'A'} -> [1 0 0 0]
function vecColumn = cat2Vector(catColumn, exp)
    vecColumn = cell(1,length(catColumn))';
    
    if strncmpi(exp,'sato',4) %SATO experiments
        for i = 1:length(vecColumn)
        response = catColumn{i};
            switch (response)
                case {'C'}
                    vecColumn{i} = [1,0,0,0];
                case {'L'}
                    vecColumn{i} = [0,1,0,0];
                case {'P'}
                    vecColumn{i} = [0,0,1,0];
                case {'S'}
                    vecColumn{i} = [0,0,0,1];
                otherwise
                    vecColumn{i} = missing;
            end
        end
        
    else % Non-SATO experiments
        for i = 1:length(vecColumn)
        response = catColumn{i};
            switch (response)
                case {'A1','Q', 'A'}
                    vecColumn{i} = [1,0,0,0];
                case {'A2','R', 'B'}
                    vecColumn{i} = [0,1,0,0];
                case {'B1','S', 'C'}
                    vecColumn{i} = [0,0,1,0];
                case {'B2','T', 'D'}
                    vecColumn{i} = [0,0,0,1];
                otherwise
                    vecColumn{i} = missing;
            end
        end
    end
    
end