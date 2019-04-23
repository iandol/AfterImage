		ListenChar(0);
		
		x = 1:length(task.response);
		info = cell2mat(task.responseInfo);
		ped = [info.pedestal];
		
		idxW = [info.contrastOut] == 1;
		idxB = [info.contrastOut] == 0;
		
		idxNO = task.response == NOSEE;
		idxYESBRIGHT = task.response == YESBRIGHT;
		idxYESDARK = task.response == YESDARK;
		
		
		cla(ana.plotAxis1); line(ana.plotAxis1,[0 max(x)+1],[0.5 0.5],'LineStyle','--','LineWidth',2); hold(ana.plotAxis1,'on')
		plot(ana.plotAxis1, x(idxNO & idxB), ped(idxNO & idxB),'ro','MarkerFaceColor','r','MarkerSize',8);
		plot(ana.plotAxis1, x(idxNO & idxW), ped(idxNO & idxW),'bo','MarkerFaceColor','b','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESDARK & idxB), ped(idxYESDARK & idxB),'rv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESDARK & idxW), ped(idxYESDARK & idxW),'bv','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESBRIGHT & idxB), ped(idxYESBRIGHT & idxB),'r^','MarkerFaceColor','w','MarkerSize',8);
		plot(ana.plotAxis1, x(idxYESBRIGHT & idxW), ped(idxYESBRIGHT & idxW),'b^','MarkerFaceColor','w','MarkerSize',8);
		
		if length(task.response) > 4
			try %#ok<TRYNC>
				idx = idxNO & idxB;
				blackPedestal = ped(idx);
				[bAvg, bErr] = stderr(blackPedestal);
				idx = idxNO & idxW;
				whitePedestal = ped(idx);
				[wAvg, wErr] = stderr(whitePedestal);
				if length(blackPedestal) > 4 && length(whitePedestal)> 4
					p = ranksum(abs(blackPedestal-0.5),abs(whitePedestal-0.5));
				else
					p = 1;
				end
				t = sprintf('TRIAL:%i BLACK=%.2g +- %.2g (%i)| WHITE=%.2g +- %.2g (%i) | P=%.2g [B=%.2g W=%.2g]', task.thisRun, bAvg, bErr, length(blackPedestal), wAvg, wErr, length(whitePedestal), p, mean(abs(blackPedestal-0.5)), mean(abs(whitePedestal-0.5)));
				title(ana.plotAxis1, t);
			end
		else
			t = sprintf('TRIAL:%i', task.thisRun);
			title(ana.plotAxis1, t);
		end
		box(ana.plotAxis1,'on'); grid(ana.plotAxis1,'on');
		ylim(ana.plotAxis1,[0 1]);
		xlim(ana.plotAxis1,[0 max(x)+1]);
		xlabel(ana.plotAxis1,'Trials (red=BLACK blue=WHITE)')
		ylabel(ana.plotAxis1,'Pedestal Contrast')
		hold(ana.plotAxis1,'off')
		
		if ana.useStaircase == true
			scaleM = 200;
            tit = ''; tit2 = '';
			cla(ana.plotAxis2); hold(ana.plotAxis2,'on');
			if ~isempty(staircaseB.threshold)
				rB = linspace(min(staircaseB.stimRange),max(staircaseW.stimRange),200);
				if ana.logSlope
					b = 10.^staircaseB.slope(end);
				else
					b = staircaseB.slope(end);
				end
				outB = ana.PF([staircaseB.threshold(end) ...
					b staircaseB.guess(end) ...
					staircaseB.lapse(end)], rB);
				plot(ana.plotAxis2,rB,outB,'r-','LineWidth',2);
				
				r = staircaseB.response;
				t = 0.5-staircaseB.x(1:length(r));
				yes = r == 1;
				no = r == 0;
				plot(ana.plotAxis2,t(yes), ones(1,sum(yes)),'ro','MarkerFaceColor','r','MarkerSize',3);
				plot(ana.plotAxis2,t(no), zeros(1,sum(no)),'ro','MarkerFaceColor','w','MarkerSize',3);
				[SL, NP, OON] = PAL_PFML_GroupTrialsbyX(staircaseB.x(1:length(staircaseB.response)),...
					staircaseB.response,...
					ones(size(staircaseB.response)));
				for SR = 1:length(SL(OON~=0))
					scatter(ana.plotAxis2, SL(SR), NP(SR)/OON(SR), scaleM*sqrt(OON(SR)./sum(OON)), ...
						'MarkerFaceColor',[1 0.7 0.7],'MarkerEdgeColor','k','MarkerFaceAlpha',.7)
				end
				tit = sprintf('B\\alpha:%.2g \\pm %.2g | B\\beta:%.2g \\pm %.2g',...
					staircaseB.threshold(end),staircaseB.seThreshold(end),b,staircaseB.seSlope(end));
			end
			if ~isempty(staircaseW.threshold)
				rW = linspace(min(staircaseB.stimRange),max(staircaseW.stimRange),200);
				if ana.logSlope
					b = 10.^staircaseW.slope(end);
				else
					b = staircaseW.slope(end);
				end
				outW = ana.PF([staircaseW.threshold(end) ...
					b staircaseW.guess(end) ...
					staircaseW.lapse(end)], rW);
				plot(ana.plotAxis2,rW,outW,'b--','LineWidth',2);
				
				r = staircaseW.response;
				t = 0.5+staircaseW.x(1:length(r));
				yes = r == 1;
				no = r == 0;
				plot(ana.plotAxis2,t(yes), ones(1,sum(yes)),'kd','MarkerFaceColor','b','MarkerSize',3);
				plot(ana.plotAxis2,t(no), zeros(1,sum(no)),'bd','MarkerFaceColor','w','MarkerSize',3);
				[SL, NP, OON] = PAL_PFML_GroupTrialsbyX(staircaseW.x(1:length(staircaseW.response)),...
					staircaseW.response,...
					ones(size(staircaseW.response)));
				for SR = 1:length(SL(OON~=0))
					scatter(ana.plotAxis2, SL(SR), NP(SR)/OON(SR), scaleM*sqrt(OON(SR)./sum(OON)), ...
						'MarkerFaceColor',[0.7 0.7 1],'MarkerEdgeColor','b','MarkerFaceAlpha',.7)
				end
				tit2 = sprintf(' | W\\alpha:%.2g \\pm %.2g | W\\beta:%.2g \\pm %.2g',...
					staircaseW.threshold(end),staircaseW.seThreshold(end),b,staircaseW.seSlope(end));
			end
			box(ana.plotAxis2, 'on'); grid(ana.plotAxis2, 'on');
			ylim(ana.plotAxis2, [0 1]);
			xlim(ana.plotAxis2, [0 1]);
			title(ana.plotAxis2,[tit tit2]);
			xlabel(ana.plotAxis2, 'Contrast (red=BLACK blue=WHITE)');
			ylabel(ana.plotAxis2, 'Responses');
			hold(ana.plotAxis2, 'off');
			
			%=========================plot posteriors
			cla(ana.plotAxis3); 
			pos = PAL_Scale0to1(staircaseB.pdf(:,:,1,1));
			if ana.logSlope
				x = 10.^staircaseB.priorBetaRange;
			else
				x = staircaseB.priorBetaRange;
			end
			imagesc(ana.plotAxis3, x, staircaseB.priorAlphaRange, pos);
			axis(ana.plotAxis3,'tight');
			xlabel(ana.plotAxis3, 'Beta \beta');
			ylabel(ana.plotAxis3, 'Alpha \alpha');
			title(ana.plotAxis3, 'Black Posterior');
			cla(ana.plotAxis4); 
			pos = PAL_Scale0to1(staircaseW.pdf(:,:,1,1));
			if ana.logSlope
				x = 10.^staircaseW.priorBetaRange;
			else
				x = staircaseW.priorBetaRange;
			end
			imagesc(ana.plotAxis4, x, staircaseW.priorAlphaRange, pos);
			axis(ana.plotAxis4,'tight');
			xlabel(ana.plotAxis4, 'Beta \beta');
			ylabel(ana.plotAxis4, 'Alpha \alpha');
			title(ana.plotAxis4, 'White Posterior');
		end
		drawnow;