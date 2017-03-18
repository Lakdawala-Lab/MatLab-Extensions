%  Colocalize Spot Function for Imaris 8.4.1
%
%  Copyright Bitplane 2015
%  Modified by Amar Bhagwat 2016
%
%  Installation:
%
%  - Copy this file into the XTensions folder in the Imaris installation directory
%  - You will find this function in the Image Processing menu
%
%    <CustomTools>
%      <Menu>
%       <Submenu name="Spots Functions">
%        <Item name="Colocalize FISH Spots" icon="Matlab">
%          <Command>MatlabXT::XTSpotsColocalizeFISH(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSpots">
%          <Item name="Colocalize FISH Spots" icon="Matlab">
%            <Command>MatlabXT::XTSpotsColocalizeFISH(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%
%  Description:
%   
%   This extension identifies spots that are colocalized with each other
%	within a user specified distance in micrometers. This scripts extends
%	spot colocalization to sets of 3 spots (A,B, and C) and identifies 
%	ones that exclusively form pairs (A-B, A-C, B-C) and ones that form
%	triples (A-B-C). Non colocalized spots are also listed separately.
% 
%

function XTSpotsColocalizeFISH(aImarisApplicationID, aThreshold)

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

% the user has to create a scene with some spots
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
    msgbox('Please create some Spots in the Surpass scene!');
    return;
end

% find how many spots are in the scene
vSpots = vImarisApplication.GetSurpassSelection;
vSpotsSelected = vImarisApplication.GetFactory.IsSpots(vSpots);

if vSpotsSelected
    vScene = vSpots.GetParent;
else
    vScene = vImarisApplication.GetSurpassScene;
end
vNumberOfSpots = 0;
vSpotsList{vScene.GetNumberOfChildren} = [];
vNamesList{vScene.GetNumberOfChildren} = [];
for vChildIndex = 1:vScene.GetNumberOfChildren
    vDataItem = vScene.GetChild(vChildIndex - 1);
    if vImarisApplication.GetFactory.IsSpots(vDataItem)
        vNumberOfSpots = vNumberOfSpots+1;
        vSpotsList{vNumberOfSpots} = vImarisApplication.GetFactory.ToSpots(vDataItem);
        vNamesList{vNumberOfSpots} = char(vDataItem.GetName);
    end
end

if vNumberOfSpots<2
    msgbox('Please create at least 2 spots objects!');
    return;
end

vNamesList = vNamesList(1:vNumberOfSpots);

% choose the 2 spots for coloc. check that 2 or more are selected
vPair = [];
while length(vPair) < 2
    [vPair, vOk] = listdlg('ListString',vNamesList,'SelectionMode','multiple',...
        'ListSize',[250 150],'Name','Colocalize spots','InitialValue',[1,2], ...
        'PromptString',{'Please select at least 2 spots to colocalize:'});
    if vOk<1, return, end
    if length(vPair) < 2
        vHandle = msgbox(['Please select at least two (2) objects. Use "Control" and left ', ...
            'click to select/unselect an object of the list.']);
        uiwait(vHandle);
    end
end

vSpots1 = vSpotsList{vPair(1)};
vSpots2 = vSpotsList{vPair(2)};

if length(vPair)==3
    vSpots3 = vSpotsList{vPair(3)};
end

% ask for threshold
if nargin<2
    vQuestion = {sprintf(['Get the spots with distance <= threshold. \n', ...
        'Please enter the threshold value now:'])};
    vAnswer = inputdlg(vQuestion,'Colocalize spots',1,{'0.2'});
    if isempty(vAnswer), return, end
    vThreshold = str2double(vAnswer{1});
else
    vThreshold = aThreshold;
end
vThresholdSquare = vThreshold.^2;

%vProgressDisplay = waitbar(0,'Colocalizing spots');

%positions and times for first set of spots
vSpotsXYZ1 = vSpots1.GetPositionsXYZ;
vTime1 = vSpots1.GetIndicesT;
vRadius1 = vSpots1.GetRadiiXYZ;
vID1 = vSpots1.GetIds;

%positions and times for second set of spots
vSpotsXYZ2 = vSpots2.GetPositionsXYZ;
vTime2 = vSpots2.GetIndicesT;
vRadius2 = vSpots2.GetRadiiXYZ;
vID2 = vSpots2.GetIds;

if length(vPair) == 3
    %positions and times for third set of spots
    vSpotsXYZ3 = vSpots3.GetPositionsXYZ;
    vTime3 = vSpots3.GetIndicesT;
    vRadius3 = vSpots3.GetRadiiXYZ;
	vID3 = vSpots3.GetIds;
end

%waitbar((vTime-vStart+1)/(vEnd-vStart+1), vProgressDisplay);
%close(vProgressDisplay);

[v1Coloc2,v2Coloc1,m1Coloc2] = two_sets_coloc(vID1,vID2,vTime1, vTime2, vSpotsXYZ1, vSpotsXYZ2,vThresholdSquare);
m2Coloc1=m1Coloc2.';
if length(vPair) == 3
    [v2Coloc3,v3Coloc2,m2Coloc3] = two_sets_coloc(vID2,vID3,vTime2, vTime3, vSpotsXYZ2, vSpotsXYZ3,vThresholdSquare);
    m3Coloc2=m2Coloc3.';
	[v1Coloc3,v3Coloc1,m1Coloc3] = two_sets_coloc(vID1,vID3,vTime1, vTime3, vSpotsXYZ1, vSpotsXYZ3,vThresholdSquare);
	m3Coloc1=m1Coloc3.';
end

if isempty(find(v1Coloc2, 1)) && isempty(find(v1Coloc3, 1)) && isempty(find(v3Coloc2, 1))
    msgbox('There are no colocated spots.');
    return
end

if length(vPair) == 2
	%find unpaired spots in 2 sets
    v1single = ~v1Coloc2;
    v2single = ~v2Coloc1;
elseif length(vPair) == 3
	% find unpaired spots in 3 sets
    v1single = ~v1Coloc2 & ~v1Coloc3;
    v2single = ~v2Coloc1 & ~v2Coloc3;
    v3single = ~v3Coloc1 & ~v3Coloc2;
    
	% find spots that are part of a triple
    v1triple_tmp = v1Coloc2 & v1Coloc3;
	v2triple_tmp = v2Coloc1 & v2Coloc3;
	v3triple_tmp = v3Coloc2 & v3Coloc1;
	
	% force all spots in a triple to be colocated
	% for example - if A-B and A-C are a pair, then force B-C to be
	% a pair as well. This is to overcome any pairs that may not get counted
	% on account of chromatic aberration. Do this for each set (A, B and
	% C).
	
	for nt=1:numel(v1triple_tmp)
		if v1triple_tmp(nt) == true
			v2Coloc3(find(m1Coloc2(nt,:) > 0)) = true;
			v3Coloc2(find(m1Coloc3(nt,:) > 0)) = true;	
		end
	end
    	
	for nt=1:numel(v2triple_tmp)
		if v2triple_tmp(nt) == true
			v1Coloc3(find(m2Coloc1(nt,:) > 0)) = true;
			v3Coloc1(find(m2Coloc3(nt,:) > 0)) = true;
		end
	end
    	
	for nt=1:numel(v3triple_tmp)
		if v3triple_tmp(nt) == true
			v1Coloc2(find(m3Coloc1(nt,:) > 0)) = true;
			v2Coloc1(find(m3Coloc2(nt,:) > 0)) = true;
		end
	end
    
	% now finalize the triples using the newly forced doubles
	v1triple = v1Coloc2 & v1Coloc3;
	v2triple = v2Coloc1 & v2Coloc3;
	v3triple = v3Coloc2 & v3Coloc1;
	
	% now finalize the exclusive doubles using the forced doubles data from
	% above
    v1double2 = (v1Coloc2 & ~v1Coloc3);
	v1double3 = (~v1Coloc2 & v1Coloc3);
    v2double1 = (v2Coloc1 & ~v2Coloc3);
	v2double3 = (~v2Coloc1 & v2Coloc3);
    v3double2 = (v3Coloc2 & ~v3Coloc1);
	v3double1 = (~v3Coloc2 & v3Coloc1);
    
end

% create new group
vSpotsGroup = vImarisApplication.GetFactory.CreateDataContainer;
if length(vPair) == 2
    vSpotsGroup.SetName(sprintf('Coloc[Threshold = %.2f um] %s | %s', ...
        vThreshold, char(vSpots1.GetName), char(vSpots2.GetName)));
    vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots1.Set(vSpotsXYZ1(v1Coloc2, :), vTime1(v1Coloc2), zeros(sum(v1Coloc2),1));
    vNewSpots1.SetRadiiXYZ(vRadius1(v1Coloc2,:));
    vNewSpots1.SetName([char(vSpots1.GetName), ' colocated']);
    vRGBA = vSpots1.GetColorRGBA;
    vNewSpots1.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots1, -1);

    vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots1.Set(vSpotsXYZ1(v1single, :), vTime1(v1single), zeros(sum(v1single),1));
    vNewSpots1.SetRadiiXYZ(vRadius1(v1single,:));
    vNewSpots1.SetName([char(vSpots1.GetName), ' singles']);
    vRGBA = vSpots1.GetColorRGBA;
    vNewSpots1.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots1, -1);

    vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots2.Set(vSpotsXYZ2(v2Coloc1, :), vTime2(v2Coloc1), zeros(sum(v2Coloc1),1));
    vNewSpots2.SetRadiiXYZ(vRadius2(v2Coloc1,:));
    vNewSpots2.SetName([char(vSpots2.GetName),' colocated']);
    vRGBA = vSpots2.GetColorRGBA;
    vNewSpots2.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots2, -1);

    vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots2.Set(vSpotsXYZ2(v2single, :), vTime2(v2single), zeros(sum(v2single),1));
    vNewSpots2.SetRadiiXYZ(vRadius2(v2single,:));
    vNewSpots2.SetName([char(vSpots2.GetName), ' singles']);
    vRGBA = vSpots2.GetColorRGBA;
    vNewSpots2.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots2, -1);

