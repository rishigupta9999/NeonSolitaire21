//
//  CameraStateMgr.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "StateMachine.h"
#import "NeonMath.h"
#import "DebugManager.h"
#import "CameraState.h"

@class CameraStateMachine;

// Note: It might be cleaner to have this subclass CameraStateMachine, rather than containing an instance of it.
// But it's possible in the future we might have this class manage a collection of CameraStateMachine instances,
// in which case this approach makes more sense.
//
// Alternatively, the Framebuffer class might update a CameraStateMachine as needed.  So in that case, this class
// would become something like a GlobalCameraStateMachine or DefaultCameraStateMachine and then subclassing
// CameraStateMachine makes far more sense.

@interface CameraStateMgr : NSObject <DebugMenuCallback>
{    
    Matrix44    mDebugViewMatrix;
    
    BOOL        mPreserveDebugCamera;
	
	CameraStateMachine*	mCameraStateMachine;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(CameraStateMgr*)GetInstance;

-(CameraStateMgr*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)GetViewMatrix:(Matrix44*)outViewMatrix;
-(void)GetProjectionMatrix:(Matrix44*)outProjectionMatrix;
-(void)GetScreenRotationMatrix:(Matrix44*)outScreenRotation;

-(void)GetInverseViewMatrix:(Matrix44*)outInverseViewMatrix;
-(void)GetInverseProjectionMatrix:(Matrix44*)outInverseProjectionMatrix;
-(void)GetInverseScreenRotationMatrix:(Matrix44*)outInverseScreenRotationMatrix;

-(void)GetPosition:(Vector3*)outPosition;
-(void)GetLookAt:(Vector3*)outLookAt;
-(void)GetHFov:(float*)outFov;
-(void)GetFar:(float*)outFar;
-(void)GetNear:(float*)outNear;

-(CameraStateMachine*)GetStateMachine;

-(void)DebugMenuItemPressed:(NSString*)inName;
-(CameraState*)GetActiveState;

-(void)Push:(State*)inState;
-(void)Push:(State*)inState withParams:(NSObject*)inParams;
-(void)ReplaceTop:(State*)inState;
-(void)Pop;


@end