/*
 * Copyright (c) 2011 Yeecco Limited
 */

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "AppDelegate.h"

@interface EAGLView : UIView
{
        GLint               backingWidth;
        GLint               backingHeight;

        EAGLContext       * context;

        GLuint              viewRenderbuffer, viewFramebuffer;
        GLuint              depthRenderbuffer;

        CGRect              googleplayButtonFrame;
        GLuint              googleplayTexture;
        GLuint              googleplayDisabledTexture;
        BOOL                googleplayEnabled;

        CGRect              tapjoyButtonFrame;
        GLuint              tapjoyTexture;
        GLuint              tapjoyDisabledTexture;
        BOOL                tapjoyEnabled;

        CGRect              amazonappsButtonFrame;
        GLuint              amazonappsTexture;
        GLuint              amazonappsDisabledTexture;
        BOOL                amazonappsEnabled;

        CGRect              chartboostButtonFrame;
        GLuint              chartboostTexture;
        GLuint              chartboostDisabledTexture;
        BOOL                chartboostEnabled;

        CGRect              samsungappsButtonFrame;
        GLuint              samsungappsTexture;
        GLuint              samsungappsDisabledTexture;
        BOOL                samsungappsEnabled;
 
        CGRect              adcolonyButtonFrame;
        GLuint              adcolonyTexture;
        GLuint              adcolonyDisabledTexture;
        BOOL                adcolonyEnabled;

        BOOL                animating;
        NSInteger           animationFrameInterval;
        id                  displayLink;

        id                  delegate;
        BOOL                shine;
}

@property(nonatomic, assign) id                             delegate;
@property(nonatomic) BOOL                                   shine;
@property(nonatomic) BOOL                                   googleplayEnabled;
@property(nonatomic) BOOL                                   tapjoyEnabled;
@property(nonatomic) BOOL                                   amazonappsEnabled;
@property(nonatomic) BOOL                                   chartboostEnabled;
@property(nonatomic) BOOL                                   samsungappsEnabled;
@property(nonatomic) BOOL                                   adcolonyEnabled;


- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

- (NSInteger) animationFrameInterval;
- (void) setAnimationFrameInterval: (NSInteger) frameInterval;

- (void) startAnimation;
- (void) stopAnimation;

- (GLuint) textureFromImageNamed: (NSString *) name;
- (void) loadSpriteVerticesForFrame: (CGRect) frame;

- (void) setupView;
- (void) drawView;

- (void) touchesEnded: (NSSet *) touches withEvent: (SVEvent *) event;
- (void) plasmaPurchased;


@end

@interface NSObject (IAPDelegate)
- (void) buyShine;
- (void) showOffersTJC;
@end

