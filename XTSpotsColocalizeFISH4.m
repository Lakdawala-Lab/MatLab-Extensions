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
%        <Item name="Colocalize 4 FISH Spots" icon="Matlab">
%          <Command>MatlabXT::XTSpotsColocalizeFISH4(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSpots">
%          <Item name="Colocalize 4 FISH Spots" icon="Matlab">
%            <Command>MatlabXT::XTSpotsColocalizeFISH4(%i)</Command>
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
%	spot colocalization to sets of 4 spots (1, 2, 3 and 4) and identifies 
%	ones that exclusively form pairs (1-2, 1-3, 1-4, 2-3, 2-4, 3-4) and 
%	ones that form triples (1-2-3, 1-2-4, 1-3-4, 2-3-4) and ones that form 
%	quadruples (1-2-3-4). Non colocalized spots are also listed separately.
% 
% 
%

function XTSpotsColocalizeFISH4(aImarisApplicationID, aThreshold)

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
vNumberOfSpots = 0; % initialize count of spot sets
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

% warn about insufficient number of spots
if vNumberOfSpots<4
    msgbox('Please create at least 4 spots objects!');
    return;
end

vNamesList = vNamesList(1:vNumberOfSpots);

% choose the 4 spots for coloc. check that 2 or more are selected
vPair = [];
while length(vPair) < 4
    [vPair, vOk] = listdlg('ListString',vNamesList,'SelectionMode','multiple',...
        'ListSize',[250 150],'Name','Colocalize spots','InitialValue',[1,2], ...
        'PromptString',{'Please select the four spots to colocalize:'});
    if vOk<1, return, end
    if length(vPair) < 2
        vHandle = msgbox(['Please select four (4) objects. Use "Control" and left ', ...
            'click to select/unselect an object of the list. For fewer than 4 sets, use one of the other functions.']);
        uiwait(vHandle);
    end
end
% copy 4 sets of spots into memory
vSpots1 = vSpotsList{vPair(1)};
vSpots2 = vSpotsList{vPair(2)};
vSpots3 = vSpotsList{vPair(3)};
vSpots4 = vSpotsList{vPair(4)};

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

%positions and times for third set of spots
vSpotsXYZ3 = vSpots3.GetPositionsXYZ;
vTime3 = vSpots3.GetIndicesT;
vRadius3 = vSpots3.GetRadiiXYZ;
vID3 = vSpots3.GetIds;

%positions and times for fourth set of spots
vSpotsXYZ4 = vSpots4.GetPositionsXYZ;
vTime4 = vSpots4.GetIndicesT;
vRadius4 = vSpots4.GetRadiiXYZ;
vID4 = vSpots4.GetIds;
%end

%waitbar((vTime-vStart+1)/(vEnd-vStart+1), vProgressDisplay);
%close(vProgressDisplay);

% Identify all 6 possible pairings amongst 4 sets of spots
% coloc matrix for 1with2
[v1Coloc2,v2Coloc1,m1Coloc2] = two_sets_coloc(vID1,vID2,vTime1, vTime2, vSpotsXYZ1, vSpotsXYZ2,vThresholdSquare);
m2Coloc1=m1Coloc2.';
% coloc matrix for 2with3
[v2Coloc3,v3Coloc2,m2Coloc3] = two_sets_coloc(vID2,vID3,vTime2, vTime3, vSpotsXYZ2, vSpotsXYZ3,vThresholdSquare);
m3Coloc2=m2Coloc3.';
% coloc matrix for 1with3
[v1Coloc3,v3Coloc1,m1Coloc3] = two_sets_coloc(vID1,vID3,vTime1, vTime3, vSpotsXYZ1, vSpotsXYZ3,vThresholdSquare);
m3Coloc1=m1Coloc3.';
% coloc matrix for 3with4
[v3Coloc4,v4Coloc3,m3Coloc4] = two_sets_coloc(vID3,vID4,vTime3, vTime4, vSpotsXYZ3, vSpotsXYZ4,vThresholdSquare);
m4Coloc3=m3Coloc4.';
% coloc matrix for 1with4
[v1Coloc4,v4Coloc1,m1Coloc4] = two_sets_coloc(vID1,vID4,vTime1, vTime4, vSpotsXYZ1, vSpotsXYZ4,vThresholdSquare);
m4Coloc1=m1Coloc4.';
% coloc matrix for 2with4
[v2Coloc4,v4Coloc2,m2Coloc4] = two_sets_coloc(vID2,vID4,vTime2, vTime4, vSpotsXYZ2, vSpotsXYZ4,vThresholdSquare);
m4Coloc2=m2Coloc4.';

% alert user that at least one of the pairings has no colocated spots
if isempty(find(v1Coloc2, 1)) || isempty(find(v1Coloc3, 1)) || isempty(find(v3Coloc2, 1)) || isempty(find(v1Coloc4, 1)) || isempty(find(v2Coloc4, 1)) || isempty(find(v3Coloc4, 1))
    msgbox('At least one of the sets has no colocated spots.');
    return
end

%temporary quadruples to be refined below
v1quad_tmp = v1Coloc2 & v1Coloc3 & v1Coloc4;
v2quad_tmp = v2Coloc1 & v2Coloc3 & v2Coloc4;
v3quad_tmp = v3Coloc2 & v3Coloc1 & v3Coloc4;
v4quad_tmp = v4Coloc1 & v4Coloc2 & v4Coloc3;

% if spot from set 1 is a quad, force the associated spots
% from sets 2,3, and 4 to be associated with each other. This is 
% necessary because for example 1 may be within threshold distance of 
% 2,3 and 4, and so is listed as a quadruple
% but 2 and 3 may be just out of reach of each other. This will force them
% to listed as an associated pair. Below, we do this for each quadruple
% found in sets 1,2,3, and 4

% force 2,3,4 to form pairs if 1 forms quadruples with 2,3 and 4.
for nt=1:numel(v1quad_tmp)
    if v1quad_tmp(nt) == true
        v2Coloc3(find(m1Coloc2(nt,:) > 0)) = true;
        v3Coloc2(find(m1Coloc3(nt,:) > 0)) = true;
        v2Coloc4(find(m1Coloc2(nt,:) > 0)) = true;
        v4Coloc2(find(m1Coloc4(nt,:) > 0)) = true;
        v3Coloc4(find(m1Coloc3(nt,:) > 0)) = true;
        v4Coloc3(find(m1Coloc4(nt,:) > 0)) = true;
    end
end

% similarly for 1,3,4
for nt=1:numel(v2quad_tmp)
    if v2quad_tmp(nt) == true
        v1Coloc3(find(m2Coloc1(nt,:) > 0)) = true;
        v3Coloc1(find(m2Coloc3(nt,:) > 0)) = true;
        v1Coloc4(find(m2Coloc1(nt,:) > 0)) = true;
        v4Coloc1(find(m2Coloc4(nt,:) > 0)) = true;
        v3Coloc4(find(m2Coloc3(nt,:) > 0)) = true;
        v4Coloc3(find(m2Coloc4(nt,:) > 0)) = true;
    end
end

% similarly for 1,2,4
for nt=1:numel(v3quad_tmp)
    if v3quad_tmp(nt) == true
        v1Coloc2(find(m3Coloc1(nt,:) > 0)) = true;
        v2Coloc1(find(m3Coloc2(nt,:) > 0)) = true;
        v1Coloc4(find(m3Coloc1(nt,:) > 0)) = true;
        v4Coloc1(find(m3Coloc4(nt,:) > 0)) = true;
        v2Coloc4(find(m3Coloc2(nt,:) > 0)) = true;
        v4Coloc2(find(m3Coloc4(nt,:) > 0)) = true;
    end
end

%similarly for 1,2,3
for nt=1:numel(v4quad_tmp)
    if v4quad_tmp(nt) == true
        v1Coloc2(find(m4Coloc1(nt,:) > 0)) = true;
        v2Coloc1(find(m4Coloc2(nt,:) > 0)) = true;
        v1Coloc3(find(m4Coloc1(nt,:) > 0)) = true;
        v3Coloc1(find(m4Coloc3(nt,:) > 0)) = true;
        v2Coloc3(find(m4Coloc2(nt,:) > 0)) = true;
        v3Coloc2(find(m4Coloc3(nt,:) > 0)) = true;
    end
end

% finalize designation as quadruples using the forced association above
v1quad = v1Coloc2 & v1Coloc3 & v1Coloc4;
v2quad = v2Coloc1 & v2Coloc3 & v2Coloc4;
v3quad = v3Coloc1 & v3Coloc2 & v3Coloc4;
v4quad = v4Coloc1 & v4Coloc2 & v4Coloc3;

% now for the triples... 12 of them... bear with me here.
%
% if spot from set 1 is a triple, force the associated spots
% from sets 2,3 to be associated with each other. This is 
% necessary because, for example, 1 may be within threshold distance of 
% 2,3 and so is listed as a triple
% but 2 and 3 may be just out of reach of each other. This will force them
% to listed as an associated pair. Below, we do this for each triple
% found in sets 1,2,3

% #1 calculating for 1,2,3
v1triple23_tmp = v1Coloc2 & v1Coloc3 & ~v1Coloc4;
v2triple31_tmp = v2Coloc1 & v2Coloc3 & ~v2Coloc4;
v3triple12_tmp = v3Coloc1 & v3Coloc2 & ~v3Coloc4;
	
for nt=1:numel(v1triple23_tmp)
	if v1triple23_tmp(nt) == true
		v2Coloc3(find(m1Coloc2(nt,:) > 0)) = true;
		v3Coloc2(find(m1Coloc3(nt,:) > 0)) = true;	
	end
end


for nt=1:numel(v2triple31_tmp)
	if v2triple31_tmp(nt) == true
		v1Coloc3(find(m2Coloc1(nt,:) > 0)) = true;
		v3Coloc1(find(m2Coloc3(nt,:) > 0)) = true;
	end
end


for nt=1:numel(v3triple12_tmp)
	if v3triple12_tmp(nt) == true
		v1Coloc2(find(m3Coloc1(nt,:) > 0)) = true;
		v2Coloc1(find(m3Coloc2(nt,:) > 0)) = true;
	end
end
    
v1triple23 = v1Coloc2 & v1Coloc3 & ~v1Coloc4;
v2triple31 = v2Coloc1 & v2Coloc3 & ~v2Coloc4;
v3triple12 = v3Coloc1 & v3Coloc2 & ~v3Coloc4;

% #2 calculating for 1,2,4
v1triple24_tmp = v1Coloc2 & ~v1Coloc3 & v1Coloc4;
v2triple41_tmp = v2Coloc1 & ~v2Coloc3 & v2Coloc4;
v4triple12_tmp = v4Coloc1 & v4Coloc2 & ~v4Coloc3;
	
for nt=1:numel(v1triple24_tmp)
	if v1triple24_tmp(nt) == true
		v2Coloc4(find(m1Coloc2(nt,:) > 0)) = true;
		v4Coloc2(find(m1Coloc4(nt,:) > 0)) = true;	
	end
end


for nt=1:numel(v2triple41_tmp)
	if v2triple41_tmp(nt) == true
		v1Coloc4(find(m2Coloc1(nt,:) > 0)) = true;
		v4Coloc1(find(m2Coloc4(nt,:) > 0)) = true;
	end
end


for nt=1:numel(v4triple12_tmp)
	if v4triple12_tmp(nt) == true
		v1Coloc2(find(m4Coloc1(nt,:) > 0)) = true;
		v2Coloc1(find(m4Coloc2(nt,:) > 0)) = true;
	end
end
    
v1triple24 = v1Coloc2 & ~v1Coloc3 & v1Coloc4;
v2triple41 = v2Coloc1 & ~v2Coloc3 & v2Coloc4;
v4triple12 = v4Coloc1 & v4Coloc2 & ~v4Coloc3;

% #3 calculating for 1,3,4
v1triple34_tmp = ~v1Coloc2 & v1Coloc3 & v1Coloc4;
v3triple41_tmp = v3Coloc1 & ~v3Coloc2 & v3Coloc4;
v4triple13_tmp = v4Coloc1 & ~v4Coloc2 & v4Coloc3;
	
for nt=1:numel(v1triple34_tmp)
	if v1triple34_tmp(nt) == true
		v3Coloc4(find(m1Coloc3(nt,:) > 0)) = true;
		v4Coloc3(find(m1Coloc4(nt,:) > 0)) = true;	
	end
end


for nt=1:numel(v3triple41_tmp)
	if v3triple41_tmp(nt) == true
		v4Coloc1(find(m3Coloc4(nt,:) > 0)) = true;
		v1Coloc4(find(m3Coloc1(nt,:) > 0)) = true;
	end
end


for nt=1:numel(v4triple13_tmp)
	if v4triple13_tmp(nt) == true
		v1Coloc3(find(m4Coloc1(nt,:) > 0)) = true;
		v3Coloc1(find(m4Coloc3(nt,:) > 0)) = true;
	end
end
    
v1triple34 = ~v1Coloc2 & v1Coloc3 & v1Coloc4;
v3triple41 = v3Coloc1 & ~v3Coloc2 & v3Coloc4;
v4triple13 = v4Coloc1 & ~v4Coloc2 & v4Coloc3;

% #4 calculating for 2,3, 4
v2triple34_tmp = ~v2Coloc1 & v2Coloc3 & v2Coloc4;
v3triple42_tmp = ~v3Coloc1 & v3Coloc2 & v3Coloc4;
v4triple23_tmp = ~v4Coloc1 & v4Coloc2 & v4Coloc3;
	
for nt=1:numel(v2triple34_tmp)
	if v2triple34_tmp(nt) == true
		v3Coloc4(find(m2Coloc3(nt,:) > 0)) = true;
		v4Coloc3(find(m2Coloc4(nt,:) > 0)) = true;	
	end
end


for nt=1:numel(v3triple42_tmp)
	if v3triple42_tmp(nt) == true
		v4Coloc2(find(m3Coloc4(nt,:) > 0)) = true;
		v2Coloc4(find(m3Coloc2(nt,:) > 0)) = true;
	end
end


for nt=1:numel(v4triple23_tmp)
	if v4triple23_tmp(nt) == true
		v2Coloc3(find(m4Coloc2(nt,:) > 0)) = true;
		v3Coloc2(find(m4Coloc3(nt,:) > 0)) = true;
	end
end
    
v2triple34 = ~v2Coloc1 & v2Coloc3 & v2Coloc4;
v3triple42 = ~v3Coloc1 & v3Coloc2 & v3Coloc4;
v4triple23 = ~v4Coloc1 & v4Coloc2 & v4Coloc3;

% also define doubles both ways eg. 1&2 and 2&1
v1double2 = (v1Coloc2 & ~v1Coloc3 & ~v1Coloc4);
v1double3 = (~v1Coloc2 & v1Coloc3 & ~v1Coloc4);
v1double4 = (~v1Coloc2 & ~v1Coloc3 & v1Coloc4);

v2double1 = (v2Coloc1 & ~v2Coloc3 & ~v2Coloc4);
v2double3 = (~v2Coloc1 & v2Coloc3 & ~v2Coloc4);
v2double4 = (~v2Coloc1 & ~v2Coloc3 & v2Coloc4);

v3double2 = (v3Coloc2 & ~v3Coloc1 & ~v3Coloc4);
v3double1 = (~v3Coloc2 & v3Coloc1 & ~v3Coloc4);
v3double4 = (~v3Coloc2 & ~v3Coloc1 & v3Coloc4);

v4double1 = (v4Coloc1 & ~v4Coloc2 & ~v4Coloc3);
v4double2 = (~v4Coloc1 & v4Coloc2 & ~v4Coloc3);
v4double3 = (~v4Coloc1 & ~v4Coloc2 & v4Coloc3);

% find the spots that are singles
v1single = ~v1Coloc2 & ~v1Coloc3 & ~v1Coloc4;
v2single = ~v2Coloc1 & ~v2Coloc3 & ~v2Coloc4;
v3single = ~v3Coloc1 & ~v3Coloc2 & ~v3Coloc4;
v4single = ~v4Coloc1 & ~v4Coloc2 & ~v4Coloc3;


% analysis done, make new groups in Imaris for the singles, doubles and
% quads

% create new group
vSpotsGroup = vImarisApplication.GetFactory.CreateDataContainer;

vSpotsGroup.SetName(sprintf('Coloc[%.2f] %s | %s | %s | %s', ...
    vThreshold, char(vSpots1.GetName), char(vSpots2.GetName), ...
    char(vSpots3.GetName), char(vSpots4.GetName)));

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

vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4single, :), vTime4(v4single), zeros(sum(v4single),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4single,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' singles']);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

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

