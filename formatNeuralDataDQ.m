
% Params
sessionDate = '2023_04_07';

% Probe params
numProbes = 2;
probe1ChanNum = 64;
probe1Chamber = 'K3';
probe1Loc = 'S1';

probe2ChanNum = 32;
probe2Chamber = 'G6';
probe2Loc = 'M1';

% Directory path
probeDir = 'C://Users/somlab/Desktop/DQ_Demo/ProbeConfigs/';

rawDir = 'R://ProjectFolders/Prehension/Data/DaiquiriRightHemisphere/sessions/';
userDir = 'S://UserFolders/NatalyaShelchkova/Prehension/processed_sessions/';

% Load data
% mmap loads it into a memory cache as oppposed to loading the full data
% in, but once its extracted via x.Data.Data.mapped it exists in memory and
% takes up space -> better to extract data once channels are sorted and
% being split?
fml = load_open_ephys_binary(fullfile(rawDir, sessionDate, 'neural', 'recording1', 'structure.oebin'), 'continuous', 1, 'mmap');

% rawData.data = fml.Data.Data.mapped;
numChannels = size(fml.Header.channels, 1);
for ch = 1:numChannels
    rawData.channelNames{ch, 1} = fml.Header.channels(ch).channel_name;
    rawData.channelID(ch, 1) = str2double(fml.Header.channels(ch).channel_name(3:end));
end

% Load probe data
jsonFile = fileread(fullfile(probeDir, sprintf('%ich_linear_layout.json', probe1ChanNum)));
tmp = jsondecode(jsonFile);

probe1Info.headstageID = cellfun(@str2num, tmp.probes.contact_ids);
probe1Info.electrodeID = tmp.probes.device_channel_indices;

jsonFile = fileread(fullfile(probeDir, sprintf('%ich_linear_layout.json', probe2ChanNum)));
tmp = jsondecode(jsonFile);

probe2Info.headstageID = cellfun(@str2num, tmp.probes.contact_ids) + probe1ChanNum;
probe2Info.electrodeID = tmp.probes.device_channel_indices + probe1ChanNum;

probeInfo.headstageID = [probe1Info.headstageID; probe2Info.headstageID];
probeInfo.electrodeID = [probe1Info.electrodeID; probe2Info.electrodeID];

clear tmp;
%% Check channel order

[tmp, sortedChOrder] = ismember(rawData.channelID', probeInfo.headstageID');
sortedData = rawData.data(sortedChOrder, :);

%% Split data by probe
p1Data = rawData.data(1:probe1ChanNum, :);

% Create meta file
meta.sessionDate = sessionDate;
meta.monkey = 'Daiquiri';
meta.chamberLoc = probe1Chamber;
meta.brainArea = probe1Loc;
meta.dataShape = [probe1ChanNum, fml.Data.Format{2}(2)];
meta.numChannels = probe1ChanNum;
meta.channelInfo.headstageID = probe1Info.headstageID;
meta.channelInfo.channelID = 1:probe1ChanNum;
meta.numSamples = size(fml.Timestamps, 1);
meta.timestamps = fml.Timestamps;

% Create output directory
outputDir = fullfile(userDir, sessionDate, 'binary_s1');
if exist(outputDir, 'dir') ~= 7; mkdir(outputDir); end

% Write metadata info
metafile = fullfile(outputDir, sprintf('raw_%s_%s.json', probe1Chamber, sessionDate));
fid = fopen(metafile, 'w');
fprintf(fid, '%s', jsonencode(meta));
fclose(fid);

% Write binary data split by probe
outputPath = fullfile(outputDir, sprintf('raw_%s_%s.bin', probe1Chamber, sessionDate));

fid = fopen(outputPath, 'w');
fwrite(fid, p1Data, 'int16');
fclose(fid);


% Write binary data split by probe
meta.chamberLoc = probe2Chamber;
meta.brainArea = probe2Loc;
meta.dataShape = [probe2ChanNum, fml.Data.Format{2}(2)];
meta.numChannels = probe2ChanNum;
meta.channelInfo.headstageID = probe2Info.headstageID;
meta.channelInfo.channelID = (probe1ChanNum + 1):96;

outputDir = fullfile(userDir, sessionDate, 'binary_m1');
if exist(outputDir, 'dir') ~= 7; mkdir(outputDir); end

% Write metadata info
metafile = fullfile(outputDir, sprintf('raw_%s_%s.json', probe2Chamber, sessionDate));
fid = fopen(metafile, 'w');
fprintf(fid, '%s', jsonencode(meta));
fclose(fid);

outputPath = fullfile(outputDir, sprintf('raw_%s_%s.bin', probe2Chamber, sessionDate));
fid = fopen(outputPath, 'w');
fwrite(fid, rawData.data((probe1ChanNum + 1):end, :), 'int16');
fclose(fid);



%% Format event data

tmp = load_open_ephys_binary(fullfile(rawDir, sessionDate, 'neural', 'recording1', 'structure.oebin'), 'events', 1);

eventData.numTrials = sum(logical(tmp.FullWords));
eventData.ttlOn = tmp.Timestamps(logical(tmp.FullWords));
eventData.ttlOff = tmp.Timestamps(~logical(tmp.FullWords));

save(fullfile(outputDir, sprintf('eventData_%s_%s.mat', probe2Chamber, sessionDate)), "eventData")





