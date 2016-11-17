//
//  CameraState.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "State.h"
#import "NeonMath.h"

@class Camera;

@interface CameraState : State
{
}

-(void)GetViewMatrix:(Matrix44*)outViewMatrix;
-(void)GetProjectionMatrix:(Matrix44*)outProjectionMatrix;

-(void)GetPosition:(Vector3*)outPosition;
-(void)GetLookAt:(Vector3*)outLookAt;
-(void)GetHFov:(float*)outHFov;

-(void)GetNear:(float*)outNear;
-(void)GetFar:(float*)outFar;

-(Camera*)GetActiveCamera;

@end