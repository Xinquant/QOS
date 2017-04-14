% bring up qubits one by one
% Yulin Wu, 2017/3/11
%%
import data_taking.public.util.*
import data_taking.public.xmon.*
qubits = {'q1','q2','q3','q4','q5','q6','q7','q8','q9','q10'};
dips = [7.04343, 7.00426, 6.9902, 6.96171,6.9199,6.88215,6.833590,6.79613,6.75390,6.70932]*1e9-200e6; % by qubit index
scanRange = 5e6; % fine scan each qubit dips
%%
s21_rAmp('qubit','q1','freq',[dips(10)-100e6:0.1e6:dips(1)+100e6],'amp',[5e3],...  % logspace(log10(1000),log10(32768),25)
      'notes','attenuation:26dB','gui',true,'save',true);
%% S21 fine scan for each qubit dip, you can scan the power(by scan amp in log scale) to find the dispersive shift
%%
s21_rAmp('qubit',qubits{ii},'freq',[dips(4)-2e6:0.05e6:dips(4)+1e6],'amp',[logspace(log10(1000),log10(32768),25)],...  % logspace(log10(1000),log10(32768),25)
      'notes','attenuation:26dB','gui',true,'save',true);
%%
amp = logspace(log10(1000),log10(32768),25);
amp = 10000;
for ii = 2
s21_rAmp('qubit',qubits{ii},'freq',[dips(ii)-2e6:0.05e6:dips(ii)+1e6],'amp',amp,...
      'notes','attenuation:26dB','gui',true,'save',true);
end
%%
s21_zdc('qubit', 'q4',...
      'freq',[dips(4)-3.5e6:0.1e6:dips(4)+1e6],'amp',[-3e4:1.5e3:3e4],...
      'gui',true,'save',true);
%%
s21_zpa('qubit', 'q4',...
      'freq',[dips(4)-2.2e6:0.15e6:dips(4)+1e6],'amp',[-3e4:2e3:3e4],...
      'gui',true,'save',true);
%% spectroscopy1_zpa_s21
% for ii = 1:numel(qubits)
% 	setZDC(qubits{ii},1e4);
% end
% setZDC(qubits{4},0);
for ii = 5:10
spectroscopy1_zpa_s21('qubit',qubits{ii},...
       'biasAmp',[-2e4:5e3:2e4],'driveFreq',[5.93e9:0.20e6:6.13e9],...
       'gui',false,'save',true);
end
%%
spectroscopy1_zpa_s21('qubit','q2',...
       'biasAmp',[0],'driveFreq',[5.978e9:0.10e6:5.984e9],...
       'gui',true,'save',true);
%%
spectroscopy1_zpa_s21('qubit','q2','gui',true);
%%
spectroscopy1_zpa('qubit','q2',...
       'biasAmp',[-3.5e4:1000:1e4],'driveFreq',[5.978e9:0.25e6:6.15e9],...
       'gui',true,'save',true);
%%
spectroscopy1_zpa_s21('qubit','q2',...
       'biasAmp',[0],'driveFreq',[],...
       'gui',true,'save',true);
%%
for ii = 1:numel(qubits)
    spectroscopy111_zpa_s21('biasQubit',qubits{ii},'biasAmp',[-3e4:5e3:3e4],...
       'driveQubit','q4','driveFreq',[5.9e9:3e6:6.15e9],...
       'readoutQubit','q4',...
       'gui',true,'save',true);
end
%%
spectroscopy111_zpa_s21('biasQubit','q1','biasAmp',[-2e4:5e3:2e4],...
       'driveQubit','q1','driveFreq',[5.8e9:0.1e6:6.4e9],...
       'readoutQubit','q1',...
       'gui',true,'save',true);
%%
rabi_amp1('qubit','q2','biasAmp',0,'biasLonger',0,...
      'xyDriveAmp',[0:500:3e4],'detuning',[0],'driveTyp','X/2',...
      'dataTyp','P','gui',true,'save',true);
% rabi_amp1('qubit','q2','xyDriveAmp',[0:500:3e4]);  % lazy mode
%%
tuneup.optReadoutFreq('qubit','q2','gui',true,'save',true);
%%
s21_01('qubit','q2','freq',[],'notes','','gui',true,'save',true);
%%
tuneup.iq2prob_01('qubit','q2','numSamples',1e4,...
      'gui',true,'save',true);
%%
spectroscopy1_zdc('qubit','q1',...
       'biasAmp',[-3e4:5e2:3e4],'driveFreq',[5.5e9:15e6:6.3e9]+125e6,...
       'gui',true,'save',true);
%%
ramsey_df01('qubit','q2',...
      'time',[0:16:20e2],'detuning',[+5]*1e6,...
      'dataTyp','P','notes','','gui',true,'save',true);
%%
T1_1('qubit','q2','biasAmp',[0:-200:-3.5e4],'biasDelay',16,'time',[0:160*2:30e3],...
      'gui',true,'save',true);
%%
T1_1_s21('qubit','q4','biasAmp',[0],'time',[0:400:20e3],'biasDelay',16,...
      'gui',true,'save',true);