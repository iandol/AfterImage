function Contrast_Pedestal_Fitting(filename, st)

if ~exist('filename','var')
	filename = '';
end
if ~isempty(filename) && ~iscell(filename)
		mm{1} = filename;
elseif iscell(filename)
		mm = filename;
else
	error('No valid files to load');
end

if ~exist('st','var')  || isempty(st)
	st.useFixed = true;
	st.pedestalRange = [0:0.05:0.4];
	st.pedestalBlackLinear = 0.5 - fliplr(st.pedestalRange);
	st.pedestalWhiteLinear = 0.5 + st.pedestalRange;
	st.StimLevels					= st.pedestalRange;
	st.StimLevelsFineGrain = linspace(min(st.StimLevels),max(st.StimLevels),200);
	st.nTrials = 8;
	st.noSEEWeight = 0.5;
	st.doModelComparison		= false;
	st.doModelComparisonSingle = false;
	st.totalT				= 64;
	st.useFixed		= true;
	st.maxGamma = 0.5;
	st.PF				= @PAL_Weibull;
end

PF							= st.PF	;
paramsFree				= [1 1 1 0];
searchGrid.alpha		= st.StimLevelsFineGrain;
searchGrid.beta		= linspace(0.5, 5, 100);
searchGrid.gamma		= linspace(0.01,st.maxGamma,30);
if st.useFixed
	searchGrid.lambda	= 0.001;
else
	searchGrid.lambda	= linspace(0.001,0.1,5);
end
paramsFree1				= paramsFree; 
searchGrid1				= searchGrid;
opts						= PAL_minimize('options');
opts.TolX				= 1e-09;           %precision). This is a good idea,
opts.TolFun				= 1e-09;           %especially in high-dimension
opts.MaxIter			= 10000;           %parameter space.
opts.MaxFunEvals		= 10000;
guessLimits				= [0.01 st.maxGamma]; %this is gamma
lapseLimits				= [0.0001 0.1]; %this is lambda

if length(mm) < 2
	xp=1; yp = 1;
elseif length(mm) < 3
	xp=1; yp = 2;
elseif length(mm) < 5
	xp=2; yp = 2;
elseif length(mm) < 7
	xp=2; yp = 3;
elseif length(mm) < 9
	xp=2; yp = 4;
elseif length(mm) < 10
	xp=3; yp = 3;
elseif length(mm) < 13
	xp=3; yp = 4;
else
	xp=4; yp=4;
end

NOSEE =  1; YESBRIGHT = 2; YESDARK = 3;

figH = figure('Position',[0 30 1000 1000],'NumberTitle','off','Name',['Subjects: ' func2str(PF)]);
figH2 = figure('Position',[30 30 1000 1000],'NumberTitle','off','Name',['Subjects: ' func2str(PF)]);
pn = panel(figH);
pn.pack(xp,yp);
pn.fontsize = 10;
pn.margin = [15 15 8 20]; % margin [left bottom right top]
pn.de.margin = [10 15 15 27];
qn = panel(figH2);
qn.pack(xp,yp);
qn.fontsize = 10;
qn.margin = [15 15 5 20]; % margin [left bottom right top]
qn.de.margin = [10 15 15 27];

warning off

for i=1:length(mm)
	clear task taskB taskW md s stimuli eL;
	load(mm{i},'task','taskB','taskW','md','s'); fprintf('\n=>=> Loaded: %s\n', mm{i});
	figure(figH);
	[ii, jj] = ind2sub([xp yp],i); pn(ii,jj).select();
	doPlotRaw();

	response				= task.response.response;
	contrastOut			= task.response.contrastOut;
	pedestal				= task.response.pedestal;

	idxW						= contrastOut == 1;
	idxB						= contrastOut == 0;
	idxNOSEE				= response == NOSEE;
	idxYESBRIGHT		= response == YESBRIGHT;
	idxYESDARK			= response == YESDARK;

	pedestalB				= unique(pedestal(idxB));
	pedestalW				= unique(pedestal(idxW));

	a = 1;
	for j = pedestalB
		idxP			= pedestal == j;
		d					= response(idxB & idxYESDARK & idxP);
		db(i,a)		= length(d); %#ok<*SAGROW>
		b					= response(idxB & idxYESBRIGHT & idxP);
		bb(i,a)		= length(b);
		nn				= response(idxB & idxNOSEE & idxP);
		nb(i,a)		= length(nn);
		rB(i,a)		= (db(i,a) + nb(i,a) * st.noSEEWeight )/st.nTrials;
		rBr(i,a)	= (db(i,a) + nb(i,a));
		a					= a + 1;
	end

	a = 1;
	for j = pedestalW
		idxP			= pedestal == j;
		d					= response(idxW & idxYESDARK & idxP);
		dw(i,a)		= length(d);
		b					= response(idxW & idxYESBRIGHT & idxP);
		bw(i,a)		= length(b);
		n					= response(idxW & idxNOSEE & idxP);
		nw(i,a)		= length(n);
		rW(i,a)		= (bw(i,a) + nw(i,a) * st.noSEEWeight )/st.nTrials;
		rWr(i,a)	= (bw(i,a) + nw(i,a));
		a					= a + 1;
	end
	figure(figH2);
	[ii, jj] = ind2sub([xp yp],i); qn(ii,jj).select();
	[model0(i,:), model1(i,:)] = doPlotSingleCurve();
