function masked2STILatency(ana)

%----------compatibility for windows
%if ispc; PsychJavaTrouble(); end
KbName('UnifyKeyNames');

%===================Initiate out metadata===================
ana.date = datestr(datetime);
ana.version = Screen('Version');
ana.computer = Screen('Computer');
discSize = ana.discSize;
%===================experiment parameters===================
if ana.debug
	ana.screenID = 0;
else
	ana.screenID = max(Screen('Screens'));%-1;
end

%===================Make a name for this run===================
cd(ana.ResultDir)
if ~isempty(ana.subject)
	if ana.useStaircase; type = 'AISTAIR'; else; type = 'AIMOC'; end %#ok<*UNRCH>
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
pedestalBlackLinear = ana.pedestalRange;
pedestalWhiteLinear = ana.pedestalRange;
pedestalBlack =  ana.pedestalRange;
pedestalWhite = ana.pedestalRange;  % by Xu20180515

%-------------------response values, linked to left, up, down
SAME = 3; 	 UNSURE = 4; BREAKFIX = -1; EARLY = 0; DELAY = 1;

%-----------------------Positionqs to move stimuli
XPos = [3 1.5 -1.5 -1.5 1.5 -3];
YPos = [0 2.598 2.598 -2.598 -2.598 0];        

saveMetaData();

%======================================================stimulus objects
%---------------------main disc (stimulus and pedestal).
st1 = discStimulus();  % white stimulus
st1.name = ['STIM_' ana.nameExp];
st1.xPosition = XPos(1);
st1.colour = [1 1 1 1];
st1.size = 3;
st1.sigma = ana.sigma;

st2 = discStimulus();   % black stimulus
st2.name = ['STIM_' ana.nameExp];
st2.xPosition = XPos(2);
st2.colour = [0 0 0 1];
st2.size = 3;
st2.sigma = ana.sigma;

%-----mask stimulus
m = dotsStimulus();
m.mask = true;
m.density = 1000;
m.coherence = 0;
m.size = 12;
m.speed=0.5;
m.name = ['MASK_' ana.nameExp];
m.xPosition = 0;
m.size = 8;

%----------combine them into a single meta stimulus------------------
%% --combine them into a single meta stimulus------------------
m1 =m; m1.xPosition = 0;
m2 =m; m2.xPosition = 0;

stimuli1 = metaStimulus();
stimuli1.name = ana.nameExp;
stimuli1.maskStimuli{1} = m1;
stimuli1{1} = st1;

stimuli2 = metaStimulus();
stimuli2.name = ana.nameExp;
stimuli2{1} = st2;
stimuli2.maskStimuli{1} = m2;

stimuli1.showMask = false;
stimuli2.showMask = false;

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
setup(stimuli1,sM); %setup our stimulus object
setup(stimuli2,sM); %setup our stimulus object
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
%     posloop = 1
	breakloop = false;
	fixated = 'no';
	response = NaN;
	responseRedo = 0; %number of trials the subject was unsure and redid (left arrow)

	while ~breakloop && task.thisRun <= task.nRuns
		%-----setup our values and print some info for the trial
		hide(stimuli1);hide(stimuli2);
		response = NaN;
		stimuli1.showMask = false;
		colourOut = task.outValues{task.thisRun,1};
		if ana.useStaircase == true
			if colourOut == 0
				pedestal = staircaseB.xCurrent-0.05;
			else
				pedestal = staircaseW.xCurrent-0.05;
			end
		else
			if colourOut == 0
				pedestal = taskB.outValues{taskB.thisRun,1}-0.05; %*discSize;
            else
			    pedestal = taskW.outValues{taskW.thisRun,1}-0.05; %*discSize;% Xu 20150515
			end
        end
        posloop = randperm(6);
		stimuli1{1}.xPositionOut = XPos(posloop(1));
		stimuli1{1}.yPositionOut = YPos(posloop(1));
		stimuli2{1}.xPositionOut = XPos(posloop(2));
		stimuli2{1}.yPositionOut = YPos(posloop(2));
					stimuli1{1}.colourOut = 1;stimuli2{1}.colourOut = 0;
		ts(1).x = XPos(posloop(1));
		ts(1).y = YPos(posloop(1));
		ts(1).size = stimuli1{1}.sizeOut/sM.ppd;
		ts(1).selected = true;
		ts(2).x = XPos(posloop(2));
		ts(2).y = YPos(posloop(2));
		ts(2).size = stimuli2{1}.sizeOut/sM.ppd;
		ts(2).selected = true;
		
		%save([tempdir filesep nameExp '.mat'],'task','taskB','taskW');
