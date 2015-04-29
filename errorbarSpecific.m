pathCreation
randseed(467614472);

disp('im in')
cd(processeddir)
datafile = dir('*.set');

cd(plotdir)
plotfolders = {'CatvsRest','','RelvsIrr','','Self','','KnownvsUnknown'};

% Relevant ones are on even numbers, irrelevant on odd. Cat on 7
typenames = {'Cats','Rest','Relevant','Irrelevant','Relevant Self','Irrelevant Self','Known','Unknown'};
color = cmyk2rgb([0 1 0 0.4; 0.5 0.5 0.5 0.3;...
    0.2 0.75 0.4 0; 0.75 0.75 0.5 0;...
    1 0.3 0 0.15; 1 1 0 0;...
    0.15 0.7 1 0; 1 0.35 1 0.35]);

minTime = -100;
maxTime = 430;

for jj = 1:2:7
    
    %% Plot ERPs from Ready and Clean data
    for mm = 1:length(datafile)
        
        EEG = pop_loadset(datafile(mm).name, processeddir);
        names = strrep(datafile(mm).name, '.set', '');
        %     load(filename(kk).name);
        fprintf('Loaded dataset %s \n',names)
        
        % cat vs rest
        ALLEEG = pop_selectevent( EEG, 'latency','-1<=1','type',{'IC'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        ALLEEG(2) = pop_selectevent( EEG, 'latency','-1<=1','type',{'IU','RU','IK','RK','IS','RS'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        
        % Rel vs Irr
        ALLEEG(3) = pop_selectevent( EEG, 'latency','-1<=1','type',{'IU','IK','IS'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        ALLEEG(4) = pop_selectevent( EEG, 'latency','-1<=1','type',{'RU','RK','RS'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        
        % Self rel vs irr
        ALLEEG(5) = pop_selectevent( EEG, 'latency','-1<=1','type',{'RS'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        ALLEEG(6) = pop_selectevent( EEG, 'latency','-1<=1','type',{'IS'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        
        % Known vs unknown
        ALLEEG(7) = pop_selectevent( EEG, 'latency','-1<=1','type',{'IU','RU'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        ALLEEG(8) = pop_selectevent( EEG, 'latency','-1<=1','type',{'IK','RK'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        
        
        tmp='';
        
        cd(plotfolders{jj});
        
        for kk = 1:size(ALLEEG(1).chanlocs,2)
            %% Create for target class
            tData = ALLEEG(jj).data(kk,:,:);
            tTime = ALLEEG(jj).times;
            
            nmbrT = 1;
            idxTime =[];
            for ii=1:size(tTime,2)
                if minTime <= tTime(ii) && tTime(ii) <= maxTime
                    idxTime(nmbrT) = ii;
                    nmbrT = nmbrT + 1;
                end
            end
            
            Target = reshape( tData(1,idxTime,:), size(idxTime,2), size(tData,3));
            Target = Target - repmat(mean(Target(1:15,:),1),size(idxTime,2),1);
            mTarget = median(Target,2);
            stdTarget = std(Target' - repmat(mTarget,1,size(Target,2))');
            
            
            %% Now for class 2
            ntData = ALLEEG(jj+1).data(kk,:,:);
            ntTime = ALLEEG(jj+1).times;
            
            nmbrT = 1;
            idxTime =[];
            for ii=1:size(ntTime,2)
                if minTime <= ntTime(ii) && ntTime(ii) <= maxTime
                    idxTime(nmbrT) = ii;
                    nmbrT = nmbrT + 1;
                end
            end
            
            Nontarget = reshape( ntData(1,idxTime,:), size(idxTime,2), size(ntData,3));
            Nontarget = Nontarget - repmat(mean(Nontarget(1:15,:),1),size(idxTime,2),1);
            mNontarget = median(Nontarget,2);
            stdNontarget = std(Nontarget' - repmat(mNontarget,1,size(Nontarget,2))');
            
            %% plot errorbars
            figure(1);clf
            
            shadedErrorBar(minTime:2:maxTime, mTarget, 2*stdTarget,{ 'Color',color(jj,:)},1);
            hold on
            shadedErrorBar(minTime:2:maxTime, mNontarget, 2*stdNontarget,{ 'Color',color(jj+1,:)},1);
            ylim([-28,28])
            hold off
            tmp = strcat(ALLEEG(jj).chanlocs(kk).labels,'_',names,'_',plotfolders{jj},'_error');
            disp(tmp)
            title(strrep(tmp, '_', ' '));
            legend(typenames{jj},typenames{jj+1},'Location','southoutside','Orientation','horizontal')
            %legend('Location','southoutside','Orientation','horizontal')
            legend('show')
            hold off
            
            print(tmp,'-dpng');
        end
        cd(plotdir)
    end
    
    fprintf('-------------------- Plotted %s --------------------\n',tmp)
    % Plot all channels
    %pop_comperp( ALLEEG, 1, [1 2 3] ,[],'addavg','off','addstd','off','addall','on','diffavg','off','diffstd','on','tplotopt',{'ydir' 1});
    %pop_comperp( ALLEEG, 1, [1 2 3] ,[],'chans',25,'addavg','off','addstd','off','addall','on','diffavg','off','diffstd','on','tplotopt',{'ydir' 1});
end

disp('-------------------- DONE --------------------')
%exit;