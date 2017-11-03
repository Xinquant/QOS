/**
* @project USTCADDA
* @title USTCDAC.java
* @package ustcdac
* @description The control interface of DAC
* @author GuoCheng
* @email fortune@mail.ustc.edu.cn
* @date 2017.10.16
* @version V1.0
*/

package ustcdac;

import com.sun.jna.ptr.IntByReference;
import com.sun.jna.platform.win32.WinDef.UINTByReference;
import com.sun.jna.platform.win32.WinDef.UINT;
import com.sun.jna.platform.win32.WinDef.USHORT;
import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import ustcdac.CDACLib;

/**
 * @className USTCDAC
 * @description The control interface of DAC
 * @date 2017.10.17
 */
public class USTCDAC {
	/**
	 * @fields daName : The dac's name
	 */
	public String daName;
	/**
	 * @fields id : The id of opened dac
	 */
	private UINT id;
	/**
	 * @fields ip : The ip address of DAC
	 */
	private String ip;
	/**
	 * @fields port : The serve port of DAC
	 */
	private USHORT port;
	/**
	 * @fields isOpen : The open state of DAC
	 */
	private boolean isOpen;
	/**
	 * @fields isBlock : The DAC run mode, true for block mode, false for unblock
	 *         mode
	 */
	private boolean isBlock;

	/**
	 * @fields sampleRate : Sample rate of DAC
	 */
	public final double sampleRate = 2e9;
	/**
	 * @fields channelAmount : Channel amount of DAC
	 */
	public final int channelAmount = 4;

	final int WRITEMEMINST = 0x00000004;
	final int STARTSTOPINST = 0x00000405;
	final int SETLOOPINST = 0x00000905;
	final int SETBROADCAST = 0x00001305;
	final int SENDCMDINST = 0x00001805;
	final int INITBOARDINST = 0x00001A05;
	final int SETDEFVOLTINST = 0x00001B05;
	final int READAD9136C1 = 0x00001C05;
	final int READAD9136C2 = 0x00001D05;
	final int POWERONDACINST = 0x00001E05;
	final int CLEARTRIGINST = 0x00001F05;
	final int CONFIGEERPOM = 0x00002005;

	final int SETTOTALCNTCMD = 1;
	final int SETDACSTARTCMD = 2;
	final int SETDACSTOPCMD = 3;
	final int SETTRIGSTARTCMD = 4;
	final int SETTRIGSTOPCMD = 5;
	final int SETISMASTERCMD = 6;
	final int SETTRIGSELCMD = 7;
	final int SENDINTTRIGCMD = 8;
	final int SETTRIGINTCMD = 9;
	final int SETTRIGCOUNTCMD = 10;
	final int INITBOARDCMD = 11;

	/**
	 * @className InstructionPara
	 * @description The data struct of instruction
	 * @date 2017.10.17
	 */
	public class InstructionPara {
		public int functype;
		public int instruction;
		public int para1;
		public int para2;
	};

	/**
	 * @className ReturnPara
	 * @description the data struct of return data
	 * @date 2017.10.17
	 */
	public class ReturnPara {
		public int retData;
		public int retState;
		public short[] data;
	}

	/**
	 * Create new instance of USTCDAC.
	 * 
	 * @param ip
	 *            DAC ip address
	 * @param port
	 *            DAC serve port
	 */
	public USTCDAC(String ip, short port) {
		this.ip = ip;
		this.port = new USHORT(port);
	}

	/**
	 * Create new instance of USTCDAC.
	 * 
	 * @param ip
	 *            DAC ip address
	 */
	public USTCDAC(String ip) {
		this.ip = ip;
		this.port = new USHORT(80);
	}

	/**
	 * @title writeInstruction
	 * @description Write instruction to DAC
	 * @param instruction
	 *            Instruction defined by DAC
	 * @param para1
	 *            First parameter
	 * @param para2
	 *            Second parameter
	 */
	private void writeInstruction(int instruction, int para1, int para2) {
		int code = CDACLib.INSTANCE.WriteInstruction(id, instruction, para1, para2);
		checkReturn(code);
		block();
	}

	/**
	 * @title formatWave
	 * @description Format int data to adapted to network byte order
	 * @param wave
	 *            The raw wave data
	 * @return The formated wave data
	 */
	private short[] formatWave(int[] wave) {
		int waveLen = wave.length;
		if (wave.length % 8 != 0) {
			waveLen = ((wave.length >> 3) + 1) << 3;
		}
		short[] newWave = new short[waveLen];
		for (int i = 1; i < wave.length; i += 2) {
			newWave[i] = (short) (wave[i - 1] & 0x0000ffff);
			newWave[i - 1] = (short) (wave[i] & 0x0000ffff);
		}
		for (int i = wave.length; i < waveLen; i++) {
			newWave[i] = (short) (32768 & 0x00ff);
		}
		return newWave;
	}

