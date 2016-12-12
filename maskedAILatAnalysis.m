function maskedAILatAnalysis()
% oldDir = pwd;
% [PathName] = uigetdir('','Select the DATA Folder:');
% cd(PathName)

PF			= @PAL_Weibull;
avgF		= @nanmedian;
errF		= 'SE';
NOSEE		= 1;
YESSEE	= 2;

%=======================Our data list=========================================
n = 1;
%mm{n}='AISTAIRLatency_LiMW_2016_12_9_16_1_59.mat'; n=n+1;
mm{n}='AISTAIRLatency_LuYL_2016_12_7_15_47_52.mat'; n=n+1;
mm{n}='AISTAIRLatency_GongHL_2016_10_21_21_36_54.mat'; n=n+1;
%mm{n}='AISTAIRLatency_ChenJH_2016_10_21_21_14_55.mat'; n=n+1;
%mm{n}='AISTAIRLatency_HeKY_2016_10_17_13_15_48.mat'; n=n+1;
mm{n}='AISTAIRLatency_LiuYe_2016_10_17_12_47_52.mat'; n=n+1;
mm{n}='AISTAIRLatency_LiuX_2016_10_15_15_30_51.mat';  n=n+1;
mm{n}='AISTAIRLatency_Ian_2016_10_15_15_9_16.mat';  n=n+1;
mm{n}='AISTAIRLatency_Hui_2016_10_15_14_47_40.mat';  n=n+1;
mm{n}='AISTAIRLatency_ChenZY_2016_10_15_17_15_59'; n=n+1;
%mm{n}='AISTAIRLatency_ChenZY_2016_10_14_22_0_21.mat'; n=n+1;
% mm{n}='AISTAIRLatency_ChenZY_2016_10_14_21_48_6.mat'; n=n+1;
% mm{n}='AISTAIRLatency_LiuYe_2016_10_14_21_35_34.mat'; n=n+1;
% mm{n}='AISTAIRLatency_LiuYe_2016_10_14_21_26_14.mat'; n=n+1;
% mm{n}='AISTAIRLatency_HeKY_2016_10_14_21_0_48.mat'; n=n+1;
% mm{n}='AISTAIRLatency_HeKY_2016_10_14_20_15_47.mat'; n=n+1;
% mm{n}='AISTAIRLatency_Ian_2016_10_14_19_18_21.mat'; n=n+1;
% mm{n}='AISTAIRLatency_Hui_2016_10_14_18_54_45.mat'; n=n+1;
% mm{n}='AISTAIRLatency_Ian_2016_10_14_18_15_17.mat'; n=n+1;
% mm{n}='AISTAIRLatency_Hui_2016_10_14_18_3_53.mat'; n=n+1;
% mm{n}='AISTAIRLatency_Hui_2016_10_13_22_1_8.mat'; n=n+1;

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


%===================================================================================
%=======================PLOT RAW SUBJECT DATA=======================================

figH = figure('Position',[0 10 1400 1000],'NumberTitle','off','Name','Subjects RAW','Color',[1 1 1]);
p = panel(figH);
p.pack(xp,yp);
p.fontsize = 12;
p.margin = [15 15 8 10]; % margin [left bottom right top]
p.de.margin = [10 15 15 20];
warning off

for i=1:length(mm)
	clear task taskB taskW md s stimuli eL;
	load(mm{i},'task','taskB','taskW','md','s');
	if ~isfield(md,'useGratingMask');md.useGratingMask=1;end
	tit = [md.subject '-' md.lab '-' md.comments '-T=' num2str(md.stimTime) '-GM=' num2str(md.useGratingMask)];
	fprintf('Loaded: %s = %s\n', mm{i}, tit);
	[ii, jj] = ind2sub([xp yp],i);
	p(ii,jj).select();
	doPlotRaw();
	Bthreshold(i)			= taskB.threshold(end); %#ok<*AGROW>
	BthresholdErr(i)		= taskB.seThreshold(end);
	Bslope(i)				= taskB.slope(end);
	BslopeErr(i)			= taskB.seSlope(end);
	Bguess(i)				= taskB.guess(end);
	BguessErr(i)			= taskB.seGuess(end);
	Blapse(i)				= taskB.lapse(end);
	BlapseErr(i)			= taskB.seLapse(end);
	Wthreshold(i)			= taskW.threshold(end);
	WthresholdErr(i)		= taskW.seThreshold(end);
	Wslope(i)				= taskW.slope(end);
	WslopeErr(i)			= taskW.seSlope(end);
	Wguess(i)				= taskW.guess(end);
	WguessErr(i)			= taskW.seGuess(end);
	Wlapse(i)				= taskW.lapse(end);
	WlapseErr(i)			= taskW.seLapse(end);
