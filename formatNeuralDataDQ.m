
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
fml = load_open_ephys_binary(fullfile('R:\ProjectFolders\Prehension\Data\DaiquiriRightHemisphere\sessions\2023_04_07\neural\recording1', 'structure.oebin'), 'continuous', 1, 'mmap');

rawData.data = fml.Data.Data.mapped;
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

% Write binary data split by probe
outputDir = fullfile(userDir, sessionDate, 'binary_s1');
if exist(outputDir, 'dir') ~= 7; mkdir(outputDir); end
outputPath = fullfile(outputDir, sprintf('raw_%s_%s.bin', probe1Chamber, sessionDate));

fid = fopen(outputPath, 'w');
fwrite(fid, p1Data, 'int16');
fclose(fid);


% Write binary data split by probe
outputDir = fullfile(userDir, sessionDate, 'binary_m1');
if exist(outputDir, 'dir') ~= 7; mkdir(outputDir); end
outputPath = fullfile(outputDir, sprintf('raw_%s_%s.bin', probe2Chamber, sessionDate));

fid = fopen(outputPath, 'w');
fwrite(fid, rawData.data((probe1ChanNum + 1):end, :), 'int16');
fclose(fid);



