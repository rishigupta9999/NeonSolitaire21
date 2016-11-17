//
//  CameraState.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "CameraState.h"
#import "CameraUVN.h"

@implementation CameraState

-(void)GetViewMatrix:(Matrix44*)outViewMatrix
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if (activeCamera)
    {
        [activeCamera GetViewMatrix:outViewMatrix];
    }
    else
    {
        SetIdentity(outViewMatrix);
    }
}

-(void)GetProjectionMatrix:(Matrix44*)outProjectionMatrix
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if (activeCamera)
    {
        [activeCamera GetProjectionMatrix:outProjectionMatrix];
    }
    else
    {
        SetIdentity(outProjectionMatrix);
    }
}

-(void)GetPosition:(Vector3*)outPosition
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if (activeCamera)
    {
        [activeCamera GetPosition:outPosition];
    }
    else
    {
        Set(outPosition, 0.0, 0.0, 0.0);
    }
}

-(void)GetLookAt:(Vector3*)outLookAt
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if (activeCamera)
    {
        [activeCamera GetLookAt:outLookAt];
    }
    else
    {
        Set(outLookAt, 0.0, 0.0, 0.0);
    }
}

-(void)GetHFov:(float*)outHFov
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if ((activeCamera) && ([activeCamera class] == [CameraUVN class]))
    {
        [(CameraUVN*)activeCamera GetHFov:outHFov];
    }
    else
    {
        *outHFov = 0.0f;
    }
}

-(void)GetNear:(float*)outNear
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if (activeCamera)
    {
        *outNear = activeCamera->mNear;
    }
    else
    {
        *outNear = 1.0f;
    }
}

-(void)GetFar:(float*)outFar
{
    Camera* activeCamera = [self GetActiveCamera];
    
    if (activeCamera)
    {
        *outFar = activeCamera->mFar;
    }
    else
    {
        *outFar = 1.0f;
    }
}

-(Camera*)GetActiveCamera
{
    return NULL;
}

@end