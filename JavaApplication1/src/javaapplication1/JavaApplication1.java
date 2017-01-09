/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javaapplication1;

/**
 *
 * @author MIT
 */
import java.io.File;
import org.sikuli.script.*;
public class JavaApplication1
{

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args)
    {
        // TODO code application logic here
        System.out.println("hello world");
        try
        {
            Screen s = new Screen();
            //App.open("C:\\Program Files\\Scats6\\TrafficReporter\\ScatsTR.exe");
            s.doubleClick("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\AppOpen.png");
            Thread.sleep(4000);
            App.focus("ScatsTR.exe");
            //resizeApp("ScatsTR.exe",1280,1024);
    
            s.click("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\StrtMonitor.png");
            File baseDir = new File("C:\\Documents and Settings\\MIT\\Desktop\\Glide data2013Run1");
            File [] baseDirectoryListing = baseDir.listFiles();
            int rcNo =0;
            int numOfModules[] = {45,15,49,54,54,46};
            int moduleNo =0;
            for(int k=0 ;k<baseDirectoryListing.length;k++)
            {
                String dirName = baseDirectoryListing[k].getName();
                if(dirName.startsWith("RC"))
                {
                    File dir = new File("C:\\Documents and Settings\\MIT\\Desktop\\Glide data2013Run1\\"+dirName+"\\SM");
                    File [] directoryListing = dir.listFiles();
                    for(int j = 0 ; j<directoryListing.length ;j++)
                    {
                        File child = directoryListing[j];
                        try
                        {
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\FolderOpen.png"));
                            App.focus("ScatsTR.exe");
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\StartDate.png").below(150));
                            Thread.sleep(3000);
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Preview.png"));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\FileName.png").right(100));
                            s.type(child.getAbsolutePath());
                            String fileName = child.getName();
                            String last2letters = fileName.substring(fileName.length()-5,fileName.length()-3);
                            System.out.println(last2letters);
                            s.click("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Open.png");
                            Thread.sleep(3000);
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(80));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(110));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(140));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(170));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(230));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(260));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(290));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(320));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(350));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(380));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(420));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(450));
                            
                            for(int i=0;i<numOfModules[moduleNo]-12;i++)
                            //while(true)
                            {
                                s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Down.png"));
                                s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Str.png").below(450));
                                //Region downScroll = s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\DownScroll.png");
                               // Region scroll = s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Scroller_1.png");
                                //s.click(scroll);
                               /* System.out.println(downScroll.y);
                                System.out.println(scroll.y);
                                System.out.println(downScroll.y - scroll.y);
                                if(downScroll.y - scroll.y <30)
                                {
                                    break;
                                }*/
                                /*boolean foundEndScroll = true;
                                try
                                {
                                    Region t = s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\EndScroll.png");
                                    if(t != null)
                                    {
                                        break;
                                    }
                                }
                                catch(Exception ex)
                                {
                                    foundEndScroll = false;
                                }
                                if(foundEndScroll)
                                {
                                   break; 
                                }*/
                            }
                            s.click("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Text.png");
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\OKFile.png"));
                            boolean foundWait = false;

                            foundWait = false;
                            Thread.sleep(360000);
                            //Thread.sleep(5000);
                            while(foundWait == false)
                            {
                                foundWait = true;
                                try
                                {
                                    App.focus("ScatsTR.exe");
                                    s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\SaveFloppy.png"));
                                    s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Save.png");
                                }
                                catch(Exception e)
                                {
                                    foundWait = false;
                                    Thread.sleep(20000);
                                }                         
                            }
                            Thread.sleep(2000);
                            s.type("C:\\Documents and Settings\\MIT\\Desktop\\Glide data2013Run1\\OP "+dirName+"\\SM\\SM_201308"+last2letters+".txt");
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\FileName.png").right(670));
                            Thread.sleep(10000);
                            System.out.println("done"); 
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\Window.png"));
                            s.click(s.find("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\CloseAll.png"));
                            App.close("ScatsTR.exe");
                            Thread.sleep(7000);
                            s.doubleClick("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\AppOpen.png");
                            Thread.sleep(10000);
                            App.focus("ScatsTR.exe");
                            s.click("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\StrtMonitor.png");
                        }
                        catch(Exception exloop)
                        {
                            j--;
                            App.close("ScatsTR.exe");
                            Thread.sleep(10000);
                            s.doubleClick("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\AppOpen.png");
                            Thread.sleep(10000);
                            App.focus("ScatsTR.exe");
                            s.click("C:\\Documents and Settings\\MIT\\Desktop\\Checkboxes\\StrtMonitor.png");
                        }
                    }
                    moduleNo++;
                }               
            }            
        }
        
        catch(Exception ex)
        {
            System.out.println(ex);
        }
        
    }
    
}
