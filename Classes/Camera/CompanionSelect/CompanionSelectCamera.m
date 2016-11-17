//
//  CompanionSelectCamera.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "CameraStateMgr.h"
#import "CameraState.h"
#import "CompanionSelectCamera.h"
#import "CompanionManager.h"
#import "CompanionEntity.h"
#import "Skeleton.h"

#define CAMERA_PATH_DURATION    (1.0f)
#define HIDE_PLAYER_DELAY       (0.0f)

static const Vector3 sDealerOffsetVector = { { 0.0f, 0.0f, 9.0f } };
static const Vector3 sDealerNeckOffsetVector = { { 0.0f, -1.5f, 0.0f } };

@implementation CompanionSelectCamera

-(void)Startup
{
    [super Startup];
        
    mPositionPath = [(Path*)[Path alloc] Init];
    mLookAtPath = [(Path*)[Path alloc] Init];
    
    mCamera = [(CameraUVN*)[CameraUVN alloc] Init];
    
    // We want to look at the dealer (instead of the center of the table)
    Companion* dealer = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_DEALER];
    CompanionEntity* dealerEntity = dealer->mEntity;    
    Skeleton* dealerSkeleton = [[dealerEntity GetPuppet] GetSkeleton];
    Joint* dealerNeckJoint = [dealerSkeleton GetJointAtIndex:JOINT_NECK];
    
// If we're starting in CompanionSelect, the dealer skeleton hasn't had a chance to update, and all the transforms are
// zero.  This will give us an inaccurate calculation below.
#if START_STATE_OVERRIDE
    [dealerEntity Update:0.0f];
#endif
    
    Vector3 dealerNeckLocalPosition;
    [dealerNeckJoint GetLocalSpacePosition:&dealerNeckLocalPosition];
    
    Vector3 dealerNeckWorldPosition;
    [dealerEntity TransformLocalToWorld:&dealerNeckLocalPosition result:&dealerNeckWorldPosition];
    
    // Put the camera right in front of the dealer
    Vector3 destCameraPosition;
    
    Add3(&dealerNeckWorldPosition, (Vector3*)&sDealerNeckOffsetVector, &dealerNeckWorldPosition);
    Add3(&dealerNeckWorldPosition, (Vector3*)&sDealerOffsetVector, &destCameraPosition);
    
    Vector3 lastPosition;
    Vector3 lastLookAt;
    
    [[CameraStateMgr GetInstance] GetPosition:&lastPosition];
    [[CameraStateMgr GetInstance] GetLookAt:&lastLookAt];

    [mPositionPath AddNodeVec3:&lastPosition atTime:0.0f];
    [mPositionPath AddNodeVec3:&destCameraPosition atTime:CAMERA_PATH_DURATION];
    
    [mLookAtPath AddNodeVec3:&lastLookAt atTime:0.0f];
    [mLookAtPath AddNodeVec3:&dealerNeckWorldPosition atTime:CAMERA_PATH_DURATION];
    
    mStateTime = 0.0f;
    mPlayerHidden = FALSE;
}

-(void)Resume
{
    NSAssert(FALSE, @"Resume is unsupported");
    [super Resume];
}

-(void)Suspend
{
    NSAssert(FALSE, @"Suspend is unsupported");
    [super Suspend];
}

-(void)Shutdown
{
    [super Shutdown];
    
    [mPositionPath release];
    [mLookAtPath release];
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
    
    if ((mStateTime > HIDE_PLAYER_DELAY) && (!mPlayerHidden))
    {
        Companion* player = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_PLAYER];
        CompanionEntity* playerEntity = player->mEntity;
        
        [playerEntity SetVisible:FALSE];
    }
    
    mStateTime += inTimeStep;
}

@end