	/**
	 * @title formatSeq
	 * @description Format long seq to adapted to network byte order
	 * @param seq
	 *            The raw seq array
	 * @return The formated seq array
	 */
	private short[] formatSeq(long[] seq) {
		short[] newSeq = new short[seq.length * 4];
		for (int i = 0; i < seq.length; i++) {
			newSeq[i * 4] = (short) ((seq[i] >> 32) & 0x000000000000ffff);
			newSeq[i * 4 + 1] = (short) ((seq[i] >> 48) & 0x000000000000ffff);
			newSeq[i * 4 + 2] = (short) ((seq[i] >> 0) & 0x000000000000ffff);
			newSeq[i * 4 + 3] = (short) ((seq[i] >> 16) & 0x000000000000ffff);
		}
		return newSeq;
	}

	/**
	 * @title writeMemory
	 * @description Write raw data to memory
	 * @param instruction
	 *            The instruction defined by DAC
	 * @param startAddr
	 *            Start address of memory
	 * @param data
	 *            The data to be write in memory
	 */
	private void writeMemory(int instruction, int startAddr, short data[]) {
		Pointer pData = new Memory(2 * data.length);
		for (int k = 0; k < data.length; k++) {
			pData.setShort(k << 1, data[k]);
		}
		int code = CDACLib.INSTANCE.WriteMemory(id, instruction, startAddr, 2 * data.length, pData);
		checkReturn(code);
		block();
	}

	/**
	 * @title openDAC
	 * @description Open connection to specified DAC
	 */
	public void openDAC() {
		if (!isOpen) {
			UINTByReference pID = new UINTByReference();
			int code = CDACLib.INSTANCE.OpenDAC(pID, ip, port);
			checkReturn(code);
			id = pID.getValue();
			isOpen = true;
		}
	}

	/**
	 * @title closeDAC
	 * @description Close connection to specified DAC
	 */
	public void closeDAC() {
		if (isOpen) {
			int code = CDACLib.INSTANCE.CloseDAC(id);
			checkReturn(code);
			id.setValue(0);
			isOpen = false;
		}
	}

	/**
	 * @title getInstruction
	 * @description Get specified instruction content
	 * @param posOffset
	 *            Offset of function stack, for example 1 for lastest function
	 * @return Struct instruction parameter
	 */
	public InstructionPara getInstruction(int posOffset) {
		IntByReference pFuncType = new IntByReference();
		IntByReference pInstruction = new IntByReference();
		IntByReference pPara1 = new IntByReference();
		IntByReference pPara2 = new IntByReference();
		int code = CDACLib.INSTANCE.GetFunctionType(id, posOffset, pFuncType, pInstruction, pPara1, pPara2);
		checkReturn(code);
		InstructionPara funcType = new InstructionPara();
		funcType.functype = pFuncType.getValue();
		funcType.instruction = pInstruction.getValue();
		funcType.para1 = pPara1.getValue();
		funcType.para2 = pPara2.getValue();
		return funcType;
	}

	/**
	 * @title getReturn
	 * @description Get specified return value
	 * @param posOffset
	 *            Offset of function stack, for example 1 for lastest function
	 * @return Struct return parameter
	 */
	public ReturnPara getReturn(int posOffset) {
		IntByReference pRetData = new IntByReference(0);
		IntByReference pRetState = new IntByReference(-1);
		Pointer pData = null;
		ReturnPara returnPara = new ReturnPara();
		InstructionPara instructionPara = new InstructionPara();
		instructionPara = getInstruction(posOffset);
		if (instructionPara.functype != 1) {
			pData = new Memory(instructionPara.para2);
		}
		int code = CDACLib.INSTANCE.GetReturn(id, posOffset, pRetState, pRetData, pData);
		checkReturn(code);
		returnPara.retData = pRetData.getValue();
		returnPara.retState = pRetState.getValue();
		if (instructionPara.functype != 1) {
			returnPara.data = pData.getShortArray(0, instructionPara.para2 >> 1);
		}
		return returnPara;
	}

	/**
	 * @title writeReg
	 * @description Write register on DAC board
	 * @param bank
	 *            The register bank
	 * @param addr
	 *            The register address
	 * @param data
	 *            The register data
	 */
	public void writeReg(int bank, int addr, int data) {
		int cmd = bank << 8 + 2;
		writeInstruction(cmd, addr, data);
	}

	/**
	 * @title readReg
	 * @description Read register on DAC board
	 * @param bank
	 *            Bank address of register
	 * @param addr
	 *            Address of register
	 * @return Register value
	 */
	public int readReg(int bank, int addr) {
		int cmd = bank << 8 + 1;
		writeInstruction(cmd, addr, 0);
		ReturnPara returnPara = getReturn(1);
		return returnPara.retData;
	}

