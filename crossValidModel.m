pathCreation
randseed(467614472);

cd(kevindir)
filename = dir('*.mat');
%%

for studyidx = 1:4
    for kk = 1:length(filename)
        fprintf('---- %s ----\n',filename(kk).datenum);
        names = strrep(filename(kk).name, '.mat', '');
        fprintf('Dataset %s \n',names)
        
        %% Find best normal kernel model
        [studyname,TrainLabel,TrainSet,TestLabel,TestSet,typicalidx,typicalModel, typicalError] = returnOptimalModel(studyidx,filename(kk),1); %% typical
        % Predict the Train dataset
        fprintf('Dataset %s \n typical kernel with box constraint 10^%d and error of %f\n',names,typicalidx,typicalError)
        [testResults,~] = predict(typicalModel, TrainSet');
        printStatistics(TrainLabel, testResults, studyidx, studyname,'Training Data');
        
        % Predict the Test dataset
        [testResults,~] = predict(typicalModel, TestSet');
        printStatistics(TestLabel, testResults, studyidx, studyname, 'Test Data');
        
        %% Find best RBF kernel model
        [studyname,TrainLabel,TrainSet,TestLabel,TestSet,bestidx,bestModel,bestError] = returnOptimalModel(studyidx,filename(kk),2); %% rbf
        % Predict the Train dataset
        fprintf('Dataset %s \n RBF kernel with box constraint 10^%d and error of %f\n',names,bestidx,bestError)
        [testResults,~] = predict(bestModel, TrainSet');
        printStatistics(TrainLabel, testResults, studyidx, studyname,'Training Data');
        
        % Predict the Test dataset
        [testResults,~] = predict(bestModel, TestSet');
        printStatistics(TestLabel, testResults, studyidx, studyname, 'Test Data');      
        
    end % End study
end % End Files
exit;