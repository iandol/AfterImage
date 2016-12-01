function maskedAIContrast()

%----------compatibility for windows
%if ispc; PsychJavaTrouble(); end
KbName('UnifyKeyNames');

%------------Base Experiment settings--------------
ans = inputdlg({'Subject Name','Comments (room, lights etc.)'});
subject = ans{1};
lab = 'lab214_aristotle'; %dorris lab or our machine?
comments = ans{2};
useStaircase = false;
stimTime = 4;
pedestalTime = 0.35;
maskTime = 1.5;
nBlocks = 144; %number of repeated blocks?
sigma = 10;
discSize = 3;
pedestalRange = [0:0.05:0.4];

if strcmpi(lab,'lab214_aristotle')
	calibrationFile=load('Calib-AristotlePC-G5201280x1024x852.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = true;
	isDummy = false;
	pixelsPerCm = 36; %26 for Dorris lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
	distance = 56.5; %64.5 in Dorris lab;
	windowed = [];
	useScreen = 2; %screen 2 in Dorris lab is CRT
	eyelinkIP = []; %keep it empty to force the default
	pedestalBlackLinear = 0.5 - fliplr(pedestalRange);
	pedestalWhiteLinear = 0.5 + pedestalRange;
	pedestalBlack =  pedestalBlackLinear;
	pedestalWhite = pedestalWhiteLinear;
elseif strcmpi(lab,'dorrislab_aristotle')
	calibrationFile=load('Calib_AristotleG520.mat');
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	end
	backgroundColour = [0.5 0.5 0.5];
	useEyeLink = true;
	isDummy = false;
	pixelsPerCm = 26; %26 for Dorris lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
	distance = 64.5; %64.5 in Dorris lab;
	windowed = [];
	useScreen = [2]; %screen 2 in Dorris lab is CRT
	eyelinkIP = []; %keep it empty to force the default
	pedestalBlackLinear =  [0.1725    0.2196    0.2667    0.3137    0.3608    0.4078    0.4549    0.5];
	pedestalWhiteLinear = [ 0.5    0.5490    0.5961    0.6431    0.6902    0.7373    0.7843    0.8314];
	pedestalBlack =  [0.1725    0.2196    0.2667    0.3137    0.3608    0.4078    0.4549    0.5];
	pedestalWhite = [ 0.5    0.5490    0.5961    0.6431    0.6902    0.7373    0.7843    0.8314];
else
	calibrationFile='';
	if isstruct(calibrationFile) %older matlab version bug wraps object in a structure
		calibrationFile = calibrationFile.c;
	end
	backgroundColour = [0.6863 0.6863 0.6863];
	useEyeLink = true;
	isDummy = false;
	pixelsPerCm = 26; %26 for Dorris lab,32=Lab CRT -- 44=27"monitor or Macbook Pro
	distance = 64.5; %64.5 in Dorris lab;
	windowed = [];
	useScreen = [1]; %screen 1 in Dorris lab is CRT
	eyelinkIP = []; %keep it empty to force the default
	pedestalBlackLinear = [44 56 68 80 92 104 116 128]./255;
	pedestalWhiteLinear = [128 140 152 164 176 188 200 212]./255;
	pedestalBlack = [0.4275    0.4784    0.5216    0.5647    0.6000    0.6353    0.6667    0.6863];
	pedestalWhite = [0.6863    0.7216    0.7490    0.7765    0.8000    0.8275    0.8510    0.8745];
end

%-------------------response values, linked to left, up, down
NOSEE = 1; 	YESBRIGHT = 2; YESDARK = 3; UNSURE = 4;

%-----------------------Positions to move stimuli
XPos = [3 1.5 -1.5 -1.5 1.5 -3];
YPos = [0 2.598 2.598 -2.598 -2.598 0];

%----------------eyetracker settings-------------------------
fixX = 0;
fixY = 0;
firstFixInit = 1;
firstFixTime = 0.7;
firstFixRadius = 2;
strictFixation = true;

%----------------Make a name for this run-----------------------
if useStaircase; type = 'STAIR'; else type = 'MOC'; end %#ok<*UNRCH>
nameExp = ['AI' type '_' subject];
c = sprintf(' %i',fix(clock()));
c = regexprep(c,' ','_');
nameExp = [nameExp c];

%======================================stimulus objects
%---------------------main disc (stimulus and pedestal).
st = discStimulus();
st.name = ['STIM_' nameExp];
st.xPosition = -3;
st.colour = [1 1 1 1];
st.size = discSize;
st.sigma = sigma;

%-----mask stimulus
m = gratingStimulus();
m.contrast = 0.25;
m.angle = 45;
m.sf = 2;
m.tf = 2;
m.colour = backgroundColour;
m.name = ['MASK_' nameExp];
m.xPosition = st.xPosition;
m.size = st.size;
m.sigma = st.sigma;

%----------combine them into a single meta stimulus------------------
stimuli = metaStimulus();
stimuli.name = nameExp;

sidx = 1;
maskidx = 1;
stimuli{sidx} = st;
stimuli.maskStimuli{maskidx} = m;
stimuli.showMask = false;

%-----------------------open the PTB screens------------------------
s = screenManager('verbose',false,'blend',true,'screen',useScreen,...
	'pixelsPerCm',pixelsPerCm,...
	'distance',distance,'bitDepth','FloatingPoint32BitIfPossible',...
	'debug',true,'antiAlias',0,'nativeBeamPosition',0, ...
	'srcMode','GL_SRC_ALPHA','dstMode','GL_ONE_MINUS_SRC_ALPHA',...
	'windowed',windowed,'backgroundColour',[backgroundColour 0],...
	'gammaTable', calibrationFile); %use a temporary screenManager object
screenVals = open(s); %open PTB screen
setup(stimuli,s); %setup our stimulus object
%setup(t,s); %setup our stimulus object

%---------------------setup eyelink---------------------------
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
	eL.modify.calibrationtargetcolour = [1 1 0];
	eL.modify.calibrationtargetsize = 0.5;
	eL.modify.calibrationtargetwidth = 0.01;
	eL.modify.waitformodereadytime = 500;
	eL.modify.devicenumber = -1; % -1 = use any keyboard
	% X, Y, FixInitTime, FixTime, Radius, StrictFix
	updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixRadius, strictFixation);
	initialise(eL, s);
	setup(eL);
	Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
	Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
	Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
	Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
