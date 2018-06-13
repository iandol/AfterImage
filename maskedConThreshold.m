function maskedConThreshold()

%----------compatibility for windows
%if ispc; PsychJavaTrouble(); end
KbName('UnifyKeyNames');

%------------Base Experiment settings--------------
sinfo = inputdlg({'\bfSubject Name','Comments (\itroom, lights etc.)'},...
	'Afterimage Contrast Matching',...
	[1 50;5 50],{'Anon',''},struct('Resize','on','Interpreter','tex'));
if isempty(sinfo);return;end
subject = sinfo{1};

comments = sinfo{2};
lab = 'lab305_aristotle'; %which lab and machine?
useStaircase = true;
stimTime = 0.4;
pedestalTime = 0;
maskTime = 1.5;
sigma = 10;
discSize = 3;
nBlocks = 4;

if strcmpi(lab,'lab305_aristotle')
	calibrationFile=[];%load('AOCat60Hz_COLOR.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = true;
	isDummy = false;
	pixelsPerCm = 27; %26 for D-lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
	distance = 62.5; %64.5 in D-lab;
	windowed = [];
	useScreen = 1; %screen 2 in D-lab is CRT
	eyelinkIP = []; %keep it empty to force the default
	if useStaircase
		PF = @PAL_Gumbel;
		slopeMax = 200;
		gammaVal = 0.5;
		lambdaVal = 0.01;
		marginalize = [2];
		pedestalRange = 0:0.003:0.09;
		pedestalBlack = pedestalRange;
		pedestalBlackLinear = pedestalBlack;
		pedestalWhite = pedestalRange;
		pedestalWhiteLinear = pedestalWhite;
	else
		pedestalRange = 0:0.003:0.09; % pedestalRange here is the stimulus contrast 
		pedestalBlack = 0.5 - pedestalRange;
		pedestalBlackLinear = pedestalBlack;
		pedestalWhite = 0.5 + pedestalRange;
		pedestalWhiteLinear = pedestalWhite;
	end
elseif strcmpi(lab,'lab214_aristotle')
	calibrationFile=load('Calib-AristotlePC-G5201280x1024x852.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = true;
	isDummy = false;
	pixelsPerCm = 36; %26 for D-lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
	distance = 56.5; %64.5 in D-lab;
	windowed = [];
	useScreen = 2; %screen 2 in D-lab is CRT
	eyelinkIP = []; %keep it empty to force the default
	pedestalBlackLinear = 0.5 - fliplr(pedestalRange);
	pedestalWhiteLinear = 0.5 + pedestalRange;
	pedestalBlack =  pedestalBlackLinear;
	pedestalWhite = pedestalWhiteLinear;
end
nBlocksOverall = nBlocks * length(pedestalRange);

%-------------------response values, linked to left, up, down
NOSEE = 1; 	YESSEE = 2; UNSURE = 4; BREAKFIX = -1;

%-----------------------Positions to move stimuli
XPos = [3 1.5 -1.5 -1.5 1.5 -3];
YPos = [0 2.598 2.598 -2.598 -2.598 0];

%----------------eyetracker settings-------------------------
fixX = 0;
fixY = 0;
firstFixInit = 1;
firstFixTime = 0.5;
firstFixDiameter = 2;
strictFixation = true;

%----------------Make a name for this run-----------------------
if useStaircase; type = 'STAIR'; else type = 'MOC'; end %#ok<*UNRCH>
nameExp = ['AI' type '_' subject];
c = sprintf(' %i',fix(clock()));
c = regexprep(c,' ','_');
nameExp = [nameExp c];

%======================================================stimulus objects
%---------------------main disc (stimulus and pedestal).
st = discStimulus();
st.name = ['STIM_' nameExp];
st.xPosition = -3;
st.colour = [1 1 1 1];
st.size = discSize;
st.sigma = sigma;

%-----mask stimulus
m = dotsStimulus();
m.mask = true;
m.density = 1000;
m.coherence = 0;
m.size = st.size+1;
m.speed=0.5;
m.name = ['MASK_' nameExp];
m.xPosition = st.xPosition;
m.size = st.size;

%----------combine them into a single meta stimulus------------------
stimuli = metaStimulus();
stimuli.name = nameExp;

sidx = 1;
maskidx = 1;
stimuli{sidx} = st;
stimuli.maskStimuli{maskidx} = m;
stimuli.showMask = false;
%======================================================stimulus objects

%-----------------------open the PTB screens------------------------
sM = screenManager('verbose',false,'blend',true,'screen',useScreen,...
	'pixelsPerCm',pixelsPerCm,...
	'distance',distance,'bitDepth','FloatingPoint32BitIfPossible',...
	'debug',false,'antiAlias',0,'nativeBeamPosition',0, ...
	'srcMode','GL_SRC_ALPHA','dstMode','GL_ONE_MINUS_SRC_ALPHA',...
	'windowed',windowed,'backgroundColour',[backgroundColour 0]); %use a temporary screenManager object
if ~isempty(calibrationFile); sM.gammaTable = calibrationFile; end
screenVals = open(sM); %open PTB screen
setup(stimuli,sM); %setup our stimulus object

%---------------------setup eyelink---------------------------
if useEyeLink == true
	eL = eyelinkManager('IP',eyelinkIP); %eL.verbose = true;
	eL.isDummy = isDummy; %use dummy or real eyelink?
	eL.name = nameExp;
	eL.saveFile = [nameExp '.edf'];
	eL.recordData = true; %save EDF file
	eL.sampleRate = 250;
	eL.remoteCalibration = false; % manual calibration?
	eL.calibrationStyle = 'HV5'; % calibration style
	eL.modify.calibrationtargetcolour = [1 1 0];
	eL.modify.calibrationtargetsize = 0.5;
	eL.modify.calibrationtargetwidth = 0.01;
	eL.modify.waitformodereadytime = 500;
	eL.modify.devicenumber = -1; % -1 = use any keyboard
	% X, Y, FixInitTime, FixTime, Radius, StrictFix
	updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixDiameter, strictFixation);
	initialise(eL, sM);
	setup(eL);
	Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
	Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
	Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
	Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
end


%---------------------------Set up task variables----------------------
task = stimulusSequence();
task.name = nameExp;
task.nBlocks = nBlocksOverall;
task.nVar(1).name = 'colour';
task.nVar(1).stimulus = 1;
task.nVar(1).values = [0 1];
randomiseStimuli(task);
initialiseTask(task);

if useStaircase == false
	staircaseB = []; staircaseW = [];
	taskW = stimulusSequence();
	taskW.name = nameExp;
	taskW.nBlocks = nBlocks;
	taskW.nVar(1).name = 'pedestalWhite';
	taskW.nVar(1).stimulus = 1;
	taskW.nVar(1).values = pedestalWhite;
	randomiseStimuli(taskW);
	
	aaaaa
	initialiseTask(taskW);
	
	taskB = stimulusSequence();
	taskB.name = nameExp;
	taskB.nBlocks = nBlocks;
	taskB.nVar(1).name = 'pedestalBlack';
	taskB.nVar(1).stimulus = 1;
	taskB.nVar(1).values = pedestalBlack;
	randomiseStimuli(taskB);
	initialiseTask(taskB);
else
	taskB.thisRun = 0; taskW.thisRun = 0;
	stopCriterion = 'trials';
	trials = 40;
	stopRule = 40;
	usePriors = false;
	grain = 100;
	setupStairCase();
end

%=====================================================================
try %our main experimental try catch loop
%=====================================================================
	
	if useEyeLink == true; getSample(eL); end %ensure our eyelink code is in memory
	
	loop = 1;
	posloop = 1;
	breakloop = false;
	fixated = 'no';
	response = NaN;
	responseRedo = 0; %number of trials the subject was unsure and redid (left arrow)
	
	figH = figure('Position',[0 0 900 700],'NumberTitle','off','Name',...
		['Subject: ' subject ' @ ' lab ' started ' datestr(now) ' | ' comments]);
	box on; grid on; grid minor; ylim([0.4 0.6]);
	xlabel('Trials (red=BLACK blue=WHITE)')
	ylabel('Stimulus Luminance')
	title('Masked Contrast Pedestal Experiment')
	drawnow; WaitSecs(0.25);
	
	while ~breakloop && task.thisRun <= task.nRuns
		%-----setup our values and print some info for the trial
		hide(stimuli);
		response = NaN;
		stimuli.showMask = false;
		colourOut = task.outValues{task.thisRun,1};
		if useStaircase == true
			if colourOut == 0
				pedestal = 0.5-staircaseB.xCurrent;
			else
				pedestal = 0.5+staircaseW.xCurrent;
			end
		else
			if colourOut == 0
				pedestal = taskB.outValues{taskB.thisRun,1};
			else
				pedestal = taskW.outValues{taskW.thisRun,1};
			end
		end
		
		if posloop > 6; posloop = 1; end
		stimuli{1}.xPositionOut = XPos(posloop);
		stimuli{1}.yPositionOut = YPos(posloop);
		stimuli.maskStimuli{1}.xPositionOut = XPos(posloop);
		stimuli.maskStimuli{1}.yPositionOut = YPos(posloop);
		stimuli{1}.colourOut = pedestal;  % addd by xu
		
		ts.x = XPos(posloop);
		ts.y = YPos(posloop);
		ts.size = stimuli{1}.size;
		ts.selected = true;
		
		%save([tempdir filesep nameExp '.mat'],'task','taskB','taskW');
		fprintf('\n===>>>START %i: PEDESTAL = %.3g | Colour = %.3g | ',task.thisRun,pedestal,colourOut);
		
		Priority(MaxPriority(sM.win));
		posloop = posloop + 1;
		stimuli.update();
		stimuli.maskStimuli{1}.update();
		
		%-----initialise eyelink and draw fix spot
		if useEyeLink
			resetFixation(eL);
			updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixDiameter, strictFixation);
			trackerClearScreen(eL);
			trackerDrawFixation(eL); %draw fixation window on eyelink computer
			trackerDrawStimuli(eL,ts);
			edfMessage(eL,'V_RT MESSAGE END_FIX END_RT'); ... %this 3 lines set the trial info for the eyelink
			edfMessage(eL,['TRIALID ' num2str(task.thisRun)]); ... %obj.getTaskIndex gives us which trial we're at
			edfMessage(eL,['MSG:PEDESTAL ' num2str(pedestal)]); ... %add in the pedestal of the current state for good measure
			edfMessage(eL,['MSG:CONTRAST ' num2str(colourOut)]); ... %add in the pedestal of the current state for good measure
			startRecording(eL);
			statusMessage(eL,'INITIATE FIXATION...');
			fixated = '';
			syncTime(eL);
			while ~strcmpi(fixated,'fix') && ~strcmpi(fixated,'breakfix')
				drawCross(sM,0.4,[1 1 1 1],fixX,fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				tFix = Screen('Flip',sM.win); %flip the buffer
				getSample(eL);
				fixated=testSearchHoldFixation(eL,'fix','breakfix');
			end
			if strcmpi(fixated,'breakfix'); response = BREAKFIX; end
		else
			drawCross(sM,0.4,[1 1 1 1],fixX,fixY);
			tFix = Screen('Flip',sM.win); %flip the buffer
			WaitSecs(0.5);
			fixated = 'fix';
		end
		
		%------Our main stimulus drawing loop
		while strcmpi(fixated,'fix') %initial fixation held
			if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
			stimuli.show();
			tStim = GetSecs;
			vbl = tStim;
			while vbl <= tStim+stimTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],fixX,fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				if useEyeLink
					getSample(eL); %drawEyePosition(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break;
					end
				end
				animate(stimuli); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			if ~strcmpi(fixated,'fix')
				response = BREAKFIX; statusMessage(eL,'Subject Broke Fixation!'); edfMessage(eL,'MSG:BreakFix')
				continue
			end
			stimuli{1}.colourOut = pedestal;
			tPedestal=GetSecs;
			while GetSecs <= tPedestal + pedestalTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],fixX,fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				if useEyeLink
					getSample(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break;
					end
				end
				%animate(stimuli); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			if ~strcmpi(fixated,'fix')
				response = BREAKFIX; statusMessage(eL,'Subject Broke Fixation!'); edfMessage(eL,'MSG:BreakFix')
				continue
			end
			stimuli.showMask = true; %metaStimulus can trigger a mask
			tMask=GetSecs;
			while GetSecs <= tMask + maskTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],fixX,fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				animate(stimuli); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			
			drawBackground(sM);
			Screen('DrawText',sM.win,['See anything: [LEFT]=YES  [RIGHT]=NO  [DOWN]=UNSURE'],0,0);
			if useEyeLink
				statusMessage(eL,'Waiting for Subject Response!');
				edfMessage(eL,'Subject Responding')
				edfMessage(eL,'END_RT'); ...
			end
		tMaskOff = Screen('Flip',sM.win);
		
		%-----check keyboard
		%timeout = GetSecs+5;
		breakloopkey = false;
		ListenChar(2);
		while ~breakloopkey
			[keyIsDown, ~, keyCode] = KbCheck(-1);
			if keyIsDown == 1
				rchar = KbName(keyCode);
				if iscell(rchar);rchar=rchar{1};end
				switch lower(rchar)
					case {'leftarrow','left'}
						breakloopkey = true; fixated = 'no';
						response = YESSEE;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed LEFT!');
							edfMessage(eL,'Subject Pressed LEFT')
						end
						doPlot();
					case {'downarrow','down'} %darker than
						breakloopkey = true; fixated = 'no';
						response = UNSURE;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed RIGHT!');
							edfMessage(eL,'Subject Pressed RIGHT')
						end
						doPlot();
					case {'rightarrow','right'}
						breakloopkey = true; fixated = 'no';
						response = NOSEE;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject UNSURE!');
							edfMessage(eL,'Subject UNSURE')
						end
						doPlot();
					case {'backspace','delete'}
						breakloopkey = true; fixated = 'no';
						response = -10;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject UNDO!');
							edfMessage(eL,'Subject UNDO')
						end
						doPlot();
					case {'c'} %calibrate
						response = BREAKFIX;
						breakloopkey = true; fixated = 'no';
						stopRecording(eL);
						setOffline(eL);
						trackerSetup(eL);
						WaitSecs(2);
					case {'d'}
						response = BREAKFIX;
						breakloopkey = true; fixated = 'no';
						stopRecording(eL);
						setOffline(eL);
						success = driftCorrection(eL);
						WaitSecs(2);
					case {'q'} %quit
						response = BREAKFIX;
						breakloopkey = true; fixated = 'no';
						fprintf('\n!!!QUIT!!!\n');
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
			%if timeout<=GetSecs; breakloopkey = true; end
		end
		tEnd = GetSecs;
		ListenChar(0);
		end
		resetFixation(eL); trackerClearScreen(eL);
		stopRecording(eL);
		edfMessage(eL,['TRIAL_RESULT ' num2str(response)]);
		setOffline(eL);
		drawBackground(sM);
		Screen('Flip',sM.win); %flip the buffer
		WaitSecs(0.5);
	end
	%-----Cleanup
	Screen('Flip',sM.win);
	Priority(0); ListenChar(0); ShowCursor;
	close(sM); %close screen
	p=uigetdir(pwd,'Select Directory to Save Data, CANCEL to not save.');
	if ischar(p)
		cd(p);
		md = saveMetaData();
		response = task.response;
		responseInfo = task.responseInfo;
		save([nameExp '.mat'], 'response', 'responseInfo', 'task',...
			'taskB', 'taskW', 'staircaseB', 'staircaseW', 'md', 'sM',...
			'stimuli', 'eL');
		if ishandle(figH); saveas(figH, [nameExp '.fig']); end
		disp(['=====SAVE, saved current data to: ' pwd]);
	else
		eL.saveFile = ''; %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
	reset(stimuli); %reset our stimulus ready for use again
	
