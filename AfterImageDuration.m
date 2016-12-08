function varargout = AfterImageDuration(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @AfterImageDuration_OpeningFcn, ...
    'gui_OutputFcn',  @AfterImageDuration_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
function AfterImageDuration_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

function varargout = AfterImageDuration_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

function RefSpotDiameter_Callback(hObject, eventdata, handles)

function RefSpotLatency_Callback(hObject, eventdata, handles)

function RefSpotIntensity_Callback(hObject, eventdata, handles)

function RefSpotXPosition_Callback(hObject, eventdata, handles)

function RefSpotYPosition_Callback(hObject, eventdata, handles)

function StiSpotDiameter_Callback(hObject, eventdata, handles)

function StiSpotDuration_Callback(hObject, eventdata, handles)

function StiSpotIntensity_Callback(hObject, eventdata, handles)

function PxPerCm_Callback(hObject, eventdata, handles)

function ViewDistance_Callback(hObject, eventdata, handles)

function FixPointXPosition_Callback(hObject, eventdata, handles)

function FixPointYPosition_Callback(hObject, eventdata, handles)

function FixPointSize_Callback(hObject, eventdata, handles)

function FixPointColor_Callback(hObject, eventdata, handles)

function BackgroundColor_Callback(hObject, eventdata, handles)

function StiSpotXPosition_Callback(hObject, eventdata, handles)

function StiSpotYPosition_Callback(hObject, eventdata, handles)

function Trials_Callback(hObject, eventdata, handles)

function AIDCalibFile_Callback(hObject, eventdata, handles)

function CloseButton_Callback(hObject, eventdata, handles)
global sM scr el
close(sM)
Eyelink('StopRecording');
Screen('CloseAll');
sca
clear sM scr el

function InitializeButton_Callback(hObject, eventdata, handles)
global sM scr fixationWindow el fixWinSize rectColor
fn = get(handles.AIDCalibFile, 'String');
calibrationFile=load(fn);
if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
	calibrationFile = calibrationFile.c;
else 
	calibrationFile = [];
end
KbName('UnifyKeyNames');
screenNumber=max(Screen('Screens'));
windowed = [];
backgroundColor = str2num(get(handles.BackgroundColor,'String'));
pixelsPerCm = str2num(get(handles.PxPerCm,'String'));
distance = str2num(get(handles.ViewDistance,'String'));

%-----------------------open the PTB screens------------------------
sM = screenManager('verbose',false,'blend',true,'screen',screenNumber,...
	'pixelsPerCm',pixelsPerCm,...
	'distance',distance,'bitDepth','FloatingPoint32BitIfPossible',...
	'debug',false,'antiAlias',0,'nativeBeamPosition',0, ...
	'srcMode','GL_SRC_ALPHA','dstMode','GL_ONE_MINUS_SRC_ALPHA',...
	'windowed',windowed,'backgroundColour',[backgroundColor 0],...
	'gammaTable', calibrationFile); %use a temporary screenManager object
screenVals = open(sM); %open PTB screen
scr.w = sM.win;
scr.screenRect = sM.winRect;
scr.ifi = sM.screenVals.ifi;
scr.ppd = sM.ppd;

fixWinSize = 1.5*scr.ppd; % deg change to pixel ;30; %pixel

rectColor = 0;
sM.drawCross;sM.flip;
%% eyelink init & Calibration ----lixh
dummymode=0;
% Provide Eyelink with details about the graphics environment
% and perform some initializations. The information is returned
% in a structure that also contains useful defaults
% and control codes (e.g. tracker state bit and Eyelink key values).
window = scr.w;
el=EyelinkInitDefaults(window);
el.backgroundcolour = BlackIndex(el.window);
el=EyelinkInitDefaults(window);
% Initialization of the connection with the Eyelink Gazetracker.
% exit program if this fails.
if ~EyelinkInit(dummymode, 1)
    fprintf('Eyelink Init aborted.\n');
    cleanup;  % cleanup function
    return;
end
%   SET UP TRACKER CONFIGURATION
Eyelink('command', 'calibration_type = HV5');
%	set parser (conservative saccade thresholds)
Eyelink('command', 'saccade_velocity_threshold = 35');
Eyelink('command', 'saccade_acceleration_threshold = 9500');
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA');
% you must call this function to apply the changes from above
%     EyelinkUpdateDefaults(el);

% Calibrate the eye tracker

EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection

%EyelinkDoDriftCorrection(el);

% STEP 5
% start recording eye position

function fix = infixationWindow(mx,my)
global fixationWindow
% determine if gx and gy are within fixation window
fix = mx > fixationWindow(1) &&  mx <  fixationWindow(3) && ...
    my > fixationWindow(2) && my < fixationWindow(4) ;



function FillFixPointFunction(hObject, eventdata, handles)
global sM scr fixWinSize rectColor
FixPointSize = str2num(get(handles.FixPointSize,'String'))*scr.ppd;
FixPointXPosition = str2num(get(handles.FixPointXPosition,'String'));
FixPointYPosition = str2num(get(handles.FixPointYPosition,'String'));
FixPointColor = str2num(get(handles.FixPointColor,'String'));
Screen('FillRect',scr.w,rectColor,[FixPointXPosition-fixWinSize/2 FixPointYPosition-fixWinSize/2 FixPointXPosition+fixWinSize/2 FixPointYPosition+fixWinSize/2]);
sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
Screen('Flip',scr.w);


function RefreshButton_Callback(hObject, eventdata, handles)
global sM scr
BackgroundColor = str2num(get(handles.BackgroundColor,'String'));
sM.drawBackground;
sM.drawCross; sM.flip;

function StartButton_Callback(hObject, eventdata, handles)
global sM scr el fixationWindow fixWinSize
Eyelink('StartRecording');
out_percent = 0;
sM.drawBackground; sM.flip;
StiSpotDiameter = str2num(['[' get(handles.StiSpotDiameter,'string') ']']).*scr.ppd;
StiSpotDuration = str2num(['[' get(handles.StiSpotDuration,'string') ']']);
StiSpotIntensity = str2num(['[' get(handles.StiSpotIntensity,'string') ']']);
StiSpotPosition = [str2num(get(handles.StiSpotXPosition,'string')) str2num(get(handles.StiSpotYPosition,'string'))];
RefSpotDiameter = str2num(get(handles.RefSpotDiameter,'string'))*scr.ppd;
RefSpotIntensity = str2num(get(handles.RefSpotIntensity,'string'));
RefSpotLatency = str2num(['[' get(handles.RefSpotLatency,'string') ']']);
RefSpotPosition = [str2num(get(handles.RefSpotXPosition,'string')) str2num(get(handles.RefSpotYPosition,'string'))];
Trials = str2num(get(handles.Trials,'string'));
KbName('UnifyKeyNames');
fButton = KbName('F');
cButton = KbName('C');
escButton = KbName('escape');
leftButton = KbName('leftarrow');
rightButton = KbName('rightarrow');
downButton = KbName('downarrow');
upButton = KbName('uparrow');
index = [];
for i=1:Trials
    index = [index randperm(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency))];
end
index_StiSpotDiameter = ceil(index/length(StiSpotDuration)/length(StiSpotIntensity)/length(RefSpotLatency));
remain = mod(index-1, length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency))+ 1;
index_StiSpotDuration = ceil(remain/length(StiSpotIntensity)/length(RefSpotLatency));
remain = mod(remain-1, length(StiSpotIntensity)*length(RefSpotLatency))+ 1;
index_StiSpotIntensity = ceil(remain/length(RefSpotLatency));
remain = mod(remain-1, length(RefSpotLatency))+ 1;
index_RefSpotLatency = remain;
Screen('DrawText',scr.w,'Hold Button F to START!',scr.screenRect(3)/2-50,scr.screenRect(4)/2+200);
FixPointSize = str2num(get(handles.FixPointSize,'String'));
FixPointXPosition = str2num(get(handles.FixPointXPosition,'String'));
FixPointYPosition = str2num(get(handles.FixPointYPosition,'String'));
FixPointColor = [0 0 0 1]; %str2num(get(handles.FixPointColor,'String'));
sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
sM.flip;

