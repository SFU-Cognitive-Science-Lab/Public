%  feedback model data table for manuscript
%  
%  Author: Kat kdolguikh@bccfe.ca 
%  Date Created: 11/05/2021
%  Last Edit: 
%  Cognitive Science Lab, Simon Fraser University 
%  Originally Created For: Feedback (model)
%  
%  Reviewed: 
%  Verified: 
%  
%  INPUT: nothing
            
%  
%  OUTPUT: model_table (also saved as a .csv), formatted for the manuscript
%  
%  Additional Scripts Used:
%
%
%
% NOTE: pls run from folder that houses your model data
% AND make sure only the most recent run of each exp is there


function model_table = fb_table()
    
    model_prep = [];

    for j = ["asset", "5to1", "sato2", "sato4"]
    
        filename = dir(strcat(j, '*.csv'));

        maxFile = size(filename, 1);

        this_model = [];

         for i = 1:maxFile

            mFile = cellstr(filename(i).name);
            mTable = readtable(char(mFile));

            if mTable.seed_p2(1) == 0 model = "null";
            elseif mTable.seed_p4(1) ~= 0 model = "fb";
            elseif mTable.seed_p4(1) == 0 model = "nofb";
            end

            working = [mTable.likelihood_1, mTable.likelihood_2, mTable.likelihood_3, mTable.likelihood_4, mTable.likelihood_5, mTable.likelihood_6];
            expMeans = mean(working);
            
            this_model = [this_model; [expMeans, model]];
        
         end
        
        % expand this_model to correct format;
        % sort in order of model
        exp_sorted = sortrows(this_model, 7);
        
        this_exp = [j, exp_sorted(:, 1)', exp_sorted(:, 2)', exp_sorted(:, 3)', exp_sorted(:, 4)', exp_sorted(:, 5)', exp_sorted(:, 6)'];
        
        model_prep = [model_prep; this_exp];
     end
     
     % change matrix to table
     model_table = array2table(model_prep);
     model_table.Properties.VariableNames(1:19) = {'Experiment', 'FBR_block1', 'R_block1', 'NULL_block1', 'FBR_block2', 'R_block2', 'NULL_block2', 'FBR_block3', 'R_block3', 'NULL_block3', 'FBR_block4', 'R_block4', 'NULL_block4', 'FBR_block5', 'R_block5', 'NULL_block5', 'FBR_block6', 'R_block6', 'NULL_block6'};

     writetable(model_table, 'manuscript_table.csv');
     
end