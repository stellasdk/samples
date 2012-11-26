/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import "AppDelegate.h"
#import "EAGLView.h"

#if defined (__STELLA_VERSION_MAX_ALLOWED) && defined (__STELLA_NANDROID)
#import <StellaKit/JNIHelper.h>

@interface JNIHelper (Hello)

- (void) sendMessageToJava: (NSString *) message;
- (void) callbackMessage: (NSString *) message;

@end

@implementation JNIHelper (Hello)

- (void) sendMessageToJava: (NSString *) message
{
        jstring         str_message                 = (*self.env)->NewStringUTF (self.env, [message cStringUsingEncoding: NSUTF8StringEncoding]);

        jmethodID       classID_StellaSDKSample     = [self classIDFromName: @"com/yourcompany/JNITest/StellaSDKSample"];
        jmethodID       methodID_sendMessage        = (*self.env)->GetStaticMethodID (self.env, classID_StellaSDKSample, "sendMessage", "(Ljava/lang/String;)V");

        if (! methodID_sendMessage) {
                NSLog (@"failed to find jmethod: %s", "sendMessage");
        }

        (*self.env)->CallStaticObjectMethod (self.env, classID_StellaSDKSample, methodID_sendMessage, str_message);
        (*self.env)->DeleteLocalRef (self.env, str_message);
}

- (void) callbackMessage: (NSString *) message
{
        UIAlertView * alertView     = [ [UIAlertView alloc] initWithTitle: @"JNITest"
                                                                  message: message
                                                                 delegate: self
                                                        cancelButtonTitle: @"OK"
                                                        otherButtonTitles: nil, nil ];

        [alertView show];
        [alertView release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
        NSLog (@"Alert view clicked");
}
@end

void Java_com_yourcompany_JNITest_StellaSDKSample_nativeCallbackMessage (JNIEnv * env, jobject thiz, jstring str_message)
{
        jboolean        is_copy;
        const char    * utf_message     = (*env)->GetStringUTFChars (env, str_message, &is_copy);
        NSString      * message         = [NSString stringWithCString: utf_message encoding: NSUTF8StringEncoding];

        if (is_copy) {
                (*env)->ReleaseStringUTFChars (env, str_message, utf_message);
        }

        [[JNIHelper sharedHelper] performSelectorOnMainThread: @selector (callbackMessage:) withObject: message waitUntilDone: NO];
}
#endif

@implementation AppDelegate

@synthesize window;

- (void) applicationDidFinishLaunching: (UIApplication *) application
{
        window      = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        glView      = [[EAGLView alloc] initWithFrame: window.frame];

        window.backgroundColor      = [UIColor whiteColor];
        [window addSubview: glView];
        [window makeKeyAndVisible];

        [glView startAnimation];

    #if defined (__STELLA_VERSION_MAX_ALLOWED) && defined (__STELLA_NANDROID)
        [[JNIHelper sharedHelper] sendMessageToJava: @"message from Objective-C"];
    #endif
}

- (void) applicationWillResignActive: (UIApplication *) application
{
        [glView stopAnimation];
}

- (void) applicationDidBecomeActive: (UIApplication *) application
{
        [glView startAnimation];
}

- (void) applicationWillTerminate: (UIApplication *) application
{
        [glView stopAnimation];
}

- (void) dealloc
{
        [window release];
        [glView release];

        [super dealloc];
}

@end
