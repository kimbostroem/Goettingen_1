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
%                       'identity'	    g(mu) = mu.             Default for Normal distribution
%                       'log'	        g(mu) = log(mu).        Default for Poisson
%                       'logit'	        g(mu) = log(mu/(1-mu))  Default for Binomial distribution
%                       'loglog'	    g(mu) = log(-log(mu))
%                       'probit'	    g(mu) = norminv(mu)
%                       'comploglog'	g(mu) = log(-log(1-mu))
%                       'reciprocal'	g(mu) = mu.^(-1)        Default for Gamma
%                       Scalar p	    g(mu) = mu.^p           Default for InverseGaussian (p= -2)

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
options.outDir = resultsDir;
options.id = 'Subject';
options.x = 'Diagnose, RelSide, Task, Joint';
options.within = 'RelSide, Task, Joint';
options.interact = 'Diagnose, RelSide, Task, Joint';
options.fitMethod = 'REMPL';
% options.posthocMethod = 'utest';
options.outlierMethod = 'auto';
options.removeOutliers = 'prepost';
options.showVarNames = 3;
options.constraint = 'Joint ~= kneeHip & Stage == t1';
options.separateMulti = 'true';
% options.transform = 'q50';

%% Analysis

options.y = {
    'maxForce'
    'maxForceXY'
    };
% depVars = {'maxForce'};
options.yLabel = {
    'Force'
    'Force'
    };
options.yUnits = {
    'BW'
    'BW'
    };
options.distribution = {
    'gamma'
    };

kbstat(options);

