%%%%%%%%%%%%
%% section 1
clear all;
close all;
dirn = 'D:\SPIMdata\Data_for_SPIM_manuscript\extra data for spim manuscript 20190720\A549-GFPRab11A-WSN-DMSO\stats';
cd(dirn);
dirtxt='A549_R11AGFP_WSN_DMSO*';
A=dir(dirtxt);
fn=waitbar(0,'File list');
t_interval = 0.837; %seconds per volume pair SPIM A and SPIM B (this factor added on 12/19/2017)
endj = 5;

% init data arrays
durdat=[];
figure;
durp=gca;durf=gcf;
hold(durp,'on');
tldat=[];
figure;
tlp=gca;tlf=gcf;
hold(tlp,'on');
tddat=[];
figure;
tdp=gca;tdf=gcf;
hold(tdp,'on');
tsdat=[];
figure;
tsp=gca;tsf=gcf;
hold(tsp,'on');
tsvdat=[];
figure;
tsvp=gca;tsvf=gcf;
hold(tsvp,'on');
tsdvdat=[];
figure;
tsdvp=gca;tsdvf=gcf;
hold(tsdvp,'on');
tstdat=[];
figure;
tstp=gca;tstf=gcf;
hold(tstp,'on');
figure;
velp=gca;velf=gcf;
hold(velp,'on');

for j = 1:1:endj
    no_onesies=[];
    %get duration
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Duration.csv']);
    [M,T,R]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Duration')
        no_onesies=find(M(:,1) > 1);
        no_idx=M(no_onesies,4);
        durdat = vertcat(durdat, M(no_onesies,1));
        makeholdplot(durp,0,0.7,150,M(no_onesies,1)*t_interval,dirtxt,A(j).name(1:end-11),'Track Duration','Track Duration (s)');
    end
    
    %get track displacement
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Displacement_Length.csv']);
    [M,T,R]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Displacement Length')
        [com_v,ia,ib]=intersect(M(:,4),no_idx);
        tddat = vertcat(tddat, M(ia,1));
        makeholdplot(tdp,0,0.1,5,M(ia,1),dirtxt,A(j).name(1:end-11),'Track Displacement Length','Track Displacement Length (um)');
    end
    
    %get track length
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Length.csv']);
    [M,T,R]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Length')
        [com_v,ia,ib]=intersect(M(:,4),no_idx);
        tldat = vertcat(tldat, M(ia,1));
        makeholdplot(tlp,0,0.1,20,M(ia,1),dirtxt,A(j).name(1:end-11),'Track length','Track length (um)');
    end
    
    %get avg speed
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Speed_Mean.csv']);
    [M,T,R]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Speed Mean')
        [com_v,ia,ib]=intersect(M(:,4),no_idx);
        tsdat = vertcat(tsdat, M(ia,1));
        makeholdplot(tsp,0,0.01,1,M(ia,1)/t_interval,dirtxt,A(j).name(1:end-11),'Average speed','Average speed (um/s)');
    end
    
%     %get track speed variation
%     fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Speed_Variation.csv']);
%     [M,T,R]=xlsread(fname);
%     dathead = T(3,1); 
%     if strcmp(dathead{1},'Track Speed Variation')
%         [com_v,ia,ib]=intersect(M(:,4),no_idx);
%         tsvdat = vertcat(tsvdat, M(ia,1));
%         makeholdplot(tsvp,0,0.01,2.5,M(ia,1),dirtxt,'Speed Variation','Speed Variation');
%     end
    
%     %get track speed variation
%     fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Speed_StdDev.csv']);
%     [M,T,R]=xlsread(fname);
%     dathead = T(3,1); 
%     if strcmp(dathead{1},'Track Speed StdDev')
%         [com_v,ia,ib]=intersect(M(:,4),no_idx);
%         tsdvdat = vertcat(tsdvdat, M(ia,1));
%         makeholdplot(tsdvp,0,0.01,2.5,M(ia,1)/t_interval,dirtxt,A(j).name(1:end-11),'Speed Std Dev.','Speed Std. Dev (um/s)');
%     end
    
    %get track straightness
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Straightness.csv']);
    [M,T,R]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Straightness')
        [com_v,ia,ib]=intersect(M(:,4),no_idx);
        tstdat = vertcat(tstdat, M(ia,1));
        makeholdplot(tstp,0,0.01,1.5,M(ia,1),dirtxt,A(j).name(1:end-11),'Track Straightness','Track Straightness');
	end
	
	% calculate and plot track velocity
	no_onesies=[];
    %get duration
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Duration.csv']);
    [M,T,~]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Duration')
        no_onesies=find(M(:,1) > 1);
        no_idx=M(no_onesies,4);
        durdat = M(no_onesies,1)*t_interval;
        %makeholdplot(durp,0,0.7,150,M(no_onesies,1)*t_interval,dirtxt,'Track Duration','Track Duration (s)');
    end
    
    %get track displacement
    fname=fullfile(dirn,A(j).name,[A(j).name(1:end-11),'_Track_Displacement_Length.csv']);
    [M,T,~]=xlsread(fname);
    dathead = T(3,1); 
    if strcmp(dathead{1},'Track Displacement Length')
        [com_v,ia,ib]=intersect(M(:,4),no_idx);
        dispdat = M(ia,1);
        %makeholdplot(tdp,0,0.01,,M(ia,1),dirtxt,'Track Displacement Length','Track Displacement Length (um)');
    end
	veldat = dispdat./durdat;
	makeholdplot(velp,0,0.01,1,veldat,dirtxt,A(j).name(1:end-11),'Track velocity','Track velocity (um/s)');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot histogram of speeds, path lengths
