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


#if defined (RENDER_USING_ES2)
#warning render using es2
#define glGenFramebuffersOES            glGenFramebuffers
#define glDeleteFramebuffersOES         glDeleteFramebuffers
#define glCheckFramebufferStatusOES     glCheckFramebufferStatus
#define glBindFramebufferOES            glBindFramebuffer

#define GL_FRAMEBUFFER_OES              GL_FRAMEBUFFER
#define GL_FRAMEBUFFER_COMPLETE_OES     GL_FRAMEBUFFER_COMPLETE

#define GL_RENDERBUFFER_OES             GL_RENDERBUFFER
#define GL_RENDERBUFFER_WIDTH_OES       GL_RENDERBUFFER_WIDTH
#define GL_RENDERBUFFER_HEIGHT_OES      GL_RENDERBUFFER_HEIGHT

#define GL_COLOR_ATTACHMENT0_OES        GL_COLOR_ATTACHMENT0
#endif



#if defined (RENDER_USING_ES2)
static const GLchar      * vertexShaderSource = " \
     attribute vec4          a_Vertex; \n\
     attribute vec2          a_TexCoord; \n\
     \n\
     uniform mat4            u_MVPMatrix; \n\
     \n\
     #ifdef GL_ES \n\
     varying mediump vec2    v_TexCoord; \n\
     #else \n\
     varying vec2            v_TexCoord; \n\
     #endif \n\
     \n\
     void main () { \n\
             v_TexCoord          = a_TexCoord; \n\
             gl_Position         = u_MVPMatrix * a_Vertex; \n\
     } \n\
";

static const GLchar      * fragmentShaderSource = " \
    #ifdef GL_ES \n\
    precision lowp          float; \n\
    #endif \n\
    \n\
    uniform sampler2D       u_Texture; \n\
    varying vec2            v_TexCoord; \n\
    \n\
    void main () { \n\
            gl_FragColor        = texture2D (u_Texture, v_TexCoord); \n\
    } \n\
";


static GLuint initShader (GLenum shaderType, const char * source)
{
        GLuint shader = glCreateShader (shaderType);
        if (!shader) {
                NSLog (@"failed to create shader");
                return 0;
        }

        glShaderSource (shader, 1, &source, NULL);

        glCompileShader (shader);

        GLint compiled = 0;
        glGetShaderiv (shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
                NSLog (@"failed to compile shader");
                glDeleteShader (shader);
                return 0;
         }

        return shader;
}

static GLuint initProgram (const char * vertexSource, const char * fragmentSource)
{
        GLuint vertexShader     = initShader (GL_VERTEX_SHADER, vertexSource);
        if (!vertexShader) {
                NSLog (@"failed to init vertex shader");
                return 0;
        }

        GLuint fragmentShader   = initShader (GL_FRAGMENT_SHADER, fragmentSource);
        if (!fragmentShader) {
                NSLog (@"failed to init fragment shader");
                return 0;
        }

        GLuint program          = glCreateProgram ();
        if (! program) {
                NSLog (@"failed to create shader program");
                return 0;
        }

        glAttachShader (program, vertexShader);
        glAttachShader (program, fragmentShader);

        glLinkProgram (program);
        GLint linkStatus        = GL_FALSE;

        glGetProgramiv (program, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
                NSLog (@"failed to link program");
                glDeleteProgram (program);
                return 0;
        }

        return program;
}

