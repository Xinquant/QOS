function varargout = optReadoutFreq(varargin)
% finds the optimal readout resonator probe frequency for qubit
%
% <_f_> = optReadoutFreq('qubit',_c&o_,...
%       'gui',<_b_>,'save',<_b_>)
% _f_: float
% _i_: integer
% _c_: char or char string
% _b_: boolean
% _o_: object
% a&b: default type is a, but type b is also acceptable
% []: can be an array, scalar also acceptable
% {}: must be a cell array
% <>: optional, for input arguments, assume the default value if not specified
% arguments order not important as long as the form correct pairs.
    
    % Yulin Wu, 2017/1/14
    
    import qes.*
    import data_taking.public.xmon.s21_01
	import data_taking.public.util.getQubits

    args = util.processArgs(varargin,{'gui',false,'save',true});
	q = data_taking.public.util.getQubits(args,{'qubit'});
	
    R_AVG_MIN = 1000;
    if q.r_avg < R_AVG_MIN
        q.r_avg = R_AVG_MIN;
    end
    frequency = q.r_freq-3*q.t_rrDipFWHM_est:q.t_rrDipFWHM_est/20:q.r_freq+3*q.t_rrDipFWHM_est;
    e = s21_01('qubit',q,'freq',frequency);
    data = cell2mat(e.data{1});
    data = data(2:end,:); % 2:end, drop first point to deal with an ad bug, may not be necessary in future versions
    frequency = frequency(2:end);
    data(:,1) = abs(data(:,1)).*...
        exp(1i*qes.util.removeJumps(angle(data(:,1)),0.2*pi)); % remove mw source phase jumps
    data(:,2) = abs(data(:,2)).*...
        exp(1i*qes.util.removeJumps(angle(data(:,2)),0.2*pi)); 
    data(:,1) = smooth(data(:,1),3);
    data(:,2) = smooth(data(:,2),3);
    
    [~, idx] = max(abs(data(:,1) - data(:,2)));
    optFreq = frequency(idx);
    
    if args.gui
        hf = figure('NumberTitle','off','Name','optimal resonator readout frequency','HandleVisibility','callback');
        ax = axes('parent',hf);
        plot(ax,data(:,1),'--.r');
        hold(ax,'on');
        plot(ax,data(:,2),'--.b');
        plot(ax,real(data(idx,:)),imag(data(idx,:)),'-','Color',[0,1,0]);
        legend(ax,{'|1>','|0>','Max IQ separation'});
        xlabel(ax,'I');
        ylabel(ax,'Q');
        title(ax,sprintf('Maximum IQ separation frequency: %0.5fGHHz',optFreq/1e9));
        set(ax,'PlotBoxAspectRatio',[1,1,1]);
        pbaspect(ax,[1,1,1]);
    end
    if args.save
        QS = qes.qSettings.GetInstance();
        QS.saveSSettings({q.name,'r_freq'},optFreq);
    end
	varargout{1} = optFreq;
end