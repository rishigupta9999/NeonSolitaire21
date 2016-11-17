//
//  Run21IntroCamera.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "Run21IntroCamera.h"

#import "LevelDefinitions.h"
#import "Flow.h"

#import "CameraStateMgr.h"

#import "CameraUVN.h"
#import "GameObjectManager.h"
#import "MiniGameTableEntity.h"

#import "Run21DuringPlayCamera.h"

static const float CAMERA_INTRO_DELAY	= 1.0f;
static const float CAMERA_FINAL_DELAY	= 1.0f;

typedef struct
{
    Vector3 mStartPos;
    Vector3 mStartLookAt;
    
    Vector3 mEndPos;
    Vector3 mEndLookAt;
    
    float   mFov;
    
    float   mDuration;
} IntroCameraPanInfo;

#define NUM_INTRO_CAMERA    (4)
static IntroCameraPanInfo   sIntroCameraPanInfo[NUM_INTRO_CAMERA] = {   { { 9.799995, 1.280005, 3.753700 }, { -4.600000, 1.600000, -4.600000 }, { -9.199995, 1.280005, 3.753700 }, { -4.600000, 1.600000, -4.600000 }, 75.0f, 3.5f },
                                                                        { { -10.799994, -0.319995, 5.753698 }, { -1.000000, 0.400000, -1.200000 }, { 6.599998, 6.480003, 5.953698 }, { 0.200000, 0.400000, -2.200000 }, 60.0f, 3.0f },
                                                                        { { -0.600000, 3.080005, 10.753694 }, { 2.800000, 3.600001, -1.200000 }, { -0.600000, 3.080005, 10.753694 }, { 2.800000, 3.600001, -1.200000 }, 59.0f, 2.0f },
                                                                        { { 10.599995, 6.280004, 3.953700 }, { -0.800000, 0.800000, -1.200000 }, { 10.599995, 6.280004, 3.953700 }, { -0.800000, 0.800000, -1.200000 }, 68.0f, 2.0f } };

@implementation Run21IntroCamera

-(void)Startup
{
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
	
    mPositionPath = [(Path*)[Path alloc] Init];
    mLookAtPath = [(Path*)[Path alloc] Init];
    mFovPath = [(Path*)[Path alloc] Init];
    
    int chosenCamera = arc4random_uniform(NUM_INTRO_CAMERA);
    
    chosenCamera = 3;
    
    IntroCameraPanInfo* panInfo = &sIntroCameraPanInfo[chosenCamera];
    
    Vector3 finalPos, finalLookAt;
    float finalFov;
    
    [Run21DuringPlayCamera CalculateCameraPosition:&finalPos lookAt:&finalLookAt fov:&finalFov];
    
    [mPositionPath AddNodeVec3:&panInfo->mStartPos atTime:0.0f];
	[mPositionPath AddNodeVec3:&panInfo->mStartPos atTime:CAMERA_INTRO_DELAY];
	[mPositionPath AddNodeVec3:&panInfo->mEndPos atTime:panInfo->mDuration];
    [mPositionPath AddNodeVec3:&finalPos atTime:(panInfo->mDuration + CAMERA_FINAL_DELAY)];
	
	[mLookAtPath AddNodeVec3:&panInfo->mStartLookAt atTime:0.0f];
	[mLookAtPath AddNodeVec3:&panInfo->mStartLookAt atTime:CAMERA_INTRO_DELAY];
	[mLookAtPath AddNodeVec3:&panInfo->mEndLookAt atTime:panInfo->mDuration];
    [mLookAtPath AddNodeVec3:&finalLookAt atTime:(panInfo->mDuration + CAMERA_FINAL_DELAY)];
    
    [mFovPath AddNodeScalar:panInfo->mFov atTime:0.0f];
    [mFovPath AddNodeScalar:panInfo->mFov atTime:panInfo->mDuration];
    [mFovPath AddNodeScalar:finalFov atTime:(panInfo->mDuration + CAMERA_FINAL_DELAY)];
	
    Set(&mCamera->mUp, 0.0, 1.0, 0.0);
    
    [mCamera SetHFov:panInfo->mFov];
}

-(void)Resume
{
}

-(void)Suspend
{
}

-(void)Shutdown
{
}

-(void)dealloc
{
    [mCamera release];
    [mPositionPath release];
    [mLookAtPath release];
    [mFovPath release];
    
    [super dealloc];
}

-(CameraUVN*)GetActiveCamera
{
    return mCamera;
}

-(void)ProcessMessage:(Message*)inMsg
{
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
    [mPositionPath	Update:inTimeStep];
	[mLookAtPath	Update:inTimeStep];
    [mFovPath       Update:inTimeStep];
    
    if (![mCamera GetDebugCameraAttached])
    {
        [mPositionPath	GetValueVec3:&mCamera->mPosition];
        [mLookAtPath	GetValueVec3:&mCamera->mLookAt];
        [mFovPath       GetValueScalar:&mCamera->mFov];
    }
    
    if ([mPositionPath Finished])
    {
        [[CameraStateMgr GetInstance] ReplaceTop:[Run21DuringPlayCamera alloc]];
    }
}

@end