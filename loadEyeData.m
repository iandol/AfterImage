
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
	e.correctValue = [1 2 3];
	e.incorrectValue = [0 4];
	e.simpleParse
	e.plot(e.correct.idx(1:10))
else
	
end
