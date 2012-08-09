/*
     File: GLSpriteAppDelegate.m
 Abstract: The UIApplication  delegate class which is  the central controller of
 the application.
 
  Version: 1.9
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

#import "GLSpriteAppDelegate.h"
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
        jstring         str_message             = (*self.env)->NewStringUTF (self.env, [message cStringUsingEncoding: NSUTF8StringEncoding]);

        jmethodID       classID_StellaSDKSample     = [self classIDFromName: @"com/yourcompany/sdkfeatures/StellaSDKSample"];
        jmethodID       methodID_sendMessage        = (*self.env)->GetStaticMethodID (self.env, classID_StellaSDKSample, "sendMessage", "(Ljava/lang/String;)V");
    
        if (! methodID_sendMessage) {
                NSLog (@"failed to find jmethod: %s", "sendMessage");
        }

        (*self.env)->CallStaticObjectMethod (self.env, classID_StellaSDKSample, methodID_sendMessage, str_message);
        (*self.env)->DeleteLocalRef (self.env, str_message);
}

- (void) callbackMessage: (NSString *) message
{
        NSLog (@"Got %@", message);
}

@end


void Java_com_yourcompany_sdkfeatures_StellaSDKSample_nativeCallbackMessage (JNIEnv * env, jobject thiz, jstring str_message)
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




@implementation GLSpriteAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
#if defined (__STELLA_VERSION_MAX_ALLOWED)
	window      = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	glView      = [[EAGLView alloc] initWithFrame: window.frame];

	window.backgroundColor      = [UIColor whiteColor]; 
	[window addSubview: glView];
	[window makeKeyAndVisible];

#endif

#if defined (__STELLA_VERSION_MAX_ALLOWED) && defined (__STELLA_NANDROID)
    [[JNIHelper sharedHelper] sendMessageToJava: @"message from Objective-C"];
    // NSLog (@"jni:%d", [JNIHelper sharedHelper]);
#endif


	[glView startAnimation];
}

- (void) applicationWillResignActive:(UIApplication *)application
{
	[glView stopAnimation];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
	[glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
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
