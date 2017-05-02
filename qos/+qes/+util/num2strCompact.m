function Value = num2strCompact(Value,numDigits)
    % a compact and smarter version of MATLAB num2str
    % num2str(1e8,'%e'):	'1.000000e+08'
    % num2str(1e8):         '1e8'
    % num2str(1e-8):        '1e-8'

% Copyright 2016 Yulin Wu, USTC, China
% mail4ywu@gmail.com/mail4ywu@icloud.com

    if isempty(Value)
        Value = '';
    end
    if nargin < 2
        numDigits = 5;
    end
    if ~isreal(Value)
        re = qes.util.num2strCompact(real(Value),numDigits);
        im = qes.util.num2strCompact(imag(Value),numDigits);
        if qes.util.startsWith(im,'-')
            Value = [re,im,'i'];
        else
            Value = [re,'+',im,'i'];
        end
        return;
    end
    
    formatspecf = ['%0.',num2str(numDigits,'%0.0f'),'f'];
    formatspece = ['%0.',num2str(numDigits,'%0.0f'),'f'];
    if abs(Value) > 1e3 ||...
            (abs(Value) < 1e-3 && round(Value) ~= Value)
        Value = num2str(Value,formatspece);
    else 
        if round(Value) == Value
            Value = num2str(Value,formatspecf);
        else
            Value = num2str(Value,formatspecf);
        end
    end
    Value = regexprep(Value,'\.*0+e','e');
    Value = regexprep(Value,'(e\+*0+)|(e\+)','e');
    Value = regexprep(Value,'e\-*0+','e-');
    if numel(Value)>1 && Value(1) == '+'
        Value(1) = [];
    end
    if ~isempty(regexp(Value,'\.\d+', 'once')) && isempty(regexp(Value,'[eE]', 'once'))
        while numel(Value) && (strcmp(Value(end),'0') || strcmp(Value(end),'.'))
            Value(end) = [];
        end
    end
end