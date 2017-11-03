/**
* @project USTCADDA
* @title USTCADC.java
* @package ustcadc
* @description The control interface of ADC
* @author GuoCheng
* @email fortune@mail.ustc.edu.cn
* @date 2017.10.16
* @version V1.0
*/

package ustcadc;

import com.sun.jna.ptr.IntByReference;
import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import ustcadc.CADCLib;

/**
 * @className USTCADC
 * @description The control interface of ADC
 * @date 2017.10.17
 */
public class USTCADC {
	/**
	 * @fields adName : The name of the ADC.
	 */
	public String adName;
	/**
	 * @fields id : The ID of the ADC.
	 */
	private int id;
	/**
	 * @fields sampleDepth : The sample depth of the ADC.
	 */
	private int sampleDepth;
	/**
	 * @fields trigCount : The trigger count of the ADC.
	 */
	private int trigCount;
	/**
	 * @fields windowStart : The demod window start position of the ADC.
	 */
	private int windowStart;
	/**
	 * @fields windowWidth : The demod window width of the ADC.
	 */
	private int windowWidth;
	/**
	 * @fields demodFreq : The demod frequency array of the ADC.
	 */
	private double demodFreq;
	/**
	 * @fields isOpen : The open state of the ADC.
	 */
	private boolean isOpen;
	/**
	 * @fields isDemod : The demod state of the ADC, true for demod mode.
	 */
	private boolean isDemod;
	/**
	 * @fields srcMac : The MAC address of PC.
	 */
	private String srcMac;
	/**
	 * @fields dstMac : The MAC address of ADC.
	 */
	private String dstMac;
	/**
	 * @fields channelAmount : The channel amount of ADC.
	 */
	public final int channelAmount = 2;
	/**
	 * @fields sampleRate : The sample rate of the ADC.
	 */
	public final double sampleRate = 1e9;

	final byte[] macAddrInst = { 0, 17 }; // Instruction of setMacAddr,and next six bytes as MAC address
	final byte[] sampleDepthInst = { 0, 18 }; // Instruction of setSampleDepth,and next two bytes as sample depth.
	final byte[] trigCountInst = { 0, 19 }; // Instruction of setTrigCount, and next two bytes as trigger count.
	final byte[] windowWidthInst = { 0, 20 }; // Instruction of setWindowLength, and next two bytes as window length.
	final byte[] windowStartInst = { 0, 21 }; // Instruction of setWindowStart, and next two bytes as window start.
	final byte[] demodFreqInst = { 0, 22 }; // Instruction of setDemodFreq, and next two bytes as step of DDS.
	final byte[] setGainInst = { 0, 23 }; // Instruction of setGain,and next two bytes as gain of channel I & Q.
	final byte[] demodModeInst = { 1, 1, 34, 34, 34, 34, 34, 34 }; // Instruction of setting demod mode.
	final byte[] waveModeInst = { 1, 1, 17, 17, 17, 17, 17, 17 }; // Instruction of setting wave mode.
	final byte[] forceTrigInst = { 0, 1, -18, -18, -18, -18, -18, -18 }; // Instruction of forcing trigger the ADC.
	final byte[] enableADCInst = { 0, 3, -18, -18, -18, -18, -18, -18 }; // Instruction of enabling the ADC.

	/**
	 * Create new instance of USTCADC.
	 * 
	 * @param srcMac
	 *            Source mac address of PC
	 * @param dstMac
	 *            Destination mac address of PC
	 */
	public USTCADC(String srcMac, String dstMac) {
		this.srcMac = srcMac;
		this.dstMac = dstMac;
		this.isOpen = false;
		this.id = -1;
	}

	/**
	 * @title openADC
	 * @description Start monitoring specified netcard.
	 */
	public void openADC() {
		if (!isOpen) {
			IntByReference pID = new IntByReference();
			int code = CADCLib.INSTANCE.OpenADC(pID, srcMac, dstMac);
			id = pID.getValue();
			USTCADC.checkReturn(id, code);
			setADCDstMacAddr();
			isOpen = true;
		}
	}

	/**
	 * @title closeADC
	 * @description Stop monitoring specified netcard
	 */
	public void closeADC() {
		if (isOpen) {
			int code = CADCLib.INSTANCE.CloseADC(id);
			USTCADC.checkReturn(id, code);
			id = 0;
			isOpen = false;
		}
	}

