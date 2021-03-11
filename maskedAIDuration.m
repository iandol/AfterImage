function maskedAIDuration(ana)

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

pedestalBlack = ana.pedestalRange;
pedestalBlackLinear = pedestalBlack;
pedestalWhite = ana.pedestalRange;
pedestalWhiteLinear = pedestalWhite;

%-------------------response values, linked to left, up, down
DISAPPEAR = 1; UNSURE = 2; BREAKFIX = -1;

%-----------------------Positions to move stimuli
XPos1 = [3 1.5 -1.5 -1.5 1.5 -3] * 3 / 3;
YPos1 = [0 2.598 2.598 -2.598 -2.598 0] * 3 / 3;
XPos =XPos1; YPos = YPos1;
saveMetaData();

%======================================================stimulus objects
%---------------------main disc (stimulus and pedestal).
st = discStimulus();
st.name = ['STIM_' ana.nameExp];
st.xPosition = XPos1(1);
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
m.size = st.size;

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
task.nVar(1).values = [0.5-ana.stimulusCon 0.5+ana.stimulusCon];
randomiseStimuli(task);
initialiseTask(task);

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

clc
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
		stimuli{1}.colourOut = colourOut;

        if colourOut == 0.5 - ana.stimulusCon
            pedestal = taskB.outValues{taskB.thisRun,1};
        else
            pedestal = taskW.outValues{taskW.thisRun,1};
        end
			
		stimuli{1}.sizeOut = pedestal;
		stimuli{1}.sigmaOut = ana.sigma;
		
