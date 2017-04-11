% 	FileName:USTCADDA.m
% 	Author:GuoCheng
% 	E-mail:fortune@mail.ustc.edu.cn
% 	All right reserved @ GuoCheng.
% 	Modified: 2017.2.26
%   Description:The class of ADDA
classdef ustcadda_v1 < qes.hwdriver.icinterface_compatible % extends icinterface_compatible, Yulin Wu
    properties
        runReps = 1             %run repetition
        adRecordLength = 1           %��Ҫ��Runǰ���� !!!!!     % daRecordLength
    end
    
    properties (SetAccess = private)
    
        numDABoards
        numDAChnls
        numADBoards
        numADChnls
    
        daOutputDelayStep
        daTrigDelayStep
        daSamplingRate

        adRange
        adDelayStep
    end
    
    properties (SetAccess = private) % Yulin Wu
        adTakenChnls
        daTakenChnls
    end
    
    properties(SetAccess = private, GetAccess = private) 
        da_list = []
        ad_list = []
        da_channel_list = []
        ad_channel_list = []
        
        da_master_index = 1
    end
    
    methods % Yulin Wu
        function TakeDAChnls(obj,chnls)
            if any(chnls>length(obj.da_channel_list))
				throw(MException('QOS_ustcadda:daChnlAlreadyTaken','some da channels are taken already'));
			end
			if any(ismember(chnls,obj.daTakenChnls))
				throw(MException('QOS_ustcadda:daChnlAlreadyTaken','some da channels are taken already'));
			end
			obj.daTakenChnls = [obj.daTakenChnls, chnls];
		end
		function ReleaseDAChnls(obj,chnls)
			obj.daTakenChnls = setdiff(obj.daTakenChnls,chnls);
		end
		
		function TakeADChnls(obj,chnls)
			if any(ismember(chnls,obj.adTakenChnls))
				throw(MException('QOS_ustcadda:adChnlAlreadyTaken','some ad channels are taken already'));
			end
			obj.adTakenChnls = [obj.adTakenChnls, chnls];
		end
		function ReleaseADChnls(obj,chnls)
			obj.adTakenChnls = setdiff(obj.adTakenChnls,chnls);
		end
		
		function val = GetDAChnlSamplingRate(obj, chnls)
			val = zeros(size(chnls));
			for ii = 1:numel(val)
				val(ii) = obj.da_list(obj.da_channel_list(chnls(ii)).index).da.sample_rate;
			end
		end
		
		function val = GetADChnlSamplingRate(obj,chnls)
			val = zeros(size(chnls));
			for ii = 1:numel(val)
				val(ii) = obj.ad_list(obj.ad_channel_list(chnls(ii)).index).ad.sample_rate;
			end
        end
        
        function val = GetTrigInterval(obj)
			val = obj.da_list(obj.da_master_index).da.trig_interval;
		end
    end
    methods (Access = private) % Yulin Wu
        function obj = ustcadda_v1()
            obj.Config();
            obj.Open();
        end
    end
    
    methods (Static = true)
        function obj = GetInstance() % Yulin Wu
            persistent objlst;
            if isempty(objlst) || ~isvalid(objlst)
                obj = qes.hwdriver.sync.ustcadda_v1();
                objlst = obj;
            else
                obj = objlst;
            end
        end
        function seq = GenerateTrigSeq(count,delay)
            % �����1~7�������0
            if(mod(count,8) ~= 0)
                count = (floor(count/8)+1);
            else
                count = count/8;
            end
            % ��2����������,���Ǳ������512bitλ�������
            seq  = zeros(1,16384);
            %first sequence,�����16ns��ʱ�����ڴ������������
            function_ctrl = 64;   %53-63λ
            trigger_ctrl  = 0;      %48-55λ
            counter_ctrl  = 0;      %32-47λ����ʱ������
            length_wave   = 2;      %16-31λ,������γ���
            address_wave  = 0;  %0    %0-15������ʼ��ַ
            for  k = 1:2:4096 
                seq(4*k-3) = counter_ctrl;
                seq(4*k-2) = function_ctrl*256 + trigger_ctrl;
                seq(4*k-1) = address_wave;
                seq(4*k)   = length_wave;
            end

            if(delay ~= 0)
                function_ctrl = 32;     %53-63λ����ʱ�����ֹͣ��ʶ
                counter_ctrl  = delay-1;%32-47λ����ʱ������
            else
                function_ctrl = 0;      %�������
                counter_ctrl  = 0;
            end
            
            trigger_ctrl = 0;       %48-55λ
            length_wave  = count;   %16-31λ,������γ���
            address_wave = count;   %0-15������ʼ��ַ����1��Ϊ����������ı�����
            for k = 2:2:4096
                seq(4*k-3) = counter_ctrl;
                seq(4*k-2) = function_ctrl*256 + trigger_ctrl;
                seq(4*k-1) = address_wave;
                seq(4*k)   = length_wave;
            end
        end
        
        function seq = GenerateContinuousSeq(count)
            seq  = zeros(1,16384);
            if(mod(count,8) ~= 0)
                count = floor(count/8)+1;
            else
                count = count/8;
            end
            for k = 1:4096
                seq(4*k-3) = 0;
                seq(4*k-2) = 0;
                seq(4*k-1) = 0;
                seq(4*k)   = count;
            end
        end
    end
    
    methods
        function Config(obj)
            obj.Close();
            QS = qes.qSettings.GetInstance();
            s = QS.loadHwSettings('ustcadda');
            % ����ADDA
            
            obj.numDABoards = length(s.da_boards);
            obj.numADBoards = length(s.ad_boards);
            obj.daOutputDelayStep = s.daOutputDelayStep;
            obj.daTrigDelayStep = s.daTrigDelayStep;
            obj.adDelayStep = s.adDelayStep;
            obj.adRange = s.adRange;

            % ����DAC
            for k = 1:obj.numDABoards
                obj.da_list(k).da = qes.hwdriver.sync.ustcadda_backend.USTCDAC(s.da_boards{k}.ip,s.da_boards{k}.port);
                obj.da_list(k).da.set('name',s.da_boards{k}.name);
                obj.da_list(k).da.set('channel_amount',s.da_boards{k}.numChnls);
                obj.da_list(k).da.set('gain',cell2mat(s.da_boards{k}.gain));
                obj.da_list(k).da.set('sample_rate',s.da_boards{k}.samplingRate);
                obj.da_list(k).da.set('sync_delay',s.da_boards{k}.syncDelay); 
                obj.da_list(k).da.set('trig_delay',s.da_boards{k}.daTrigDelayOffset);
                %����trig_selĬ��ֵ0
                obj.da_list(k).da.set('trig_sel',s.trigger_source);
                %����master�壬Ĭ��ֵΪ��һ����
                obj.da_list(k).da.set('ismaster', 0);
                if(isfield(s,'da_master') && strcmpi(s.da_boards{k}.name,s.da_master))
                    obj.da_master_index = k;
                end
                % ��ʼ��ͨ����maskֵ
                obj.da_list(k).mask_plus = 0; %��mask
                obj.da_list(k).mask_min  = 0; %��mask
                obj.da_list(k).da.set('trig_interval',s.triggerInterval);
                % da_trig_delay����
                obj.da_list(k).da_trig_delay = 0;
                % redefined offsetCorr settings, Yulin Wu
                obj.da_list(k).offsetCorr = cell2mat(s.da_boards{k}.offsetCorr);
                obj.da_list(k).da.set('offsetcorr',cell2mat(s.da_boards{k}.offsetCorr));
            end

            % ��������
            obj.da_list(obj.da_master_index).da.set('ismaster',true);
            obj.da_list(obj.da_master_index).da.set('trig_interval',s.triggerInterval);
            
            % ӳ��ͨ��
            for k = 1:length(s.da_chnl_map)
                channel = fieldnames(s.da_chnl_map{k});
                channel_info = s.da_chnl_map{k}.(channel{1});
