
clear e
analyze = 'contrast';

[fn,pn]=uigetfile('*.mat','Load MAT File');
cd(pn)
load(fn)
fn = regexprep(fn,'\.mat$','.edf');
e = eyelinkAnalysis('file',fn,'dir',pn);

if strcmpi(analyze,'contrast')
	e.variableMessageName='PEDESTAL';
	e.pixelsPerCm = s.pixelsPerCm;
	e.distance = s.distance;
	e.xCenter = s.xCenter;
	e.yCenter = s.yCenter;
	e.correctValue = [1 2 3]; %NOSEE YESBRIGHT YESDARK
	e.incorrectValue = [0 4]; %UNSURE
	e.breakFixValue = -1;
	e.measureRange = [-0.2 5];
	e.plotRange = [0 4];
	e.excludeIncorrect = false;
	e.simpleParse
	e.plot(e.correct.idx(1:10))
else
	
end