end

%===================================================================================
%===============================PLOT PF Parameters==================================

figH2 = figure('Position',[5 50 800 800],'NumberTitle','off','Name','Subjects Plot','Color',[1 1 1]);
q=panel(figH2);
q.pack(2,2);
p.margin = [20 20 20 20]; % margin [left bottom right top]
p.de.margin = [10 15 15 20];

q(1,1).select();
hold on
errorbar(1:length(mm),Bthreshold,BthresholdErr,'r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',40);
errorbar(1:length(mm),Wthreshold,WthresholdErr,'b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',40);
title('Threshold'); xlabel('Subject Number');ylabel('Threshold \pm1SE (s)');box on; grid on; grid minor;
xlim([0 length(mm)+1]);

q(1,2).select();
hold on
errorbar(1:length(mm),Bslope,BslopeErr,'r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',40);
errorbar(1:length(mm),Wslope,WslopeErr,'b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',40);
title('Slope')
xlabel('Subject Number');ylabel('Slope \pm1SE');box on; grid on; grid minor;
xlim([0 length(mm)+1]);

q(2,1).select();
hold on
errorbar(1:length(mm),Bguess,BguessErr,'r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',40);
errorbar(1:length(mm),Wguess,WguessErr,'b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',40);
title('Guess')
xlabel('Subject Number');ylabel('Guess \pm1SE');box on; grid on; grid minor;
xlim([0 length(mm)+1]);

q(2,2).select();
hold on
errorbar(1:length(mm),Blapse,BlapseErr,'r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',40);
errorbar(1:length(mm),Wlapse,WlapseErr,'b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',40);
title('Lapse')
xlabel('Subject Number');ylabel('Lapse \pm1SE');box on; grid on; grid minor;
xlim([0 length(mm)+1]);


%===================================================================================
%===============================PLOT PF and InsetErrors=============================

figH3 = figure('Position',[0 20 1000 1000],'NumberTitle','off','Name','Subjects Plot','Color',[1 1 1]);
StimLevels = linspace(0, 0.9, 200);

for i = 1:length(Bthreshold)
	modelB(i,:) = PF([Bthreshold(i) Bslope(i) Bguess(i) Blapse(i)],StimLevels);
	modelW(i,:) = PF([Wthreshold(i) Wslope(i) Wguess(i) Wlapse(i)],StimLevels);
	hold on
	plot(StimLevels,modelB(i,:),'r-.','LineWidth',0.75);
	plot(StimLevels,modelW(i,:),'b-.','LineWidth',0.75);
end

modelBAll = PF([avgF(Bthreshold) avgF(Bslope) avgF(Bguess) avgF(Blapse)],StimLevels);
modelWAll = PF([avgF(Wthreshold) avgF(Wslope) avgF(Wguess) avgF(Wlapse)],StimLevels);
plot(StimLevels,modelBAll,'r-','Color',[0.7 0 0],'LineWidth',3);
plot(StimLevels,modelWAll,'b-','Color',[0 0 0.7],'LineWidth',3);
title('Latency Paradigm Psychometric Functions');
xlabel('\Deltat Mask Time \pm1SE (s)'),ylabel('Proportion Afterimage Seen');
grid on; grid minor; box on

[mBe, mB] = stderr(Bthreshold,errF,0.05,avgF);
[mWe, mW] = stderr(Wthreshold,errF,0.05,avgF);

pval = signrank(Bthreshold,Wthreshold);
[~,pvalvar] = vartest2(Bthreshold,Wthreshold);

if length(mBe)==1
	e(1)=mBe; e(2)=mBe; mBe=e;
else
	e(1)=mB-mBe(1);e(2)=mBe(2)-mB; mBe=e;
end
if length(mWe)==1
	e(1)=mWe; e(2)=mWe; mWe=e;
else
	e(1)=mW-mWe(1);e(2)=mWe(2)-mW; mWe=e;
end

Bi = findNearest(StimLevels, mB);
Wi = findNearest(StimLevels, mW);

