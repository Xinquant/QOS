/**
* @project USTCADDA
* @title CDACLib.java
* @package ustcdac
* @description The communication interface of DAC
* @author GuoCheng
* @email fortune@mail.ustc.edu.cn
* @date 2017.10.16
* @version V1.0
*/
package ustcdac;

import  com.sun.jna.Library;
import  com.sun.jna.Native;
import  com.sun.jna.ptr.IntByReference;
import  com.sun.jna.Pointer;
import  com.sun.jna.platform.win32.WinDef.UINT;
import  com.sun.jna.platform.win32.WinDef.USHORT;
import  com.sun.jna.platform.win32.WinDef.UINTByReference;

/**
 * @className CDACLib
 * @description TODO
 * @date 2017.10.17
 */
interface CDACLib extends Library {
    CDACLib INSTANCE = (CDACLib) Native.loadLibrary("dll\\USTCDACDriver.dll",CDACLib.class);
    public int OpenDAC(UINTByReference pID,String ip,USHORT port);
    public int CloseDAC(UINT id);
    public int WriteInstruction(UINT id,int instruction, int para1,int para2);
    public int WriteMemory(UINT id, int instruction, int start, int length,Pointer pData);
    public int ReadMemory(UINT id, int instruction,int start,int length);
    public int SetTimeOut(UINT id,int direction,float time);
    public int GetFunctionType(UINT id,int offset,IntByReference pFuncType,IntByReference pInstruction,IntByReference pPara1,IntByReference pPara2);
    public int GetReturn(UINT id,int offset,IntByReference pRetStat,IntByReference pRetData,Pointer pData);
    public int CheckFinished(UINT id,IntByReference pIsFinised);
    public int WaitUntilFinished(UINT id,int time);
    public int GetSoftInformation(Pointer info);
    public int CheckSuccessed(UINT id,IntByReference pIsSuccessed,IntByReference pPostion);
    public int GetErrorMsg(int errorCode, Pointer pMsg); 
}