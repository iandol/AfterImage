function maskedAILatency()

%----------compatibility for windows
KbName('UnifyKeyNames'); %if ispc; clear all; pack; end

%==========================Base Experiment settings==============================
ans = inputdlg({'Subject Name','Comments (room, lights etc.)'});
subject = ans{1};
lab = 'lab214_aristotle'; %which lab or machine?
staircase = true;
useGratingMask = true;
comments = ans{2};
stimTime = 8;
maskDelay = 0.35;
maskTime = 1;
nBlocks = 128; %number of repeated blocks?
sigma = 3;
discSize = 3;
maskDelayTimes = [0.04 0.07 0.1 0.12 0.14 0.16 0.2 0.3 0.4];
maxTime = 0.9; %max mask time
ITI = 1; %inter trial interval

if strcmpi(lab,'lab214_aristotle')
	calibrationFile=load('Calib-AristotlePC-G5201280x1024x852.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	else 
		calibrationFile = [];
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = false;
	isDummy = true;
	pixelsPerCm = 36; %34 G520@1280x1024, 26@1024x768 for G520, 40=Dell LCF and iMac (retina native), 32=Lab CRT, 44=27"monitor or Macbook Pro
	distance = 57.7; %64.5 in Dorris lab;
	windowed = [];
	useScreen = []; %screen 2 in lab is CRT
	eyelinkIP = []; %keep it empty to force the default
elseif strcmpi(lab,'aristotle')
	calibrationFile=[]; %load('Calib_Dell_LCD.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	else 
		calibrationFile = [];
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = false;
	isDummy = true;
	pixelsPerCm = 40; %26 for Dorris lab G520, 40=Dell LCF and iMac (retina native), 32=Lab CRT, 44=27"monitor or Macbook Pro
	distance = 50; %64.5 in Dorris lab;
	windowed = [];
	useScreen = []; %screen 1 in Dorris lab is CRT
	eyelinkIP = []; %keep it empty to force the default
else
	calibrationFile='';%load('Calib_Dorris_G520.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	else 
		calibrationFile = [];
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = true;
	isDummy = true;
	pixelsPerCm = 32; %26 for Dorris lab, 32=Lab CRT, 44=27"monitor or Macbook Pro
	distance = 50; %64.5 in Dorris lab;
	windowed = [800 600];
	useScreen = [0]; %screen 1 in Dorris lab is CRT
	eyelinkIP = []; %keep it empty to force the default
end

%-------------------response values, linked to left, up, down
NOSEE = 0; 	YESSEE = 1; UNSURE = 4;

%-----------------------Positions to move stimuli
XPos = [3 1.5 -1.5 -1.5 1.5 -3];
YPos = [0 2.598 2.598 -2.598 -2.598 0];

%----------------eyetracker settings-------------------------
fixX = 0;
fixY = 0;
firstFixInit = 1;
firstFixTime = 0.5;
firstFixRadius =1.5;
strictFixation = true;

%----------------Make a name for this run-----------------------
if staircase; pf='AISTAIRLatency_'; else pf='AILatency_'; end
nameExp = [pf subject];
c = sprintf(' %i',fix(clock()));
c = regexprep(c,' ','_');
nameExp = [nameExp c];

%======================================stimulus objects=======================
%---------------------main disc (stimulus and pedestal).
st = discStimulus();
st.name = ['STIM_' nameExp];
st.xPosition = -3;
st.colour = [1 1 1 1];
st.size = discSize;
st.sigma = sigma;

%-----mask stimulus
m = gratingStimulus();
m.contrast = 0.8;
m.angle = 45;
m.sf = 3;
m.tf = 2;
m.colour = backgroundColour;
m.name = ['MASK_' nameExp];
m.xPosition = st.xPosition;
m.size = st.size;
m.sigma = st.sigma;

%-----combine them into a single meta stimulus
stimuli = metaStimulus();
stimuli.name = nameExp;

sidx = 1;
maskidx = 1;
stimuli{sidx} = st;
stimuli.maskStimuli{maskidx} = m;
stimuli.showMask = false;

%==============================open the PTB screens=======================
s = screenManager('verbose',false,'blend',true,'screen',useScreen,...
	'pixelsPerCm',pixelsPerCm,...
	'distance',distance,'bitDepth','FloatingPoint32BitIfPossible',...
	'debug',false,'antiAlias',[],'nativeBeamPosition',true, ...
	'srcMode','GL_SRC_ALPHA','dstMode','GL_ONE_MINUS_SRC_ALPHA',...
	'windowed',windowed,'backgroundColour',[backgroundColour 0],...
	'gammaTable', calibrationFile); %use a screenManager object
screenVals = open(s); %open PTB screen
setup(stimuli,s); %setup our stimulus object with our PTB screen

%==============================setup eyelink==========================
if useEyeLink == true
	eL = eyelinkManager('IP',eyelinkIP);
	%eL.verbose = true;
	eL.isDummy = isDummy; %use dummy or real eyelink?
	eL.name = nameExp;
	eL.saveFile = [nameExp '.edf'];
	eL.recordData = true; %save EDF file
	eL.sampleRate = 500;
	eL.remoteCalibration = false; % manual calibration?
	eL.calibrationStyle = 'HV5'; % calibration style
	eL.modify.calibrationtargetcolour = [1 1 1];
	eL.modify.calibrationtargetsize = 0.5;
	eL.modify.calibrationtargetwidth = 0.01;
	eL.modify.waitformodereadytime = 500;
	eL.modify.devicenumber = -1; % -1 = use any keyboard
	% X, Y, FixInitTime, FixTime, Radius, StrictFix
	updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixRadius, strictFixation);
	initialise(eL, s);
	setup(eL);
else
	eL = [];
end

%---------------------------Set up task variables----------------------
task = stimulusSequence();
task.name = nameExp;
task.nBlocks = 50;
task.nVar(1).name = 'colour';
task.nVar(1).stimulus = [1];
task.nVar(1).values = [0 1];
randomiseStimuli(task);
initialiseTask(task);

if staircase == true
	
	stopCriterion = 'trials';
	stopRule = 25;
	
	stims = linspace(0.022,maxTime,50);
	priorAlphaB = [0:0.01:maxTime];
	priorAlphaW = [0:0.01:maxTime];
	priorBeta = [0.5:0.5:4]; %our slope
	priorGammaRange = 0.5;  %fixed value (using vector here would make it a free parameter) 
	priorLambdaRange = [0.02:0.02:0.12]; %ditto
	
	taskB = PAL_AMPM_setupPM('stimRange',stims,'PF',@PAL_Weibull,...
		'priorAlphaRange', priorAlphaB, 'priorBetaRange', priorBeta,...
		'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
		'numTrials', stopRule,'marginalize','lapse');
	
	taskW = PAL_AMPM_setupPM('stimRange',stims,'PF',@PAL_Weibull,...
		'priorAlphaRange', priorAlphaW, 'priorBetaRange', priorBeta,...
		'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
		'numTrials', stopRule,'marginalize','lapse');
	
	priorB = PAL_pdfNormal(taskB.priorAlphas,0.25,1).*PAL_pdfNormal(taskB.priorBetas,2,3);
	priorW = PAL_pdfNormal(taskW.priorAlphas,0.25,1).*PAL_pdfNormal(taskW.priorBetas,2,3);
% 	figure; 
% 	subplot(1,2,1);imagesc(taskB.priorAlphaRange,taskB.priorBetaRange,priorB);axis square
% 	subplot(1,2,2);imagesc(taskW.priorAlphaRange,taskW.priorBetaRange,priorW); axis square
% 	xlabel('Threshold');ylabel('Slope');title('Initial Bayesian Priors')

	taskB = PAL_AMPM_setupPM(taskB,'prior',priorB);
	taskW = PAL_AMPM_setupPM(taskW,'prior',priorB);
	
else

	taskB = stimulusSequence();
	taskB.name = nameExp;
	taskB.nBlocks = 8;
	taskB.nVar(1).name = 'maskDelayB';
	taskB.nVar(1).stimulus = [1];
	taskB.nVar(1).values = maskDelayTimes;
	randomiseStimuli(taskB);
	initialiseTask(taskB);

	taskW = stimulusSequence();
	taskW.name = nameExp;
	taskW.nBlocks = 8;
	taskW.nVar(1).name = 'maskDelayW';
	taskW.nVar(1).stimulus = [1];
	taskW.nVar(1).values = maskDelayTimes;
	randomiseStimuli(taskW);
	initialiseTask(taskW);

end

%=====================================================================
try %our main experimentqal try catch loop
	
	if useEyeLink == true; getSample(eL); end %load everything into memory
	
	loop = 1;
	posloop = 1;
	breakloop = false;
	fixated = 'no';
	response = NaN;
	
	task.response.redo = 0; %number of trials the subject was unsure and redid (left arrow)
	
	figH = figure('Position',[0 0 900 700],'NumberTitle','off','Name',...
		['Subject: ' subject ' @ ' lab ' started ' datestr(now) ' | ' comments]);
	box on; grid on; grid minor; ylim([0 0.5]);
	xlabel('Trials (red=BLACK-STIM blue=WHITE-STIM)')
	ylabel('Mask Latency')
	title('Masked Latency Experiment')
	drawnow; WaitSecs('YieldSecs',0.25);
	
	while ~breakloop
		%==============setup our values and print some info for the trial===========
		hide(stimuli);
		stimuli.showMask = false;
		colourOut = task.outValues{task.totalRuns,1};
		stimuli{1}.colourOut = colourOut;
		if colourOut == 0
			if staircase
				maskDelay = taskB.xCurrent;
			else
				maskDelay = taskB.outValues{taskB.totalRuns,1};
			end
			ts.selected = true;
		else
			if staircase
				maskDelay = taskW.xCurrent;
			else
				maskDelay = taskW.outValues{taskW.totalRuns,1};
			end
			ts.selected = false;
		end
		
		if posloop > 6; posloop = 1; end
		stimuli{1}.xPositionOut = XPos(posloop);
		stimuli{1}.yPositionOut = YPos(posloop);
		stimuli.maskStimuli{1}.xPositionOut = XPos(posloop);
		stimuli.maskStimuli{1}.yPositionOut = YPos(posloop);
		ts.x = XPos(posloop);
		ts.y = YPos(posloop);
		ts.size = stimuli{1}.size;
		
		currentUUID = num2str(dec2hex(floor((now - floor(now))*1e10)));
		
		save([tempdir filesep nameExp '.mat'],'task','taskB','taskW');
		Priority(MaxPriority(s.win));
		fprintf('\n===>>>START %i: maskDelay = %.3g | Colour = %.3g | ',task.totalRuns,maskDelay,colourOut);
		posloop = posloop + 1;
		stimuli.update();
		stimuli.maskStimuli{1}.update();
		
		tFix = 0; tStim = 0; tDelay = 0; tMask = 0; tMaskOff = 0; tEnd = 0;
		
		%======================initialise eyelink and draw fix spaot================
		if useEyeLink
			resetFixation(eL);
			updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixRadius, strictFixation);
			trackerClearScreen(eL);
			trackerDrawFixation(eL); %draw fixation window on eyelink computer
			trackerDrawStimuli(eL,ts);
			edfMessage(eL,'V_RT MESSAGE END_FIX END_RT');  %this 3 lines set the trial info for the eyelink
			edfMessage(eL,['TRIALID ' num2str(task.totalRuns)]);  %obj.getTaskIndex gives us which trial we're at
			edfMessage(eL,['UUID ' currentUUID]); %add a unique ID
			edfMessage(eL,['MSG:MASKDELAY ' num2str(maskDelay)]); %add in the delay of the current state for good measure
			startRecording(eL);
			syncTime(eL);
			statusMessage(eL,'INITIATE FIXATION...');
			fixated = '';
			while ~strcmpi(fixated,'fix') && ~strcmpi(fixated,'breakfix')
				drawCross(s,0.4,[0 0 0 1],fixX,fixY);
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				tFix = Screen('Flip',s.win); %flip the buffer
				getSample(eL);
				fixated=testSearchHoldFixation(eL,'fix','breakfix');
				[keyIsDown, ~, keyCode] = KbCheck(-1);
				if keyIsDown == 1
					rchar = KbName(keyCode);
					if iscell(rchar);rchar=rchar{1};end
					switch lower(rchar)
						case {'c'}
							fixated = 'breakfix';
							stopRecording(eL);
							setOffline(eL);
							trackerSetup(eL);
							WaitSecs(2);
						case {'d'}
							fixated = 'breakfix';
							stopRecording(eL);
							driftCorrection(eL);
							WaitSecs(2);
						case {'q'}
							fixated = 'breakfix';
							breakloop = true;
					end
				end
			end
		else
			drawCross(s,0.4,[0 0 0 1],fixX,fixY);
			tFix = Screen('Flip',s.win); %flip the buffer
			WaitSecs('YieldSecs',0.5);
			fixated = 'fix';
		end
		
		%------Our main stimulus drawing loop
		while strcmpi(fixated,'fix') %initial fixation held
			if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
			stimuli.show();
			
			%-------------------show stimulus
			vbl = GetSecs; vbls = vbl;
			while GetSecs < vbls+stimTime
				draw(stimuli); %draw stimulus
				drawCross(s,0.4,[0 0 0 1],fixX,fixY);
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				if useEyeLink
					getSample(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break;
					end
				end
				animate(stimuli); %animate stimulus, will be seen on next draw
				nextvbl = vbl + screenVals.halfisi;
				vbl = Screen('Flip',s.win, nextvbl); %flip the buffer
				if tStim==0;tStim=vbl;end
			end
			if ~strcmpi(fixated,'fix')
				statusMessage(eL,'Subject Broke Fixation!'); edfMessage(eL,'BreakFix')
				continue
			end
			
			%----------------show variable delay before mask
			vbl = GetSecs; vbls = vbl;
			while GetSecs < vbls + maskDelay
				drawBackground(s); %draw background
				drawCross(s,0.4,[0 0 0 1],fixX,fixY);
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				if useEyeLink
					getSample(eL); 
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break;
					end
				end
				nextvbl = vbl + screenVals.halfisi;
				vbl = Screen('Flip',s.win, nextvbl); %flip the buffer
				if tDelay==0; tDelay = vbl; end
			end
			if ~strcmpi(fixated,'fix')
				statusMessage(eL,'Subject Broke Fixation!'); edfMessage(eL,'BreakFix')
				continue
			end
			
			%------------------------show mask
			if useGratingMask; stimuli.showMask = true; end%metaStimulus can trigger a mask
			vbl = GetSecs; vbls = vbl;
			while GetSecs < vbls + maskTime
				draw(stimuli); %draw stimulus
				drawCross(s,0.4,[0 0 0 1],fixX,fixY);
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				animate(stimuli); %animate stimulus, will be seen on next draw
				nextvbl = vbl + screenVals.halfisi;
				vbl = Screen('Flip',s.win, nextvbl); %flip the buffer
				if tMask==0; tMask = vbl;end
			end
			
			%---------------------get response
			Priority(0);
			drawBackground(s);
			Screen('DrawText',s.win,['See anything AFTER stimulus: [A]=YES [B]=NO'],0,0);
			if useEyeLink
				statusMessage(eL,'Waiting for Subject Response!');
				edfMessage(eL,'Subject Responding')
				edfMessage(eL,'END_RT'); ...
			end
			tMaskOff = Screen('Flip',s.win);
			checkKeys();
		end
		
		if useEyeLink
			resetFixation(eL);
			stopRecording(eL);
			edfMessage(eL,['TRIAL_RESULT ' num2str(response)]);
			setOffline(eL);
		end
		drawBackground(s);
		Screen('Flip',s.win); %flip the buffer
		if staircase 
			if taskW.stop && taskB.stop
				fprintf('\n======>>> Adaptive Methods finished!\n');
				breakloop = true;
			end
		else
			if task.totalRuns > task.nRuns
				fprintf('\n======>>> Main Task Loop Completed!\n');
				breakloop = true;
			end
		end
		Priority(0);
		WaitSecs(ITI);
	end
	
	%=================================Cleanup
	Screen('Flip',s.win);
	Priority(0); ListenChar(0); ShowCursor;
	close(s); %close screen
	p=uigetdir(pwd,'Select Directory to Save Data, CANCEL to not save.');
	if isstr(p)
		cd(p);
		md = saveMetaData();
		save([nameExp '.mat'], 'task', 'taskB', 'taskW', 'md', 's', 'stimuli', 'eL');
		if ishandle(figH); saveas(figH, [nameExp '.fig']); end
		disp(['=====SAVE, saved current data to: ' pwd]);
	else
		eL.saveFile = ''; %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
	reset(stimuli); %reset our stimulus ready for use again
	
catch ME
	close(s); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	md = saveMetaData();
	save([nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW', 'md', 's', 'stimuli', 'eL', 'ME')
	if ishandle(figH); saveas(figH, [nameExp 'CRASH.fig']); end
	ple(ME)
	if useEyeLink == true; eL.saveFile = [nameExp 'CRASH.edf']; close(eL); end
	reset(stimuli);
	clear stimuli task taskB taskW md eL s
	rethrow(ME);
end

%=============================MEASURE the REPSONSE=====================
	function updateResponse()
		if response == NOSEE || response == YESSEE %subject responded
			fprintf('\tResponse = %i | maskDelay = %.2g | Contrast = %i | Trial = %i ', response,maskDelay,colourOut,task.totalRuns);
			fprintf(' TIMES: %.2g %.2g %.2g %.2g', tDelay-tStim , tMask-tDelay, tMaskOff-tMask, tEnd-tMaskOff); 
			task.response.response(task.totalRuns) = response;
			task.response.N = task.totalRuns;
			task.response.times(task.totalRuns,:) = [tFix tStim tDelay tMask tMaskOff tEnd];
			task.response.contrastOut(task.totalRuns) = colourOut;
			task.response.maskDelay(task.totalRuns) = maskDelay;
			task.response.UUID{task.totalRuns} = currentUUID;
			task.totalRuns = task.totalRuns + 1;
			
			if staircase
				if colourOut == 0
					task.response.xCurrent = taskB.xCurrent;
					taskB = PAL_AMPM_updatePM(taskB,response);
				else
					task.response.xCurrent = taskW.xCurrent;
					taskW = PAL_AMPM_updatePM(taskW,response);
				end
			else
				task.response.blackN(task.totalRuns) = taskB.totalRuns;
				task.response.whiteN(task.totalRuns) = taskW.totalRuns;
				if colourOut == 0
					taskB.totalRuns = taskB.totalRuns + 1;
				else
					taskW.totalRuns = taskW.totalRuns + 1;
				end
			end
		elseif response == -1
			if task.totalRuns > 1
				fprintf(' SUBJECT RESET of trial %i -- ', task.totalRuns);
				task.totalRuns = task.totalRuns - 1;
				if task.response.contrastOut(end) == 0
					taskB.totalRuns = taskB.totalRuns - 1;
				else
					taskW.totalRuns = taskW.totalRuns - 1;
				end
				task.response.N = task.totalRuns;
				task.response.response(end) = [];
				task.response.contrastOut(end) = [];
				task.response.maskDelay(end) = [];
				task.response.blackN(end) = [];
				task.response.whiteN(end) = [];
				fprintf('NEW TRIAL NUMBER  = %i\n', task.totalRuns);
			end
		elseif response == UNSURE
			task.response.redo = task.response.redo + 1;
			fprintf(' Subject REDO, overall = %.2g ',task.response.redo);
		end
	end

%=============================PLOT THE DATA=====================
	function doPlot()
		if ~isfield(task.response,'response') || isempty(task.response.response)
			return
		end
		figure(figH);
		x = 1:length(task.response.response);
		delay = task.response.maskDelay;
		
		idxW = task.response.contrastOut == 1;
		idxB = task.response.contrastOut == 0;
		
		idxNOSEE = task.response.response == NOSEE;
		idxYESSEE = task.response.response == YESSEE;
		
		cla; 
		if staircase; subplot(2,1,1); end
		
		hold on
		
		plot(x(idxNOSEE & idxB), delay(idxNOSEE & idxB),'ro','MarkerFaceColor','r','MarkerSize',8); 
		plot(x(idxNOSEE & idxW), delay(idxNOSEE & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(x(idxYESSEE & idxB), delay(idxYESSEE & idxB),'ro','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESSEE & idxW), delay(idxYESSEE & idxW),'bo','MarkerFaceColor','w','MarkerSize',8);
		
		if length(task.response.response) > 4
			try
				idx = idxNOSEE & idxB;
				blackDelay = delay(idx);
				[bAvg, bErr] = stderr(blackDelay);
				idx = idxNOSEE & idxW;
				whiteDelay = delay(idx);
				[wAvg, wErr] = stderr(whiteDelay);
				if length(blackDelay) > 4 && length(whiteDelay)> 4
					p = ranksum(abs(blackDelay-0.5),abs(whiteDelay-0.5));
				else
					p = 1;
				end
				t = sprintf('NEXT TRIAL:%i \nBLACK=%.2g +- %.2g (%i)| WHITE=%.2g +- %.2g (%i) | P=%.2g ', task.totalRuns, bAvg, bErr, length(blackDelay), wAvg, wErr, length(whiteDelay), p);
				title(t);
			end
		else
			t = sprintf('NEXT TRIAL:%i', task.totalRuns);
			title(t);
		end
		box on; grid on; grid minor;
		xlabel('Total Trials (red=BLACK blue=WHITE)');
		ylabel('Mask Delay (seconds)');
		hold off;
		if staircase
			subplot(2,1,2); hold on;
			if ~isempty(taskB.response); errorbar(taskB.threshold,taskB.seThreshold,'ro-'); end
			if ~isempty(taskW.response); errorbar(taskW.threshold,taskW.seThreshold,'bo-'); end
			xlabel('Trials (red=BLACK blue=WHITE)');
			ylabel('Mask Delay (seconds)');
			hold off
			box on; grid on; grid minor;
		end
		drawnow;
	end

	function md = saveMetaData()
		md = struct();
		md.subject = subject;
		md.lab = lab;
		md.staircase = staircase;
		md.useGratingMask = useGratingMask;
		md.comments = comments;
		md.calibrationFile = calibrationFile;
		md.useEyeLink = useEyeLink;
		md.isDummy = isDummy;
		md.backgroundColour = backgroundColour;
		md.stimTime = stimTime;
		md.maskDelay = maskDelay;
		md.maskTime = maskTime;
		md.maskDelayTimes = maskDelayTimes;
		md.maxTime = maxTime;
		md.ITI = ITI;
		md.pixelsPerCm = pixelsPerCm; %26 for Dorris lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
		md.distance = distance; %64.5 in Dorris lab;
		md.nBlocks = nBlocks; %number of repeated blocks?
		md.windowed = windowed;
		md.useScreen = useScreen; %screen 1 in Dorris lab is CRT
		md.eyelinkIP = eyelinkIP;
		md.sigma = sigma;
		md.discSize = discSize;
		md.NOSEE = NOSEE;
		md.YESSEE = YESSEE;
		md.UNSURE = UNSURE;
		md.XPos = XPos;
		md.yPos = YPos;
		
		md.fixX = fixX;
		md.fixY = fixY;
		md.firstFixInit = firstFixInit;
		md.firstFixTime = firstFixTime;
		md.firstFixRadius = firstFixRadius;
		md.strictFixation = strictFixation;
		
	end

	function checkKeys() %----------------------check keyboard
			rchar = '';
			ListenChar(2);
			if ispc
				[buttons, keyCode, xy] = JoyStickWait(0);
				if any(buttons)
					if buttons(1) == 1
						rchar = 'left';
					elseif buttons(2) == 1
						rchar = 'right';
					elseif buttons(3) == 1
						rchar = 'down';
					elseif buttons(4) == 1
						rchar = 'down';
					elseif xy(1) == 0
						rchar = 'c';
					elseif xy(1) > 65000
						rchar = 'd';
					end
				else
					rchar = KbName(keyCode); if iscell(rchar);rchar=rchar{1};end	
				end
			else
				[~, keyCode] = KbWait(-1);
				rchar = KbName(keyCode); if iscell(rchar);rchar=rchar{1};end	
			end
			tEnd = GetSecs; 
			ListenChar(0);
			switch lower(rchar)
				case {'leftarrow','left'}
					breakloopkey = true; fixated = 'no';
					response = YESSEE;
					if useEyeLink
						statusMessage(eL,['Subject Pressed LEFT: response = ' num2str(response)]);
						edfMessage(eL,['Subject Pressed LEFT: response = ' num2str(response)])
					end
					updateResponse();
					doPlot();
				case {'rightarrow','right'} %brighter than
					breakloopkey = true; fixated = 'no';
					response = NOSEE;
					if useEyeLink
						statusMessage(eL,['Subject Pressed RIGHT: response = ' num2str(response)]);
						edfMessage(eL,['Subject Pressed RIGHT: response = ' num2str(response)])
					end
					updateResponse();
					doPlot();
				case {'downarrow','down'} %darker than
					breakloopkey = true; fixated = 'no';
					response = UNSURE;
					updateResponse();
					if useEyeLink
						statusMessage(eL,'Subject Pressed DOWN!');
						edfMessage(eL,'Subject Pressed DOWN')
					end
					updateResponse();
					doPlot();
				case {'backspace','delete'}
					breakloopkey = true; fixated = 'no';
					response = -1;
					updateResponse();
					if useEyeLink
						statusMessage(eL,'Subject UNDO!');
						edfMessage(eL,'Subject UNDO')
					end
					doPlot();
				case {'c'} %calibrate
					breakloopkey = true; fixated = 'no';
					if useEyeLink
						stopRecording(eL);
						setOffline(eL);
						trackerSetup(eL);
						WaitSecs(2);
					end
				case {'d'}
					breakloopkey = true; fixated = 'no';
					if useEyeLink
						stopRecording(eL);
						setOffline(eL);
						success = driftCorrection(eL);
						WaitSecs(2);
					end
				case {'q'} %quit
					breakloopkey = true; fixated = 'no';
					fprintf('\n!!!QUIT!!!\n');
					response = NaN;
					breakloop = true;
				otherwise
					breakloopkey = true; fixated = 'no';
					response = UNSURE;
					updateResponse();
					if useEyeLink
						statusMessage(eL,'Subject UNSURE!');
						edfMessage(eL,'Subject UNSURE')
					end
			end
	end

	function [avg,error] = stderr(data,type,onlyerror)
		if nargin<3; onlyerror=0; end
		if nargin<2; type='SE';	end
		if size(type,1)>1; type=reshape(type,1,size(type,1));	end
		if size(data,1) > 1 && size(data,2) > 1; nvals = size(data,1);
		else nvals = length(data); end
		avg=nanmean(data);
		switch(type)
			case 'SE'
				err=nanstd(data);
				error=sqrt(err.^2/nvals);
			case '2SE'
				err=nanstd(data);
				error=sqrt(err.^2/nvals);
				error = error*2;
			case 'CIMEAN'
				[error, raw] = bootci(1000,{@nanmean,data},'alpha',0.01);
				avg = nanmean(raw);
			case 'CIMEDIAN'
				[error, raw] = bootci(1000,{@nanmedian,data},'alpha',0.01);
				avg = nanmedian(raw);
			case 'SD'
				error=nanstd(data);
			case '2SD'
				error=(nanstd(data))*2;
			case '3SD'
				error=(nanstd(data))*3;
			case 'V'
				error=nanstd(data).^2;
			case 'F'
				if max(data)==0
					error=0;
				else
					error=nanvar(data)/nanmean(data);
				end
			case 'C'
				if max(data)==0
					error=0;
				else
					error=nanstd(data)/nanmean(data);
				end
			case 'A'
				if max(data)==0
					error=0;
				else
					error=nanvar(diff(data))/(2*nanmean(data));
				end
		end
		if onlyerror==1
			avg=error;
		end
	end

end

