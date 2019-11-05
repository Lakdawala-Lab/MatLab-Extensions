dirn = 'D:\SPIMdata\Data_for_SPIM_manuscript\extra data for spim manuscript 20190720\A549-GFPRab11A-WSN-DMSO\ArrCoeff';
cd(dirn);
dirtxt='A549_R11AGFP_WSN_DMSO*';
A=dir(dirtxt);
wb=waitbar(0,'File list');
%endj = 3; % number of arrest thresholds
endk=length(A); % file number 
%arrthresh = {'300','400','500'};
%lcol = {'-r','-g','-b'};
M=nan(100,1);
avgarrcoeff=nan(endk,1);
for k=1:1:endk;
    %figure;
    %for j = 1:1:endj
    %get arr coeff data
    %hold on;
    fn=dir([dirn,'\',A(k).name]);
    fname1=fullfile(dirn,fn.name);
    [M1,T1,R1]=xlsread(fname1,'arrest coeff vs. track length','C4:AZ103'); % freq. of arr. coeff
    [M2,T2,R2]=xlsread(fname1,'arrest coeff vs. track length','E2:DA2'); % arr-coeffs
    M = sum(M1,2);
    bcent=(M2(1:end-1)+M2(2:end))/2;
    numer=bcent*M;
    denom = sum(M);
    avgarrcoeff(k)=numer/denom;
    %
    
    %bar(bcent,M,1.1);
%bcum=cumsum(M(:,j));
%p1=plot(bcent,bcum/bcum(end),lcol{j});
%vp=gca;
%b(1).FaceColor = 'red';
%b(2).FaceColor = 'black';
%b(3).FaceColor = 'blue';
%title(vp,horzcat(strrep(A(k).name,'_','-'),'  arrest coefficient'));
%xlabel(vp,'arrest coefficient');
%ylabel(vp,'frequency');
    
%     [n,c]=hist3([M1(:,1),M2(:,1)], 'Edges',edges);
%     contourf(c{1}, c{2}, n', [10,20,30,40,50,60,70,80,90,100,200,300,400,500,600,700,800,900,1000,1500,2000,2500,3000]);
%     vp=gca;
    %set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
%     ylim(vp,[0,1000]);
%     xlim(vp,[0,1]);
%     colormap(vp,jet);
%     title(vp,horzcat(strrep(dirtxt,'_','-'),'  track int vs track speed'));
%     xlabel(vp,'avg track speed (um/s)');
%     ylabel(vp,'avg track intensity')
    %makeholdplot(vp,0,0.01,1,M(:,4),dirtxt,'Track velocities','Track velocity (um/s)');
end
waitbar(k / endk);

%hold off;

%fname=fullfile(dirn,'graphs_trk_len_grt_thn_1',strip(dirtxt,'*'),'arr_coeff_graphs',horzcat(strrep(A(k).name,'_','-'),'-arr-coeff-thresh-300-400-500nm.fig'));
%savefig(gcf,fname);
% end
delete(wb);

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