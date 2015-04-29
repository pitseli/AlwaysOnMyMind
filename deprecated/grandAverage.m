%% some comments on triggers:
% 'trialbegin = 250
% 'trialend = 251 or 252
% 'INCORRECT trial = 251
% 'CORRECT trial = 252
% 'FIRST number after 250: chosen face
% 
% '101-115: 15 pictures of people
% '199: picture = self
% '100: cat picture
% 
% '90: pre-picture. Upcoming picture is an unknown person
% '91: pre-picture. Upcoming picture is a student (or teacher)
% '92: pre-picture. Upcoming picture is a cat
% '93: pre-picture. Upcoming picture is self
% '
% 'Example marker file in EEG (S… is trigger number, followed by time stamp in samples (@500 Hz):
% 'Mk1=New Segment,,1,1,0,20150311140810092942
% 'Mk2=Stimulus,S250,7864,0,0    <--- trial begin
% 'Mk3=Stimulus,S112,10775,0,0   <--- picked number 12
% 'Mk4=Stimulus,S 91,11646,0,0   <--- next is known
% 'Mk5=Stimulus,S102,11672,0,0   <--- is picture 2
% 'Mk6=Stimulus,S 91,11885,0,0   <--- next is known
% 'Mk7=Stimulus,S115,11912,0,0   <--- is picture 15
% 'Mk8=Stimulus,S 91,12125,0,0   <--- next is known
% 'Mk9=Stimulus,S111,12172,0,0   <--- is picture 11
% 'Mk10=Stimulus,S 91,12385,0,0  <--- next is known
% 'Mk11=Stimulus,S103,12412,0,0  <--- is picture 3
% 'Mk12=Stimulus,S 93,12625,0,0  <--- next is self
% 'Mk13=Stimulus,S105,12652,0,0  <--- is picture 5
% 'Mk14=Stimulus,S 91,12865,0,0  <--- next is known
% 'Mk15=Stimulus,S112,12891,0,0  <--- is picture 12 (RELEVANT)
% 'Mk16=Stimulus,S 93,13105,0,0  <--- next is self
% 'Mk17=Stimulus,S105,13131,0,0  <--- is picture 5
% '...
% 'Mk66=Stimulus,S 92,19181,0,0  <--- next is cat!
% 'Mk67=Stimulus,S100,19208,0,0  <--- is a cat picture
% '...
% 'Mk98=Stimulus,S 91,23079,0,0  <--- next is known
% 'Mk99=Stimulus,S103,23106,0,0  <--- is picture 3
% 'Mk100=Stimulus,S252,24632,0,0 <--- recognized picture (12) as the one to be remembered.
% '
% '
% '
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

%preprocessing:
 files = dir('*.vhdr');
 EEG = pop_loadbv(cd,files(ceil(rand(1)*4)+1).name);
 EEG = pop_chanedit(EEG, 'lookup','C:\\eeglab\\eeglab13_3_2b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
 EEG = pop_select(EEG, 'point', [EEG.event(2).latency-10000 EEG.event(end).latency+10000]); %chopping the data up to keep just the experiment;
 EEG = pop_eegfiltnew(EEG, [], 0.3, 5500, true, [], 0); %HP filter to remove drift
 EEG = pop_eegfiltnew(EEG, [], 80, 84, 0, [], 0); %LP filter to remove some noise
 EEG = pop_eegfiltnew(EEG, 46, 54, 826, 1, [], 0); %notch filter to remove electroc interference
 EEG = pop_runica(EEG, 'extended',1,'interupt','on'); %running ICA (explained in the session)
 pop_saveset(EEG, 'example.set')

 
 EEG = pop_loadset('example.set');

relevs = 0; irrevs = 0;
for cevent = 1:length(EEG.event);
    if strcmp(EEG.event(cevent).type, 'S250'), trialbeginev = cevent; end; %trialbegin found, storing event num 
    if strcmp(EEG.event(cevent).type, 'S251'), trialbeginev = 0; end; %trialend found, but error in recognition (rare)
    if strcmp(EEG.event(cevent).type, 'S252'), %trial end found, loop back:
        chosenone = str2double(EEG.event(trialbeginev+1).type(2:4)); %selected face.
        if ~(chosenone>100 && chosenone<116), 
            disp ('huh?')
        else
            for ccevent = (trialbeginev+2):(cevent-1), %from trial begin+2 (first one is just chosen face!), to trial end-1
                evnum = str2double(EEG.event(ccevent).type(2:4));
                if (evnum > 100) && (evnum < 116) %if it's a face
                    if evnum == chosenone, EEG.event(ccevent).type = [EEG.event(ccevent).type 'R']; relevs = relevs+1;
                    else EEG.event(ccevent).type = [EEG.event(ccevent).type 'I']; irrevs = irrevs+1;
                    end; %if evnum
                end %if faceonset                        
            end
        end
        trialbeginev = 0;        
    end %end loopback;
end %for cevent
disp (['Found ' num2str(relevs) ' relevant and ' num2str(irrevs) ' irrelevant. Irrevs should be almost exactly equal to 5 times relevs!']);
allrelevents = cellstr([repmat('S',[15 1]) num2str((101:115)') repmat('R',[15 1])])';
allirrevents = cellstr([repmat('S',[15 1]) num2str((101:115)') repmat('I',[15 1])])';
EEG = pop_epoch(EEG, [allrelevents allirrevents 'S100'], [-0.2 0.8]);
pop_saveset(EEG, 'example_epoched.set');

%in order to get nice grand averages for R vs I:
%1) we remove the baseline 
%2a) then reject trials based on thresholds (4 5 6 8 9 10 11 13 14 15 18 19 20 21 24 25 26 29 30 31 channels are more central, -40 to 40 uV is normal, %removing +- 20-30% of trials. Make sure all bad trials will be removed!
%2b) or first correct by removing artefactual ICA and then doing 2 (now about 0 to 10% of trials should be removed)
%3) we rereference to TP9/TP10 (for consistency in literature)
%4) separate R and I trials into two datasets
%5) contrast mean R and I, e.g. :
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
plotthischan = 23; %plotting Pz (change to other channel if preferred!)
figure; 
ebar = errorbar([-200: 2:798],squeeze(mean(ALLEEG(2).data(plotthischan,:,:),3)), squeeze(std(ALLEEG(2).data(plotthischan,:,:), [],3))/sqrt(size(ALLEEG(2).data,3))); 
set(ebar,'DisplayName',['Relevant ' num2str(size(ALLEEG(2).data,3)) ' epochs'], 'Color',[0.2 0.6 0.2]);
hold on
ebar = errorbar([-200: 2:798],squeeze(mean(ALLEEG(3).data(plotthischan,:,:),3)), squeeze(std(ALLEEG(3).data(plotthischan,:,:), [],3))/sqrt(size(ALLEEG(3).data,3))); 
set(ebar,'DisplayName',['Cats ' num2str(size(ALLEEG(3).data,3)) ' epochs'], 'Color',[0.2 0.2 0.7]);
hold on
ebar = errorbar([-200: 2:798],squeeze(mean(ALLEEG(1).data(plotthischan,:,:),3)), squeeze(std(ALLEEG(1).data(plotthischan,:,:), [],3))/sqrt(size(ALLEEG(1).data,3))); 
set(ebar,'DisplayName',['Irrelevant ' num2str(size(ALLEEG(1).data,3)) ' epochs'], 'Color',[0.5 0 0]);
set(gca, 'XLim', [-200 800]);
title(EEG.chanlocs(plotthischan).labels);
