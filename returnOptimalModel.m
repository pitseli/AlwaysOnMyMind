function  [studyname,TrainLabel,TrainSet,TestLabel,TestSet,bestidx,bestModel,bestError] = returnOptimalModel(studyidx,filename,model)
pathCreation
randseed(467614472);

load(filename.name);

% Keep only one event per epoch (one epoch contains 2 events)
minTime = -100;
maxTime = 430;

jj = 1;
idxTime = zeros(1, abs(maxTime - minTime)/2);
for kk=1:size(Time,2)
    if minTime <= Time(kk) && Time(kk) <= maxTime
        idxTime(jj) = kk;
        jj = jj + 1;
    end
end

LabelInt = zeros(size(Data,3),1);

% Relevant ones are on even numbers, irrelevant on odd. Cat on 7
types = {'IU','RU','IK','RK','IS','RS','IC'};

% Reformat Labels into integers for simplicity
for kk = 1:length(types)
    str = strcmp(Label,types{kk});
    fprintf('# %s: %d ',types{kk},sum(str));
    LabelInt(str) = kk;
end


% Make sure there are no empty events
idx = find(LabelInt ~= 0);
LabelInt = LabelInt(idx);
Data = Data(:,:,idx);
ICAdata = ICAdata(:,:,idx);


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

[studyname, targetidx, nontargetidx] = studyIndexes(studyidx,flag,filename.name,LabelInt);

if (isempty(targetidx)||isempty(nontargetidx))
    fprintf('%s for dataset %s doesnt have enough data! \n',studyname,filename.name);
    return
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
    else
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
    for jj = 1:size(Features,1)
        TrainSet(jj,:) = median( TrainData( Features(jj,1),(Features(jj,2)-1):(Features(jj,2)+1),:) ,2 );
        TestSet(jj,:) = median(TestData(Features(jj,1),(Features(jj,2)-1):(Features(jj,2)+1),:),2);
    end
    if model == 1
        SVMModel = fitcsvm(TrainSet', findTarget(TrainLabel,studyidx), 'OutlierFraction', 0.1,'BoxConstraint',10^-5);
        bestModel = crossval(SVMModel,'KFold',5);
        bestError = kfoldLoss(bestModel);
        bestidx = -5;
        for kk= -4:1:5
            SVMModel = fitcsvm(TrainSet', findTarget(TrainLabel,studyidx), 'OutlierFraction', 0.1,'BoxConstraint',10^kk);
            CVSVMModel = crossval(SVMModel,'KFold',5);
            err = kfoldLoss(CVSVMModel);
            if err < bestError
                bestModel = SVMModel;
                bestError = err;
                bestidx = kk;
            end
        end
        disp('ended typical')
        
    else
        SVMModel = fitcsvm(TrainSet',findTarget(TrainLabel,studyidx),'KernelFunction','rbf','BoxConstraint',10^-5);
        bestModel = crossval(SVMModel,'KFold',5);
        bestError = kfoldLoss(bestModel);
        bestidx = -5;
        for kk= -4:1:5
            SVMModel = fitcsvm(TrainSet',findTarget(TrainLabel,studyidx),'KernelFunction','rbf','BoxConstraint',10^kk);
            CVSVMModel = crossval(SVMModel,'KFold',5);
            err = kfoldLoss(CVSVMModel);
            if err < bestError
                bestModel = SVMModel;
                bestError = err;
                bestidx = kk;
            end
        end
        disp('ended kernels')
    end    
end