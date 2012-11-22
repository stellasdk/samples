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

@synthesize     delegate;
@synthesize     shine;
@synthesize     googleplayEnabled;
@synthesize     tapjoyEnabled;
@synthesize     amazonappsEnabled;
@synthesize     chartboostEnabled;
@synthesize     samsungappsEnabled;
@synthesize     adcolonyEnabled;

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
        eaglLayer.drawableProperties    =
        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

        context     = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES1];

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


- (void) destroyFramebuffer
{
        glDeleteFramebuffersOES (1, &viewFramebuffer);
        viewFramebuffer = 0;
        glDeleteRenderbuffersOES (1, &viewRenderbuffer);
        viewRenderbuffer = 0;

        if (depthRenderbuffer) {
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
        if (frameInterval < 1)      return;

        animationFrameInterval      = frameInterval;

        if (animating) {
                [self stopAnimation];
                [self startAnimation];
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



GLfloat     spriteVertices[]      = {
        -0.5f,       0.5f,  /* top left */
         0.5f,       0.5f,  /* top right */
        -0.5f,      -0.5f,  /* bottom left */
         0.5f,      -0.5f,  /* botton right */
};

GLfloat     spriteTexCoords[]     = {
        0.0f,      0.0f,    /* bottom left */
        1.0f,      0.0f,    /* bottom right */
        0.0f,      1.0f,    /* top left */
        1.0f,      1.0f,    /* top right */
};


- (GLuint) textureFromImageNamed: (NSString *) name
{
        CGImageRef          spriteImage;
        CGContextRef        spriteContext;
        GLubyte           * spriteData;
        size_t              width;
        size_t              height;

        spriteImage     = [UIImage imageNamed: name].CGImage;

        if (! spriteImage) {
                NSLog (@"failed to read sprite image");
                return 0;
        }

        // Get the width and height of the image
        width       = CGImageGetWidth (spriteImage);
        height      = CGImageGetHeight (spriteImage);


        GLuint      spriteTexture;

        spriteData = (GLubyte *) calloc (width * height * 4, sizeof (GLubyte));
        // Uses the bitmap creation function provided by the Core Graphics framework.
        spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
        // After you create the context, you can draw the sprite image to the context.
        CGContextDrawImage (spriteContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), spriteImage);
        // You don't need the context at this point, so you need to release it to avoid memory leaks.
        CGContextRelease (spriteContext);

        // Use OpenGL ES to generate a name for the texture.
        glGenTextures (1, &spriteTexture);
        glBindTexture (GL_TEXTURE_2D, spriteTexture);
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

        free (spriteData);

        return spriteTexture;
}

- (void) loadSpriteVerticesForFrame: (CGRect) frame
{
        spriteVertices[0]   = frame.origin.x * 2.0f / (GLfloat) backingWidth - 1.0f;
        spriteVertices[1]   = 1.0f - frame.origin.y * 2.0f / (GLfloat) backingHeight;

        spriteVertices[2]   = (frame.origin.x+frame.size.width) * 2.0f / (GLfloat) backingWidth - 1.0f;
        spriteVertices[3]   = spriteVertices[1];

        spriteVertices[4]   = spriteVertices[0];
        spriteVertices[5]   = 1.0f - (frame.origin.y+frame.size.height) * 2.0f / (GLfloat) backingHeight;

        spriteVertices[6]   = spriteVertices[2];
        spriteVertices[7]   = spriteVertices[5];

        glVertexPointer (2, GL_FLOAT, 0, spriteVertices);
}

- (void) setupView
{
        glViewport (0, 0, backingWidth, backingHeight);

        glMatrixMode (GL_MODELVIEW);
        glLoadIdentity ();

        glVertexPointer (2, GL_FLOAT, 0, spriteVertices);
        glEnableClientState (GL_VERTEX_ARRAY);
        glTexCoordPointer (2, GL_FLOAT, 0, spriteTexCoords);
        glEnableClientState (GL_TEXTURE_COORD_ARRAY);

        googleplayButtonFrame           = CGRectMake (20.0f, 32.0f, 128.0f, 128.0f);
        googleplayTexture               = [self textureFromImageNamed: @"Googleplay.png"];

        tapjoyButtonFrame               = CGRectMake (172.0f, 32.0f, 128.0f, 128.0f);
        tapjoyTexture                   = [self textureFromImageNamed: @"Tapjoy.png"];

        amazonappsButtonFrame           = CGRectMake (20.0f, 176.0f, 128.0f, 128.0f);
        amazonappsTexture               = [self textureFromImageNamed: @"Amazonapps.png"];

        chartboostButtonFrame           = CGRectMake (172.0f, 176.0f, 128.0f, 128.0f);
        chartboostTexture               = [self textureFromImageNamed: @"Chartboost.png"];

        samsungappsButtonFrame          = CGRectMake (20.0f, 320.0f, 128.0f, 128.0f);
        samsungappsTexture              = [self textureFromImageNamed: @"Samsungapps.png"];

        adcolonyButtonFrame             = CGRectMake (172.0f, 320.0f, 128.0f, 128.0f);
        adcolonyTexture                 = [self textureFromImageNamed: @"Adcolony.png"];

        glEnable (GL_TEXTURE_2D);
        glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glEnable (GL_BLEND);
}

- (void) drawView
{
        [EAGLContext setCurrentContext: context];

        glBindFramebufferOES (GL_FRAMEBUFFER_OES, viewFramebuffer);

    #if defined (__STELLA_VERSION_MAX_ALLOWED) && defined (__STELLA_NANDROID)
        glViewport (0, 0, backingWidth, backingHeight);
    #endif

        if (! shine) {
                glClearColor (81.0f/255.0f, 147.0f/255.0f, 207.0f/255.0f, 1.0f);
        }
        else {
                static GLfloat  hue     = 0.0f;
                GLfloat r       = (1.0f + sin(hue - 2.0f * M_PI / 3.0f)) / 3.0f;
                GLfloat g       = (1.0f + sin(hue)) / 3.0f;
                GLfloat b       = (1.0f + sin(hue + 2.0f * M_PI / 3.0f)) / 3.0f;

                glClearColor (r, g, b, 1.0f);
                hue       += 0.03f;
        }

        glClear (GL_COLOR_BUFFER_BIT);

        [self loadSpriteVerticesForFrame: googleplayButtonFrame];
        glBindTexture (GL_TEXTURE_2D, googleplayEnabled ? googleplayTexture : googleplayDisabledTexture);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);

        [self loadSpriteVerticesForFrame: tapjoyButtonFrame];
        glBindTexture (GL_TEXTURE_2D, tapjoyEnabled ? tapjoyTexture : tapjoyDisabledTexture);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);

        [self loadSpriteVerticesForFrame: amazonappsButtonFrame];
        glBindTexture (GL_TEXTURE_2D, amazonappsEnabled ? amazonappsTexture : amazonappsDisabledTexture);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);

        [self loadSpriteVerticesForFrame: chartboostButtonFrame];
        glBindTexture (GL_TEXTURE_2D, chartboostEnabled ? chartboostTexture : chartboostDisabledTexture);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);

        [self loadSpriteVerticesForFrame: samsungappsButtonFrame];
        glBindTexture (GL_TEXTURE_2D, samsungappsEnabled ? samsungappsTexture : samsungappsDisabledTexture);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);
       
        [self loadSpriteVerticesForFrame: adcolonyButtonFrame];
        glBindTexture (GL_TEXTURE_2D, adcolonyEnabled ? adcolonyTexture : adcolonyDisabledTexture);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);

        glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
        [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (SVEvent *) event
{
        UITouch       * touch   = [touches anyObject];
        CGPoint         location    = [touch locationInView: self];

        if (googleplayEnabled && CGRectContainsPoint (googleplayButtonFrame, location)) {
                [delegate buyShineGooglePlay];
        }
        else if (tapjoyEnabled && CGRectContainsPoint (tapjoyButtonFrame, location)) {
                [delegate showOffersTJC];
        }
        else if (amazonappsEnabled && CGRectContainsPoint (amazonappsButtonFrame, location)) {
                [delegate buyShineAmazon];
        }
        else if (chartboostEnabled && CGRectContainsPoint (chartboostButtonFrame, location)) {
                [delegate showInterstitialCB];
        }
        else if (samsungappsEnabled && CGRectContainsPoint (samsungappsButtonFrame, location)) {
                [delegate buyShinePlasma];
                [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(plasmaPurchased) name: @"plasmaPurchased" object: nil];
        }
        else if (adcolonyEnabled && CGRectContainsPoint (adcolonyButtonFrame, location)) {
                [delegate showADC];
        }
}

- (void) plasmaPurchased
{
        shine   = YES;
}

@end
