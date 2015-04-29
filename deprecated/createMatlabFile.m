EEG = pop_loadset('ICA_cleaned_referenced_epoched.set');

Data = EEG.data;
Time = EEG.times;
for i=1:size(EEG.epoch,2)
    Label{i} = EEG.epoch(i).eventtype{2};
end
ICAweights = EEG.icaweights;
ICAsphere = EEG.icasphere;
ICAdata = EEG.icaact;
clear A ALLCOM ALLEEG ans CURRENTSET CURRENTSTUDY EEG eeglabUpdater hmenu i LASTCOM PLUGINLIST STUDY tmp
