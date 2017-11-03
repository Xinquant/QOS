%% import
clear
addpath('dlls');
import qes.*
import qes.hwdriver.sync.*
QS = qSettings.GetInstance('C:\Users\fortu\Documents\GitHub\QOS\qos\settings');
ustcaddaObj = ustcadda_v1.GetInstance();
%% test
x = 2000;
wavedata = 2e4*sin((1:2000)/2000*20*pi)+32768;
% wavedata = zeros(1,200);
% wavedata(101:200) = 65535;
ustcaddaObj.SetADDemod(1,0);
ustcaddaObj.SetDAChnlOutputDelay(1:16,zeros(1,16));
ustcaddaObj.SetDABoardTrigDelay([1,2,3,4],[0,0,0,0]);
ustcaddaObj.SetDAChnlOutputOffset(1:8,zeros(1,8));
ustcaddaObj.SetDARuntimes([1,2,3,4],[x,x,x,x]);
ustcaddaObj.SetDATrigCount([1 2 3 4],[x,x,x,x]);
ustcaddaObj.SetADTrigCount(1,x);
ustcaddaObj.SetADSampleDepth(1,2000);
irepeat = 1;
while(1)
    tic
    for ch = 1:16
        ustcaddaObj.SendWave(ch,wavedata);
    end
    ret = ustcaddaObj.Run(1);
    if(ret == 1)
        subplot(2,1,1);plot(ustcaddaObj.ad_list(1).I');
        subplot(2,1,2);plot(ustcaddaObj.ad_list(1).Q');
        pause(0.5);
    end
    disp([irepeat,toc]);
    irepeat = irepeat + 1;
end
