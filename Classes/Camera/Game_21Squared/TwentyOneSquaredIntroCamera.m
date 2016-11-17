//
//  TwentyOneSquaredIntroCamera.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "TwentyOneSquaredIntroCamera.h"

#import "CameraStateMgr.h"

#import "CameraUVN.h"
#import "GameObjectManager.h"
#import "MiniGameTableEntity.h"

#import "TwentyOneSquaredDuringPlayCamera.h"

@implementation TwentyOneSquaredIntroCamera

-(void)Startup
{
    // Create a basic UVN camera
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
    
    // Focus on the center of the table
    GameObject* table = [[GameObjectManager GetInstance] FindObjectWithHash:[MiniGameTableEntity GetHashForClass]];
    
    Box boundingBox;
    [table GetWorldSpaceBoundingBox:&boundingBox];
    
    Vector3 center;
    GetTopCenterForBox(&boundingBox, &center);
    
    Set(&mCamera->mLookAt, center.mVector[x], center.mVector[y], center.mVector[z]);

    // Set up a path to animate over the table
    mPositionPath = [(Path*)[Path alloc] Init];
    
    Vector3 start;
    Vector3 end;
    
    Set(&start, center.mVector[x], center.mVector[y] + 40.0f, center.mVector[z] + 50.0f);
    
    [TwentyOneSquaredDuringPlayCamera CalculateCameraPosition:&end lookAt:&mCamera->mLookAt];
    
    [mPositionPath AddNodeVec3:&start atTime:0.0f];
    [mPositionPath AddNodeVec3:&start atTime:0.5f];
    [mPositionPath AddNodeVec3:&end atTime:2.5f];
    
    [mPositionPath GetValueVec3:&mCamera->mPosition];
    
    Set(&mCamera->mUp, 0.0, 1.0, 0.0);
}

-(void)Resume
{
}

-(void)Suspend
{
}

-(void)Shutdown
{
    [mCamera release];
    [mPositionPath release];
}

-(CameraUVN*)GetActiveCamera
{
    return mCamera;
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
    [mPositionPath Update:inTimeStep];
    
    [mPositionPath GetValueVec3:&mCamera->mPosition];
    
    if ([mPositionPath Finished])
    {
        [[CameraStateMgr GetInstance] ReplaceTop:[TwentyOneSquaredDuringPlayCamera alloc]];
    }
}

@end