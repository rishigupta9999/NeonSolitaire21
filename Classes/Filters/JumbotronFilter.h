//
//  JumbotronFilter.h
//
//  Copyright 2013 Neon Games. All rights reserved.
//

#import "Filter.h"

@class Framebuffer;
@class CameraOrtho;
@class Path;

typedef struct
{
    Texture*        mSourceTexture;
    Framebuffer*    mDestFramebuffer;
    float           mMinNoise;
    float           mMaxNoise;
    BOOL            mFlickerEnabled;
    BOOL            mUseColorOffsets;
} JumbotronFilterParams;

typedef struct
{
    Path*           mNoisePath;
    float           mUpperAmount;
    float           mLowerAmount;
} NoiseEffect;

typedef struct
{
    Path*           mFlickerPath;
} FlickerEffect;

@interface JumbotronFilter : Filter
{
    Texture*        mSourceTexture;
    Texture*        mCirclePixelTexture;
    Texture*        mNoiseTexture;
    Framebuffer*    mDestFramebuffer;
    Framebuffer*    mCompositingFramebuffer;
    CameraOrtho*    mCameraOrtho;
    
    NoiseEffect     mNoiseEffect;
    FlickerEffect   mFlickerEffect;
    
    BOOL            mFlickerEnabled;
    BOOL            mUseColorOffsets;
}

-(JumbotronFilter*)InitWithParams:(JumbotronFilterParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(JumbotronFilterParams*)outParams;

-(void)InitNoiseEffect:(BOOL)inFirst;
-(void)InitFlickerEffect:(BOOL)inFirst;

-(void)Draw;
-(void)Update:(CFTimeInterval)inTimeStep;

-(void)UpdateNoiseEffect:(CFTimeInterval)inTimeStep;
-(void)UpdateFlickerEffect:(CFTimeInterval)inTimeStep;

-(float)GetFlickerAmount;

@end