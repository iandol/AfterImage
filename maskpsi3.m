clear all

useEyeLink = false;
useStaircase = true;
usePsi = false;
backgroundColour = [0.5 0.5 0.5];
subject = 'Ian';
fixx = 0;
fixy = 0;
pixelsPerCm = 44; %32=Lab CRT -- 44=27"monitor or Macbook Pro
nBlocks = 10; %number of repeated blocks?
windowed = [1024 768];

%-----spot stimulus
s = spotStimulus();
s.xPosition = -4;
t.contrast = 1;
s.size = 3;

sM = screenManager('verbose',false,'blend',true,'screen',0,'pixelsPerCm',pixelsPerCm,...
	'bitDepth','8bit','debug',true,'antiAlias',0,'nativeBeamPosition',0, ...
	'srcMode','GL_SRC_ALPHA','dstMode','GL_ONE_MINUS_SRC_ALPHA',...
	'windowed',windowed,'backgroundColour',[backgroundColour 0]); %use a temporary screenManager object
screenVals = open(sM); %open PTB screen
setup(s,sM); %setup our stimulus object

if useStaircase
	
	stopCriterion = 'trials';
	stopRule = 25;
	
	stims = [0:0.01:1];
	priorAlphaB = [0:0.01:1];
	priorAlphaW = [0:0.01:1];
	priorBeta = [0.5:0.5:5];
	priorGammaRange = 0.5;  %fixed value (using vector here would make it a free parameter) 
	priorLambdaRange = .02; %ditto
	
	PMB = PAL_AMPM_setupPM('stimRange',stims,'PF',@PAL_Weibull,...
		'priorAlphaRange', priorAlphaB, 'priorBetaRange', priorBeta,...		%'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
		'numTrials', stopRule);
	
	PMW = PAL_AMPM_setupPM('stimRange',stims,'PF',@PAL_Weibull,...
		'priorAlphaRange', priorAlphaW, 'priorBetaRange', priorBeta,...		%'priorGammaRange',priorGammaRange, 'priorLambdaRange',priorLambdaRange,...
		'numTrials', stopRule);
	
	priorB = PAL_pdfNormal(PMB.priorAlphas,0.4,1).*PAL_pdfNormal(PMB.priorBetas,2,3);
	priorW = PAL_pdfNormal(PMW.priorAlphas,0.6,1).*PAL_pdfNormal(PMW.priorBetas,2,3);

	PMB = PAL_AMPM_setupPM(PMB,'prior',priorB);
	PMW = PAL_AMPM_setupPM(PMW,'prior',priorB);
	
else

end

breakloop = false;
loop = 1;
figure;
hold on;
if rem(loop,2) == 1
	sM.backgroundColour = [0.3 0.3 0.3];
	bG = 0.3;
	s.colourOut = PMB.xCurrent;
else
	sM.backgroundColour = [0.7 0.7 0.7];
	bG = 0.7;
	s.colourOut = PMW.xCurrent;
end
update(s);

try
	%trial loop
	while breakloop ~= true
		drawBackground(sM);
		drawCross(sM,0.3,[1 0 0],fixx,fixy);
		vbl = Screen('Flip',sM.win); %flip the buffer
		WaitSecs(0.5)
		vbl = Screen('Flip',sM.win); %flip the buffer
		vbls = vbl;
		while GetSecs <= vbls+1
			drawBackground(sM);
			draw(s); %draw stimulus
			drawCross(sM,0.3,[1 0 0],fixx,fixy);
			Screen('DrawingFinished', sM.win); %tell PTB/GPU to draw
			nextvbl = vbl + screenVals.halfisi;
			vbl = Screen('Flip',sM.win, nextvbl); %flip the buffer
		end

		sM.backgroundColour = [0.5 0.5 0.5];
		drawBackground(sM);
		Screen('DrawText',sM.win,'BRIGHTER THAN (Left) or DARKER THAN (Right)',0,0);
		Screen('Flip',sM.win); %flip the buffer

		response = -1;
		ListenChar(2);
		[~, keyCode] = KbWait(-1);
		rchar = KbName(keyCode);
		if iscell(rchar);rchar=rchar{1};end
		switch lower(rchar)
			case {'leftarrow','left'}
				response = 1;
			case {'rightarrow','right'}
				response = 0;
			case {'escape','esc'}
				fprintf('\nQUIT!\n');
				breakloop = true;
		end
		ListenChar(0);

		%update PM based on response
		if response > -1
			if bG == 0.3
				if ~PMB.stop
					amplitude = PMB.xCurrent;
					PMB = PAL_AMPM_updatePM(PMB,response);
					s.colourOut = PMW.xCurrent; update(s);
					if response == 1
						plot(length(PMB.x),PMB.x(end),'ro','MarkerFaceColor','r');
					else
						plot(length(PMB.x),PMB.x(end),'ko');
					end
					t = sprintf('C=%.2g | R=%i | T=%i | BG=%.2g\n',amplitude,response,loop,bG);
					fprintf(t);
					Screen('DrawText',sM.win,t,0,0);
				end
				Screen('Flip',sM.win); %flip the buffer
			else
				if ~PMW.stop
					amplitude = PMW.xCurrent;
					PMW = PAL_AMPM_updatePM(PMW,response);
					s.colourOut = PMB.xCurrent; update(s); %mext trial black
					if response == 1
						plot(length(PMW.x),PMW.x(end),'bo-','MarkerFaceColor','b');
					else
						plot(length(PMW.x),PMW.x(end),'go-');
					end
					t = sprintf('C=%.2g | R=%i | T=%i | BG=%.2g\n',amplitude,response,loop,bG);
					fprintf(t);
					Screen('DrawText',sM.win,t,0,0);
				end
				Screen('Flip',sM.win); %flip the buffer
			end
		end
		
		if PMW.stop && PMB.stop
			fprintf('\n======>>> Adaptive Methods finished!\n');
			breakloop = true;
		end

		WaitSecs('YieldSecs',0.5);
		loop = loop + 1;
		if rem(loop,2) == 1
			sM.backgroundColour = [0.3 0.3 0.3];
			bG = 0.3;
		else
			sM.backgroundColour = [0.7 0.7 0.7];
			bG = 0.7;
		end
	end

	Screen('Flip',sM.win);
	Priority(0); ListenChar(0); ShowCursor;
	close(sM); %close screen
	clear sM s
	
catch
	Priority(0); ListenChar(0); ShowCursor;
	close(sM); %close screen
	clear sM s
	
end
