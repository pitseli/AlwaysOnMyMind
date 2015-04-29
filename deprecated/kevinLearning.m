pathCreation
randseed(467614472);
cd(processeddir)

filename = {'Gabi_Daten_Heavy_Filter.mat'};%,'Gabi_pruned_24comps.mat'};
fname = {'Gabi_','Kevin_'};

for mm = 1:size(filename,2)
    load(filename{mm});
    
    % Keep only one event per epoch (one epoch contains 2 events)
    minTime = -150;
    maxTime = 450;
    
    nmbrT = 1;
    idxTime = zeros(1,abs(maxTime)-abs(minTime)+1);
    for ii=1:size(Time,2)
        if minTime <= Time(ii) && Time(ii) <= maxTime
            idxTime(nmbrT) = ii;
            nmbrT = nmbrT + 1;
        end
    end
    
    %% Reformat Labels into integers for simplicity
    LabelInt = zeros(size(Data,3),1);
    % Relevant ones are on even numbers, irrelevant on odd. Cat on 7
    
    % Irrelevant Known => 1
    str = strcmp(Label,'IK');
    fprintf('# IK: %d, ',sum(str))
    LabelInt(str) = 1;
    
    % Relevant Known => 2
    str = strcmp(Label,'RK');
    fprintf('# RK: %d, ',sum(str))
    LabelInt(str) = 2;
    
    % Irrelevant Unknown => 3
    str = strcmp(Label,'IU');
    fprintf('# IU: %d, ',sum(str))
    LabelInt(str) = 3;
    
    % Relevant Unknown => 4
    str = strcmp(Label,'RU');
    fprintf('# RU: %d, ',sum(str))
    LabelInt(str) = 4;
    
    % Irrelevant Self => 5
    str = strcmp(Label,'IS');
    fprintf('# IS: %d, ',sum(str))
    LabelInt(str) = 5;
    
    % Relevant Self => 6
    str = strcmp(Label,'RS');
    fprintf('# RS: %d, ',sum(str))
    LabelInt(str) = 6;
    
    % Cat => 7
    str = strcmp(Label,'IC');
    fprintf('# Cats: %d\n',sum(str))
    LabelInt(str) = 7;
    
    %% keep data that are only interesting events
    NONdeleteIDX = find(LabelInt ~= 0);
    
    LabelInt = LabelInt(NONdeleteIDX);
    Data = Data(:,:,NONdeleteIDX);
    ICAdata = ICAdata(:,:,NONdeleteIDX);
    
    %% split the dataset on training and test dataset
    dataLength = size(Data,3);
    idx = randperm(dataLength); % NOTE! correct that the same distribution is both on test and train as original
    trainingIDX = idx(1:floor(dataLength*0.75));
    testIDX = idx((floor(dataLength*0.75) + 1):end);
    
    trueTrainingData = ICAdata(:,idxTime,trainingIDX);
    trueTrainingLabel = LabelInt(trainingIDX);
    
    trueTestData = ICAdata(:,idxTime,testIDX);
    trueTestLabel = LabelInt(testIDX);
    
    %% Smoothing
    smoothingWindow = 10;
    smoothedSize = (smoothingWindow/2):(size(Data,2) - smoothingWindow/2);
    SmoothingData = zeros( size(Data,1), size(smoothedSize,2), size(Data,3) );
    SmoothingICAdata = zeros( size(ICAdata,1), size(smoothedSize,2), size(Data,3) );
    for ii=(smoothingWindow/2):(size(Data,2) - smoothingWindow/2)
        smoothedSize = (ii-smoothingWindow/2+1):(ii+smoothingWindow/2);
        SmoothingData(:,ii,:) = mean(Data(:,smoothedSize,:), 2);
        SmoothingICAdata(:,ii,:) = mean(ICAdata(:,smoothedSize,:), 2);
    end
    
    smTrainingData = SmoothingICAdata(:,idxTime,trainingIDX);
    smTrainingLabel = LabelInt(trainingIDX);
    
    smTestData = SmoothingICAdata(:,idxTime,testIDX);
    smTestLabel = LabelInt(testIDX);
    
    %% Run once for simple and once for smoothed
    jj=2;    %for jj=1:2
    
    if jj==1
        flag='normal_';
        TrainingData = trueTrainingData;
        TrainingLabel = trueTrainingLabel;
        
        TestData = trueTestData;
        TestLabel = trueTestLabel;
    else
        flag='sm_';
        TrainingData = smTrainingData;
        TrainingLabel = smTrainingLabel;
        
        TestData = smTestData;
        TestLabel = smTestLabel;
    end
    %% Frequency shift
    TrainingDataFFT = zeros(size(TrainingData));
    for ii=1:30
        d = reshape(TrainingData(ii,:,:),size(TrainingData,2),size(TrainingData,3));
        TrainingDataFFT(ii,:,:) = fftshift(fft(d));
    end
    
    %% Cat and Non-Cat
    col = {'r','g','b','y','m','b','c'};
    for ii=1:30
        
        catIDX = find((TrainingLabel==7));
        catTrain = reshape(TrainingData(ii,:,catIDX),size(TrainingData,2),size(catIDX,1));
        meanCat = median(catTrain,2);
        stdCat = std(catTrain'-repmat(meanCat,1,size(catTrain,2))');
        
        figure(1); clf
        hold on
        shadedErrorBar(minTime:2:maxTime,meanCat,stdCat,'r',1)
        
        noncatIDX = find((TrainingLabel~=7));
        catTrain = reshape(TrainingData(ii,:,noncatIDX),size(TrainingData,2),size(noncatIDX,1));
        meanCat = median(catTrain,2);
        stdCat = std(catTrain'-repmat(meanCat,1,size(catTrain,2))');
        
        shadedErrorBar(minTime:2:maxTime,meanCat,2*stdCat,'b',1)
        hold off
        
        %print(num2str(ii),'-dpng');
        pause(0.5)
    end
    
    %% Learning
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
    
    %% Train a SVM classifier
    TrainSet = zeros(size(Features,1),size(TrainingData,3));
    TestSet = zeros(size(Features,1),size(TestData,3));
    for ii=1:size(Features,1)
        TrainSet(ii,:) = median( TrainingData( Features(ii,1),(Features(ii,2)-1):(Features(ii,2)-1),:) ,2 );
        TestSet(ii,:) = median(TestData(Features(ii,1),(Features(ii,2)-1):(Features(ii,2)-1),:),2);
    end
    SVMModel = fitcsvm(TrainSet', TrainingLabel==7, 'OutlierFraction', 0.1);
    
    %% Predict the Test dataset
    [testResults,score] = predict(SVMModel, TestSet');
    RealPositives = (TestLabel==7);
    
    tmp = (2*RealPositives + testResults);
    TruePositives = tmp == 3;
    TrueNegatives = tmp == 0;
    FalsePositives = tmp == 1;
    FalseNegatives = tmp == 2;
    
    % Evaluate classification
    precision = sum(TruePositives)/sum(TruePositives + FalsePositives);
    recall = sum(TruePositives)/sum(TruePositives + FalseNegatives);
    accuracy = sum(TruePositives+TrueNegatives)/sum(TruePositives+TrueNegatives+FalseNegatives+FalsePositives);
    F1Score = 2*sum(TruePositives)/sum(2*sum(TruePositives)+FalseNegatives+FalsePositives);
    stats = table(precision, recall, accuracy, F1Score,...
        sum(TruePositives),sum(FalsePositives),sum(FalseNegatives),sum(TrueNegatives),...
        'VariableNames',{'Precision' 'Recall' 'Accuracy' 'F1score' 'TP' 'FP' 'TN' 'FN'});
    disp('Statistics for separating Cats from others')
    disp(stats)
    % end
end