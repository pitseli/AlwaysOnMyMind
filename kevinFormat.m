function kevinFormat(EEG)
pathCreation

cd(processeddir)
fprintf('Loaded dataset %s \n',strrep(EEG.setname, '_', ' '))

Data = EEG.data;
Time = EEG.times;
Label = cell(size(EEG.epoch,2),1);
for kk=1:size(Label,1)
    Label{kk} = EEG.epoch(kk).eventtype{2};
end
ICAweights = EEG.icaweights;
ICAsphere = EEG.icasphere;
ICAdata = EEG.icaact;
newname = strrep(datafile(mm).name, '.set', '.mat');
cd(kevindir)
save(newname,'Data','Time','Label','ICAweights','ICAsphere','ICAsphere')
fprintf('Saved dataset %s \n',strrep(newname, '_', ' '))
end