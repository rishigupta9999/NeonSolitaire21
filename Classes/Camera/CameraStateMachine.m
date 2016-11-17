//
//  CameraStateMachine.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "CameraStateMachine.h"
#import "CameraState.h"
#import "CameraUVN.h"

@implementation CameraStateMachine

-(CameraStateMachine*)Init
{
	[super Init];
	
	SetIdentity(&mViewMatrix);
    SetIdentity(&mProjectionMatrix);
    
    GenerateRotationMatrix(-90, 0.0f, 0.0f, 1.0f, &mScreenRotationMatrix);
    
    SetIdentity(&mInverseViewMatrix);
    SetIdentity(&mInverseProjectionMatrix);
    
    Inverse(&mScreenRotationMatrix, &mInverseScreenRotationMatrix);
        
    Set(&mPosition, 0.0, 0.0, 0.0);
    Set(&mLookAt, 0.0, 0.0, 0.0);
    mFov = 0.0f;
    	
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
	[super Update:inTimeStep];
	
	[self CacheCameraParameters];
}

-(void)CacheCameraParameters
{
    [(CameraState*)mActiveState GetViewMatrix:&mViewMatrix];
    [(CameraState*)mActiveState GetProjectionMatrix:&mProjectionMatrix];
    
    Inverse(&mViewMatrix, &mInverseViewMatrix);
    InverseProjection(&mProjectionMatrix, &mInverseProjectionMatrix);
    
    [(CameraState*)mActiveState GetPosition:&mPosition];
    [(CameraState*)mActiveState GetLookAt:&mLookAt];
    [(CameraState*)mActiveState GetHFov:&mFov];
    
    [(CameraState*)mActiveState GetFar:&mFar];
    [(CameraState*)mActiveState GetNear:&mNear];
}

-(void)GetViewMatrix:(Matrix44*)outViewMatrix
{
	CloneMatrix44(&mViewMatrix, outViewMatrix);
}

-(void)SetViewMatrix:(Matrix44*)inViewMatrix
{
	CloneMatrix44(inViewMatrix, &mViewMatrix);
}

-(void)GetProjectionMatrix:(Matrix44*)outProjectionMatrix
{
	CloneMatrix44(&mProjectionMatrix, outProjectionMatrix);
}

-(void)GetScreenRotationMatrix:(Matrix44*)outScreenRotation
{
    CloneMatrix44(&mScreenRotationMatrix, outScreenRotation);
}

-(void)GetInverseViewMatrix:(Matrix44*)outInverseViewMatrix
{
    CloneMatrix44(&mInverseViewMatrix, outInverseViewMatrix);
}

-(void)GetInverseProjectionMatrix:(Matrix44*)outInverseProjectionMatrix
{
    CloneMatrix44(&mInverseProjectionMatrix, outInverseProjectionMatrix);
}

-(void)GetInverseScreenRotationMatrix:(Matrix44*)outInverseScreenRotationMatrix
{
    CloneMatrix44(&mInverseScreenRotationMatrix, outInverseScreenRotationMatrix);
}

-(CameraState*)GetActiveState
{
    return (CameraState*)mActiveState;
}

-(void)GetPosition:(Vector3*)outPosition
{
    CloneVec3(&mPosition, outPosition);
}

-(void)GetLookAt:(Vector3*)outLookAt
{
    CloneVec3(&mLookAt, outLookAt);
}

-(void)GetHFov:(float*)outHFov
{
    *outHFov = mFov;
}

-(void)GetFar:(float*)outFar
{
    *outFar = mFar;
}

-(void)GetNear:(float*)outNear
{
    *outNear = mNear;
}

// Given the specified camera position / look-at, what FOV do we need to get the specified
// rectange visible on the screen?
+(float)GetRequiredHFovForRect:(Rect3D*)inRect position:(Vector3*)inPosition lookAt:(Vector3*)inLookAt
{
    // Generate a transformation matrix from the current position / look-at
    
    CameraUVN* dummyCamera = [(CameraUVN*)[CameraUVN alloc] Init];
    
    CloneVec3(inPosition, &dummyCamera->mPosition);
    CloneVec3(inLookAt, &dummyCamera->mLookAt);
    
    Matrix44 viewMatrix;
    
    [dummyCamera GetViewMatrix:&viewMatrix];
    
    // Convert points to eye space
    
    Vector4 points[4];
            
    TransformVector4x3(&viewMatrix, &inRect->mTopLeft, &points[0]);
    TransformVector4x3(&viewMatrix, &inRect->mTopRight, &points[1]);
    TransformVector4x3(&viewMatrix, &inRect->mBottomLeft, &points[2]);
    TransformVector4x3(&viewMatrix, &inRect->mBottomRight, &points[3]);
    
    float minX, maxX, minZ, minY, maxY, maxZ;
    
    minX = points[0].mVector[x];
    maxX = points[0].mVector[x];
    minY = points[0].mVector[y];
    maxY = points[0].mVector[y];
    minZ = points[0].mVector[z];
    maxZ = points[0].mVector[z];
    
    for (int i = 1; i < 4; i++)
    {
        float curX = points[i].mVector[x];
        float curY = points[i].mVector[y];
        float curZ = points[i].mVector[z];
        
        if (curX < minX)
        {
            minX = curX;
        }
        
        if (curX > maxX)
        {
            maxX = curX;
        }
        
        if (curY < minY)
        {
            minY = curY;
        }
        
        if (curY > maxY)
        {
            maxY = curY;
        }
        
        if (curZ < minZ)
        {
            minZ = curZ;
        }
        
        if (curZ > maxZ)
        {
            maxZ = curZ;
        }
    }
    
    NSAssert(((minZ < 0) && (maxZ < 0)), @"Z values should both be negative (in front of the camera).  Are the passed in values sane?");
    
    // Both min and max could be on the same half of the screen depending on how the camera is positioned.
    // Consequently the FOV would need to be much higher than it would be if the calculation was just based
    // on (maxX - minX) and so forth.  Use twice the maximum distance from the center line to assure we see
    // everything we want to.
    
    float width = 2.0 * max(fabsf(maxX), fabsf(minX));
    float height = 2.0 * max(fabsf(maxY), fabsf(minY));
    
    float hFov = 0.0;
    
    float halfWidth = width / 2.0;
    
    if (dummyCamera->mAspect > (width / height))
    {
        halfWidth = (height / 2.0) * dummyCamera->mAspect;
    }    

    hFov = 2 * atan(halfWidth / abs(minZ));
    
    [dummyCamera release];
    
    return RadiansToDegrees(hFov);
}

@end