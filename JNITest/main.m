/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import <UIKit/UIKit.h>

int main (int argc, char *argv[])
{
        NSAutoreleasePool     * pool    = [[NSAutoreleasePool alloc] init];
        
        int retval  = UIApplicationMain (argc, argv, nil, @"AppDelegate");
        
        [pool release];
        
        return retval;
}
