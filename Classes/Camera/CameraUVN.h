//
//  CameraUVN.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "NeonMath.h"
#import "Camera.h"

@interface CameraUVN : Camera
{
    @public
        Vector3 mUp;
		
		float   mFov;
        float   mAspect;
}

-(CameraUVN*)Init;
-(void)GetViewMatrix:(Matrix44*)outViewMatrix;
-(void)GetProjectionMatrix:(Matrix44*)outProjMatrix;

-(void)GetHFov:(float*)outFov;
-(void)SetHFov:(float)inFov;

@end