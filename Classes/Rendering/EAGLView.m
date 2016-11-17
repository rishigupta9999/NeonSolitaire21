//
//  EAGLView.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//
 
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"
#import "GameStateMgr.h"
#import "Neon21AppDelegate.h"

#import "TouchSystem.h"
#import "GLExtensionManager.h"

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize animationTimer;


// You must implement this
+ (Class)layerClass 
{
	return [CAEAGLLayer class];
}


//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{
    gAppView = self;
    
	if ((self = [super initWithCoder:coder]))
    {
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
		   [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		mPrimaryContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (!mPrimaryContext || ![EAGLContext setCurrentContext:mPrimaryContext])
        {
			[self release];
			return nil;
		}
        
        mSharegroup = [mPrimaryContext sharegroup];
        mWorkerThreadContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1 sharegroup:mSharegroup];
		
		animationInterval = 1.0 / 60.0;
        
        lastLoggingTime = CFAbsoluteTimeGetCurrent();
        frameCounter = 0;
        
        mViewRenderbuffer = 0;
        mViewFramebuffer = 0;
        
        mMultisampleFramebuffer = 0;
        mMultisampleRenderbuffer = 0;
        mMultisampleDepthStencilbuffer = 0;
        
        mDepthStencilRenderbuffer = 0;
        mDepthRenderbuffer = 0;
        mStencilRenderbuffer = 0;
        
        mWorkerThreadLock = [[NSLock alloc] init];
        
        mUsedMultisample = FALSE;
	}
	return self;
}

-(void)StartGLRender:(BOOL)inAttemptMultisample
{
    [EAGLContext setCurrentContext:mPrimaryContext];
	    
    if ((mMultisampleFramebuffer == 0) || (!inAttemptMultisample))
    {
        mUsedMultisample = FALSE;
        NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mViewFramebuffer);
    }
    else
    {
        mUsedMultisample = TRUE;
        NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mMultisampleFramebuffer);
    }
    
	NeonGLViewport(0, 0, mBackingWidth, mBackingHeight);
    
    NeonGLEnable(GL_DEPTH_TEST);

	NeonGLClearColor(0.0f, 0.0f, 0.0f, 1.0f); // TODO: Kking debug
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

-(void)EndGLRender
{
    NSAssert(mPrimaryContext != NULL, @"Null context");
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, mViewRenderbuffer);
	[mPrimaryContext presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    const GLenum discards[3]  = { GL_COLOR_ATTACHMENT0_OES, GL_DEPTH_ATTACHMENT_OES, GL_STENCIL_ATTACHMENT_OES };
        
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, [[GLExtensionManager GetInstance] GetUsingStencil] ? 3 : 2, discards);
}

-(void)End3DRendering
{
    if ((mMultisampleFramebuffer != 0) && (mUsedMultisample))
    {
        NeonGLBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, mViewFramebuffer);
        NeonGLBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, mMultisampleFramebuffer);
        glResolveMultisampleFramebufferAPPLE();
        
        const GLenum discards[3]  = { GL_COLOR_ATTACHMENT0_OES, GL_DEPTH_ATTACHMENT_OES, GL_STENCIL_ATTACHMENT_OES };
        
        glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, [[GLExtensionManager GetInstance] GetUsingStencil] ? 3 : 2, discards);
                
        NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mViewFramebuffer);
    }
}

- (void)drawView 
{
    [self StartGLRender:TRUE];
    
    [[GameStateMgr GetInstance] Draw];
    
    [self EndGLRender];
}


- (void)layoutSubviews
{
	[EAGLContext setCurrentContext:mPrimaryContext];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}


