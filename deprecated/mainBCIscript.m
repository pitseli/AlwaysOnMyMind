%% CONSTANTS
pathCreation
randseed(467614472);

subjnum = 0;
infile = '103.vhdr';

% load data, set channels
EEG = pop_loadbv(indir, infile);
[~, EEG.setname, ~] = fileparts(infile);

%this doesn't do anything much (finding channel locations)
%change below directory to your eeglab one with added
%plugins/dipfit/BESA/etc
EEG = pop_chanedit(EEG, 'lookup',str);
%ICA is based on the single event of pictures (markers 1 to 6)

%%
%convert triggers into more sensible names
selectedFace = 0; %this will hold the actually selected face (1-15)
selectedFaceEvent = 0; %this will hold the event number at which a face is selected - trial begin

% just made the code prettier, by using variables instead of the respective
% trigger numbers
unknownTrigger=90; knownTrigger=91; catTrigger=92; oneselfTrigger=93;
trialBegin=250; trialCorrect=252; trialFalse=251;

nextChoose=0; nextKnown=0; nextUnknown=0; nextSelf=0; nextCat=0;
for currEvent = 1:length(EEG.event) %go through events
    eventNumber = str2double(EEG.event(currEvent).type(2:4)); %get current trigger;
    
    % A random trigger that wasn't documented, occured only once in event
    % 2471 between a UnknownPerson trigger and the picture. we just ignore it for the moment
    if eventNumber == 82
        idx=currEvent;
        continue
    end
    
    if eventNumber == trialBegin
        nextChoose=1;
        EEG.event(currEvent).type ='Begin';
        trialEvents = currEvent; % where the trial begins
        continue
    end
    
    % Trial end cases
    if eventNumber == trialCorrect
        EEG.event(currEvent).type ='Correct';
        % nothing to do, everything went as expected
        continue
    end
    if eventNumber == trialFalse
        % mark all data on erroneous trial as ERR, don't discard precious data
        for ii=trialEvents:currEvent
            EEG.event(ii).type = 'ERR';
        end
        continue
    end
    
    % Actual selection of triggers
    if nextChoose==1
        nextChoose=0;
        EEG.event(currEvent).type ='Selected';
        selectedFace = eventNumber - 100; %the chosen face is evnum - 100
        selectedFaceEvent = currEvent; %the event with chosen face is cevent;
        continue
    end
    
    % Pre-picture triggers
    if eventNumber == knownTrigger,   % next person is known
        EEG.event(currEvent).type ='Known';
        nextKnown=1;
        continue
    elseif eventNumber == unknownTrigger % next person is unknown
        EEG.event(currEvent).type ='Unknown';
        nextUnknown=1;
        continue
    elseif eventNumber == oneselfTrigger % next person is oneself
        EEG.event(currEvent).type ='Self';
        nextSelf = 1;
        continue
    elseif eventNumber == catTrigger % next person is a cat
        EEG.event(currEvent).type ='Cat';
        nextCat=1;
        continue
    end
    
    % Actual pictures
    if eventNumber >= 101 && eventNumber <= 115,  % People, self included
        if eventNumber - 100 == selectedFace
            % Relevant trigger
            if nextKnown
                EEG.event(currEvent).type = 'RK';
                nextKnown=0;
                continue
            end
            if nextUnknown
                EEG.event(currEvent).type = 'RU';
                nextUnknown=0;
                continue
            end
            if nextSelf
                EEG.event(currEvent).type = 'RS';
                nextSelf=0;
                continue
            end
        else % Irrelevant trigger
            if nextKnown
                EEG.event(currEvent).type = 'IK';
                nextKnown=0;
                continue
            end
            if nextUnknown
                EEG.event(currEvent).type = 'IU';
                nextUnknown=0;
                continue
            end
            if nextSelf
                EEG.event(currEvent).type = 'IS';
                nextSelf=0;
                continue
            end
        end % End of SelectedFace if
    end % End of PEOPLE if
    
    if eventNumber == 100
        if nextCat
            EEG.event(currEvent).type = 'IC';
            nextCat=0;
            continue
        end
    end % End of CAT if
    
    % there is no actual 199 trigger :p
    if eventNumber == 199
        if nextSelf
            EEG.event(currEvent).type = 'IS';
            nextSelf=0;
            continue
        end
    end
end % End of Event for


%% let's do some preprocessing!
EEG.setname =  '30_before_preprocessing.set'; pop_saveset(EEG, EEG.setname);
EEG = pop_eegfiltnew(EEG, 0.5, 0); %removing drift (SLOW!)
EEG.setname =  '30_after drift.set'; pop_saveset(EEG, EEG.setname);
EEG = pop_eegfiltnew(EEG, 46, 54, [], 1, [], 0); %removing e-interference w notch filter
EEG.setname =  '30_after notch.set'; pop_saveset(EEG, EEG.setname);
EEG = pop_eegfiltnew(EEG, 0, 100); %removing high frequency spikes
EEG.setname =  '30_after hf noise'; pop_saveset(EEG, EEG.setname);
EEG = pop_epoch( EEG, {'RU','RK','RS','IU','IK','IS','IC'}, [-0.2 0.8], 'newname', 'epoched', 'epochinfo', 'no');
EEG = pop_rmbase( EEG, [-200 0]);
EEG.setname =  '30_epoched'; pop_saveset(EEG, EEG.setname);

%% DO ICA yourself:
EEG = pop_runica(EEG, 'extended',1,'interupt','on'); %running ICA: takes 30 minutes to 2 hrs
EEG.setname =  'P06_after_ICA'; pop_saveset(EEG, EEG.setname);

