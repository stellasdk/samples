/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import <UIKit/UIKit.h>

@class EAGLView;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
        IBOutlet UIWindow     * window;
        IBOutlet EAGLView     * glView;
}

@property(nonatomic, retain) UIWindow      * window;

- (void) applicationDidFinishLaunching: (UIApplication *) application;
- (void) applicationWillResignActive: (UIApplication *) application;
- (void) applicationDidBecomeActive: (UIApplication *) application;
- (void) applicationWillTerminate: (UIApplication *) application;

- (void) dealloc;

@end

