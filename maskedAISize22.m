function maskedAISize22(ana)

%----------compatibility for windows
%if ispc; PsychJavaTrouble(); end
KbName('UnifyKeyNames');

%------------Base Experiment settings--------------
ana.date = datestr(datetime);
ana.version = Screen('Version');
ana.computer = Screen('Computer');

%===================experiment parameters===================
if ana.debug
	ana.screenID = 0;
else
	ana.screenID = max(Screen('Screens'));%-1;
end

%===================Make a name for this run===================
cd(ana.ResultDir)
if ana.useStaircase; type = 'AISTAIR'; else type = 'AIMOC'; end %#ok<*UNRCH>
if ~isempty(ana.subject)
	nameExp = [type '_' ana.subject];
	c = sprintf(' %i',fix(clock()));
	nameExp = [nameExp c];
	ana.nameExp = regexprep(nameExp,' ','_');
else
	ana.nameExp = 'debug';
end

cla(ana.plotAxis1);
cla(ana.plotAxis2);
cla(ana.plotAxis3);

useEyeLink = ana.useEyelink;
nBlocks = ana.nBlocks;
nBlocksOverall = nBlocks * length(ana.pedestalRange);


% pedestalRange = 0.8:0.02:1.2;
nBlocksOverall = nBlocks * length(pedestalRange);
pedestalBlackLinear = pedestalRange;
pedestalWhiteLinear = pedestalRange;
pedestalBlack =  pedestalRange;
pedestalWhite = pedestalRange;  % by Xu20180515




%-------------------response values, linked to left, up, down
NOSEE = 1; 	YESRIGHT = 2; YESLEFT = 3; UNSURE = 4; BREAKFIX = -1;

%-----------------------Positions to move stimuli
XPos1 = [1.414 1.414 -1.414 -1.414];     
YPos1 = [1.414 -1.414 -1.414 1.414];     
XPos2 = [-1.414 -1.414 1.414 1.414];    
YPos2 = [1.414 -1.414 -1.414 1.414];

saveMetaData();

%======================================================stimulus objects
%---------------------main disc (stimulus and pedestal).
st1 = discStimulus();  % white stimulus
st1.name = ['STIM_' ana.nameExp];
st1.xPosition = XPos1(1);
st1.colour = [1 1 1 1];
st1.size = ana.discSize;
st1.sigma = ana.sigma;

st2 = discStimulus();   % black stimulus
st2.name = ['STIM_' ana.nameExp];
st2.xPosition = XPos2(1);
st2.colour = [0 0 0 1];
st2.size = ana.discSize;
st2.sigma = ana.sigma;

%-----mask stimulus
m = dotsStimulus();
m.mask = true;
m.density = 1000;
m.coherence = 0;
m.size = 10;
m.speed=0.5;
m.name = ['MASK_' ana.nameExp];
m.xPosition = st.xPosition;
m.size = st.size;

%----------combine them into a single meta stimulus------------------
%% --combine them into a single meta stimulus------------------
m1 =m; m1.xPosition = 0;
m2 =m; m2.xPosition = 0;

stimuli = metaStimulus();
stimuli.name = ana.nameExp;
stimuli.maskStimuli{1} = m1;
stimuli.maskStimuli{2} = m2;
stimuli{1} = st1;
stimuli{2} = st2;
stimuli.showMask = false;

%======================================================stimulus objects

%-----------------------open the PTB screens------------------------
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 0);
%===================open our screen====================
sM = screenManager();
sM.screen = ana.screenID;
sM.windowed = ana.windowed;
sM.pixelsPerCm = ana.pixelsPerCm;
sM.distance = ana.distance;
sM.debug = ana.debug;
sM.blend = true;
sM.bitDepth = 'FloatingPoint32Bit';
if exist(ana.gammaTable, 'file')
	load(ana.gammaTable);
	if isa(c,'calibrateLuminance')
		sM.gammaTable = c;
	end
	clear c;
	if ana.debug
		sM.gammaTable.plot
	end
