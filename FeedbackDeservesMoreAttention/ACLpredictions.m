% AUTHOR: Cynthia Cui & Kat kdolguikh@bccfe.ca
% DATE CREATED: February 13, 2021
% LAST EDITED: Nov 19, 2021 -Kat

% Cognitive Science Lab at Simon Fraser Univeristy
% CREATED FOR: Feedback 2021
%
% REVIEWED: [Apr-10-2021] Tyrus Tracey
% VERIFIED:
%
% PURPOSE: 
% Output modelled attention to features like in Leong et al. 2019, based on
% participant gaze data.
%
% INPUT: 
%   - free parameters used in calculations (eta, beta, p2, p4 importance)
%   - subject number
%   - experiment name string
%   - vector of trialIDs of desired block
%   - number of categories in experiment
%
% OUTPUT:
%   - modelPredictions: matrix of model predicitons (probabilities) for each trial for one subject
%   - subjectChoices: actual category selections made by participant
%
% Additional Scripts Used: 
%   - getFixationWeights.m
%   - get_attn.m

function [modelPredictions, subjectChoices] = ACLpredictions(freeParams, subjectNum, experiment, trials, categories)
    ETA = freeParams(1);
    BETA = freeParams(2);
    P2WEIGHT = freeParams(3);
    P4WEIGHT = freeParams(4);

    % Pull subject data
    subjectData = getFixationWeights(experiment, subjectNum);
    subjectData(subjectData.TrialID < trials(1) | subjectData.TrialID > trials(end), :) = [];

    % if it's a 2 category experiment, delete some columns;
    CorrectResponses = cell2mat(subjectData.CorrectResponse);
    subjectChoices = cell2mat(subjectData.Response);
    if categories == 2
        subjectChoices(:, all(CorrectResponses == 0)) = [];
        CorrectResponses(:, all(CorrectResponses == 0)) = [];
    end
    
    % To be used in filtering trial-by-trial stimulus data
    feature_rowIndices = [1, 3, 5];
    trial_features = [subjectData.Feature1Value, subjectData.Feature2Value, subjectData.Feature3Value];
    
    % Initialize output matrix
    modelPredictions = [];

    % Initialize model value matrix
    updateMatrix = repmat(0.5, 6, categories);
    
    % Format subject data for attention weights
    p2attn = get_attn(subjectData, 2, categories);
    p4attn = get_attn(subjectData, 4, categories);
    
    % If attention doesn't matter, assume everything is looked at equally
    attn_base = repmat((1/3), 6, categories);
    
    % Loop through trials like a participant does
    for trial = 1:length(subjectData.TrialID)
        % Initialize matrix representing displayed features for trial
        % Only weights for displayed features will be adjusted
        onscreen = zeros(6, categories);
        
        % This gives us the difference between "base" or "unimportant" attention and the actual subject data
        % This difference is what will be adjusted based on the p2 and p4 free parameters:
        % If the parameter = 0, then the difference will = 0 and all attention will be 1/3 to each feature
        
        % part of attention weighting from equation 4 and 6
        p2attn_adjusted = p2attn(:, :, trial) - attn_base;
        p4attn_adjusted = p4attn(:, :, trial) - attn_base;
        
        % identify which features were actually onscreen
        for i = 1:3
           onscreen((feature_rowIndices(i) + trial_features(trial, i)), :) = 1; 
        end
        
        % EQUATION 1 and 2:
        % Get value for each category 
        % If there is no attention data, then attn_base and p2attn_adjusted
        % needs to cancel out, so we do not set a P2Weight value
        if sum(p2attn(:,:,trial)) == 0
            value_per_feature = onscreen .* updateMatrix;
        else
            value_per_feature = (attn_base + (p2attn_adjusted*P2WEIGHT)).*onscreen .* updateMatrix;
        end
        
        category_values = sum(value_per_feature);
        
        % EQUATION 3:
        % converting value matrix to probability values (using softmax action selection rule)
        category_choices = sm(category_values, BETA);
 
        % Append result to model prediction output
        modelPredictions = [modelPredictions; category_choices];

        % EQUATION 4:
        % Calculate prediction error: the difference between observed rewards
        % and expected value of chosen category
        predictionError = repmat((CorrectResponses(trial, :) - category_choices), 6, 1);

        % EQUATION 5 & 6:
        % update model using predictionError 
        change_this_trial = ((attn_base + (p4attn_adjusted*P4WEIGHT))*ETA).*onscreen.*predictionError;

        updateMatrix = updateMatrix + change_this_trial;
        
    end
end

% Softmax calculation for Equation 3
function cat_choices = sm(values, beta)
    denom = sum(exp(beta*values));
    cat_choices = (exp(beta*values))/denom;
end