%                 channel_info = regexp(channel_info,' ', 'split');
				channel_info = regexp(channel_info,'\s+', 'split'); % be lenient, Yulin Wu
                da_name = channel_info{1};
                channel_name = channel_info{2};
                % da_index = 1;
				da_index = [];
                for x = 1:length(obj.da_list)
                    if(strcmpi(da_name,obj.da_list(x).da.name))
                        da_index = x;
						break; % Yulin Wu
                    end
                end
				% We need to check the settings. Yulin Wu
				ch = str2double(channel_name(3:length(channel_name)));
				if isempty(da_index) 
					throw(MException('QOS_ustcadda:badSettings',sprintf('DA %s in da_chnl_map not exist.',da_name)));
				elseif ch > obj.da_list(da_index).da.channel_amount
					throw(MException('QOS_ustcadda:badSettings',sprintf('Channel %s dose not exist on DA %s',channel_info{2}, da_name)));
				end
                obj.da_channel_list(k).index = da_index; % bug fix: obj.da_channel_list(ch) -> obj.da_channel_list(k), Yulin Wu
                obj.da_channel_list(k).ch = ch;
                % ������ݽṹ��
                obj.da_channel_list(k).data = [];
                % ����ͨ�������������ʱ
                obj.da_channel_list(k).delay = 0;
            end
            % ����ADC,Ŀǰֻ֧��һ������
            for k = 1:obj.numADBoards
                obj.ad_list(k).ad = qes.hwdriver.sync.ustcadda_backend.USTCADC(s.ad_boards{k}.netcard);
                obj.ad_list(k).ad.set('sample_rate',s.ad_boards{k}.samplingRate);
                obj.ad_list(k).ad.set('channel_amount',s.ad_boards{k}.numChnls);
                obj.ad_list(k).ad.set('mac',s.ad_boards{k}.mac);
            end
            % ӳ��ADC��ͨ��
            for k = 1:length(s.ad_chnl_map)
                channel = fieldnames(s.ad_chnl_map{k});
                channel_info = s.ad_chnl_map{k}.(channel{1});
                % channel_info = regexp(channel_info,' ', 'split');
				channel_info = regexp(channel_info,'\s+', 'split'); % Yulin Wu
                ad_name = channel_info{1};
                channel_name = channel_info{2};
                ad_index = 1;
                for x = 1:length(obj.ad_list)
                    if(strcmpi(ad_name,obj.da_list(x).da.name))
                        ad_index = x;
						break; % Yulin Wu
                    end
                end
				
				% We need to check the settings. Yulin Wu
				ch = str2double(channel_name(3:length(channel_name)));
				if isempty(ad_index) 
					throw(MException('QOS_ustcadda:badSettings',sprintf('AD %s in ad_chnl_map not exist.',ad_name)));
				elseif ch > obj.ad_list(ad_index).ad.channel_amount
					throw(MException('QOS_ustcadda:badSettings',sprintf('Channel %s dose not exist on AD %s',channel_info{2}, ad_name)));
				end
				
                obj.ad_channel_list(k).index = ad_index; % bug fix: obj.ad_channel_list(ch) -> obj.ad_channel_list(k), Yulin Wu
                obj.ad_channel_list(k).ch = ch;
                % ������ݽṹ��
                % obj.da_channel_list(ch).data = []; % bug? Yulin Wu
            end
            
            obj.numDAChnls = length(obj.da_channel_list);
            obj.numADChnls = length(obj.ad_channel_list);
            
            obj.adTakenChnls = [];
            obj.daTakenChnls = [];
        end
        
        function Close(obj)
            len = length(obj.da_list);
            while(len>0)
                obj.da_list(len).da.Close();
                len = len - 1;
            end
            len = length(obj.ad_list);
            while(len>0)
                obj.ad_list(len).ad.Close();
                len = len - 1;
            end
        end
        
        function Open(obj)
            len = length(obj.da_list);
            while(len>0)
                obj.da_list(len).da.Open();
                len = len - 1;
            end
            len = length(obj.ad_list);
            while(len>0)
                obj.ad_list(len).ad.Open();
                len = len - 1;
            end
        end
        
        function [I,Q] = Run(obj,isSample)
            I=0;Q=0;ret = -1;
            
            
             obj.da_list(obj.da_master_index).da.SetTrigCount(obj.runReps);
			%                                                       ||
			%                                                       ||
			%                                                      \||/
			%                                                       \/
			% obj.da_list(obj.da_master_index).da.SetTrigCount(2*obj.runReps);
            
            
            
			
            obj.ad_list(1).ad.SetTrigCount(obj.runReps);
            obj.ad_list(1).ad.SetSampleDepth(obj.adRecordLength);
            % ֹͣ�������������ͨ������������ͨ��
            for k = 1:obj.numDABoards
                obj.da_list(k).da.StartStop((15 - obj.da_list(k).mask_min)*16);
                obj.da_list(k).da.StartStop(obj.da_list(k).mask_plus);
                obj.da_list(k).da.SetTrigDelay(obj.da_list(k).da_trig_delay);
            end
            % ����Ƿ�ɹ�д�����
            
            for k=1:obj.numDABoards
