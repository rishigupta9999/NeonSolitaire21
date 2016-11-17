//
//  Stinger.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "GameObject.h"
#import "Color.h"
#import "TouchSystem.h"

@class TextBox;
@class RenderGroup;
@class GameObjectCollection;
@class AnimatedIcon;

typedef enum
{
    STINGER_TYPE_MINOR,
    STINGER_TYPE_MAJOR,
    STINGER_TYPE_DEALER_DIALOG_TIMED,
    STINGER_TYPE_DEALER_DIALOG_CLICKTHRU,
    STINGER_TYPE_DEALER_DIALOG_INDEFINITE,
    STINGER_TYPE_INVALID
} StingerType;

typedef enum
{
    STINGER_STATE_INTRO,
    STINGER_STATE_MAINTAIN,
    STINGER_STATE_PHASE_OUT,
    STINGER_STATE_PHASE_IN,
    STINGER_STATE_EXPIRING,
    STINGER_STATE_PENDING_EXPIRATION,
    STINGER_STATE_INVALID
} StingerState;

typedef struct
{
    NSMutableArray*	mPrimary;
    NSMutableArray*	mSecondary;
    CFTimeInterval	mDuration;
    Color			mColor;
    StingerType		mType;
	RenderGroup*	mRenderGroup;
    Vector2         mRenderOffset;
    Vector2         mRenderScale;
    float           mFontSize;
    NSString*       mFontName;
    CTTextAlignment mFontAlignment;
	BOOL			mDrawBar;
} StingerParams;

typedef enum
{
    STINGER_PARAMETER_DYNAMIC,
    STINGER_PARAMETER_PREGENERATED,
    STINGER_PARAMETER_MAX,
    STINGER_PARAMETER_INVALID = STINGER_PARAMETER_MAX
} StingerParameterType;

@interface StingerParameter : NSObject
{
    @public
        NSString*               mParameterData;
        StingerParameterType    mParameterType;
}

-(StingerParameter*)Init;
-(void)dealloc;
+(StingerParameter*)MakeStingerParameter:(NSString*)inParameterData type:(StingerParameterType)inParameterType;

@end

typedef enum
{
    STINGER_ROW_PRIMARY,
    STINGER_ROW_SECONDARY
} StingerRow;

@interface StingerEntry : NSObject
{
    @public
        NSMutableArray* mTextures;
        u32             mContentWidth;
        u32             mContentHeight;
        u32             mBorderSize;
        u32             mRetinaScaleFactor;
        BOOL            mForcePremultipliedAlpha;
}

-(StingerEntry*)Init;
-(void)dealloc;

-(void)AddTextureLayer:(Texture*)inTexture;

@end


@interface Stinger : GameObject<TouchListenerProtocol>
{
    CFTimeInterval          mTimeRemaining;
    
    Path*                   mBarTopPath;
    Path*                   mBarBottomPath;
    
    Path*                   mBarAlphaPath;
    Path*                   mColorPath[4];
    
    Color                   mColor;
    Path*                   mColorMultiplyPath;
    
    Path*                   mSizePath;
    Path*                   mTapToContinueAlphaPath;
        
    Color                   mDrawColors[4];
    
    StingerType             mStingerType;
    BOOL                    mIndefiniteStinger;
    StingerState            mStingerState;
    
    NSMutableArray*         mPrimaryStingerEntries;
    NSMutableArray*         mSecondaryStingerEntries;
    
    TextBox*                mTapToContinueIndicator;
    AnimatedIcon*           mTapToContinueIconIndicator;
    
    u32                     mPrimaryHeight;
    u32                     mPrimaryWidth;
    u32                     mSecondaryHeight;
    u32                     mSecondaryWidth;
    
    u32                     mPrimaryBorderSize;
    u32                     mSecondaryBorderSize;
    
    u32                     mPrevTotalHeight;
    u32                     mTotalHeight;
    
    u32                     mCurPhase;
    u32                     mNumPhases;
    
    StingerParams           mParams;
    
    u32                     mCountdown;
    BOOL                    mRetina;
    
    CFTimeInterval          mDealerDialogFadeOutTime;
    CFTimeInterval          mDealerDialogFadeInTime;
    
@public
    BOOL                    mStingerCausedPause;
}

-(Stinger*)InitWithParams:(StingerParams*)inParams;
-(void)dealloc;
-(GameObject*)Remove;

-(void)DrawOrtho;
-(void)Update:(CFTimeInterval)inTimeStep;

+(void)InitDefaultParams:(StingerParams*)outParams;

-(void)BuildStingerTexture:(StingerRow)inStingerRow stingerEntry:(StingerEntry*)inStingerEntry params:(StingerParameter*)inParams;
-(void)LoadPregeneratedStingerTexture:(StingerEntry*)inStingerEntry filename:(NSString*)inFilename;

-(void)BuildBarPath;
-(void)BuildBarAlphaPath;
-(void)BuildColorPath;
-(void)BuildColorTransitionPath;
-(void)BuildTapToContinueAlphaPath;

-(void)DrawBar;
-(void)DrawBloom:(NSArray*)inTextureLayers scale:(float)inScale forcePremultipliedAlpha:(BOOL)inForcePremultipliedAlpha;

-(void)SetColor:(Color*)inColor;
-(void)SetColorPerVertex:(Color*)inColors;

-(void)BuildSizePath;

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;

-(void)GenerateStingerData;
-(void)PhaseOut;
-(void)PhaseIn;

-(BOOL)Terminate;

-(GameObjectCollection*)GetGameObjectCollection;
-(StingerState)GetStingerState;

@end