%1 with 4 only
vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots1.Set(vSpotsXYZ1(v1double4, :), vTime1(v1double4), zeros(sum(v1double4),1));
vNewSpots1.SetRadiiXYZ(vRadius1(v1double4,:));
vNewSpots1.SetName([char(vSpots1.GetName), ' & ', char(vSpots4.GetName),' only']);
vRGBA = vSpots1.GetColorRGBA;
vNewSpots1.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots1, -1);

%4 with 1 only
vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4double1, :), vTime4(v4double1), zeros(sum(v4double1),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4double1,:));
vNewSpots4.SetName([char(vSpots4.GetName),' & ', char(vSpots1.GetName), ' only']);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

%4 with 3 only
vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4double3, :), vTime4(v4double3), zeros(sum(v4double3),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4double3,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' & ', char(vSpots3.GetName), ' only']);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

%3 with 4 only
vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots3.Set(vSpotsXYZ3(v3double4, :), vTime3(v3double4), zeros(sum(v3double4),1));
vNewSpots3.SetRadiiXYZ(vRadius3(v3double4,:));
vNewSpots3.SetName([char(vSpots3.GetName),' & ', char(vSpots4.GetName), ' only']);
vRGBA = vSpots3.GetColorRGBA;
vNewSpots3.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots3, -1);

