//
//  CameraOrtho.h
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "Camera.h"

@interface CameraOrtho : Camera
{
	float mLeft;
	float mRight;
	float mTop;
	float mBottom;
	
	Matrix44 mProjectionMatrix;
	Matrix44 mViewMatrix;
}

-(CameraOrtho*)Init;

-(void)SetFrameLeft:(float)inLeft right:(float)inRight top:(float)inTop bottom:(float)inBottom;

-(void)GetViewMatrix:(Matrix44*)outViewMatrix;
-(void)GetProjectionMatrix:(Matrix44*)outProjMatrix;

-(void)GenerateViewMatrix;
-(void)GenerateProjectionMatrix;

@end