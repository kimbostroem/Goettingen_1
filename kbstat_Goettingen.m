%% Initilization

%       distribution    Distribution used for the GLM fit.
%                       OPTIONAL, default = 'Normal'.
%                       Possible values:
%                       'normal'	        Normal distribution
%                       'logNormal'         Normal distribution on log-values
%                       'binomial'	        Binomial distribution
%                       'poisson'	        Poisson distribution
%                       'gamma'	            Gamma distribution
%                       'inverseGaussian'	Inverse Gaussian distribution
%
%       link            Link function used for the GLM fit.
%                       OPTIONAL, default depends on chosen distribution.
%                       Possible values:
%                       'identity'	    g(mu) = mu.             Default for Normal distribution.
%                       'log'	        g(mu) = log(mu).        Default for Poisson, Gamma, and InverseGaussian.
%                       'logit'	        g(mu) = log(mu/(1-mu))  Default for Binomial distribution.
%                       'loglog'	    g(mu) = log(-log(mu))
%                       'probit'	    g(mu) = norminv(mu)
%                       'comploglog'	g(mu) = log(-log(1-mu))
%                       'reciprocal'	g(mu) = mu.^(-1)
%                       Scalar p	    g(mu) = mu.^p           Canonical for Gamma (p = -1) and InverseGaussian (p= -2)

%% Init

fprintf('Initializing...\n');

% clear workspace
clear
close all

% restore default path
restoredefaultpath;

% add library and subfolders to path
addpath(genpath('../kbstat'));
resultsDir = '../Statistics';

%% Global options

options = struct;
options.inFile = '../Data_Out/DataTable.csv';
options.id = 'Subject';
options.x = 'Stage, Diagnose';
options.within = 'Stage';
options.interact = '';
options.posthocMethod = 'ttest';
options.removeOutliers = 'true';
options.isRescale = true;
options.errorBars = 'se';

%% Analysis of Motor data

depVars = {'left_hip_maxForce', 'left_knee_maxForce'};
depVarUnitss = {'BW'};
tasks = {'walk', 'squat'};
% distribution = 'gamma';
% link = '';

optionsOrig = options;
if isfield(options, 'constraint')
    constraintOrig = options.constraint;
else
    constraintOrig = '';
end
for iVar = 1:length(depVars)
    depVar = depVars{iVar};
    depVarUnits = depVarUnitss{iVar};
    for iTask = 1:length(tasks)
        task = tasks{iTask};
        if ~isempty(task)
            options.y = depVar;
            if ~isempty(constraintOrig)
                options.constraint = sprintf('%s & Task == %s', constraintOrig, task);
            else
                options.constraint = sprintf('Task == %s', task);
            end
            options.title = sprintf('%s %s', task, depVar);
            options.outDir = sprintf('%s/%s_%s', resultsDir, task, depVar);
        else
            options.y = depVar;
            options.outDir = sprintf('%s/%s', resultsDir, depVar);
        end
        options.yUnits = depVarUnits;
        kbstat(options);
        options = optionsOrig;
    end
end