end
sM.backgroundColour = ana.backgroundColor;
screenVals = sM.open; % OPEN THE SCREEN
fprintf('\n--->>> AIContrast Opened Screen %i : %s\n', sM.win, sM.fullName);
setup(stimuli,sM); %setup our stimulus object

%==============================setup eyelink==========================
if useEyeLink == true
	ana.strictFixation = true;
	eL = eyelinkManager('IP',[]);
	fprintf('--->>> eL setup starting: %s\n', eL.fullName);
	eL.isDummy = ana.isDummy; %use dummy or real eyelink?
	eL.name = ana.nameExp;
	eL.saveFile = [ana.nameExp '.edf'];
	eL.recordData = true; %save EDF file
	eL.sampleRate = ana.sampleRate;
	eL.remoteCalibration = false; % manual calibration?
	eL.calibrationStyle = ana.calibrationStyle; % calibration style
	eL.modify.calibrationtargetcolour = [1 1 1];
	eL.modify.calibrationtargetsize = 1;
	eL.modify.calibrationtargetwidth = 0.05;
	eL.modify.waitformodereadytime = 500;
	eL.modify.devicenumber = -1; % -1 = use any keyboard
	% X, Y, FixInitTime, FixTime, Radius, StrictFix
	updateFixationValues(eL, ana.fixX, ana.fixY, ana.firstFixInit,...
		ana.firstFixTime, ana.firstFixDiameter, ana.strictFixation);
	%sM.verbose = true; eL.verbose = true; sM.verbosityLevel = 10; eL.verbosityLevel = 4; %force lots of log output
	initialise(eL, sM); %use sM to pass screen values to eyelink
	setup(eL); % do setup and calibration
	fprintf('--->>> eL setup complete: %s\n', eL.fullName);
	WaitSecs('YieldSecs',0.5);
	getSample(eL); %make sure everything is in memory etc.
end


%---------------------------Set up task variables----------------------
task = stimulusSequence();
task.name = ana.nameExp;
task.nBlocks = nBlocksOverall;
task.nVar(1).name = 'colour';
task.nVar(1).stimulus = 1;
task.nVar(1).values = [0 1];
randomiseStimuli(task);
initialiseTask(task);

if ana.useStaircase == false
	staircaseB = []; staircaseW = [];
	taskW = stimulusSequence();
	taskW.name = ana.nameExp;
	taskW.nBlocks = nBlocks;
	taskW.nVar(1).name = 'pedestalWhite';
	taskW.nVar(1).stimulus = 1;
	taskW.nVar(1).values = pedestalWhite;
	randomiseStimuli(taskW);
	initialiseTask(taskW);
	
	taskB = stimulusSequence();
	taskB.name = ana.nameExp;
	taskB.nBlocks = nBlocks;
	taskB.nVar(1).name = 'pedestalBlack';
	taskB.nVar(1).stimulus = 1;
	taskB.nVar(1).values = pedestalBlack;
	randomiseStimuli(taskB);
	initialiseTask(taskB);
else
	taskB.thisRun = 0; taskW.thisRun = 0;
	stopRule = 40;
	usePriors = ana.usePriors;
	grain = 100;
	setupStairCase();
end

