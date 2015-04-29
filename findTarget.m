function target = findTarget(label,studyidx)

% Which events are we comparing?
if studyidx == 1
	target = (label == 7);
elseif studyidx == 2
	target = (label==6);
elseif studyidx == 3
	target = ((label==3)+(label==4));
elseif studyidx == 4
	target = (mod(label,2)==0);
end