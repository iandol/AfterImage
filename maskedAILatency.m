function maskedAILatency(ana)

%----------compatibility for windows
%if ispc; PsychJavaTrouble(); end
KbName('UnifyKeyNames');

%===================Initiate out metadata===================
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

% pedestalRange = 0:0.02:0.4;
if ana.useStaircase
	pedestalBlack = ana.pedestalRange;
	pedestalBlackLinear = pedestalBlack;
	pedestalWhite = ana.pedestalRange;
	pedestalWhiteLinear = pedestalWhite;
else
	pedestalBlack = fliplr(ana.pedestalRange);
	pedestalBlackLinear = pedestalBlack;
	pedestalWhite = ana.pedestalRange;
	pedestalWhiteLinear = pedestalWhite;
end

%-------------------response values, linked to left, up, down
NOSEE = 1; 	YESSEE = 2; UNSURE = 4; BREAKFIX = -1;

%-----------------------Positions to move stimuli
XPos = [3 1.5 -1.5 -1.5 1.5 -3] * 3 / 3;
YPos = [0 2.598 2.598 -2.598 -2.598 0] * 3 / 3;
if ana.discSize <= 1;  XPos =  2/3*XPos; YPos =  2/3*YPos;   end
if ana.discSize >= 4;  XPos =  4/3*XPos; YPos =  4/3*YPos;   end

saveMetaData();

%======================================================stimulus objects
%---------------------main disc (stimulus and pedestal).
st = discStimulus();
st.name = ['STIM_' ana.nameExp];
st.xPosition = XPos(1);
st.colour = [1 1 1 1];
st.size = ana.discSize;
st.sigma = ana.sigma;

%-----mask stimulus
m = dotsStimulus();
m.mask = true;
m.density = 1000;
m.coherence = 0;
m.size = st.size+1;
m.speed=0.5;
m.name = ['MASK_' ana.nameExp];
m.xPosition = st.xPosition;
m.size = st.size+1;
%----------combine them into a single meta stimulus------------------
stimuli = metaStimulus();
stimuli.name = ana.nameExp;

sidx = 1;
maskidx = 1;
stimuli{sidx} = st;
stimuli.maskStimuli{maskidx} = m;
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
	posloop = 1;
	breakloop = false;
	fixated = 'no';
	response = NaN;
	responseRedo = 0; %number of trials the subject was unsure and redid (left arrow)
	
	while ~breakloop && task.thisRun <= task.nRuns
		%-----setup our values and print some info for the trial
		hide(stimuli);
		response = NaN;
		stimuli.showMask = false;
		colourOut = task.outValues{task.thisRun,1};
		if ana.useStaircase == true
			if colourOut == 0
				pedestal = staircaseB.xCurrent; % latency of mask
			else
				pedestal = staircaseW.xCurrent;
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
		stimuli{1}.colourOut = colourOut;  % addd by xu
		
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
		while strcmp(fixated, 'fix') && finishLoop == false
			if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
			
			%=====================STIMULUS
			stimuli.show();
			tStim = GetSecs;  vbl = tStim;
			while vbl <= tStim + ana.stimulusTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
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
			stimuli{1}.colourOut = 0.5;
			tPedestal=GetSecs;
			while GetSecs <= tPedestal + pedestal
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
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				animate(stimuli); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			
			%=====================RESPONSE
			drawBackground(sM);
			Screen('DrawText',sM.win,['See anything: [LEFT]=YES  [RIGHT]=NO  [DOWN]=UNSURE'],0,0);
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
			[secs, keyCode] = KbWait(-1);
			rchar = KbName(keyCode);
