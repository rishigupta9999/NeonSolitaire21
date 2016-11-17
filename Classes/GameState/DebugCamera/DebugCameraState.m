//
//  DebugCameraState.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "DebugCameraState.h"
#import "GameObjectManager.h"
#import "CameraStateMgr.h"
#import "CameraUVN.h"
#import "DebugCamera.h"
#import "GameStateMgr.h"
                                                                
@implementation DebugCameraState

-(void)Startup
{
	Camera* activeCamera = [[[CameraStateMgr GetInstance] GetActiveState] GetActiveCamera];
	NSAssert(([activeCamera class] == [CameraUVN class]), @"Active camera must be a UVN camera");

    mDebugCamera = [[DebugCamera alloc] InitWithCamera:(CameraUVN*)activeCamera];
    
    [[GameStateMgr GetInstance] ResumeProcessing];
    
    [[TouchSystem GetInstance] AddListener:self];
}

-(void)Resume
{
    NSAssert(FALSE, @"Resume not supported");
}

-(void)Shutdown
{
    [mDebugCamera release];
}

-(void)Suspend
{
    NSAssert(FALSE, @"Suspend not supported");
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mDebugCamera Update:inTimeStep];
}

-(void)DrawOrtho
{
    [mDebugCamera DrawOrtho];
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
    Camera* activeCamera = [[[CameraStateMgr GetInstance] GetActiveState] GetActiveCamera];

    if (inData->mTouchType == TOUCHES_ENDED)
    {
        NSLog(@"Camera Position: %f, %f, %f", activeCamera->mPosition.mVector[x],
                                              activeCamera->mPosition.mVector[y],
                                              activeCamera->mPosition.mVector[z]);
                                              
        NSLog(@"Camera Look At: %f, %f, %f",  activeCamera->mLookAt.mVector[x],
                                              activeCamera->mLookAt.mVector[y],
                                              activeCamera->mLookAt.mVector[z]);
        
        if ([activeCamera class] == [CameraUVN class])
        {
            NSLog(@"Camera Fov: %f", ((CameraUVN*)activeCamera)->mFov);
        }
    }
    
    return TOUCHSYSTEM_CONSUME_NONE;
}

@end