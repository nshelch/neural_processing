%% Split data by trial
    E(rec) = load_open_ephys_binary(fullfile(neural_dirs(rec).folder, neural_dirs(rec).name, 'structure.oebin'), 'events', 1);



% Save data for sorting