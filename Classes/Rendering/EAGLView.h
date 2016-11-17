//
//  EAGLView.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/
@interface EAGLView : UIView
{
    @private
        /* The pixel dimensions of the backbuffer */
        GLint mBackingWidth;
        GLint mBackingHeight;
        
        EAGLContext*    mPrimaryContext;
        EAGLContext*    mWorkerThreadContext;
        EAGLSharegroup* mSharegroup;
        
        /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
        GLuint mViewRenderbuffer;
        GLuint mViewFramebuffer;
        
        GLuint mMultisampleFramebuffer;
        GLuint mMultisampleRenderbuffer;
        GLuint mMultisampleDepthStencilbuffer;
        
        /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
        GLuint mDepthStencilRenderbuffer;
        GLuint mDepthRenderbuffer;
        GLuint mStencilRenderbuffer;
        
        NSTimer *animationTimer;
        NSTimeInterval animationInterval;
        
        CFTimeInterval lastLoggingTime;
        u32            frameCounter;
        
        BOOL    mUsedMultisample;
        NSLock* mWorkerThreadLock;
}

-(void)startAnimation;
-(void)stopAnimation;
-(void)drawView;

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

-(void)StartGLRender:(BOOL)inAttemptMultisample;
-(void)EndGLRender;
-(void)End3DRendering;

-(u32)GetBackingWidth;
-(u32)GetBackingHeight;

-(EAGLContext*)BeginWorkerThread;
-(void)EndWorkerThread;

@end