end

if length(mm) == 1; return; end %no need to do population analysis...

%%%%%%%%%%%%%%%%%%%%statistics on crossing point%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:length(mm)
	Bup=find(model0(i,:)>=0.499);
	Wup=find(model1(i,:)>=0.499);
	Bcross=Bup(1);
	Wcross=Wup(1);
	BcrossContrast(i)=(st.StimLevelsFineGrain(Bcross));
	WcrossContrast(i)=(st.StimLevelsFineGrain(Wcross));
end

g = getDensity('x',BcrossContrast,'y',WcrossContrast,...
	'legendtxt',{'DARK','BRIGHT'},'columnlabels',{'Contrast Crossing'});
g.run;

%%%%%%%%%%%%%%%%%%%%%%statistics on integrals%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:length(mm)
	kB=find(model0(i,:)>=0.5);
	kW=find(model1(i,:)>=0.5);
	Bhight=0.5-model0(i,1:kB(1)-1);
	Whight=0.5-model1(i,1:kW(1)-1);
	IntB(i)=sum(Bhight*0.4/50);
	IntW(i)=sum(Whight*0.4/50);
	
% 	idxB=find(model0(i,:)<=0.5);
% 	idxW=find(model1(i,:)<=0.5);
% 	intB(i)=trapz(st.StimLevelsFineGrain(idxB),abs(0.5-model0(i,idxB)));
% 	intW(i)=trapz(st.StimLevelsFineGrain(idxW),abs(0.5-model1(i,idxW)));
end

g = getDensity('x',IntB,'y',IntW,...
	'legendtxt',{'DARK','BRIGHT'},'columnlabels',{'Contrast Integral'});
g.run;
% g.x = intB;
% g.y = intW;
% g.columnlabels = {'TRAPZ Contrast Integral'};
% g.run;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Bsterr		= std(rB)/sqrt(length(mm));
Wsterr		= std(rW)/sqrt(length(mm));

NumPos0			= fliplr(mean(rB))*st.totalT;
OutOfNum0		= repmat(st.totalT,1,length(NumPos0));
NumPos1			= mean(rW)*st.totalT;
OutOfNum1		= repmat(st.totalT,1,length(NumPos1));

%=====================================ML FIT======================

disp(['-->Performing Psychometric Fitting using: ' func2str(PF)]);
[paramsValues0, LL0, exitflag0, message] = PAL_PFML_Fit(st.StimLevels,NumPos0,OutOfNum0,searchGrid,paramsFree,PF,'lapseLimits',lapseLimits,'guessLimits',guessLimits,'searchOptions',opts);
fprintf('\n===EXIT: %i LL=%.2g -- Luminance BLACK Parameters: ',exitflag0,LL0)
disp(paramsValues0)
fprintf(' message: %s\n',message.message);

[paramsValues1, LL1, exitflag1, message] = PAL_PFML_Fit(st.StimLevels,NumPos1,OutOfNum1,searchGrid,paramsFree,PF,'lapseLimits',lapseLimits,'guessLimits',guessLimits,'searchOptions',opts);
fprintf('\n===EXIT: %i LL=%.2g -- Luminance WHITE Parameters: ',exitflag1,LL1)
disp(paramsValues1)
fprintf(' message: %s\n',message.message);

