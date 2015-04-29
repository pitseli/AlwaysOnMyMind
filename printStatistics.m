function [precision, recall, accuracy, F1Score,TP,FP,TN,FN] = printStatistics(targetLabels,predictedLabels,studyidx,studyname,dataset)

RealPositives = findTarget(targetLabels,studyidx);
tmp = (2*RealPositives + predictedLabels);
TotalData = length(targetLabels);

TrueNegatives = (tmp == 0); FalseNegatives = (tmp == 2);
FalsePositives = (tmp == 1); TruePositives = (tmp == 3);
TP=sum(TruePositives); FN=sum(FalseNegatives);
FP=sum(FalsePositives); TN=sum(TrueNegatives);

% Evaluate classification
precision = TP/(TP+FP);
recall = TP/(TP+FN);

accuracy = (TP + TN)/(TP+TN+FP+FN);
F1Score = 2*TP/(2*TP+FN+FP);

prompt = sprintf('separating %s on %d %s\n',studyname,TotalData,dataset);
stats = table(precision, recall, accuracy, F1Score,TP,FP,TN,FN,TotalData,...
    'VariableNames',{'precision', 'recall', 'accuracy', 'F1Score','TP','FP','TN','FN','TotalData'});
disp(prompt)
disp(stats)
disp(' ')