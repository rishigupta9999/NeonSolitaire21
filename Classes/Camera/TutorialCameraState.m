//
//  TutorialCameraState.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "TutorialCameraState.h"
#import "CameraUVN.h"
#import "Path.h"

@implementation TutorialCameraStateParams

-(TutorialCameraStateParams*)Init
{
    mInterpolateIn = FALSE;
    
    return self;
}

@end

@implementation TutorialCameraState

-(void)Startup
{
    [super Startup];
    
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
	
    mPositionPath = [(Path*)[Path alloc] Init];
    mLookAtPath = [(Path*)[Path alloc] Init];
    mFovPath = [(Path*)[Path alloc] Init];
    
    TutorialCameraStateParams* params = (TutorialCameraStateParams*)mParams;
    
    [mPositionPath AddNodeVec3:&params->mPosition atTime:0.0];
    [mLookAtPath AddNodeVec3:&params->mLookAt atTime:0.0];
    [mFovPath AddNodeScalar:params->mFov atTime:0.0];
}

-(void)Resume
{
    [super Resume];
}

-(void)Shutdown
{
    [mPositionPath release];
    [mLookAtPath release];
    [mFovPath release];
    
    [mCamera release];
    
    [super Shutdown];
}

-(void)Suspend
{
    [super Suspend];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mPositionPath Update:inTimeStep];
    [mLookAtPath Update:inTimeStep];
    [mFovPath Update:inTimeStep];
    
    [mPositionPath	GetValueVec3:&mCamera->mPosition];
    [mLookAtPath	GetValueVec3:&mCamera->mLookAt];
    [mFovPath       GetValueScalar:&mCamera->mFov];
}

-(void)SetPosition:(Vector3*)inPosition time:(float)inTime
{
    Vector3 oldPosition;
    [mPositionPath GetValueVec3:&oldPosition];
    
    [mPositionPath release];
    mPositionPath = [(Path*)[Path alloc] Init];
    
    [mPositionPath AddNodeVec3:&oldPosition atTime:0.0f];
    [mPositionPath AddNodeVec3:inPosition   atTime:inTime];
}

-(void)SetLookAt:(Vector3*)inLookAt time:(float)inTime
{
    Vector3 oldLookAt;
    [mLookAtPath GetValueVec3:&oldLookAt];
    
    [mLookAtPath release];
    mLookAtPath = [(Path*)[Path alloc] Init];
    
    [mLookAtPath AddNodeVec3:&oldLookAt atTime:0.0f];
    [mLookAtPath AddNodeVec3:inLookAt   atTime:inTime];
}

-(void)SetFov:(float)inFov time:(float)inTime
{
    float oldFov = 0;
    [mFovPath GetValueScalar:&oldFov];
    
    [mFovPath release];
    mFovPath = [(Path*)[Path alloc] Init];
    
    [mFovPath AddNodeScalar:oldFov atTime:0.0f];
    [mFovPath AddNodeScalar:inFov atTime:inTime];
}

-(BOOL)GetFinished
{
    return ([mPositionPath Finished] && [mLookAtPath Finished] && [mFovPath Finished]);
}

-(Camera*)GetActiveCamera
{
    return mCamera;
}

@end