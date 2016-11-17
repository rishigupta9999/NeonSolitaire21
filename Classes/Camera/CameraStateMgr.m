//
//  CameraStateMgr.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "CameraStateMgr.h"
#import "CameraStateMachine.h"
#import "CameraUVN.h"

#import "GameStateMgr.h"
#import "DebugCameraState.h"
#import "DebugManager.h"

static CameraStateMgr* sInstance = NULL;
static const char* DEBUG_CAMERA_STRING = "Debug Camera";
static const char* PRESERVE_DEBUG_CAMERA = "Preserve Debug Camera";

@implementation CameraStateMgr

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"CameraStateMgr is non-NULL in CreateInstance\n");
    
    sInstance = (CameraStateMgr*)[((CameraStateMgr*)[CameraStateMgr alloc]) Init];
}

+(void)DestroyInstance
{
}

+(CameraStateMgr*)GetInstance
{
    return sInstance;
}

-(CameraStateMgr*)Init
{
	mCameraStateMachine = (CameraStateMachine*)[(CameraStateMachine*)[CameraStateMachine alloc] Init];
        
    [[DebugManager GetInstance] RegisterDebugMenuItem:[NSString stringWithUTF8String:DEBUG_CAMERA_STRING] WithCallback:self];
    [[DebugManager GetInstance] RegisterDebugMenuItem:[NSString stringWithUTF8String:PRESERVE_DEBUG_CAMERA] WithCallback:self];
    
	SetIdentity(&mDebugViewMatrix);

    mPreserveDebugCamera = FALSE;    
    return self;
}

-(void)dealloc
{
	[mCameraStateMachine release];
	
	[super dealloc];
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
    if (![[DebugManager GetInstance] DebugGameStateActive])
    {
        [mCameraStateMachine Update:inTimeStep];
    }
    
	[mCameraStateMachine CacheCameraParameters];
	
    BOOL debugStateActive = ([[[GameStateMgr GetInstance] GetActiveState] class] == [DebugCameraState class]);
        
    if (debugStateActive)
    {
		[mCameraStateMachine GetViewMatrix:&mDebugViewMatrix];
    }
    
    if (!debugStateActive && mPreserveDebugCamera)
    {
		[mCameraStateMachine SetViewMatrix:&mDebugViewMatrix];
    }
}

-(void)GetViewMatrix:(Matrix44*)outViewMatrix
{
	[mCameraStateMachine GetViewMatrix:outViewMatrix];
}

-(void)GetProjectionMatrix:(Matrix44*)outProjectionMatrix
{
	[mCameraStateMachine GetProjectionMatrix:outProjectionMatrix];
}

-(void)GetScreenRotationMatrix:(Matrix44*)outScreenRotation
{
	[mCameraStateMachine GetScreenRotationMatrix:outScreenRotation];
}

-(void)GetInverseViewMatrix:(Matrix44*)outInverseViewMatrix
{
	[mCameraStateMachine GetInverseViewMatrix:outInverseViewMatrix];
}

-(void)GetInverseProjectionMatrix:(Matrix44*)outInverseProjectionMatrix
{
	[mCameraStateMachine GetInverseProjectionMatrix:outInverseProjectionMatrix];
}

-(void)GetInverseScreenRotationMatrix:(Matrix44*)outInverseScreenRotationMatrix
{
	[mCameraStateMachine GetInverseScreenRotationMatrix:outInverseScreenRotationMatrix];
}

-(void)DebugMenuItemPressed:(NSString*)inName
{
    if ([inName compare:[NSString stringWithUTF8String:DEBUG_CAMERA_STRING]] == NSOrderedSame)
    {
        [[DebugManager GetInstance] ToggleDebugGameState:[DebugCameraState class]];
    }
    else if ([inName compare:[NSString stringWithUTF8String:PRESERVE_DEBUG_CAMERA]] == NSOrderedSame)
    {
        mPreserveDebugCamera = !mPreserveDebugCamera;
    }
}

-(CameraStateMachine*)GetStateMachine
{
    return mCameraStateMachine;
}

-(CameraState*)GetActiveState
{
	return [mCameraStateMachine GetActiveState];
}

-(void)GetPosition:(Vector3*)outPosition
{
	[mCameraStateMachine GetPosition:outPosition];
}

-(void)GetLookAt:(Vector3*)outLookAt
{
	[mCameraStateMachine GetLookAt:outLookAt];
}

-(void)GetHFov:(float*)outFov
{
	[mCameraStateMachine GetHFov:outFov];
}

-(void)GetFar:(float*)outFar
{
	[mCameraStateMachine GetFar:outFar];
}

-(void)GetNear:(float*)outNear
{
	[mCameraStateMachine GetNear:outNear];
}

-(void)Push:(State*)inState
{
	[mCameraStateMachine Push:inState];
}

-(void)Push:(State*)inState withParams:(NSObject*)inParams
{
    [mCameraStateMachine Push:inState withParams:inParams];
}

-(void)ReplaceTop:(State*)inState
{
	[mCameraStateMachine ReplaceTop:inState];
}

-(void)Pop
{
	[mCameraStateMachine Pop];
}

@end