elseif length(vPair) == 3
    vSpotsGroup.SetName(sprintf('Coloc[%.2f] %s | %s | %s', ...
        vThreshold, char(vSpots1.GetName), char(vSpots2.GetName),char(vSpots3.GetName)));
    %single spots
    vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots1.Set(vSpotsXYZ1(v1single, :), vTime1(v1single), zeros(sum(v1single),1));
    vNewSpots1.SetRadiiXYZ(vRadius1(v1single,:));
    vNewSpots1.SetName([char(vSpots1.GetName), ' singles']);
    vRGBA = vSpots1.GetColorRGBA;
    vNewSpots1.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots1, -1);
    
    vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots2.Set(vSpotsXYZ2(v2single, :), vTime2(v2single), zeros(sum(v2single),1));
    vNewSpots2.SetRadiiXYZ(vRadius2(v2single,:));
    vNewSpots2.SetName([char(vSpots2.GetName), ' singles']);
    vRGBA = vSpots2.GetColorRGBA;
    vNewSpots2.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots2, -1);
    
    vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots3.Set(vSpotsXYZ3(v3single, :), vTime3(v3single), zeros(sum(v3single),1));
    vNewSpots3.SetRadiiXYZ(vRadius3(v3single,:));
    vNewSpots3.SetName([char(vSpots3.GetName), ' singles']);
    vRGBA = vSpots3.GetColorRGBA;
    vNewSpots3.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots3, -1);
    
	%1 with 2 only
    vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots1.Set(vSpotsXYZ1(v1double2, :), vTime1(v1double2), zeros(sum(v1double2),1));
    vNewSpots1.SetRadiiXYZ(vRadius1(v1double2,:));
    vNewSpots1.SetName([char(vSpots1.GetName), ' & ', char(vSpots2.GetName),' only']);
    vRGBA = vSpots1.GetColorRGBA;
    vNewSpots1.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots1, -1);

    %2 with 1 only
    vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots2.Set(vSpotsXYZ2(v2double1, :), vTime2(v2double1), zeros(sum(v2double1),1));
    vNewSpots2.SetRadiiXYZ(vRadius2(v2double1,:));
    vNewSpots2.SetName([char(vSpots2.GetName),' & ', char(vSpots1.GetName), ' only']);
    vRGBA = vSpots2.GetColorRGBA;
    vNewSpots2.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots2, -1);
    
    %1 with 3 only
    vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots1.Set(vSpotsXYZ1(v1double3, :), vTime1(v1double3), zeros(sum(v1double3),1));
    vNewSpots1.SetRadiiXYZ(vRadius1(v1double3,:));
    vNewSpots1.SetName([char(vSpots1.GetName), ' & ', char(vSpots3.GetName), ' only']);
    vRGBA = vSpots1.GetColorRGBA;
    vNewSpots1.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots1, -1);

    %3 with 1 only
    vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots3.Set(vSpotsXYZ3(v3double1, :), vTime3(v3double1), zeros(sum(v3double1),1));
    vNewSpots3.SetRadiiXYZ(vRadius3(v3double1,:));
    vNewSpots3.SetName([char(vSpots3.GetName),' & ', char(vSpots1.GetName), ' only']);
    vRGBA = vSpots3.GetColorRGBA;
    vNewSpots3.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots3, -1);
    
    %3 with 2 only
    vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots3.Set(vSpotsXYZ3(v3double2, :), vTime3(v3double2), zeros(sum(v3double2),1));
    vNewSpots3.SetRadiiXYZ(vRadius3(v3double2,:));
    vNewSpots3.SetName([char(vSpots3.GetName), ' & ', char(vSpots2.GetName), ' only']);
    vRGBA = vSpots3.GetColorRGBA;
    vNewSpots3.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots3, -1);
    
    %2 with 3 only
    vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots2.Set(vSpotsXYZ2(v2double3, :), vTime2(v2double3), zeros(sum(v2double3),1));
    vNewSpots2.SetRadiiXYZ(vRadius2(v2double3,:));
    vNewSpots2.SetName([char(vSpots2.GetName),' & ', char(vSpots3.GetName), ' only']);
    vRGBA = vSpots2.GetColorRGBA;
    vNewSpots2.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots2, -1);
	
    % triple spots
    vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots1.Set(vSpotsXYZ1(v1triple, :), vTime1(v1triple), zeros(sum(v1triple),1));
    vNewSpots1.SetRadiiXYZ(vRadius1(v1triple,:));
    vNewSpots1.SetName([char(vSpots1.GetName), ' triples']);
    vRGBA = vSpots1.GetColorRGBA;
    vNewSpots1.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots1, -1);
    
    vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots2.Set(vSpotsXYZ2(v2triple, :), vTime2(v2triple), zeros(sum(v2triple),1));
    vNewSpots2.SetRadiiXYZ(vRadius2(v2triple,:));
    vNewSpots2.SetName([char(vSpots2.GetName), ' triples']);
    vRGBA = vSpots2.GetColorRGBA;
    vNewSpots2.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots2, -1);
    
    vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots3.Set(vSpotsXYZ3(v3triple, :), vTime3(v3triple), zeros(sum(v3triple),1));
    vNewSpots3.SetRadiiXYZ(vRadius3(v3triple,:));
    vNewSpots3.SetName([char(vSpots3.GetName), ' triples']);
    vRGBA = vSpots3.GetColorRGBA;
    vNewSpots3.SetColorRGBA(vRGBA);
    vSpotsGroup.AddChild(vNewSpots3, -1);
    
    
