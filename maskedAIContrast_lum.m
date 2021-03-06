function maskedAIContrast(ana)

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

if ana.useStaircase
	pedestalBlack = ana.pedestalRange;
	pedestalBlackLinear = pedestalBlack;
	pedestalWhite = ana.pedestalRange;
	pedestalWhiteLinear = pedestalWhite;
else
	pedestalBlack = 0.5 - fliplr(ana.pedestalRange);
	pedestalBlackLinear = pedestalBlack;
	pedestalWhite = 0.5 + ana.pedestalRange;
	pedestalWhiteLinear = pedestalWhite;
end

%-------------------response values, linked to left, up, down
NOSEE = 1; 	YESBRIGHT = 2; YESDARK = 3; UNSURE = 4; BREAKFIX = -1;

%-----------------------Positions to move stimuli
XPos = [3 1.5 -1.5 -1.5 1.5 -3] * 4 / 3;
YPos = [0 2.598 2.598 -2.598 -2.598 0] * 4 / 3;

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
		stimuli{1}.colourOut = colourOut;
		if ana.useStaircase == true
			if colourOut == 0
				pedestal = staircaseB.xCurrent;
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
			drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);try
    n = 1;
while n <= trials
	if exitLoop; break; end  
    
	%%%%%%% initialise eyelink and draw fix spot %%%%%%%
    if useEyeLink
        resetFixation(eL);
        trackerClearScreen(eL);
