function isoluminant_stimuli()

ins = inputdlg({'Subject Name','Comments (room, lights etc.)'});
if isempty(ins); return; end
ana=[]; %this holds the experiment data and parameters
ana.subject = ins{1};
ana.comments = ins{2};
ana.date = datestr(datetime);
ana.version = Screen('Version');
ana.computer = Screen('Computer');
ana.calibFile = [];
useEyeLink = true;
isDummy = true;
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 0);
%--------------fix parameters
fixX = 0;
fixY = 0;
firstFixInit = 1;
firstFixTime = 1;
firstFixRadius = 1;
strictFixation = true;

%----------------Make a name for this run-----------------------
pf='Isolum_';
nameExp = [pf ana.subject];
c = sprintf(' %i',fix(clock()));
c = regexprep(c,' ','_');
nameExp = [nameExp c];

%---------------------- viewing parameters -------------------------------
screenID = max(Screen('Screens'));%-1;
pixelsPerCm = 35;
distance = 56.5;
windowed = [0 0 1000 1000];
backgroundColor = [0.5 0.5 0.5];
frequency = 0.3;
circle_diameter = 6;
duration = 30;

try
	
	sM = screenManager();
	sM.screen = screenID;
	sM.windowed = windowed;
	sM.pixelsPerCm = pixelsPerCm;
	sM.distance = distance;
	sM.backgroundColour = backgroundColor;
	sM.open;
	
	%============================SET UP VARIABLES=====================================
	%%%input color paras
	rgb_start = [0 0 0];
	rgb_step = [0 0.2 0];
	rgb_end  = [0 1 0];
	rgb1 = [1 0 0];
	
	trials = (sum(rgb_end)-sum(rgb_start))/sum(rgb_step)+1; %
	
	%%%%%%%%set time
	flash_time = 1/frequency;
	onFrames = round(flash_time/sM.screenVals.ifi); % video frames for each color
	numChange = duration/(1/frequency);%number of flash
	
	diameter = ceil(circle_diameter*sM.ppd);
	circleRect = [0,0,diameter,diameter];
	circleRect = CenterRectOnPoint(circleRect, sM.xCenter, sM.yCenter);
	
	%==============================setup eyelink==========================
	if useEyeLink == true
		eL = eyelinkManager('IP',[]);
		%eL.verbose = true;
		eL.isDummy = isDummy; %use dummy or real eyelink?
		eL.name = nameExp;
		eL.saveFile = [nameExp '.edf'];
		eL.recordData = true; %save EDF file
		eL.sampleRate = 500;
		eL.remoteCalibration = false; % manual calibration?
		eL.calibrationStyle = 'HV5'; % calibration style
		eL.modify.calibrationtargetcolour = [0 0 0];
		eL.modify.calibrationtargetsize = 0.5;
		eL.modify.calibrationtargetwidth = 0.05;
		eL.modify.waitformodereadytime = 500;
		eL.modify.devicenumber = -1; % -1 = use any keyboard
		% X, Y, FixInitTime, FixTime, Radius, StrictFix
		updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixRadius, strictFixation);
		initialise(eL, sM); %use sM to pass screen values to eyelink
		setup(eL); % do setup and calibration
		WaitSecs('YieldSecs',0.25);
		getSample(eL); %make sure everything is in memory etc.
	else
		eL = [];
	end
	
	%===================================================
	%global struct ana to save parameters
	%saveMetaData();
	%======================================================
	
	
	if ~useEyeLink
		Screen('FillRect',sM.win,gray,[]);
		normBoundsRect = Screen('TextBounds', sM.win, 'Please fix at the central point.');
		Screen('DrawText',sM.win,'Please fix at the central point.', sM.xCenter-normBoundsRect(3)/2, sM.yCenter+normBoundsRect(4));
		drawCross(sM,0.3,[0 0 0 1],fixX,fixY);
		Screen('Flip',sM.win);
		WaitSecs('YieldSecs',2);
	end
	
	% initialise our trial variables
	iii = 0;
	breakLoop = false;
	
	while ~breakLoop
		
		fixated = 'no';
		sM.drawBackground();
		Screen('Flip',sM.win);
		WaitSecs('YieldSecs',1);
		Priority(MaxPriority(sM.win));
		ifi = sM.screenVals.ifi;
		if iii<trials
			if useEyeLink
				resetFixation(eL);
				updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixRadius, strictFixation);
				trackerClearScreen(eL);
				trackerDrawFixation(eL); %draw fixation window on eyelink computer
				edfMessage(eL,'V_RT MESSAGE END_FIX END_RT');  %this 3 lines set the trial info for the eyelink
				edfMessage(eL,['TRIALID ' num2str(iii)]);  %obj.getTaskIndex gives us which trial we're at
				startRecording(eL);
				statusMessage(eL,'INITIATE FIXATION...');
				fixated = '';
				ListenChar(2);
				syncTime(eL);
				%fprintf('===>>> INITIATE FIXATION Trial = %i\n', iii);
				while ~strcmpi(fixated,'fix') && ~strcmpi(fixated,'breakfix')
					drawCross(sM,0.3,[0 0 0 1],fixX,fixY);
					Screen('Flip',sM.win); %flip the buffer
					getSample(eL);
					fixated=testSearchHoldFixation(eL,'fix','breakfix');
					[keyIsDown, ~, keyCode] = KbCheck(-1);
					if keyIsDown == 1
						rchar = KbName(keyCode); if iscell(rchar);rchar=rchar{1};end
						switch lower(rchar)
							case {'c'}
								fixated = 'breakfix';
								stopRecording(eL);
								setOffline(eL);
								trackerSetup(eL);
								WaitSecs('YieldSecs',2);
							case {'d'}
								fixated = 'breakfix';
								stopRecording(eL);
								driftCorrection(eL);
								WaitSecs('YieldSecs',2);
							case {'escape'}
								fixated = 'breakfix';
								breakLoop = true;
						end
						%ListenChar(0);
					end
				end
				if strcmpi(fixated,'breakfix')
					
					fprintf('===>>> BROKE INITIATE FIXATION Trial = %i\n', iii);
					statusMessage(eL,'Subject Broke Initial Fixation!');
					edfMessage(eL,'MSG:BreakFix');
					resetFixation(eL);
					stopRecording(eL);
					setOffline(eL);
					continue
				end
			else %no eyetracker, simple show cross
				fixated = 'fix';
				%                 drawCross(sM,0.3,[0 0 0 1],fixX,fixY);
				Screen('Flip',sM.win);
				WaitSecs('YieldSecs',0.75);
			end
			%if we lost fixation then
			if ~strcmpi(fixated,'fix'); continue; end
			
			%=========================Our actual stimulus drawing loop==========================
			if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
			
			rgb2 = rgb_start + rgb_step.*iii;  %get the value of rgb2 under each trials
			vbl = Screen('Flip',sM.win);
			for i = 1:numChange
				rgb3 = mod(i,2)*rgb1+mod(i+1,2)*rgb2; %exchange colors
				rgb4 = mod(i+1,2)*rgb1+mod(i,2)*rgb2;
				for j = 1:onFrames
					Screen('FillRect', sM.win, rgb3, sM.winRect);
					Screen('FillOval', sM.win, rgb4, circleRect);
					% Screen('FillRect',sM.win,sM.winhite,[wrect(3)-120 0 wrect(3) 120]); % white square for photodiode
					% vbl = Screen('Flip',sM.win,vbl+(waitframes-0.5)*ifi);
					Screen('Flip',sM.win);
					
					if useEyeLink
						getSample(eL);
						isfix = isFixated(eL);
						if ~isfix
							fixated = 'breakfix';
							break %break the while loop
						end
					end
					%                     [vbl,~,~,missed] = Screen('Flip', w, vbl + ana.halfifi);
					%                     if missed>0 && isempty(windowed); fprintf('---!!! Missed frame !!!---\n'); end
					
				end
				
				Screen('Flip',sM.win);
			end
			
			%             sM.drawBackground();
			Screen('Flip',sM.win);
			% 			thisTrial = iii;
			% check if we lost fixation
			if ~strcmpi(fixated,'fix')
				fprintf('===>>> BROKE FIXATION Trial = %i\n', iii);
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix');
				resetFixation(eL);
				stopRecording(eL);
				setOffline(eL);
				continue
			end
			iii = iii+1;
			Screen('FillRect', sM.win, [0 0 0], sM.winRect);
			Screen('Flip',sM.win);
			pause(1);
		end % END iii <= trials
		if iii>=trials; breakLoop = true; end
		
	end
	close(sM);
	ListenChar(0);ShowCursor;Priority(0);Screen('CloseAll');
	if exist(ResultDir,'dir')
		cd(ResultDir);
	end
	disp(['==>> SAVE, saved current data to: ' pwd]);
	
	save([nameExp '.mat'],'ana','eL');
	
	%     savefig(figH, [nameExp '.fig']);
	if useEyeLink == true; close(eL); end
catch ME
	close(sM);
	ListenChar(0);ShowCursor;Priority(0);Screen('CloseAll');
	getReport(ME)
end


	function saveMetaData()
		
		ana.ResultDir =  ResultDir;
		ana.backgroundColor = backgroundColor;
		ana.stdDis = stdDis;
		ana.xCen = xCen;
		ana.yCen = yCen;
		
		ana.useEyeLink = useEyeLink;
		ana.isDummy = isDummy;
		ana.pixelsPerCm = pixelsPerCm; %26 for Dorris lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
		ana.distance = distance; %64.5 in Dorris lab;
		ana.windowed = windowed;
		ana.eL = eL;
		
		ana.fixX = fixX;
		ana.fixY = fixY;
		ana.firstFixInit = firstFixInit;
		ana.firstFixTime = firstFixTime;
		ana.firstFixRadius = firstFixRadius;
		ana.strictFixation = strictFixation;
		
	end
end