errorbar(StimLevels(Bi),modelBAll(Bi),mBe(1),mBe(2),'horizontal','r.','Color',[0.7 0 0],'MarkerSize',60,'LineWidth',2);
errorbar(StimLevels(Wi),modelWAll(Wi),mWe(1),mWe(2),'horizontal','b.','Color',[0 0 0.7],'MarkerSize',60,'LineWidth',2);
text(StimLevels(Bi)+0.01,modelBAll(Bi)+0.01,sprintf('%.2g±%.1g',mB,mBe(1)),'FontSize',20);
text(StimLevels(Wi)+0.01,modelWAll(Wi)+0.01,sprintf('%.2g±%.1g',mW,mWe(1)),'FontSize',20);

paxes = axes('Position',[0.575 0.16 0.32 0.32]); hold(paxes,'on');
errorbar(paxes,1:length(mm),Bthreshold,BthresholdErr,'r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',40);
errorbar(paxes,1:length(mm),Wthreshold,WthresholdErr,'b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',40);
title(paxes,sprintf('Subject Thresholds p=%.2g pvar=%.2g',pval,pvalvar)); xlabel(paxes,'Subject Number');ylabel(paxes,'\Deltat Mask Time \pm1SE (s)');box on; grid on;
xlim([0 length(mm)+1]);ylim([0 0.6]);
paxes.XTick = 1:length(mm);

%===================================================================================
%===============================PLOT PF and ABOVEErrors=============================

figH3b = figure('Position',[10 20 1000 1000],'NumberTitle','off','Name','Subjects Plot','Color',[1 1 1]);
paxes1 = axes(figH3b,'Position',[0.1 0.1 0.8 0.6]);hold(paxes1,'on');
paxes2 = axes(figH3b, 'Position',[0.1 0.7 0.8 0.25]);hold(paxes2,'on');
axes(paxes1);
for i = 1:length(Bthreshold)
	plot(StimLevels,modelB(i,:),'r-.','LineWidth',0.75);
	plot(StimLevels,modelW(i,:),'b-.','LineWidth',0.75);
end
plot(StimLevels,modelBAll,'r-','Color',[0.7 0 0],'LineWidth',3);
plot(StimLevels,modelWAll,'b-','Color',[0 0 0.7],'LineWidth',3);
xlabel('\Deltat Mask Time \pm1SE (s)'),ylabel('Proportion Afterimage Seen');
grid on; grid minor; box on; xlim([0 0.8])

errorbar(StimLevels(Bi),modelBAll(Bi),mBe(1),mBe(2),'horizontal','r.','Color',[0.7 0 0],'MarkerSize',60,'LineWidth',2);
errorbar(StimLevels(Wi),modelWAll(Wi),mWe(1),mWe(2),'horizontal','b.','Color',[0 0 0.7],'MarkerSize',60,'LineWidth',2);
text(StimLevels(Bi)+0.01,modelBAll(Bi)+0.01,sprintf('%.2g±%.1g',mB,mBe(1)),'FontSize',20);
text(StimLevels(Wi)+0.01,modelWAll(Wi)+0.01,sprintf('%.2g±%.1g',mW,mWe(1)),'FontSize',20);

axes(paxes2);
errorbar(Wthreshold,1:length(mm),WthresholdErr,'horizontal','b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',40,'CapSize',20);
errorbar(Bthreshold,1:length(mm),BthresholdErr,'horizontal','r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',40,'CapSize',20);
ylabel('Subject Number')
box on; grid on; grid minor
ylim([0 length(mm)+1]); xlim([0 0.8]);
paxes2.XTickLabel = {''};
paxes2.YTick = 1:length(mm);
paxes2.YMinorGrid = 'off';
%paxes2.YAxisLocation = 'right';
title(sprintf('Latency Paradigm Psychometric Functions p=%.2g pvar=%.2g',pval,pvalvar));
paxes1.FontSize = 14;
paxes2.FontSize = 14;

%===================================================================================
%===============================PLOT Errors and Side PF=============================

