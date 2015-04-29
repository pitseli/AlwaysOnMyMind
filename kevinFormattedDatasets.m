pathCreation
randseed(467614472);

cd(processeddir)
load('Gabi_Daten_Heavy_Filter.mat');
datafile = dir('*.set');

pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 1, 'option_saveversion6', 1, ...
    'option_single', 1, 'option_memmapdata', 0, 'option_eegobject', 0, ...
    'option_computeica', 1, 'option_scaleicarms', 1, 'option_rememberfolder', 1, ...
    'option_donotusetoolboxes', 0, 'option_checkversion', 1, 'option_chat', 0);

cd(kevindir)

% Relevant ones are on even numbers, irrelevant on odd. Cat on 7
types = {'IU','RU','IK','RK','IS','RS','IC'};
for ii = 1:length(datafile)
    
    EEG = pop_loadset(datafile(ii).name, processeddir);
    fprintf('Loaded dataset %s \n',strrep(datafile(ii).name, '_', ' '))
    
    Data = EEG.data;
    Time = EEG.times;
    
    Label = cell(size(EEG.epoch,2),1);
    for kk=1:size(Label,1)
        Label{kk} = EEG.epoch(kk).eventtype{2};
    end
    
    %%  Use the same ICA weights on all datasets

    ICAdata = (ICAweights*ICAsphere)*Data(EEG.icachansind,:);
    ICAdata = reshape( ICAdata, size(ICAdata,1), EEG.pnts, EEG.trials);

    newname = strrep(datafile(ii).name, '.set', '.mat');
    save(newname,'Data','Time','Label','ICAweights','ICAsphere','ICAdata');
    fprintf('Saved dataset %s \n',newname)
end
disp('Changed them all!! :D')