function isoluminant_stimuli()

%----------------Initiate out metadata-------------
ins = inputdlg({'Subject Name','Comments (room, lights etc.)'});
if isempty(ins); return; end
ana=[]; %this holds the experiment data and parameters
ana.ResultDir = "~/Desktop/IsoLum/";
ana.subject = ins{1};
ana.comments = ins{2};
ana.date = datestr(datetime);
ana.version = Screen('Version');
ana.computer = Screen('Computer');
ana.calibFile = [];
ana.isDummy = true;

%---------------------- experiment parameters -------------------------------
ana.screenID = max(Screen('Screens'));%-1;
ana.pixelsPerCm = 35;
ana.distance = 56.5;
ana.windowed = [0 0 1000 1000];
ana.backgroundColor = [0.5 0.5 0.5];
ana.frequency = 0.345;
ana.circleDiameter = 6;
ana.trialDuration = 3;

%----------------Make a name for this run-----------------------
pf='Isolum_';
nameExp = [pf ana.subject];
c = sprintf(' %i',fix(clock()));
c = regexprep(c,' ','_');
ana.nameExp = [nameExp c];

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
	PsychDefaultSetup(2);
	Screen('Preference', 'SkipSyncTests', 0);
	%-----------open our screen----------------
	sM = screenManager();
	sM.screen = ana.screenID;
	sM.windowed = ana.windowed;
	sM.pixelsPerCm = ana.pixelsPerCm;
	sM.distance = ana.distance;
	sM.backgroundColour = ana.backgroundColor;

	sM.open;
	
	%============================SET UP VARIABLES=====================================
	%%%input color paras
	rgb_start = [0 0 0];
	rgb_step = [0 0.1 0];
	rgb_end  = [0 1 0];
	rgb1 = [1 0 0];
	
	trials = (sum(rgb_end)-sum(rgb_start))/sum(rgb_step)+1; %
	
	%%%%%%%%set time
	onFrames = round(ana.frequency/sM.screenVals.ifi); % video frames for each color
	numChange = ana.trialDuration/(1/ana.frequency);%number of flash
	
	diameter = ceil(ana.circleDiameter*sM.ppd);
	circleRect = [0,0,diameter,diameter];
	circleRect = CenterRectOnPoint(circleRect, sM.xCenter, sM.yCenter);
	
	%==============================setup eyelink==========================

	eL = eyelinkManager('IP',[]);
	%eL.verbose = true;
	eL.isDummy = ana.isDummy; %use dummy or real eyelink?
	eL.name = ana.nameExp;
	eL.saveFile = [ana.nameExp '.edf'];
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
	
	%===================================================
	%global struct ana to save parameters
	saveMetaData();
	%======================================================
	
	% initialise our trial variables
	iii = 0;
	breakLoop = false;
	fixated = 'no';
	ifi = sM.screenVals.ifi;
	
	while ~breakLoop
		sM.drawBackground();
		Screen('Flip',sM.win);
		WaitSecs('YieldSecs',0.5);
		Priority(MaxPriority(sM.win));
		if iii<trials
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
			drawCross(sM,0.3,[0 0 0 1],fixX,fixY);
			Screen('Flip',sM.win); %flip the buffer
			syncTime(eL);
			%fprintf('===>>> INITIATE FIXATION Trial = %i\n', iii);
			while ~strcmpi(fixated,'fix') && ~strcmpi(fixated,'breakfix')
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
				end
			end
			ListenChar(0);
			if strcmpi(fixated,'breakfix')
				fprintf('===>>> BROKE INITIATE FIXATION Trial = %i\n', iii);
				statusMessage(eL,'Subject Broke Initial Fixation!');
				edfMessage(eL,'MSG:BreakFix');
				resetFixation(eL);
				stopRecording(eL);
				setOffline(eL);
				continue
			end

			%if we lost fixation then
			if ~strcmpi(fixated,'fix'); continue; end
			
			%=========================Our actual stimulus drawing loop==========================
			edfMessage(eL,'END_FIX'); 
			statusMessage(eL,'Show Stimulus...');
			
			rgb2 = rgb_start + rgb_step.*iii;  %get the value of rgb2 under each trials
			vbl = Screen('Flip',sM.win);
			for i = 1:numChange
				rgb3 = mod(i,2)*rgb1+mod(i+1,2)*rgb2; %exchange colors
				rgb4 = mod(i+1,2)*rgb1+mod(i,2)*rgb2;
				for j = 1:onFrames
					Screen('FillRect', sM.win, rgb3, sM.winRect);
					Screen('FillOval', sM.win, rgb4, circleRect);
					Screen('Flip',sM.win);
					getSample(eL);
					if ~isFixated(eL)
						fixated = 'breakfix';
						break %break the for loop
					end
				end
				if strcmpi(fixated,'breakfix');break;end %break second for loop
				Screen('Flip',sM.win);
			end
			
			sM.drawBackground();
			Screen('Flip',sM.win);

			% check if we lost fixation
			if ~strcmpi(fixated,'fix')
				fprintf('===>>> BROKE FIXATION Trial = %i\n', iii);
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix');
				resetFixation(eL);
				stopRecording(eL);
				setOffline(eL);
				continue
			else
				iii = iii+1;
			end

			WaitSecs('YieldSecs',1);

		end % END iii <= trials
		if iii>=trials; breakLoop = true; end
		
	end
	close(sM);
	close(eL);
	ListenChar(0);ShowCursor;Priority(0);Screen('CloseAll');
	if exist(ana.ResultDir,'dir')
		cd(ana.ResultDir);
		disp(['==>> SAVE, saved current data to: ' pwd]);
		save([ana.nameExp '.mat'],'ana','eL', 'sM');
	end
catch ME
	close(sM);
	ListenChar(0);ShowCursor;Priority(0);Screen('CloseAll');
	getReport(ME)
end


	function saveMetaData()

		ana.fixX = fixX;
		ana.fixY = fixY;
		ana.firstFixInit = firstFixInit;
		ana.firstFixTime = firstFixTime;
		ana.firstFixRadius = firstFixRadius;
		ana.strictFixation = strictFixation;
		
	end
end
