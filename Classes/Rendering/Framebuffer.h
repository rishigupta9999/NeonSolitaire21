//
//  Framebuffer.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

@class Texture;
@class DynamicTexture;
@class CameraStateMachine;
@class GameObjectCollection;

typedef struct
{
	u32		mWidth;
	u32		mHeight;
	GLenum	mColorFormat;
	GLenum	mColorType;
} FramebufferParams;

@interface Framebuffer : NSObject
{
	DynamicTexture*			mColorAttachment;
	GLuint					mFramebuffer;
	
	FramebufferParams		mParams;
}

-(Framebuffer*)InitWithParams:(FramebufferParams*)inParams;
-(void)dealloc;

+(void)InitDefaultParams:(FramebufferParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;

-(void)Bind;

-(Texture*)GetColorAttachment;
-(u32)GetWidth;
-(u32)GetHeight;

@end