% 		while ~breakloopkey			
% 			if keyIsDown == 1
				if iscell(rchar);rchar=rchar{1};end
				switch lower(rchar)
					case {'leftarrow','left'}
						response = YESSEE;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed LEFT!');
							edfMessage(eL,'Subject Pressed LEFT')
						end
						doPlot();
					case {'downarrow','down'} %darker than
						response = UNSURE;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed RIGHT!');
							edfMessage(eL,'Subject Pressed RIGHT')
						end
						doPlot();
					case {'rightarrow','right'}
						response = NOSEE;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject UNSURE!');
							edfMessage(eL,'Subject UNSURE')
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
		if useEyeLink
			resetFixation(eL); trackerClearScreen(eL);
			stopRecording(eL);
			edfMessage(eL,['TRIAL_RESULT ' num2str(response)]);
			setOffline(eL);
		end
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
		if ~useEyeLink; eL = []; end
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
	if ~useEyeLink; eL = []; end
	save([ana.nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW',...
		'staircaseB', 'staircaseW', 'ana', 'sM', 'stimuli', 'eL', 'ME')
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
			task.thisRun = taskB.thisRun+taskW.thisRun;
			if ana.useStaircase == true
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
				fprintf('subject response: %i | ', yesnoresponse)
			else
				if colourOut == 0
					taskB.thisRun = taskB.thisRun + 1;
				else
					taskW.thisRun = taskW.thisRun + 1;
				end
			end
		elseif response == -10
			if task.totalRuns > 1
				if ana.useStaircase == true
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
				
		x = 1:length(task.response);
		info = cell2mat(task.responseInfo);
		ped = [info.pedestal];
		
		idxW = [info.contrastOut] == 1;
		idxB = [info.contrastOut] == 0;
		
		idxNO = task.response == NOSEE;
		idxYESSEE = task.response == YESSEE;

		cla(ana.plotAxis1); line(ana.plotAxis1,[0 max(x)+1],[0.5 0.5],'LineStyle','--','LineWidth',2); hold(ana.plotAxis1,'on')
		plot(ana.plotAxis1,x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(ana.plotAxis1,x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(ana.plotAxis1,x(idxYESSEE & idxB), ped(idxYESSEE & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1,x(idxYESSEE & idxW), ped(idxYESSEE & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);

		
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
				title(ana.plotAxis1, t);
			end
		else
			t = sprintf('TRIAL:%i', task.thisRun);
			title(ana.plotAxis1, t);
		end
		box(ana.plotAxis1,'on'); grid(ana.plotAxis1,'on');
		ylim(ana.plotAxis1,[0 0.6]);
		xlim(ana.plotAxis1,[0 max(x)+1]);
		xlabel(ana.plotAxis1,'Trials (red=BLACK blue=WHITE)')
		ylabel(ana.plotAxis1,'Mask latency (s)')
		hold(ana.plotAxis1,'off')
		
		if ana.useStaircase == true
			cla(ana.plotAxis2); hold(ana.plotAxis2,'on');
			if ~isempty(staircaseB.threshold)
				rB = [min(staircaseB.stimRange):.003:max(staircaseW.stimRange)];
				outB = ana.PF([staircaseB.threshold(end) ...
					staircaseB.slope(end) staircaseB.guess(end) ...
					staircaseB.lapse(end)], rB);
				plot(ana.plotAxis2,rB,outB,'r-','LineWidth',2);
				
				r = staircaseB.response;
				t = staircaseB.x(1:length(r));
				yes = r == 1;
				no = r == 0; 
				plot(ana.plotAxis2,t(yes), ones(1,sum(yes)),'ko','MarkerFaceColor','r','MarkerSize',10);
				plot(ana.plotAxis2,t(no), zeros(1,sum(no))+ana.gamma,'ro','MarkerFaceColor','w','MarkerSize',10);
			end
			if ~isempty(staircaseW.threshold)
				rW = [min(staircaseB.stimRange):.003:max(staircaseW.stimRange)];
				outW = ana.PF([staircaseW.threshold(end) ...
					staircaseW.slope(end) staircaseW.guess(end) ...
					staircaseW.lapse(end)], rW);
				plot(ana.plotAxis2,rW,outW,'b--','LineWidth',2);
				
				r = staircaseW.response;
				t = staircaseW.x(1:length(r));
				yes = r == 1;
				no = r == 0;
				plot(ana.plotAxis2,t(yes), ones(1,sum(yes)),'kd','MarkerFaceColor','b','MarkerSize',8);
				plot(ana.plotAxis2,t(no), zeros(1,sum(no))+ana.gamma,'bd','MarkerFaceColor','w','MarkerSize',8);
				end

				box(ana.plotAxis2, 'on'); grid(ana.plotAxis2, 'on');
				ylim(ana.plotAxis2, [ana.gamma 1]);
				xlim(ana.plotAxis2, [0 0.6]);
				xlabel(ana.plotAxis2, 'Mask latency (s) (red=BLACK blue=WHITE)');
				ylabel(ana.plotAxis2, 'Responses');
				hold(ana.plotAxis2, 'off');
			
		end
		drawnow;
	end

function setupStairCase()
		priorAlphaB = linspace(min(pedestalBlack), max(pedestalBlack),grain);
		priorAlphaW = linspace(min(pedestalWhite), max(pedestalWhite),grain);
		priorBetaB = linspace(0, ana.betaMax, 40); %our slope
		priorBetaW = linspace(0, ana.betaMax, 40); %our slope
		priorGammaRange = ana.gamma;  %fixed value (using vector here would make it a free parameter)
		priorLambdaRange = ana.lambda; %ditto
		
		staircaseB = PAL_AMPM_setupPM('stimRange',pedestalBlack,'PF',ana.PF,...
			'priorAlphaRange', priorAlphaB, 'priorBetaRange', priorBetaB,...
			'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
			'numTrials', stopRule,'marginalize',ana.marginalize);
		
		staircaseW = PAL_AMPM_setupPM('stimRange',pedestalWhite,'PF',ana.PF,...
			'priorAlphaRange', priorAlphaW, 'priorBetaRange', priorBetaW,...
			'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
			'numTrials', stopRule,'marginalize',ana.marginalize);
		
		if usePriors
			priorB = PAL_pdfNormal(staircaseB.priorAlphas,ana.alphaPrior,ana.alphaSD).*PAL_pdfNormal(staircaseB.priorBetas,ana.betaPrior,ana.betaSD);
			priorW = PAL_pdfNormal(staircaseW.priorAlphas,ana.alphaPrior,ana.alphaSD).*PAL_pdfNormal(staircaseW.priorBetas,ana.betaPrior,ana.betaSD);
			figure;
			subplot(1,2,1);imagesc(staircaseB.priorBetaRange,staircaseB.priorAlphaRange,priorB);axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors BLACK')
			subplot(1,2,2);imagesc(staircaseW.priorBetaRange,staircaseW.priorAlphaRange,priorW); axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors WHITE')
			staircaseB = PAL_AMPM_setupPM(staircaseB,'prior',priorB);
			staircaseW = PAL_AMPM_setupPM(staircaseW,'prior',priorW);
		end
	end

	function saveMetaData()
		ana.values.nBlocksOverall = nBlocksOverall;
		ana.values.pedestalBlackLinear = pedestalBlackLinear;
		ana.values.pedestalWhiteLinear = pedestalWhiteLinear;
		ana.values.pedestalBlack = pedestalBlack;
		ana.values.pedestalWhite = pedestalWhite;
		ana.values.NOSEE = NOSEE;
	    ana.values.YESSEE = YESSEE;
		ana.values.UNSURE = UNSURE;
		ana.values.BREAKFIX = BREAKFIX;
		ana.values.XPos = XPos;
		ana.values.yPos = YPos;
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

