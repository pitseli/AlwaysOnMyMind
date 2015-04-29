pathCreation
randseed(467614472);

cd(rawdir)
datafile = dir('*.vhdr');
%% convert triggers into more sensible names
parfor mm = 1:length(datafile)
    % load data, set channels
    EEG = pop_loadbv(rawdir, datafile(mm).name);
    [~, EEG.setname, ~] = fileparts(datafile(mm).name);
    EEG = pop_chanedit(EEG, 'lookup',str);
    EEG = pop_select(EEG, 'point', [EEG.event(2).latency-10000 EEG.event(end).latency+10000]);
    disp('Loaded EEG data')
    
    selectedFace = 0; %this will hold the actually selected face (1-15)
    selectedFaceEvent = 0; %this will hold the event number at which a face is selected - trial begin
    
    % just made the code prettier, by using variables instead of the respective
    % trigger numbers
    unknownTrigger = 90; knownTrigger = 91; catTrigger = 92; oneselfTrigger = 93;
    trialBegin = 250; trialCorrect = 252; trialFalse = 251;
    
    nextChoose = 0; nextKnown = 0; nextUnknown = 0; nextSelf = 0; nextCat = 0;
    for currEvent = 1:length(EEG.event) %go through events
        eventNumber = str2double(EEG.event(currEvent).type(2:4)); %get current trigger;
    
        if nextChoose == 1
            nextChoose = 0;
            EEG.event(currEvent).type = 'Selected';
            selectedFace = eventNumber - 100; %the chosen face is evnum - 100
            selectedFaceEvent = currEvent; %the event with chosen face is cevent;
            continue
        end

        if eventNumber == trialBegin
            nextChoose = 1;
            EEG.event(currEvent).type = 'Begin';
            trialEvents = currEvent; % where the trial begins
            continue       
        
        % Trial end cases
        elseif eventNumber == trialCorrect
            EEG.event(currEvent).type = 'Correct';
            % nothing to do, everything went as expected
            continue
        
        elseif eventNumber == trialFalse
            % mark all data on erroneous trial as ERR, don't discard precious data
            for ii = trialEvents:currEvent
                EEG.event(ii).type = 'ERR';
            end
            continue
        
        % Pre-picture triggers
        elseif eventNumber == knownTrigger, % next person is known
            EEG.event(currEvent).type = 'Known';
            nextKnown = 1;
            continue
        elseif eventNumber == unknownTrigger % next person is unknown
            EEG.event(currEvent).type = 'Unknown';
            nextUnknown = 1;
            continue
        elseif eventNumber == oneselfTrigger % next person is oneself
            EEG.event(currEvent).type = 'Self';
            nextSelf = 1;
            continue
        elseif eventNumber == catTrigger % next person is a cat
            EEG.event(currEvent).type = 'Cat';
            nextCat = 1;
            continue
        end

        % Actual pictures
        if eventNumber >= 101 && eventNumber <= 115, % People, self included
            if eventNumber - 100 == selectedFace
                % Relevant trigger
                if nextKnown
                    EEG.event(currEvent).type = 'RK';
                    nextKnown = 0;
                    continue
                
                elseif nextUnknown
                    EEG.event(currEvent).type = 'RU';
                    nextUnknown = 0;
                    continue
                
                elseif nextSelf
                    EEG.event(currEvent).type = 'RS';
                    nextSelf = 0;
                    continue
                end
            else % Irrelevant trigger
                if nextKnown
                    EEG.event(currEvent).type = 'IK';
                    nextKnown = 0;
                    continue
                
                elseif nextUnknown
                    EEG.event(currEvent).type = 'IU';
                    nextUnknown = 0;
                    continue
                
                elseif nextSelf
                    EEG.event(currEvent).type = 'IS';
                    nextSelf = 0;
                    continue
                else
                    disp('Unexpected Event')
                    EEG.event(currEvent).type = 'ERR';
                    continue
                end

            end % End of SelectedFace if
        end % End of PEOPLE if
        
        if eventNumber == 100
            if nextCat
                EEG.event(currEvent).type = 'IC';
                nextCat = 0;
                continue
            end
        end % End of CAT if
        
        % there is no actual 199 trigger :p
        if eventNumber == 199
            if nextSelf
                EEG.event(currEvent).type = 'IS';
                nextSelf = 0;
                continue
            end
        end
    end % End of Event for
    disp('Renamed Events')
    
    %% let's do some preprocessing!
    fprintf('Saving initial files of dataset %d\n',mm);
    cd(processeddir);
    EEG.setname = strcat(num2str(mm),'_processed.set'); pop_saveset(EEG, EEG.setname);
    EEG = pop_eegfiltnew(EEG, [], 0.3, 5500, true, [], 0); %HP filter to remove drift
    EEG = pop_eegfiltnew(EEG, [], 80, 84, 0, [], 0); %LP filter to remove some noise
    EEG = pop_eegfiltnew(EEG, 46, 54, 826, 1, [], 0); %notch filter to remove electroc interference
    EEG = pop_epoch( EEG, {'IU','RU','IK','RK','IS','RS','IC'}, [-0.2 0.8], 'newname', 'epoched', 'epochinfo', 'no');
    EEG = pop_rmbase( EEG, [-200 0]); % removing baseline
    fprintf('Saving epoched files of dataset %d\n',mm); pop_saveset(EEG, EEG.setname);
end

disp('Saved and copied all files')