	/**
	 * @title recvData
	 * @description Recieve raw data of ADC
	 * @return The demension is [channelAmount, trigCount, sampleDepth]
	 * @throws Exception
	 *             Throw exception when receive data failed
	 */
	public short[][][] recvData() throws Exception {
		Pointer pDataI = new Memory(sampleDepth * trigCount);
		Pointer pDataQ = new Memory(sampleDepth * trigCount);
		int code = CADCLib.INSTANCE.RecvData(id, trigCount, sampleDepth, pDataI, pDataQ);
		if (code != 0) {
			Pointer errordata = new Memory(1024);
			CADCLib.INSTANCE.GetErrorMsg(id, code, errordata);
			String errormsg = errordata.getString(0L);
			throw new Exception(errormsg);
		}
		short data[][][] = new short[2][trigCount][sampleDepth];
		for (int i = 0; i < trigCount; i++) {
			for (int j = 0; j < sampleDepth; j++) {
				data[0][i][j] = (short) (pDataI.getByte(i * sampleDepth + j) & 0x00ff);
				data[1][i][j] = (short) (pDataQ.getByte(i * sampleDepth + j) & 0x00ff);
			}
		}
		return data;
	}

	/**
	 * @title recvDemo
	 * @description Recieve demod data of ADC
	 * @return The demension is [channelAmount, trigCount]
	 * @throws Exception
	 *             Throw exception when receive data failed
	 */
	public int[][] recvDemo() throws Exception {
		Pointer pDataIQ = new Memory(2 * trigCount * 4);
		int code = CADCLib.INSTANCE.RecvDemo(id, trigCount, pDataIQ);
		if (code != 0) {
			Pointer errordata = new Memory(1024);
			CADCLib.INSTANCE.GetErrorMsg(id, code, errordata);
			String errormsg = errordata.getString(0L);
			throw new Exception(errormsg);
		}
		int data[][] = new int[2][trigCount];
		for (int i = 0; i < trigCount; i++) {
			data[0][i] = pDataIQ.getInt(i * 8);
			data[1][i] = pDataIQ.getInt(i * 8 + 4);
		}
		return data;
	}

	/**
	 * @title setSampleDepth
	 * @description Set sample depth of ADC
	 * @param sampleDepth
	 *            Sample depth, maximun 20000
	 */
	public void setSampleDepth(int sampleDepth) {
		byte[] data = new byte[4];
		data[0] = sampleDepthInst[0];
		data[1] = sampleDepthInst[1];
		data[2] = (byte) (sampleDepth >> 8);
		data[3] = (byte) (sampleDepth);
		sendData(data);
		this.sampleDepth = sampleDepth;
	}

	/**
	 * @title setTrigCount
	 * @description Set recieve trigger count of ADC
	 * @param trigCount
	 *            Trigger count
	 */
	public void setTrigCount(int trigCount) {
		byte[] data = new byte[4];
		data[0] = trigCountInst[0];
		data[1] = trigCountInst[1];
		data[2] = (byte) (trigCount >> 8);
		data[3] = (byte) (trigCount);
		sendData(data);
		this.trigCount = trigCount;
	}

	/**
	 * @title setWindowWidth
	 * @description Set demod window width of ADC
	 * @param windowWidth
	 *            Demod window width
	 */
	public void setWindowWidth(int windowWidth) {
		byte[] data = new byte[4];
		data[0] = windowWidthInst[0];
		data[1] = windowWidthInst[1];
		data[2] = (byte) (windowWidth >> 8);
		data[3] = (byte) (windowWidth);
		sendData(data);
		this.windowWidth = windowWidth;
	}

	/**
	 * @title setWindowStart
	 * @description Set demod window start position of ADC
	 * @param windowStart
	 *            Demod window start
	 */
	public void setWindowStart(int windowStart) {
		byte[] data = new byte[4];
		data[0] = windowStartInst[0];
		data[1] = windowStartInst[1];
		data[2] = (byte) (windowStart >> 8);
		data[3] = (byte) (windowStart);
		sendData(data);
		this.windowStart = windowStart;
	}

	/**
	 * @title setDemodFreq
	 * @description Set demod frequency of ADC
	 * @param demodFreq
	 *            Demod frequency
	 */
	public void setDemodFreq(double demodFreq) {
		byte[] data = new byte[4];
		int step = (int) (demodFreq / sampleRate * 65536);
		data[0] = demodFreqInst[0];
		data[1] = demodFreqInst[1];
		data[2] = (byte) (step >> 8);
		data[3] = (byte) (step);
		sendData(data);
		this.demodFreq = demodFreq;
	}

	/**
	 * @title setGain
	 * @description Set channel gains of ADC
	 * @param gainI
	 *            Channel I gain
	 * @param gainQ
	 *            Channel Q gain
	 */
	public void setGain(byte gainI, byte gainQ) {
		byte[] data = new byte[4];
		data[0] = setGainInst[0];
		data[1] = setGainInst[1];
		data[2] = gainI;
		data[3] = gainQ;
		sendData(data);
	}

	/**
	 * @title forceTrigADC
	 * @description Force trigger ADC
	 */
	public void forceTrigADC() {
		byte[] data = new byte[8];
		for (int i = 0; i < 8; i++) {
			data[i] = forceTrigInst[i];
		}
		sendData(data);
	}