%         trackerDrawStimuli(eL,ts);
        trackerDrawFixation(eL); %draw fixation window on eyelink computer
        edfMessage(eL,'V_RT MESSAGE END_FIX END_RT'); ... %this 3 lines set the trial info for the eyelink
        edfMessage(eL,['TRIALID ' num2str(n)]); ... %obj.getTaskIndex gives us which trial we're at
       
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
%         WaitSecs(0.5);
        fixated = 'fix';
    end
     %%%%%%% draw circle to show the location of stimulus %%%%%%%  
      
     Screen('FrameOval', win, 1, [maskDstRectsRand(1, n)+(masktexrect(3)-maskRadiusPix*2)/2-circelSizeWeight1, maskDstRectsRand(2, n)+(masktexrect(4)-maskRadiusPix*2)/2-circelSizeWeight1, ...
         maskDstRectsRand(3, n)-(masktexrect(3)-maskRadiusPix*2)/2+circelSizeWeight1, maskDstRectsRand(4, n)-(masktexrect(4)-maskRadiusPix*2)/2+circelSizeWeight1]);
     sM.drawCross();
     sM.flip();
     WaitSecs('YieldSecs', 0.5);

     Screen('FillRect', win, 0.5);
     sM.drawCross();
     sM.flip;
     WaitSecs('YieldSecs', 0.5);

     fprintf('TRIAL:%i: staircase value = %.2f\n', n, staircase.xCurrent);

     %%%%%%% draw fixed phase %%%%%%%
     finishLoop = false;
     while strcmp(fixated, 'fix') && finishLoop == false
         if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
        
         currentTime = GetSecs;
         nextTime = currentTime + ana.part1_duration;
         vbl = currentTime;
         while vbl < nextTime
             Screen('DrawTextures', win, dotstex, [], dotDstRects, [], [], 1, dotColorMatrix, [], [], mydots);
             if ana.foregroundMask
                 Screen('DrawTextures', win, masktex, [], maskDstRectsRand(:, n), [], [], 1, [0.5, 0.5, 0.5, 1]', [], [], mymask);
             end
             sM.drawCross();
             
             [x1, y1] = RectCenterd(dotDstRects);
             index_kill1 = find(((x1+initialSpeed(1)*cosd(initialDirection))-w)>0);
             x1 = mod(x1+initialSpeed(1)*cosd(initialDirection), w);
             y1 = mod(y1-initialSpeed(1)*sind(initialDirection), h);
             y1(index_kill1) = h*rand(1,length(index_kill1)); %rand y of out_dots
             dotDstRects = CenterRectOnPointd(inrect, x1, y1);
             if useEyeLink
                getSample(eL); %drawEyePosition(eL);
                isfix = isFixated(eL);
                if ~isfix
                    fixated = 'breakfix';
                    break
                end
            end
             
             vbl = Screen('Flip', win, vbl + halfisi);
             
         end
         if useEyeLink && ~strcmpi(fixated,'fix')
            response = BREAKFIX; finishLoop = true;
            statusMessage(eL,'Subject Broke Fixation!');
            edfMessage(eL,'MSG:BreakFix')
            break
        end
         %%%%%%% draw test phase %%%%%%%
         dotSpeedPerFrame = ((dotSpeedWeight*staircase.xCurrent)+dotSpeedMean)*pixelPerDeg*ifi; % pixel/frame
         %mae_dir(n)= ana.dotDirection(dotDirectionMatrix(n));
         
         %=== Negative is left == 1 | Positive is right == 2
         MAEDirection(n) = (dotSpeedPerFrame >= 0) + 1;
         MAESpeed(n) = dotSpeedPerFrame/(pixelPerDeg*ifi);
         fprintf('==Dot Speed is %.3f (%.3f), direction is %.2f\n',dotSpeedPerFrame,MAESpeed(n),MAEDirection(n));
         
         currentTime = GetSecs;
         nextTime = currentTime + ana.stimulusDuration;
         vbl = currentTime;
         while vbl < nextTime
             
             Screen('DrawTextures', win, dotstex, [], dotDstRects, [], [], 1, dotColorMatrix, [], [], mydots);
             if ana.foregroundMask
                 Screen('DrawTextures', win, masktex, [], maskDstRectsRand(:, n), [], [], 1, [0.5, 0.5, 0.5, 1]', [], [], mymask);
             end
             sM.drawCross();
             
             [x, y] = RectCenterd(dotDstRects);
             index_kill2 = find((x+dotSpeedPerFrame*cosd(0)-w)>0);
             x = mod(x+dotSpeedPerFrame*cosd(0),w);
             y = mod(y-dotSpeedPerFrame*sind(0),h);
             y(index_kill2) = h*rand(1,length(index_kill2)); %rand y of out_dots
             dotDstRects = CenterRectOnPointd(inrect, x, y);
             
            if useEyeLink
                getSample(eL); %drawEyePosition(eL);
                isfix = isFixated(eL);
                if ~isfix
                    fixated = 'breakfix';
                    break
                endtry
    n = 1;
while n <= trials
	if exitLoop; break; end  
    
	%%%%%%% initialise eyelink and draw fix spot %%%%%%%
    if useEyeLink
        resetFixation(eL);
        trackerClearScreen(eL);
%         trackerDrawStimuli(eL,ts);
        trackerDrawFixation(eL); %draw fixation window on eyelink computer
        edfMessage(eL,'V_RT MESSAGE END_FIX END_RT'); ... %this 3 lines set the trial info for the eyelink
        edfMessage(eL,['TRIALID ' num2str(n)]); ... %obj.getTaskIndex gives us which trial we're at
       
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
%         WaitSecs(0.5);
        fixated = 'fix';
    end
     %%%%%%% draw circle to show the location of stimulus %%%%%%%  
      
     Screen('FrameOval', win, 1, [maskDstRectsRand(1, n)+(masktexrect(3)-maskRadiusPix*2)/2-circelSizeWeight1, maskDstRectsRand(2, n)+(masktexrect(4)-maskRadiusPix*2)/2-circelSizeWeight1, ...
         maskDstRectsRand(3, n)-(masktexrect(3)-maskRadiusPix*2)/2+circelSizeWeight1, maskDstRectsRand(4, n)-(masktexrect(4)-maskRadiusPix*2)/2+circelSizeWeight1]);
     sM.drawCross();
     sM.flip();
     WaitSecs('YieldSecs', 0.5);

     Screen('FillRect', win, 0.5);
     sM.drawCross();
     sM.flip;
     WaitSecs('YieldSecs', 0.5);

     fprintf('TRIAL:%i: staircase value = %.2f\n', n, staircase.xCurrent);

     %%%%%%% draw fixed phase %%%%%%%
     finishLoop = false;
     while strcmp(fixated, 'fix') && finishLoop == false
         if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
        
         currentTime = GetSecs;
         nextTime = currentTime + ana.part1_duration;
         vbl = currentTime;
         while vbl < nextTime
             Screen('DrawTextures', win, dotstex, [], dotDstRects, [], [], 1, dotColorMatrix, [], [], mydots);
             if ana.foregroundMask
                 Screen('DrawTextures', win, masktex, [], maskDstRectsRand(:, n), [], [], 1, [0.5, 0.5, 0.5, 1]', [], [], mymask);
             end
             sM.drawCross();
             
             [x1, y1] = RectCenterd(dotDstRects);
             index_kill1 = find(((x1+initialSpeed(1)*cosd(initialDirection))-w)>0);
             x1 = mod(x1+initialSpeed(1)*cosd(initialDirection), w);
             y1 = mod(y1-initialSpeed(1)*sind(initialDirection), h);
             y1(index_kill1) = h*rand(1,length(index_kill1)); %rand y of out_dots
             dotDstRects = CenterRectOnPointd(inrect, x1, y1);
             if useEyeLink
                getSample(eL); %drawEyePosition(eL);
                isfix = isFixated(eL);
                if ~isfix
                    fixated = 'breakfix';
                    break
                end
            end
             
             vbl = Screen('Flip', win, vbl + halfisi);
             
         end
         if useEyeLink && ~strcmpi(fixated,'fix')
            response = BREAKFIX; finishLoop = true;
            statusMessage(eL,'Subject Broke Fixation!');
            edfMessage(eL,'MSG:BreakFix')
            break
        end
         %%%%%%% draw test phase %%%%%%%
         dotSpeedPerFrame = ((dotSpeedWeight*staircase.xCurrent)+dotSpeedMean)*pixelPerDeg*ifi; % pixel/frame
         %mae_dir(n)= ana.dotDirection(dotDirectionMatrix(n));
         
         %=== Negative is left == 1 | Positive is right == 2
         MAEDirection(n) = (dotSpeedPerFrame >= 0) + 1;
         MAESpeed(n) = dotSpeedPerFrame/(pixelPerDeg*ifi);
         fprintf('==Dot Speed is %.3f (%.3f), direction is %.2f\n',dotSpeedPerFrame,MAESpeed(n),MAEDirection(n));
         
         currentTime = GetSecs;
         nextTime = currentTime + ana.stimulusDuration;
         vbl = currentTime;
         while vbl < nextTime
             
             Screen('DrawTextures', win, dotstex, [], dotDstRects, [], [], 1, dotColorMatrix, [], [], mydots);
             if ana.foregroundMask
                 Screen('DrawTextures', win, masktex, [], maskDstRectsRand(:, n), [], [], 1, [0.5, 0.5, 0.5, 1]', [], [], mymask);
             end
             sM.drawCross();
             
             [x, y] = RectCenterd(dotDstRects);
             index_kill2 = find((x+dotSpeedPerFrame*cosd(0)-w)>0);
             x = mod(x+dotSpeedPerFrame*cosd(0),w);
             y = mod(y-dotSpeedPerFrame*sind(0),h);
             y(index_kill2) = h*rand(1,length(index_kill2)); %rand y of out_dots
             dotDstRects = CenterRectOnPointd(inrect, x, y);
             
            if useEyeLink
                getSample(eL); %drawEyePosition(eL);
                isfix = isFixated(eL);
                if ~isfix
                    fixated = 'breakfix';
                    break
                end
            end
             vbl = Screen('Flip', win, vbl + halfisi);
             
         end
        if useEyeLink && ~strcmpi(fixated,'fix')
            response = BREAKFIX; finishLoop = true;
            statusMessage(eL,'Subject Broke Fixation!');
            edfMessage(eL,'MSG:BreakFix')
            break
        end
    
	%%%%%%%%% GET Result %%%%%%%%%%%
        Screen('FillRect', win, 0.5);
        sM.drawCross();
        sM.flip();
        WaitSecs('YieldSecs',0.5);
        if ana.dotDirection(dotDirectionMatrix(n)) == 0 || ana.dotDirection(dotDirectionMatrix(n)) == 180
            imageTexture = imread('choice_plane_LR.jpg');
        elseif ana.dotDirection(dotDirectionMatrix(n)) == 90 || ana.dotDirection(dotDirectionMatrix(n)) == 270
            imageTexture = imread('choice_plane_UD.jpg');
        end
        imageID = Screen('MakeTexture', win, imageTexture);
        Screen('DrawTexture', win, imageID, [], sM.winRect);
        Screen('Flip', win);
        
        if useEyeLink
            statusMessage(eL,'Waiting for Subject Response!');
            edfMessage(eL,'Subject Responding')
            edfMessage(eL,'END_RT'); ...
        end
        finishLoop = true;
     end
    if response ~= BREAKFIX
        [~, keyCode, ~] = KbWait;
        if keyCode(leftKey) == 1
            Response(n) = 1;
        elseif keyCode(rightKey) == 1
            Response(n) = 2;
        elseif keyCode(upKey) == 1
            Response(n) = 1;
        elseif keyCode(downKey) == 1
            Response(n) = 2;
        elseif keyCode(escKey) == 1
            exitLoop = true;
            break
        end
    end
	Screen('FillRect', win, 0.5);
	sM.flip();
	WaitSecs('YieldSecs', ana.ITI);

% 	thisResponse = Response(n) == MAEDirection(n);
	thisResponse = Response(n) == 2;
	
	fprintf('====Subject response %i, means this trial response was: %i\n\n',Response(n), thisResponse);

	staircase = PAL_AMPM_updatePM(staircase, thisResponse);

	plotResults();
    if useEyeLink
        resetFixation(eL); trackerClearScreen(eL);
        stopRecording(eL);
        edfMessage(eL,['TRIAL_RESULT ' num2str(Response(n))]);
        setOffline(eL);
    end
%     drawBackground(sM);
%     Screen('Flip',sM.win); %flip the buffer
%     WaitSecs(0.5);
 if response ~= BREAKFIX;n = n + 1;end  %
    
   response = 1;
end

%-----Cleanup
	Screen('Flip',sM.win);
	Priority(0); ListenChar(0); ShowCursor;
	close(sM); %close screen
	p=uigetdir(pwd,'Select Directory to Save Data, CANCEL to not save.');
	if ischar(p)
		cd(p);
		
		if ~useEyeLink; eL = []; end
		save([ana.nameExp '.mat'], 'ana', 'Response','staircase', 'sM','eL','MAEDirection','MAESpeed');
		disp(['=====SAVE, saved current data to: ' pwd]);
	else
		if useEyeLink; eL.saveFile = ''; end %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
% 	reset(stimuli); %reset our stimulus ready for use again


% if ~exitLoop
% 	fileName = strcat('MAE_tasks', datestr(now, 'yyyy-mm-dd-HH-MM-SS'), '.mat');
% 	save(fileName, 'Response', 'ana', 'staircase','MAEDirection','MAESpeed');
% end

% sM.close();
% sca;
% Screen('CloseAll');
catch ME
	ple(ME)
	close(sM); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	save([ana.nameExp 'CRASH.mat'], 'ana', 'Response','staircase', 'sM','eL','MAEDirection','MAESpeed')
	if useEyeLink == true; eL.saveFile = [ana.nameExp 'CRASH.edf']; close(eL); end
% 	reset(stimuli);
% 	clear stimuli task taskB taskW md eL s
    clear eL s
	rethrow(ME);
end
            end
             vbl = Screen('Flip', win, vbl + halfisi);
             
         end
        if useEyeLink && ~strcmpi(fixated,'fix')
            response = BREAKFIX; finishLoop = true;
            statusMessage(eL,'Subject Broke Fixation!');
            edfMessage(eL,'MSG:BreakFix')
            break
        end
    
	%%%%%%%%% GET Result %%%%%%%%%%%
        Screen('FillRect', win, 0.5);
        sM.drawCross();
        sM.flip();
        WaitSecs('YieldSecs',0.5);
        if ana.dotDirection(dotDirectionMatrix(n)) == 0 || ana.dotDirection(dotDirectionMatrix(n)) == 180
            imageTexture = imread('choice_plane_LR.jpg');
        elseif ana.dotDirection(dotDirectionMatrix(n)) == 90 || ana.dotDirection(dotDirectionMatrix(n)) == 270
            imageTexture = imread('choice_plane_UD.jpg');
        end
        imageID = Screen('MakeTexture', win, imageTexture);
        Screen('DrawTexture', win, imageID, [], sM.winRect);
        Screen('Flip', win);
        
        if useEyeLink
            statusMessage(eL,'Waiting for Subject Response!');
            edfMessage(eL,'Subject Responding')
            edfMessage(eL,'END_RT'); ...
        end
        finishLoop = true;
     end
    if response ~= BREAKFIX
        [~, keyCode, ~] = KbWait;
        if keyCode(leftKey) == 1
            Response(n) = 1;
        elseif keyCode(rightKey) == 1
            Response(n) = 2;
        elseif keyCode(upKey) == 1
            Response(n) = 1;
        elseif keyCode(downKey) == 1
            Response(n) = 2;
        elseif keyCode(escKey) == 1
            exitLoop = true;
            break
        end
    end
	Screen('FillRect', win, 0.5);
	sM.flip();
	WaitSecs('YieldSecs', ana.ITI);

% 	thisResponse = Response(n) == MAEDirection(n);
	thisResponse = Response(n) == 2;
	
	fprintf('====Subject response %i, means this trial response was: %i\n\n',Response(n), thisResponse);

	staircase = PAL_AMPM_updatePM(staircase, thisResponse);

	plotResults();
    if useEyeLink
        resetFixation(eL); trackerClearScreen(eL);
        stopRecording(eL);
        edfMessage(eL,['TRIAL_RESULT ' num2str(Response(n))]);
        setOffline(eL);
    end
%     drawBackground(sM);
%     Screen('Flip',sM.win); %flip the buffer
%     WaitSecs(0.5);
 if response ~= BREAKFIX;n = n + 1;end  %
    
   response = 1;
end

%-----Cleanup
	Screen('Flip',sM.win);
	Priority(0); ListenChar(0); ShowCursor;
	close(sM); %close screen
	p=uigetdir(pwd,'Select Directory to Save Data, CANCEL to not save.');
	if ischar(p)
		cd(p);
		
		if ~useEyeLink; eL = []; end
		save([ana.nameExp '.mat'], 'ana', 'Response','staircase', 'sM','eL','MAEDirection','MAESpeed');
		disp(['=====SAVE, saved current data to: ' pwd]);
	else
		if useEyeLink; eL.saveFile = ''; end %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
% 	reset(stimuli); %reset our stimulus ready for use again


% if ~exitLoop
% 	fileName = strcat('MAE_tasks', datestr(now, 'yyyy-mm-dd-HH-MM-SS'), '.mat');
% 	save(fileName, 'Response', 'ana', 'staircase','MAEDirection','MAESpeed');
% end

% sM.close();
% sca;
% Screen('CloseAll');
catch ME
	ple(ME)
	close(sM); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	save([ana.nameExp 'CRASH.mat'], 'ana', 'Response','staircase', 'sM','eL','MAEDirection','MAESpeed')
	if useEyeLink == true; eL.saveFile = [ana.nameExp 'CRASH.edf']; close(eL); end
% 	reset(stimuli);
% 	clear stimuli task taskB taskW md eL s
    clear eL s
	rethrow(ME);
end
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
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
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
			if useEyeLink && ~strcmpi(fixated,'fix')
				response = BREAKFIX; finishLoop = true;
				statusMessage(eL,'Subject Broke Fixation!');
				edfMessage(eL,'MSG:BreakFix')
				break
			end
			
			%=====================PEDESTAL
			stimuli{1}.colourOut = pedestal;
			tPedestal=GetSecs;
			while GetSecs <= tPedestal + ana.pedestalTime
				draw(stimuli); %draw stimulus
				drawCross(sM,0.4,[1 1 1 1],ana.fixX,ana.fixY);
				Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
				if useEyeLink
					getSample(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break
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
			Screen('DrawText',sM.win,['See anything AFTER stimulus: [LEFT]=NO [UP]=BRIGHTER [DOWN]=DARKER [RIGHT]=SHOW AGAIN'],0,0);
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
			if iscell(rchar);rchar=rchar{1};end
			switch lower(rchar)
				case {'leftarrow','left'}
					response = NOSEE;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject Pressed LEFT!');
						edfMessage(eL,'Subject Pressed LEFT')
					end
					doPlot();
				case {'uparrow','up'} %brighter than
					response = YESBRIGHT;
					updateResponse();
					if useEyeLink
						trackerDrawText(eL,'Subject Pressed RIGHT!');
						edfMessage(eL,'Subject Pressed RIGHT')
					end
					doPlot();
				case {'downarrow','down'} %darker than
					response = YESDARK;
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
		if useEyeLink; eL.saveFile = ''; end %blank save file so it doesn't save
	end
	if useEyeLink == true; close(eL); end
	reset(stimuli); %reset our stimulus ready for use again
	
catch ME
	ple(ME)
	close(sM); %close screen
	Priority(0); ListenChar(0); ShowCursor;
	disp(['!!!!!!!!=====CRASH, save current data to: ' pwd]);
	save([ana.nameExp 'CRASH.mat'], 'task', 'taskB', 'taskW',...
		'staircaseB', 'staircaseW', 'ana', 'sM', 'stimuli', 'eL', 'ME')
	if useEyeLink == true; eL.saveFile = [ana.nameExp 'CRASH.edf']; close(eL); end
	reset(stimuli);
	clear stimuli task taskB taskW md eL s
	rethrow(ME);
end

	function updateResponse()
		tEnd = GetSecs;
		ListenChar(0);
		if response == NOSEE || response == YESBRIGHT || response == YESDARK %subject responded
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
					if response == NOSEE || response == YESDARK
						yesnoresponse = 0;
					else
						yesnoresponse = 1;
					end
					staircaseB = PAL_AMPM_updatePM(staircaseB, yesnoresponse);
				elseif colourOut == 1
					if response == NOSEE || response == YESDARK
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
		idxYESBRIGHT = task.response == YESBRIGHT;
		idxYESDARK = task.response == YESDARK;
		
		
		cla(ana.plotAxis1); line(ana.plotAxis1,[0 max(x)+1],[0.5 0.5],'LineStyle','--','LineWidth',2); hold(ana.plotAxis1,'on')
		plot(ana.plotAxis1, x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(ana.plotAxis1, x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESDARK & idxB), ped(idxYESDARK & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESDARK & idxW), ped(idxYESDARK & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESBRIGHT & idxB), ped(idxYESBRIGHT & idxB),'r^','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESBRIGHT & idxW), ped(idxYESBRIGHT & idxW),'b^','MarkerFaceColor','w','MarkerSize',8);
		
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
		ylim(ana.plotAxis1,[0 1]);
		xlim(ana.plotAxis1,[0 max(x)+1]);
		xlabel(ana.plotAxis1,'Trials (red=BLACK blue=WHITE)')
		ylabel(ana.plotAxis1,'Pedestal Contrast')
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
			xlim(ana.plotAxis2, [0 1]);
			title(ana.plotAxis2,[tit tit2]);
			xlabel(ana.plotAxis2, 'Luminance (red=BLACK blue=WHITE)');
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
			priorB = PAL_pdfNormal(staircaseB.priorAlphas,ana.alphaPriorB,ana.alphaSD).*PAL_pdfNormal(staircaseB.priorBetas,bP,bSD);
			priorW = PAL_pdfNormal(staircaseW.priorAlphas,ana.alphaPriorW,ana.alphaSD).*PAL_pdfNormal(staircaseW.priorBetas,bP,bSD);
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
		ana.values.NOSEE = NOSEE;
		ana.values.YESBRIGHT = YESBRIGHT;
		ana.values.YESDARK = YESDARK;
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