	/**
	 * @title writeWave
	 * @description Write wave to specified channel
	 * @param channel
	 *            The channel can be 1~4
	 * @param memOffset
	 *            The offset wave point of memory
	 * @param data
	 *            The wave data
	 */
	public void writeWave(int channel, int memOffset, int[] data) {
		assert (channel <= channelAmount && channel >= 1);
		int startAddr = (((channel << 1) - 2) << 18) + (memOffset << 1);
		writeMemory(WRITEMEMINST, startAddr, formatWave(data));
	}

	/**
	 * @title writeSeq
	 * @description Write seq to specified channel
	 * @param channel
	 *            The channel can be 1~4
	 * @param memOffset
	 *            The offset seq of memory
	 * @param seq
	 *            The sequence data, each sequence has 64bits
	 */
	public void writeSeq(int channel, int memOffset, long seq[]) {
		assert (channel <= channelAmount && channel >= 1);
		int startAddr = (((channel << 1) - 1) << 18) + (memOffset << 3);
		writeMemory(WRITEMEMINST, startAddr, formatSeq(seq));
	}

	/**
	 * @title setTimeOut
	 * @description Set sending or recieving timeout
	 * @param isOut
	 *            Ture for sending timeout, false for recieving timeout
	 * @param time
	 *            The unit is second
	 */
	public void setTimeOut(boolean isOut, float time) {
		int code;
		if (isOut) {
			code = CDACLib.INSTANCE.SetTimeOut(id, 1, time);
		} else {
			code = CDACLib.INSTANCE.SetTimeOut(id, 0, time);
		}
		checkReturn(code);
	}

	/**
	 * @title block
	 * @description If isblock has been set, then block to finish all tasts
	 */
	public void block() {
		if (isBlock) {
			getReturn(1);
		}
	}

	/**
	 * @title readAD9136
	 * @description Read DAC(ad9136) chip's register
	 * @param chip
	 *            The selected chip, this can be 1~2
	 * @param addr
	 *            The register address
	 * @return The register data( low 8bits)
	 */
	public int readAD9136(int chip, int addr) {
		if (chip == 1) {
			writeInstruction(READAD9136C1, addr, 0);
		} else {
			writeInstruction(READAD9136C2, addr, 0);
		}
		ReturnPara returnPara = getReturn(1);
		return returnPara.retData;
	}

	/**
	 * @title initBoard
	 * @description Init the DAC chip
	 */
	public void initBoard() {
		writeInstruction(INITBOARDINST, INITBOARDCMD, 1 << 16);
	}

	/**
	 * @title powerOnDAC
	 * @description Power on DAC(ad9136) chip manually
	 * @param chip
	 *            The selected chip, this can be 1~2
	 * @param onOff
	 *            The on/off state of DAC
	 */
	public void powerOnDAC(int chip, boolean onOff) {
		if (onOff) {
			writeInstruction(POWERONDACINST, chip, 1);
		} else {
			writeInstruction(POWERONDACINST, chip, 0);
		}
	}

	/**
	 * @title startStop
	 * @description Start or stop channel output, each bit correspond a channel
	 * @param index
	 *            0x0f to start all channel, 0xf0 to stop all channel. for example
	 *            0x01 start channel 1 output
	 */
	public void startStop(int index) {
		writeInstruction(STARTSTOPINST, index, 0);
	}

	/**
	 * @title setLoop
	 * @description Set loop times
	 * @param ch1
	 *            Channel 1 loop times, 2 bytes
	 * @param ch2
	 *            Channel 2 loop times, 2 bytes
	 * @param ch3
	 *            Channel 3 loop times, 2 bytes
	 * @param ch4
	 *            Channel 4 loop times, 2 bytes
	 */
	public void setLoop(short ch1, short ch2, short ch3, short ch4) {
		int para1 = ((int) ch1) << 8 & ch2;
		int para2 = ((int) ch3) << 8 & ch4;
		writeInstruction(SETLOOPINST, para1, para2);
	}

	/**
	 * @title setTotalCount
	 * @description Set total counter of synchronize system
	 * @param count
	 *            Tolal count counter
	 */
	public void setTotalCount(int count) {
		writeInstruction(SENDCMDINST, SETTOTALCNTCMD, count << 16);
	}

	/**
	 * @title setDACStart
	 * @description Set DAC start counter of sychronize system
	 * @param start
	 *            DAC start counter
	 */
	public void setDACStart(int start) {
		writeInstruction(SENDCMDINST, SETDACSTARTCMD, start << 16);
	}

	/**
	 * @title setDACStop
	 * @description Set DAC stop counter of sychronize system
	 * @param stop
	 *            DAC stop counter
	 */
	public void setDACStop(int stop) {
		writeInstruction(SENDCMDINST, SETDACSTOPCMD, stop << 16);
	}

