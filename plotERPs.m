pathCreation
randseed(467614472);

cd(processeddir)
datafile = dir('*.set');

cd(plotdir)
% Relevant ones are on even numbers, irrelevant on odd. Cat on 7
types = {'IU','RU','IK','RK','IS','RS','IC'};
color = cmyk2rgb([1 0.3 1 0.15; 1 0 1 0; 0.3 1 1 0; ... % relevant colours, light
                  0 0.5 1 0; 1 1 0 0; 1 0.3 0 0.15;... % irrelevant colours, dark
                  0 1 0 0.4]); % cats :3

%% Plot ERPs from Ready and Clean data
for mm = 1:length(datafile)
    
    EEG = pop_loadset(datafile(mm).name, processeddir);
    names = strrep(datafile(mm).name, '_', ' ');
    names = strrep(names, '.set', '');
    fprintf('Loaded dataset %s \n',names)
    
    % Every type is a dataset
    ALLEEG = struct([]);
    for jj = 1:length(types)
        ALLEEG(jj) = pop_selectevent( EEG, 'latency','-1<=1','type',types{jj},'deleteevents','off','deleteepochs','on','invertepochs','off');
    end
    tmp='';
    tt = 1;
    
    for jj = 1:(length(types)-1)
        for kk = jj+1:length(types)
            for ll = 1:size(ALLEEG(1).chanlocs,2)
                figure(1);clf
                hold on
                ebar = errorbar(-200:2:798,squeeze(mean(ALLEEG(jj).data(ll,:,:),3)), squeeze(std(ALLEEG(jj).data(ll,:,:), [],3))/sqrt(size(ALLEEG(jj).data,3)));
                set(ebar,'DisplayName',[' ' types{jj} ' ' num2str(size(ALLEEG(jj).data,3)) ' epochs '], 'Color',color(jj,:));
                ebar = errorbar(-200:2:798,squeeze(mean(ALLEEG(kk).data(ll,:,:),3)), squeeze(std(ALLEEG(kk).data(ll,:,:), [],3))/sqrt(size(ALLEEG(kk).data,3)));
                set(ebar,'DisplayName',[' ' types{kk} ' ' num2str(size(ALLEEG(kk).data,3)) ' epochs '], 'Color',color(kk,:));
                tmp = strjoin({ALLEEG(jj).chanlocs(ll).labels,'on dataset',names,' _ ',num2str(tt)});
                fprintf('%s \n',tmp)
                title(tmp);
                legend('Location','southoutside','Orientation','horizontal')
                legend('show')
                hold off
                
                print(tmp,'-dpng');
            end
            tt = tt + 1;
        end
    end
    clc
    fprintf('-------------------- Plotted %s --------------------\n',tmp)
    % Plot all channels
    %pop_comperp( ALLEEG, 1, [1 2 3] ,[],'addavg','off','addstd','off','addall','on','diffavg','off','diffstd','on','tplotopt',{'ydir' 1});
    %pop_comperp( ALLEEG, 1, [1 2 3] ,[],'chans',25,'addavg','off','addstd','off','addall','on','diffavg','off','diffstd','on','tplotopt',{'ydir' 1});
end

disp('-------------------- DONE --------------------')
exit;