% 		fprintf('\n===>>>START %i: PEDESTAL = %.3g | Colour = %.3g | ',task.thisRun,pedestal,colourOut);
				
		stimuli1.update();
		stimuli1.maskStimuli{1}.update();
		stimuli2.update();
		stimuli2.maskStimuli{1}.update();
		
		
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
            stimuli1.show();
			stimuli2.show();
			tStim = GetSecs;
			vbl = tStim;
			while vbl <= tStim + abs(pedestal) % early
                if pedestal < 0; draw(stimuli1); else draw(stimuli2); end%draw stimulus		
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
				if pedestal < 0; animate(stimuli1); else animate(stimuli2); end%draw stimulus	animate(stimuli1); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			while vbl <= tStim + ana.stimulusTime
					
				draw(stimuli2); %draw stimulus
				draw(stimuli1);	
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
				animate(stimuli2);
				animate(stimuli1);
				
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end
			
			if useEyeLink && ~strcmpi(fixated,'fix')
				response = BREAKFIX; finishLoop = true;
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix')
				break
            end
            
            %% ====================PEDESTAL
			stimuli1{1}.colourOut = 0.5;stimuli2{1}.colourOut = 0.5;
			tPedestal=GetSecs;
			while GetSecs <= tPedestal + ana.pedestalTime
				draw(stimuli1); %draw stimulus
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
            
            %% =====================MASK
			stimuli1.showMask = true; %metaStimulus can trigger a mask
			tMask=GetSecs;
			while GetSecs <= tMask + ana.maskTime
				draw(stimuli1); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				animate(stimuli1); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
            end
            
			%% =====================RESPONSE
			drawBackground(sM);
			Screen('DrawText',sM.win,['Which is bigger: [LEFT], [RIGHT], [DOWN]=SAME or [UP] = UNSURE '],0,0);
			tMaskOff = Screen('Flip',sM.win);
			if useEyeLink
				statusMessage(eL,'Waiting for Subject Response!');
				edfMessage(eL,'Subject Responding')
				edfMessage(eL,'END_RT'); ...
			end
        finishLoop = true;
		end
		
		%% -----check keyboard
        if response ~= BREAKFIX
			ListenChar(2);
			[secs, keyCode] = KbWait(-1);
			rchar = KbName(keyCode);
				if iscell(rchar);rchar=rchar{1};end
				fprintf(' CHAR IS %s', rchar);
				switch lower(rchar)
					case {'leftarrow','left'}          
                            response = DELAY;
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed LEFT!');
							edfMessage(eL,'Subject Pressed LEFT')
						end
						doPlot();
					case {'uparrow','up'} %
						response = UNSURE; % unsure
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed uparrow!');
							edfMessage(eL,'Subject Pressed uparrow')
						end
						doPlot();
					case {'downarrow','down'} %
						response = SAME;  % same
						updateResponse();
						if useEyeLink
							trackerDrawText(eL,'Subject Pressed UNSURE!');
							edfMessage(eL,'Subject Pressed UNSURE')
						end
						doPlot();
					case {'rightarrow','right'}
                            response = EARLY;
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
	%% -----Cleanup
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
			'stimuli1', 'stimuli2','eL');
		disp(['=====SAVE, saved current data to: ' pwd]);
	else
		eL.saveFile = ''; %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
	reset(stimuli1); %reset our stimulus ready for use again
	reset(stimuli2);
