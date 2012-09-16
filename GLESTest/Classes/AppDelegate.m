/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import "AppDelegate.h"
#import "EAGLView.h"


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
}

- (void) applicationWillResignActive: (UIApplication *) application
{
	    [glView stopAnimation];
}

- (void) applicationDidBecomeActive: (UIApplication *) application
{
	    [glView startAnimation];
}

- (void)applicationWillTerminate: (UIApplication *) application
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