%                 tic
                isSuccessed = obj.da_list(k).da.CheckStatus();
%                 toc
                if(isSuccessed ~= 1)
                    error('ustcadda_v1:Run','There were some task failed!');
                end
            end
            % �ɼ�����
            while(ret ~= 0)
                obj.ad_list(1).ad.EnableADC();  
                obj.da_list(obj.da_master_index).da.SendIntTrig();
                if(isSample == true)
                    [ret,I,Q] = obj.ad_list(1).ad.RecvData(obj.runReps,obj.adRecordLength);
                else
                    ret = 0;
                end
            end
            % ����������ɹ̶���ʽ
            if(isSample == true)
                I = (reshape(I,[obj.adRecordLength,obj.runReps]))';
                Q = (reshape(Q,[obj.adRecordLength,obj.runReps]))';
            end
            % �����ͨ����¼
            for k = 1:obj.numDABoards
                obj.da_list(k).mask_plus = 0;
                obj.da_list(k).da_trig_delay = 0;
            end
        end
        
        function SendWave(obj,channel,data)
            obj.da_channel_list(channel).data = data;
            ch_info = obj.da_channel_list(channel);
            ch_delay = obj.da_channel_list(channel).delay;
            ch = ch_info.ch;
            da_struct = obj.da_list(ch_info.index);
            len = length(data);
            % ���ɸ�ʽ��������
            seq = obj.GenerateTrigSeq(len,ch_delay);
            % ��������
            da_struct.da.WriteSeq(ch,0,seq);
            % ��ʽ������,��Ҫ���������������ʵ�ָ�ʽ
            if(mod(len,8) ~= 0)
                data(len+1:(floor(len/8)+2)*8) = 32768;
            end
            len = length(data);
            data(len+1:len+16) = 32768;    %16�����������ʼ��
            % added uint16 to do clipping, otherwise DA might do wrap
            % around(65535+N is taken as N-1), this is  unacceptable for
            % qubits measurement applications, Yulin Wu
            
            % redefined offsetCorr to be a da board specific property other
            % than a ustcadda property, Yulin Wu
            data = uint16(data +...
                obj.da_list(obj.da_channel_list(channel).index).offsetCorr(obj.da_channel_list(channel).ch)); 
            % ���Ͳ���
            da_struct.da.WriteWave(ch,0,data);
            % �൱�ڻ���һ��ͨ��
            if(mod(floor(da_struct.mask_plus/(2^(ch-1))),2) == 0)
                obj.da_list(ch_info.index).mask_plus = da_struct.mask_plus + 2^(ch-1);
            end
        end
       
        function SendContinuousWave(obj,channel,voltage)
            % �����ֱ��������Ҫ��������Ϊ1*8����
            if(length(voltage) == 1)
                voltage = zeros(1,8) + voltage;
            end
            ch_info = obj.da_channel_list(channel);
            ch = ch_info.ch;
            da_struct = obj.da_list(ch_info.index);
            % ֹͣ���
            da_struct.da.StartStop(2^(ch-1)*16);
            % д������
            seq = obj.GenerateContinuousSeq(length(voltage));
            da_struct.da.WriteSeq(ch,0,seq);
            % д�벨��
            % added uint16 to do clipping, otherwise DA might do wrap
            % around(65535+N is taken as N-1), this is  unacceptable for
            % qubits measurement applications, Yulin Wu
            
            % redefined offsetCorr to be a da board specific property other
            % than a ustcadda property, Yulin Wu
            voltage = uint16(voltage +...
                obj.da_list(obj.da_channel_list(channel).index).offsetCorr(obj.da_channel_list(channel).ch)); 
            da_struct.da.WriteWave(ch,0,voltage);
            % ����״̬
            if(mod(floor(da_struct.mask_min/(2^(ch-1))),2) == 0)
                obj.da_list(ch_info.index).mask_min = da_struct.mask_min + 2^(ch-1);
            end
            da_struct.da.StartStop(obj.da_list(ch_info.index).mask_min);
        end
        
        function StopContinuousWave(obj,channel)
            ch_info = obj.da_channel_list(channel);
            ch = ch_info.ch;
            da_struct = obj.da_list(ch_info.index);
            if(mod(floor(da_struct.mask_min/(2^(ch-1))),2) ~= 0)
                obj.da_list(ch_info.index).mask_min = da_struct.mask_min - 2^(ch-1);
                da_struct.da.StartStop(2^(ch-1)*16);
            end
        end
        
        function setDAChnlOutputDelay(obj,ch,delay)
            obj.da_channel_list(ch).delay = delay;
        end
        
        function SetDABoardTrigDelay(obj,da_name,point)
            for k = 1:obj.numDABoards
                name = obj.da_list(k).da.name;
                if(strcmpi(name,da_name))
                    obj.da_list(k).da_trig_delay = point;
                end
            end
        end
        
        function delay = GetDABoardTrigDelay(obj,da_name)

            for k = 1:obj.numDABoards
                name = obj.da_list(k).da.name;
                if(strcmpi(name,da_name))
                   delay = list(k).da_trig_delay;
                end
            end
            
        end

        function name = GetDACNameByChnl(obj,ch)
            ch_info = obj.da_channel_list(ch);
            da = obj.da_list(ch_info.index).da;
            name = da.name;
        end
        
        function delete(obj) % Yulin Wu
            try % the object should be deletable under any circunstance
%                 for ch = obj.numDAChnls % zeroing might not be a good for
%                % qubit measurement, removed, Yulin Wu
%                     obj.SendContinuousWave(ch,32768+obj.offsetCorr(ch)); % zero all channels
%                 end
            catch
            end
            obj.Close();
        end
        
    end
end