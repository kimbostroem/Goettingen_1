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
options.id = 'Subject';
options.x = 'Diagnose, RelSide, Task, Joint';
options.within = 'RelSide, Task, Joint';
options.interact = 'Diagnose, RelSide, Task, Joint';
options.removeOutliers = 'true';
options.showVarNames = 3;
options.constraint = 'Joint ~= kneeHip & Stage == t1';
options.separateMulti = 'true';

%% Analysis of Motor data

depVars = {
    'maxForce'
    'maxForceXY'
    };
% depVars = {'maxForce'};
depVarLabels = {
    'Force'
    };
depVarUnitss = {
    'BW'
    };
distributions = {
    'gamma'
    };

optionsOrig = options;
if isfield(options, 'constraint')
    constraintOrig = options.constraint;
else
    constraintOrig = '';
end

%% Analyze multivariate

if exist('depVarLabels', 'var') && length(depVarLabels) == 1
    options.yLabel = depVarLabels{1};
elseif exist('depVarLabels', 'var')
    options.yLabel = depVarLabels{iVar};
end

if exist('depVarUnitss', 'var') && length(depVarUnitss) == 1
    options.yUnits = depVarUnitss{1};
elseif exist('depVarUnitss', 'var')
    options.yUnits = depVarUnitss{iVar};
end

if exist('distributions', 'var') && length(distributions) == 1
    options.distribution = distributions{1};
elseif exist('distributions', 'var')
    options.distribution = distributions{iVar};
end

if exist('links', 'var') && length(links) == 1
    options.link = links{1};
elseif exist('links', 'var')
    options.link = links{iVar};
end

options.y = depVars;
options.outDir = sprintf('%s', resultsDir);

kbstat(options);
% reset options to original state
options = optionsOrig;

% %% Analyze separate univariate 
% 
% for iVar = 1:length(depVars)
%     depVar = depVars{iVar};
% 
%     if length(depVarLabels) == 1
%         options.yLabel = depVarLabels{1};
%     else
%         options.yLabel = depVarLabels{iVar};
%     end
% 
%     if length(depVarUnitss) == 1
%         options.yUnits = depVarUnitss{1};
%     else
%         options.yUnits = depVarUnitss{iVar};
%     end
% 
%     if exist('distributions', 'var') && length(distributions) == 1
%         options.distribution = distributions{1};
%     elseif exist('distributions', 'var')
%         options.distribution = distributions{iVar};
%     end
%     if exist('links', 'var') && length(links) == 1
%         options.link = links{1};
%     elseif exist('links', 'var')
%         options.link = links{iVar};
%     end
% 
%     if ~isempty(constraintOrig)
%         options.constraint = sprintf('%s & Stage == t1', constraintOrig);
%     else
%         options.constraint = sprintf('Stage == t1');
%     end
% 
%     options.y = depVar;
%     options.outDir = sprintf('%s/%s', resultsDir, depVar);
% 
% 
%     kbstat(options);
%     % reset options to original state
%     options = optionsOrig;
% end
