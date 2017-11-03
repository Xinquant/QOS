/**
* @project USTCADDA
* @title CADCLib.java
* @package ustcadc
* @description The communication interface of ADC
* @author GuoCheng
* @email fortune@mail.ustc.edu.cn
* @date 2017.10.16
* @version V1.0
*/
package ustcadc;

import  com.sun.jna.Library;
import  com.sun.jna.Native;
import  com.sun.jna.Pointer;
import  com.sun.jna.ptr.IntByReference;

/**
 * @className CADCLib
 * @description TODO
 * @date 2017.10.17
 */
interface CADCLib extends Library {
    CADCLib INSTANCE = (CADCLib) Native.loadLibrary("dll\\USTCADCDriver",CADCLib.class);
    int OpenADC(IntByReference pID,String srcMac,String dstMac);
    int CloseADC(int id);
    int SendData(int id,int len, Pointer pData);
    int RecvData(int id,int row, int column,Pointer pDataI, Pointer pDataQ);
    int RecvDemo(int id,int row, Pointer pData);
    int GetMacAddress(int id,int isDst,Pointer pMac);
    int GetErrorMsg(int id,int errorCode, Pointer strMsg);
    int GetSoftInformation(Pointer info);
}