end
    

% set the parent spots invisible so that the user can see the colocated
% spots only
vSpots1.SetVisible(0);
vSpots2.SetVisible(0);
if length(vPair)==3
    vSpots3.SetVisible(0);
end
vScene.AddChild(vSpotsGroup, -1);

function [v1Coloc2,v2Coloc1,m1Coloc2] = two_sets_coloc(vIDLcl1, vIDLcl2, vTimeLcl1, vTimeLcl2, vSpotsXYZLcl1, vSpotsXYZLcl2,vThresholdSquare)

% initialize coloc to zero
v1Coloc2 = false(numel(vTimeLcl1), 1);
v2Coloc1 = false(numel(vTimeLcl2), 1);
m1Coloc2 = false(numel(vTimeLcl1), numel(vTimeLcl2));

vTimeLcl1 = double(vTimeLcl1);
vTimeLcl2 = double(vTimeLcl2);

% common time slot when both spots exist
vStart = max([min(vTimeLcl1), min(vTimeLcl2)]);
vEnd = min([max(vTimeLcl1), max(vTimeLcl2)]);

% for each time point, find valid spots on each of the 2 lists
for vTime = vStart:vEnd
    vValid1 = find(vTimeLcl1 == vTime);
    vValid2 = find(vTimeLcl2 == vTime);

    vXYZ = vSpotsXYZLcl2(vValid2, :);
    for vSpot1 = 1:numel(vValid1)
        vColocated1 = vValid1(vSpot1);
        % find distances from given spot from list 1 to all spots
        % on list 2
        vX = vXYZ(:, 1) - vSpotsXYZLcl1(vColocated1, 1);
        vY = vXYZ(:, 2) - vSpotsXYZLcl1(vColocated1, 2);
        vZ = vXYZ(:, 3) - vSpotsXYZLcl1(vColocated1, 3);
        
        % Boolean vector of coloq spots from list 2 against the
        % given spot from list 1
        vDistanceList = vX.^2 + vY.^2 + vZ.^2 <= vThresholdSquare;
        
        % select spots from list 2 that colocate with given spot from
        % list 1
        vColocated2 = vValid2(vDistanceList);
        if ~isempty(vColocated2)
            v1Coloc2(vColocated1) = true;
            v2Coloc1(vColocated2) = true;
			for idx=1:numel(vColocated2)
				m1Coloc2(vColocated1,vColocated2(idx)) = true;
			end
        end
    end
    
 
end
