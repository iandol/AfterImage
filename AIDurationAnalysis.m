if ismac; cd('/Volumes/Data/AfterImages/DATA/'); end

errortype = 'sem';

revision = 3;

if revision == 3
	in = load('Duration Data Revision 3.mat');
	in = in.Vdata;
	aidat=in(:,3);
	contrast=in(:,2);
	sdur=in(:,1);
	contrast(contrast==0)=-0.5;
	contrast(contrast==0.2)=-0.3;
	contrast(contrast==0.4)=-0.1;
	contrast(contrast==0.6)=0.1;
	contrast(contrast==0.8)=0.3;
	contrast(contrast==1)=0.5;
else
	in = load('Durationdata.mat');
	in = in.Durationdata;
	aidat=in(:,1);
	contrast=in(:,2);
	sdur=in(:,3);
	contrast(contrast==0)=-0.5;
	contrast(contrast==115)=-0.3;
	contrast(contrast==159)=-0.1;
	contrast(contrast==191)=0.1;
	contrast(contrast==218)=0.3;
	contrast(contrast==255)=0.5;
end

aidur=table(aidat, contrast, sdur,'VariableNames',{'AI_Duration','Contrast','Stimulus_Duration'});

clear g;
figure('Position',[10 50 1000 1000],'Name','Duration Results');
g(1,1)=gramm('x',aidur.Contrast,'y',aidur.AI_Duration,'color',aidur.Stimulus_Duration);
g(1,1).set_color_options('map','matlab');
g(1,1).set_names('y','Afterimage Duration(s)','color','Stimulus Duration(s)','x','Contrast');
g(1,1).set_order_options('x',0);
g(2,1)=copy(g(1));
g(1,2)=copy(g(1));
g(2,2)=copy(g(1));
%g(1,1).facet_grid([],pdata.Contrast,'scale','fixed');
g(1,1).geom_jitter('width',0.3,'height',0);
g(1,1).stat_glm('disp_fit','true');
g(2,1).stat_summary('type',errortype,'geom','area','setylim','true'); g(2,1).no_legend;
g(2,1).set_title(errortype);
g(1,2).stat_boxplot('width',0.7,'dodge',0.5); g(1,2).no_legend;
g(2,2).stat_smooth(); g(2,2).no_legend;
g.axe_property('XGrid','on','YGrid','on','Box','on');
g.set_title('Relation of Afterimage Duration to Contrast and Stimulus duration');
g.draw;


[p,tbl1,stats]=anovan(aidur.AI_Duration,{aidur.Stimulus_Duration,aidur.Contrast},'model','interaction','varnames',{'StimDuration','Contrast'});set(gcf,'Name','Duration Results')
figure('Position',[20 60 1000 1000],'Name','Duration Results')
[c,~,~,gnames]=multcompare(stats,'CType','tukey-kramer','Dimension',[1 2]);set(gcf,'Name','Duration Results')
ptable=[gnames(c(:,1)),gnames(c(:,2)),num2cell(c(:,3:6))];

eightsec.data = aidur.AI_Duration(aidur.Stimulus_Duration==8);
eightsec.contrast = aidur.Contrast(aidur.Stimulus_Duration==8);

[p2,tbl2,stats]=anova1(eightsec.data,eightsec.contrast,'varnames',{'Ctrst'});set(gcf,'Name','Duration Results for 8 Secs Duration')
figure('Position',[10 40 1000 1000],'Name','Duration Results for 8 Secs Duration')
[c,~,~,gnames]=multcompare(stats,'CType','tukey-kramer');set(gcf,'Name','Duration Results for 8 Secs Duration')
ptable2=[gnames(c(:,1)),gnames(c(:,2)),num2cell(c(:,3:6))];

foursec.data = aidur.AI_Duration(aidur.Stimulus_Duration==4);
foursec.contrast = aidur.Contrast(aidur.Stimulus_Duration==4);

[p3,tbl3,stats]=anova1(foursec.data,foursec.contrast,'varnames',{'Ctrst'});set(gcf,'Name','Duration Results for 4 Secs Duration')
figure('Position',[10 40 1000 1000],'Name','Duration Results for 4 Secs Duration')
[c,~,~,gnames]=multcompare(stats,'CType','tukey-kramer');set(gcf,'Name','Duration Results for 4 Secs Duration')
ptable3=[gnames(c(:,1)),gnames(c(:,2)),num2cell(c(:,3:6))];
