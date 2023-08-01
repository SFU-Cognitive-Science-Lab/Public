%  visualizations for feeback model (using both p2 and p4 attention)u
%  
%  Author: Kat kdolguikh@bccfe.ca 
%  Date Created: 08/12/2021
%  Last Edit: 11/05/21 changing axis label
%  Cognitive Science Lab, Simon Fraser University 
%  Originally Created For: Feedback (model)
%  
%  Reviewed: 
%  Verified: 
%  
%  INPUT: 
            
%  
%  OUTPUT: nothing, but produces and saves some figures
%  
%  Additional Scripts Used:
%
%
%
% NOTE: pls run from folder that houses your model data
% AND make sure only the most recent run of each exp is there


function [] = fb_model_vis()

    % find all data files that include both varying attn parameters 
    filename = dir('*_model_fit_p2_free_p4_free*.csv');
   
    maxExp = size(filename, 1);
    
    % we split every experiment into 6 bins of 20;
    bins = 6;
    
    for i = 1:maxExp
        % get current data file
        expFile = cellstr(filename(i).name);
        
        expTable = readtable(char(expFile));
        
        % all csvs have the same columns. 18-23 are p2 attention (bin 1-6 in order), 24-29 are p4 attention (bin 1-6 in order)
        expMeansPrep = table2array(expTable(:, 18:29));
        
        % get means and standard error of the mean (for error bars)
        expMeans = mean(expMeansPrep);
        expSem = std(expMeansPrep)./sqrt(length(expMeansPrep));
        
        % divide p2 and p4
        p2Means = expMeans(:, 1:6);
        p4Means = expMeans(:, 7:12);
        
        p2ErrorBar = expSem(:, 1:6);
        p4ErrorBar = expSem(:, 7:12);
        
        % create figure: we need to stack 4 figures here (2 for p2, 2 for p4):
        % we want thicker lines for the data than the error bars, so we stack plot() with errorbar()
        % using two different line widths, as there is no way within errorbar() to do that
        errorbar(p2Means, p2ErrorBar, 'b');
        xlim([0 7]);
        ylim([0 1]);
        hold on
        errorbar(p4Means, p4ErrorBar, 'r');
        
        plot(p2Means, 'b', 'LineWidth', 1.5);
        plot(p4Means, 'r', 'LineWidth', 1.5);
        
        legend('Response phase attention', 'FB phase attention');
        xlabel('Experiment block');
        ylabel('Mean fitted value of attention parameter');
        
       % figtitle = char(strcat('Importance of attention in model: ', expTable.experiment(1)));
        
       % title(figtitle);
        
        savename = char(strcat(expTable.experiment(1), '_attn_importance.png'));
        
        saveas(gca, savename);
        
        close all;
        
    end


end