-(BOOL)createFramebuffer
{
    // Detect if the display is a retina display before doing this.
    // We also have to make store our decision on the scaleFactor somewhere global so the UI classes can scale
    // the geometry appropriately.  Or at least load retina display versions of the textures.
    
    self.contentScaleFactor = GetScreenScaleFactor();
    
    // Create framebuffer for drawing to the CAEAGLLayer that's displayed on the device
	glGenFramebuffersOES(1, &mViewFramebuffer);
	glGenRenderbuffersOES(1, &mViewRenderbuffer);
	
	NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mViewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, mViewRenderbuffer);
	[mPrimaryContext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mViewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &mBackingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &mBackingHeight);
    
    BOOL msaaSupported = [[GLExtensionManager GetInstance] IsExtensionSupported:GL_EXTENSION_APPLE_FRAMEBUFFER_MULTISAMPLE];
    BOOL gpuClassMBX = ([[GLExtensionManager GetInstance] GetGPUClass] == GPU_CLASS_MBX);
    BOOL useMSAA = FALSE;
    BOOL usingStencil = FALSE;
	
    // Don't use MSAA if one of the following conditions is met:
    // 1) The GPU doesn't support MSAA
    // 2) We're running on an MBX device
    // 3) We're running on an iPad that's not an iPad 2.  iPad 1 is too slow, and retina iPads run at retina and don't need MSAA.
    
    BOOL iPad2 = (GetDevicePad() && !GetScreenRetina() && ([[GLExtensionManager GetInstance] GetGPUClass] == GPU_CLASS_SGX) && ([[GLExtensionManager GetInstance] GetGPUVersion] == 543));
    
	if ((!msaaSupported) || (gpuClassMBX) || ((GetDevicePad()) && !iPad2))
    {        
        if ([[GLExtensionManager GetInstance] IsExtensionSupported:GL_EXTENSION_OES_PACKED_DEPTH_STENCIL])
        {
            glGenRenderbuffersOES(1, &mDepthStencilRenderbuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, mDepthStencilRenderbuffer);
            
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH24_STENCIL8_OES, mBackingWidth, mBackingHeight);
            glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthStencilRenderbuffer);
            glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_STENCIL_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthStencilRenderbuffer);
            
            usingStencil = TRUE;
        }
        else if ([[GLExtensionManager GetInstance] IsExtensionSupported:GL_EXTENSION_OES_STENCIL_8])
        {
            glGenRenderbuffersOES(1, &mDepthRenderbuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, mDepthRenderbuffer);

            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, mBackingWidth, mBackingHeight);
            glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthRenderbuffer);
            
            glGenRenderbuffersOES(1, &mStencilRenderbuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, mStencilRenderbuffer);
            
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_STENCIL_INDEX8_OES, mBackingWidth, mBackingHeight);
            glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_STENCIL_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mStencilRenderbuffer);
            
            usingStencil = TRUE;
        }
        else
        {
            glGenRenderbuffersOES(1, &mDepthRenderbuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, mDepthRenderbuffer);
            
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, mBackingWidth, mBackingHeight);
            glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mDepthRenderbuffer);
        }
        
        useMSAA = FALSE;
	}
    else
    {
        useMSAA = TRUE;
    }

	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
    
    // Create multisample framebuffer if applicable
    if (useMSAA)
    {
        glGenFramebuffersOES(1, &mMultisampleFramebuffer);
        NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mMultisampleFramebuffer);
        
        glGenRenderbuffersOES(1, &mMultisampleRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, mMultisampleRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_RGBA8_OES, mBackingWidth, mBackingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, mMultisampleRenderbuffer);
 
        glGenRenderbuffersOES(1, &mMultisampleDepthStencilbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, mMultisampleDepthStencilbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_DEPTH24_STENCIL8_OES, mBackingWidth, mBackingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mMultisampleDepthStencilbuffer);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_STENCIL_ATTACHMENT_OES, GL_RENDERBUFFER_OES, mMultisampleDepthStencilbuffer);

        NeonGLError();
         
        if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
        {
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        }
        
        usingStencil = TRUE;

    }
    
    NeonGLError();
    
    [[GLExtensionManager GetInstance] SetUsingStencil:usingStencil];
	
	return YES;
}


- (void)destroyFramebuffer 
{
	
	glDeleteFramebuffersOES(1, &mViewFramebuffer);
	mViewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &mViewRenderbuffer);
	mViewRenderbuffer = 0;
    
	if(mDepthRenderbuffer != 0)
    {
		glDeleteRenderbuffersOES(1, &mDepthRenderbuffer);
		mDepthRenderbuffer = 0;
	}

	if(mStencilRenderbuffer != 0)
    {
		glDeleteRenderbuffersOES(1, &mStencilRenderbuffer);
		mStencilRenderbuffer = 0;
	}
	
	if(mDepthStencilRenderbuffer != 0)
    {
		glDeleteRenderbuffersOES(1, &mDepthStencilRenderbuffer);
		mDepthStencilRenderbuffer = 0;
	}
    
    if (mMultisampleFramebuffer != 0)
    {
        glDeleteFramebuffersOES(1, &mMultisampleFramebuffer);
        mMultisampleFramebuffer = 0;
    }
    
    if (mMultisampleRenderbuffer != 0)
    {
        glDeleteRenderbuffersOES(1, &mMultisampleRenderbuffer);
        mMultisampleRenderbuffer = 0;
    }
    
    if (mMultisampleDepthStencilbuffer != 0)
    {
        glDeleteRenderbuffersOES(1, &mMultisampleDepthStencilbuffer);
        mMultisampleDepthStencilbuffer = 0;
    }
}


- (void)startAnimation 
{
	self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation 
{
	self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer 
{
	[animationTimer invalidate];
	animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
	
	animationInterval = interval;
    
	if (animationTimer) 
    {
		[self stopAnimation];
		[self startAnimation];
	}
}


- (void)dealloc
{
	
	[self stopAnimation];
	
	if ([EAGLContext currentContext] == mPrimaryContext) {
		[EAGLContext setCurrentContext:nil];
	}
	
    [mWorkerThreadLock unlock];
	[mPrimaryContext release];
    [mWorkerThreadContext release];
    
	[super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[TouchSystem GetInstance] RegisterEvent:TOUCHES_BEGAN WithData:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[TouchSystem GetInstance] RegisterEvent:TOUCHES_ENDED WithData:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[TouchSystem GetInstance] RegisterEvent:TOUCHES_MOVED WithData:touches];
}

-(u32)GetBackingWidth
{
    return mBackingWidth;
}

-(u32)GetBackingHeight
{
    return mBackingHeight;
}

-(EAGLContext*)BeginWorkerThread
{
    [mWorkerThreadLock lock];
    [EAGLContext setCurrentContext:mWorkerThreadContext];
    
    return mWorkerThreadContext;
}

-(void)EndWorkerThread
{
    glFlush();
    
    [EAGLContext setCurrentContext:NULL];
    [mWorkerThreadLock unlock];
}

@end
