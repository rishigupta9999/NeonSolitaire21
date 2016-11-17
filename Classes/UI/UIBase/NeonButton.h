//
//  NeonButton.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "Button.h"
#import "Color.h"
#import "PlacementValue.h"
#import "UISounds.h"
#import "LocalizationManager.h"

@class BloomGaussianFilter;

typedef enum
{
    NEON_BUTTON_QUALITY_HIGH,
    NEON_BUTTON_QUALITY_MEDIUM,
    NEON_BUTTON_QUALITY_LOW,
    NEON_BUTTON_QUALITY_NUM
} NeonButtonQuality;

typedef enum
{
    TOGGLE_STATE_FIRST,
    TOGGLE_STATE_SECOND,
    TOGGLE_STATE_NUM
} ToggleState;

typedef struct
{
    NSString*           mTexName;
    NSString*           mPressedTexName;
    NSString*           mToggleTexName;
    NSString*           mBackgroundTexName;
    NSString*           mPregeneratedGlowTexName;
    BOOL                mBloomBackground;
    NeonButtonQuality   mQuality;
    u32                 mFadeSpeed;

    NSString*       mText;
    NeonFontType    mFontType;
    u32             mTextSize;
    u32             mBorderSize;
    Color           mTextColor;
    Color           mBorderColor;
    PlacementValue  mTextPlacement;
    
    BOOL            mBoundingBoxCollision;
    Vector2         mBoundingBoxBorderSize;
    
    UIGroup*        mUIGroup;
    
    UISoundId       mUISoundId;
} NeonButtonParams;

typedef enum
{
    PULSE_STATE_NORMAL,
    PULSE_STATE_POSITIVE,
    PULSE_STATE_HIGHLIGHTED,
    PULSE_STATE_NEGATIVE,
    PULSE_STATE_TRANSITION_TO_PAUSE,
    PULSE_STATE_TRANSITION_FROM_PAUSE,
    PULSE_STATE_PAUSED,
} PulseState;

@interface NeonButton : Button
{
    NeonButtonParams        mParams;
    Texture*                mBaseTexture;
    Texture*                mToggleTexture;
    Texture*                mBackgroundTexture;
    Texture*                mTextTexture;
        
    NSMutableArray*         mBlurLayers;
    
    float                   mBlurLevel;
    
    Path*                   mUsePath;
    
    Path*                   mEnabledPath;
    Path*                   mHighlightedPath;
    Path*                   mTransitionPath;
        
    PulseState              mPulseState;
    
    u32                     mTextStartX;
    u32                     mTextStartY;
    u32                     mTextEndX;
    u32                     mTextEndY;
    
    u32                     mFrameDelay;
    
    BOOL                    mPregeneratedGlow;
    
    ToggleState             mToggleState;
}

-(NeonButton*)InitWithParams:(NeonButtonParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(NeonButtonParams*)outParams;

-(void)BuildEnabledPath;
-(void)BuildPositiveHighlightedPath;
-(void)BuildNegativeHighlightedPath;
-(void)BuildPathToTarget:(float)inTarget withTime:(float)inTime;

-(void)DrawOrtho;

-(void)StatusChanged:(UIObjectState)inState;
-(void)DispatchEvent:(ButtonEvent)inEvent;

-(void)SetToggleOn:(BOOL)inToggleOn;
-(BOOL)GetToggleOn;

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint;
-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceRay;
-(Texture*)GetUseTexture;

-(void)CalculateTextPlacement;

-(u32)GetWidth;
-(u32)GetHeight;

-(void)SetPulseAmount:(float)inPercent time:(float)inTime;
-(void)ResumePulse:(float)inTime;

@end