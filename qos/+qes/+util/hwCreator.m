function hwobj = hwCreator(s)
    % s: settings string�� typically loaded from settings file, for example��
    % a mw signal generator
    % s.name = 'mw_anritsu_002';
    % s.class = 'MWSource';
    % s.interface.class = 'visa';
    % s.interface.vendor = 'agilent';
    % s.interface.rscname = 'TCPIP0::1.0.0.4::inst0::INSTR';
    % s.freqlimits = [2.0000e+09 2.0000e+10];
    % s.powerlimits = [-130 20];
    % s.power = -50;
    % s.frequency = 6e9;
    % s.on = true;
    %
    % a tektronix awg
    % s.name = 'tek_5k_002';
    % s.class = 'AWG';
    % s.interface.class = 'tcpip';
    % s.interface.ip = '1.0.0.202';
    % s.interface.port = '4001';
    % s.nchnls = 4;
    % s.skew = [];
    %
    % a digitizer
    % s.class = {'AlazarATS', 'name', 'BoardGroupID', 'BoardID'};
    % s.name = 'alazar_001';
    % s.BoardGroupID = 1;
    % s.BoardID = 1;

% Copyright 2016 Yulin Wu, Institute of Physics, Chinese  Academy of Sciences
% mail4ywu@gmail.com/mail4ywu@icloud.com

    if ischar(s.class)
        if ~isfield(s,'interface')
            f = str2func(['@qes.hwdriver.', s.class, '.GetInstance']);
            hwobj = feval(f, s.name);
        else
%             if ischar(s.interface) && (qes.util.startsWith(s.interface,'sync.ustc_da') ||...
%                     qes.util.startsWith(s.interface,'syn.ustc_dc'))
            if ischar(s.interface) && (~isempty(strfind(s.interface,'ustc_da')) ||~isempty(strfind(s.interface,'ustc.ad')))
                interfaceobj = feval(str2func(['@(chnlMap)qes.hwdriver.',s.interface,'(chnlMap)']),s.chnlMap);
            elseif ~isfield(s.interface,'class')
                error('HardwareCreator:IllegalHaredwareSettings','Haredware settings ''interface'' field must be a struct with a ''class'' field, error in settings ''%s''', s.name);
            else
                switch s.interface.class
                    case 'visa'
                        if ~isfield(s.interface,'vendor') || ~ismember(s.interface.vendor,{'ni','agilent'})
                            error('HardwareCreator:UnrecognizedHaredwareSettings','empty or unsupported visa vendor class ''%s'' in settings ''%s''', s.interface.vendor, s.name);
                        end
                        if ~isfield(s.interface,'rscname') || ~ischar(s.interface.rscname)
                            error('HardwareCreator:UnrecognizedHaredwareSettings','empty or unrecognized visa resource string ''%s'' in settings ''%s''', s.interface.rscname, s.name);
                        end
                        interfaceobj = visa(s.interface.vendor, s.interface.rscname);
                    case 'gpib'
                        if ~isfield(s.interface,'vendor') || ~ismember(s.interface.vendor,{'advantech','cec','contec','ics','iotech','keithley','mcc','ni','agilent'})
                            error('HardwareCreator:UnrecognizedHaredwareSettings','empty or unsupported gpib vendor class ''%s'' in settings ''%s''', s.interface.vendor, s.name);
                        end
                        if ~isfield(s.interface,'boardidx')
                            s.interface.boardidx = 0;
                            warning('HardwareCreator:HaredwareSettingsFieldMissing','boardidx not set, 0 is used.');
                        end
                        if ~isfield(s.interface,'gpibaddr') 
                            error('HardwareCreator:HaredwareSettingsMissing','gpib address not set for: ''%s''', s.name);
                        end
                        interfaceobj = gpib(s.interface.vendor, s.interface.boardidx, s.interface.gpibaddr);
                    case 'tcpip'
                        if ~isfield(s.interface,'ip') || ~ischar(s.interface.ip)
                            error('HardwareCreator:UnrecognizedHaredwareSettings','empty or illegal ip address format in settings ''%s''', s.interface.vendor, s.name);
                        end
                        if ~isfield(s.interface,'port') || ~isnumeric(s.interface.port)
                            error('HardwareCreator:HaredwareSettingsMissing','empty or illegal port number format in settings ''%s''', s.name);
                        end
                        interfaceobj = tcpip(s.interface.ip, s.interface.port);
                    case {'sync.ustc_da_v1','sync.ustc_dc_v1','aync.ustc_da_v1','aync.ustc_dc_v1'}
                        interfaceobj = feval(str2func(['@(chnlMap)qes.hwdriver.', s.interface.class,'(chnlMap)']),...
                            s.interface.chnlMap);
                    case {'sync.signalCore5511a'}
                        interfaceobj = feval(str2func(['@qes.hwdriver.', s.interface.class, '.GetInstance']));
                    case {'sync.simuMwSrc'}
                        interfaceobj = feval(str2func(['@qes.hwdriver.', s.interface.class, '.GetInstance']));
                    otherwise
                        error('HardwareCreator:UnrecognizedHaredwareSettings','unrecognized ''interface'' class ''%s''', s.interface.class);
                end
            end
            f = str2func(['@qes.hwdriver.', s.class, '.GetInstance']);
            if isfield(s,'drivertype')
               hwobj = feval(f, s.name, interfaceobj, s.drivertype);
            else
               hwobj = feval(f, s.name, interfaceobj);
            end
        end
    elseif iscell(s.class)
        f = str2func(['@qes.hwdriver.', s.class{1}, '.GetInstance']);
        hwobj = feval(f, s.name, s.class{2:end});
    else
        error('HardwareCreator:UnrecognizedHaredwareSettings','''class'' must be a char sting or a cell of char strings, error in settings ''%s''', s.name);
    end
    metadata = metaclass(hwobj);
    NotSetYetList = {};
    for ii = 1:length(metadata.PropertyList)
        if strcmpi(metadata.PropertyList(ii).SetAccess, 'Public') && isfield(s,metadata.PropertyList(ii).Name)
            try
                hwobj.(metadata.PropertyList(ii).Name) = s.(metadata.PropertyList(ii).Name);
            catch
                NotSetYetList = [NotSetYetList, {metadata.PropertyList(ii).Name}]; % some properties can only be set after some other properties are set
            end
        end
    end
    NNotSet = length(NotSetYetList);
    if NNotSet
        NotSetYetList = fliplr(NotSetYetList);
        for ii = 1:NNotSet
            hwobj.(NotSetYetList{ii}) = s.(NotSetYetList{ii});
        end
    end
end