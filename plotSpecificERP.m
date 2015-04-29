pathCreation
randseed(467614472);

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

%% Plot ERPs from Ready and Clean data
for mm = 1:length(datafile)
    
    EEG = pop_loadset(datafile(mm).name, processeddir);
    names = strrep(datafile(mm).name, '.set', '');
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
    for jj = 1:2:7   
        cd(plotfolders{jj});
        parfor kk = 1:size(ALLEEG(1).chanlocs,2)
            figure(kk);clf
            hold on
            ebar = errorbar(-200:2:798,squeeze(mean(ALLEEG(jj).data(kk,:,:),3)), squeeze(std(ALLEEG(jj).data(kk,:,:), [],3))/sqrt(size(ALLEEG(jj).data,3)));
            set(ebar,'DisplayName',[' ' typenames{jj} ' ' num2str(size(ALLEEG(jj).data,3)) ' epochs '], 'Color',color(jj,:));
            ebar = errorbar(-200:2:798,squeeze(mean(ALLEEG(jj+1).data(kk,:,:),3)), squeeze(std(ALLEEG(jj+1).data(kk,:,:), [],3))/sqrt(size(ALLEEG(jj+1).data,3)));
            set(ebar,'DisplayName',[' ' typenames{jj+1} ' ' num2str(size(ALLEEG(jj+1).data,3)) ' epochs '], 'Color',color(jj+1,:));
            tmp = strcat(ALLEEG(jj).chanlocs(kk).labels,'_',names,'_',plotfolders{jj});
            disp(tmp)
            title(strrep(tmp, '_', ' '));
            legend('Location','southoutside','Orientation','horizontal')
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
exit;