catch ME
	close(sM); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	save([ana.nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW',...
		'staircaseB', 'staircaseW', 'ana', 'sM','stimuli1', 'stimuli2', 'eL', 'ME')
	ple(ME)
	if useEyeLink == true; eL.saveFile = [nameExp 'CRASH.edf']; close(eL); end
	reset(stimuli1);reset(stimuli2);
	clear stimuli1 stimuli2 task taskB taskW md eL s
	rethrow(ME);
end

	function updateResponse()
		tEnd = GetSecs;
		ListenChar(0);
		if response == SAME || response == EARLY || response == DELAY %subject responded
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
			if ana.useStaircase == true
				if colourOut == 0
					if  response == 0
						yesnoresponse = 0;
					else
						yesnoresponse = 1;
					end
					staircaseB = PAL_AMPM_updatePM(staircaseB, yesnoresponse);
				elseif colourOut == 1
					if  response == 0
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
		
		idxNO = task.response == SAME;
		idxYESEARLY = task.response == EARLY;
		idxYESDELAY = task.response == DELAY;
			
		cla(ana.plotAxis1);  line([0 max(x)+1],[3 3],'LineStyle','--','LineWidth',2); hold(ana.plotAxis1,'on')
		plot(ana.plotAxis1,x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(ana.plotAxis1,x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(ana.plotAxis1,x(idxYESDELAY & idxB), ped(idxYESDELAY & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1,x(idxYESDELAY & idxW), ped(idxYESDELAY & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1,x(idxYESEARLY & idxB), ped(idxYESEARLY & idxB),'r^','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1,x(idxYESEARLY & idxW), ped(idxYESEARLY & idxW),'b^','MarkerFaceColor','w','MarkerSize',8);
		
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
		ylim(ana.plotAxis1,[-0.05 0.05]);
		xlim(ana.plotAxis1,[0 max(x)+1]);
		xlabel(ana.plotAxis1,'Trials (red=LARGE blue=SMALL)')
		ylabel(ana.plotAxis1,'Delay Time (s)')
		hold(ana.plotAxis1,'off')
        
		if ana.useStaircase == true
            scaleM = 200;
            tit = ''; tit2 = '';
			cla(ana.plotAxis2); hold(ana.plotAxis2,'on');
			if ~isempty(staircaseB.threshold)
				rB = linspace(min(staircaseB.stimRange),max(staircaseW.stimRange),200);
				if ana.logSlope
					b = 10.^staircaseB.slope(end);
				else
					b = staircaseB.slope(end);
				end
				outB = ana.PF([staircaseB.threshold(end) ...
					b staircaseB.guess(end) ...
					staircaseB.lapse(end)], rB);
				plot(ana.plotAxis2,rB,outB,'r-','LineWidth',2);
				
				r = staircaseB.response;
				t = staircaseB.x(1:length(r));
				yes = r == 1;
				no = r == 0;
				plot(ana.plotAxis2,t(yes), ones(1,sum(yes)),'ro','MarkerFaceColor','r','MarkerSize',3);
				plot(ana.plotAxis2,t(no), zeros(1,sum(no)),'ro','MarkerFaceColor','w','MarkerSize',3);
				[SL, NP, OON] = PAL_PFML_GroupTrialsbyX(staircaseB.x(1:length(staircaseB.response)),...
					staircaseB.response,...
					ones(size(staircaseB.response)));
				for SR = 1:length(SL(OON~=0))
					scatter(ana.plotAxis2, SL(SR), NP(SR)/OON(SR), scaleM*sqrt(OON(SR)./sum(OON)), ...
						'MarkerFaceColor',[1 0.7 0.7],'MarkerEdgeColor','k','MarkerFaceAlpha',.7)
				end
				tit = sprintf('B\\alpha:%.2g \\pm %.2g | B\\beta:%.2g \\pm %.2g',...
					staircaseB.threshold(end),staircaseB.seThreshold(end),b,staircaseB.seSlope(end));
			end
			if ~isempty(staircaseW.threshold)
				rW = linspace(min(staircaseB.stimRange),max(staircaseW.stimRange),200);
				if ana.logSlope
					b = 10.^staircaseW.slope(end);
				else
					b = staircaseW.slope(end);
				end
				outW = ana.PF([staircaseW.threshold(end) ...
					b staircaseW.guess(end) ...
					staircaseW.lapse(end)], rW);
				plot(ana.plotAxis2,rW,outW,'b--','LineWidth',2);
				
				r = staircaseW.response;
				t = staircaseW.x(1:length(r));
				yes = r == 1;
				no = r == 0;
				plot(ana.plotAxis2,t(yes), ones(1,sum(yes)),'kd','MarkerFaceColor','b','MarkerSize',3);
				plot(ana.plotAxis2,t(no), zeros(1,sum(no)),'bd','MarkerFaceColor','w','MarkerSize',3);
				[SL, NP, OON] = PAL_PFML_GroupTrialsbyX(staircaseW.x(1:length(staircaseW.response)),...
					staircaseW.response,...
					ones(size(staircaseW.response)));
				for SR = 1:length(SL(OON~=0))
					scatter(ana.plotAxis2, SL(SR), NP(SR)/OON(SR), scaleM*sqrt(OON(SR)./sum(OON)), ...
						'MarkerFaceColor',[0.7 0.7 1],'MarkerEdgeColor','b','MarkerFaceAlpha',.7)
				end
				tit2 = sprintf(' | W\\alpha:%.2g \\pm %.2g | W\\beta:%.2g \\pm %.2g',...
					staircaseW.threshold(end),staircaseW.seThreshold(end),b,staircaseW.seSlope(end));
			end
				box(ana.plotAxis2, 'on'); grid(ana.plotAxis2, 'on');
				ylim(ana.plotAxis2, [0 1]);
				xlim(ana.plotAxis2, [0 0.1]);
				xlabel(ana.plotAxis2, 'TIME (red=LARGE blue=SMALL)');
				ylabel(ana.plotAxis2, 'Responses');
				hold(ana.plotAxis2, 'off');
				
				%=========================plot posteriors
				cla(ana.plotAxis3);
				pos = PAL_Scale0to1(staircaseB.pdf(:,:,1,1));
				if ana.logSlope
					x = 10.^staircaseB.priorBetaRange;
				else
					x = staircaseB.priorBetaRange;
				end
				imagesc(ana.plotAxis3, x, staircaseB.priorAlphaRange, pos);
				axis(ana.plotAxis3,'tight');
				xlabel(ana.plotAxis3, 'Beta \beta');
				ylabel(ana.plotAxis3, 'Alpha \alpha');
				title(ana.plotAxis3, 'Black Posterior');
				cla(ana.plotAxis4);
				pos = PAL_Scale0to1(staircaseW.pdf(:,:,1,1));
				if ana.logSlope
					x = 10.^staircaseW.priorBetaRange;
				else
					x = staircaseW.priorBetaRange;
				end
				imagesc(ana.plotAxis4, x, staircaseW.priorAlphaRange, pos);
				axis(ana.plotAxis4,'tight');
				xlabel(ana.plotAxis4, 'Beta \beta');
				ylabel(ana.plotAxis4, 'Alpha \alpha');
				title(ana.plotAxis4, 'White Posterior');
				
		end
		drawnow;
	end

	function setupStairCase()
		priorAlphaB = linspace(min(pedestalBlack), max(pedestalBlack),ana.alphaGrain);
		priorAlphaW = linspace(min(pedestalWhite), max(pedestalWhite),ana.alphaGrain);
		if ana.logSlope
			s = log10(0.01); e = log10(ana.betaMax);
		else
			s = 0.01; e = ana.betaMax;
		end
		priorBetaB = linspace(s, e, ana.betaGrain); %our slope
		priorBetaW = linspace(s, e, ana.betaGrain); %our slope
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
			if ana.logSlope
				bP = log10(ana.betaPrior);
				bSD = log10(ana.betaSD);
			else
				bP = ana.betaPrior;
				bSD = ana.betaSD;
			end
			priorB = PAL_pdfNormal(staircaseB.priorAlphas,ana.alphaPrior,ana.alphaSD).*PAL_pdfNormal(staircaseB.priorBetas,bP,bSD);
			priorW = PAL_pdfNormal(staircaseW.priorAlphas,ana.alphaPrior,ana.alphaSD).*PAL_pdfNormal(staircaseW.priorBetas,bP,bSD);
			figure;
			subplot(1,2,1);imagesc(staircaseB.priorBetaRange,staircaseB.priorAlphaRange,priorB);axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors BLACK')
			subplot(1,2,2);imagesc(staircaseW.priorBetaRange,staircaseW.priorAlphaRange,priorW); axis square
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors WHITE')
			staircaseB = PAL_AMPM_setupPM(staircaseB,'prior',priorB);
			staircaseW = PAL_AMPM_setupPM(staircaseW,'prior',priorW);
			drawnow;
		end
	end

	function saveMetaData()
		ana.values.nBlocksOverall = nBlocksOverall;
		ana.values.pedestalBlackLinear = pedestalBlackLinear;
		ana.values.pedestalWhiteLinear = pedestalWhiteLinear;
		ana.values.pedestalBlack = pedestalBlack;
		ana.values.pedestalWhite = pedestalWhite;
		ana.values.SAME = SAME;
		ana.values.EARLY = EARLY;
		ana.values.SAMLL = DELAY;
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

