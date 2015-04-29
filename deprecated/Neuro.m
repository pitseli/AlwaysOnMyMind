pathCreation
randseed(467614472);
load('Gabi_Daten_Heavy_Filter.mat');

minTime = -150;
maxTime = 430;

nmbrT = 1;
idxTime = [];
for i=1:size(Time,2)
    if minTime <= Time(i) && Time(i) <= maxTime
        idxTime(nmbrT) = i;
        nmbrT = nmbrT + 1;
    end
end

LabelInt = zeros(size(Data,3),1);

% Irrelevante Known => 1
LabelInt(strcmp(Label,'IK')) = 1;

% Irrelevante Unknown => 2
LabelInt(strcmp(Label,'IU')) = 2;

% Relevante Known => 3
LabelInt(strcmp(Label,'RK')) = 3;

% Relevante Unknown => 4
LabelInt(strcmp(Label,'RU')) = 4;

% Irrelevant Self => 5
LabelInt(strcmp(Label,'IS')) = 5;

% Relevant Self => 6
LabelInt(strcmp(Label,'RS')) = 6;

% Cat => 7
LabelInt(strcmp(Label,'IC')) = 7;

NONdeleteIDX = find(LabelInt ~= 0);

LabelInt = LabelInt(NONdeleteIDX);
Data = Data(:,:,NONdeleteIDX);
ICAdata = ICAdata(:,:,NONdeleteIDX);

length = size(Data,3);
idx = randperm(length);
trainingIDX = idx(1:floor(length*0.75));
testIDX = idx((floor(length*0.75) + 1):end);

%Smoothing
k=10
for i=(k/2):(size(Data,2) - k/2)
    SmoData(:,i,:) =mean(Data(:,(i-k/2+1):(i+k/2),:),2);
    SmoICAdata(:,i,:) = mean(ICAdata(:,(i-k/2+1):(i+k/2),:),2);
end

TrainingData = SmoICAdata(:,idxTime,trainingIDX);
TrainingLabel = LabelInt(trainingIDX);

TestData = SmoICAdata(:,idxTime,testIDX);
TestLabel = LabelInt(testIDX);



%%
col = {'r','g','b','y','m','b','c'};
for i=1:30
    c=i
    clf
    hold on
    
    for lbl = 1:7
        ownIDX = find((TrainingLabel==lbl));
        A = reshape(TrainingData(c,:,ownIDX(1:10)),size(idxTime,2),size(ownIDX(1:10),1));
        A2 = A - repmat(mean(A(1:30,:),1),size(idxTime,2),1);
        
        meanA2 = median(A2,2);
        
        stdA2 = std(A2'-repmat(meanA2,1,size(A,2))');
        
        shadedErrorBar(minTime:2:maxTime,meanA2,2*stdA2,col(lbl),1)
        hold on
    end
    print(num2str(c),'-dpng');
    pause(2)
end

%%
for i=1:30
    c=i
    
    ownIDX2 = find((TrainingLabel==7));
    ownIDX = find((TrainingLabel==1) + (TrainingLabel==2) + (TrainingLabel==3) + (TrainingLabel==4) + (TrainingLabel==5) + (TrainingLabel==6));
    B = reshape(TrainingData(c,:,ownIDX2),size(idxTime,2),size(ownIDX2,1));
    A = reshape(TrainingData(c,:,ownIDX),size(idxTime,2),size(ownIDX,1));
    A2 = B - repmat(mean(B(1:15,:),1),size(idxTime,2),1);
    B2 = A - repmat(mean(A(1:15,:),1),size(idxTime,2),1);
    clf
    meanA2 = median(A2,2);
    meanB2 = median(B2,2);
    stdA2 = std(A2'-repmat(meanA2,1,size(A,2))');
    stdB2 = std(B2' - repmat(meanB2,1,size(B,2))');
    shadedErrorBar(minTime:2:maxTime,meanA2,2*stdA2,'b',1)
    hold on
    shadedErrorBar(minTime:2:maxTime,meanB2,2*stdB2,'r',1)
    print(num2str(c),'-dpng');
    pause(2)
end

%%
k=1
i=180
val = -1.5;
%for k=1:30
for val=-10:1:10
    %for i=1:10:size(TrainingData,2)
    c=k
    
    ownIDX2 = find((TrainingLabel==7));
    ownIDX = find((TrainingLabel==1) + (TrainingLabel==2) + (TrainingLabel==3) + (TrainingLabel==4) + (TrainingLabel==5) + (TrainingLabel==6));
    B = reshape(TrainingData(c,:,ownIDX2),size(idxTime,2),size(ownIDX2,1));
    A = reshape(TrainingData(c,:,ownIDX),size(idxTime,2),size(ownIDX,1));
    B2 = B - repmat(median(B(1:30,:),1),size(idxTime,2),1);
    pointwiseIDX = find(abs(mean(B2((i-3):(i+3),:))' - val) < 1);
    B2 = B2(:,pointwiseIDX);
    A2 = A - repmat(median(A(1:30,:),1),size(idxTime,2),1);
    pointwiseIDX = find(abs(mean(A2((i-3):(i+3),:)) - val) < 1);
    A2 = A2(:,pointwiseIDX);
    clf
    meanA2 = mean(A2,2);
    meanB2 = mean(B2,2);
    if sum(meanA2 == NaN) > 0
        meanA2 = zeros(size(meanA2));
    end
    if sum(meanB2 == NaN) > 0
        meanB2 = zeros(size(meanB2));
    end
    stdA2 = std(A2'-repmat(meanA2,1,size(A2,2))');
    stdB2 = std(B2' - repmat(meanB2,1,size(B2,2))');
    if stdA2 == 0
        stdA2 = zeros(size(meanA2));
    end
    if stdB2 == 0
        stdB2 = zeros(size(meanB2));
    end
    %plot(minTime:2:maxTime,A2(:,1:2),'b');
    %hold on
    %plot(minTime:2:maxTime,B2(:,1:2),'r');
    shadedErrorBar(minTime:2:maxTime,meanA2,2*stdA2,'b',1)
    hold on
    shadedErrorBar(minTime:2:maxTime,meanB2,2*stdB2,'r',1)
    ylim([-15,15])
    title(sprintf('A=%i B=%i',size(A2,2),size(B2,2)));
    %print(num2str([c val]),'-dpng');
    pause(2)
    %end
end