figH4 = figure('Position',[10 20 1000 1000],'NumberTitle','off','Name','Subjects Plot','Color',[1 1 1]);
paxes1 = axes(figH4,'Position',[0.1 0.1 0.6 0.8]);hold(paxes1,'on');
paxes2 = axes(figH4, 'Position',[0.7 0.1 0.2 0.8]);hold(paxes2,'on');
axes(paxes1);
errorbar(1:length(mm),Bthreshold,BthresholdErr,'r.','Color',[0.7 0 0],'LineWidth',2,'MarkerSize',60,'CapSize',20);
errorbar(1:length(mm),Wthreshold,WthresholdErr,'b.','Color',[0 0 0.7],'LineWidth',2,'MarkerSize',60,'CapSize',20);
title('Subject Thresholds'); xlabel('Subject Number');ylabel('\Deltat Mask Time \pm1SE (s)');
paxes1.XLim = [0 length(mm)+1]; paxes1.YLim = [0 0.6];
paxes1.XTick = 1:length(mm); paxes1.Box = 'on'; grid on; grid minor;
axes(paxes2); grid on; grid minor;
for i = 1:length(Bthreshold)
	plot(modelB(i,:),StimLevels,'r-.','LineWidth',0.75);
	plot(modelW(i,:),StimLevels,'b-.','LineWidth',0.75);
end
plot(modelBAll,StimLevels,'r-','Color',[0.7 0 0],'LineWidth',3);
plot(modelWAll,StimLevels,'b-','Color',[0 0 0.7],'LineWidth',3);

errorbar(modelBAll(Bi),StimLevels(Bi),mBe(1),mBe(2),'vertical','r.','Color',[0.7 0 0],'MarkerSize',60,'LineWidth',2);
errorbar(modelWAll(Wi),StimLevels(Wi),mWe(1),mWe(2),'vertical','b.','Color',[0 0 0.7],'MarkerSize',60,'LineWidth',2);
text(modelBAll(Bi)+0.025,StimLevels(Bi),sprintf('%.2g±%.1g',mB,mBe(1)),'FontSize',20);
text(modelWAll(Wi)+0.025,StimLevels(Wi),sprintf('%.2g±%.1g',mW,mWe(1)),'FontSize',20);

paxes2.XLim = [0.5 1.0]; paxes2.YLim = [0 0.6];
xlabel('Proportion Afterimage Seen');
title(sprintf('Latency Paradigm Psychometric Functions p=%.2g pvar=%.2g',pval,pvalvar));
paxes1.XMinorGrid = 'off';
paxes2.YTickLabel = {''};
paxes2.YMinorGrid = 'off';
paxes2.Box = 'on';
paxes1.FontSize = 14;
paxes2.FontSize = 14;

warning on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%=============================PLOT THE RAW DATA=====================
	function doPlotRaw()
		if ~isfield(task.response,'response') || isempty(task.response.response)
			return
		end
		x = 1:length(task.response.response);
		delay = task.response.maskDelay;

		idxW = task.response.contrastOut == 1;
		idxB = task.response.contrastOut == 0;

		idxNOSEE = task.response.response == md.NOSEE;
		idxYESSEE = task.response.response == md.YESSEE;

		cla;

		hold on
		if md.staircase
			modx=2:2:length(x);
			if ~isempty(taskB.response); areabar(modx,taskB.threshold,taskB.seThreshold,[0.7 0 0],0.2); end
			if ~isempty(taskW.response); areabar(modx,taskW.threshold,taskW.seThreshold,[0 0 0.7],0.2); end
		end
		scatter(x(idxNOSEE & idxB), delay(idxNOSEE & idxB),40,'r','MarkerFaceColor','r','MarkerFacealpha',0.6);
		scatter(x(idxNOSEE & idxW), delay(idxNOSEE & idxW),40,'b','MarkerFaceColor','b','MarkerFacealpha',0.6);
		scatter(x(idxYESSEE & idxB), delay(idxYESSEE & idxB),40,'r','MarkerFaceColor','w','MarkerFacealpha',0.6);
		scatter(x(idxYESSEE & idxW), delay(idxYESSEE & idxW),40,'b','MarkerFaceColor','w','MarkerFacealpha',0.6);
		box on; grid on; grid minor;ylim([0 0.9])
		text(5,0.85,tit);
		xlabel('Total Trials (red=BLACK blue=WHITE)');
		ylabel('Mask Delay (seconds)');
		tt = regexprep(mm{i},'_','-');
		title(tt)
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

	%=====================FIND NEAREST=====================================
	function [idx,val,delta]=findNearest(in,value)
		%find nearest value in a vector, if more than 1 index return the first
		[~,idx] = min(abs(in - value));
		val = in(idx);
		delta = abs(value - val);
	end
end
