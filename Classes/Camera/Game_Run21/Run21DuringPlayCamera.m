//
//  Run21DuringPlayCamera.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "Flow.h"
#import "CameraStateMgr.h"
#import "Run21DuringPlayCamera.h"
#import "Run21CelebrationCamera.h"

#import "CameraUVN.h"
#import "GameObjectManager.h"
#import "MiniGameTableEntity.h"

#import "PlayerHand.h"

#import "GameStateMgr.h"

#import "Run21CameraConstants.h"

typedef struct
{
    Vector3 mPosition;
    Vector3 mLookAt;
    float   mFov;
} CameraInfo;

#define NUM_CAMERAS (1)

static CameraInfo sCameraInfo[NUM_CAMERAS] = {  { { -0.000000, 7.480002, 9.753695 }, { -0.000000, 0.800000, -2.000000 }, 79.0f } };
static CameraInfo sTallCameraInfo[NUM_CAMERAS] = {  { { -0.000000, 6.680003, 12.153692 }, { -0.000000, 1.0, -2.000000 }, 73.0f } };

static const float CAMERA_ANIMATE_DURATION = 0.5;

@implementation Run21DuringPlayCameraParams

@synthesize InterpolateFromPrevious = mInterpolateFromPrevious;

-(Run21DuringPlayCameraParams*)init
{
    mInterpolateFromPrevious = FALSE;
    return self;
}

@end

@implementation Run21DuringPlayCamera

-(void)Startup
{
    // Create a basic UVN camera
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
    
    mCameraIndex = 0;
        
    [Run21DuringPlayCamera CalculateCameraPosition:&mCamera->mPosition lookAt:&mCamera->mLookAt fov:&mCamera->mFov];
        
    // Register for messages from the GameNeon21 game state.
    GameState* curState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    [[curState GetMessageChannel] AddListener:self];
    
    [GetGlobalMessageChannel() AddListener:self];
    
    mPositionPath = [(Path*)[Path alloc] Init];
    mLookAtPath = [(Path*)[Path alloc] Init];
    mFovPath = [(Path*)[Path alloc] Init];
    
    BOOL interpolateFromPrevious = FALSE;
    
    if (mParams != NULL)
    {
        Run21DuringPlayCameraParams* cameraParams = (Run21DuringPlayCameraParams*)mParams;
        
        interpolateFromPrevious = cameraParams.InterpolateFromPrevious;
    }

    if (interpolateFromPrevious)
    {
        Vector3 oldPosition, oldLookAt;
        float oldFov;
        
        [[CameraStateMgr GetInstance] GetPosition:&oldPosition];
        [[CameraStateMgr GetInstance] GetLookAt:&oldLookAt];
        [[CameraStateMgr GetInstance] GetHFov:&oldFov];
        
        [mPositionPath AddNodeVec3:&oldPosition atTime:0.0];
        [mLookAtPath AddNodeVec3:&oldLookAt atTime:0.0];
        [mFovPath AddNodeScalar:oldFov atTime:0.0];
        
        [mPositionPath AddNodeVec3:&mCamera->mPosition atTime:1.0];
        [mLookAtPath AddNodeVec3:&mCamera->mLookAt atTime:1.0];
        [mFovPath AddNodeScalar:mCamera->mFov atTime:1.0];
    }
    else
    {
        [mPositionPath AddNodeVec3:&mCamera->mPosition atTime:0.0];
        [mLookAtPath AddNodeVec3:&mCamera->mLookAt atTime:0.0];
        [mFovPath AddNodeScalar:mCamera->mFov atTime:0.0];
    }
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_BEGIN_DURINGPLAY_CAMERA withData:NULL];
}

-(void)Resume
{
    Vector3 destPosition, destLookAt;
    float destFov;
    
    [Run21DuringPlayCamera CalculateCameraPosition:&destPosition lookAt:&destLookAt fov:&destFov];
    
    [mPositionPath Reset];
    [mLookAtPath Reset];
    [mFovPath Reset];
    
    Vector3 curPosition, curLookAt;
    float curFov;
    
    [[CameraStateMgr GetInstance] GetPosition:&curPosition];
    [[CameraStateMgr GetInstance] GetLookAt:&curLookAt];
    [[CameraStateMgr GetInstance] GetHFov:&curFov];
    
    [mPositionPath AddNodeVec3:&curPosition atTime:0.0];
    [mLookAtPath AddNodeVec3:&curLookAt atTime:0.0];
    [mFovPath AddNodeScalar:curFov atTime:0.0];
    
    [mPositionPath AddNodeVec3:&destPosition atTime:CAMERA_ANIMATE_DURATION];
    [mLookAtPath AddNodeVec3:&destLookAt atTime:CAMERA_ANIMATE_DURATION];
    [mFovPath AddNodeScalar:destFov atTime:CAMERA_ANIMATE_DURATION];
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_BEGIN_DURINGPLAY_CAMERA withData:NULL];
}

-(void)Suspend
{
}

-(void)Shutdown
{
    [GetGlobalMessageChannel() RemoveListener:self];
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
    switch(inMsg->mId)
    {
        case EVENT_CONCLUSION_BROKETHEBANK:
        {
            [[CameraStateMgr GetInstance] Push:[Run21CelebrationCamera alloc]];
            break;
        }
    }
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
    [mPositionPath Update:inTimeStep];
    [mLookAtPath Update:inTimeStep];
    [mFovPath Update:inTimeStep];
    
    if (![mCamera GetDebugCameraAttached])
    {
        [mPositionPath GetValueVec3:&mCamera->mPosition];
        [mLookAtPath GetValueVec3:&mCamera->mLookAt];
        [mFovPath GetValueScalar:&mCamera->mFov];
    }
}

+(void)CalculateCameraPosition:(Vector3*)outPosition lookAt:(Vector3*)outLookAt fov:(float*)outFov
{
    CameraInfo* curInfo = &sCameraInfo[0];
    
    if (GetDeviceiPhoneTall())
    {
        curInfo = &sTallCameraInfo[0];
    }
    
    CloneVec3(&curInfo->mPosition, outPosition);
    CloneVec3(&curInfo->mLookAt, outLookAt);

    *outFov = curInfo->mFov;
}

@end