/*
 * Copyright (c) 2011 Yeecco Limited
 */

#if defined (__STELLA_VERSION_MAX_ALLOWED)
#import <StellaAnimation/StellaAnimation.h>
#else
#import <QuartzCore/QuartzCore.h>
#endif
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"


@implementation EAGLView

@synthesize     animating;
@dynamic        animationFrameInterval;


+ (Class) layerClass
{
	    return [CAEAGLLayer class];
}


- (id) initWithFrame: (CGRect) frame
{
        self    = [super initWithFrame: frame];
        if (! self)     return nil;

		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		context     = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
			[self release];
			return nil;
		}
		
		animating               = FALSE;

		animationFrameInterval  = 1;
		displayLink             = nil;

		
		[self setupView];
		[self drawView];

	
	    return self;
}

- (void) dealloc
{
	    if([EAGLContext currentContext] == context) {
		        [EAGLContext setCurrentContext: nil];
	    }
	
	    [context release];
	    context = nil;
	
	    [super dealloc];
}


- (void) layoutSubviews
{
    	[EAGLContext setCurrentContext:context];
    	[self destroyFramebuffer];
    	[self createFramebuffer];
    	[self drawView];
}


- (BOOL) createFramebuffer
{
    	glGenFramebuffersOES (1, &viewFramebuffer);
    	glGenRenderbuffersOES (1, &viewRenderbuffer);
	
    	glBindFramebufferOES (GL_FRAMEBUFFER_OES, viewFramebuffer);
    	glBindRenderbufferOES (GL_RENDERBUFFER_OES, viewRenderbuffer);
    	[context renderbufferStorage: GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
    	glFramebufferRenderbufferOES (GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
    	glGetRenderbufferParameterivOES (GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    	glGetRenderbufferParameterivOES (GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    	if (glCheckFramebufferStatusOES (GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        		return NO;
    	}
	
    	return YES;
}


- (void)destroyFramebuffer
{
    	glDeleteFramebuffersOES (1, &viewFramebuffer);
    	viewFramebuffer = 0;
    	glDeleteRenderbuffersOES (1, &viewRenderbuffer);
    	viewRenderbuffer = 0;
	
    	if(depthRenderbuffer) {
        		glDeleteRenderbuffersOES (1, &depthRenderbuffer);
        		depthRenderbuffer = 0;
    	}
}


- (NSInteger) animationFrameInterval
{
	    return animationFrameInterval;
}

- (void) setAnimationFrameInterval: (NSInteger) frameInterval
{
    	if (frameInterval >= 1)
    	{
    		    animationFrameInterval      = frameInterval;
		
        		if (animating) {
        			[self stopAnimation];
        			[self startAnimation];
        		}
    	}
}

- (void) startAnimation
{
        if (animating)      return;


#if defined (__STELLA_VERSION_MAX_ALLOWED)
		displayLink = [NSClassFromString(@"SADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)];
#else
		displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)];
#endif

		[displayLink setFrameInterval: animationFrameInterval];
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
		
		animating = TRUE;

}

- (void) stopAnimation
{
        if (!animating)     return;

		[displayLink invalidate];
		displayLink = nil;

		animating = FALSE;
}




- (void) setupView
{
	    glViewport (0, 0, backingWidth, backingHeight);

        glClearColor (81.0f/255.0f, 147.0f/255.0f, 207.0f/255.0f, 1.0f);
}

- (void) drawView
{
    	[EAGLContext setCurrentContext: context];
	
    	glBindFramebufferOES (GL_FRAMEBUFFER_OES, viewFramebuffer);

    #if defined (__STELLA_VERSION_MAX_ALLOWED) && defined (__STELLA_NANDROID)
        glViewport (0, 0, backingWidth, backingHeight);
    #endif

    	glClear (GL_COLOR_BUFFER_BIT);

	
    	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
}



@end
