pathCreation
randseed(467614472);

cd(processeddir)
datafile = dir('*.set');

thres = 45;
%%
parfor mm = 1:length(datafile)
    EEG = pop_loadset(datafile(mm).name, processeddir);
    
    % remove epochs that the reference channels are bad
    EEG = pop_eegthresh(EEG,1,[17, 22] ,-45,45,-0.2,0.798,2,0,0);
    EEG.setname = strcat(num2str(mm),'_thresholed.set'); pop_saveset(EEG, EEG.setname);
    clc;fprintf('Saving files ready for filtering of dataset %d\n',mm);
    %EEG = pop_eegthresh( EEG, icacomp, elecrange, negthresh, posthresh,starttime, endtime, superpose, reject, topcommand);
    EEG = pop_eegthresh(EEG,1,[4:6 8 9:11 13:15 18:21 24:26 29:31] ,-1*thres,thres,-0.2,0.798,2,0,0);
    EEG = pop_rejtrend(EEG,1,1:32,500, [4:6 8 9:11 13:15 18:21 24:26 29:31] ,0.3, 2, 0, 0);
    EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1 );
    EEG = pop_rejepoch( EEG, find(EEG.reject.rejglobal == 1) ,0);
    EEG = pop_reref(EEG, [17 22]);
    pop_saveset(EEG, EEG.setname);
    clc;fprintf('Saving filtered files of dataset %d\n',mm);
end