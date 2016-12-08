if ismac; cd('/Volumes/Data/AfterImages/DATA/'); end

n		= 1;
mm	= [];
st	= [];
dataSet = 'revision2';

if strcmpi(dataset,'revision1')
	mm{n}='AIMOC_GongHL_2016_10_24_13_44_56.mat'; n=n+1;
	%mm{n}='AIMOC_GongHL_2016_10_21_21_54_21.mat'; n=n+1;
	%mm{n}='AIMOC_ChenJH_2016_10_21_20_46_48.mat'; n=n+1;
	%mm{n}='AIMOC_HeKY_2016_9_28_13_16_14.mat'; n=n+1;
	mm{n}='AIMOC_LiuYe_2016_9_27_11_14_4.mat'; n=n+1;
	mm{n}='AIMOC_LiuXu_2016_9_24_13_13_56.mat'; n=n+1;
	mm{n}='AIMOC_Ian_2016_9_22_19_37_43.mat'; n=n+1; %<--This is Hui
	mm{n}='AIMOC_Ian_2016_9_22_20_4_0.mat'; n=n+1;
	mm{n}='AIMOC_ChenZY_2016_9_24_15_9_18.mat'; n=n+1;
	
	st.pedestalBlackLinear	= [0.1725 0.2196 0.2667 0.3137 0.3608 0.4078 0.4549 0.5];
	st.pedestalWhiteLinear	= [0.5 0.5490 0.5961 0.6431 0.6902 0.7373 0.7843 0.8314];
	st.StimLevelsB					= fliplr(abs(0.5-pedestalBlackLinear));
	st.StimLevelsW					= abs(0.5-pedestalWhiteLinear);
	st.StimLevels						= mean([StimLevelsB;StimLevelsW]);
	st.grain								= 300;
	st.StimLevelsFineGrain	= linspace(min(st.StimLevels),max(st.StimLevels),st.grain);
	st.nTrials							= 8;
	st.doModelComparison		= false;
	st.doModelComparisonSingle = false;
	st.noSEEWeight					= 0.5;
	st.totalT								= 64;
	st.useFixed							= true;
	
else
	%-------------Ye Liu different runs
	
% 	mm{n}='AIMOC_LiuYe_2016_12_6_12_40_25.mat'; n=n+1; %bino
% 	mm{n}='AIMOC_LiuYe_2016_12_6_10_52_50.mat'; n=n+1; %bino
% 	mm{n}='AIMOC_LiuYe_2016_12_5_15_24_56.mat'; n=n+1; %bino
% 	mm{n}='AIMOC_LiuYe_2016_12_5_14_25_5.mat'; n=n+1; %0.5sec sigma=10 light=ON
% 	mm{n}='AIMOC_LiuYe_2016_12_2_14_20_33.mat'; n=n+1; %0.4secs sig=15
% 	mm{n}='AIMOC_LiuYe_2016_12_1_11_10_11.mat'; n=n+1; %6secs

	%-------------All subjects
	mm{n}='AIMOC_LuYL_2016_12_7_14_25_19.mat';	n=n+1;
	mm{n}='AIMOC_LiMW_2016_12_8_14_10_56.mat';	n=n+1;
	mm{n}='AIMOC_GongHL_2016_12_2_15_32_39.mat';	n=n+1;
	mm{n}='AIMOC_LiuYe_2016_12_6_12_40_25.mat';		n=n+1;
	mm{n}='AIMOC_LiuXu_2016_12_2_13_11_9.mat';		n=n+1;
	mm{n}='AIMOC_LiuHui_2016_12_2_13_42_30.mat';	n=n+1;
	mm{n}='AIMOC_Ian_2016_12_2_12_8_0.mat';				n=n+1;
	mm{n}='AIMOC_ChenZY_2016_12_2_14_55_3.mat';		n=n+1;
	
	st.pedestalRange				= 0:0.05:0.4;
	st.pedestalBlackLinear		= 0.5 - fliplr(st.pedestalRange);
	st.pedestalWhiteLinear		= 0.5 + st.pedestalRange;
	st.StimLevels					= st.pedestalRange;
	st.grain							= 300;
	st.StimLevelsFineGrain		= linspace(min(st.StimLevels),max(st.StimLevels),st.grain);
	st.nTrials						= 8;
	st.doModelComparison			= true;
	st.doModelComparisonSingle = false;
	st.noSEEWeight					= 0.5;
	st.totalT						= 72;
	st.useFixed						= true;
	st.maxGamma						= 0.5;
	st.PF								= @PAL_Weibull;
end

Contrast_Pedestal_Fitting(mm,st);