%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This matlab script reads the node and edge network for the tracks
% exported from Imaris into a directed graph framework. It then uses the
% graph toolkit to find all starting and ending points and every possible
% path that exists between those start and end points. Various metrics can
% then be calculated and exported, e.g. path lengths, path durations, path
% displacement, average speeds, velocities, etc. This is then written into
% a separate analysis file for each spots data set.
%
% Author: Amar Bhagwat, 2017
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function node_network_analysis(startn,endn)
%%%%%%%%%%%%
%% section 1
dirn = 'L:\Data\Amar Bhagwat\20170226\spots_tracks_excel';
cd(dirn);
A=dir('A549_R11AGFP_*');
%fn2=waitbar(0,'file count');
fn=[];

% start a separate analysis for each spots file. Since the datasets are
% independent, they can be run as parallel threads on separate processors
% using the matlab parallel for command - parfor
parfor j = startn:1:endn
    % open data file
    int_thresh=1e6; % was selected to be 55
	fname=fullfile(dirn,A(j).name);
	dat_edge1=xlsread(fname,'track edges', 'A:B'); % node pairs of edges
	dat_pos=xlsread(fname,'spots info', 'A:E'); % positions of nodes
    
    spotInt = dat_pos(:,5)<int_thresh;
    %dat_pos = dat_pos1(spotInt,1:4);
    
    EdgeInt = false(length(dat_edge1),2);
    for eidx=1:1:length(EdgeInt)
        if spotInt(dat_edge1(eidx,1)) == true
            EdgeInt(eidx,1) = true;
        end
        if spotInt(dat_edge1(eidx,2)) == true
            EdgeInt(eidx,2) = true;
        end
    end
    edgeInt=EdgeInt(:,1) & EdgeInt(:,2);
    dat_edge = dat_edge1(edgeInt,:);
    
    % do some calculations on the GPU for speedup
	startpos=gpuArray(dat_pos(dat_edge(:,1),1:3)); %start nodes per step
	endpos=gpuArray(dat_pos(dat_edge(:,2),1:3)); %end nodes per step
	%weight=sqrt(sum((endpos-startpos).^2,2)); % distance as weight
    diffWsq=arrayfun(@calcDist,startpos,endpos); % distance as weight
    weight1=sqrt(sum(diffWsq,2));
    weight = gather(weight1); % bring data back from GPU
	
    X=digraph(dat_edge(:,1),dat_edge(:,2),weight); % make directed graph
	startX=indegree(X); %measure incoming routes into a node
	endX=outdegree(X); %measure outgoing routes out of a node
	startnodes=find(startX == 0); % zero incoming routes means a starting node 
	endnodes=find(endX == 0); % zero outgoing nodes = end node

	%% section 2
	tr_no=1; %initialize track counter
	trklens = nan(100000,7); %initialize an empty vector for speed
	fn(j)=waitbar(0,'checking paths...'); 
	for i = 1:1:length(startnodes) % loop for each starting point
        
        % identify paths and distance traveled for those paths
		[path,d] = shortestpathtree(X,startnodes(i),endnodes,'OutputForm','cell');
		locs=find(d<Inf); % identify paths where distance is a finite number
		for k=1:1:length(locs) % iterate through all paths
			p = path{locs(k)}; % % current path under consideration
            % testing, ignore... coordsG = gpuArray(dat_pos(p(:),1:4));

            % measure displacement of path
			vDisp=sqrt(sum((dat_pos(p(end),1:3)-dat_pos(p(1),1:3)).^2,2));
            % meausre path duration
            vDuration=dat_pos(p(end),4)-dat_pos(p(1),4);
            
            % there is a bug somewhere, check why durations are negative 
            % in one file
            if vDuration < 0
                dispnegT = ['negative DURATION: ',num2str(vDuration),...
                    ' at idx: ', num2str(k), ' IN FILE IDX: ', num2str(j),...
                    ' at startnode: ', num2str(i)];
                disp(dispnegT);
            end
            % measure speed per step
            vStartSeg = gpuArray(dat_pos(p(1:end-1),1:3));
			vEndSeg = gpuArray(dat_pos(p(2:end),1:3));
			%vLengthSeg = sqrt(sum((vEndSeg - vStartSeg).^2,2));
            diffLsq = arrayfun(@calcDist,vStartSeg,vEndSeg);
            vLengthSeg1=sum(sqrt(sum(diffLsq,2)));
            vLengthSeg = gather(vLengthSeg1); % total distance traveled
			% vTimeSeg = dat_pos(p(2:end),4)-dat_pos(p(1:end-1),4);
			% wrong! vAvgSpeed = mean(vLengthSeg./vTimeSeg);
            vAvgSpeed = vLengthSeg/vDuration;
            vVel = vDisp/vDuration;
            % Following block measures maximum excursion followed by this
            % path
            
            % the diffX matrix measures distance between each pair of nodes 
            % that form the path. Like a inter-city distance grid on a driving map 
            xPos=dat_pos(p(:),1); % x positions
            yPos=dat_pos(p(:),2); % y positions
            zPos=dat_pos(p(:),3); % z positions
            diffX=xPos*ones(1,length(xPos))-ones(length(xPos),1)*xPos';
            diffY=yPos*ones(1,length(xPos))-ones(length(xPos),1)*yPos';
            diffZ=zPos*ones(1,length(xPos))-ones(length(xPos),1)*zPos';
            
            % for grins and giggles, also map the average intensity of the
            % track and the intensity std dev.
            
            trkIntAvg=mean(dat_pos(p(:),5)); % average intensity of track
            trkIntStd=std(dat_pos(p(:),5)); % average intensity of track
            
            % convert into a 3-D distance
           	diffR=sqrt(diffX.^2+diffY.^2+diffZ.^2);
		
            % find maximum inter-node distance
            maxExcur=max(max(diffR));
            
            % save the current track info into previously initialized vector
			trklens(tr_no,:)=[vDisp,vLengthSeg,maxExcur,vAvgSpeed,vVel,trkIntAvg,trkIntStd];
			tr_no=tr_no+1; % increment track counter
        end % current starting point completed
		waitbar(i/length(startnodes),fn(j));
    end % all starting points explored and completed
	close(fn(j));
    % save the info into a xls file for further analysis and plotting
	nn=strsplit(A(j).name,'.');
    % make new file name
	nfn=fullfile(dirn,'combo_anlys_corr_with_int',[char(nn(1)),'_alldatac_int.',char(nn(2))]);
    % convert to a table so we can write column header text
	T={'Displacement','distance','max_excursion','AvgSpeed','AvgVel','Avg Intensity','Intensity Std Dev'};
    outdat=num2cell(trklens(~isnan(trklens(:,1)),1:7));%,...
        %trklens(~isnan(trklens(:,2)),2),...
        %trklens(~isnan(trklens(:,3)),3),...
        %trklens(~isnan(trklens(:,4)),4),...
        %trklens(~isnan(trklens(:,5)),5)};
    output_matrix=[T; outdat];    
    dispMsg=['Writing file: ',char(nn(1)),'_alldatac_int.',char(nn(2))];
    disp(dispMsg);
	xlswrite(nfn,output_matrix,'all_data','A1'); % write XLS file
    dispMsg=['Done writing file: ',char(nn(1)),'_alldatac_int.',char(nn(2))];
    disp(dispMsg);
	%waitbar(i/length(startnodes));
end
%close(fn2);
return;
end

function diffLsq = calcDist(startpos,endpos)
diffLsq=(endpos-startpos).^2;
end
