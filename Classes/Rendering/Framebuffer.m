//
//  Framebuffer.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "Framebuffer.h"
#import "DynamicTexture.h"
#import "GameObjectCollection.h"
#import "CameraStateMachine.h"

#define DEFAULT_FRAMEBUFFER_WIDTH	(512)
#define DEFAULT_FRAMEBUFFER_HEIGHT	(512)

@implementation Framebuffer

-(Framebuffer*)InitWithParams:(FramebufferParams*)inParams
{
	memcpy(&mParams, inParams, sizeof(FramebufferParams));
	
	TextureCreateParams textureCreateParams;
	
	[DynamicTexture InitDefaultCreateParams:&textureCreateParams];
	
	textureCreateParams.mWidth = inParams->mWidth;
	textureCreateParams.mHeight = inParams->mHeight;
	textureCreateParams.mFormat = inParams->mColorFormat;
	textureCreateParams.mType = inParams->mColorType;
	
	TextureParams genericParams;
	[Texture InitDefaultParams:&genericParams];
	
	mColorAttachment = (DynamicTexture*)[(DynamicTexture*)[DynamicTexture alloc] InitWithCreateParams:&textureCreateParams genericParams:&genericParams];
		
	GLint oldFb;
	NeonGLGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &oldFb);

	glGenFramebuffersOES(1, &mFramebuffer);
	NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mFramebuffer);
		
	glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, mColorAttachment->mTexName, 0);
	
#if NEON_DEBUG
	NSAssert(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) == GL_FRAMEBUFFER_COMPLETE_OES, @"Unexpectedly incomplete framebuffer");
#endif
	
	NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, oldFb);
	
	return self;
}

-(void)dealloc
{
	[mColorAttachment release];
	
	[super dealloc];
}

+(void)InitDefaultParams:(FramebufferParams*)outParams
{
	outParams->mWidth = DEFAULT_FRAMEBUFFER_WIDTH;
	outParams->mHeight = DEFAULT_FRAMEBUFFER_HEIGHT;
	outParams->mColorFormat = GL_RGBA;
	outParams->mColorType = GL_UNSIGNED_BYTE;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
}

-(void)Draw
{
}

-(void)Bind
{
	NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, mFramebuffer);
}

-(Texture*)GetColorAttachment
{
	return mColorAttachment;
}

-(u32)GetWidth
{
	return mParams.mWidth;
}

-(u32)GetHeight
{
	return mParams.mHeight;
}

@end