%=====================================BAYES FIT======================
searchGrid.alpha = linspace(0.01,max(st.StimLevels), st.grain);
searchGrid.beta = log10(linspace(0.5,10, st.grain));  %log-transformed values for beta
if st.useFixed %---fixed parameters
	searchGrid.gamma = paramsValues0(3); %mean([paramsValues0(3) paramsValues1(3)]);
	searchGrid.lambda = paramsValues0(4); %mean([paramsValues0(4) paramsValues1(4)]);
	searchGrid1 = searchGrid;
	searchGrid1.gamma = paramsValues1(3); %mean([paramsValues0(3) paramsValues1(3)]);
	searchGrid1.lambda = paramsValues1(4); %mean([paramsValues0(4) paramsValues1(4)]);
else%---freee parameters
	searchGrid.gamma = linspace(0,paramsValues0(3)*2,21); %using value for guess rate ...
	searchGrid.lambda = linspace(0.01,paramsValues0(4)*2,21); %... and lapse rate
	searchGrid1 = searchGrid;
end

[a, b, g, l] = ndgrid(searchGrid.alpha,searchGrid.beta,searchGrid.gamma,searchGrid.lambda);
prior = PAL_pdfNormal(a,0.2,0.1).*PAL_pdfNormal(b,log10(1),1); %last two terms define beta distribution (minus normalization) with mode 0.02 on lapse rate
prior = prior./sum(sum(sum(sum(prior))));   %normalization happens here
%figure;contour(10.^searchGrid.beta,searchGrid.alpha,prior);title('Bayesian Prior');colorbar

[paramsValues2D0, posterior2D0] = PAL_PFBA_Fit(st.StimLevels, NumPos0, OutOfNum0, searchGrid, PF);
[paramsValues2D1, posterior2D1] = PAL_PFBA_Fit(st.StimLevels, NumPos1, OutOfNum1, searchGrid1, PF);

paramsValues2D0(1,2) = 10.^paramsValues2D0(1,2);
paramsValues2D1(1,2) = 10.^paramsValues2D1(1,2);

pV0 = paramsValues2D0(1,:);
pV1 = paramsValues2D1(1,:);

fprintf('\n\n===BAYESEXIT: -- BLACK Parameters: '); disp(pV0)
fprintf('\n===BAYESEXIT: -- WHITE Parameters: '); disp(pV1)
fprintf('\n\n');

%===================================================PLOT========================================

PC0=NumPos0./OutOfNum0;
PC1=NumPos1./OutOfNum1;
PC0Model = PF(paramsValues0,st.StimLevelsFineGrain);
PC1Model = PF(paramsValues1,st.StimLevelsFineGrain);
Model0 = PF(pV0,st.StimLevelsFineGrain);
Model1 = PF(pV1,st.StimLevelsFineGrain);

figure('Position',[5 5 1000 1000],'NumberTitle','off','Name','Bayesian Contrast Pedestal Fitting');hold on
errorbar(st.StimLevels,PC0,fliplr(Bsterr),'Color',[0.7 0 0],'linewidth',2,'Linestyle','none','Marker','.','MarkerSize',30);
errorbar(st.StimLevels,PC1,Wsterr,'Color',[0 0 0.7],'linewidth',2,'Linestyle','none','Marker','.','MarkerSize',30);
plot(st.StimLevelsFineGrain,PC0Model,'-.','color',[0.7 0 0],'linewidth',1);
plot(st.StimLevelsFineGrain,PC1Model,'-.','color',[0 0 0.7],'linewidth',1);
plot(st.StimLevelsFineGrain,Model0,'-','color',[0.7 0 0],'linewidth',2);
plot(st.StimLevelsFineGrain,Model1,'-','color',[0 0 0.7],'linewidth',2);
line([0,0.35],[0.5 0.5],'LineStyle',':','Color',[0.5 0.5 0.5],'linewidth',2)
title(['Contrast nulling experiment: ' func2str(PF)]);xlabel('Pedestal contrast');ylabel('Pedestal seen ratio');
grid on;grid minor; box on
paxes = axes('Position',[0.18 0.75 0.1 0.15]);
hold on
errorbar([1],paramsValues2D0(1,1),paramsValues2D0(2,1),'Color',[0.7 0 0],'linewidth',2,'Linestyle','none','Marker','.','MarkerSize',30);
errorbar([1],paramsValues2D1(1,1),paramsValues2D1(2,1),'Color',[0 0 0.7],'linewidth',2,'Linestyle','none','Marker','.','MarkerSize',30);
hold off
title(paxes,sprintf('T: %.3g-%.3g %.3g-%.3g',paramsValues2D0(1,1),paramsValues2D0(2,1),paramsValues2D1(1,1),paramsValues2D1(2,1)));
ylabel(paxes,'Time (s)')
axis square; grid on;box on;xlim([0.5 1.5]);
paxes = axes('Position',[0.35 0.75 0.1 0.15]);
hold on
errorbar([1],paramsValues2D0(1,2),paramsValues2D0(2,2),'Color',[0.7 0 0],'linewidth',2,'Linestyle','none','Marker','.','MarkerSize',30);
errorbar([1],paramsValues2D1(1,2),paramsValues2D1(2,2),'Color',[0 0 0.7],'linewidth',2,'Linestyle','none','Marker','.','MarkerSize',30);
hold off
title(paxes,sprintf('S: %.3g-%.3g %.3g-%.3g',paramsValues2D0(1,2),paramsValues2D0(2,2),paramsValues2D1(1,2),paramsValues2D1(2,2)));
ylabel(paxes,'Slope')
axis square; grid on;box on;xlim([0.5 1.5]);