	/**
	 * @title setTrigStart
	 * @description Set trigger start counter of sychronize system
	 * @param start
	 *            Trigger start counter
	 */
	public void setTrigStart(int start) {
		writeInstruction(SENDCMDINST, SETTRIGSTARTCMD, start << 16);
	}

	/**
	 * @title setTrigStop
	 * @description Set trigger stop counter of sychronize system
	 * @param stop
	 *            Tigger stop counter
	 */
	public void setTrigStop(int stop) {
		writeInstruction(SENDCMDINST, SETTRIGSTOPCMD, stop << 16);
	}

	/**
	 * @title setIsMaster
	 * @description Set whether DAC board is master
	 * @param isMaster
	 *            True for master DAC board, false for slave board
	 */
	public void setIsMaster(boolean isMaster) {
		if (isMaster) {
			writeInstruction(SENDCMDINST, SETISMASTERCMD, 1 << 16);
		} else {
			writeInstruction(SENDCMDINST, SETISMASTERCMD, 0);
		}
	}

	/**
	 * @title setTrigSel
	 * @description Set internal trigger select source, 3 for SMA, 0 for UTP
	 * @param trigSelect
	 *            Trigger select
	 */
	public void setTrigSel(int trigSelect) {
		writeInstruction(SENDCMDINST, SETTRIGSELCMD, trigSelect << 16);
	}

	/**
	 * @title setTrigInterval
	 * @description Set trigger interval time, time = periodCount * 4e-9
	 * @param periodCount
	 *            Period count
	 */
	public void setTrigInterval(int periodCount) {
		writeInstruction(SENDCMDINST, SETTRIGINTCMD, periodCount << 12);
	}

	/**
	 * @title setTrigCount
	 * @description Set DAC board output trigger count
	 * @param trigCount
	 *            Trigger count
	 */
	public void setTrigCount(int trigCount) {
		writeInstruction(SENDCMDINST, SETTRIGCOUNTCMD, trigCount << 12);
	}

	/**
	 * @title clearTrigCount
	 * @description Clear internal trigger count counter
	 */
	public void clearTrigCount() {
		writeInstruction(CLEARTRIGINST, 0, 0);
	}

	/**
	 * @title setDefaultVolt
	 * @description Set default output voltage
	 * @param channel
	 *            DAC channel
	 * @param voltCode
	 *            Output voltage code
	 */
	public void setDefaultVolt(int channel, short voltCode) {
		assert (channel <= channelAmount && channel >= 1);
		writeInstruction(SETDEFVOLTINST, channel - 1, voltCode);
	}

	/**
	 * @title setBroadCast
	 * @description Set is broadcast and broadcast time
	 * @param isBroadCast
	 *            True for broadcast
	 * @param period
	 *            Period of broadcast
	 */
	public void setBroadCast(boolean isBroadCast, float period) {
		byte periodCount = (byte) (period * 5);
		if (isBroadCast) {
			writeInstruction(SETBROADCAST, 1, periodCount);
		} else {
			writeInstruction(SETBROADCAST, 0, periodCount);
		}
	}

	/**
	 * @title configEEPROM
	 * @description Config EEPROM instruction
	 */
	public void configEEPROM() {
		writeInstruction(CONFIGEERPOM, 0, 0);
	}

	/**
	 * @title getChipTemperature
	 * @description Get DAC chip's temperature
	 * @param chip
	 *            The selected chip, this can be 1~2
	 * @return The specified chip's temperature
	 */
	public double getChipTemperature(int chip) {
		assert (chip == 1 || chip == 2);
		int tt1 = readAD9136(chip, 0x132) & 0x000000FF;
		int tt2 = readAD9136(chip, 0x133) & 0x000000FF;
		double temp = 30 + 7.3 * ((tt2 << 8) + tt1 - 39200) / 1000.0;
		return temp;
	}

	/**
	 * @title setIsBlock
	 * @description Set run mode
	 * @param isBlock
	 *            True for block mode, false for unblock mode
	 */
	public void setIsBlock(boolean isBlock) {
		this.isBlock = isBlock;
	}

	/**
	 * @title checkReturn
	 * @description Check return state
	 * @param code
	 *            The error code returned by other function
	 */
	public static void checkReturn(int code) {
		if (code != 0) {
			Pointer errordata = new Memory(1024);
			CDACLib.INSTANCE.GetErrorMsg(code, errordata);
			String errormsg = errordata.getString(0, "GBK");
			try {
				throw new Exception(errormsg);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	/**
	 * @title getDriverInfo
	 * @description Get dynamic link library information
	 * @return The dll information
	 */
	public static String getDriverInfo() {
		Pointer pData = new Memory(1024);
		int code = CDACLib.INSTANCE.GetSoftInformation(pData);
		checkReturn(code);
		String info = pData.getString(0L);
		return info;
	}
}