	/**
	 * @title enableADC
	 * @description Enable ADC to receive trigger
	 */
	public void enableADC() {
		byte[] data = new byte[8];
		for (int i = 0; i < 8; i++) {
			data[i] = enableADCInst[i];
		}
		sendData(data);
	}

	/**
	 * @title setDemodMode
	 * @description Set run mode of ADC
	 * @param isDemod
	 *            True for raw data mode, false for demod mode
	 */
	public void setDemodMode(boolean isDemod) {
		byte[] data = new byte[8];
		for (int i = 0; i < 8; i++) {
			if (isDemod)
				data[i] = demodModeInst[i];
			else
				data[i] = waveModeInst[i];
		}
		sendData(data);
		this.isDemod = isDemod;
	}

	/**
	 * @title sendData
	 * @description Send data to ADC, the instruction was define in data.
	 * @param data
	 *            The raw data to be send
	 */
	private void sendData(byte data[]) {
		Pointer pData = new Memory(data.length);
		for (int i = 0; i < data.length; i++) {
			pData.setByte(i, data[i]);
		}
		int code = CADCLib.INSTANCE.SendData(id, data.length, pData);
		USTCADC.checkReturn(id, code);
	}

	/**
	 * @title setADCDstMacAddr
	 * @description Set the ADC's destination mac address(PC's mac address).
	 */
	private void setADCDstMacAddr() {
		byte[] data = new byte[8];
		Pointer pMac = new Memory(6);
		int code = CADCLib.INSTANCE.GetMacAddress(id, 0, pMac);
		USTCADC.checkReturn(this.id, code);
		data[0] = macAddrInst[0];
		data[1] = macAddrInst[1];
		for (int i = 0; i < 6; i++) {
			data[i + 2] = pMac.getByte(i);
		}
		sendData(data);
	}

	/**
	 * @title getMacAddr
	 * @description Get the mac address
	 * @param isDst
	 *            True for ADC, false for PC
	 * @return Mac address
	 */
	public String getMacAddr(boolean isDst) {
		if (isDst) {
			return dstMac;
		} else {
			return srcMac;
		}
	}

	/**
	 * @title getDemodMode
	 * @description Get run mode of ADC
	 * @return isDemod, true for raw data mode, false for demod
	 */
	public boolean getDemodMode() {
		return isDemod;
	}

	/**
	 * @title getOpenState
	 * @description Get monitoring state
	 * @return isOpen
	 */
	public boolean getOpenState() {
		return isOpen;
	}

	/**
	 * @title getSampleDepth
	 * @description Get sample depth of ADC
	 * @return sampleDepth
	 */
	public int getSampleDepth() {
		return sampleDepth;
	}

	/**
	 * @title getTrigCount
	 * @description Get recieve trigger count of ADC.
	 * @return trigCount
	 */
	public int getTrigCount() {
		return trigCount;
	}

	/**
	 * @title getWindowWidth
	 * @description Get demod window width of ADC.
	 * @return windowWidth
	 */
	public int getWindowWidth() {
		return windowWidth;
	}

	/**
	 * @title getWindowStart
	 * @description Get demod window start position of ADC.
	 * @return windowStart
	 */
	public int getWindowStart() {
		return windowStart;
	}

	/**
	 * @title getDemodFreq
	 * @description Get demod frequency of ADC.
	 * @return demodFreq
	 */
	public double getDemodFreq() {
		return demodFreq;
	}

	/**
	 * @title getSampleRate
	 * @description Get sample rate of ADC.
	 * @return sampleRate
	 */
	public double getSampleRate() {
		return sampleRate;
	}

	/**
	 * @title getDriverInfo
	 * @description Get dynamic link library information. @return, the version
	 *              information of dll
	 * @return The dll information
	 */
	public static String getDriverInfo() {
		Pointer pData = new Memory(1024);
		int code = CADCLib.INSTANCE.GetSoftInformation(pData);
		USTCADC.checkReturn(code);
		String info = pData.getString(0L);
		return info;
	}

	/**
	 * @title checkReturn
	 * @description Check the return state of ADC.
	 * @param code
	 *            The error code returned by other function
	 */
	public static void checkReturn(int code) {
		USTCADC.checkReturn(0, code);
	}

	/**
	 * @title checkReturn
	 * @description Check the return state of ADC
	 * @param id
	 *            ID of ADC
	 * @param code
	 *            The error code returned by other function
	 */
	public static void checkReturn(int id, int code) {
		if (code != 0) {
			Pointer errordata = new Memory(1024);
			CADCLib.INSTANCE.GetErrorMsg(id, code, errordata);
			String errormsg = errordata.getString(0L);
			try {
				throw new Exception(errormsg);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

}