%%
EEG = pop_loadset('P05_epoched.set');
%EEG = pop_loadset('all_ICA.set');
ans=EEG.data(:,:,1);
%ans=reshape(ans,[30,500]);
ans=reshape(ans,[30,500]);
figure
plot(ans','DisplayName','ans')

%%

% 'questions that can be answered:
% 'MAIN: what is the effect of seeing the relevant (chosen) picture?
% '-->
% 'for each trial, we find out which picture is chosen (number to be predicted)
% 'we then calculate 6 ERPs, one for each of the 6 different faces (exclude cats), each having been repeated 4-12 times
% 'the task is then to use these ERPs to predict the chosen face.
%
% 'BONUS:
% 'how many trials to obtain good accuracy of prediction?
% 'what is the effect of seeing your own picture
% 'is the effect of seeing your own picture different if it is relevant?
% 'what is the effect of / can you detect the cat?
% 'what is the effect of positive/negative feedback?
% 'what is the effect of seeing a known (other student/teacher) vs unknown person?

%in order to get nice grand averages for R vs I:

%1) we remove the baseline
%2a) then reject trials based on thresholds (4 5 6 8 9 10 11 13 14 15 18 19 20 21 24 25 26 29 30 31 channels are more central, -40 to 40 uV is normal, %removing +- 20-30% of trials. Make sure all bad trials will be removed!
%2b) or first correct by removing artefactual ICA and then doing 2 (now about 0 to 10% of trials should be removed)
%3) we rereference to TP9/TP10 (for consistency in literature)
%4) separate R and I trials into two datasets
%5) contrast mean R and I, e.g. :

4:6 8:11 13:15 17:20 22:24 27:29


EEG = pop_rmbase(EEG, [-200 0]); %1
%2a from here (can be done easier with EEGLAB GUI)
EEG = pop_eegthresh(EEG,1,[4:6 8 9:11 13 14 15 18 19:21 24 25 26 29 30:31] ,-45,45,-0.2,0.798,2,0,0); %2a (25 - default - is extremely conservative, I've seen up to 100 uV, but >50 i consider bad)
EEG = pop_rejtrend(EEG,1,[1:32] ,500,[4:6 8 9:11 13 14 15 18 19:21 24 25 26 29 30:31] ,0.3,2,0,0); %2a
EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1); %2a
EEG = pop_rejepoch( EEG, find(EEG.reject.rejglobal == 1) ,0); %2a

%3: 17 and 22 are TP9/TP10
EEG = pop_reref(EEG, [17 22]);

%4 from here

clear ALLEEG;

ALLEEG = pop_selectevent( EEG, 'latency','-1<=1','type',{'S101I' 'S102I' 'S103I' 'S104I' 'S105I' 'S106I' 'S107I' 'S108I' 'S109I' 'S110I' 'S111I' 'S112I' 'S113I' 'S114I' 'S115I'},'deleteevents','off','deleteepochs','on','invertepochs','off'); %irr!
ALLEEG(2) = pop_selectevent( EEG, 'latency','-1<=1','type',{'S101R' 'S102R' 'S103R' 'S104R' 'S105R' 'S106R' 'S107R' 'S108R' 'S109R' 'S110R' 'S111R' 'S112R' 'S113R' 'S114R' 'S115R'},'deleteevents','off','deleteepochs','on','invertepochs','off'); %rel!
ALLEEG(3) = pop_selectevent( EEG, 'latency','-1<=1','type',{'S100'},'deleteevents','off','deleteepochs','on','invertepochs','off'); %cat!
pop_comperp( ALLEEG, 1, [1 2 3] ,[],'addavg','off','addstd','off','addall','on','diffavg','off','diffstd','off','tplotopt',{'ydir' 1});;

%notice default is negative up with pop_comperp from within EEGLAB. Bah.

%or:

%

figure; errorbar([-200: 2:798],squeeze(mean(ALLEEG(3).data(1,:,:),3)), squeeze(std(ALLEEG(3).data(1,:,:), [],3))/sqrt(size(ALLEEG(3).data,3))); title('cats');
figure; errorbar([-200: 2:798],squeeze(mean(ALLEEG(2).data(1,:,:),3)), squeeze(std(ALLEEG(2).data(1,:,:), [],3))/sqrt(size(ALLEEG(3).data,3))); title('faces');

%%
%Steps to take after:
%IN EEGLAB:
%tools>reject data epochs>all methods
%use criteria:
%Find Abnormal values. Use channels 1:11 13:15 18:21 23:32. Criterion = lower limit -50, upper limit 50. Calc/Plot Update Marks 
%Reject Marked Trials> OK> Overwrite in memory but give new name.
%Tools > Rereference: Rereference to channel: TP9 TP10
%Press OK, Overwrite in memory. 
%Edit>Select Epochs or Events> Latency -1 to 1. Type: R. 
%Press OK, do not overwrite in memory, but give new name: REL
%Dataset>select your previous dataset
%Edit>Select Epochs or Events> Latency -1 to 1. Type: R. Check: Invert Epoch selection. 
%Press OK, do not overwrite in memory, but give new name: IRR.
%In Datasets, notice which number of dataset is called REL and which is IRR
%Plot>Sum Compare ERPs 
%Datasets to average (the REL and IRR dataset numbers). Uncheck all
%checkmarks but check last one of first line: datasets to average: all
%ERPs. 
%Look for P3 in channel Pz: what is the effect of relevance?

%Try to answer additional questions on slide 14 for exercise!
%Do save session history to retrieve/re-use code.