#endif



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

    #if defined (RENDER_USING_ES2)
        context     = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; // What about EGL_CONTEXT_CLIENT_VERSION ?
    #else
        context     = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1]; // What about EGL_CONTEXT_CLIENT_VERSION ?
    #endif


        if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
            [self release];
            return nil;
        }

        animating               = FALSE;

        animationFrameInterval  = 1;
        animationTimer          = nil;

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
        [EAGLContext setCurrentContext: context];
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

    #if defined (RENDER_WITH_DEPTH_BUFFER)
        NSLog (@"attach a depth buffer");
        NSUInteger      widePOT     = 1;
        NSUInteger      highPOT     = 1;
        while (widePOT < backingWidth)      widePOT <<= 1;
        while (highPOT < backingHeight)     highPOT <<= 1;
    #endif

    #if defined (RENDER_WITH_DEPTH_BUFFER)
        glGenRenderbuffers (1, &depthRenderbuffer);
        glBindRenderbuffer (GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorage (GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16, widePOT, highPOT);
        glFramebufferRenderbuffer (GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER_OES, depthRenderbuffer);
    #endif

        if (glCheckFramebufferStatusOES (GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
                NSLog (@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES (GL_FRAMEBUFFER_OES));
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
    #if defined (RENDER_USING_ES2)
        shaderProgram    = initProgram (vertexShaderSource, fragmentShaderSource);
        if (! shaderProgram) {
                NSLog (@"failed to create shader program");
        }

        glUseProgram (shaderProgram);
    #endif

        glViewport (0, 0, backingWidth, backingHeight);
        spriteVertices[1]   = 0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;
        spriteVertices[3]   = 0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;
        spriteVertices[5]   = -0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;
        spriteVertices[7]   = -0.5f * (GLfloat) backingWidth / (GLfloat) backingHeight;


    #if defined (RENDER_USING_ES2)
        attributeLocation_Vertex    = glGetAttribLocation (shaderProgram, "a_Vertex");
        attributeLocation_TexCoord  = glGetAttribLocation (shaderProgram, "a_TexCoord");

        uniformLocation_MVPMatrix   = glGetUniformLocation (shaderProgram, "u_MVPMatrix");
        uniformLocation_Texture     = glGetUniformLocation (shaderProgram, "u_Texture");

        CGAffineTransform       ctm   = SGAffineTransformIdentity;
        GLfloat     matrix[16]  = {
                ctm.a,  ctm.b,  0.0,    0.0,    /* sX,  */
                ctm.c,  ctm.d,  0.0,    0.0,    /*      sY, */
                0.0,    0.0,    1.0,    0.0,    /*           sZ, */
                ctm.tx, ctm.ty, 0.0,    1.0,    /* tX,  tY,  tZ,  1, */
        };
        glUniformMatrix4fv (uniformLocation_MVPMatrix, 1, GL_FALSE, matrix);

        glVertexAttribPointer (attributeLocation_Vertex, 2, GL_FLOAT, GL_FALSE, 0, spriteVertices);
        glEnableVertexAttribArray (attributeLocation_Vertex);

        glVertexAttribPointer (attributeLocation_TexCoord, 2, GL_FLOAT, GL_FALSE, 0, spriteTexCoords);
        glEnableVertexAttribArray (attributeLocation_TexCoord);

    #else
        glMatrixMode (GL_MODELVIEW);
        glLoadIdentity ();

        glVertexPointer (2, GL_FLOAT, 0, spriteVertices);
        glEnableClientState (GL_VERTEX_ARRAY);
        glTexCoordPointer (2, GL_FLOAT, 0, spriteTexCoords);
        glEnableClientState (GL_TEXTURE_COORD_ARRAY);
    #endif


        CGImageRef          spriteImage;
        CGContextRef        spriteContext;
        GLubyte           * spriteData;
        size_t                width, height;

        spriteImage     = [UIImage imageNamed: @"yeecco-logo.png"].CGImage;

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

    #if defined (RENDER_USING_ES2)
    #else
        glEnable (GL_TEXTURE_2D);
    #endif

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

        static GLfloat  hue     = 0.0f;
        GLfloat r       = (1.0f + sin(hue - 2.0f * M_PI / 3.0f)) / 3.0f;
        GLfloat g       = (1.0f + sin(hue)) / 3.0f;
        GLfloat b       = (1.0f + sin(hue + 2.0f * M_PI / 3.0f)) / 3.0f;

        glClearColor (r, g, b, 1.0f);
        hue       += 0.03f;


        glClear (GL_COLOR_BUFFER_BIT);
        glDrawArrays (GL_TRIANGLE_STRIP, 0, 4);


        glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
        [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}





@end
