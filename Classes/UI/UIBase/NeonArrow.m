//
//  NeonArrow.m
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.
//

#import "NeonArrow.h"

static const char* sArrowheadName = "neonarrow_head.papng";
static const char* sArrowheadCenter = "neonarrow_center.papng";
static const char* sArrowheadTail = "neonarrow_tail.papng";

@implementation NeonArrow

-(NeonArrow*)initWithParams:(NeonArrowParams*)inParams
{
    [super InitWithUIGroup:inParams->mUIGroup];
    
    UIObjectTextureLoadParams textureLoadParams;
    [UIObject InitDefaultTextureLoadParams:&textureLoadParams];
    
    textureLoadParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    
    textureLoadParams.mTextureName = [NSString stringWithUTF8String:sArrowheadName];
    mHeadTexture = [self LoadTextureWithParams:&textureLoadParams];
    [mHeadTexture retain];
    
    textureLoadParams.mTextureName = [NSString stringWithUTF8String:sArrowheadCenter];
    mCenterTexture = [self LoadTextureWithParams:&textureLoadParams];
    [mCenterTexture retain];
    
    textureLoadParams.mTextureName = [NSString stringWithUTF8String:sArrowheadTail];
    mTailTexture = [self LoadTextureWithParams:&textureLoadParams];
    [mTailTexture retain];
    
    memcpy(&mParams, inParams, sizeof(NeonArrowParams));
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

+(void)InitDefaultParams:(NeonArrowParams*)outParams
{
    outParams->mUIGroup = NULL;
    outParams->mLength = 200;
}

-(void)DrawOrtho
{
    QuadParams  quadParams;
    
    [UIObject InitQuadParams:&quadParams];
    
    quadParams.mBlendEnabled = TRUE;
    quadParams.mTexture = mHeadTexture;

    quadParams.mColorMultiplyEnabled = TRUE;
    
    for (int i = 0; i < 4; i++)
    {
        SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, mAlpha);
    }

    [self DrawQuad:&quadParams withIdentifier:"ArrowHead"];
    
    quadParams.mTexture = mCenterTexture;
    quadParams.mScaleType = QUAD_PARAMS_SCALE_Y;
    SetVec2(&quadParams.mScale, 0, mParams.mLength);
    SetVec2(&quadParams.mTranslation, -1, [mHeadTexture GetEffectiveHeight] + 0.5);
    
    [self DrawQuad:&quadParams withIdentifier:"ArrowCenter"];
    
    quadParams.mTexture = mTailTexture;
    quadParams.mScaleType = QUAD_PARAMS_SCALE_NONE;
    SetVec2(&quadParams.mTranslation, 0, [mHeadTexture GetEffectiveHeight] + 0.5 + mParams.mLength);
    
    [self DrawQuad:&quadParams withIdentifier:"ArrowTail"];

}

@end