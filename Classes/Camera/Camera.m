//
//  Camera.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Camera.h"

#define DEFAULT_NEAR    (0.1f)
#define DEFAULT_FAR     (100.0f)

@implementation Camera

-(Camera*)Init
{
    Set(&mPosition, 0.0f, 0.0f, 0.0f);
    
    mNear = DEFAULT_NEAR;
    mFar = DEFAULT_FAR;
    
    mDebugCamera = NULL;
    
    return self;
}

-(void)GetPosition:(Vector3*)outPosition
{
    CloneVec3(&mPosition, outPosition);
}

-(void)GetLookAt:(Vector3*)outLookAt
{
    CloneVec3(&mLookAt, outLookAt);
}

-(void)GetViewMatrix:(Matrix44*)outViewMatrix
{
	NSAssert(FALSE, @"Subclasses must implement this");
}

-(void)GetProjectionMatrix:(Matrix44*)outProjMatrix
{
	NSAssert(FALSE, @"Subclasses must implement this");
}

-(DebugCamera*)GetDebugCameraAttached
{
    return mDebugCamera;
}

-(void)SetDebugCameraAttached:(DebugCamera*)inDebugCamera
{
    mDebugCamera = inDebugCamera;
}

@end