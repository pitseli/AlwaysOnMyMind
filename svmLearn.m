pathCreation
randseed(467614472);

cd(kevindir)
filename = dir('*.mat');
%%
for kk = 1:length(filename)
    studyname='';
    
    fprintf('---- %s ----\n',filename(kk).datenum);
    
    load(filename(kk).name);
    
    % Keep only one event per epoch (one epoch contains 2 events)
    minTime = -100;
    maxTime = 430;
    
    jj = 1;
    idxTime = zeros(1, abs(maxTime - minTime)/2);
    for ii=1:size(Time,2)
        if minTime <= Time(ii) && Time(ii) <= maxTime
            idxTime(jj) = ii;
            jj = jj + 1;
        end
    end
    
    LabelInt = zeros(size(Data,3),1);
    
    % Relevant ones are on even numbers, irrelevant on odd. Cat on 7
    types = {'IU','RU','IK','RK','IS','RS','IC'};
    
    % Reformat Labels into integers for simplicity
    for ii = 1:length(types)
        str = strcmp(Label,types{ii});
        fprintf('# %s: %d ',types{ii},sum(str));
        %fprintf('# %s: %d ',types{ii},sum(str));
        LabelInt(str) = ii;
    end
    
    
    % Make sure there are no empty events
    idx = find(LabelInt ~= 0);
    
    LabelInt = LabelInt(idx);
    Data = Data(:,:,idx);
    ICAdata = ICAdata(:,:,idx);
    
    studyidx = 4;
    % Run once for simple and once for smoothed
    for ii = 1:2
        if ii == 1
            flag='using normal';
        else
            flag='using smoothing';
            % Smoothing
            smoothingWindow = 10;
            smoothedSize = (smoothingWindow/2):(size(Data,2) - smoothingWindow/2);
            SmoothingData = zeros( size(Data,1), size(smoothedSize,2), size(Data,3) );
            SmoothingICAdata = zeros( size(ICAdata,1), size(smoothedSize,2), size(Data,3) );
            for jj = (smoothingWindow/2):(size(Data,2) - smoothingWindow/2)
                smoothedSize = (jj-smoothingWindow/2+1):(jj+smoothingWindow/2);
                SmoothingData(:,jj,:) = mean(Data(:,smoothedSize,:), 2);
                SmoothingICAdata(:,jj,:) = mean(ICAdata(:,smoothedSize,:), 2);
            end
            Data = SmoothingData;
            ICAdata = SmoothingICAdata;
        end
        
        % Which events are we comparing?
        if studyidx == 1
            studyname = strjoin({'Cats vs Rest',flag,'for dataset',filename(kk).name});
            targetidx = find(LabelInt == 7);
            nontargetidx = find(LabelInt ~= 7);
            
        elseif studyidx == 2
            studyname = strjoin({'Relevant Self vs Irrelevant Self',flag,'for dataset',filename(kk).name});
            targetidx = find(LabelInt==6);
            nontargetidx = find(LabelInt==5);
            
        elseif studyidx == 3
            studyname = strjoin({'Known vs Unknown',flag,'for dataset',filename(kk).name});
            targetidx = find((LabelInt==3)+(LabelInt==4));
            nontargetidx = find((LabelInt==1)+(LabelInt==2));
        elseif studyidx == 4
            studyname = strjoin({'Relevant vs Irrelevant',flag,'for dataset',filename(kk).name});
            targetidx = find(mod(LabelInt,2)==0);
            nontargetidx = find(mod(LabelInt,2));                
        end
        
        if (isempty(targetidx)||isempty(nontargetidx))
            fprintf('%s for dataset %s doesnt have enough data! \n',studyname,filename(kk).name);
            continue
        else
            disp(studyname)
            disp(strjoin({'# Target:',num2str(size(targetidx,1)),'# Non-Target:',num2str(size(nontargetidx,1)),...
                'Overall:',num2str(size(targetidx,1) + size(nontargetidx,1))}));
            disp('----------------------------------')
            
            %% Making sure both Test and Train datasets have the same distribution of classes as in the original
            targetMark=length(targetidx);
            nontargetMark=length(nontargetidx);
            targetidx = targetidx(randperm(targetMark));
            nontargetidx = nontargetidx(randperm(nontargetMark));
            
            trainingIDX = [targetidx(1:ceil(targetMark*0.75)); nontargetidx(1:ceil(nontargetMark*0.75))];
            testIDX = [targetidx((ceil(targetMark*0.75 + 1):end)); nontargetidx(ceil(nontargetMark*0.75 + 1):end)];
            
            % resuffle the datasets, as they are ordered now
            trainingIDX = trainingIDX(randperm(length(trainingIDX)));
            testIDX = testIDX(randperm(length(testIDX)));
            
            TrainData = ICAdata(:,idxTime,trainingIDX);
            TrainLabel = LabelInt(trainingIDX);
            
            TestData = ICAdata(:,idxTime,testIDX);
            TestLabel = LabelInt(testIDX);
            
            %% Learning
            if studyidx == 1
                Features = [ %Channel/Component, %Time; ...
                    16, floor(size(idxTime,2) -(maxTime - 224)/2);...
                    14, floor(size(idxTime,2) -(maxTime - 362)/2);...
                    13, floor(size(idxTime,2) -(maxTime - 235)/2);...
                    13, floor(size(idxTime,2) -(maxTime - 427)/2);...
                    12, floor(size(idxTime,2) -(maxTime - 318)/2);...
                    10, floor(size(idxTime,2) -(maxTime - 395)/2);...
                    10, floor(size(idxTime,2) -(maxTime - 268)/2);...
                    7, floor(size(idxTime,2) -(maxTime - 361)/2);...
                    5, floor(size(idxTime,2) -(maxTime - 342)/2);...
                    4, floor(size(idxTime,2) -(maxTime - 290)/2);...
                    1, floor(size(idxTime,2) -(maxTime - 427)/2)...
                    ];
            else %if studyidx == 2
                Features = [ %Channel/Component, %Time; ...
                    22, floor(size(idxTime,2) -(maxTime - 230)/2);...
                    17, floor(size(idxTime,2) -(maxTime - 358)/2);...
                    10, floor(size(idxTime,2) -(maxTime - 282)/2);...
                    4, floor(size(idxTime,2) -(maxTime - 288)/2);...
                    1, floor(size(idxTime,2) -(maxTime - 376)/2)...
                    ];
            end
            
            %% Train a SVM classifier
            TrainSet = zeros(size(Features,1),size(TrainData,3));
            TestSet = zeros(size(Features,1),size(TestData,3));
            for ll = 1:size(Features,1)
                TrainSet(ll,:) = median( TrainData( Features(ll,1),(Features(ll,2)-1):(Features(ll,2)+1),:) ,2 );
                TestSet(ll,:) = median(TestData(Features(ll,1),(Features(ll,2)-1):(Features(ll,2)+1),:),2);
            end
            SVMModel = fitcsvm(TrainSet', findTarget(TrainLabel,studyidx), 'OutlierFraction', 0.1);
            
            %% Predict the Train dataset
            [testResults,~] = predict(SVMModel, TrainSet');
            printStatistics(TrainLabel, testResults, studyidx, studyname,'Training Data');
            
            %% Predict the Test dataset
            [testResults,~] = predict(SVMModel, TestSet');
            printStatistics(TestLabel, testResults, studyidx, studyname, 'Test Data');
            
        end % End IF targetidx

    end % End FOR smooth vs normal
end % End Files

exit;