if st.useFixed
	%posterior = posterior2D0 + posterior2D1;
	if ~any(isnan(posterior2D0(:))) || ~any(isnan(posterior2D1(:)))
		paxes = axes('Position',[0.6 0.14 0.3 0.3]);
		posterior2D0 = posterior2D0 ./ max(max(max(max(posterior2D0))));
		posterior2D1 = posterior2D1 ./ max(max(max(max(posterior2D1))));
		hold on
		contour(paxes, 10.^searchGrid.beta,searchGrid.alpha,posterior2D0);
		contour(paxes, 10.^searchGrid.beta,searchGrid.alpha,posterior2D1);
		hold off
		colorbar(paxes);
		xlabel(paxes,'[\beta] Slope');
		ylabel(paxes,'[\alpha] Threshold in seconds')
		axis square; grid on;box on; xlim([0 3]);
		title(paxes,'Posterior Distribution \pm 95% CI')
	end
	% +-95% CI
	errMult = 1.96;
	line([paramsValues2D0(1,2), paramsValues2D0(1,2)],[paramsValues2D0(1,1)-(paramsValues2D0(2,1)*errMult), paramsValues2D0(1,1)+(paramsValues2D0(2,1)*errMult)],'LineWidth',2);
	line([paramsValues2D1(1,2), paramsValues2D1(1,2)],[paramsValues2D1(1,1)-(paramsValues2D1(2,1)*errMult), paramsValues2D1(1,1)+(paramsValues2D1(2,1)*errMult)],'LineWidth',2);
	line([paramsValues2D0(1,2)-(paramsValues2D0(2,2)*errMult), paramsValues2D0(1,2)+(paramsValues2D0(2,2)*errMult)], [paramsValues2D0(1,1), paramsValues2D0(1,1)],'LineWidth',2);
	line([paramsValues2D1(1,2)-(paramsValues2D1(2,2)*errMult), paramsValues2D1(1,2)+(paramsValues2D1(2,2)*errMult)], [paramsValues2D1(1,1), paramsValues2D1(1,1)],'LineWidth',2);
end
drawnow
warning on

