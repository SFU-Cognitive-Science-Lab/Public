% Author: Kat kdolguikh@bccfe.ca 
% Date Created: [Mar 19-2021]
% Last Edited: [Apr-03-2021] 
%
%  Cognitive Science Lab, Simon Fraser University 
%  Originally Created For: Feedback 2021
%
%  Reviewed: Tyrus Tracey [Apr-03-2021]
%  Verified: Cynthia Cui [Apr-014-2021]
%
%   PURPOSE: 
%  Format p2/p4 attention data for easier matrix multiplication.
%
%   INPUT: 
%  Subject data retrieved from getFixationWeights.m, 
%  trial phase of interest, and number of stimulus categories in
%  experiment.
%
%   OUTPUT: 
%  Three-dimensional (6 x (2|4) x trials) matrix of feature weight values.
%   - Six rows for F1_0, F1_1, F2_0, F2_1, F3_0, F3_1
%   - 2 or 4 categories as per experiment (repeated weight values for each category)
%   - Number of trials in experiment
%
%   Additional Scripts Used: 
%  None.

function formatted_data = get_attn(dataTable, phase, categories)
    maxTrial = length(dataTable.TrialID);
    
    % Get appropriate gaze data proportions and format into three columns:
    % Proportional time fixated on F1, F2, and F3.
    if phase == 2
        attnTable = [dataTable.P2Func1, dataTable.P2Func2, dataTable.P2Func3];
    elseif phase == 4
        attnTable = [dataTable.P4Func1, dataTable.P4Func2, dataTable.P4Func3];  
    end

    % Initialize the array we are going to output.
    % It is 3D: think of dimensions 1 and 2 as a normal matrix (feature values and category),
    % and dimension 3 as "pages"/"sheets" (trials).
    % So we get one sheet per trial, where the format of the sheet is:
    %
    %                   CATEGORY_A1  CATEGORY_A2  CATEGORY_B1  CATEGORY_B2
    % (f1_start) F1_Val0      
    %        +1  F1_Val1
    % (f2_start) F2_Val0
    %        +1  F2_Val1
    % (f3_start) F3_Val0
    %        +1  F3_Val1
    
    formatted_data = zeros(6, categories, maxTrial);
    
    % Identify base row value for each feature (as shown in above comment)
    feature1_start = 1;
    feature2_start = 3;
    feature3_start = 5;
    
    % Fill in attention data where appropriate.
    % Iterate through each trial and fill its respective sheet.
    for i = 1:maxTrial
            % For each feature, we want to make sure we put the attention weights in the right spot
            % based on the value (0/1) of that feature on that particular trial(see matrix format above)
            
            % We fill in our formatted_data matrix (which will be the output)
            % by referencing our attnTable (where rows are trials, and col1 = f1, col2 = f2, col3 = f3)
            
            % We fill in all 4 columns of each sheet the same way, because category choice
            % does not influence/affect the attention weights
            % output sheets are only 6x4 because that matches the dimensions of our
            % value matrix in the model, and will make multiplication easier  
            
            % Since feature values can be either 0 or 1, if val = 0, we fill in the attention value at
            % the feature start value. 
            % If val = 1, we fill the row below it. (featurex_start + 1)
            formatted_data((feature1_start + dataTable.Feature1Value(i)), :, i) = attnTable(i, 1);
            formatted_data((feature2_start + dataTable.Feature2Value(i)), :, i) = attnTable(i, 2);
            formatted_data((feature3_start + dataTable.Feature3Value(i)), :, i) = attnTable(i, 3);
    end

end
