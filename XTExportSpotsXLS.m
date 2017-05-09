%
%
%  Connect Tracks Function for Imaris 7.3.0
%
%  Copyright Bitplane AG 2011
%  Modified by Amar Bhagwat
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
%        <Item name="Export spots details as XLS" icon="Matlab" tooltip="Export spots details.">
%          <Command>MatlabXT::XTExportSpotsXLS(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSpots">
%          <Item name="Export spots details as XLS">
%            <Command>MatlabXT::XTExportSpotsXLS(%i)</Command>
%          </Item>
%        </SurpassComponent>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Export spots details as XLS.">
%            <Command>MatlabXT::XTExportSpotsXLS(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%
%  Description:
%   
%   Export details of spots objects including PositionXYZ, RadiiXYZ,
%   Timestamps, Edges, merge locations, split locations. This will be 
%   written to an XLS file chosen by the user.
%   
%

function XTExportSpotsXLS(aImarisApplicationID)

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

% the user has to create a scene with some surpass components
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
  msgbox('Please create some tracks in the surpass scene!');
  return
end

% get the selected object (spots or surfaces)
% read coordinates, time points and number of objects
vFactory = vImarisApplication.GetFactory;
vObjects = vImarisApplication.GetSurpassSelection;
vDataSet = vImarisApplication.GetDataSet;
if vFactory.IsSpots(vObjects)
  vObjects = vFactory.ToSpots(vObjects);
  vCoords = vObjects.GetPositionsXYZ;
  vTimes = vObjects.GetIndicesT + 1;
  vRadius = vObjects.GetRadiiXYZ;
  vNumberOfObjects = numel(vTimes);
  vScene = vObjects.GetParent;
elseif vFactory.IsSurfaces(vObjects)
  vObjects = vFactory.ToSurfaces(vObjects);
  vNumberOfObjects = vObjects.GetNumberOfSurfaces;
  vCoords = zeros(vNumberOfObjects, 3);
  vTimes = ones(vNumberOfObjects, 1);
  for vIndex = 1:vNumberOfObjects
    vCoords(vIndex, :) = vObjects.GetCenterOfMass(vIndex - 1);
    vTimes(vIndex) = vObjects.GetTimeIndex(vIndex - 1) + 1;
  end
else
  msgbox('Please select some spots or surfaces!')
  return
end

% initialize some variables to be used later
vTimeEnd=max(vTimes);
vIntSpot  = zeros(numel(vTimes), 1);
vDistSpot = zeros(numel(vTimes), 1);
vSplitTrue= false(numel(vTimes), 1);
vMergeTrue = false(numel(vTimes), 1);

% get the edges
vEdges = vObjects.GetTrackEdges + 1; % indices start from 1 here (matlab)
if isempty(vEdges)  
  msgbox('Please select some tracks!')
  return
end
vNumberOfEdges = size(vEdges, 1);

%%%%%%%%%%%% get clipping plane info%%%%%%%%%
vScenePar=vScene.GetParent;
vNumberOfClippingPlanes = 0;
vCPList{vScenePar.GetNumberOfChildren} = [];
vCPNamesList{vScenePar.GetNumberOfChildren} = [];
for vChildIndex = 1:vScenePar.GetNumberOfChildren
    vDataItem = vScenePar.GetChild(vChildIndex - 1);
    if vImarisApplication.GetFactory.IsClippingPlane(vDataItem)
        vNumberOfClippingPlanes = vNumberOfClippingPlanes+1;
        vCPList{vNumberOfClippingPlanes} = vImarisApplication.GetFactory.ToClippingPlane(vDataItem);
        vCPNamesList{vNumberOfClippingPlanes} = char(vDataItem.GetName);
    end
end

if vNumberOfClippingPlanes<1
    msgbox('Please define at least 1 Clipping Plane');
    return;
end

vCPNamesList = vCPNamesList(1:vNumberOfClippingPlanes);

% choose the clipping plane
vCPName = [];
while length(vCPName) < 1
    [vCPName, vOk] = listdlg('ListString',vCPNamesList,'SelectionMode','multiple',...
        'ListSize',[250 150],'Name','Select clipping plane','InitialValue',[1], ...
        'PromptString',{'Please select one clipping plane to measure distance:'});
    if vOk<1, return, end
    if length(vCPName) < 1
        vHandle = msgbox(['Please select only one objects. Use "Control" and left ', ...
            'click to select/unselect an object of the list.']);
        uiwait(vHandle);
    end
end

vPlane = vCPList{vCPName(1)};
vPlaneXYZ = vPlane.GetPosition;
vClippingPlaneValues=vPlane.GetOrientationAxisAngle;
vAxis = vClippingPlaneValues.mAxisXYZ;
vAngle = vClippingPlaneValues.mAngle;
vQuaternion=vPlane.GetOrientationQuaternion;

% diagnostics for clipping plane. Uncomment the code below to troubleshoot
% any problems with the clipping plane information

%	message = sprintf(['Plane position: [',num2str(vPlaneXYZ'),' ] \n', ...
%		'Axis: [', num2str(vAxis'),' ] \n',... 
%		'Angle: [', num2str(vAngle) ,' ] \n',...
%		'Quaternion: [', num2str(vQuaternion') ]);
%	msgbox(message);

% calculate quantity 'd' for clipping plane. This number is 
% to be used later to calculate distance from the coverslip
d = vPlaneXYZ(1)-vPlaneXYZ(3);

%%%%%%%%%%%%%%% get spot intensity info

vProgressDisplay = waitbar(0,'Getting spots intensity information');
% dataset dimensions
vExtMin = [vDataSet.GetExtendMinX, vDataSet.GetExtendMinY, vDataSet.GetExtendMinZ];
vExtMax = [vDataSet.GetExtendMaxX, vDataSet.GetExtendMaxY, vDataSet.GetExtendMaxZ];
vSize = [vDataSet.GetSizeX, vDataSet.GetSizeY, vDataSet.GetSizeZ];
vVoxelSize = (vExtMax - vExtMin) ./ vSize;

% find the extrema of the time index
vStart = min(vTimes);
vEnd = max(vTimes);

%iterate over the time index
for vTime = vStart:vEnd
	% boolean vector for spots at the right time
    vValid1 = find(vTimes == vTime); %present

	%iterate over each spot   
	for vSpot1 = 1:numel(vValid1)
		vColocated1 = vValid1(vSpot1); % index of the present spot
		vSpotCoordXYZ=int32(floor((vCoords(vColocated1, :)-vExtMin)./vVoxelSize));
		try
			tempInt = vDataSet.GetDataSubVolumeShorts(vSpotCoordXYZ(1), vSpotCoordXYZ(2), vSpotCoordXYZ(3), int32(0), int32(vTime-1), int32(1), int32(1), int32(1)) ;
		catch 
			% This section is executed if there is a problem getting spot intensity
			% for one or two glitches, this will not matter, but if a large number 
			% of spots fail to get an intensity, there is a bigger problem that should
			% be investigated
			tempInt=zeros(1,1,1);
			msgbox(['Warning: failed to acquire intensity for spot ',num2str(vColocated1)]);
		end
		vIntSpot (vColocated1) = mean(mean(mean(tempInt)));
		vDistSpot(vColocated1) = (1/sqrt(2))*(-vCoords(vColocated1, 1)+vCoords(vColocated1, 3)+d);
	end
	% update the progress bar
    waitbar(double(vTime-vStart+1)/double(vEnd-vStart+1), vProgressDisplay);

end
close(vProgressDisplay);

% ask user for filename to write to
[xlsfilename, xlspathname] = uiputfile('*.xlsx','Save data to excel spreadsheet');
comp_path = fullfile(xlspathname,xlsfilename);
% if no spots, exit
if isempty(xlsfilename), return, end

% write a worksheet with information about spots: location, timestamp, intensity, and distance from coverslip
data_out=double([double(vCoords),double(vTimes), double(vIntSpot),double(vDistSpot)]);
data_cells=num2cell(data_out);     %Convert data to cell array
col_header={'Position X','Position Y','Position Z','TimeStamp','Intensity','Dist to Coverslip'};     % column labels
output_matrix=[ col_header; data_cells];     %Join cell arrays
format long 
xlswrite(comp_path,  output_matrix, 'spots info');

% write another worksheet with information about track edges
% each row contains a two values: index of spot where an edge begins 
% and index of spot where that edge ends. This describes a single edge of the track network
data_cells2=num2cell(double(vEdges));     %Convert data to cell array
col_header2={'start index','end index'};     %Row cell array (for column labels)
output_matrix2=[ col_header2; data_cells2];
xlswrite(comp_path,  output_matrix2, 'track edges');