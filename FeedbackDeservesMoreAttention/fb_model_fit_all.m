%  fit feedback attention model (2021) to get free parameters
%  
%  Author: Kat kdolguikh@bccfe.ca 
%  Date Created: 02/20/2021
%  Last Edit: Nov 19, 2021 (Kat)
%  Cognitive Science Lab, Simon Fraser University 
%  Originally Created For: Feedback (model)
%  
%  Reviewed: Cynthia [04/15/2021]
%  Verified: Tyrus Tracey [Apr-15-2021] 
%  
%  INPUT: 
%       exp: experiment name
%       p2_vary: should p2 attention be a free parameter in the model, or be fixed at 0?
%            IF FIXED: 0
%            IF VARYING: 1
%        p4_vary: should p4 attention be a free parameter in the model, or be fixed at 0?
%            IF FIXED: 0
%            IF VARYING: 1
            
%  
%  OUTPUT: likelihood, optimized free parameters, and fit statistics for every subject in experiment
%       eta: learning rate (for eq. 3)
%       beta: scaling parameter (for eq. 4)
%       p2_attn: importance of p2 attention allocation (better word than "importance"? Idk)
%       p4_attn: importance of p4 attention allocation
%  
%  Additional Scripts Used: ACLpredictions.m, getFixationWeights.m
%  
%  Additional Comments: 
%       PLEASE RUN THIS SCRIPT FROM THE FOLDER WHERE YOU KEEP YOUR DATA
%       fminsearchbnd is a version of fminsearch that allows you to set upper and lower bounds on the free parameters
%       if you don't have it already, you will need to download from: https://www.mathworks.com/matlabcentral/fileexchange/8277-fminsearchbnd-fminsearchcon
% 
%       you will also need to add the folder where you save it to the matlab path before running this script
%       addpath('{INSERT FOLDER LOCATION HERE}')


