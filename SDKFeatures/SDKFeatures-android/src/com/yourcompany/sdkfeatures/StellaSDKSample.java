package com.yourcompany.sdkfeatures;

import org.stella.lib.StellaNativeActivity;

import android.app.NativeActivity;
import android.util.Log;


public class StellaSDKSample
{
        /* initialisers */
        static StellaSDKSample      _sharedSDKSample;
        private static StellaSDKSample sharedSDKSample ()
        {
                if (_sharedSDKSample == null) {
                        _sharedSDKSample  = new StellaSDKSample (StellaNativeActivity.sharedNativeActivity ());
                }
        
                return _sharedSDKSample;
        }

        private NativeActivity          _nativeActivity;        
        private StellaSDKSample (NativeActivity nativeActivity)
        {
                _nativeActivity     = nativeActivity;
        }


        /* JNI interface */
        public static void sendMessage (String message) 
        {
                sharedSDKSample ()._sendMessage (message);
        }


        private static native void nativeCallbackMessage (String message);
        private void _sendMessage (final String message) 
        {
                _nativeActivity.runOnUiThread (new Runnable () {
                        @Override
                        public void run () {
                                Log.v ("StellaSDKSample", "Got "+ message);
                                nativeCallbackMessage ("message from Java");
                        }
                });
        } 


}