%=====================================================================
try %our main experimental try catch loop
%=====================================================================
		
	loop = 1;
	breakloop = false;
	fixated = 'no';
	response = NaN;
	responseRedo = 0; %number of trials the subject was unsure and redid (left arrow)

	while ~breakloop && task.thisRun <= task.nRuns
		%-----setup our values and print some info for the trial
		hide(stimuli);
		response = NaN;
		stimuli.showMask = false;
		stimuli{1}.colourOut = 1; stimuli{2}.colourOut = 0;
		colourOut = task.outValues{task.thisRun,1};
		if useStaircase == true
			if colourOut == 0
				pedestal = staircaseB.xCurrent*discSize;
				stimuli{1}.sizeOut = pedestal;
				stimuli{2}.sizeOut = discSize;
				if posloop == 1 || posloop == 3; posloop = 2; else posloop = 1; end
			else
				pedestal = discSize*staircaseW.xCurrent;
				 stimuli{1}.sizeOut = discSize;
				 stimuli{2}.sizeOut = pedestal;  
				if posloop == 1 || posloop == 3; posloop = 4; else posloop = 3; end
			end
		else
			if colourOut == 0
				pedestal = taskB.outValues{taskB.thisRun,1};
				stimuli{1}.sizeOut = pedestal;
				stimuli{2}.sizeOut = discSize;
				if posloop == 1 || posloop == 3; posloop = 2; else posloop = 1; end
            else
			    pedestal = taskW.outValues{taskW.thisRun,1};% Xu 20150515
				 stimuli{1}.sizeOut = discSize;
				 stimuli{2}.sizeOut = pedestal;  
				if posloop == 1 || posloop == 3; posloop = 4; else posloop = 3; end
			end
		end

		stimuli{1}.xPositionOut = XPos1(posloop);
		stimuli{1}.yPositionOut = YPos1(posloop);
		stimuli{2}.xPositionOut = XPos2(posloop);
		stimuli{2}.yPositionOut = YPos2(posloop);
		

		ts(1).x = XPos1(posloop);
		ts(1).y = YPos1(posloop);
		ts(1).size = stimuli{1}.sizeOut/sM.ppd;
		ts(1).selected = true;
		ts(2).x = XPos2(posloop);
		ts(2).y = YPos2(posloop);
		ts(2).size = stimuli{2}.sizeOut/sM.ppd;
		ts(2).selected = true;
		
		%save([tempdir filesep nameExp '.mat'],'task','taskB','taskW');
		fprintf('\n===>>>START %i: PEDESTAL = %.3g | Colour = %.3g | ',task.thisRun,pedestal,colourOut);
		

		stimuli.update();
		stimuli.maskStimuli{1}.update();
		
		%-----initialise eyelink and draw fix spot
		if useEyeLink
			resetFixation(eL);
			trackerClearScreen(eL);
			trackerDrawStimuli(eL,ts);
			trackerDrawFixation(eL); %draw fixation window on eyelink computer
			edfMessage(eL,'V_RT MESSAGE END_FIX END_RT'); ... %this 3 lines set the trial info for the eyelink
			edfMessage(eL,['TRIALID ' num2str(task.thisRun)]); ... %obj.getTaskIndex gives us which trial we're at
			edfMessage(eL,['MSG:PEDESTAL ' num2str(pedestal)]); ... %add in the pedestal of the current state for good measure
			edfMessage(eL,['MSG:CONTRAST ' num2str(colourOut)]); ... %add in the pedestal of the current state for good measure
			startRecording(eL);
			statusMessage(eL,'INITIATE FIXATION...');
			fixated = '';
			syncTime(eL);
			while ~strcmpi(fixated,'fix') && ~strcmpi(fixated,'breakfix')
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				tFix = Screen('Flip',sM.win); %flip the buffer
				getSample(eL);
				fixated=testSearchHoldFixation(eL,'fix','breakfix');
			end
			if strcmpi(fixated,'breakfix')
				fprintf(' BREAK INIT FIXATION');
				response = BREAKFIX;
			end
		else
			drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
			tFix = Screen('Flip',sM.win); %flip the buffer
			WaitSecs(0.5);
			fixated = 'fix';
		end
		
		%------Our main stimulus drawing loop
		finishLoop = false;
		while strcmpi(fixated,'fix') && finishLoop == false
			if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
		
			%=====================STIMULUS
			stimuli.show();
			tStim = GetSecs;  vbl = tStim;
			while vbl <= tStim + ana.stimulusTime
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
			if useEyeLink && ~strcmpi(fixated,'fix')
				response = BREAKFIX; finishLoop = true;
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix')
				break
			end
			
			%====================PEDESTAL
			stimuli{1}.colourOut = 0.5;stimuli{2}.colourOut = 0.5;
			tPedestal=GetSecs;
			while GetSecs <= tPedestal + pedestalTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
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
				response = BREAKFIX; finishLoop = true;
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix')
				break
			end
			
			%=====================MASK
			stimuli.showMask = true; %metaStimulus can trigger a mask
			tMask=GetSecs;
			while GetSecs <= tMask + ana.maskTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],fixX,fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				animate(stimuli); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			
			%=====================RESPONSE
			drawBackground(sM);
			Screen('DrawText',sM.win,['Which is bigger: [LEFT]=LEFT [RIGHT]=RIHGT [UP]=Same [DOWN]=unsure '],0,0);
			tMaskOff = Screen('Flip',sM.win);
			if useEyeLink
				statusMessage(eL,'Waiting for Subject Response!');
				edfMessage(eL,'Subject Responding')
				edfMessage(eL,'END_RT'); ...
			end
		    finishLoop = true;
		end
		
		%-----check keyboard
		if response ~= BREAKFIX
			ListenChar(2);
			[keyIsDown, ~, keyCode] = KbCheck(-1);
			rchar = KbName(keyCode);
			if iscell(rchar);rchar=rchar{1};end
			switch lower(rchar)
				case {'leftarrow','left'}
					response = YESLEFT;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject Pressed LEFT!');
						edfMessage(eL,'Subject Pressed LEFT')
					end
					doPlot();
				case {'uparrow','up'} %brighter than
					response = NOSEE;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject Pressed uparrow!');
						edfMessage(eL,'Subject Pressed uparrow')
					end
					doPlot();
				case {'downarrow','down'} %darker than
					response = UNSURE;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject Pressed UNSURE!');
						edfMessage(eL,'Subject Pressed UNSURE')
					end
					doPlot();
				case {'rightarrow','right'}
					response = YESRIGHT;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject RIGHT!');
						edfMessage(eL,'Subject RIGHT')
					end
					doPlot();
				case {'backspace','delete'}
					response = -10;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject UNDO!');
						edfMessage(eL,'Subject UNDO')
					end
					doPlot();
				case {'c'} %calibrate
					response = BREAKFIX;
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
					fprintf('\n!!!QUIT!!!\n');
					breakloop = true;
				otherwise
					response = UNSURE;
					updateResponse();
					if useEyeLink
						statusMessage(eL,'Subject UNSURE!');
						edfMessage(eL,'Subject UNSURE')
					end
			end

		end
		tEnd = GetSecs;
		ListenChar(0);
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
		response = task.response;
		responseInfo = task.responseInfo;
		save([ana.nameExp '.mat'], 'ana', 'response', 'responseInfo', 'task',...
			'taskB', 'taskW', 'staircaseB', 'staircaseW', 'sM',...
			'stimuli', 'eL');
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
	save([ana.nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW',...
		'staircaseB', 'staircaseW', 'ana', 'sM', 'stimuli', 'eL', 'ME')
	ple(ME)
	if useEyeLink == true; eL.saveFile = [ana.nameExp 'CRASH.edf']; close(eL); end
	reset(stimuli);
	clear stimuli task taskB taskW md eL s
	rethrow(ME);
end

	function updateResponse()
		tEnd = GetSecs;
		ListenChar(0);
		if response == NOSEE || response == YESRIGHT || response == YESLEFT %subject responded
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
					if response == NOSEE || response == YESLEFT
						yesnoresponse = 0;
					else
						yesnoresponse = 1;
					end
					staircaseB = PAL_AMPM_updatePM(staircaseB, yesnoresponse);
				elseif colourOut == 1
					if response == NOSEE || response == YESLEFT
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
		
		if isempty(task.response)
			return
		end
		
		x = 1:length(task.response);
		info = cell2mat(task.responseInfo);
		ped = [info.pedestal];
		
		idxW = [info.contrastOut] == 1;
		idxB = [info.contrastOut] == 0;
		
		idxNO = task.response == NOSEE;
		idxYESRIGHT = task.response == YESRIGHT;
		idxYESLEFT = task.response == YESLEFT;
		
		if useStaircase == true
			subplot(2,1,1)
		end
		
		cla; line([0 max(x)+1],[0.5 0.5],'LineStyle','--','LineWidth',2); hold on
		plot(x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(x(idxYESLEFT & idxB), ped(idxYESLEFT & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESLEFT & idxW), ped(idxYESLEFT & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESRIGHT & idxB), ped(idxYESRIGHT & idxB),'r^','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESRIGHT & idxW), ped(idxYESRIGHT & idxW),'b^','MarkerFaceColor','w','MarkerSize',8);
		
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
		box on; grid on; ylim([2 3]); xlim([0 max(x)+1]);
		xlabel('Trials (red=BLACK blue=WHITE)')
		ylabel('Pedestal Size')
		hold off
		if useStaircase == true
			subplot(2,1,2)
			cla; hold on;
			if ~isempty(staircaseB.threshold)
				rB = [min(staircaseB.stimRange):.003:max(staircaseW.stimRange)];
				outB = PF([staircaseB.threshold(end) ...
					staircaseB.slope(end) staircaseB.guess(end) ...
					staircaseB.lapse(end)], rB);
				plot(rB,outB,'r-');
				
				r = staircaseB.response;
				t = staircaseB.threshold;
				yes = r == 1;
				no = r == 1; 
				plot(t(yes), ones(1,sum(yes)),'ro','MarkerFaceColor','r','MarkerSize',8);
				plot(t(no), zeros(1,sum(no)),'ro','MarkerFaceColor','w','MarkerSize',8);
			end
			if ~isempty(staircaseW.threshold)
				rW = [min(staircaseB.stimRange):.003:max(staircaseW.stimRange)];
				outW = PF([staircaseW.threshold(end) ...
					staircaseW.slope(end) staircaseW.guess(end) ...
					staircaseW.lapse(end)], rW);
				plot(rW,outW,'b-');
				
				r = staircaseW.response;
				t = staircaseW.threshold;
				yes = r == 1;
				no = r == 1; 
				plot(t(yes), ones(1,sum(yes)),'bo','MarkerFaceColor','b','MarkerSize',8);
				plot(t(no), zeros(1,sum(no)),'bo','MarkerFaceColor','w','MarkerSize',8);
			end
			box on; grid on; ylim([0 1]); xlim([0.8 1.2]);
			xlabel('Size (red=BLACK blue=WHITE)');
			ylabel('Responses');
			hold off
		end
		drawnow;
	end

	function setupStairCase()
		priorAlphaB = linspace(min(pedestalBlack), max(pedestalBlack), grain);
		priorAlphaW = linspace(min(pedestalWhite), max(pedestalBlack), grain);
		priorBetaB = linspace(0, 8, 40); %our slope
		priorBetaW = linspace(0, 8, 40); %our slope
		priorGammaRange = 0.5;  %fixed value (using vector here would make it a free parameter)
		priorLambdaRange = 0.01; %ditto
		
		staircaseB = PAL_AMPM_setupPM('stimRange',pedestalBlack,'PF',PF,...
			'priorAlphaRange', priorAlphaB, 'priorBetaRange', priorBetaB,...
			'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
			'numTrials', stopRule,'marginalize','lapse');
		
		staircaseW = PAL_AMPM_setupPM('stimRange',pedestalWhite,'PF',PF,...
			'priorAlphaRange', priorAlphaW, 'priorBetaRange', priorBetaW,...
			'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
			'numTrials', stopRule,'marginalize','lapse');
		
		
			priorB = PAL_pdfNormal(staircaseB.priorAlphas,0.8,1.2).*PAL_pdfNormal(staircaseB.priorBetas,3,8);
			priorW = PAL_pdfNormal(staircaseW.priorAlphas,0.8,1.2).*PAL_pdfNormal(staircaseW.priorBetas,3,8);
			figure;
			subplot(1,2,1);imagesc(staircaseB.priorBetaRange,staircaseB.priorAlphaRange,priorB);axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors BLACK')
			subplot(1,2,2);imagesc(staircaseW.priorBetaRange,staircaseW.priorAlphaRange,priorW); axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors WHITE')
			if usePriors
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
% 		md.discSize = discSize;
		md.NOSEE = NOSEE;
		md.YESRIGHT = YESRIGHT;
		md.YESLEFT = YESLEFT;
		md.UNSURE = UNSURE;
		md.BREAKFIX = BREAKFIX;
		md.XPos = XPos1;
		md.yPos = YPos1;
		
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

