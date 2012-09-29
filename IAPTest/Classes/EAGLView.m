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


- (void) setupView
{

        glViewport (0, 0, backingWidth, backingHeight);

        spriteVertices[1]   = 0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;
        spriteVertices[3]   = 0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;
        spriteVertices[5]   = -0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;
        spriteVertices[7]   = -0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;

        buttonFrame.origin.x        = backingWidth/4.0f;
        buttonFrame.origin.y        = backingHeight/2.0f - backingWidth/4.0f;
        buttonFrame.size.width      = backingWidth/2.0f;
        buttonFrame.size.height     = backingWidth/2.0f;


        glMatrixMode (GL_MODELVIEW);
        glLoadIdentity ();

        glVertexPointer (2, GL_FLOAT, 0, spriteVertices);
        glEnableClientState (GL_VERTEX_ARRAY);
        glTexCoordPointer (2, GL_FLOAT, 0, spriteTexCoords);
        glEnableClientState (GL_TEXTURE_COORD_ARRAY);



        CGImageRef          spriteImage;
        CGContextRef        spriteContext;
        GLubyte           * spriteData;
        size_t                width, height;

        spriteImage     = [UIImage imageNamed: @"buy-me.png"].CGImage;

        if (! spriteImage) {
                NSLog (@"failed to read sprite image");
                return;
        }

        // Get the width and height of the image
        width       = CGImageGetWidth (spriteImage);
        height      = CGImageGetHeight (spriteImage);


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

        glEnable (GL_TEXTURE_2D);

        glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glEnable (GL_BLEND);


        [SKPaymentQueue setSamsungPlasmaItemGroupID: @"100000008752"];
        [SKPaymentQueue setSamsungPlasmaDeveloperMode];
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
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);


        glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
        [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (SVEvent *) event
{
        UITouch       * touch   = [touches anyObject];
        CGPoint         location    = [touch locationInView: self];

        if (! CGRectContainsPoint (buttonFrame, location)) {
                return;
        }

        [self buyToShine];
}



- (void) buyToShine
{
        NSMutableArray      * productIdentifierList;
        productIdentifierList = [[NSMutableArray alloc] initWithCapacity: 2];

        [productIdentifierList addObject: [NSString stringWithFormat: @"000000012717"]];     /* buy this to shine */
        [productIdentifierList addObject: [NSString stringWithFormat: @"000000012725"]];     /* unavailable */

        if ([SKPaymentQueue canMakePayments]) {
                [[SKPaymentQueue defaultQueue] addTransactionObserver: self];

                SKProductsRequest     * request     =
                [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray: productIdentifierList]];

                request.delegate    = self;
                [request start];
        }
        else {
                NSLog (@"cannot make payment");
        }
}

- (void) productsRequest: (SKProductsRequest *) request didReceiveResponse: (SKProductsResponse *) response
{
        if (response.products.count != 1) {
                NSLog (@"product request contains no object");
                return;
        }

        SKProduct     * product     = [response.products objectAtIndex: 0];
        SKPayment     * payment     = [SKPayment paymentWithProductIdentifier: product.productIdentifier];
        [[SKPaymentQueue defaultQueue] addPayment: payment];
}



- (void) paymentQueue: (SKPaymentQueue *) queue updatedTransactions: (NSArray *) transactions
{
        NSLog  (@"payment queue updated transactions");
        for (SKPaymentTransaction * transaction in transactions) {
                switch (transaction.transactionState) {
                        case SKPaymentTransactionStatePurchased:
                                [self completeTransaction: transaction];
                                break;

                        case SKPaymentTransactionStateFailed:
                                [self failedTransaction: transaction];
                                break;

                        case SKPaymentTransactionStateRestored:
                                [self restoreTransaction: transaction];
                                break;

                        default: ;
                }
        }
}

- (void) failedTransaction: (SKPaymentTransaction *) transaction
{
        NSLog  (@"failed transaction");
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restoreTransaction: (SKPaymentTransaction *) transaction
{
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) completeTransaction: (SKPaymentTransaction *) transaction
{
        shine       = YES;
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}




@end
