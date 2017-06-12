
analyze = 'contrast';

clear e task msaccB msaccW AllsaccB AllsaccW g
[fn,pn]=uigetfile('*.mat','Load MAT File');
if isnumeric(fn);disp('No file selected...');return;end
cd(pn);
load(fn);
fn2 = regexprep(fn,'\.mat$','.edf');
e = eyelinkAnalysis('file',fn2,'dir',pn);

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
		e.measureRange				= [-0.5 4];
		e.plotRange						= [-0.5 4];
		e.VFAC								= 6;
		e.MINDUR							= 3;
		e.excludeIncorrect		= false;
		e.parseSimple();
		e.pruneNonRTTrials();
		e.parseSaccades();
		
		plotRange = [0 4];
		
		% DATA FROM MAT FILE
		responses = task.response.response;
		contrasts = task.response.contrastOut;
		pedestals = task.response.pedestal;
	
		%DATA FROM EYELINK
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
		
		%NEED to CHECK responses and responsesEye are the same
		responsesEye = [e.trials(cidx).result];
		pedEye = [e.trials(cidx).variable];
		
		if length(responses) ~= length(responsesEye)
			warning('Length of MAT and EDF responses not the same !!!')
		elseif ~all(responses==responsesEye)
			warning('Content of MAT and EDF responses not the same !!!')
			responses = responsesEye;
		end
		
		e.updateCorrectIndex(cidx);
		
		if length(contrasts) == length(cidx)
			blackIdx = cidx(contrasts==0);
			whiteIdx = cidx(contrasts==1);
		end
		
		a = 1; b = 1; msaccB = []; 
		for i = blackIdx
			msaccB(a) = length(e.trials(i).microSaccades(e.trials(i).microSaccades > plotRange(1) & e.trials(i).microSaccades < plotRange(2)));
			if msaccB(a) > 0
				for j = 1:length(e.trials(i).msacc)
					if e.trials(i).msacc(j).isMicroSaccade && e.trials(i).msacc(j).time >= plotRange(1) && e.trials(i).msacc(j).time <= plotRange(2) 
						AllsaccB(b).trial = a;
						AllsaccB(b).time = e.trials(i).msacc(j).time;
						AllsaccB(b).velocity = e.trials(i).msacc(j).velocity;
						AllsaccB(b).rho = e.trials(i).msacc(j).rho;
						b = b + 1;
					end
				end
			end
			a = a + 1;
		end
		
		a = 1; b = 1; msaccW = [];
		for i = whiteIdx
			msaccW(a) = length(e.trials(i).microSaccades(e.trials(i).microSaccades > plotRange(1) & e.trials(i).microSaccades < plotRange(2)));
			if msaccW(a) > 0
				for j = 1:length(e.trials(i).msacc)
					if e.trials(i).msacc(j).isMicroSaccade && e.trials(i).msacc(j).time >= plotRange(1) && e.trials(i).msacc(j).time <= plotRange(2)
						AllsaccW(b).trial = a;
						AllsaccW(b).time = e.trials(i).msacc(j).time;
						AllsaccW(b).velocity = e.trials(i).msacc(j).velocity;
						AllsaccW(b).rho = e.trials(i).msacc(j).rho;
						b = b + 1;
					end
				end
			end
			a = a + 1;
		end
		
		g = getDensity('x', msaccB, 'y', msaccW, 'legendtxt', {'Black','White'}, 'columnlabels',{'Microsaccades'});
		g.run
		
		fn = regexprep(fn,'\.mat$','_MSACC.mat');
		save(fn, 'e', 'msaccB', 'msaccW', 'AllsaccB', 'AllsaccW', 'pedestals', 'responses', 'pedEye', 'responsesEye');
		
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
		e.parseSimple;
		e.pruneNonRTTrials;
		e.parseSaccades;
		e.plot(e.correct.idx(1:10));
end