%4 with 2 only
vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4double2, :), vTime4(v4double2), zeros(sum(v4double2),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4double2,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' & ', char(vSpots2.GetName), ' only']);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

%2 with 4 only
vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots2.Set(vSpotsXYZ2(v2double4, :), vTime2(v2double4), zeros(sum(v2double4),1));
vNewSpots2.SetRadiiXYZ(vRadius2(v2double4,:));
vNewSpots2.SetName([char(vSpots2.GetName),' & ', char(vSpots4.GetName), ' only']);
vRGBA = vSpots2.GetColorRGBA;
vNewSpots2.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots2, -1);

% triple spots 1,2,3
vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots1.Set(vSpotsXYZ1(v1triple23, :), vTime1(v1triple23), zeros(sum(v1triple23),1));
vNewSpots1.SetRadiiXYZ(vRadius1(v1triple23,:));
vNewSpots1.SetName([char(vSpots1.GetName), ' triples with', char(vSpots2.GetName), ' and ', char(vSpots3.GetName)]);
vRGBA = vSpots1.GetColorRGBA;
vNewSpots1.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots1, -1);

vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots2.Set(vSpotsXYZ2(v2triple31, :), vTime2(v2triple31), zeros(sum(v2triple31),1));
vNewSpots2.SetRadiiXYZ(vRadius2(v2triple31,:));
vNewSpots2.SetName([char(vSpots2.GetName), ' triples with', char(vSpots3.GetName), ' and ', char(vSpots1.GetName)]);
vRGBA = vSpots2.GetColorRGBA;
vNewSpots2.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots2, -1);

vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots3.Set(vSpotsXYZ3(v3triple12, :), vTime3(v3triple12), zeros(sum(v3triple12),1));
vNewSpots3.SetRadiiXYZ(vRadius3(v3triple12,:));
vNewSpots3.SetName([char(vSpots3.GetName), ' triples with', char(vSpots1.GetName), ' and ', char(vSpots2.GetName)]);
vRGBA = vSpots3.GetColorRGBA;
vNewSpots3.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots3, -1);

% triple spots 1,2,4
vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots1.Set(vSpotsXYZ1(v1triple24, :), vTime1(v1triple24), zeros(sum(v1triple24),1));
vNewSpots1.SetRadiiXYZ(vRadius1(v1triple24,:));
vNewSpots1.SetName([char(vSpots1.GetName), ' triples with', char(vSpots2.GetName), ' and ', char(vSpots4.GetName)]);
vRGBA = vSpots1.GetColorRGBA;
vNewSpots1.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots1, -1);

vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots2.Set(vSpotsXYZ2(v2triple41, :), vTime2(v2triple41), zeros(sum(v2triple41),1));
vNewSpots2.SetRadiiXYZ(vRadius2(v2triple41,:));
vNewSpots2.SetName([char(vSpots2.GetName), ' triples with', char(vSpots4.GetName), ' and ', char(vSpots1.GetName)]);
vRGBA = vSpots2.GetColorRGBA;
vNewSpots2.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots2, -1);

vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4triple12, :), vTime4(v4triple12), zeros(sum(v4triple12),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4triple12,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' triples with', char(vSpots1.GetName), ' and ', char(vSpots2.GetName)]);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

% triple spots 1,3,4
vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots1.Set(vSpotsXYZ1(v1triple34, :), vTime1(v1triple34), zeros(sum(v1triple34),1));
vNewSpots1.SetRadiiXYZ(vRadius1(v1triple34,:));
vNewSpots1.SetName([char(vSpots1.GetName), ' triples with', char(vSpots3.GetName), ' and ', char(vSpots4.GetName)]);
vRGBA = vSpots1.GetColorRGBA;
vNewSpots1.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots1, -1);

vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots3.Set(vSpotsXYZ3(v3triple41, :), vTime3(v3triple41), zeros(sum(v3triple41),1));
vNewSpots3.SetRadiiXYZ(vRadius3(v3triple41,:));
vNewSpots3.SetName([char(vSpots3.GetName), ' triples with', char(vSpots4.GetName), ' and ', char(vSpots1.GetName)]);
vRGBA = vSpots3.GetColorRGBA;
vNewSpots3.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots3, -1);

vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4triple13, :), vTime4(v4triple13), zeros(sum(v4triple13),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4triple13,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' triples with', char(vSpots1.GetName), ' and ', char(vSpots3.GetName)]);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

