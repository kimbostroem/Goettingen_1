function makeData()

%% Init

fprintf('Initializing...\n');

% clear workspace
clear
% close all open figures
close all

% set folders
outDir = '../Data_Out';
inDir = '../Data_In';
motorDir = fullfile(inDir, 'Measurements');
paramDir = fullfile(inDir, 'Meta');

% create output folder if necessary
if ~isfolder(outDir)
    mkdir(outDir);
end

% restore default path
restoredefaultpath;
% add library and subfolders to path
addpath(genpath('library'));

diary(fullfile(outDir,'log.txt'));

fprintf('\nMaking Motor Data...\n');

Measurements = struct();


%% Subjects
SubjectTable = readtable(fullfile(paramDir, 'Subjects.xlsx'), 'TextType','string');
% delete excluded subjects
idx = (SubjectTable.Excluded == 1);
SubjectTable(idx,:) = [];
% delete "Excluded" and "WhyExcluded" columns
SubjectTable.Excluded = [];
SubjectTable.WhyExcluded = [];
subjects = cellstr(SubjectTable.Subject);
Measurements.SubjectTable = SubjectTable;

joints = {'hip', 'knee'};
sides = {'left', 'right'};
nJoints = length(joints);
nSides = length(sides);

% list content of input folder into cell array
dirInfo = dir(fullfile(motorDir, '*.mat'));
fdirs = {dirInfo.folder}';
fnames = {dirInfo.name}';
idxExclude = startsWith(fnames', {'.', '~'}) | [dirInfo.isdir];
fnames(idxExclude) = [];
fdirs(idxExclude) = [];

fprintf('Extract measurement data...\n');
ticAll = tic;

[~, fnames, fexts] = fileparts(fnames);
fpaths = strcat(fdirs, filesep, fnames, fexts);

nFiles = length(fpaths);
% nFiles = 10;
fileNr = 1; % init file index to end of already loaded files
DataStruct = struct([]);
for iFile = 1:nFiles
    fpath = fpaths{iFile};
    [~, fname, ~] = fileparts(fpath);
    tic

    tokens = regexpi(fname, '(\d+)(a)?_(\d+)_(\d+)(_\d+)?([\w-]*)', 'tokens');
    parts = tokens{1};
    subjectStr = parts{1};
    subjectStr2 = parts{2};
    stageStr = parts{3};
    taskStr = parts{4};
    trialStr = parts{5};
    if ~isempty(subjectStr2)
        subject = sprintf('C%s',subjectStr);
    else
        subject = sprintf('P%s',subjectStr);
    end
    [subjectIdx, ~] = find(strcmp(subjects, subject));
    if isempty(subjectIdx)
        fprintf('\t%s:\tNo subject with code ''%s'' -> skipping\n', fname, subjectCode);
        continue
    end

    Filename = fname(1:end-9); % remove 'mvnx_out'
    DataStruct(fileNr).Filename = string(Filename);

    % load data
    tmp = load(fpath);
    fields = fieldnames(tmp);
    RawData = tmp.(fields{1});

    % Stage
    stage = sprintf('t%s', stageStr);

    % Task
    switch taskStr
        case '1'
            task = 'walk';
        case '2'
            task = 'squat';
        case '3'
            task = 'sit';
        case '4'
            task = 'stair';
        otherwise
            error('Unknown task %s', taskStr);
    end

    % Trial
    if isempty(trialStr)
        trial = 1;
    else
        trial = str2double(trialStr(2:end));
    end

    DataStruct(fileNr).Subject = string(subject);
    DataStruct(fileNr).Height = RawData.body.general.height;
    DataStruct(fileNr).Weight = RawData.body.general.weight;
    % subject properties
    subjectProps = {'Sex', 'Age', 'BMI', 'Diagnose'};
    for iProp = 1:length(subjectProps)
        propName = subjectProps{iProp};
        propValue = SubjectTable.(propName)(subjectIdx);
        DataStruct(fileNr).(subjectProps{iProp}) = propValue;
    end
    subjectWeight = DataStruct(fileNr).Weight;

    DataStruct(fileNr).Stage = string(stage);
    DataStruct(fileNr).Task = string(task);
    DataStruct(fileNr).Trial = trial;

    for iJoint = 1:nJoints
        joint = joints{iJoint};
        for iSide = 1:nSides
            side = sides{iSide};
            jointName = sprintf('%s_%s_joint', side, joint);
            jointIdx = strcmp({RawData.signals.joints.name}, jointName);
            if ~any(jointIdx)
                error('No such joint %s', jointName);
            elseif sum(jointIdx) > 1
                error('Too many joints with name %s', jointName);
            end
            signal = RawData.signals.joints(jointIdx).dynamic.jointTotalForce.data;
            
            depVar = sprintf('%s_%s_maxForce', side, joint);
            x = vecnorm(signal(:, 1:3), 2, 2);            
            DataStruct(fileNr).(depVar) = quantile(x, 0.95) / subjectWeight;            
            depVar = sprintf('%s_%s_medForce', side, joint);
            x = vecnorm(signal(:, 1:3), 2, 2);            
            DataStruct(fileNr).(depVar) = quantile(x, 0.5) / subjectWeight;
            
            depVar = sprintf('%s_%s_maxForceXY', side, joint);
            x = vecnorm(signal(:, 1:2), 2, 2);            
            DataStruct(fileNr).(depVar) = quantile(x, 0.95) / subjectWeight;            
            depVar = sprintf('%s_%s_medForceXY', side, joint);
            x = vecnorm(signal(:, 1:2), 2, 2);            
            DataStruct(fileNr).(depVar) = quantile(x, 0.5) / subjectWeight;
            
            depVar = sprintf('%s_%s_maxForceZ', side, joint);
            x = vecnorm(signal(:, 3), 2, 2);            
            DataStruct(fileNr).(depVar) = quantile(x, 0.95) / subjectWeight;            
            depVar = sprintf('%s_%s_medForceZ', side, joint);
            x = vecnorm(signal(:, 3), 2, 2);            
            DataStruct(fileNr).(depVar) = quantile(x, 0.5) / subjectWeight;
        end
    end

    % hip to knee ratio
    for iSide = 1:nSides       
        hipIdx = strcmp({RawData.signals.joints.name}, [side, '_hip_joint']);
        kneeIdx = strcmp({RawData.signals.joints.name}, [side, '_knee_joint']);
        hipSignal = RawData.signals.joints(hipIdx).dynamic.jointTotalForce.data;
        kneeSignal = RawData.signals.joints(kneeIdx).dynamic.jointTotalForce.data;
        x = (vecnorm(hipSignal, 2, 2) ./ vecnorm(kneeSignal, 2, 2))';        
        depVar = [side, '_knee2Hip_maxForceRatio'];
        DataStruct(fileNr).(depVar) = quantile(x, 0.95);
        depVar = [side, '_knee2Hip_medForceRatio'];
        DataStruct(fileNr).(depVar) = quantile(x, 0.5);
    end


    % report progress
    fprintf('\t-> %s (%d/%d = %.1f%% in %.3fs)\n', fname, iFile, nFiles, iFile/nFiles*100, toc);

    % increment number of processed files
    fileNr = fileNr+1;
end

DataTable = struct2table(DataStruct);
Measurements.DataTable = DataTable;

% export Measurements structure to base workspace
assignin('base', 'Measurements', Measurements);

% save subject table 
fprintf('Saving Subject table...\n');
saveTable(SubjectTable, 'SubjectTable', {'xlsx'}, outDir);

% save Data table 
fprintf('Saving Data table...\n');
saveTable(DataTable, 'DataTable', {'csv', 'xlsx'}, outDir);

% save Measurements structure to MAT file
fprintf('Saving Measurements.mat...\n');
save(fullfile(outDir, 'Measurements.mat'), 'Measurements', '-v7.3');

fprintf('Finished extracting data from %d files in %.3f s\n', fileNr, toc(ticAll));

diary off;

end