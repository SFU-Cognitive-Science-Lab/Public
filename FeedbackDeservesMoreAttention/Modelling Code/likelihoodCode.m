%  Likelihood Test comparisons. 
%
%  Author: Mark (based on Kat's code).
%  Date Created: 08/19/2021
%  Last Edit:
%  Cognitive Science Lab, Simon Fraser University
%  Originally Created For: Feedback (model)
%
%  Reviewed:
%  Verified:
%
%  INPUT: None - but you need to run from the folder with the fits. 
%
%  OUTPUT: Saves the liklihoods, test statistics, and pvalues for
%  comparisons of fixed, p2, and p2+p4 model fits. 
%
%  Additional Scripts Used: None
%

% NOTE: pls run from folder that houses your model data
% AND make sure *only* the most recent run of each exp is there


for j=1:4
    Experiments = {'asset','5to1','sato2','sato4', 'oris2', 'oris3'}
    
    % find all data files that include both varying attn parameters
    filename = dir([Experiments{j}, '*.csv']);
    
    maxExp = size(filename, 1);
    
    for i = 1:maxExp
        % get current data file
        expFile = cellstr(filename(i).name);
        expTable = readtable(char(expFile));
        

        % commented out for single bin  ####
%         likelihoods = sum([expTable.likelihood_1, expTable.likelihood_2,...
%             expTable.likelihood_3, expTable.likelihood_4,...
%             expTable.likelihood_5, expTable.likelihood_6]) ;

        % for single bin. 
           likelihoods = sum(expTable.likelihood) ;

        
        fittype = strfind(expFile,'free') ;
        fittype = length(fittype{1}) ;
        
        if fittype == 0
            fixedLikelihoods = likelihoods ;
        else if fittype == 1
                p2freeLikelihoods = likelihoods ;
            else p2p4freeLikelihoods = likelihoods ;
            end
        end
        
        
    end
    
    fixVp2Statistic = fixedLikelihoods - p2freeLikelihoods ;
    p2Vp2p4Statistic = p2freeLikelihoods - p2p4freeLikelihoods ;
    fixVp2_pval = chi2pdf(fixVp2Statistic,1) ;
    p2Vp2p4_pval = chi2pdf(p2Vp2p4Statistic,1) ;
    
    NewResults = table(Experiments(j),fixedLikelihoods,p2freeLikelihoods,p2p4freeLikelihoods,...
        fixVp2Statistic,p2Vp2p4Statistic,fixVp2_pval,p2Vp2p4_pval);
    
    if j == 1
        Results = NewResults;
    else
        Results = [Results; NewResults]
    end
    
   
    writetable(Results,'results.csv')    
    
end