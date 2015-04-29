pathCreation
randseed(467614472);

Features = [ %Channel/Component, %Time; ...
    4, floor(size(idxTime,2) -(maxTime - 290)/2);...
    1, floor(size(idxTime,2) -(maxTime - 427)/2)...
    ];
% Train a SVM SVMModelassifier
TrainSet = zeros(size(Features,1),size(TrainData,3));
TestSet = zeros(size(Features,1),size(TestData,3));
for ll = 1:size(Features,1)
    TrainSet(ll,:) = median( TrainData( Features(ll,1),(Features(ll,2)-1):(Features(ll,2)+1),:) ,2 );
    TestSet(ll,:) = median(TestData(Features(ll,1),(Features(ll,2)-1):(Features(ll,2)+1),:),2);
end
SVMModel = fitcsvm(TrainSet', findTarget(TrainLabel,1), 'OutlierFraction', 0.1);
% Predict the Train dataset
[testResults,~] = predict(SVMModel, TrainSet');
printStatistics(TrainLabel, testResults, studyidx, fileID, studyname,'Training Data');

%%
data3=TrainSet';
theSVMModelass=findTarget(TrainLabel,1);

%SVMModel = fitcsvm(TrainSet', findTarget(TrainLabel,1), 'OutlierFraction', 0.1);
%Train the SVM SVMModelassifier
SVMModel = fitcsvm(data3,theSVMModelass,'KernelFunction','rbf','BoxConstraint',1);

% Predict scores over the grid
d = 0.02;
[x1Grid,x2Grid] = meshgrid(min(data3(:,1)):d:max(data3(:,1)),...
    min(data3(:,2)):d:max(data3(:,2)));
xGrid = [x1Grid(:),x2Grid(:)];

[testResults,~] = predict(SVMModel, TrainSet');
printStatistics(TrainLabel, testResults, 1, 1, 1,'Training Data');

[~,scores] = predict(SVMModel,xGrid);
% Plot the data and the decision boundary
figure;
h(1:2) = gscatter(data3(:,1),data3(:,2),theSVMModelass,'rb','.');
hold on
ezpolar(@(x)1);
h(3) = plot(data3(SVMModel.IsSupportVector,1),data3(SVMModel.IsSupportVector,2),'ko');
contour(x1Grid,x2Grid,reshape(scores(:,2),size(x1Grid)),[0 0],'k');
legend(h,{'-1','+1','Support Vectors'});
axis equal
hold off

%%
[ttestResults,scores] = predict(SVMModel, TestSet');
printStatistics(TestLabel, ttestResults, 1, 1, 1,'Test Data');