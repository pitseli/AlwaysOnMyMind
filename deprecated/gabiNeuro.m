pathCreation
randseed(467614472);

filename = dir('*.mat');
%%
for mm = 1:length(filename)
   
    load(filename(mm).name);
    
    %% Keep only one event per epoch (one epoch contains 2 events)
    minTime = -150;
    maxTime = 430;
    
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
    str=strcmp(Label,'IK');
    fprintf('# IK: %d\n',sum(str))
    LabelInt(str) = 1;
    
    % Relevant Known => 2
    str=strcmp(Label,'RK');
    fprintf('# RK: %d\n',sum(str))
    LabelInt(str) = 2;
    
    % Irrelevant Unknown => 3
    str=strcmp(Label,'IU');
    fprintf('# IU: %d\n',sum(str))
    LabelInt(str) = 3;
    
    % Relevant Unknown => 4
    str=strcmp(Label,'RU');
    fprintf('# RU: %d\n',sum(str))
    LabelInt(str) = 4;
    
    % Irrelevant Self => 5
    str=strcmp(Label,'IS');
    fprintf('# IS: %d\n',sum(str))
    LabelInt(str) = 5;
    
    % Relevant Self => 6
    str=strcmp(Label,'RS');
    fprintf('# RS: %d\n',sum(str))
    LabelInt(str) = 6;
    
    % Cat => 7
    str=strcmp(Label,'IC');
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
    
    %% Smooooooooooth baby yeaaaaaah :3
    
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
    
    
    %% Start
    %% Run plots once for normal and one for smoothed
    for jj=1:2
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
        %% Coloured overlap
        col = {'r','g','b','y','m','b','c'};
        for ii=1:30
            clf
            hold on
            
            for lbl = 1:7
                idx = find((TrainingLabel==lbl));
                tmp = reshape(TrainingData(ii,:,idx(1:10)),size(idxTime,2),size(idx(1:10),1));
                tmp = tmp - repmat(mean(tmp(1:30,:),1),size(idxTime,2),1);
                
                mtmp = median(tmp,2);
                stdtmp = std(tmp'-repmat(mtmp,1,size(tmp,2))');
                
                shadedErrorBar(minTime:2:maxTime, mtmp, 2*stdtmp, col(lbl), 1)
                hold on
            end
            picname = strcat('overlap_',flag,fname{mm},num2str(ii));
            %print(picname,'-dpng');
            pause(0.5)
        end
        
        
        %% All (relevant vs irrelevant)
        relevantIDX = find( (TrainingLabel==2) + (TrainingLabel==4) + (TrainingLabel==6) );
        irrelevantIDX = find( (TrainingLabel==1) + (TrainingLabel==3) + (TrainingLabel==5) + (TrainingLabel==7) );
        
        for ii=1:30 % number of components
            
            % relevant ones
            relevantData = reshape( TrainingData(ii,:,relevantIDX), size(idxTime,2), size(relevantIDX,1) );
            
            % irrelevant ones
            irrelevantData = reshape( TrainingData(ii,:,irrelevantIDX), size(idxTime,2), size(irrelevantIDX,1) );
            
            relevantReshaped = relevantData - repmat( median(relevantData(1:100,:),1), size(idxTime,2),1 );
            irrelevantReshaped = irrelevantData - repmat( median(irrelevantData(1:100,:),1), size(idxTime,2),1 );
            
            clf
            relevantMean = median(irrelevantReshaped,2);
            irrelevantMean = median(relevantReshaped,2);
            relevantstd = std(irrelevantReshaped'-repmat(relevantMean,1,size(irrelevantData,2))');
            irrelevantstd = std(relevantReshaped' - repmat(irrelevantMean,1,size(relevantData,2))');
            
            shadedErrorBar(minTime:2:maxTime,relevantMean,relevantstd,'b',1)
            hold on
            shadedErrorBar(minTime:2:maxTime,irrelevantMean,irrelevantstd,'r',1)
            
            picname = strcat('all',flag,fname{mm},num2str(ii));
            print(picname,'-dpng');
            pause(0.5)
        end
        
        %% CATS vs All :D
        for ii=1:30
            
            catIdx = find((TrainingLabel==7));
            restIDX = find((TrainingLabel~=1));
            Cats = reshape(TrainingData(ii,:,catIdx),size(idxTime,2),size(catIdx,1));
            Rest = reshape(TrainingData(ii,:,restIDX),size(idxTime,2),size(restIDX,1));
            Cats = Cats - repmat(mean(Cats(1:15,:),1),size(idxTime,2),1);
            Rest = Rest - repmat(mean(Rest(1:15,:),1),size(idxTime,2),1);
            figure(ii); clf;
            mRest = median(Rest,2);
            mCats = median(Cats,2);
            stdRest = std(Rest'-repmat(mRest,1,size(Rest,2))');
            stdCats = std(Cats' - repmat(mCats,1,size(Cats,2))');
            shadedErrorBar(minTime:2:maxTime,mRest,2*stdRest,'b',1)
            hold on
            shadedErrorBar(minTime:2:maxTime,mCats,2*stdCats,'r',1)
            hold off
            picname = strcat('CATS_',flag, num2str(ii));
            title(picname)
            %print(picname,'-dpng');
            pause(0.5)
        end
        
        %% Significant (relevant vs irrelevant)
        relevantIDX = find( (TrainingLabel==2) + (TrainingLabel==4) + (TrainingLabel==6) );
        irrelevantIDX = find( (TrainingLabel==1) + (TrainingLabel==3) + (TrainingLabel==5) + (TrainingLabel==7) );
        
        for kk=1:30
            %for val=-4:1:4
            for ii=1:10:size(TrainingData,2)
                val =-1.5;
                
                % relevant ones
                relevantData = reshape( TrainingData(kk,:,relevantIDX), size(idxTime,2), size(relevantIDX,1) );
                relevantReshaped = relevantData - repmat( median(relevantData(1:30,:),1), size(idxTime,2), 1 );
                pointwiseIDX = find(abs(relevantReshaped(ii,:) - val) < 0.4);
                relevantReshaped = relevantReshaped(:,pointwiseIDX);
                
                % irrelevant ones
                irrelevantData = reshape( TrainingData(kk, :, irrelevantIDX), size(idxTime, 2), size(irrelevantIDX, 1) );
                irrelevantReshaped = irrelevantData - repmat( median( irrelevantData(1:30, :), 1), size(idxTime,2), 1 );
                pointwiseIDX = find(abs( irrelevantReshaped(ii,:) - val ) < 0.4);
                irrelevantReshaped = irrelevantReshaped(:,pointwiseIDX);
                
                clf
                relevantMean = mean(irrelevantReshaped,2);
                irrelevantMean = mean(relevantReshaped,2);
                if sum(isnan(relevantMean)) > 0
                    relevantMean = zeros(size(relevantMean));
                end
                if sum(isnan(irrelevantMean)) > 0
                    irrelevantMean = zeros(size(irrelevantMean));
                end
                
                relevantstd = std( irrelevantReshaped' - repmat(relevantMean,1,size(irrelevantReshaped,2))' );
                irrelevantstd = std( relevantReshaped' - repmat(irrelevantMean,1,size(relevantReshaped,2))' );
                if relevantstd == 0
                    relevantstd = zeros(size(relevantMean));
                end
                if irrelevantstd == 0
                    irrelevantstd = zeros(size(irrelevantMean));
                end
                
                %             plot(minTime:2:maxTime, relevantReshaped(:,1:2),'b');
                %             hold on
                %             plot(minTime:2:maxTime, irrelevantReshaped(:,1:2),'r');
                shadedErrorBar(minTime:2:maxTime, relevantMean, 2*relevantstd,'b',1)
                hold on
                shadedErrorBar(minTime:2:maxTime, irrelevantMean, 2*irrelevantstd,'r',1)
                ylim([-15,15])
                
                picname = strcat('significant_',flag,fname{mm},num2str([kk val]));
                print(picname,'-dpng');
                pause(0.5)
            end
        end
    end
end