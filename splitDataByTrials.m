close all; clear; clc;

baseDir = 'S:\UserFolders\NatalyaShelchkova\Prehension\processed_sessions';
sessionDate = '2023_04_07';
brainLoc = 'm1';
dataDir = fullfile(baseDir, sessionDate, strcat('binary_', brainLoc));

dataFilename = 'raw_G6_2023_04_07.bin';
datasource = fullfile(dataDir, dataFilename);

metaFilename = 'raw_G6_2023_04_07.json';

% Load meta data -> fix this
metafile = fileread(fullfile(dataDir, metaFilename));
meta = jsondecode(metafile);

% Load neural data
data = fread(fopen(datasource, 'r'), meta.dataShape, '*int16'); 

% Load event data
load(fullfile(dataDir, 'eventData_G6_2023_04_07.mat'))

%% Split data by trial

splitTrials = 0:50:284; splitTrials(1) = 1; splitTrials(end + 1) = eventData.numTrials;

for bb = 1:length(splitTrials) - 1
    if bb == 1
        startTime = eventData.ttlOn(splitTrials(bb)); % start of first trial in block
    else
        startTime = eventData.ttlOn(splitTrials(bb) + 1); % so trials arent overlapping between blocks
    end
    endTime = eventData.ttlOff(splitTrials(bb + 1)); % end of last trial in block

    dataIdx = find(meta.timestamps >= startTime & meta.timestamps <= endTime);

    % Apply filters -> test in offline sorter first
    [b, a] = butter(1, [600 6000]/(30000/2), 'bandpass');
    tmp = filtfilt(b, a, double(data(:, dataIdx)));

    % Save data
    outputPath = fullfile(dataDir, sprintf('raw_trial_%i-%i_%s_%s.bin', splitTrials(bb) + 1, splitTrials(bb + 1), meta.chamberLoc, sessionDate));
    % outputPath = fullfile('./', sprintf('raw_trial_%i-%i_%s_%s.bin', splitTrials(bb), splitTrials(bb + 1), meta.chamberLoc, sessionDate));

    fid = fopen(outputPath, 'w');


    % fwrite(fid, data(:, dataIdx), 'int16');
    fclose(fid);
end