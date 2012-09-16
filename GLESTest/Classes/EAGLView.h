/*
 * Copyright (c) 2011 Yeecco Limited
 */


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>

// #define RENDER_USING_ES2

#if defined (RENDER_USING_ES2)
#import <OpenGLES/ES2/gl2.h>
#import <OpenGLES/ES2/gl2ext.h>
#else
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#endif


@interface EAGLView : UIView
{
	    GLint               backingWidth;
	    GLint               backingHeight;
	
	    EAGLContext       * context;
	
	    GLuint              viewRenderbuffer, viewFramebuffer;
	    GLuint              depthRenderbuffer;
	
	    GLuint              spriteTexture;
	
	    BOOL                animating;
	    BOOL                displayLinkSupported;
	    NSInteger           animationFrameInterval;

	    id                  displayLink;
	    NSTimer           * animationTimer;
	    
    #if defined (RENDER_USING_ES2)
        GLuint              shaderProgram;
        GLuint              attributeLocation_Vertex;
        GLuint              attributeLocation_TexCoord;
        GLuint              uniformLocation_MVPMatrix;
        GLuint              uniformLocation_Texture;
    #endif
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

@end