% triple spots 2,3,4
vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots2.Set(vSpotsXYZ2(v2triple34, :), vTime2(v2triple34), zeros(sum(v2triple34),1));
vNewSpots2.SetRadiiXYZ(vRadius2(v2triple34,:));
vNewSpots2.SetName([char(vSpots2.GetName), ' triples with', char(vSpots3.GetName), ' and ', char(vSpots4.GetName)]);
vRGBA = vSpots2.GetColorRGBA;
vNewSpots2.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots2, -1);

vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots3.Set(vSpotsXYZ3(v3triple42, :), vTime3(v3triple42), zeros(sum(v3triple42),1));
vNewSpots3.SetRadiiXYZ(vRadius3(v3triple42,:));
vNewSpots3.SetName([char(vSpots3.GetName), ' triples with', char(vSpots4.GetName), ' and ', char(vSpots2.GetName)]);
vRGBA = vSpots3.GetColorRGBA;
vNewSpots3.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots3, -1);

vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4triple23, :), vTime4(v4triple23), zeros(sum(v4triple23),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4triple23,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' triples with', char(vSpots2.GetName), ' and ', char(vSpots3.GetName)]);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);

% quadruple spots
vNewSpots1 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots1.Set(vSpotsXYZ1(v1quad, :), vTime1(v1quad), zeros(sum(v1quad),1));
vNewSpots1.SetRadiiXYZ(vRadius1(v1quad,:));
vNewSpots1.SetName([char(vSpots1.GetName), ' quads']);
vRGBA = vSpots1.GetColorRGBA;
vNewSpots1.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots1, -1);

vNewSpots2 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots2.Set(vSpotsXYZ2(v2quad, :), vTime2(v2quad), zeros(sum(v2quad),1));
vNewSpots2.SetRadiiXYZ(vRadius2(v2quad,:));
vNewSpots2.SetName([char(vSpots2.GetName), ' quads']);
vRGBA = vSpots2.GetColorRGBA;
vNewSpots2.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots2, -1);

vNewSpots3 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots3.Set(vSpotsXYZ3(v3quad, :), vTime3(v3quad), zeros(sum(v3quad),1));
vNewSpots3.SetRadiiXYZ(vRadius3(v3quad,:));
vNewSpots3.SetName([char(vSpots3.GetName), ' quads']);
vRGBA = vSpots3.GetColorRGBA;
vNewSpots3.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots3, -1);

vNewSpots4 = vImarisApplication.GetFactory.CreateSpots;
vNewSpots4.Set(vSpotsXYZ4(v4quad, :), vTime4(v4quad), zeros(sum(v4quad),1));
vNewSpots4.SetRadiiXYZ(vRadius4(v4quad,:));
vNewSpots4.SetName([char(vSpots4.GetName), ' quads']);
vRGBA = vSpots4.GetColorRGBA;
vNewSpots4.SetColorRGBA(vRGBA);
vSpotsGroup.AddChild(vNewSpots4, -1);
   
% set parent spots invisible so that user can see the colocalization
vSpots1.SetVisible(0);
vSpots2.SetVisible(0);
vSpots3.SetVisible(0);
vSpots4.SetVisible(0);

vScene.AddChild(vSpotsGroup, -1);


function [v1Coloc2,v2Coloc1,m1Coloc2] = two_sets_coloc(vIDLcl1, vIDLcl2, vTimeLcl1, vTimeLcl2, vSpotsXYZLcl1, vSpotsXYZLcl2,vThresholdSquare)
% This function that finds colocalized spots 1 with 2 and 2 with 1. 
% It also returns a 2-d matrix that keeps a record of which spot from 
% set 1 colocates with spot from set 22

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
