//
//  Model.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Model.h"
#import "GameObjectManager.h"
#import "ResourceManager.h"

@implementation Model

-(void)Init
{
    mTexture = NULL;
    mAutoloadTextures = TRUE;
    
    mGlowEnabled = FALSE;
    mGlowAmount = 0.0f;
    
    mOwnerObject = NULL;
    
    ZeroBoundingBox(&mBoundingBox);
    
    mUseOverride = FALSE;
    
    mClipPlaneEnabled = FALSE;
}

+(void)InitDefaultRenderState:(ModelRenderState*)outRenderState
{
    SetVec4(&outRenderState->mColor, 1.0, 1.0, 1.0, 1.0);
}

-(void)SetAutoloadTextures:(BOOL)inAutoloadTextures
{
    mAutoloadTextures = inAutoloadTextures;
}

-(BOOL)GetAutoloadTextures
{
    return mAutoloadTextures;
}

-(void)SetTexture:(Texture*)inTexture
{
    mTexture = inTexture;
    [mTexture retain];
}

-(void)Draw
{
}

-(void)Update:(u32)inFrameTime
{
}

-(void)GetBoundingBox:(BoundingBox*)outBoundingBox
{
    CopyBoundingBox(&mBoundingBox, outBoundingBox);
}

-(void)Remove
{
}

-(void)dealloc
{
    [mTexture release];
    [mSkeleton release];
    
    [super dealloc];
}

-(void)BindSkeleton:(Skeleton*)inSkeleton
{
    if (mSkeleton != NULL)
    {
        [mSkeleton release];
    }
    
    mSkeleton = inSkeleton;
    [mSkeleton retain];
}

-(void)BindSkeletonWithFilename:(NSString*)inFilename
{
    if (mSkeleton != NULL)
    {
        [mSkeleton release];
    }
    
    NSNumber* handle = [[ResourceManager GetInstance] LoadAssetWithName:inFilename];
    
    NSData* skeletonData = [[ResourceManager GetInstance] GetDataForHandle:handle];
    
    mSkeleton = [[Skeleton alloc] InitWithData:skeletonData];
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:handle];
}

-(Skeleton*)GetSkeleton
{
    return mSkeleton;
}

-(void)SetGlowEnabled:(BOOL)inEnabled
{
    mGlowEnabled = inEnabled;
}

-(void)SetRenderStateOverride:(ModelRenderState*)renderState
{
    mUseOverride = TRUE;
    memcpy(&mRenderStateOverride, renderState, sizeof(ModelRenderState));
}

-(void)ClearRenderStateOverride
{
    mUseOverride = FALSE;
}

-(void)SetClipPlaneEnabled:(BOOL)inEnabled
{
    mClipPlaneEnabled = inEnabled;
}

-(void)SetClipPlane:(Plane*)inPlane
{
    ClonePlane(inPlane, &mClipPlane);
}

@end