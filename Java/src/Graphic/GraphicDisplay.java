package Graphic;

import javax.swing.*;
import java.util.ArrayList;
import com.ericsson.otp.erlang.*;
import java.lang.System;

import Main.Main;
import Communication.JavaErlangCommunication;

/**
 * The GraphicDisplay class of the program, the will draw the graphics.
 * @author Project Snowfox
 */

public class GraphicDisplay extends JPanel
{
	private static JavaErlangCommunication javaErlangCommunicator = Main.javaErlangCommunicator;
	private static JFrame simulation;
	private static ImageComponents imageComponent = null;
	private static ArrayList<Unit> unitList;
	public static int xBound;
	public static int yBound;
	public static final int winX = 0;
	public static final int winY = 0;
	private static long frequency = 10;

	/**
	 * Constructor for the GraphicDisplay class.
	 */
	public GraphicDisplay() {
	}


	/**
	 * Start running the simulation.
	 * @throws InterruptedException thrown when a thread is waiting, sleeping, or otherwise occupied, and the thread is interrupted, either before or during the activity.
	 * @throws OtpErlangRangeException thrown when an attempt is made to create an Erlang term with data that is out of range for the term in question.
	 */
	public static void runSimulation() throws InterruptedException, OtpErlangRangeException {
		createUnitGraphics();
		imageComponent.validate();
		imageComponent.repaint();
		long startTime, stopTime, finishedTime, sleep, zero, second;
		zero = 0;
		second = 1000;
		while(true) {
			startTime = System.currentTimeMillis();
			ArrayList erlangList = javaErlangCommunicator.recievePos();
			if(erlangList == null) {
				System.out.println("Simulation done.");
				break;
			}
			updateUnitGraphics(erlangList);
			imageComponent.validate();
			imageComponent.repaint();
			stopTime = System.currentTimeMillis();
			finishedTime = stopTime - startTime;
			sleep = Math.max(((second/frequency)-finishedTime), zero);
			Thread.sleep(sleep);
		}
	}


	/**
	 * Checks if a coordination is out of bound.
	 * @param xpos x-position as a int.
	 * @param ypos y-position as a int.
	 * @return true if the coordination is out of bounds, otherwise returns false.
	 */
	public static boolean isOutOfBounds(int xpos, int ypos) {
		return xpos < 0 || xpos > xBound || ypos < 0 || ypos > yBound;
	}


	/**
	 * Starting the GUI.
	 * @throws OtpErlangRangeException thrown when an attempt is made to create an Erlang term with data that is out of range for the term in question.
	 */
	public static void initializeGUI() throws OtpErlangRangeException {
		while(imageComponent == null){
			imageComponent = new ImageComponents(winX, winY);
		}
		imageComponent.setImage(javaErlangCommunicator.getMapImage());
		xBound     = imageComponent.getWidth();
		yBound     = imageComponent.getHeight();
		imageComponent.setSize(xBound, yBound);
		createUnitGraphics();
	}


	/**
	 * Creates the Units for the simulation.
	 * @throws OtpErlangRangeException thrown when an attempt is made to create an Erlang term with data that is out of range for the term in question.
	 */
	public static void createUnitGraphics() throws OtpErlangRangeException {
		int x,y,sickness;
		OtpErlangPid PID;
		ArrayList erlangList = null;
		while(erlangList == null) {
			erlangList = javaErlangCommunicator.recievePos();
			//Wait for communication.
		}
		for(int i = 0; i < erlangList.size(); i++) {
			ArrayList unit = (ArrayList) erlangList.get(i);
			y = (Integer) unit.get(3);
			x = (Integer) unit.get(2);
			sickness = (Integer) unit.get(1);
			PID = (OtpErlangPid) unit.get(0);
			Unit person = new Unit(PID, sickness, x, y);
			imageComponent.addUnit(person);
		}
	}


	/**
	 * Updating the unitList position and status.
	 * @param erlangList a list with a Units' position, status and PID.
	 * @throws OtpErlangRangeException thrown when an attempt is made to create an Erlang term with data that is out of range for the term in question.
	 */
	public static void updateUnitGraphics(ArrayList erlangList) throws OtpErlangRangeException {
		int x,y,sickness;
		OtpErlangPid PID;
		ArrayList<Unit> updateList = new ArrayList<Unit>();
		for(int i = 0; i < erlangList.size(); i++) {
			ArrayList unit = (ArrayList) erlangList.get(i);
			y = (Integer) unit.get(3);
			x = (Integer) unit.get(2);
			sickness = (Integer) unit.get(1);
			PID = (OtpErlangPid) unit.get(0);
			Unit person = new Unit(PID, sickness, x, y);
			updateList.add(person);
		}
		imageComponent.setUnitList(updateList);
	}


	/**
	 * Displaying the GUI.
	 * @throws OtpErlangRangeException thrown when an attempt is made to create an Erlang term with data that is out of range for the term in question.
	 */
	public static void createAndShowGUI() throws OtpErlangRangeException {
		initializeGUI();
		JFrame frame = new JFrame("Project Snowfox");
		frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		frame.getContentPane().add(imageComponent);
		//frame.setSize(xBound, yBound);
		frame.pack();
		frame.setVisible(true);
	}
}
