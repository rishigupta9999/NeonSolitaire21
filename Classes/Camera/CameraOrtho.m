//
//  CameraOrtho.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.

#import "CameraOrtho.h"

@implementation CameraOrtho

-(CameraOrtho*)Init
{
	[super Init];
	
	mLeft = 0.0f;
	mRight = 0.0f;
	mTop = 0.0f;
	mBottom = 0.0f;
	
	mFar = 1.0f;
	mNear = -1.0f;
	
	SetIdentity(&mViewMatrix);
	SetIdentity(&mProjectionMatrix);
	
	return self;
}

-(void)SetFrameLeft:(float)inLeft right:(float)inRight top:(float)inTop bottom:(float)inBottom
{
	mLeft = inLeft;
	mRight = inRight;
	mTop = inTop;
	mBottom = inBottom;
	
	[self GenerateViewMatrix];
	[self GenerateProjectionMatrix];
}

-(void)GetViewMatrix:(Matrix44*)outViewMatrix
{
	CloneMatrix44(&mViewMatrix, outViewMatrix);
}

-(void)GetProjectionMatrix:(Matrix44*)outProjMatrix
{
	CloneMatrix44(&mProjectionMatrix, outProjMatrix);
}

-(void)GenerateViewMatrix
{
#if 0
	Matrix44 translation, scale;
	// Only necessary for EAGL views.  Since this class is only used
	// for offscreen framebuffers, this isn't necessary.
	
	// Put origin at top left
	GenerateTranslationMatrix(mLeft, mTop, 0.0f, &translation);
	GenerateScaleMatrix(1.0f, -1.0f, 1.0f, &scale);
	
	MatrixMultiply(&translation, &scale, &mViewMatrix);
#else
	GenerateTranslationMatrix(mLeft, mBottom, 0.0f, &mViewMatrix);
#endif
}

-(void)GenerateProjectionMatrix
{
	SetIdentity(&mProjectionMatrix);
	
	mProjectionMatrix.mMatrix[0] = 2.0f / (mRight - mLeft);
	mProjectionMatrix.mMatrix[5] = 2.0f / (mTop - mBottom);
	mProjectionMatrix.mMatrix[10] = -2.0f / (mFar - mNear);
	
	mProjectionMatrix.mMatrix[12] = - ((mRight + mLeft) / (mRight - mLeft));
	mProjectionMatrix.mMatrix[13] = - ((mTop + mBottom) / (mTop - mBottom));
	mProjectionMatrix.mMatrix[14] = - ((mFar + mNear) / (mFar - mNear));
}

@end