% 	hold on;
% 	f = histogram(tracks(:,1),[0:0.01:1], 'Normalization','probability');
% 	hval{j}=f.Values;
% 	f.FaceColor = 'auto';
% 	f.FaceAlpha= 0.5;
% 	f.EdgeColor = 'none';
%%%%%%%%%%%%%%%%%%% function extend section %%%%%%%%%%
waitbar(j / endj);
end

%% save figures
mkdir(fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*')));
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-dur.fig'));
savefig(durf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-disp.fig'));
savefig(tdf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-len.fig'));
savefig(tlf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-spd.fig'));
savefig(tsf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-spd-var.fig'));
savefig(tsvf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-straightness.fig'));
savefig(tstf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-std-dev.fig'));
savefig(tsdvf,fname);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-trk-vel.fig'));
savefig(velf,fname);

%%
allf=figure;
one=subplot(2,3,1);
two=subplot(2,3,2);
three=subplot(2,3,3);
four=subplot(2,3,4);
five=subplot(2,3,5);
six=subplot(2,3,6);

% %track duration (corrected for time invterval 12/19/2017)
makecumplot(one,0,0.7,35,[0.03 0.55 0.27 0.4],durdat*t_interval,dirtxt,' track duration',' track duration (s)');

% %track length
makecumplot(two,0,0.1,15,[0.36 0.55 0.27 0.4],tldat,dirtxt,' track length',' track length (um)');

% %track displacement
makecumplot(three,0,0.1,5,[0.69 0.55 0.27 0.4],tddat,dirtxt,' track displacement',' track displacement (um)');

% %track speed (corrected for time invterval 12/19/2017)
makecumplot(four,0,0.01,1,[0.03 0.05 0.27 0.4],tsdat/t_interval,dirtxt,' track speed',' track speed (um/s)');

% %track speed std dev (corrected for time invterval 12/19/2017)
makecumplot(five,0,0.01,2.5,[0.36 0.05 0.27 0.4],tsdvdat/t_interval,dirtxt,' speed std dev',' speed std dev (um/s)');

% %track straightness
makecumplot(six,0,0.01,1,[0.69 0.05 0.27 0.4],tstdat,dirtxt,' track straightness',' track straightness');

%%
close(fn);
fname=fullfile(dirn,'graphs_trk_len_grt_thn_3',strip(dirtxt,'*'),horzcat(strip(dirtxt,'*'),'-all-metrics-comb.fig'));
savefig(allf,fname);

function mp = makeholdplot(phnd,xmi,xstep,xma,dat,dirtxt,lgnd,ptitle,pxlabel)
    xmin=xmi-xstep/2;
    xmax=xma+xstep/2;
    f = histcounts(dat,[xmin:xstep:xmax], 'Normalization','probability');
%     f.FaceColor = 'none';
%     f.FaceAlpha= 0.5;
%     f.EdgeColor = 'auto';
    histcum=cumsum(f);
    plot(phnd,[xmin+xstep/2:xstep:xmax-xstep/2],histcum,'LineStyle','-','DisplayName',lgnd);
	ylim(phnd,[0,1]);
    xlim(phnd,[xmin,xmax]);
    title(phnd,horzcat(strrep(dirtxt,'_','-'),ptitle));
    xlabel(phnd,pxlabel);
    ylabel(phnd,'cumulative frequency');
end

function cp = makecumplot(sphnd,xmi,xstep,xma,pos,dat,dirtxt,ptitle,pxlabel)
    subplot(sphnd);
    subplot('Position',pos);
    xmin=xmi-xstep/2;
    xmax=xma+xstep/2;
    f = histogram(dat,[xmin:xstep:xmax], 'Normalization','probability');
    dhist=f.Values;
    f.FaceColor = 'auto';
    f.FaceAlpha= 0.5;
    f.EdgeColor = 'none';
    xlim([xmin,xmax]);
    title(horzcat(strrep(dirtxt,'_','-'),ptitle));
    xlabel(pxlabel);
    ylabel('frequency');
    hold on;
    histcum=cumsum(dhist);
    yyaxis right;
    plot([xmin+xstep/2:xstep:xmax-xstep/2],histcum,'r-');
    ylim([0,1]);
    ylabel('cumulative freq');
end