end


%---------------------------Set up task variables----------------------
task = stimulusSequence();
task.name = nameExp;
task.nBlocks = 72;
task.nVar(1).name = 'colour';
task.nVar(1).stimulus = [1];
task.nVar(1).values = [0 1];
randomiseStimuli(task);
initialiseTask(task);

taskW = stimulusSequence();
taskW.name = nameExp;
taskW.nBlocks = 8;
taskW.nVar(1).name = 'pedestalWhite';
taskW.nVar(1).stimulus = [1];
taskW.nVar(1).values = pedestalWhite;
randomiseStimuli(taskW);
initialiseTask(taskW);

taskB = stimulusSequence();
taskB.name = nameExp;
taskB.nBlocks = 8;
taskB.nVar(1).name = 'pedestalBlack';
taskB.nVar(1).stimulus = [1];
taskB.nVar(1).values = pedestalBlack;
randomiseStimuli(taskB);
initialiseTask(taskB);

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
	box on; grid on; grid minor; ylim([0 1]);
	xlabel('Trials (red=BLACK blue=WHITE)')
	ylabel('Pedestal Contrast')
	title('Masked Contrast Pedestal Experiment')
	drawnow; WaitSecs(0.25);
	
	while ~breakloop && task.totalRuns <= task.nRuns
		%-----setup our values and print some info for the trial
		hide(stimuli);
		stimuli.showMask = false;
		colourOut = task.outValues{task.totalRuns,1};
		stimuli{1}.colourOut = colourOut;
		if colourOut == 0
			pedestal = taskB.outValues{taskB.totalRuns,1};
			pedestalLinear = pedestalBlackLinear(pedestalBlack==pedestal);
		else
			pedestal = taskW.outValues{taskW.totalRuns,1};
			pedestalLinear = pedestalWhiteLinear(pedestalWhite==pedestal);
		end
		
		if posloop > 6; posloop = 1; end
		stimuli{1}.xPositionOut = XPos(posloop);
		stimuli{1}.yPositionOut = YPos(posloop);
		stimuli.maskStimuli{1}.xPositionOut = XPos(posloop);
		stimuli.maskStimuli{1}.yPositionOut = YPos(posloop);
		posloop = posloop + 1;
		stimuli.update();
		stimuli.maskStimuli{1}.update();
		
		%-----initialise eyelink and draw fix spaot
		if useEyeLink
			resetFixation(eL);
			updateFixationValues(eL, fixX, fixY, firstFixInit, firstFixTime, firstFixRadius, strictFixation);
			trackerClearScreen(eL);
			trackerDrawFixation(eL); %draw fixation window on eyelink computer
			%trackerDrawStimuli(eL,ts);
			edfMessage(eL,'V_RT MESSAGE END_FIX END_RT'); ... %this 3 lines set the trial info for the eyelink
				edfMessage(eL,['TRIALID ' num2str(task.totalRuns)]); ... %obj.getTaskIndex gives us which trial we're at
				edfMessage(eL,['PEDESTAL ' num2str(pedestal)]); ... %add in the pedestal of the current state for good measure
				startRecording(eL);
			syncTime(eL);
			statusMessage(eL,'INITIATE FIXATION...');
			fixated = '';
			eL.verbose = true;
			while ~strcmpi(fixated,'fix') && ~strcmpi(fixated,'breakfix')
				drawSpot(s,0.1,[1 1 0],fixX,fixY);
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
							setOffline(eL);
							driftCorrection(eL);
							WaitSecs(2);
						case {'q'}
							fixated = 'breakfix';
							breakloop = true;
					end
				end
			end
			WaitSecs(0.5); eL.verbose = false;
		else
			drawSpot(s,0.1,[1 1 0],fixX,fixY);
			tFix = Screen('Flip',s.win); %flip the buffer
			WaitSecs(0.5);
			fixated = 'fix';
		end
		
		%------Our main stimulus drawing loop
		while strcmpi(fixated,'fix') %initial fixation held
			if useEyeLink; edfMessage(eL,'END_FIX'); statusMessage(eL,'Show Stimulus...'); end
			stimuli.show();
			tStim = GetSecs;
			vbl = tStim;
			while GetSecs <= tStim+stimTime
				draw(stimuli); %draw stimulus
				drawSpot(s,0.1,[1 1 0],fixX,fixY);
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				if useEyeLink;
					getSample(eL); %drawEyePosition(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break;
					end
				end
				animate(stimuli); %animate stimulus, will be seen on next draw
				nextvbl = vbl + screenVals.halfisi;
				vbl = Screen('Flip',s.win, nextvbl); %flip the buffer
			end
			if ~strcmpi(fixated,'fix')
				statusMessage(eL,'Subject Broke Fixation!'); edfMessage(eL,'BreakFix')
				continue
			end
			stimuli{1}.colourOut = pedestal;
			tPedestal=GetSecs;
			while GetSecs <= tPedestal + pedestalTime
				draw(stimuli); %draw stimulus
				drawSpot(s,0.1,[1 1 0],fixX,fixY);
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				if useEyeLink;
					getSample(eL); %drawEyePosition(eL);
					isfix = isFixated(eL);
					if ~isfix
						fixated = 'breakfix';
						break;
					end
				end
				%animate(stimuli); %animate stimulus, will be seen on next draw
				nextvbl = vbl + screenVals.halfisi;
				vbl = Screen('Flip',s.win, nextvbl); %flip the buffer
			end
			if ~strcmpi(fixated,'fix')
				statusMessage(eL,'Subject Broke Fixation!'); edfMessage(eL,'BreakFix')
				continue
			end
			stimuli.showMask = true; %metaStimulus can trigger a mask
			tMask=GetSecs;
			while GetSecs <= tMask + maskTime
				draw(stimuli); %draw stimulus
				drawSpot(s,0.1,[1 1 0],fixX,fixY);
				% 				if useEyeLink == true;
				% 					getSample(eL); %drawEyePosition(eL);
				% 				end
				Screen('DrawingFinished', s.win); %tell PTB/GPU to draw
				animate(stimuli); %animate stimulus, will be seen on next draw
				nextvbl = vbl + screenVals.halfisi;
				vbl = Screen('Flip',s.win, nextvbl); %flip the buffer
			end
			
			drawBackground(s);
			Screen('DrawText',s.win,['Did you see anything AFTER stimulus: [LEFT]=NO [RIGHT]=YES'],0,0);
			if useEyeLink;
				statusMessage(eL,'Waiting for Subject Response!');
				edfMessage(eL,'Subject Responding')
				edfMessage(eL,'END_RT'); ...
			end
			tMaskOff = Screen('Flip',s.win);
		
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
							response = NOSEE;
							updateResponse();
							if useEyeLink;
								statusMessage(eL,'Subject Pressed LEFT!');
								edfMessage(eL,'Subject Pressed LEFT')
							end
							doPlot();
						case {'uparrow','up'} %brighter than
							breakloopkey = true; fixated = 'no';
							response = YESBRIGHT;
							updateResponse();
							if useEyeLink;
								statusMessage(eL,'Subject Pressed RIGHT!');
								edfMessage(eL,'Subject Pressed RIGHT')
							end
							doPlot();
						case {'downarrow','down'} %darker than
							breakloopkey = true; fixated = 'no';
							response = YESDARK;
							updateResponse();
							if useEyeLink;
								statusMessage(eL,'Subject Pressed RIGHT!');
								edfMessage(eL,'Subject Pressed RIGHT')
							end
							doPlot();
						case {'righttarrow','right'}
							breakloopkey = true; fixated = 'no';
							response = UNSURE;
							updateResponse();
							if useEyeLink;
								statusMessage(eL,'Subject UNSURE!');
								edfMessage(eL,'Subject UNSURE')
							end
							doPlot();
						case {'backspace','delete'}
							breakloopkey = true; fixated = 'no';
							response = -1;
							updateResponse();
							if useEyeLink;
								statusMessage(eL,'Subject UNDO!');
								edfMessage(eL,'Subject UNDO')
							end
							doPlot();
						case {'c'} %calibrate
							breakloopkey = true; fixated = 'no';
							stopRecording(eL);
							setOffline(eL);
							trackerSetup(eL);
							WaitSecs(2);
						case {'d'}
							breakloopkey = true; fixated = 'no';
							stopRecording(eL);
							setOffline(eL);
							success = driftCorrection(eL);
							WaitSecs(2);
						case {'q'} %quit
							breakloopkey = true; fixated = 'no';
							fprintf('\n!!!QUIT!!!\n');
							response = NaN;
							breakloop = true;
						otherwise
							breakloopkey = true; fixated = 'no';
							response = UNSURE;
							updateResponse();
							if useEyeLink;
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
		figure(figH);
		drawnow;
		resetFixation(eL);
		stopRecording(eL);
		edfMessage(eL,['TRIAL_RESULT ' num2str(response)]);
		setOffline(eL);
		drawBackground(s);
		Screen('Flip',s.win); %flip the buffer
		WaitSecs(0.5);
	end
	%-----Cleanup
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

	function updateResponse()
		tEnd = GetSecs;
		if response == NOSEE || response == YESBRIGHT || response == YESDARK %subject responded
			task.response.response(task.totalRuns) = response;
			task.response.N = task.totalRuns;
			task.response.times(task.totalRuns,:) = [tFix tStim tPedestal tMask tMaskOff tEnd];
			task.response.contrastOut(task.totalRuns) = colourOut;
			task.response.pedestal(task.totalRuns) = pedestalLinear;
			task.response.pedestalGamma(task.totalRuns) = pedestal;
			task.response.blackN(task.totalRuns) = taskB.totalRuns;
			task.response.whiteN(task.totalRuns) = taskW.totalRuns;
			task.totalRuns = task.totalRuns + 1;
			if colourOut == 0
				taskB.totalRuns = taskB.totalRuns + 1;
			else
				taskW.totalRuns = taskW.totalRuns + 1;
			end
		elseif response == -1
			if task.totalRuns > 1
				fprintf('Subject RESET of trial %i -- ', task.totalRuns);
				task.totalRuns = task.totalRuns - 1;
				if task.response.contrastOut(end) == 0
					taskB.totalRuns = taskB.totalRuns - 1;
				else
					taskW.totalRuns = taskW.totalRuns - 1;
				end
				task.response.N = task.totalRuns;
				task.response.response(end) = [];
				task.response.contrastOut(end) = [];
				task.response.pedestal(end) = [];
				task.response.pedestalGamma(end) = [];
				task.response.blackN(end) = [];
				task.response.whiteN(end) = [];
				fprintf('new trial  = %i\n', task.totalRuns);
			end
		elseif response == UNSURE
			task.response.redo = task.response.redo + 1;
			fprintf('Subject is trying stimulus again, overall = %.2g %\n',task.response.redo);
		end
	end

	function doPlot()
		ListenChar(0);
		
		x = 1:length(task.response.response);
		ped = task.response.pedestal;
		
		idxW = task.response.contrastOut == 1;
		idxB = task.response.contrastOut == 0;
		
		idxNO = task.response.response == NOSEE;
		idxYESBRIGHT = task.response.response == YESBRIGHT;
		idxYESDARK = task.response.response == YESDARK;
		
		cla; line([min(x) max(x)],[0.5 0.5],'LineStyle','--','LineWidth',1);	hold on
		plot(x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8); 
		plot(x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(x(idxYESDARK & idxB), ped(idxYESDARK & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESDARK & idxW), ped(idxYESDARK & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESBRIGHT & idxB), ped(idxYESBRIGHT & idxB),'r^','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESBRIGHT & idxW), ped(idxYESBRIGHT & idxW),'b^','MarkerFaceColor','w','MarkerSize',8);
		
		if length(task.response.response) > 4
			try
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
				t = sprintf('TRIAL:%i BLACK=%.2g +- %.2g (%i)| WHITE=%.2g +- %.2g (%i) | P=%.2g [B=%.2g W=%.2g]', task.totalRuns, bAvg, bErr, length(blackPedestal), wAvg, wErr, length(whitePedestal), p, mean(abs(blackPedestal-0.5)), mean(abs(whitePedestal-0.5)));
				title(t);
			end
		else
			t = sprintf('TRIAL:%i', task.totalRuns);
			title(t);
		end
		box on; grid on; ylim([0 1]);
		xlabel('Trials (red=BLACK blue=WHITE)')
		ylabel('Pedestal Contrast')
		hold off
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
		md.nBlocks = nBlocks; %number of repeated blocks?
		md.windowed = windowed;
		md.useScreen = useScreen; %screen 1 in Dorris lab is CRT
		md.eyelinkIP = eyelinkIP;
		md.pedestalBlackLinear = pedestalBlackLinear;
		md.pedestalWhiteLinear = pedestalWhiteLinear;
		md.pedestalBlack = pedestalBlack;
		md.pedestalWhite = pedestalWhite;
		md.sigma = sigma;
		md.discSize = discSize;
		md.NOSEE = NOSEE;
		md.YESBRIGHT = YESBRIGHT;
		md.YESDARK = YESDARK;
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