EyeData = [];
error_index1 = [];
error_index2 = [];
error_index3 = [];
error_index4 = [];
ResponseMatrix = zeros(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency),7);
for i=1:length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency)*Trials
    ResponseMatrix(i,1)=StiSpotDiameter(index_StiSpotDiameter(i))/scr.ppd;
    ResponseMatrix(i,2)=StiSpotDuration(index_StiSpotDuration(i));
    ResponseMatrix(i,3)=StiSpotIntensity(index_StiSpotIntensity(i));
    ResponseMatrix(i,4)=RefSpotLatency(index_RefSpotLatency(i));
    [s, keyCode, deltaSecs] = KbPressWait;
    while keyCode(fButton)~=1
        [s, keyCode, deltaSecs] = KbPressWait;
    end
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
    WaitSecs(2*rand(1));
    ResponseMatrix(i,7)=1; %if no out win,value is 1
    
    X = [];
    Y = [];
    XX = [];
    YY = [];
    broke = 0;
    %%
    sM.drawBackground;
    Screen('FillOval', scr.w, StiSpotIntensity(index_StiSpotIntensity(i)),[StiSpotPosition(1)-StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)-StiSpotDiameter(index_StiSpotDiameter(i))/2; ...
        StiSpotPosition(1)+StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)+StiSpotDiameter(index_StiSpotDiameter(i))/2]);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
    vbl = Screen('Flip', scr.w, scr.ifi);
    %      vbl = Screen('Flip',scr.w);
    vblendtime = GetSecs + StiSpotDuration(index_StiSpotDuration(i));
    while(GetSecs < vblendtime)
        %%
        error=Eyelink('CheckRecording');
        if(error~=0)
            break;
        end
        
        % check for presence of a new sample update
        
        %         if Eyelink( 'NewFloatSampleAvailable') > 0
        % get the sample in the form of an event structure
        evt = Eyelink( 'NewestFloatSample');
        % if we don't, first find eye that's being tracked
        eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
        % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
        if eye_used == 1
            eye_used = 0; % use the left_eye data
        end
        if eye_used == 2
            eye_used = 0; % use the left_eye data
        end
        if eye_used ~= -1 % do we know which eye to use yet?
            % if we do, get current gaze position from sample
            x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
            y = evt.gy(eye_used+1);
            % do we have valid data and is the pupil visible?
            if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                % if data is valid, draw a circle on the screen at current gaze position
                % using PsychToolbox's Screen function
                %                 gazeRect=[ x-3 y-3 x+3 y+3];
                %                 colour=round(rand(3,1)*255); % coloured dot
                %                 Screen('FillOval', window, colour, gazeRect);
                %                 Screen('Flip',  el.window, [], 1); % don't erase
                mx = x;
                my = y;
            else
                mx = 0;
                my = 0;
            end
            
        else
            mx = 0;
            my = 0;
        end
        %         else
        %             mx = 0;
        %             my = 0;
        
        %         end
        X = [X mx];
        Y = [Y my];
        WaitSecs(0.001);
        %%%%%%%%%%%%%%%%%%%%%%%%----eyelink persuit
        
    end
    %%
    XX = X;
    YY = Y;
    %%%%%%%%%%%%计算eyedata范围内的最佳中间值
    X(X==0) = []; %去零
    X = sort(X);
    num = length(X);
    cut_num = round(num*(20/100));  % 取80%的有效范围
    if rem(cut_num,2) ~= 0
        cut_num = cut_num+1;
    end
    xpos = mean(X(1+cut_num/2:end-cut_num/2))
    Y(Y==0) = [];
    Y = sort(Y);
    num = length(Y);
    cut_num = round(num*(20/100));  % 取80%的有效范围
    if rem(cut_num,2) ~= 0
        cut_num = cut_num+1;
    end
    ypos = mean(Y(1+cut_num/2:end-cut_num/2))
    
    fixationWindow = [0 0 fixWinSize fixWinSize];
    fixationWindow = CenterRectOnPoint(fixationWindow, xpos, ypos);
    num_in = 0;
    num_out = 0;
    for ii = 1:length(XX)
        if infixationWindow(XX(ii),YY(ii))
            
            num_in = num_in +1;
        elseif ~infixationWindow(XX(ii),YY(ii))
            
            num_out = num_out +1;
        end
    end
    if (num_out/(num_in+num_out))>out_percent  %>95% broke
        disp('broke fix')
        broke = 1;
    else
        disp('in fix')
    end
    %%
    if broke
        Beeper(el.calibration_failed_beep(1), el.calibration_failed_beep(2), el.calibration_failed_beep(3));
        ResponseMatrix(i,7)=0;%error or out window
        error_index1 = [error_index1 index_StiSpotDiameter(i)];
        error_index2 = [error_index2 index_StiSpotDuration(i)];
        error_index3 = [error_index3 index_StiSpotIntensity(i)];
        error_index4 = [error_index4 index_RefSpotLatency(i)];
    end
    EyeData{i} = [XX;YY];
    
    for j=1:RefSpotLatency(index_RefSpotLatency(i))
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
        vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
        if j==1
            s1 = vbl;
        end
    end
    %     Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
    %     sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    %         
    %     Screen('Flip',scr.w);
    %     [s2, keyCode, deltaSecs] = KbReleaseWait;
    %     ResponseMatrix(i,5)=s2-s1;
    
    Screen('DrawText',scr.w,'Left:  AfterImage appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+200);
    Screen('DrawText',scr.w,'Right: Reference appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+250);
    Screen('DrawText',scr.w,'Down: Unsure.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+300);
    Screen('DrawText',scr.w,'Up: Skip.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+350);
    Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    sM.flip;
    %     WaitSecs(0.5);
    while 1
        [s, keyCode, deltaSecs] = KbWait;
        if keyCode(leftButton) == 1
            ResponseMatrix(i,6)=1;
            break
        elseif keyCode(rightButton) == 1
            ResponseMatrix(i,6)=2;
            break
        elseif keyCode(downButton) == 1
            ResponseMatrix(i,6)=3;
            break
        elseif keyCode(upButton) == 1
            ResponseMatrix(i,6)=4;
            break
        elseif keyCode(escButton) == 1
            sM.drawCross;sM.flip;
            return
			elseif keyCode(cButton) == 1
            EyelinkDoTrackerSetup(el);
            return
        end
    end
    ResponseMatrix(i,5)=s-s1;
    Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    sM.flip;
    WaitSecs(0.2);
    disp(i)
end

%% do trials with out window
% error_index11 = error_index1;
% error_index22 = error_index2;
% error_index33 = error_index3;
% error_index44 = error_index44;
while ~isempty(error_index1)
    error_index11 = error_index1;
    error_index22 = error_index2;
    error_index33 = error_index3;
    error_index44 = error_index4;
    error_index1 = [];
    error_index2 = [];
    error_index3 = [];
    error_index4 = [];
    
    for j=i+1:i+length(error_index11);
        ResponseMatrix(j,1)=StiSpotDiameter(error_index11(j-i))/scr.ppd;
        ResponseMatrix(j,2)=StiSpotDuration(error_index22(j-i));
        ResponseMatrix(j,3)=StiSpotIntensity(error_index33(j-i));
        ResponseMatrix(j,4)=RefSpotLatency(error_index44(j-i));
        [s, keyCode, deltaSecs] = KbPressWait;
        while keyCode(fButton)~=1
            [s, keyCode, deltaSecs] = KbPressWait;
        end
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
         
        %     Screen('FillRect',scr.w,0)
        vbl = Screen('Flip',scr.w);
        WaitSecs(2*rand(1));
        ResponseMatrix(j,7)=1; %if no out win,value is 1
        
        X = [];
        Y = [];
        XX = [];
        YY = [];
        broke = 0;
        %%
        sM.drawBackground;
        Screen('FillOval', scr.w, StiSpotIntensity(error_index33(j-i)),[StiSpotPosition(1)-StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)-StiSpotDiameter(error_index11(j-i))/2; ...
            StiSpotPosition(1)+StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)+StiSpotDiameter(error_index11(j-i))/2]);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
        vbl = Screen('Flip', scr.w, scr.ifi);
        vblendtime = GetSecs + StiSpotDuration(error_index22(j-i));
        while(GetSecs < vblendtime)
            %%
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
            
            % check for presence of a new sample update
            %             if Eyelink( 'NewFloatSampleAvailable') > 0
            % get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            % if we don't, first find eye that's being tracked
            eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
            % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
            if eye_used == 1
                eye_used = 0; % use the left_eye data
            end
            if eye_used == 2
                eye_used = 0; % use the left_eye data
            end
            if eye_used ~= -1 % do we know which eye to use yet?
                % if we do, get current gaze position from sample
                x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                y = evt.gy(eye_used+1);
                % do we have valid data and is the pupil visible?
                if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    % if data is valid, draw a circle on the screen at current gaze position
                    % using PsychToolbox's Screen function
                    %                 gazeRect=[ x-3 y-3 x+3 y+3];
                    %                 colour=round(rand(3,1)*255); % coloured dot
                    %                 Screen('FillOval', window, colour, gazeRect);
                    %                 Screen('Flip',  el.window, [], 1); % don't erase
                    mx = x;
                    my = y;
                else
                    mx = 0;
                    my = 0;
                end
                
            else
                mx = 0;
                my = 0;
            end
            %             else
            %                 mx = 0;
            %                 my = 0;
            
            %             end
            
            X = [X mx];
            Y = [Y my];
            WaitSecs(0.001);
            %%%%%%%%%%%%%%%%%%%%%%%%----eyelink persuit
            
        end
        
        %%
        XX = X;
        YY = Y;
        %%%%%%%%%%%%计算eyedata范围内的最佳中间值
        X(X==0) = []; %去零
        X = sort(X);
        num = length(X);
        cut_num = round(num*(20/100));  % 取80%的有效范围
        if rem(cut_num,2) ~= 0
            cut_num = cut_num+1;
        end
        xpos = mean(X(1+cut_num/2:end-cut_num/2))
        Y(Y==0) = [];
        Y = sort(Y);
        num = length(Y);
        cut_num = round(num*(20/100));  % 取80%的有效范围
        if rem(cut_num,2) ~= 0
            cut_num = cut_num+1;
        end
        ypos = mean(Y(1+cut_num/2:end-cut_num/2))
        
        fixationWindow = [0 0 fixWinSize fixWinSize];
        fixationWindow = CenterRectOnPoint(fixationWindow, xpos, ypos);
        num_in = 0;
        num_out = 0;
        for ii = 1:length(XX)
            if infixationWindow(XX(ii),YY(ii))
                
                num_in = num_in +1;
            elseif ~infixationWindow(XX(ii),YY(ii))
                
                num_out = num_out +1;
            end
        end
        if (num_out/(num_in+num_out))>out_percent  %>95% broke
            disp('broke fix')
            broke = 1;
        else
            disp('in fix')
        end
        if broke
            Beeper(el.calibration_failed_beep(1), el.calibration_failed_beep(2), el.calibration_failed_beep(3));
            ResponseMatrix(j,7)=0; %if no out win,value is 1
            error_index1 = [error_index1 error_index11(j-i)];
            error_index2 = [error_index2  error_index22(j-i)];
            error_index3 = [error_index3  error_index33(j-i)];
            error_index4 = [error_index4  error_index44(j-i)];
        end
        EyeData{j} = [XX;YY];
        
        for jj=1:RefSpotLatency(error_index44(j-i))
            sM.drawBackground;
            sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
            vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
            if jj==1
                s1 = vbl;
            end
        end
        %         Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
        %         sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        %             
        %         Screen('Flip',scr.w);
        %         [s2, keyCode, deltaSecs] = KbReleaseWait;
        %         ResponseMatrix(j,5)=s2-s1;
        
        Screen('DrawText',scr.w,'Left:  AfterImage appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+200);
        Screen('DrawText',scr.w,'Right: Reference appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+250);
        Screen('DrawText',scr.w,'Down: Unsure.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+300);
        Screen('DrawText',scr.w,'Up: Skip.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+350);
        Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);       
        Screen('Flip',scr.w);
        %         WaitSecs(0.5);
        while 1
            [s, keyCode, deltaSecs] = KbWait;
            if keyCode(leftButton) == 1
                ResponseMatrix(j,6)=1;
                break
            elseif keyCode(rightButton) == 1
                ResponseMatrix(j,6)=2;
                break
            elseif keyCode(downButton) == 1
                ResponseMatrix(j,6)=3;
                break
            elseif keyCode(upButton) == 1
                ResponseMatrix(j,6)=4;
                break
            elseif keyCode(escButton) == 1
                sM.drawCross;sM.flip;
                return
            end
        end
        ResponseMatrix(j,5)=s-s1;
        Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
        sM.drawCross;sM.flip;
        WaitSecs(0.2);
        disp(j)
    end
    i = i+length(error_index11);
    %     if j>4  %to many trials ,break
    %         break;
    %     end
end  %until error_index = []
Screen('DrawText',scr.w,'Thank you!',scr.screenRect(3)/2-25,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
filename = strcat(datestr(now,'yyyy-mm-dd-HH-MM-SS'),'.mat');
save (filename, 'ResponseMatrix','EyeData')


% --- Executes on button press in S3StartButton.
function S3StartButton_Callback(hObject, eventdata, handles)
global sM scr el fixationWindow fixWinSize
out_percent = 0;
BackgroundColor = str2num(get(handles.BackgroundColor,'String'));
sM.drawBackground;
% Screen('FillRect',scr.w,0);
Screen('Flip',scr.w);
StiSpotDiameter = str2num(['[' get(handles.StiSpotDiameter,'string') ']']).*scr.ppd;
StiSpotDuration = str2num(['[' get(handles.StiSpotDuration,'string') ']']);
StiSpotIntensity = str2num(['[' get(handles.StiSpotIntensity,'string') ']']);
StiSpotPosition = [str2num(get(handles.StiSpotXPosition,'string')) str2num(get(handles.StiSpotYPosition,'string'))];
RefSpotDiameter = str2num(get(handles.RefSpotDiameter,'string'))*scr.ppd;
RefSpotIntensity = str2num(get(handles.RefSpotIntensity,'string'));
RefSpotLatency = str2num(['[' get(handles.RefSpotLatency,'string') ']']);
RefSpotPosition = [str2num(get(handles.RefSpotXPosition,'string')) str2num(get(handles.RefSpotYPosition,'string'))];
Trials = str2num(get(handles.Trials,'string'));
KbName('UnifyKeyNames');
fButton = KbName('F');
escButton = KbName('escape');
leftButton = KbName('leftarrow');
rightButton = KbName('rightarrow');
downButton = KbName('downarrow');
index = [];
for i=1:Trials
    index = [index randperm(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency))];
end


index_StiSpotDiameter = ceil(index/length(StiSpotDuration)/length(StiSpotIntensity)/length(RefSpotLatency));
remain = mod(index-1, length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency))+ 1;
index_StiSpotDuration = ceil(remain/length(StiSpotIntensity)/length(RefSpotLatency));
remain = mod(remain-1, length(StiSpotIntensity)*length(RefSpotLatency))+ 1;
index_StiSpotIntensity = ceil(remain/length(RefSpotLatency));
remain = mod(remain-1, length(RefSpotLatency))+ 1;
index_RefSpotLatency = remain;
Screen('DrawText',scr.w,'Start!',scr.screenRect(3)/2-50,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
FixPointSize = str2num(get(handles.FixPointSize,'String'))*scr.ppd;
FixPointXPosition = str2num(get(handles.FixPointXPosition,'String'));
FixPointYPosition = str2num(get(handles.FixPointYPosition,'String'));
FixPointColor = str2num(get(handles.FixPointColor,'String'));
sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
% Screen('Flip',scr.w);
%%

% index_intensity_by_latency = randperm(length(index));
intensity0 = [StiSpotIntensity;RefSpotIntensity];
intensity00= [RefSpotIntensity;StiSpotIntensity];
% intensity = [];
% for n = 1:length(index)
%     if n>length(index)/2
%         intensity =  [intensity intensity00];
%     else
%         intensity =  [intensity intensity0];
%     end
% end
intensity = zeros(2,length(index));
for n = 1:length(RefSpotLatency)
    index0 = find(index_RefSpotLatency == n);
    rand_index = randperm(length(index0));
    for nn = 1:length(index0)
        if rem(nn,2)==0
            intensity(:,index0(rand_index(nn))) = intensity00;
        else
            intensity(:,index0(rand_index(nn))) = intensity0;
        end
    end
end
%%
EyeData = [];
error_index1 = [];
error_index2 = [];
error_index3 = [];
error_index4 = [];
ResponseMatrix = zeros(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency),8);
for i=1:length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency)*Trials
    ResponseMatrix(i,1)=StiSpotDiameter(index_StiSpotDiameter(i))/scr.ppd;
    ResponseMatrix(i,2)=StiSpotDuration(index_StiSpotDuration(i));
    %     ResponseMatrix(i,3)=StiSpotIntensity(index_StiSpotIntensity(i));
    ResponseMatrix(i,3)=intensity(1,i);
    ResponseMatrix(i,8)=intensity(2,i);
    ResponseMatrix(i,4)=RefSpotLatency(index_RefSpotLatency(i));
    [s, keyCode, deltaSecs] = KbPressWait;
    while keyCode(fButton)~=1
        [s, keyCode, deltaSecs] = KbPressWait;
    end
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    
    %     Screen('FillRect',scr.w,0)
    
    WaitSecs(2*rand(1));
    ResponseMatrix(i,7)=1; %if no out win,value is 1
    
    X = [];
    Y = [];
    XX = [];
    YY = [];
    broke = 0;
    %%
    sM.drawBackground;
    Screen('FillOval', scr.w, ResponseMatrix(i,3),[StiSpotPosition(1)-StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)-StiSpotDiameter(index_StiSpotDiameter(i))/2; ...
        StiSpotPosition(1)+StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)+StiSpotDiameter(index_StiSpotDiameter(i))/2]);
    Screen('FillOval', scr.w, ResponseMatrix(i,8),[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    
    vbl = Screen('Flip', scr.w);
    %      vbl = Screen('Flip',scr.w);
    vblendtime1 = GetSecs + StiSpotDuration(index_StiSpotDuration(i));
    vblendtime2 = GetSecs + StiSpotDuration(index_StiSpotDuration(i)) + RefSpotLatency(index_RefSpotLatency(i))/1000;
    vblendtime = max(vblendtime1,vblendtime2);
    vblendtime_min = min(vblendtime1,vblendtime2);
    while(GetSecs < vblendtime)
        %% close StiSpot or close RefSpot
        if GetSecs>vblendtime_min && vblendtime1<vblendtime2   %正数，左边先消失
            sM.drawBackground;
            Screen('FillOval', scr.w, ResponseMatrix(i,8),[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
            sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);

            vbl = Screen('Flip', scr.w);
        elseif GetSecs>vblendtime_min && vblendtime1>vblendtime2%%%%负数  右边先消失
            sM.drawBackground;
            Screen('FillOval', scr.w, ResponseMatrix(i,3),[StiSpotPosition(1)-StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)-StiSpotDiameter(index_StiSpotDiameter(i))/2; ...
                StiSpotPosition(1)+StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)+StiSpotDiameter(index_StiSpotDiameter(i))/2]);
            sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);

            vbl = Screen('Flip', scr.w);
        end
        %%
        error=Eyelink('CheckRecording');
        if(error~=0)
            break;
        end
        
        % check for presence of a new sample update
        
        %         if Eyelink( 'NewFloatSampleAvailable') > 0
        % get the sample in the form of an event structure
        evt = Eyelink( 'NewestFloatSample');
        % if we don't, first find eye that's being tracked
        eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
        % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
        if eye_used == 1
            eye_used = 0; % use the left_eye data
        end
        if eye_used == 2
            eye_used = 0; % use the left_eye data
        end
        if eye_used ~= -1 % do we know which eye to use yet?
            % if we do, get current gaze position from sample
            x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
            y = evt.gy(eye_used+1);
            % do we have valid data and is the pupil visible?
            if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                % if data is valid, draw a circle on the screen at current gaze position
                % using PsychToolbox's Screen function
                %                 gazeRect=[ x-3 y-3 x+3 y+3];
                %                 colour=round(rand(3,1)*255); % coloured dot
                %                 Screen('FillOval', window, colour, gazeRect);
                %                 Screen('Flip',  el.window, [], 1); % don't erase
                mx = x;
                my = y;
            else
                mx = 0;
                my = 0;
            end
            
        else
            mx = 0;
            my = 0;
        end
        %         else
        %             mx = 0;
        %             my = 0;
        
        %         end
        X = [X mx];
        Y = [Y my];
        WaitSecs(0.001);
        %%%%%%%%%%%%%%%%%%%%%%%%----eyelink persuit
        
    end
    
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    
    vbl = Screen('Flip', scr.w);
    s1 = vbl;
    
    %%
    XX = X;
    YY = Y;
    %%%%%%%%%%%%计算eyedata范围内的最佳中间值
    X(X==0) = []; %去零
    X = sort(X);
    num = length(X);
    cut_num = round(num*(20/100));  % 取80%的有效范围
    if rem(cut_num,2) ~= 0
        cut_num = cut_num+1;
    end
    xpos = mean(X(1+cut_num/2:end-cut_num/2))
    Y(Y==0) = [];
    Y = sort(Y);
    num = length(Y);
    cut_num = round(num*(20/100));  % 取80%的有效范围
    if rem(cut_num,2) ~= 0
        cut_num = cut_num+1;
    end
    ypos = mean(Y(1+cut_num/2:end-cut_num/2))
    
    fixationWindow = [0 0 fixWinSize fixWinSize];
    fixationWindow = CenterRectOnPoint(fixationWindow, xpos, ypos);
    num_in = 0;
    num_out = 0;
    for ii = 1:length(XX)
        if infixationWindow(XX(ii),YY(ii))
            
            num_in = num_in +1;
        elseif ~infixationWindow(XX(ii),YY(ii))
            
            num_out = num_out +1;
        end
    end
    if (num_out/(num_in+num_out))>out_percent  %>95% broke
        disp('broke fix')
        broke = 1;
    else
        disp('in fix')
    end
    %%
    if broke
        Beeper(el.calibration_failed_beep(1), el.calibration_failed_beep(2), el.calibration_failed_beep(3));
        ResponseMatrix(i,7)=0;%error or out window
        error_index1 = [error_index1 index_StiSpotDiameter(i)];
        error_index2 = [error_index2 index_StiSpotDuration(i)];
        error_index3 = [error_index3 i];
        error_index4 = [error_index4 index_RefSpotLatency(i)];
    end
    EyeData{i} = [XX;YY];
    
    
    
    %     for j=1:RefSpotLatency(index_RefSpotLatency(i))
    %         sM.drawBackground;
    %         sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    %             
    %
    %         vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    %         if j==1
    %             s1 = vbl;
    %         end
    %     end
    %     Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
    %     sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    %         
    %     Screen('Flip',scr.w);
    %     [s2, keyCode, deltaSecs] = KbReleaseWait;
    %     ResponseMatrix(i,5)=s2-s1;
    
    Screen('DrawText',scr.w,'Left:  AfterImage appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+200);
    Screen('DrawText',scr.w,'Right: Reference appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+250);
    Screen('DrawText',scr.w,'Down: Skip.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+300);
    %     Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    Screen('Flip',scr.w);
    %     WaitSecs(0.5);
    while 1
        [s, keyCode, deltaSecs] = KbWait;
        if keyCode(leftButton) == 1
            ResponseMatrix(i,6)=1;
            break
        elseif keyCode(rightButton) == 1
            ResponseMatrix(i,6)=2;
            break
        elseif keyCode(downButton) == 1
            ResponseMatrix(i,6)=3;
            break
     
        elseif keyCode(escButton) == 1
            sM.drawCross;sM.flip;
            return
        end
    end
    ResponseMatrix(i,5)=s-s1;
    Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
    sM.drawCross;sM.flip;
    WaitSecs(0.2);
    disp(i)
end

%% do trials with out window
% error_index11 = error_index1;
% error_index22 = error_index2;
% error_index33 = error_index3;
% error_index44 = error_index44;
while ~isempty(error_index1)
    error_index11 = error_index1;
    error_index22 = error_index2;
    error_index33 = error_index3;
    error_index44 = error_index4;
    error_index1 = [];
    error_index2 = [];
    error_index3 = [];
    error_index4 = [];
    
    for j=i+1:i+length(error_index11);
        ResponseMatrix(j,1)=StiSpotDiameter(error_index11(j-i))/scr.ppd;
        ResponseMatrix(j,2)=StiSpotDuration(error_index22(j-i));
        ResponseMatrix(j,3)=intensity(1,error_index33(j-i));
        ResponseMatrix(j,8)=intensity(2,error_index33(j-i));
        %         ResponseMatrix(j,3)=StiSpotIntensity(error_index33(j-i));
        ResponseMatrix(j,4)=RefSpotLatency(error_index44(j-i));
        [s, keyCode, deltaSecs] = KbPressWait;
        while keyCode(fButton)~=1
            [s, keyCode, deltaSecs] = KbPressWait;
        end
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        
        %     Screen('FillRect',scr.w,0)
        vbl = Screen('Flip',scr.w);
        WaitSecs(2*rand(1));
        ResponseMatrix(j,7)=1; %if no out win,value is 1
        
        X = [];
        Y = [];
        XX = [];
        YY = [];
        broke = 0;
        %%
        
        sM.drawBackground;
        Screen('FillOval', scr.w, ResponseMatrix(j,3),[StiSpotPosition(1)-StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)-StiSpotDiameter(error_index11(j-i))/2; ...
            StiSpotPosition(1)+StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)+StiSpotDiameter(error_index11(j-i))/2]);
        Screen('FillOval', scr.w, ResponseMatrix(j,8),[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        vbl = Screen('Flip', scr.w, scr.ifi);
        %      vbl = Screen('Flip',scr.w);
        vblendtime1 = GetSecs + StiSpotDuration(error_index22(j-i));
        vblendtime2 = GetSecs + StiSpotDuration(error_index22(j-i)) + RefSpotLatency(error_index44(j-i))/1000;
        vblendtime = max(vblendtime1,vblendtime2);
        vblendtime_min = min(vblendtime1,vblendtime2);
        while(GetSecs < vblendtime)
            %% close StiSpot or close RefSpot
            if GetSecs>vblendtime_min && vblendtime1<vblendtime2
                sM.drawBackground;
                Screen('FillOval', scr.w, ResponseMatrix(j,8),[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
                sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
                vbl = Screen('Flip', scr.w);
            elseif GetSecs>vblendtime_min && vblendtime1>vblendtime2
                sM.drawBackground;
                Screen('FillOval', scr.w, ResponseMatrix(j,3),[StiSpotPosition(1)-StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)-StiSpotDiameter(error_index11(j-i))/2; ...
                    StiSpotPosition(1)+StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)+StiSpotDiameter(error_index11(j-i))/2]);
                sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
                vbl = Screen('Flip', scr.w);
            end
            
            %%
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
            
            % check for presence of a new sample update
            %             if Eyelink( 'NewFloatSampleAvailable') > 0
            % get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            % if we don't, first find eye that's being tracked
            eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
            % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
            if eye_used == 1
                eye_used = 0; % use the left_eye data
            end
            if eye_used == 2
                eye_used = 0; % use the left_eye data
            end
            if eye_used ~= -1 % do we know which eye to use yet?
                % if we do, get current gaze position from sample
                x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                y = evt.gy(eye_used+1);
                % do we have valid data and is the pupil visible?
                if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    % if data is valid, draw a circle on the screen at current gaze position
                    % using PsychToolbox's Screen function
                    %                 gazeRect=[ x-3 y-3 x+3 y+3];
                    %                 colour=round(rand(3,1)*255); % coloured dot
                    %                 Screen('FillOval', window, colour, gazeRect);
                    %                 Screen('Flip',  el.window, [], 1); % don't erase
                    mx = x;
                    my = y;
                else
                    mx = 0;
                    my = 0;
                end
                
            else
                mx = 0;
                my = 0;
            end
            %             else
            %                 mx = 0;
            %                 my = 0;
            
            %             end
            
            X = [X mx];
            Y = [Y my];
            WaitSecs(0.001);
            %%%%%%%%%%%%%%%%%%%%%%%%----eyelink persuit
            
        end
        
        
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        
        vbl = Screen('Flip', scr.w);
        s1 = vbl;
        
        %%
        XX = X;
        YY = Y;
        %%%%%%%%%%%%计算eyedata范围内的最佳中间值
        X(X==0) = []; %去零
        X = sort(X);
        num = length(X);
        cut_num = round(num*(20/100));  % 取80%的有效范围
        if rem(cut_num,2) ~= 0
            cut_num = cut_num+1;
        end
        xpos = mean(X(1+cut_num/2:end-cut_num/2))
        Y(Y==0) = [];
        Y = sort(Y);
        num = length(Y);
        cut_num = round(num*(20/100));  % 取80%的有效范围
        if rem(cut_num,2) ~= 0
            cut_num = cut_num+1;
        end
        ypos = mean(Y(1+cut_num/2:end-cut_num/2))
        
        fixationWindow = [0 0 fixWinSize fixWinSize];
        fixationWindow = CenterRectOnPoint(fixationWindow, xpos, ypos);
        num_in = 0;
        num_out = 0;
        for ii = 1:length(XX)
            if infixationWindow(XX(ii),YY(ii))
                
                num_in = num_in +1;
            elseif ~infixationWindow(XX(ii),YY(ii))
                
                num_out = num_out +1;
            end
        end
        if (num_out/(num_in+num_out))>out_percent  %>95% broke
            disp('broke fix')
            broke = 1;
        else
            disp('in fix')
        end
        if broke
            Beeper(el.calibration_failed_beep(1), el.calibration_failed_beep(2), el.calibration_failed_beep(3));
            ResponseMatrix(j,7)=0; %if no out win,value is 1
            error_index1 = [error_index1 error_index11(j-i)];
            error_index2 = [error_index2  error_index22(j-i)];
            error_index3 = [error_index3  error_index33(j-i)];
            error_index4 = [error_index4  error_index44(j-i)];
        end
        EyeData{j} = [XX;YY];
        
        
        
        
        %         for jj=1:RefSpotLatency(error_index44(j-i))
        %             sM.drawBackground;
        %             sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        % 
        %
        %             vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
        %             if jj==1
        %                 s1 = vbl;
        %             end
        %         end
        %         Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
        %         sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        %             
        %         Screen('Flip',scr.w);
        %         [s2, keyCode, deltaSecs] = KbReleaseWait;
        %         ResponseMatrix(j,5)=s2-s1;
        
        Screen('DrawText',scr.w,'Left:  AfterImage appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+200);
        Screen('DrawText',scr.w,'Right: Reference appear earlier.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+250);
        Screen('DrawText',scr.w,'Down: Skip.',scr.screenRect(3)/2-200,scr.screenRect(4)/2+300);
        %         Screen('FillOval', scr.w, RefSpotIntensity,[RefSpotPosition(1)-RefSpotDiameter/2; RefSpotPosition(2)-RefSpotDiameter/2; RefSpotPosition(1)+RefSpotDiameter/2; RefSpotPosition(2)+RefSpotDiameter/2]);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        Screen('Flip',scr.w);
        %         WaitSecs(0.5);
        while 1
            [s, keyCode, deltaSecs] = KbWait;
            if keyCode(leftButton) == 1
                ResponseMatrix(j,6)=1;
                break
            elseif keyCode(rightButton) == 1
                ResponseMatrix(j,6)=2;
                break
            elseif keyCode(downButton) == 1
                ResponseMatrix(j,6)=3;
                break
            elseif keyCode(upButton) == 1
                ResponseMatrix(j,6)=4;
                break
            elseif keyCode(escButton) == 1
                sM.drawCross;sM.flip;
                return
            end
        end
        ResponseMatrix(j,5)=s-s1;
        Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
        sM.drawCross;sM.flip;
        WaitSecs(0.2);
        disp(j)
    end
    i = i+length(error_index11);
    %     if j>4  %to many trials ,break
    %         break;
    %     end
end  %until error_index = []
Screen('DrawText',scr.w,'Thank you!',scr.screenRect(3)/2-25,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
filename = strcat(datestr(now,'yyyy-mm-dd-HH-MM-SS'),'.mat');
save (filename, 'ResponseMatrix','EyeData')


function StartButton2_Callback(hObject, eventdata, handles)
global sM scr el fixationWindow  fixWinSize
out_percent = 0;
BackgroundColor = str2num(get(handles.BackgroundColor,'String'));
sM.drawBackground;
% Screen('FillRect',scr.w,0);
Screen('Flip',scr.w);
StiSpotDiameter = str2num(['[' get(handles.StiSpotDiameter,'string') ']']).*scr.ppd;
StiSpotDuration = str2num(['[' get(handles.StiSpotDuration,'string') ']']);
StiSpotIntensity = str2num(['[' get(handles.StiSpotIntensity,'string') ']']);
StiSpotPosition = [str2num(get(handles.StiSpotXPosition,'string')) str2num(get(handles.StiSpotYPosition,'string'))];
RefSpotDiameter = str2num(get(handles.RefSpotDiameter,'string'))*scr.ppd;
RefSpotIntensity = str2num(get(handles.RefSpotIntensity,'string'));
RefSpotLatency = str2num(['[' get(handles.RefSpotLatency,'string') ']']);
RefSpotPosition = [str2num(get(handles.RefSpotXPosition,'string')) str2num(get(handles.RefSpotYPosition,'string'))];
Trials = str2num(get(handles.Trials,'string'));
KbName('UnifyKeyNames');
fButton = KbName('F');
escButton = KbName('escape');
Button1 = KbName('1');
Button2 = KbName('2');
Button3 = KbName('3');
Button4 = KbName('4');
Button5 = KbName('5');
Button6 = KbName('6');
Button7 = KbName('7');
Button8 = KbName('8');
ChoisePosition=[scr.screenRect(3)/2-7*scr.ppd,scr.screenRect(4)/2+4*scr.ppd,scr.screenRect(3)/2-5*scr.ppd,scr.screenRect(4)/2+6*scr.ppd;...
    scr.screenRect(3)/2-3*scr.ppd,scr.screenRect(4)/2+4*scr.ppd,scr.screenRect(3)/2-1*scr.ppd,scr.screenRect(4)/2+6*scr.ppd;...
    scr.screenRect(3)/2+1*scr.ppd,scr.screenRect(4)/2+4*scr.ppd,scr.screenRect(3)/2+3*scr.ppd,scr.screenRect(4)/2+6*scr.ppd;...
    scr.screenRect(3)/2+5*scr.ppd,scr.screenRect(4)/2+4*scr.ppd,scr.screenRect(3)/2+7*scr.ppd,scr.screenRect(4)/2+6*scr.ppd;...
    scr.screenRect(3)/2-7*scr.ppd,scr.screenRect(4)/2+8*scr.ppd,scr.screenRect(3)/2-5*scr.ppd,scr.screenRect(4)/2+10*scr.ppd;...
    scr.screenRect(3)/2-3*scr.ppd,scr.screenRect(4)/2+8*scr.ppd,scr.screenRect(3)/2-1*scr.ppd,scr.screenRect(4)/2+10*scr.ppd;...
    scr.screenRect(3)/2+1*scr.ppd,scr.screenRect(4)/2+8*scr.ppd,scr.screenRect(3)/2+3*scr.ppd,scr.screenRect(4)/2+10*scr.ppd;...
    scr.screenRect(3)/2+5*scr.ppd,scr.screenRect(4)/2+8*scr.ppd,scr.screenRect(3)/2+7*scr.ppd,scr.screenRect(4)/2+10*scr.ppd]';
% ChoiseColor=[44 56 68 80 92 104 116 128 212 200 188 176 164 152 140 128];%1 to 8 for white spot, 9 to 16 for black spot
ChoiseColor=[109 122 133 144 153 162 170 175 223 217 211 204 198 191 184 175];%1 to 8 for white spot, 9 to 16 for black spot
index = [];
for i=1:Trials
    index = [index randperm(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency))];
end
index_StiSpotDiameter = ceil(index/length(StiSpotDuration)/length(StiSpotIntensity)/length(RefSpotLatency));
remain = mod(index-1, length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency))+ 1;
index_StiSpotDuration = ceil(remain/length(StiSpotIntensity)/length(RefSpotLatency));
remain = mod(remain-1, length(StiSpotIntensity)*length(RefSpotLatency))+ 1;
index_StiSpotIntensity = ceil(remain/length(RefSpotLatency));
remain = mod(remain-1, length(RefSpotLatency))+ 1;
index_RefSpotLatency = remain;
Screen('DrawText',scr.w,'Start!',scr.screenRect(3)/2-50,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
FixPointSize = str2num(get(handles.FixPointSize,'String'))*scr.ppd;
FixPointXPosition = str2num(get(handles.FixPointXPosition,'String'));
FixPointYPosition = str2num(get(handles.FixPointYPosition,'String'));
FixPointColor = str2num(get(handles.FixPointColor,'String'));
sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
% Screen('Flip',scr.w);

ResponseMatrix = zeros(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency),7);
EyeData = [];
error_index1 = [];
error_index2 = [];
error_index3 = [];
error_index4 = [];
for i=1:length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*length(RefSpotLatency)*Trials
    ResponseMatrix(i,1)=StiSpotDiameter(index_StiSpotDiameter(i))/scr.ppd;
    ResponseMatrix(i,2)=StiSpotDuration(index_StiSpotDuration(i));
    ResponseMatrix(i,3)=StiSpotIntensity(index_StiSpotIntensity(i));
    ResponseMatrix(i,4)=RefSpotLatency(index_RefSpotLatency(i));
    [s, keyCode, deltaSecs] = KbPressWait;
    while keyCode(fButton)~=1
        [s, keyCode, deltaSecs] = KbPressWait;
    end
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    vbl = Screen('Flip',scr.w);
    WaitSecs(2*rand(1));
    
    ResponseMatrix(i,7)=1; %if no out win,value is 1
    
    X = [];
    Y = [];
    XX = [];
    YY = [];
    broke = 0;
    %%
    sM.drawBackground;
    Screen('FillOval', scr.w, StiSpotIntensity(index_StiSpotIntensity(i)),[StiSpotPosition(1)-StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)-StiSpotDiameter(index_StiSpotDiameter(i))/2; ...
        StiSpotPosition(1)+StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)+StiSpotDiameter(index_StiSpotDiameter(i))/2]);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    vblendtime = GetSecs + StiSpotDuration(index_StiSpotDuration(i));
    while(GetSecs < vblendtime)
        %%
        error=Eyelink('CheckRecording');
        if(error~=0)
            break;
        end
        
        % check for presence of a new sample update
        %         if Eyelink( 'NewFloatSampleAvailable') > 0
        % get the sample in the form of an event structure
        evt = Eyelink( 'NewestFloatSample');
        % if we don't, first find eye that's being tracked
        eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
        % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
        if eye_used == 1
            eye_used = 0; % use the left_eye data
        end
        if eye_used == 2
            eye_used = 0; % use the left_eye data
        end
        if eye_used ~= -1 % do we know which eye to use yet?
            % if we do, get current gaze position from sample
            x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
            y = evt.gy(eye_used+1);
            % do we have valid data and is the pupil visible?
            if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                % if data is valid, draw a circle on the screen at current gaze position
                % using PsychToolbox's Screen function
                %                 gazeRect=[ x-3 y-3 x+3 y+3];
                %                 colour=round(rand(3,1)*255); % coloured dot
                %                 Screen('FillOval', window, colour, gazeRect);
                %                 Screen('Flip',  el.window, [], 1); % don't erase
                mx = x;
                my = y;
            else
                mx = 0;
                my = 0;
            end
            
        else
            mx = 0;
            my = 0;
        end
        %         else
        %             mx = 0;
        %             my = 0;
        
        %         end
        
        X = [X mx];
        Y = [Y my];
        WaitSecs(0.001);  %eyedata sample = 1000
        %%%%%%%%%%%%%%%%%%%%%%%%----eyelink persuit
        
    end
    %%
    XX = X;
    YY = Y;
    %%%%%%%%%%%%计算eyedata范围内的最佳中间值
    X(X==0) = []; %去零
    X = sort(X);
    num = length(X);
    cut_num = round(num*(20/100));  % 取80%的有效范围
    if rem(cut_num,2) ~= 0
        cut_num = cut_num+1;
    end
    xpos = mean(X(1+cut_num/2:end-cut_num/2))
    Y(Y==0) = [];
    Y = sort(Y);
    num = length(Y);
    cut_num = round(num*(20/100));  % 取80%的有效范围
    if rem(cut_num,2) ~= 0
        cut_num = cut_num+1;
    end
    ypos = mean(Y(1+cut_num/2:end-cut_num/2))
    
    fixationWindow = [0 0 fixWinSize fixWinSize];
    fixationWindow = CenterRectOnPoint(fixationWindow, xpos, ypos);
    num_in = 0;
    num_out = 0;
    for ii = 1:length(XX)
        if infixationWindow(XX(ii),YY(ii))
            
            num_in = num_in +1;
        elseif ~infixationWindow(XX(ii),YY(ii))
            if XX(ii)==0 || YY(ii) ==0
                num_out = num_out;
            else
                num_out = num_out +1;
            end
        end
    end
    if (num_out/(num_in+num_out))>out_percent  %>95% broke
        disp('broke fix')
        broke = 1;
    else
        disp('in fix')
    end
    %%
    if broke
        Beeper(el.calibration_failed_beep(1), el.calibration_failed_beep(2), el.calibration_failed_beep(3));
        ResponseMatrix(i,7)=0;%error or out window
        error_index1 = [error_index1 index_StiSpotDiameter(i)];
        error_index2 = [error_index2 index_StiSpotDuration(i)];
        error_index3 = [error_index3 index_StiSpotIntensity(i)];
        error_index4 = [error_index4 index_RefSpotLatency(i)];
    end
    EyeData{i} = [XX;YY];
    
    s1 = vbl;
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    s1 = vbl;
    
    [s2, keyCode, deltaSecs] = KbReleaseWait;
    ResponseMatrix(i,5)=s2-s1;
    
    
    
    
    if StiSpotIntensity(index_StiSpotIntensity(i))>175
        for j=1:8
            Screen('FillOval', scr.w, ChoiseColor(j),ChoisePosition(:,j));
            Screen('DrawText',scr.w,num2str(j),(ChoisePosition(1,j)+ChoisePosition(3,j))/2-10,ChoisePosition(2,j)-1.5*scr.ppd);
        end
    else
        for j=1:8
            Screen('FillOval', scr.w, ChoiseColor(j+8),ChoisePosition(:,j));
            Screen('DrawText',scr.w,num2str(j),(ChoisePosition(1,j)+ChoisePosition(3,j))/2-10,ChoisePosition(2,j)-1.5*scr.ppd);
        end
    end
    Screen('DrawText',scr.w,'Please choose the perceived intensity of after image.',scr.screenRect(3)/2-350,scr.screenRect(4)/2+300);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    Screen('Flip',scr.w);
    WaitSecs(0.5);
    while 1
        [s, keyCode, deltaSecs] = KbWait;
        if keyCode(Button1) == 1
            ResponseMatrix(i,6)=1;
            break
        elseif keyCode(Button2) == 1
            ResponseMatrix(i,6)=2;
            break
        elseif keyCode(Button3) == 1
            ResponseMatrix(i,6)=3;
            break
        elseif keyCode(Button4) == 1
            ResponseMatrix(i,6)=4;
            break
        elseif keyCode(Button5) == 1
            ResponseMatrix(i,6)=5;
            break
        elseif keyCode(Button6) == 1
            ResponseMatrix(i,6)=6;
            break
        elseif keyCode(Button7) == 1
            ResponseMatrix(i,6)=7;
            break
        elseif keyCode(Button8) == 1
            ResponseMatrix(i,6)=8;
            break
        elseif keyCode(escButton) == 1
            sM.drawCross;sM.flip;
            return
        end
    end
    Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
    sM.drawCross;sM.flip;
    WaitSecs(0.2);
    disp(i)
end
%% do trials with out window
% error_index11 = error_index1;
% error_index22 = error_index2;
% error_index33 = error_index3;
% error_index44 = error_index44;
while ~isempty(error_index1)
    error_index11 = error_index1;
    error_index22 = error_index2;
    error_index33 = error_index3;
    error_index44 = error_index4;
    error_index1 = [];
    error_index2 = [];
    error_index3 = [];
    error_index4 = [];
    
    for j=i+1:i+length(error_index11);
        ResponseMatrix(j,1)=StiSpotDiameter(error_index11(j-i))/scr.ppd;
        ResponseMatrix(j,2)=StiSpotDuration(error_index22(j-i));
        ResponseMatrix(j,3)=StiSpotIntensity(error_index33(j-i));
        ResponseMatrix(j,4)=RefSpotLatency(error_index44(j-i));
        [s, keyCode, deltaSecs] = KbPressWait;
        while keyCode(fButton)~=1
            [s, keyCode, deltaSecs] = KbPressWait;
        end
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        vbl = Screen('Flip',scr.w);
        WaitSecs(2*rand(1));
        
        ResponseMatrix(j,7)=1; %if no out win,value is 1
        X = [];
        Y = [];
        XX = [];
        YY = [];
        broke = 0;
        %%
        sM.drawBackground;
        Screen('FillOval', scr.w, StiSpotIntensity(error_index33(j-i)),[StiSpotPosition(1)-StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)-StiSpotDiameter(error_index11(j-i))/2; ...
            StiSpotPosition(1)+StiSpotDiameter(error_index11(j-i))/2; StiSpotPosition(2)+StiSpotDiameter(error_index11(j-i))/2]);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
        vblendtime = GetSecs + StiSpotDuration(error_index22(j-i));
        while(GetSecs < vblendtime)
            %%
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
            
            % check for presence of a new sample update
            %             if Eyelink( 'NewFloatSampleAvailable') > 0
            % get the sample in the form of an event structure
            evt = Eyelink( 'NewestFloatSample');
            % if we don't, first find eye that's being tracked
            eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
            % returns 0 (LEFT_EYE), 1 (RIGHT_EYE) or 2 (BINOCULAR) depending on what data is
            if eye_used == 1
                eye_used = 0; % use the left_eye data
            end
            if eye_used == 2
                eye_used = 0; % use the left_eye data
            end
            if eye_used ~= -1 % do we know which eye to use yet?
                % if we do, get current gaze position from sample
                x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                y = evt.gy(eye_used+1);
                % do we have valid data and is the pupil visible?
                if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    % if data is valid, draw a circle on the screen at current gaze position
                    % using PsychToolbox's Screen function
                    %                 gazeRect=[ x-3 y-3 x+3 y+3];
                    %                 colour=round(rand(3,1)*255); % coloured dot
                    %                 Screen('FillOval', window, colour, gazeRect);
                    %                 Screen('Flip',  el.window, [], 1); % don't erase
                    mx = x;
                    my = y;
                else
                    mx = 0;
                    my = 0;
                end
                
            else
                mx = 0;
                my = 0;
            end
            %             else
            %                 mx = 0;
            %                 my = 0;
            
            %             end
            
            X = [X mx];
            Y = [Y my];
            WaitSecs(0.001);  %eyedata sample = 1000
            %%%%%%%%%%%%%%%%%%%%%%%%----eyelink persuit
            
        end
        %%
        XX = X;
        YY = Y;
        %%%%%%%%%%%%计算eyedata范围内的最佳中间值
        X(X==0) = []; %去零
        X = sort(X);
        num = length(X);
        cut_num = round(num*(20/100));  % 取80%的有效范围
        if rem(cut_num,2) ~= 0
            cut_num = cut_num+1;
        end
        xpos = mean(X(1+cut_num/2:end-cut_num/2))
        Y(Y==0) = [];
        Y = sort(Y);
        num = length(Y);
        cut_num = round(num*(20/100));  % 取80%的有效范围
        if rem(cut_num,2) ~= 0
            cut_num = cut_num+1;
        end
        ypos = mean(Y(1+cut_num/2:end-cut_num/2))
        
        fixationWindow = [0 0 fixWinSize fixWinSize];
        fixationWindow = CenterRectOnPoint(fixationWindow, xpos, ypos);
        num_in = 0;
        num_out = 0;
        for ii = 1:length(XX)
            if infixationWindow(XX(ii),YY(ii))
                
                num_in = num_in +1;
            elseif ~infixationWindow(XX(ii),YY(ii))
                if XX(ii)==0 || YY(ii) ==0
                    num_out = num_out;
                else
                    num_out = num_out +1;
                end
            end
        end
        if (num_out/(num_in+num_out))>out_percent  %>95% broke
            disp('broke fix')
            broke = 1;
        else
            disp('in fix')
        end
        if broke
            Beeper(el.calibration_failed_beep(1), el.calibration_failed_beep(2), el.calibration_failed_beep(3));
            ResponseMatrix(j,7)=0; %if no out win,value is 1
            error_index1 = [error_index1 error_index11(j-i)];
            error_index2 = [error_index2  error_index22(j-i)];
            error_index3 = [error_index3  error_index33(j-i)];
            error_index4 = [error_index4  error_index44(j-i)];
        end
        EyeData{j} = [XX;YY];
        
        s1 = vbl;
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
        s1 = vbl;
        
        [s2, keyCode, deltaSecs] = KbReleaseWait;
        ResponseMatrix(j,5)=s2-s1;
        
        
        
        
        if StiSpotIntensity(error_index33(j-i))>175
            for jj=1:8
                Screen('FillOval', scr.w, ChoiseColor(jj),ChoisePosition(:,jj));
                Screen('DrawText',scr.w,num2str(jj),(ChoisePosition(1,jj)+ChoisePosition(3,jj))/2-10,ChoisePosition(2,jj)-1.5*scr.ppd);
            end
        else
            for jj=1:8
                Screen('FillOval', scr.w, ChoiseColor(jj+8),ChoisePosition(:,jj));
                Screen('DrawText',scr.w,num2str(jj),(ChoisePosition(1,jj)+ChoisePosition(3,jj))/2-10,ChoisePosition(2,jj)-1.5*scr.ppd);
            end
        end
        Screen('DrawText',scr.w,'Please choose the perceived intensity of after image.',scr.screenRect(3)/2-350,scr.screenRect(4)/2+300);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        Screen('Flip',scr.w);
        WaitSecs(0.5);
        while 1
            [s, keyCode, deltaSecs] = KbWait;
            if keyCode(Button1) == 1
                ResponseMatrix(j,6)=1;
                break
            elseif keyCode(Button2) == 1
                ResponseMatrix(j,6)=2;
                break
            elseif keyCode(Button3) == 1
                ResponseMatrix(j,6)=3;
                break
            elseif keyCode(Button4) == 1
                ResponseMatrix(j,6)=4;
                break
            elseif keyCode(Button5) == 1
                ResponseMatrix(j,6)=5;
                break
            elseif keyCode(Button6) == 1
                ResponseMatrix(j,6)=6;
                break
            elseif keyCode(Button7) == 1
                ResponseMatrix(j,6)=7;
                break
            elseif keyCode(Button8) == 1
                ResponseMatrix(j,6)=8;
                break
            elseif keyCode(escButton) == 1
                sM.drawCross;sM.flip;
                return
            end
        end
        Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
        sM.drawCross;sM.flip;
        WaitSecs(0.2);
        disp(j)
    end
    i = i+length(error_index11);
    %     if j>5  %to many trials ,break
    %         break;
    %     end
end  %until error_index = []
Screen('DrawText',scr.w,'Thank you!',scr.screenRect(3)/2-25,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
filename = strcat(datestr(now,'yyyy-mm-dd-HH-MM-SS'),'.mat');
save (filename, 'ResponseMatrix','EyeData')


function S1StartButton_Callback(hObject, eventdata, handles)
global sM scr
BackgroundColor = str2num(get(handles.BackgroundColor,'String'));
sM.drawBackground;
Screen('Flip',scr.w);
StiSpotDiameter = str2num(['[' get(handles.StiSpotDiameter,'string') ']']).*scr.ppd;
StiSpotDuration = str2num(['[' get(handles.StiSpotDuration,'string') ']']);
StiSpotIntensity = str2num(['[' get(handles.StiSpotIntensity,'string') ']']);
StiSpotPosition = [str2num(get(handles.StiSpotXPosition,'string')) str2num(get(handles.StiSpotYPosition,'string'))];
Trials = str2num(get(handles.Trials,'string'));
KbName('UnifyKeyNames');
backButton = KbName('backspace');
escButton = KbName('escape');

% Buttona = KbName('a');
% Buttonb = KbName('b');
% Buttonc = KbName('c');
% Buttond = KbName('d');
% Buttone = KbName('e');
% Buttonf = KbName('f');
% Buttong = KbName('g');
% Buttonh = KbName('h');
ChoiseSize=[0:0.25:5].*scr.ppd;
ChoiseName=['abcdefghijklmnopqrstu'];
for i=1:length(ChoiseName)
    eval(['Button' ChoiseName(i) '=KbName(''' ChoiseName(i) ''');']);
end
choiserow=3;choisecolumn=7;
for i=1:length(ChoiseName)
    ChoisePosition(1,i) = scr.screenRect(3)/2+((mod(i-1,choisecolumn)+1)-4)*7*scr.ppd-ChoiseSize(i)/2;
    ChoisePosition(2,i) = scr.screenRect(4)/2+(ceil(i/choisecolumn)-2.4)*7*scr.ppd-ChoiseSize(i)/2;
    ChoisePosition(3,i) = scr.screenRect(3)/2+((mod(i-1,choisecolumn)+1)-4)*7*scr.ppd+ChoiseSize(i)/2;
    ChoisePosition(4,i) = scr.screenRect(4)/2+(ceil(i/choisecolumn)-2.4)*7*scr.ppd+ChoiseSize(i)/2;
end
index = [];
for i=1:Trials
    index = [index randperm(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity))];
end
index_StiSpotDiameter = ceil(index/length(StiSpotDuration)/length(StiSpotIntensity));
remain = mod(index-1, length(StiSpotDuration)*length(StiSpotIntensity))+ 1;
index_StiSpotDuration = ceil(remain/length(StiSpotIntensity));
remain = mod(remain-1, length(StiSpotIntensity))+ 1;
index_StiSpotIntensity = remain;
Screen('DrawText',scr.w,'Start!',scr.screenRect(3)/2-50,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
pause(2)
FixPointSize = str2num(get(handles.FixPointSize,'String'))*scr.ppd;
FixPointXPosition = str2num(get(handles.FixPointXPosition,'String'));
FixPointYPosition = str2num(get(handles.FixPointYPosition,'String'));
FixPointColor = str2num(get(handles.FixPointColor,'String'));
sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
Screen('Flip',scr.w);

ResponseMatrix = zeros(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity),6);
i=1;
while i<=length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*Trials
    ResponseMatrix(i,1)=StiSpotDiameter(index_StiSpotDiameter(i))/scr.ppd;
    ResponseMatrix(i,2)=StiSpotDuration(index_StiSpotDuration(i));
    ResponseMatrix(i,3)=StiSpotIntensity(index_StiSpotIntensity(i));
    ResponseMatrix(i,4)=0;
    ResponseMatrix(i,5)=0;
    
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    vbl = Screen('Flip',scr.w);
    WaitSecs(0.8);
    vblendtime = GetSecs + StiSpotDuration(index_StiSpotDuration(i));
    while(vbl < vblendtime)
        sM.drawBackground;
        Screen('FillOval', scr.w, StiSpotIntensity(index_StiSpotIntensity(i)),[StiSpotPosition(1)-StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)-StiSpotDiameter(index_StiSpotDiameter(i))/2; ...
            StiSpotPosition(1)+StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)+StiSpotDiameter(index_StiSpotDiameter(i))/2]);
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    end
    vblendtime = GetSecs + 1;
    while(vbl < vblendtime)
        sM.drawBackground;
        sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
            
        vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    end
    if StiSpotIntensity(index_StiSpotIntensity(i))>128
        for j=1:length(ChoiseName)
            Screen('FillOval', scr.w, 51,ChoisePosition);
            Screen('DrawText',scr.w,ChoiseName(j),(ChoisePosition(1,j)+ChoisePosition(3,j))/2-10,ChoisePosition(2,j)-1.5*scr.ppd);
        end
    else
        for j=1:length(ChoiseName)
            Screen('FillOval', scr.w, 204,ChoisePosition);
            Screen('DrawText',scr.w,ChoiseName(j),(ChoisePosition(1,j)+ChoisePosition(3,j))/2-10,ChoisePosition(2,j)-1.5*scr.ppd);
        end
    end
    Screen('DrawText',scr.w,'Please choose the perceived size of after image.',scr.screenRect(3)/2-350,scr.screenRect(4)/2+400);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    Screen('Flip',scr.w);
    WaitSecs(0.5);
    indexcheck=0;
    while 1
        [s, keyCode, deltaSecs] = KbWait;
        for j=1:length(ChoiseName)
            eval(['if keyCode(Button' ChoiseName(j) ')==1; ResponseMatrix(i,6)=j; i=i+1; indexcheck=1; end;' ])
        end
        if keyCode(escButton) == 1
            sM.drawCross;sM.flip;
            return
        end
        if keyCode(backButton) == 1
            sM.drawCross;sM.flip;
            break
        end
        if indexcheck==1
            break
        end
    end
end
Screen('DrawText',scr.w,'Thank you!',scr.screenRect(3)/2-25,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
filename = strcat(datestr(now,'yyyy-mm-dd-HH-MM-SS'),'.mat');
save (filename, 'ResponseMatrix')

function S2StartButton_Callback(hObject, eventdata, handles)
global sM scr
BackgroundColor = str2num(get(handles.BackgroundColor,'String'));
sM.drawBackground;
Screen('Flip',scr.w);
StiSpotDiameter = str2num(['[' get(handles.StiSpotDiameter,'string') ']']).*scr.ppd;
StiSpotDuration = str2num(['[' get(handles.StiSpotDuration,'string') ']']);
StiSpotIntensity = str2num(['[' get(handles.StiSpotIntensity,'string') ']']);
StiSpotPosition = [str2num(get(handles.StiSpotXPosition,'string')) str2num(get(handles.StiSpotYPosition,'string'))];
Trials = str2num(get(handles.Trials,'string'));
KbName('UnifyKeyNames');
escButton = KbName('escape');
Buttonf = KbName('f');
index = [];
for i=1:Trials
    index = [index randperm(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity))];
end
index_StiSpotDiameter = ceil(index/length(StiSpotDuration)/length(StiSpotIntensity));
remain = mod(index-1, length(StiSpotDuration)*length(StiSpotIntensity))+ 1;
index_StiSpotDuration = ceil(remain/length(StiSpotIntensity));
remain = mod(remain-1, length(StiSpotIntensity))+ 1;
index_StiSpotIntensity = remain;
Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
FixPointSize = str2num(get(handles.FixPointSize,'String'))*scr.ppd;
FixPointXPosition = str2num(get(handles.FixPointXPosition,'String'));
FixPointYPosition = str2num(get(handles.FixPointYPosition,'String'));
FixPointColor = str2num(get(handles.FixPointColor,'String'));
sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
    
Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
Screen('Flip',scr.w);

ResponseMatrix = zeros(length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity),6);
for i=1:length(StiSpotDiameter)*length(StiSpotDuration)*length(StiSpotIntensity)*Trials
    ResponseMatrix(i,1)=StiSpotDiameter(index_StiSpotDiameter(i))/scr.ppd;
    ResponseMatrix(i,2)=StiSpotDuration(index_StiSpotDuration(i));
    ResponseMatrix(i,3)=StiSpotIntensity(index_StiSpotIntensity(i));
    ResponseMatrix(i,4)=0;
    ResponseMatrix(i,6)=0;
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    Screen('DrawText',scr.w,'Hold Button F!',scr.screenRect(3)/2-100,scr.screenRect(4)/2+200);
    vbl = Screen('Flip',scr.w);
    [s1, keyCode, deltaSecs] = KbPressWait;
    while keyCode(Buttonf)~=1 && keyCode(escButton)~=1
        [s1, keyCode, deltaSecs] = KbPressWait;
    end
    if keyCode(escButton) == 1
        sM.drawCross;sM.flip;
        return
    end
    
    sM.drawBackground;
    Screen('FillOval', scr.w, StiSpotIntensity(index_StiSpotIntensity(i)),[StiSpotPosition(1)-StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)-StiSpotDiameter(index_StiSpotDiameter(i))/2; ...
        StiSpotPosition(1)+StiSpotDiameter(index_StiSpotDiameter(i))/2; StiSpotPosition(2)+StiSpotDiameter(index_StiSpotDiameter(i))/2]);
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    
    [s2, keyCode, deltaSecs] = KbReleaseWait;
    ResponseMatrix(i,5)=s2-s1;
    
    sM.drawBackground;
    sM.drawCross(FixPointSize, FixPointColor, FixPointXPosition, FixPointYPosition);
        
    vbl = Screen('Flip', scr.w, vbl + (1 - 0.5) * scr.ifi);
    
end
Screen('DrawText',scr.w,'Thank you!',scr.screenRect(3)/2-25,scr.screenRect(4)/2+200);
sM.drawCross;sM.flip;
filename = strcat(datestr(now,'yyyy-mm-dd-HH-MM-SS'),'.mat');
save (filename, 'ResponseMatrix')