catch ME
	close(sM); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	md = saveMetaData();
	save([nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW',...
		'staircaseB', 'staircaseW', 'md', 'sM', 'stimuli', 'eL', 'ME')
	if ishandle(figH); saveas(figH, [nameExp 'CRASH.fig']); end
	ple(ME)
	if useEyeLink == true; eL.saveFile = [nameExp 'CRASH.edf']; close(eL); end
	reset(stimuli);
	clear stimuli task taskB taskW md eL s
	rethrow(ME);
end

	function updateResponse()
		tEnd = GetSecs;
		ListenChar(0);
		if response == NOSEE || response == YESSEE  %subject responded
			responseInfo.response = response;
			responseInfo.N = task.thisRun;
			responseInfo.times = [tFix tStim tPedestal tMask tMaskOff tEnd];
			responseInfo.contrastOut = colourOut;
			responseInfo.pedestal = pedestal;
			responseInfo.pedestalGamma = pedestal;
			responseInfo.blackN = taskB.thisRun;
			responseInfo.whiteN = taskW.thisRun;
			responseInfo.redo = responseRedo;
			updateTask(task,response,tEnd,responseInfo)
			if useStaircase == true
				if colourOut == 0
					if response == NOSEE 
						yesnoresponse = 0;
					else
						yesnoresponse = 1;
					end
					staircaseB = PAL_AMPM_updatePM(staircaseB, yesnoresponse);
				elseif colourOut == 1
					if response == NOSEE 
						yesnoresponse = 0;
					else
						yesnoresponse = 1;
					end
					staircaseW = PAL_AMPM_updatePM(staircaseW, yesnoresponse);
				end
			else
				if colourOut == 0
					taskB.thisRun = taskB.thisRun + 1;
				else
					taskW.thisRun = taskW.thisRun + 1;
				end
			end
		elseif response == -10
			if task.totalRuns > 1
				fprintf('Subject RESET of trial %i -- ', task.thisRun);
				if useStaircase == true
					warning('Not Implemented yet!!!')
				else
					if task.responseInfo(end) == 0
						taskB.rewindRun;
					else
						taskW.rewindRun;
					end
					task.rewindRun
					fprintf('new trial  = %i\n', task.thisRun);
				end
			end
		elseif response == UNSURE
			responseRedo = responseRedo + 1;
			fprintf('Subject is trying stimulus again, overall = %.2g %\n',responseRedo);
		end
	end

	function doPlot()
		ListenChar(0);
		figure(figH);
		
		x = 1:length(task.response);
		info = cell2mat(task.responseInfo);
		ped = [info.pedestal];
		
		idxW = [info.contrastOut] == 1;
		idxB = [info.contrastOut] == 0;
		
		idxNO = task.response == NOSEE;
		idxYESSEE = task.response == YESSEE;

		
		if useStaircase == true
			subplot(2,1,1)
		end
				
		
		cla; line([0 max(x)+1],[0.5 0.5],'LineStyle','--','LineWidth',2); hold on
		plot(x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(x(idxYESSEE & idxB), ped(idxYESSEE & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESSEE & idxW), ped(idxYESSEE & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);

		
		if length(task.response) > 4
			try %#ok<TRYNC>
				idx = idxNO & idxB;
				blackPedestal = ped(idx);
				[bAvg, bErr] = stderr(blackPedestal);
				idx = idxNO & idxW;
				whitePedestal = ped(idx);
				[wAvg, wErr] = stderr(whitePedestal);
				if length(blackPedestal) > 4 && length(whitePedestal)> 4
					p = ranksum(abs(blackPedestal-0.5),abs(whitePedestal-0.5));
				else
					p = 1;
				end
				t = sprintf('TRIAL:%i BLACK=%.2g +- %.2g (%i)| WHITE=%.2g +- %.2g (%i) | P=%.2g [B=%.2g W=%.2g]', task.thisRun, bAvg, bErr, length(blackPedestal), wAvg, wErr, length(whitePedestal), p, mean(abs(blackPedestal-0.5)), mean(abs(whitePedestal-0.5)));
				title(t);
			end
		else
			t = sprintf('TRIAL:%i', task.thisRun);
			title(t);
		end
		box on; grid on; ylim([0.4 0.6]); xlim([0 max(x)+1]);
		xlabel('Trials (red=BLACK blue=WHITE)')
		ylabel('Stimulus Luminance')
		hold off
		if useStaircase == true
			subplot(2,1,2)
			cla;
			hold on;
			if ~isempty(staircaseB.threshold)
				rB = [min(staircaseB.stimRange):.003:max(staircaseW.stimRange)];
				outB = PF([staircaseB.threshold(end) ...
					staircaseB.slope(end) staircaseB.guess(end) ...
					staircaseB.lapse(end)], rB);
				plot(rB,outB,'r-');
				
				r = staircaseB.response;
				t = staircaseB.x(1:length(r));
				yes = r == 1;
				no = r == 0; 
				plot(t(yes), ones(1,sum(yes)),'ko','MarkerFaceColor','r','MarkerSize',9);
				plot(t(no), zeros(1,sum(no))+gammaVal,'ro','MarkerFaceColor','w','MarkerSize',9);
			end
			if ~isempty(staircaseW.threshold)
				rW = [min(staircaseB.stimRange):.003:max(staircaseW.stimRange)];
				outW = PF([staircaseW.threshold(end) ...
					staircaseW.slope(end) staircaseW.guess(end) ...
					staircaseW.lapse(end)], rW);
				plot(rW,outW,'b-');
				
				r = staircaseW.response;
				t = staircaseW.x(1:length(r));
				yes = r == 1;
				no = r == 0; 
				plot(t(yes), ones(1,sum(yes)),'kd','MarkerFaceColor','b','MarkerSize',8);
				plot(t(no), zeros(1,sum(no))+gammaVal,'kd','MarkerFaceColor','w','MarkerSize',8);
			end
			box on; grid on; ylim([gammaVal 1]); xlim([0 0.1]);
			xlabel('Contrast (red=BLACK blue=WHITE)');
			ylabel('Responses');
			hold off
		end
		drawnow;
	end

	function setupStairCase()
		priorAlphaB = linspace(min(pedestalBlack), max(pedestalBlack),grain);
		priorAlphaW = linspace(min(pedestalWhite), max(pedestalWhite),grain);
		priorBetaB = linspace(0, slopeMax, 50); %our slope
		priorBetaW = linspace(0, slopeMax, 50); %our slope
		priorGammaRange = gammaVal;  %fixed value (using vector here would make it a free parameter)
		priorLambdaRange = lambdaVal; %ditto
		
		staircaseB = PAL_AMPM_setupPM('stimRange',pedestalBlack,'PF',PF,...
			'priorAlphaRange', priorAlphaB, 'priorBetaRange', priorBetaB,...
			'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
			'numTrials', stopRule,'marginalize',marginalize);
% 		staircaseB.xCurrent=0.4;
		staircaseW = PAL_AMPM_setupPM('stimRange',pedestalWhite,'PF',PF,...
			'priorAlphaRange', priorAlphaW, 'priorBetaRange', priorBetaW,...
			'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
			'numTrials', stopRule,'marginalize',marginalize);
		
		if usePriors
			priorB = PAL_pdfNormal(staircaseB.priorAlphas,0.3,0.05).*PAL_pdfNormal(staircaseB.priorBetas,3,8);
			priorW = PAL_pdfNormal(staircaseW.priorAlphas,0.3,0.05).*PAL_pdfNormal(staircaseW.priorBetas,3,8);
			figure;
			subplot(1,2,1);imagesc(staircaseB.priorBetaRange,staircaseB.priorAlphaRange,priorB);axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors BLACK')
			subplot(1,2,2);imagesc(staircaseW.priorBetaRange,staircaseW.priorAlphaRange,priorW); axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors WHITE')
			staircaseB = PAL_AMPM_setupPM(staircaseB,'prior',priorB);
			staircaseW = PAL_AMPM_setupPM(staircaseW,'prior',priorW);
		end
	end

	function md = saveMetaData()
		md = struct();
		md.subject = subject;
		md.lab = lab;
		md.comments = comments;
		md.calibrationFile = calibrationFile;
		md.useEyeLink = useEyeLink;
		md.isDummy = isDummy;
		md.useStaircase = useStaircase;
		md.backgroundColour = backgroundColour;
		md.stimTime = stimTime;
		md.pedestalTime = pedestalTime;
		md.maskTime = maskTime;
		md.pixelsPerCm = pixelsPerCm; %26 for Dorris lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
		md.distance = distance; %64.5 in Dorris lab;
		md.nBlocks = nBlocks;
		md.nBlocksOverall = nBlocksOverall;
		md.windowed = windowed;
		md.useScreen = useScreen; %screen 1 in Dorris lab is CRT
		md.eyelinkIP = eyelinkIP;
		md.pedestalRange = pedestalRange;
		md.pedestalBlackLinear = pedestalBlackLinear;
		md.pedestalWhiteLinear = pedestalWhiteLinear;
		md.pedestalBlack = pedestalBlack;
		md.pedestalWhite = pedestalWhite;
		md.sigma = sigma;
		md.discSize = discSize;
		md.NOSEE = NOSEE;
		md.YESSEE = YESSEE;
		md.UNSURE = UNSURE;
		md.BREAKFIX = BREAKFIX;
		md.XPos = XPos;
		md.yPos = YPos;
		
		md.fixX = fixX;
		md.fixY = fixY;
		md.firstFixInit = firstFixInit;
		md.firstFixTime = firstFixTime;
		md.firstFixRadius = firstFixDiameter;
		md.strictFixation = strictFixation;
		
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
% 			vbl = Screen('Flip',s.win);
% 			Screen('DrawText',s.win,['Mask Time: ' num2str(maskTime) ' | Match: B=' num2str(blackMatch) ' W=' num2str(whiteMatch) ],0,0);
% 			drawSpot(s,0.1,[1 1 0],fixX,fixY);
% 			if stimuli{1}.contrastOut > 0
% 				t.colourOut = (0.5/7)*0; t.xPositionOut = -6; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*1; t.xPositionOut = -2; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*2; t.xPositionOut =  2; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*3; t.xPositionOut =  6; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*4; t.xPositionOut = -6; t.yPositionOut = -3; update(t); draw(t);
% 				t.colourOut = (0.5/7)*5; t.xPositionOut = -2; t.yPositionOut = -3; update(t); draw(t);
% 				t.colourOut = (0.5/7)*6; t.xPositionOut =  2; t.yPositionOut = -3; update(t); draw(t);
% 				t.colourOut = (0.5/7)*7; t.xPositionOut =  6; t.yPositionOut = -3; update(t); draw(t);
% 			else
% 				t.colourOut = (0.5/7)*7;  t.xPositionOut = -6; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*8;  t.xPositionOut = -2; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*9;  t.xPositionOut =  2; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*10; t.xPositionOut =  6; t.yPositionOut = -7; update(t); draw(t);
% 				t.colourOut = (0.5/7)*11; t.xPositionOut = -6; t.yPositionOut = -3; update(t); draw(t);
% 				t.colourOut = (0.5/7)*12; t.xPositionOut = -2; t.yPositionOut = -3; update(t); draw(t);
% 				t.colourOut = (0.5/7)*13; t.xPositionOut =  2; t.yPositionOut = -3; update(t); draw(t);
% 				t.colourOut = (0.5/7)*14; t.xPositionOut =  6; t.yPositionOut = -3; update(t); draw(t);
% 			end
% 			Screen('flip',s.win);

