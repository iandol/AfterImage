
clear e
analyze = 'contrast';

[fn,pn]=uigetfile('*.mat','Load MAT File');
cd(pn);
load(fn);
fn = regexprep(fn,'\.mat$','.edf');
e = eyelinkAnalysis('file',fn,'dir',pn);

switch analyze
	case 'contrast'
		e.variableMessageName = 'PEDESTAL';
		e.pixelsPerCm					= s.pixelsPerCm;
		e.distance						= s.distance;
		e.xCenter							= s.xCenter;
		e.yCenter							= s.yCenter;
		e.correctValue				= [1 2 3]; %NOSEE YESBRIGHT YESDARK
		e.incorrectValue			= [0 4]; %UNSURE
		e.breakFixValue				= -1;
		e.measureRange				= [-0.5 5];
		e.plotRange						= [-0.5 4];
		e.excludeIncorrect		= false;
		e.simpleParse;
		e.pruneNonRTTrials;
		%e.parseSaccades;
		
		responses = task.response.response;
		contrasts = task.response.contrastOut;
		pedestals = task.response.pedestal;
		responsesEye = [e.trials(e.correct.idx).result];
		pedEye = [e.trials(e.correct.idx).variable];
		
		% we may have some rogue trials we need to exclude, casued by not always
		% clearing response on a new trial, thus sometimes a failed trial (breakfix etc)
		% was still given a non-error response value. Only way to correct is parse the
		% response vector from task.response and identify eyelink trials where response
		% is repeated. This code iterates through and finds the repeat trials.
		iEye = 1;
		erroridx = [];
		cidx = [];
		for i = 1:length(responses)
			if responses(i) == responsesEye(iEye)
				cidx(i) = e.correct.idx(iEye);
				iEye = iEye+1;
				continue
			else
				erroridx(end+1) = iEye;
				iEye = iEye + 1;
				cidx(i) = e.correct.idx(iEye);
				iEye = iEye + 1;
				continue
			end
		end
		
		responsesEye = [e.trials(cidx).result];
		pedEye = [e.trials(cidx).variable];
		
		if length(contrasts) == length(cidx)
			blackIdx = cidx(contrasts==0);
			whiteIdx = cidx(contrasts==1);
		end
		
	case 'latency'
		e.variableMessageName		= 'TRIALID';
		e.pixelsPerCm						= s.pixelsPerCm;
		e.distance							= s.distance;
		e.xCenter								= s.xCenter;
		e.yCenter								= s.yCenter;
		e.correctValue					= [0 1]; %NOSEE YESBRIGHT YESDARK
		e.incorrectValue				= [4]; %UNSURE
		e.breakFixValue					= -1;
		e.measureRange					= [-0.5 5];
		e.plotRange							= [-0.5 4];
		e.excludeIncorrect			= false;
		e.simpleParse;
		e.pruneNonRTTrials;
		e.parseSaccades;
		e.plot(e.correct.idx(1:10));
end