function [experiment_params] = fb_model_fit_all(exp, p2_vary, p4_vary)

    % check for valid input
    if p2_vary ~= 0 && p2_vary ~= 1
        ME = MException('MyComponent:noSuchVariable', ...
            'Invalid P2 attention value');
        throw(ME)
    end
    
     if p4_vary ~= 0 && p4_vary ~= 1
        ME = MException('MyComponent:noSuchVariable', ...
            'Invalid P4 attention value');
        throw(ME)
     end   
     
     % set name for output file
     if p2_vary == 1
        p2_name = 'p2_free_'; 
     else
        p2_name = 'p2_fixed_';
     end
     
     if p4_vary == 1
         p4_name = 'p4_free_';
     else
         p4_name = 'p4_fixed_';
     end
     
     vsn = [p2_name, p4_name];

    % useable experiments include [sato2; sato4; asset; 5to1; sshrcif; oris2 oris3]
   
    eta0 = 0.3; % learning rate
    beta0 = 10;  % maximizing
    p20 = 0.2;     
    p40 = 0.2;       

    p20 = p20 * p2_vary; % if p2_vary = 1, p20 = 0.5. if p2_vary = 0, p20 = 0;
    p40 = p40 * p4_vary; % if p4_vary = 1, p40 = 0.5. if p4_vary = 0, p40 = 0;
    x0 = [eta0, beta0, p20, p40];
    
    % minimum number of trials in completed experiment
    % minimum in asset is actually 85 (CP = 13), but I figured 100 would be better?
    maxTrial = 120;
    numBlocks = ceil(maxTrial/120); % <- changed to be a single bin ####
    
    
    % get current directory (should be where your data is kept!)
    dir = [pwd(), '/'];

    explvl = load([dir, exp, '/explvl.mat']);
    triallvl = load([dir, exp, '/triallvl.mat']);

    explvl = explvl.explvl;
    triallvl = triallvl.triallvl;
    
    first120 = triallvl(triallvl.TrialID < 121 , :);
    % the first 26 subjects in sato are missing response info, so filter out the missing ones
    if strncmp(exp, "sato", 4) == 1
        explvl = explvl(explvl.GazeDropper == 0 & explvl.random == 0 & explvl.Subject > 4028, :);
    else
        explvl = explvl(explvl.GazeDropper == 0 & explvl.random == 0, :);
    end
   
    Subject = explvl.Subject;
    
    categories = length(unique(cell2mat(triallvl.CorrectResponse)));
    
    % initialize values for output;
    % these will all be matrices. in the final table, each variable will actually contain one column for each block
    eta = zeros(length(Subject), numBlocks);
    beta = zeros(length(Subject), numBlocks);
    p2_attn = zeros(length(Subject), numBlocks);
    p4_attn = zeros(length(Subject), numBlocks);
    likelihood = zeros(length(Subject), numBlocks);
    iterations = zeros(length(Subject), numBlocks);
    flag = zeros(length(Subject), numBlocks);
    
    errors = zeros(length(Subject), 1);
    
    disp(['FITTING EXPERIMENT: ', exp])
    
    disp('Seed values:')
    disp(x0)

   for i = 1:length(Subject)
        fprintf('Fitting subject %d\n', Subject(i))
        subjectTrials = triallvl.TrialID(triallvl.Subject == Subject(i));
        
       for j = 1:numBlocks
            fprintf('  - Block %2d: Trials %3d -%3d\n', j, 20*(j-1), 20*j)
            trials = subjectTrials(subjectTrials > 120*(j-1) & subjectTrials <= 120*j);  % <-- changed to bins of 120
            % if last participant trial was before the start of 6th block, skip running the model;
            if isempty(trials)
                eta(i, j) = NaN;
                beta(i, j) = NaN;
                p2_attn(i, j) = NaN;
                p4_attn(i, j) = NaN;
                likelihood(i, j) = NaN;
                iterations(i, j) = NaN;
                flag(i, j) = NaN;
                break;
            end
        
            % this allows us to set some of the input values to fit_fb (subject and exp)
            % so that fminsearch only tries to optimize the actual free parameters
            fit_for_subject = @(p)fit_fb(p, Subject(i), exp, trials, categories);

            % inputs to fminsearchbnd: function, seed values, lower bounds, upper bounds
            % bounds are in same order as input parameters i.e. eta, beta, p2, p4
            % eta: [-inf, inf] (no bounds)
            % beta: [0, inf] (must be a positive value)
            % p2: [0, 1] (if varying), [0, 0] if fixed
            % p4: [0, 1] (if varying), [0, 0] if fixed
            % p2_vary, p4_vary  = 1 if varying, 0 if fixed
            
            [x,fval,exitflag,output] = fminsearchbnd(fit_for_subject,x0, [-inf 0 0 0], [inf inf p2_vary p4_vary]);

            % format for output table 
             eta(i, j) = x(1);
             beta(i, j) = x(2);
             p2_attn(i, j) = x(3);
             p4_attn(i, j) = x(4);
             likelihood(i, j) = fval;
             iterations(i, j) = output.iterations;
             flag(i, j) = exitflag;
        end
        
        subjectErrors = 1 - first120.TrialAccuracy(first120.Subject == Subject(i));
        errors(i) = sum(subjectErrors);
    end
    
     experiment = repmat(exp, length(Subject), 1); 
     seed_eta = repmat(x0(1), length(Subject), 1);
     seed_beta = repmat(x0(2), length(Subject), 1);
     seed_p2 = repmat(x0(3), length(Subject), 1);
     seed_p4 = repmat(x0(4), length(Subject), 1);
     
     % get extra info from exp level table;
     learner = explvl.Learner;
     condition = repmat("", height(explvl), 1);

     
     % asset is missing here bc we will leave condition blank for asset
     switch exp
         case '5to1'
            condition(explvl.SubjectCondition == 0) = "5:1";
            condition(explvl.SubjectCondition == 1) = "1:1";
         case 'sshrcif'
             condition(explvl.SubjectCondition == 6) = "62.5%";
             condition(explvl.SubjectCondition == 8) = "87.5%";
             condition(explvl.SubjectCondition == 1) = "100%";
         case 'sato2'
             condition = string(explvl.SubjectCondition);
         case 'sato4'
             condition = string(explvl.SubjectCondition);
         case 'feedback2'
             condition = string(explvl.FeedbackDuration);
         case 'feedback3'
             condition = string(explvl.FeedbackDuration);
     end
    
     experiment_params = table(experiment, Subject, condition, learner, errors, eta, beta, p2_attn, p4_attn, likelihood, flag, iterations, seed_eta, seed_beta, seed_p2, seed_p4);
     
     writetable(experiment_params,[exp, '_model_fit_', vsn, date,'.csv']);

end


function goodness_of_fit = fit_fb(parameters, subjectNum, exp, trials, categories)   %for now parameters[1] is eta, parameters[2] is beta

    % get model predictions
    [model_predictions, subject_choices] = ACLpredictions(parameters, subjectNum, exp, trials, categories);    

    % likelihood that model picks the category that participant picked 
    % so we only keep the model probabilities for the category the participant chose on each trial
    
    % not sure if it actually matters (probably not), but may be easier for verification:
    % by transposing the multiplied model predictions * subject choices, the result of
    % nonzeros will give the likelihoods in order of trial. 
    % the nonzeros function goes column by column, so say you had model predictions .* subject choices
    % = 0.5 0
    %   0   0.35
    %   0   0.6
    %   0.4 0 
    % 
    % ... ; instead of the expected [0.5, 0.35, 0.6, 0.4], which is what would make sense,
    % the non-transposed (without the ') would give you [0.5, 0.4, 0.35, 0.6]
    % which I think doesn't matter since we are taking the sum, but I like it better in the sensible order -Kat
    model_choices_correct_cat = nonzeros((model_predictions.*subject_choices)');

    % negative log likelihood;
    goodness_of_fit = sum(-2*log(model_choices_correct_cat));
end
