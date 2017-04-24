
import javax.swing.*;
import java.io.*;
import java.awt.*;
import java.awt.image.*;
import javax.imageio.*;


/**
 * The Unit class of the program, that will represent the people in the simulation.
 * @author Project Snowfox
 */

public class Unit extends JComponent
{
	public int PID;
	public int status;
	public int x;
	public int y;
	public static final Color INFECTED = Color.RED;
	public static final Color HEALTHY  = Color.GREEN;
	public static final Color ERROR = Color.BLUE;

	/**
	 * Constructor for a Unit.
	 * @param pid the Units' PID as a OtpErlangPid.
	 * @param sickness the sickness status as a int.
	 * @param posx the x-position of the Unit as a int.
	 * @param posy the y-position of the Unit as a int.
	 */
	public Unit(int pid, int sickness, int posx, int posy) {
		PID = pid;
		status = sickness;
		x = posx;
		y = posy;
	}

	/**
	 * Painting a Unit.
	 */
	public void paint() {
		repaint();
	}

	/**
	 * Repainting the new position and status of a Unit.
	 * @param newx the new x-position of the Unit as a int.
	 * @param newy the new y-position of the Unit as a int.
	 * @param sickness the new sickness status of the Unit as a int.
	 */
	public void moveUnit(int newx, int newy, int sickness) {
		status = sickness;
		x = newx;
		y = newy;
	}

	/**
	 * Returning the PID of a Unit.
	 * @return The PID of a Unit as a OtpErlangPid.
	 */
	public int pid()
	{
		return PID;
	}

	/*
	* Repainting a Unit, based on it's status.
	* @param g a graphic object
	 */
	@Override
	protected void paintComponent(Graphics g) {
		super.paintComponent(g);
		if(status == 1) {
			g.setColor(INFECTED);
		}
		else if(status == 0) {
			g.setColor(HEALTHY);
		}
		else {
			g.setColor(ERROR);
		}
		g.fillOval(x,y,5,5);
	}
}


