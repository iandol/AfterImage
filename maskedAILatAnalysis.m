function maskedAILatAnalysis()
oldDir = pwd;
[PathName] = uigetdir('','Select the DATA Folder:');
cd(PathName)

PF = @PAL_Weibull;
NOSEE =  1; YESSEE = 2;

n = 1;
mm{n}='AISTAIRLatency_HeKY_2016_10_17_13_15_48.mat'; n=n+1;
mm{n}='AISTAIRLatency_LiuYe_2016_10_17_12_47_52.mat'; n=n+1;
mm{n}='AISTAIRLatency_LiuX_2016_10_15_15_30_51.mat';  n=n+1; %Hui
mm{n}='AISTAIRLatency_Ian_2016_10_15_15_9_16.mat';  n=n+1;
mm{n}='AISTAIRLatency_Hui_2016_10_15_14_47_40.mat';  n=n+1;
mm{n}='AISTAIRLatency_ChenZY_2016_10_15_17_15_59'; n=n+1; 
%mm{n}='AISTAIRLatency_ChenZY_2016_10_14_22_0_21.mat'; n=n+1; 
%mm{n}='AISTAIRLatency_ChenZY_2016_10_14_21_48_6.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_LiuYe_2016_10_14_21_35_34.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_LiuYe_2016_10_14_21_26_14.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_HeKY_2016_10_14_21_0_48.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_HeKY_2016_10_14_20_15_47.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_Ian_2016_10_14_19_18_21.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_Hui_2016_10_14_18_54_45.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_Ian_2016_10_14_18_15_17.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_Hui_2016_10_14_18_3_53.mat'; n=n+1; 
% mm{n}='AISTAIRLatency_Hui_2016_10_13_22_1_8.mat'; n=n+1; 

if length(mm) < 5
	xp=2; yp = 2;
elseif length(mm) < 7
	xp=2; yp = 3;
elseif length(mm) < 10
	xp=3; yp = 3;
elseif length(mm) < 13
	xp=3; yp = 4;
else
	xp=4; yp=4;
end

figH = figure('Position',[0 0 1600 1200],'NumberTitle','off','Name','Subjects RAW');
p = panel(figH);
p.pack(xp,yp);
p.margin = [15 15 8 10]; % margin [left bottom right top]
p.de.margin = [10 15 15 20];
warning off

for i=1:length(mm)
	clear task taskB taskW md s stimuli eL;
	load(mm{i},'task','taskB','taskW','md','s'); 
	if ~isfield(md,'useGratingMask');md.useGratingMask=1;end
	tit = [md.subject '-' md.lab '-' md.comments '-T=' num2str(md.stimTime) '-GM=' num2str(md.useGratingMask)];
	fprintf('\nLoaded: %s = %s', mm{i}, tit);
	figure(figH); 
	[ii, jj] = ind2sub([xp yp],i);
	p(ii,jj).select();
	doPlotRaw();
	Bthreshold(i)			= taskB.threshold(end);
	BthresholdErr(i)	= taskB.seThreshold(end);
	Bslope(i)					= taskB.slope(end);
	BslopeErr(i)			= taskB.seSlope(end);
	Bguess(i)					= taskB.guess(end);
	BguessErr(i)			= taskB.seGuess(end);
	Blapse(i)					= taskB.lapse(end);
	BlapseErr(i)			= taskB.seLapse(end);
	Wthreshold(i)			= taskW.threshold(end);
	WthresholdErr(i)	= taskW.seThreshold(end);
	Wslope(i)					= taskW.slope(end);
	WslopeErr(i)			= taskW.seSlope(end);
	Wguess(i)					= taskW.guess(end);
	WguessErr(i)			= taskW.seGuess(end);
	Wlapse(i)					= taskW.lapse(end);
	WlapseErr(i)			= taskW.seLapse(end);
end

figH2 = figure('Position',[0 0 1000 1000],'NumberTitle','off','Name','Subjects Plot');
q=panel(figH2);
q.pack(2,2);
p.margin = [20 20 20 20]; % margin [left bottom right top]
p.de.margin = [10 15 15 20];

q(1,1).select();
hold on
errorbar(1:length(mm),Bthreshold,BthresholdErr,'ro','Color',[0.7 0 0],'LineWidth',2);
errorbar(1:length(mm),Wthreshold,WthresholdErr,'bo','Color',[0 0 0.7],'LineWidth',2);
title('Threshold'); xlabel('Subject Number');ylabel('Threshold');
box on; grid on; grid minor;
xlim([0 7]);ylim([0 0.8]);

q(1,2).select();
hold on
errorbar(1:length(mm),Bslope,BslopeErr,'ro','Color',[0.7 0 0],'LineWidth',2);
errorbar(1:length(mm),Wslope,WslopeErr,'bo','Color',[0 0 0.7],'LineWidth',2);
title('Slope')
xlabel('Subject Number');ylabel('Slope');box on; grid on; grid minor;

q(2,1).select();
hold on
errorbar(1:length(mm),Bguess,BguessErr,'ro','Color',[0.7 0 0],'LineWidth',2);
errorbar(1:length(mm),Wguess,WguessErr,'bo','Color',[0 0 0.7],'LineWidth',2);
title('Guess')
xlabel('Subject Number');ylabel('Guess');box on; grid on; grid minor;

q(2,2).select();
hold on
errorbar(1:length(mm),Blapse,BlapseErr,'ro','Color',[0.7 0 0],'LineWidth',2);
errorbar(1:length(mm),Wlapse,WlapseErr,'bo','Color',[0 0 0.7],'LineWidth',2);
title('Lapse')
xlabel('Subject Number');ylabel('Lapse');box on; grid on; grid minor;


figH3 = figure('Position',[0 0 1000 1000],'NumberTitle','off','Name','Subjects Plot');
StimLevels = linspace(0, 0.9, 200);

for i = 1:length(Bthreshold)
	modelB(i,:) = PF([Bthreshold(i) Bslope(i) Bguess(i) Blapse(i)],StimLevels);
	modelW(i,:) = PF([Wthreshold(i) Wslope(i) Wguess(i) Wlapse(i)],StimLevels);
	hold on
	plot(StimLevels,modelB(i,:),'r-');
	plot(StimLevels,modelW(i,:),'b-');
	title('Subject Psychometric Functions');
	xlabel('Mask Time'),ylabel('Proportion Seen');grid on; grid minor;box on
end

modelBAll = PF([mean(Bthreshold) mean(Bslope) mean(Bguess) mean(Blapse)],StimLevels);
modelWAll = PF([mean(Wthreshold) mean(Wslope) mean(Wguess) mean(Wlapse)],StimLevels);
hold on
plot(StimLevels,modelBAll,'r-','LineWidth',3);
plot(StimLevels,modelWAll,'b-','LineWidth',3);



%=============================PLOT THE DATA=====================
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
end
