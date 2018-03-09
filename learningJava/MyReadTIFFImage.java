import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.io.*;
import javax.imageio.*;
import javax.swing.*;
import java.nio.file.*;

/** Open an image file and display it*/

public class MyReadTIFFImage{
	private BufferedImage img;
	String inputFile = "C:\\Users\\amarb\\Documents\\GitHub\\learningJava\\images\\laklabgithub.jpg";
	
	public void RdImage(){
		try{File newf = new File(inputFile);
			img = ImageIO.read(newf);
			String[] strarr = img.getPropertyNames();
			if (strarr == null){
				System.out.println("null output from property");
			}else{
				printInfo(Integer.toString(strarr.length));
			}
			int cellWidth = img.getWidth(null);
			int cellHeight = img.getHeight(null);
			
		}catch(IOException e){
		}
	}
	
	
	
	public void printInfo(String prnstr){
		//int inputLength = prnstr.length;
		//for(int idx=0;idx<inputLength;idx++){
			System.out.println(prnstr);
		//}
	}
	
	
	public static void main(String[] args){
		
	}
	
}