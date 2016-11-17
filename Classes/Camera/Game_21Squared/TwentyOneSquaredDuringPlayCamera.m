//
//  TwentyOneSquaredDuringPlayCamera.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//


#import "CameraStateMgr.h"
#import "TwentyOneSquaredDuringPlayCamera.h"

#import "CameraUVN.h"
#import "GameObjectManager.h"
#import "MiniGameTableEntity.h"

#import "PlayerHand.h"

#import "GameStateMgr.h"

static Vector3 mCameraPositionOffsets[1] = {  { 0.000000f, 9.88f, 3.753699f } };
static Vector3 mCameraLookAtOffsets[1] = { { 0.000000f, -0.600000f, -1.200000f } };

static const float CAMERA_ANIMATE_DURATION = 1.0f; 

@implementation TwentyOneSquaredDuringPlayCamera

-(void)Startup
{
    // Create a basic UVN camera
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
        
    [TwentyOneSquaredDuringPlayCamera CalculateCameraPosition:&mCamera->mPosition lookAt:&mCamera->mLookAt];
        
    // Register for messages from the GameNeon21 game state.
    GameState* curState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    
    [[curState GetMessageChannel] AddListener:self];
    
    mPositionPath = [(Path*)[Path alloc] Init];
    mLookAtPath = [(Path*)[Path alloc] Init];
    
    [mPositionPath AddNodeVec3:&mCamera->mPosition atTime:0.0];
    [mLookAtPath AddNodeVec3:&mCamera->mLookAt atTime:0.0];
}

-(void)Resume
{
    Vector3 destPosition, destLookAt;
    [TwentyOneSquaredDuringPlayCamera CalculateCameraPosition:&destPosition lookAt:&destLookAt];
    
    [mPositionPath Reset];
    [mLookAtPath Reset];
    
    Vector3 curPosition, curLookAt;
    
    [[CameraStateMgr GetInstance] GetPosition:&curPosition];
    [[CameraStateMgr GetInstance] GetLookAt:&curLookAt];
    
    [mPositionPath AddNodeVec3:&curPosition atTime:0.0];
    [mLookAtPath AddNodeVec3:&curLookAt atTime:0.0];
    
    [mPositionPath AddNodeVec3:&destPosition atTime:CAMERA_ANIMATE_DURATION];
    [mLookAtPath AddNodeVec3:&destLookAt atTime:CAMERA_ANIMATE_DURATION];
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
    [mPositionPath Update:inTimeStep];
    [mLookAtPath Update:inTimeStep];
    
    if (![mCamera GetDebugCameraAttached])
    {
        [mPositionPath GetValueVec3:&mCamera->mPosition];
        [mLookAtPath GetValueVec3:&mCamera->mLookAt];
    }
}

+(void)CalculateCameraPosition:(Vector3*)outPosition lookAt:(Vector3*)outLookAt
{
    float px = mCameraPositionOffsets[0].mVector[x];
    float py = mCameraPositionOffsets[0].mVector[y];
    float pz = mCameraPositionOffsets[0].mVector[z];
    
    float lax = mCameraLookAtOffsets[0].mVector[x];
    float lay = mCameraLookAtOffsets[0].mVector[y];
    float laz = mCameraLookAtOffsets[0].mVector[z];
	
    Set(outPosition, px, py, pz);
    Set(outLookAt, lax, lay, laz);
}

@end