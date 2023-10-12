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
itemNr = 1;
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

    for iJoint = 1:nJoints
        joint = joints{iJoint};
        for iSide = 1:nSides
            side = sides{iSide};

            Filename = fname(1:end-9); % remove 'mvnx_out'
            DataStruct(itemNr).Filename = string(Filename);

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
                otherwise
                    error('Unknown task %s', taskStr);
            end

            % Trial
            if isempty(trialStr)
                trial = 1;
            else
                trial = str2double(trialStr(2:end));
            end

            DataStruct(itemNr).Subject = string(subject);
            DataStruct(itemNr).Height = RawData.body.general.height;
            DataStruct(itemNr).Weight = RawData.body.general.weight;
            % subject properties
            subjectProps = {'Sex', 'Age', 'BMI', 'Diagnose', 'AffectedSide'};
            for iProp = 1:length(subjectProps)
                propName = subjectProps{iProp};
                propValue = SubjectTable.(propName)(subjectIdx);
                DataStruct(itemNr).(subjectProps{iProp}) = propValue;
            end
            subjectWeightForce = DataStruct(itemNr).Weight * 9.81;
            subjectSide = DataStruct(itemNr).AffectedSide;
            if ismissing(subjectSide) % if no affected side is given (for healthy controls)
                subjectSide = 'left';
            end

            DataStruct(itemNr).Stage = string(stage);
            DataStruct(itemNr).Task = string(task);
            DataStruct(itemNr).Trial = trial;

            DataStruct(itemNr).Joint = joint;
            DataStruct(itemNr).Side = side;
            if strcmp(side, subjectSide)
                DataStruct(itemNr).RelSide = 'ipsi';
            else
                DataStruct(itemNr).RelSide = 'contra';
            end

            % retrieve joint data
            jointName = sprintf('%s_%s_joint', side, joint);
            jointIdx = strcmp({RawData.signals.joints.name}, jointName);
            if ~any(jointIdx)
                error('No such joint %s', jointName);
            elseif sum(jointIdx) > 1
                error('Too many joints with name %s', jointName);
            end
            signal = RawData.signals.joints(jointIdx).dynamic.jointTotalForce.data;

            depVar = 'maxForce';
            x = vecnorm(signal(:, 1:3), 2, 2);
            DataStruct(itemNr).(depVar) = quantile(x, 0.95) / subjectWeightForce;

            depVar = 'maxForceXY';
            x = vecnorm(signal(:, 1:2), 2, 2);
            DataStruct(itemNr).(depVar) = quantile(x, 0.95) / subjectWeightForce;

            % increment item index
            itemNr = itemNr+1;
        end
    end

    % report progress
    fprintf('\t-> %s (%d/%d = %.1f%% in %.3fs)\n', fname, iFile, nFiles, iFile/nFiles*100, toc);

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
saveTable(DataTable, 'DataTable', {'csv'}, outDir);

% save Measurements structure to MAT file
fprintf('Saving Measurements.mat...\n');
save(fullfile(outDir, 'Measurements.mat'), 'Measurements', '-v7.3');

fprintf('Finished extracting data from %d files into %d data rows %.3f s\n', nFiles, itemNr, toc(ticAll));

diary off;

end