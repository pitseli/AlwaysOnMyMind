function [studyname, targetidx, nontargetidx] = studyIndexes(studyidx,flag,name,LabelInt)
% Which events are we comparing?
if studyidx == 1
    studyname = strjoin({'Cats vs Rest',flag,'for dataset',name});
    targetidx = find(LabelInt == 7);
    nontargetidx = find(LabelInt ~= 7);
    
elseif studyidx == 2
    studyname = strjoin({'Relevant Self vs Irrelevant Self',flag,'for dataset',name});
    targetidx = find(LabelInt==6);
    nontargetidx = find(LabelInt==5);
    
elseif studyidx == 3
    studyname = strjoin({'Known vs Unknown',flag,'for dataset',name});
    targetidx = find((LabelInt==3)+(LabelInt==4));
    nontargetidx = find((LabelInt==1)+(LabelInt==2));
    
elseif studyidx == 4
    studyname = strjoin({'Relevant vs Irrelevant',flag,'for dataset',name});
    targetidx = find(mod(LabelInt,2)==0);
    nontargetidx = find(mod(LabelInt,2)); 
end