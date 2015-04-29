pathCreation
randseed(467614472);

cd(processeddir)
datafile = dir('*.set');
disp('Run ICA')

pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 1, 'option_saveversion6', 1, ...
    'option_single', 1, 'option_memmapdata', 0, 'option_eegobject', 0, ...
    'option_computeica', 1, 'option_scaleicarms', 1, 'option_rememberfolder', 1, ...
    'option_donotusetoolboxes', 0, 'option_checkversion', 1, 'option_chat', 0);

ndim = size(datafile,1);
%% Run ICA for every set and update it
parfor mm = 1:ndim
    fprintf('Attempting to load dataset %d of %d %s\n',mm, ndim, datafile(mm).name)
    EEG = pop_loadset(datafile(mm).name, processeddir);
    fprintf('Attempting to run ica for dataset %d of %d %s\n',mm, ndim, datafile(mm).name)
    EEG = pop_runica(EEG, 'extended',1,'interupt','off');
    fprintf('Attempting to save dataset %d of %d %s\n',mm, ndim, datafile(mm).name)
    pop_saveset(EEG, EEG.setname);
    clc;fprintf('--------------------- DONE %d of %d ---------------------------\n',mm,ndim)
end
disp('I am out')
