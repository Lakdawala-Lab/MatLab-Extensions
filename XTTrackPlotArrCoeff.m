%
%
%  Track Arrest Coefficient Function for Imaris 7.3.0
%
%  Copyright Bitplane AG 2011
%  Modified by Amar Bhagwat (Sept 2016)
%
%
%  Installation:
%
%  - Copy this file into the XTensions folder in the Imaris installation directory.
%  - You will find this function in the Image Processing menu
%
%    <CustomTools>
%      <Menu>
%       <Submenu name="Tracks Functions">
%        <Item name="Arrest Coefficient" icon="Matlab" tooltip="Calculate the arrest coefficient for the tracks.">
%          <Command>MatlabXT::XTTrackPlotArrCoeff(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSpots">
%          <Item name="Arrest Coefficient" icon="Matlab" tooltip="Calculate the arrest coefficient for the tracks.">
%            <Command>MatlabXT::XTTrackPlotArrCoeff(%i)</Command>
%          </Item>
%        </SurpassComponent>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Arrest Coefficient" icon="Matlab" tooltip="Calculate the arrest coefficient for the tracks.">
%            <Command>MatlabXT::XTTrackPlotArrCoeff(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%
%  Description:
%   
%	This function will calculate the arrest coefficient track defined as the percentage of steps that 
%	move the spot locally (less than a threshold) as compared to the total number of steps. 
%	This number is of interest in studying the effect of virus on intracellular motion of endosomes
%   
%

function XTTrackPlotArrCoeff(aImarisApplicationID,aThreshold)

% connect to Imaris interface
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
  javaaddpath ImarisLib.jar
  vImarisLib = ImarisLib;
  if ischar(aImarisApplicationID)
    aImarisApplicationID = round(str2double(aImarisApplicationID));
  end
  vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
  vImarisApplication = aImarisApplicationID;
end

% the user has to create a scene with some tracks
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
  msgbox('Please create some tracks in the surpass scene!');
  return
end

% get the selected object (spots or surfaces)
% read coordinates, time points and number of objects
vFactory = vImarisApplication.GetFactory;
vObjects = vImarisApplication.GetSurpassSelection;
vScene = vObjects.GetParent;
if vFactory.IsSpots(vObjects) %each spot gets the following data
  vObjects = vFactory.ToSpots(vObjects);
  vCoords = vObjects.GetPositionsXYZ; %3 element array denoting [X,Y,Z]position
  vTimes = vObjects.GetIndicesT + 1; % time frame the spot belongs to (MATLAB index starts at 1)
  vRadius = vObjects.GetRadiiXYZ; %X,Y,Z radii of the ellipsoid fit to the spot
  vNumberOfObjects = numel(vTimes); % number of objects found
  vTrackIds = vObjects.GetTrackIds; % unique ID of track that the spot belong to
else
  msgbox('Please select some spots!')
  return
end

% get the edges
vEdges = vObjects.GetTrackEdges + 1; % add correction of 1, because indices start from 1 in Matlab

if isempty(vEdges)  
  msgbox('Please select some tracks!')
  return
end


vNumberOfEdges = size(vEdges, 1);
vListofTracks=unique(vTrackIds); % array of unique track IDs
%initialize arrays to hold calculations
vTrackMaxDisp=nan(length(vListofTracks),1);
vTrackLength=nan(length(vListofTracks),1);
vTrackDur=nan(length(vListofTracks),1);
vTrackTotDisp=nan(length(vListofTracks),1);
vArrestCoeff=nan(length(vListofTracks),1);
vAvgVel=nan(length(vListofTracks),1);
vAnswer = inputdlg('Please enter the arrest coefficient threshold in um (diffraction limit is a good estimate):', '', 1, {'0.4'});
if isempty(vAnswer), return, end
aArrCoeffTh=str2double(char(vAnswer)); % threshold for defining "small step"
vJostling=nan(length(vListofTracks),1);
vStepsTotal=0;
nStepsTotal=0;
vDurOfEdgesTrk=nan(length(vEdges(:,1)),1);
vAngBetEdgesTrk=nan(length(vEdges(:,1)),1);

for idx=1:length(vListofTracks)
 
	% figure out the spots belonging to the current track
	vTrackEdges=vEdges(vTrackIds == vListofTracks(idx),:);
	vStart = vCoords(vTrackEdges(:,1),:); % array of starting points of edges
	vEnd =  vCoords(vTrackEdges(:,2),:); % array of end points of the same edges
	vStepsRaw=(vEnd-vStart);
	vStepsSq=sum((vEnd-vStart).^2,2);
	vSteps = sqrt(vStepsSq); % length of steps what make up the track
	vStepsTotal = vStepsTotal + sum(vStepsSq);
	nStepsTotal=nStepsTotal + length(vSteps);
	vDurOfEdgesTrk(vTrackIds == vListofTracks(idx)) = length(vSteps)*ones(length(vSteps),1);
	vAngles = nan(length(vSteps),1);
	if length(vSteps > 1)
		vArrestCoeff(idx)=sum(vSteps<aArrCoeffTh)/length(vSteps); % percentage of steps that are < 0.15 um
		vAvgVel(idx)=sum(vSteps)/length(vSteps);
		initVec = num2cell(vStepsRaw(1:end-1,:),2);
		finalVec = num2cell(vStepsRaw(2:end,:),2);
		dotVec=cellfun(@dot,initVec,finalVec);
		crossVec=cellfun(@norm,cellfun(@cross,initVec,finalVec,'UniformOutput',false));
		vAngles(1:length(vSteps)-1) = atan2(crossVec,dotVec);
		vAngBetEdgesTrk(vTrackIds == vListofTracks(idx)) = vAngles;
		%%
		% vVelocity=(vEnd-vStart);
		% vAccel =diff(vVelocity);
		% vVel_trunc=vVelocity(1:end-1);
		% vImpulse = sqrt((sum(vAccel.*vAccel,2)))./sqrt((sum(vVel_trunc.*vVel_trunc,2)));
		% vJostling(idx) = sum(vImpulse)/(length(vImpulse));
		% msgbox(['length of vec: ', num2str(size(vAccel)), '   length of impulse: ', num2str(length(vImpulse))]);
		% next calculate displacement from start of track to each point on the track
		vExcursion=sqrt(sum((vEnd-ones(numel(vEnd)/3,1)*vStart(1,:)).^2,2)); 
		vTrackLength(idx)=sum(vSteps); % total track length
		vTrackDur(idx)=length(vSteps); % total track length
		vTrackMaxDisp(idx) = max(vExcursion); % maximum excursion from starting position of track
		vTrackTotDisp(idx) = sqrt(sum((vEnd(numel(vEnd)/3,:)-vStart(1,:)).^2, 2)); %distance from start to end
	end
end

MSD=vStepsTotal/nStepsTotal;

% ask user for filename to write to
[xlsfilename, xlspathname] = uiputfile('*.xlsx','Save data to excel spreadsheet');
comp_path = fullfile(xlspathname,xlsfilename);
% if no spots, exit
if isempty(xlsfilename), return, end

% % figure 1
% % 2-D histogram of track steps differentiated by track lengths
vStartAll = vCoords(vEdges(:,1),:); % array of starting points of edges
vEndAll =  vCoords(vEdges(:,2),:); % array of end points of the same edges

vStepsAllSq=sum((vEndAll-vStartAll).^2,2);
vStepsAll = sqrt(vStepsAllSq); % length of steps what make up the track
vStepsDurAll=[vStepsAll,vDurOfEdgesTrk];
edges{1}=0:0.01:1;
edges{2}=0:1:20;
N1=hist3(vStepsDurAll,'Edges', edges);

% write a worksheet with information about spots: location, timestamp, intensity, and distance from coverslip
data_out=double(N1(1:end-1,2:end));
data_cells=num2cell(data_out);     %Convert data to cell array
col_header=['Horz axis: track duration','bin edges',num2cell(edges{2})];     % column labels
row_header=['Vert axis: arrest coeff','bin edges',num2cell(edges{1})];
% output_matrix=[ col_header; [row_header',data_cells]];     %Join cell arrays
format long 
xlswrite(comp_path,  col_header, 'steps vs track duration','C1');
xlswrite(comp_path,  row_header, 'steps vs track duration','C2');
xlswrite(comp_path,  data_cells, 'steps vs track duration','C4');


%figure2
% combined histogram of all step distributions combined together
figure;
h=histogram(vStepsAll,0:0.005:1);
dhist=h.Values;
histcum=cumsum(dhist);
%disp(['array 1 size: ',num2str(size(h.BinEdges(1:end-1)+h.BinWidth/2)), 'array 2 size: ',num2str(size(h.Values))]);
data_out=double([h.BinEdges(1:end-1)+h.BinWidth/2;h.Values;histcum]);
data_cells=num2cell(data_out');     %Convert data to cell array
col_header={'bin center','histogram','cumulative'};     % column labels

output_matrix=[ col_header; data_cells];     %Join cell arrays
format long 
xlswrite(comp_path,  output_matrix, 'steps histo and cumulative');

figure;
h=polarhistogram(vAngBetEdgesTrk,180);
data_out=double([h.BinEdges(1:end-1)+h.BinWidth/2;h.Values]);
data_cells=num2cell(data_out');     %Convert data to cell array
col_header={'bin center','histogram'};     % column labels

output_matrix=[ col_header; data_cells];     %Join cell arrays
format long 
xlswrite(comp_path,  output_matrix, 'inter-step angle hist');

% % diagnostic data - number of tracks
% disp(size(vdualvec(~isnan(vdualvec(:,1)),1)));

% % display the calculated mean square displacement (MSD)
% % based on steps displacement, not track displacement
disp(['MSD: ',num2str(MSD)]);

% % figure 3
figure;

% arrest coefficient histogram
% hist_bins=0:0.01:1;
% histogram(vArrestCoeff,hist_bins);

% 2-D histrogram of arrest coeff vs track length
vdualvec=[vArrestCoeff,vTrackLength];
edges{1}=0:0.01:1;
edges{2}=0:0.1:5;
N1=hist3(vdualvec,'Edges', edges);
set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
data_out=double(N1(1:end-1,2:end));
data_cells=num2cell(data_out);     %Convert data to cell array
col_header=['Horz axis: track length','bin edges',num2cell(edges{2})];     % column labels
row_header=['Vert axis: arrest coeff','bin edges',num2cell(edges{1})];
% output_matrix=[ col_header; [row_header',data_cells]];     %Join cell arrays
format long 
xlswrite(comp_path,  col_header, 'arrest coeff vs. track length','C1');
xlswrite(comp_path,  row_header, 'arrest coeff vs. track length','C2');
xlswrite(comp_path,  data_cells, 'arrest coeff vs. track length','C4');

% % figure 4
% % distribution of total displacements
% figure;
% histogram(vTrackTotDisp, [200]);

% % figure 5
% distribution of track durations
figure;
h=histogram(vTrackDur, 0:1:20);
data_out=double([h.BinEdges(1:end-1)+h.BinWidth/2;h.Values]);
data_cells=num2cell(data_out');     %Convert data to cell array
col_header={'bin center','histogram'};     % column labels

output_matrix=[ col_header; data_cells];     %Join cell arrays
format long 
xlswrite(comp_path,  output_matrix, 'histogram of track durations');

% %xlabel('Avg velocity');ylabel('tracklength');
% %set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');