if st.doModelComparison

	paramsValues2D0(1,2) = log10(paramsValues2D0(1,2));
	paramsValues2D1(1,2) = log10(paramsValues2D1(1,2));

	StimLevels = [st.StimLevels;st.StimLevels];
	NumPos = [NumPos0;NumPos1];
	OutOfNum = [OutOfNum0;OutOfNum1];
	paramsValues = [paramsValues0;paramsValues1];
	paramsValues2D = [paramsValues2D0(1,:);paramsValues2D1(1,:)];

	maxTries = 4;
	rangeTries = [1 1 0 0];
	B = 500;

	fh = figure('Position',[5 5 1000 500],'NumberTitle','off','Name','Contrast Pedestal Fitting')
	h = waitbar(0,'Fitting General Model, please wait...');

	%default comparison (thresholds AND slopes equal, while guess rates and lapse rates fixed
	disp('===> Fitting General Model...')

	[TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
		PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
		paramsValues, B, PF,'maxTries',maxTries,'rangeTries',rangeTries,...
		'searchOptions',opts,'lapseLimits',lapseLimits,'guessLimits',guessLimits);

	
	figure(fh); subplot(1,3,1);histogram(real(TLRSim),40);hold on
	title('Model Comparison')
	yl = get(gca, 'Ylim');xl = get(gca, 'Xlim');
	plot(TLR,.05*yl(2),'kv','MarkerSize',12,'MarkerFaceColor','k')
	text(TLR,.15*yl(2),'TLR data','Fontsize',11,'horizontalalignment','center');
	message = ['p_{all}: ' num2str(pTLR,'%5.5g')];
	text(.95*xl(2),.8*yl(2),message,'horizontalalignment','right','fontsize',10);

	waitbar(0.3,h,'Fitting Threshold Model, please wait...');
	disp('===> Fitting Threshold Model...')

	[TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
		PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
		paramsValues, B, PF, 'lesserSlopes','unconstrained', 'maxTries',maxTries,'rangeTries',rangeTries,...
		'searchOptions',opts,'lapseLimits',lapseLimits,'guessLimits',guessLimits);

	figure(fh); subplot(1,3,2);histogram(real(TLRSim),40);hold on
	title('Model Comparison for Threshold')
	yl = get(gca, 'Ylim');xl = get(gca, 'Xlim');
	plot(TLR,.05*yl(2),'kv','MarkerSize',12,'MarkerFaceColor','k')
	text(TLR,.15*yl(2),'TLR data','Fontsize',11,'horizontalalignment','center');
	message = ['p_{thresh}: ' num2str(pTLR,'%5.5g')];
	text(.95*xl(2),.8*yl(2),message,'horizontalalignment','right','fontsize',10);


	waitbar(0.7,h,'Fitting Slope Model, please wait...');
	disp('===> Fitting Slope Model...')

	[TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
		PAL_PFLR_ModelComparison(StimLevels, NumPos, OutOfNum, ...
		paramsValues, B, PF, 'lesserThresholds','unconstrained', 'maxTries',maxTries,'rangeTries',rangeTries,...
		'searchOptions',opts,'lapseLimits',lapseLimits,'guessLimits',guessLimits);

	figure(fh); subplot(1,3,3);histogram(real(TLRSim),40);hold on
	title('Model Comparison for Slope')
	yl = get(gca, 'Ylim');xl = get(gca, 'Xlim');
	plot(TLR,.05*yl(2),'kv','MarkerSize',12,'MarkerFaceColor','k')
	text(TLR,.15*yl(2),'TLR data','Fontsize',11,'horizontalalignment','center');
	message = ['p_{slope}: ' num2str(pTLR,'%5.5g')];
	text(.95*xl(2),.8*yl(2),message,'horizontalalignment','right','fontsize',10);

	waitbar(1,h,'Finished!');
	pause(0.75);
	close(h);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%===========================================================================
	function doPlotRaw()
		x = 1:length(task.response.response);
		ped = task.response.pedestal;

		idxBr = task.response.contrastOut == 1;
		idxD = task.response.contrastOut == 0;
		idxNO = task.response.response == NOSEE;
		idxYESB = task.response.response == YESBRIGHT;
		idxYESD = task.response.response == YESDARK;

		cla; line([min(x) max(x)],[0.5 0.5],'LineStyle','--','LineWidth',1);	hold on
		plot(x(idxNO & idxD), ped(idxNO & idxD),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(x(idxNO & idxBr), ped(idxNO & idxBr),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(x(idxYESD & idxD), ped(idxYESD & idxD),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESD & idxBr), ped(idxYESD & idxBr),'bv','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESB & idxD), ped(idxYESB & idxD),'r^','MarkerFaceColor','w','MarkerSize',8);
		plot(x(idxYESB & idxBr), ped(idxYESB & idxBr),'b^','MarkerFaceColor','w','MarkerSize',8);

		try
			idx = idxNO & idxD;
			blackPedestal = ped(idx);
			[bAvg, bErr] = stderr(blackPedestal);
			idx = idxNO & idxBr;
			whitePedestal = ped(idx);
			[wAvg, wErr] = stderr(whitePedestal);
			if length(blackPedestal) > 4 && length(whitePedestal)> 4
				pval = ranksum(abs(blackPedestal-0.5),abs(whitePedestal-0.5));
			else
				pval = 1;
			end
			t = sprintf('%s\nB=%.2g +- %.2g (%i) | W=%.2g +- %.2g (%i)\nP=%.2g [B=%.2g W=%.2g]', [md.subject '-' md.lab '-' md.comments],bAvg, bErr, length(blackPedestal), wAvg, wErr, length(whitePedestal), pval, mean(abs(blackPedestal-0.5)), mean(abs(whitePedestal-0.5)));
			title(t);
		catch ME
			getReport(ME);
		end

		box on; grid on; grid minor; ylim([0 1]);xlim([1 length(x)]);
		xlabel('Trials (red=BLACK blue=WHITE)')
		ylabel('Pedestal Contrast')
		hold off
	end

	%===========================================================================
	function [model0,model1] = doPlotSingleCurve()

		NumPos0=fliplr(rB(i,:)*st.nTrials);
		OutOfNum0=repmat(st.nTrials,1,length(rB));
		NumPos1=rW(i,:)*st.nTrials;
		OutOfNum1=repmat(st.nTrials,1,length(rB));

		[paramsValues0, LL0, exitflag0, message] = PAL_PFML_Fit(st.StimLevels,NumPos0,OutOfNum0,searchGrid,paramsFree,PF,'lapseLimits',lapseLimits,'guessLimits',guessLimits,'searchOptions',opts);
		[paramsValues1, LL1, exitflag1, message] = PAL_PFML_Fit(st.StimLevels,NumPos1,OutOfNum1,searchGrid1,paramsFree1,PF,'lapseLimits',lapseLimits,'guessLimits',guessLimits,'searchOptions',opts);

		%Create simple plot
		PC0=NumPos0./OutOfNum0;
		PC1=NumPos1./OutOfNum1;
		model0 = PF(paramsValues0,st.StimLevelsFineGrain);
		model1 = PF(paramsValues1,st.StimLevelsFineGrain);

		hold on
		scatter(st.StimLevels,PC0,60,'MarkerFaceColor',[0.7 0 0],'MarkerEdgeColor','none','Marker','o','MarkerFaceAlpha',0.7);
		scatter(st.StimLevels,PC1,60,'MarkerFaceColor',[0 0 0.7],'MarkerEdgeColor','none','Marker','o','MarkerFaceAlpha',0.7);
		plot(st.StimLevelsFineGrain,real(model0),'-','color',[0.7 0 0],'linewidth',2);
		plot(st.StimLevelsFineGrain,real(model1),'-','color',[0 0 0.7],'linewidth',2);
		box on;grid on; grid minor;
		line([0,0.35],[0.5 0.5],'LineStyle','-.','Color',[0.5 0.5 0.5]);
		xlabel('Pedestal contrast');ylabel('Pedestal seen ratio');
		t=sprintf('%s\n T=%.2g / %.2g S=%.2g / %.2g \nE=%.2g / %.2g L=%.2g / %.2g',[md.subject '-' md.lab '-' md.comments],...
			paramsValues0(1),paramsValues1(1),paramsValues0(2),paramsValues1(2),paramsValues0(3),paramsValues1(3),paramsValues0(4),paramsValues1(4));
		title(t);
		xlim([-0.01 inf]);ylim([-0.01 1.01]);set(gca,'YTick',[0:0.25:1]);set(gca,'XTick',[0:0.1:0.4]);


		if st.doModelComparisonSingle
			ht=text(0,0.9,'Please Wait, comparing models...','horizontalalignment','left','fontsize',14,'fontweight','bold');
			drawnow;

			SL = [st.StimLevels;st.StimLevels];
			NP = [NumPos0;NumPos1];
			OON = [OutOfNum0;OutOfNum1];
			PV = [paramsValues0;paramsValues1];

			[TLR, pTLR, paramsL, paramsF, TLRSim, converged] = ...
				PAL_PFLR_ModelComparison(SL, NP, OON, PV, ...
				500, PF,'maxTries', 4,'rangeTries', [1 1 0 0],...
				'searchOptions',opts,'lapseLimits',lapseLimits,'guessLimits',guessLimits);
			message = ['Model Comparison P = ' num2str(pTLR,'%5.5g')];
			ht.String = message;
		end

	end

	%===========================================================================
	function [error,avg] = stderr(data,type,alpha,avgF)
		if nargin<4 || isempty(avgF); avgF = @nanmean; end
		if nargin<3 || isempty(alpha); alpha=0.05; end
		if nargin<2 || isempty(type); type='SE';	end
		if size(type,1)>1; type=reshape(type,1,size(type,1));	end
		if size(data,1) > 1 && size(data,2) > 1; nvals = size(data,1); else nvals = length(data); end
		avg=avgF(data);
		switch(type)
			case 'SE'
				err=nanstd(data);
				error=sqrt(err.^2/nvals);
			case '2SE'
				err=nanstd(data);
				error=sqrt(err.^2/nvals);
				error = error*2;
			case 'CIMEAN'
				[error, raw] = bootci(1000,{@nanmean,data},'alpha',alpha);
				avg = avgF(raw);
			case 'CIMEDIAN'
				[error, raw] = bootci(1000,{@nanmedian,data},'alpha',alpha);
				avg = avgF(raw);
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
	end
end