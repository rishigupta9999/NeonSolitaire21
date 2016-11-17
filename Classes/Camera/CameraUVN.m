//
//  CameraUVN.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "CameraUVN.h"
#import "CameraState.h"

#define DEFAULT_FOV     (75.0f)
#define DEFAULT_ASPECT  (0.67f)

@implementation CameraUVN

-(CameraUVN*)Init
{
    [super Init];
    
    Set(&mLookAt, 0.0f, 0.0f, 1.0f);
    Set(&mUp, 0.0f, 1.0f, 0.0f);
	
    mFov = DEFAULT_FOV;
    mAspect = DEFAULT_ASPECT;
    
    if (GetDeviceiPhoneTall())
    {
        mAspect = (float)GetScreenAbsoluteHeight() / (float)GetScreenAbsoluteWidth();
    }
    
    return self;
}

-(void)GetViewMatrix:(Matrix44*)outViewMatrix
{
    Vector3 n, u, v;
    
    Sub3(&mPosition, &mLookAt, &n);
    Normalize3(&n);
    
    Cross3(&mUp, &n, &u);
    Normalize3(&u);
    
    Cross3(&n, &u, &v);
    Normalize3(&v);
    
    // Column 1
    outViewMatrix->mMatrix[0] = u.mVector[x];
    outViewMatrix->mMatrix[1] = v.mVector[x];
    outViewMatrix->mMatrix[2] = n.mVector[x];
    outViewMatrix->mMatrix[3] = 0.0f;
    
    // Column 2
    outViewMatrix->mMatrix[4] = u.mVector[y];
    outViewMatrix->mMatrix[5] = v.mVector[y];
    outViewMatrix->mMatrix[6] = n.mVector[y];
    outViewMatrix->mMatrix[7] = 0.0f;
    
    // Column 3
    outViewMatrix->mMatrix[8] = u.mVector[z];
    outViewMatrix->mMatrix[9] = v.mVector[z];
    outViewMatrix->mMatrix[10] = n.mVector[z];
    outViewMatrix->mMatrix[11] = 0.0f;

    // Column 4
    outViewMatrix->mMatrix[12] = - Dot3(&u, &mPosition);
    outViewMatrix->mMatrix[13] = - Dot3(&v, &mPosition);
    outViewMatrix->mMatrix[14] = - Dot3(&n, &mPosition);
    outViewMatrix->mMatrix[15] = 1.0f;
}

-(void)GetProjectionMatrix:(Matrix44*)outProjMatrix
{
    SetIdentity(outProjMatrix);
    
    float top = mNear * tan( (M_PI / 180) * (mFov / 2) );
    float bottom = -top;
    float right = top * mAspect;
    float left = -right;
    
    outProjMatrix->mMatrix[0] = (2.0f * mNear) / (right - left);
    outProjMatrix->mMatrix[5] = (2.0f * mNear) / (top - bottom);
    outProjMatrix->mMatrix[8] = (right + left) / (right - left);
    outProjMatrix->mMatrix[9] = (top + bottom) / (top - bottom);
    outProjMatrix->mMatrix[10] = (-(mFar + mNear)) / (mFar - mNear);
    outProjMatrix->mMatrix[11] = -1.0f;
    outProjMatrix->mMatrix[14] = (-2.0f * mFar * mNear) / (mFar - mNear);
    outProjMatrix->mMatrix[15] = 0.0f;
}

-(void)GetHFov:(float*)outFov
{
	*outFov = mFov;
}

-(void)SetHFov:(float)inFov
{
    mFov = inFov;
}

@end