function [buttons, keyCode, xy, deltaSecs] = JoyStickWait(deviceNumber, untilTime)

if nargin < 1
    deviceNumber = 0;
end
if nargin < 2 || isempty(untilTime)
    untilTime = inf;
end

secs				= GetSecs;
yieldInterval	= 0.005;
buttons			= [0,0,0,0];
xy					= [2^15-1 2^15-1];
keyCode			= [];
deltaSecs		= 0;

while secs < untilTime
	if ispc
		[x, y, ~, buttons] = WinJoystickMex(deviceNumber);
		xy = [x y];
		[isDown, ~, keyCode, deltaSecs] = KbCheck(-1);
		if any(buttons) || (x<1000 || x>65000) || (y<100 || y>65000) || isDown || (secs >= untilTime)
		  return;
		end
		% A tribute to Windows: A useless call to GetMouse to trigger
		% Screen()'s Windows application event queue processing to avoid
		% white-death due to hitting the "Application not responding" timeout:
		if IsWin
		  GetMouse;
		end
		% Wait for yieldInterval to prevent system overload.
		secs = WaitSecs('YieldSecs', yieldInterval);
	end
end