% 		if pedestal <= 1;  XPos =  2/3*XPos1; YPos =  2/3*YPos1;   end 
%         if pedestal >= 4;  XPos =  4/3*XPos1; YPos =  4/3*YPos1;   end 
        
		if posloop > 6; posloop = 1; end
		stimuli{1}.xPositionOut = XPos(posloop);
		stimuli{1}.yPositionOut = YPos(posloop);
		stimuli.maskStimuli{1}.xPositionOut = XPos(posloop);
		stimuli.maskStimuli{1}.yPositionOut = YPos(posloop);
		ts.x = XPos(posloop);
		ts.y = YPos(posloop);
		ts.size = stimuli{1}.size;
		ts.selected = true;
		
		%save([tempdir filesep nameExp '.mat'],'task','taskB','taskW');
		fprintf('\n==>># %i: Pedestal = %.3g | Colour = %.3g | ',task.thisRun,pedestal,colourOut);
		
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
				drawCross(sM,0.4,[0 0 0 0],ana.fixX,ana.fixY);
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
			drawCross(sM,0.4,[0 0 0 0],ana.fixX,ana.fixY);%[0.5 0.5 0.5 0.5]
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
			tStim = GetSecs; vbl = tStim;
			while vbl <= tStim + ana.stimulusTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[0 0 0 0],ana.fixX,ana.fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				if useEyeLink
					getSample(eL); %drawEyePosition(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break
					end
				end
				animate(stimuli); %animate stimulus, will be seen on next draw
				vbl = Screen('Flip',sM.win, vbl + screenVals.halfisi); %flip the buffer
			end

			
            tPedestal = GetSecs;
            tMask = 0;
			if useEyeLink && ~strcmpi(fixated,'fix')
				response = BREAKFIX; finishLoop = true;
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix')
				break
			end
			
			
			%=====================RESPONSE
			drawBackground(sM);
			Screen('DrawText',sM.win,['When you see nothing, press: [DOWN]=DISAPPEAR [RIGHT]=SHOW AGAIN'],0,0);
			drawCross(sM,0.4,[0 0 0 0],ana.fixX,ana.fixY);
			Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
			
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
            tEnd = GetSecs;
			if iscell(rchar);rchar=rchar{1};end
			switch lower(rchar)
				case {'downarrow','down'} %darker than
					response = DISAPPEAR;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject Pressed RIGHT!');
						edfMessage(eL,'Subject Pressed RIGHT')
					end
					doPlot();
				case {'righttarrow','right'}
					response = UNSURE;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject UNSURE!');
						edfMessage(eL,'Subject UNSURE')
					end
% 					doPlot();
				case {'backspace','delete'}
					response = -10;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject UNDO!');
						edfMessage(eL,'Subject UNDO')
					end
% 					doPlot();
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
		if useEyeLink; eL.saveFile = ''; end %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
	reset(stimuli); %reset our stimulus ready for use again
	
catch ME
	ple(ME)
	close(sM); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	if ~useEyeLink; eL = []; end
	save([ana.nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW',...
		'ana', 'sM', 'stimuli', 'eL', 'ME')
	if useEyeLink == true; eL.saveFile = [ana.nameExp 'CRASH.edf']; close(eL); end
	reset(stimuli);
	clear stimuli task taskB taskW md eL s
	rethrow(ME);
end

	function updateResponse()
% 		tEnd = GetSecs;
		ListenChar(0);
		if response == DISAPPEAR  %subject responded
			responseInfo.response = response;
            responseInfo.duration = tEnd - tPedestal;
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
			ana.duration (1,task.thisRun-1 )= responseInfo.duration;
            if colourOut == 0.5 - ana.stimulusCon
                taskB.thisRun = taskB.thisRun + 1;
            else
                taskW.thisRun = taskW.thisRun + 1;
            end
			
		elseif response == -10
            if task.totalRuns > 1
                if task.responseInfo(end) == 0
                    taskB.rewindRun;
                else
                    taskW.rewindRun;
                end
                task.rewindRun
                fprintf('new trial  = %i\n', task.thisRun);
            end
		elseif response == UNSURE
			responseRedo = responseRedo + 1;
			fprintf('Subject is trying stimulus again, overall = %.2g %\n',responseRedo);
		end
	end

	function doPlot()
		ListenChar(0);
		
		
		info = cell2mat(task.responseInfo);
		ped = [info.pedestal];%responseInfo.pedestal;
		dura = ana.duration;
        for i = 1:length(dura);
		x(1,i) =  find(ana.pedestalRange == ped(1,i));
        end
        
		idxW = [info.contrastOut] ==  0.5 + ana.stimulusCon;
		idxB = [info.contrastOut] ==  0.5 - ana.stimulusCon;
        
        
        cla(ana.plotAxis1);      	
		
		plot(ana.plotAxis1, x(idxB), dura(idxB),'ro','MarkerFaceColor','r','MarkerSize',8); hold(ana.plotAxis1,'on')
		plot(ana.plotAxis1, x(idxW), dura(idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		

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
			priorB = PAL_pdfNormal(staircaseB.priorAlphas,ana.alphaPriorB,ana.alphaSD).*PAL_pdfNormal(staircaseB.priorBetas,bP,bSD);
			priorW = PAL_pdfNormal(staircaseW.priorAlphas,ana.alphaPriorW,ana.alphaSD).*PAL_pdfNormal(staircaseW.priorBetas,bP,bSD);
			staircaseB = PAL_AMPM_setupPM(staircaseB,'prior',priorB);
			staircaseW = PAL_AMPM_setupPM(staircaseW,'prior',priorW);
			figure;
			if ana.logSlope
				subplot(1,2,1);imagesc(10.^staircaseB.priorBetaRange,staircaseB.priorAlphaRange,staircaseB.prior);axis square
			else
				subplot(1,2,1);imagesc(staircaseB.priorBetaRange,staircaseB.priorAlphaRange,staircaseB.prior);axis square
			end
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors BLACK')
			if ana.logSlope
				subplot(1,2,2);imagesc(10.^staircaseW.priorBetaRange,staircaseW.priorAlphaRange,staircaseW.prior); axis square
			else
				subplot(1,2,2);imagesc(staircaseW.priorBetaRange,staircaseW.priorAlphaRange,staircaseW.prior); axis square
			end
			ylabel('Threshold');xlabel('Slope');title('Initial Bayesian Priors WHITE')
			drawnow;
		end
	end

	function saveMetaData()
		ana.values.nBlocksOverall = nBlocksOverall;
		ana.values.pedestalBlackLinear = pedestalBlackLinear;
		ana.values.pedestalWhiteLinear = pedestalWhiteLinear;
		ana.values.pedestalBlack = pedestalBlack;
		ana.values.pedestalWhite = pedestalWhite;
		ana.values.DISAPPEAR = DISAPPEAR;
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
% 			drawSpot(s,0.1,[1 1 0],ana.fixX,ana.fixY);
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

