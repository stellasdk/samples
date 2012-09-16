/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import "Common.h"

@implementation Common

- (id) init
{
        self    = [super init];
        if (! self)     return nil;

        /* customised initialisation */

        return self;
}

- (void) dealloc
{
        /* customised deallocation */

        [super dealloc];
}

@end