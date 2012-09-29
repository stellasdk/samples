/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


#if defined (__STELLA_VERSION_MAX_ALLOWED)
#import <StellaStore/StellaStore.h>
#endif

@interface EAGLView : UIView<SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
        GLint               backingWidth;
        GLint               backingHeight;

        EAGLContext       * context;

        GLuint              viewRenderbuffer, viewFramebuffer;
        GLuint              depthRenderbuffer;

        GLuint              spriteTexture;

        BOOL                animating;
        NSInteger           animationFrameInterval;
        id                  displayLink;

        CGRect              buttonFrame;
        BOOL                shine;
}

@property(readonly, nonatomic, getter=isAnimating) BOOL     animating;
@property(nonatomic) NSInteger                              animationFrameInterval;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

- (NSInteger) animationFrameInterval;
- (void) setAnimationFrameInterval: (NSInteger) frameInterval;

- (void) startAnimation;
- (void) stopAnimation;
- (void) setupView;
- (void) drawView;

- (void) touchesEnded: (NSSet *) touches withEvent: (SVEvent *) event;
- (void) buyToShine;

- (void) productsRequest: (SKProductsRequest *) request didReceiveResponse: (SKProductsResponse *) response;
- (void) paymentQueue: (SKPaymentQueue *) queue updatedTransactions: (NSArray *) transactions;

- (void) failedTransaction: (SKPaymentTransaction *) transaction;
- (void) restoreTransaction: (SKPaymentTransaction *) transaction;
- (void) completeTransaction: (SKPaymentTransaction *) transaction;

@end
