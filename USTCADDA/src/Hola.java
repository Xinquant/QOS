
/**
 * @project USTCADDA
 * @title Hola.java
 * @package 
 * @description Show version information
 * @author GuoCheng
 * @email fortune@mail.ustc.edu.cn
 * @date 2017.10.17
 * @version v1.0
 */
import ustcadc.USTCADC;
import ustcdac.USTCDAC;
/**
 * @className Hola
 * @description TODO
 * @date 2017.10.17
 */
public class Hola {
	public static void main(String args[])
	{
		System.out.println("Java interface class version v1.0 @2017/10/17");
		String info = USTCDAC.getDriverInfo();
		System.out.println(info);
		info = USTCADC.getDriverInfo();
		System.out.println(info);
	}
}
