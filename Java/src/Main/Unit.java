package Main;

import com.sun.corba.se.impl.orbutil.graph.Graph;

import javax.swing.*;
import java.io.*;
import java.awt.*;
import javax.imageio.*;


public class Unit extends JComponent
{
	public int PID;
	public int status;
	public int x;
	public int y;
	public Graphics g;
  //Hashmap senare?

	public Unit(int pid, int sickness, int posx, int posy) {
		PID = pid;
		status = sickness;
		x = posx;
		y = posy;
		paint(g);
	}

	public void moveUnit(int newx, int newy, int sickness) {
		status = sickness;
		x = newx;
		y = newy;
		repaint();
	}

	public int pid()
	{
		return PID;
	}

	@Override
	protected void paintComponent(Graphics g) {
		super.paintComponent(g);
		Graphics2D g2d = (Graphics2D) g;
		if(status == 0) {
			g.setColor(new Color(000,255,000));
		}
		else {
			g.setColor(new Color(255,000,000));
		}
		g.fillOval(x,y,3,3);
		repaint();
	}
}


