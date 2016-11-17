//
//  StaticOrthoCameraState.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "StaticOrthoCameraState.h"
#import "CameraOrtho.h"

static float DEFAULT_STATIC_ORTHO_WIDTH = 256.0f;
static float DEFAULT_STATIC_ORTHO_HEIGHT = 256.0f;

@implementation StaticOrthoCameraStateParams

-(StaticOrthoCameraStateParams*)Init
{
	mWidth = DEFAULT_STATIC_ORTHO_WIDTH;
	mHeight = DEFAULT_STATIC_ORTHO_HEIGHT;
	
	return self;
}

@end

@implementation StaticOrthoCameraState

-(void)Startup
{
	StaticOrthoCameraStateParams* params = (StaticOrthoCameraStateParams*)mParams;

	mCameraOrtho = [(CameraOrtho*)[CameraOrtho alloc] Init];
	
	[mCameraOrtho SetFrameLeft:-(params->mWidth / 2)
					right:params->mWidth / 2
					top:params->mHeight / 2
					bottom:-params->mHeight / 2];
}

-(void)Resume
{
}

-(void)Suspend
{
}

-(void)Shutdown
{
	[mCameraOrtho release];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
}

-(Camera*)GetActiveCamera
{
	return mCameraOrtho;
}

@end