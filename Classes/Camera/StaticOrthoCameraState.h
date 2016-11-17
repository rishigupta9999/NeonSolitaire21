//
//  StaticOrthoCameraState.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "CameraState.h"

@class CameraOrtho;

@interface StaticOrthoCameraStateParams : NSObject
{
	@public
		float	mWidth;
		float	mHeight;
}

-(StaticOrthoCameraStateParams*)Init;

@end

@interface StaticOrthoCameraState : CameraState
{
	CameraOrtho*	mCameraOrtho;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)Update:(CFTimeInterval)inTimeStep;

-(Camera*)GetActiveCamera;

@end