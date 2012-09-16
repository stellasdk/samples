package com.yourcompany.GLESTest;

import org.stella.lib.StellaNativeActivity;

import android.app.Dialog;
import android.net.Uri;
import android.widget.VideoView;

public class MainActivity extends StellaNativeActivity
{
        static 
        {

                System.loadLibrary ("freetype");
                System.loadLibrary ("Foundation");
                System.loadLibrary ("StellaGraphics");
                System.loadLibrary ("StellaKit");
                System.loadLibrary ("GLESTest");


        }
}