function varargout = ramsey(varargin)
% ramsey
% mode: df01,dp,dz
% df01(default): detune by detuning iq frequency(sideband frequency)
% dp: detune by changing the second pi/2 pulse tracking frame
% dz: detune by z detune pulse
% 
% <_o_> = ramsey('qubit',_c&o_,'mode',m...
%       'time',[_i_],'detuning',<_f_>,'phaseOffset',<_f_>,...
%       'notes',<_c_>,'gui',<_b_>,'save',<_b_>)
% _f_: float
% _i_: integer
% _c_: char or char string
% _b_: boolean
% _o_: object
% a&b: default type is a, but type b is also acceptable
% []: can be an array, scalar also acceptable
% {}: must be a cell array
% <>: optional, for input arguments, assume the default value if not specified
% arguments order not important as long as they form correct pairs.


% Yulin Wu, 2016/12/27
    
    import qes.util.processArgs
    import data_taking.public.xmon.*
    args = processArgs(varargin,{'mode', 'df01','dataTyp','P','phaseOffset',0,...
        'gui',false,'notes','','detuning',0,'save',true});
    switch args.mode
        case 'df01'
            e = ramsey_df01('qubit',args.qubit,'dataTyp',args.dataTyp,'phaseOffset',args.phaseOffset,...
                'time',args.time,'detuning',args.detuning,...
                'notes',args.notes,'gui',args.gui,'save',args.save);
        case 'dp'
            e = ramsey_dp('qubit',args.qubit,'dataTyp',args.dataTyp,'phaseOffset',args.phaseOffset,...
                'time',args.time,'detuning',args.detuning,...
                'notes',args.notes,'gui',args.gui,'save',args.save);
        case 'dz'
            e = ramsey_dz('qubit',args.qubit,'dataTyp',args.dataTyp,'phaseOffset',args.phaseOffset,...
                'time',args.time,'detuning',args.detuning,...
                'notes',args.notes,'gui',args.gui,'save',args.save);
        otherwise
            throw(MException('QOS_spin_echo:illegalModeTyp',...
                sprintf('available modes are: df01, dz and dp, %s given.', args.mode)));
    end
    varargout{1} = e;
end