%% clean up
close all;
clearvars;
sca;

% Setup defaults and unit color range:
PsychDefaultSetup(2);

% Disable synctests for this quick demo:
oldSyncLevel = Screen('Preference', 'SkipSyncTests', 2);

% Select screen with maximum id for output window:
screenid = max(Screen('Screens'));

% Open a fullscreen, onscreen window with gray background. Enable 32bpc
% floating point framebuffer via imaging pipeline on it, if this is possible
% on your hardware while alpha-blending is enabled. Otherwise use a 16bpc
% precision framebuffer together with alpha-blending. We need alpha-blending
% here to implement the nice superposition of overlapping of discs. The demo will
% abort if your graphics hardware is not capable of any of this.
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
[win, winRect] = PsychImaging('OpenWindow', screenid, 0.5, [0 0 800 800]);

% Retrieve size of window in pixels, need it later to make sure that our
% moving discs don't move out of the visible screen area:
[width, height] = RectSize(winRect);

% Query frame duration: We use it later on to time 'Flips' properly for an
% animation with constant framerate:
ifi = Screen('GetFlipInterval', win);

% Enable alpha-blending
Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%% default x + y size
virtualSize = 128;
% radius of the disc edge
radius = virtualSize / 2;
% smoothing sigma in pixel
sigma = 33;
% use alpha channel for smoothing edge of disc?
useAlpha = true;
% smoothing method: cosine (0), smoothstep (1), inverse smoothstep (2)
smoothMethod = 1;

% Build a procedural disc
disctexture = CreateProceduralSmoothedDisc(win, virtualSize, virtualSize, [0 0 0 0], radius, sigma, ...
	useAlpha, smoothMethod);
% Preallocate array with destination rectangles:
texrect = Screen('Rect', disctexture);
myrect = CenterRect(texrect,winRect);

%% Set up up/down procedure:
PF = @PAL_Gumbel; % the psychometric function to use
up = 1;                     %increase after 1 wrong
down = 3;                   %decrease after 3 consecutive right
StepSizeDown = 0.05;
StepSizeUp = 0.05;
stopcriterion = 'trials';
stoprule = 25;
startvalue = 1;           %intensity on first trial

UD = PAL_AMUD_setupUD('up',up,'down',down);
UD = PAL_AMUD_setupUD(UD,'StepSizeDown',StepSizeDown,'StepSizeUp', ...
	StepSizeUp,'stopcriterion',stopcriterion,'stoprule',stoprule, ...
	'startvalue',startvalue);

%Determine and display targetd proportion correct and stimulus intensity
PF = @PAL_Gumbel;
trueParams = [0.5 20 0 0.01];
targetP = (StepSizeUp./(StepSizeUp+StepSizeDown)).^(1./down);
message = sprintf('\rTargeted proportion correct: %6.4f',targetP);
disp(message);
targetX = PAL_Gumbel(trueParams, targetP,'inverse');
message = sprintf('Targeted stimulus intensity given simulated observer');
message = strcat(message,sprintf(': %6.4f',targetX));
disp(message);


%% Trial loop setup

KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');
yesKey = KbName('LeftArrow');
noKey = KbName('RightArrow');

% Initially sync us to VBL at start of animation loop.
vbl = Screen('Flip',win);


%%
while ~UD.stop
	
	% get our current value
	colour = UD.xCurrent;
	
	% Step one: Batch-Draw all discs at the positions (dstRects) and
	% orientations (rotAngles) and colors (colours)
	% and with the stimulus parameters 'discParameters'
	Screen('DrawTextures', win, disctexture, [], myrect, [], [], [], [colour colour colour]);
	
	% Mark drawing ops as finished, so the GPU can do its drawing job while
	% we can compute updated parameters for next animation frame. This
	% command is not strictly needed, but it may give a slight additional
	% speedup, because the CPU can compute new stimulus parameters in
	% Matlab, while the GPU is drawing the stimuli for this frame.
	% Sometimes it helps more, sometimes less, or not at all, depending on
	% your system and code, but it only seldomly hurts.
	% performance...
	Screen('DrawingFinished', win);
	
	% Done. Flip one video refresh after the last 'Flip', ie. try to
	% update the display every video refresh cycle if you can.
	% This is the same as Screen('Flip', win);
	% but the provided explicit 'when' deadline allows PTB's internal
	% frame-skip detector to work more accurately and give a more
	% meaningful report of missed deadlines at the end of the script. Not
	% important for this demo, but here just in case you didn't know ;-)
	% vbl = Screen('Flip', win, vbl + 0.5 * ifi);
	vbl = Screen('Flip', win);
	
	WaitSecs(0.5)
	
	DrawFormattedText(win, 'Disc brighter / same as background? (left=yes,right=no)', 'center', 'center', [0 0 0]);
	vbl = Screen('Flip', win);
	
	respToBeMade = true;
	while respToBeMade
		[keyIsDown,secs, keyCode] = KbCheck;
		if keyCode(escapeKey)
			ShowCursor; sca;
			return
		elseif keyCode(yesKey)
			response = 1;
			respToBeMade = false;
		elseif keyCode(noKey)
			response = 0;
			respToBeMade = false;
		end
	end
	
	UD = PAL_AMUD_updateUD(UD, response); %update UD structure
	
end

%% say goodbye
DrawFormattedText(win, 'Experiment Finished!', 'center', 'center', [0 0 0]);
vbl = Screen('Flip', win);WaitSecs(1);
sca;

%% Threshold estimate as mean of all but the first three reversal points
Mean = PAL_AMUD_analyzeUD(UD, 'reversals', max(UD.reversal)-3);
message = sprintf('\rThreshold estimate as mean of all but last three');
message = strcat(message,sprintf(' reversals: %6.4f', Mean));
disp(message);

%% Threshold estimate found by fitting Gumbel
params = PAL_PFML_Fit(UD.x, UD.response, ones(1,length(UD.x)), ...
	trueParams, [1 0 0 0], PF);
message = sprintf('Threshold estimate as alpha of fitted Gumbel: %6.4f'...
	, params(1));
disp(message);
values = [0:0.005:1];
pf = PF(params,values);
figure('name','Results'); subplot(1,2,1);
plot(values,pf,'LineWidth',2);
line([0.5 0.5], [0 1],'linewidth', 2, 'linestyle', '--', 'color','k');
set(gca,'FontSize',16); grid on; box on;
xlabel('Stimulus Value');
ylabel('Proportion Correct');
title('Psychometric Function');

%Create simple plot:
subplot(1,2,2);
t = 1:length(UD.x);
plot(t,UD.x,'k');
hold on;
plot(t(UD.response == 1),UD.x(UD.response == 1),'ko', 'MarkerFaceColor','k');
plot(t(UD.response == 0),UD.x(UD.response == 0),'ko', 'MarkerFaceColor','w');
axis([0 max(t)+1 min(UD.x)-(max(UD.x)-min(UD.x))/10 max(UD.x)+(max(UD.x)-min(UD.x))/10]);
line([1 length(UD.x)], [targetX targetX],'linewidth', 2, 'linestyle', '--', 'color','k');
set(gca,'FontSize',16); grid on; box on;
xlabel('Trial');
ylabel('Stimulus Intensity');
title('Up/Down Adaptive Procedure');