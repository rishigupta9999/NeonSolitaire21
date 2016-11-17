//
//  NeonButton.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "NeonButton.h"
#import "TextureManager.h"
#import "BloomGaussianFilter.h"
#import "TextTextureBuilder.h"
#import "CameraStateMgr.h"
#import "UIGroup.h"

#import "UISounds.h"

#define BORDER_SIZE                 (32.0)
#define BUTTON_HIGHLIGHT_SPEED      (5.0)

#define BUTTON_IDLE_LEAD_TIME               (4.0)
#define BUTTON_IDLE_SEGMENT_TIME            (0.5)
#define BUTTON_IDLE_ACCELERATE_INTENSITY    (0.2)
#define BUTTON_IDLE_MAX_INTENSITY           (0.7)

#define BUTTON_DEFAULT_FADE_SPEED   (10.0)

static const char PREGENERATED_GLOW_IDENTIFIER[] = "PregeneratedGlow_Identifier";
static const char BLUR_LEVEL_PREFIX_IDENTIFIER[] = "BlurLevel_Identifier";
static const char BASE_LEVEL_PREFIX_IDENTIFIER[] = "BaseLevel_Identifier";
static const char TEXT_PREFIX_IDENTIFIER[] = "Text_Identifier";

u32 sNumDownsampleLevels[NEON_BUTTON_QUALITY_NUM] = { 5, 3, 2 };

// Bitfields that indicate which texture layers to keep.  Least significant bit is the most detailed layer.
u32 sDiscardField[NEON_BUTTON_QUALITY_NUM] = { 0xFF, 0x15, 0x14 };

@implementation NeonButton

-(NeonButton*)InitWithParams:(NeonButtonParams*)inParams
{
    [super InitWithUIGroup:inParams->mUIGroup];
    
    if( inParams->mToggleTexName == NULL)
    {
        inParams->mToggleTexName = inParams->mTexName;
    }
    
    memcpy(&mParams, inParams, sizeof(NeonButtonParams));
    // We strictly don't need to save all these, but for debugging purposes, the slight memory hit is worth it
    [mParams.mTexName retain];
    [mParams.mToggleTexName retain];
    [mParams.mPregeneratedGlowTexName retain];
    [mParams.mBackgroundTexName retain];
    [mParams.mText retain];
     
    NSAssert( (((!mParams.mBoundingBoxCollision) && ( (mParams.mBoundingBoxBorderSize.mVector[x] == 0.0f) && (mParams.mBoundingBoxBorderSize.mVector[y] == 0.0f) )) ||
               (mParams.mBoundingBoxCollision)), @"Can only specify a bounding box border size if we're using bounding box collisions" );
    
    mFadeSpeed = mParams.mFadeSpeed;
    
    BloomGaussianFilter* bloomFilter = NULL;
    
    mPregeneratedGlow = FALSE;
    
    UIObjectTextureLoadParams textureLoadParams;
    [UIObject InitDefaultTextureLoadParams:&textureLoadParams];

    if (inParams->mTexName != NULL)
    {
        Texture* bloomTexture = NULL;
        
        textureLoadParams.mTexDataLifetime = TEX_DATA_RETAIN;
        textureLoadParams.mTextureName = inParams->mTexName;
        
        mBaseTexture = [self LoadTextureWithParams:&textureLoadParams];
        [mBaseTexture retain];
        
        if (inParams->mPregeneratedGlowTexName != NULL)
        {
            textureLoadParams.mTexDataLifetime = TEX_DATA_DISPOSE;
            textureLoadParams.mTextureName = inParams->mPregeneratedGlowTexName;
            
            mBackgroundTexture = [self LoadTextureWithParams:&textureLoadParams];
            [mBackgroundTexture retain];
            
            mPregeneratedGlow = TRUE;
        }
        else if (inParams->mBackgroundTexName != NULL)
        {
            textureLoadParams.mTexDataLifetime = TEX_DATA_DISPOSE;
            textureLoadParams.mTextureName = inParams->mBackgroundTexName;

            mBackgroundTexture = [self LoadTextureWithParams:&textureLoadParams];         
            [mBackgroundTexture retain];
               
            bloomTexture = mBackgroundTexture;
        }
        else
        {
            mBackgroundTexture = NULL;
            bloomTexture = mBaseTexture;
        }
        
        if ((inParams->mBloomBackground) && (inParams->mPregeneratedGlowTexName == NULL))
        {
            NSAssert(mGameObjectBatch == NULL || ([mGameObjectBatch GetTextureAtlas] == NULL), @"Texture atlases are unsupported for dynamic textures");
            
            NSAssert(inParams->mQuality >= 0 && inParams->mQuality < NEON_BUTTON_QUALITY_NUM, @"Invalid quality specified");
            
            BloomGaussianParams params;
            [BloomGaussianFilter InitDefaultParams:&params];
            
            params.mInputTexture = bloomTexture;
            params.mBorder = BORDER_SIZE;
            
            // Create all the downsample levels, then delete the ones we don't want
            params.mNumDownsampleLevels = sNumDownsampleLevels[NEON_BUTTON_QUALITY_HIGH];
            
            bloomFilter = [(BloomGaussianFilter*)[BloomGaussianFilter alloc] InitWithParams:&params];
            
            [bloomFilter Update:0.0];
        }
        
        if (inParams->mText != NULL)
        {
            TextTextureParams textParams;
            
            [TextTextureBuilder InitDefaultParams:&textParams];
            
            textParams.mFontType = inParams->mFontType;
            textParams.mPointSize = inParams->mTextSize * GetTextScaleFactor();
            textParams.mColor = GetRGBAU32(&inParams->mTextColor);
            textParams.mString = inParams->mText;
            textParams.mStrokeSize = inParams->mBorderSize * GetTextScaleFactor();
            textParams.mStrokeColor = GetRGBAU32(&inParams->mBorderColor);
            textParams.mTextureAtlas = (mGameObjectBatch != NULL) ? [mGameObjectBatch GetTextureAtlas] : NULL;
            textParams.mPremultipliedAlpha = (mGameObjectBatch != NULL) ? TRUE : FALSE;
            
            mTextTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&textParams];
            
            if (mTextTexture != NULL)
            {
                [mTextTexture retain];
                
                [mTextTexture SetScaleFactor:GetTextScaleFactor()];
                
                mTextStartX = textParams.mStartX / GetTextScaleFactor();
                mTextStartY = textParams.mStartY / GetTextScaleFactor();
                mTextEndX = textParams.mEndX / GetTextScaleFactor();
                mTextEndY = textParams.mEndY / GetTextScaleFactor();
                
                [self RegisterTexture:mTextTexture];
            }
        }
        else
        {   mTextTexture = NULL;
        
            mTextStartX = 0;
            mTextStartY = 0;
            mTextEndX = 0;
            mTextEndY = 0;
        }
        
        if (inParams->mToggleTexName != NULL)
        {
            textureLoadParams.mTexDataLifetime = TEX_DATA_DISPOSE;
            textureLoadParams.mTextureName = inParams->mToggleTexName;

            mToggleTexture = [self LoadTextureWithParams:&textureLoadParams];         
            [mToggleTexture retain];
        }
        else
        {
            mToggleTexture = NULL;
        }
        
        mEnabledPath = [(Path*)[Path alloc] Init];
        mHighlightedPath = [(Path*)[Path alloc] Init];
        mTransitionPath = [(Path*)[Path alloc] Init];
        
        mUsePath = mEnabledPath;
        mPulseState = PULSE_STATE_NORMAL;
                        
        [self BuildEnabledPath];
        
        [mUsePath SetTime:(((float)(arc4random_uniform(1000-1))) / 1000.0f * (float)BUTTON_IDLE_LEAD_TIME)];
    }
    else
    {
        NSAssert(FALSE, @"Untested case, NeonButton with no background texture");
        mBaseTexture = NULL;
    }
    
    if (bloomFilter != NULL)
    {
        [bloomFilter MarkCompleted];
        
        mBlurLayers = [bloomFilter GetTextureLayers];
        [mBlurLayers retain];
        
        int count = [mBlurLayers count];
        
        for (int curLayer = (count - 1); curLayer >= 0; curLayer--)
        {
            int mask = (1 << (sNumDownsampleLevels[NEON_BUTTON_QUALITY_HIGH] - curLayer - 1));
            
            if ((sDiscardField[mParams.mQuality] & mask) == 0)
            {
                [mBlurLayers removeObjectAtIndex:curLayer];
            }
        }
        
        [bloomFilter release];
    }
    else
    {
        mBlurLayers = [[NSMutableArray alloc] initWithCapacity:1];
        [mBlurLayers addObject:mBackgroundTexture];
    }
    
    mFrameDelay = 3;
    mToggleState = TOGGLE_STATE_FIRST;
    
    return self;
}

-(void)dealloc
{
    // Release textures
    [mBaseTexture release];
    [mBackgroundTexture release];
    [mToggleTexture release];
    [mBlurLayers release];
    [mTextTexture release];
    
    // Release paths
    [mEnabledPath release];
    [mHighlightedPath release];
    [mTransitionPath release];
    
    // Release strings
    [mParams.mTexName release];
    [mParams.mToggleTexName release];
    [mParams.mBackgroundTexName release];
    [mParams.mText release];
    [mParams.mPregeneratedGlowTexName release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{    
    if (mFrameDelay > 0)
    {
        mFrameDelay--;
        return;
    }
    
    switch(mPulseState)
    {
        case PULSE_STATE_POSITIVE:
        {
            NSAssert(mUsePath == mHighlightedPath, @"Pulse state is positive, but not using the mHighlightedPath");
            
            if ([mHighlightedPath Finished])
            {
                mPulseState = PULSE_STATE_HIGHLIGHTED;
            }
            
            break;
        }
        
        case PULSE_STATE_NEGATIVE:
        {   
            NSAssert(mUsePath == mHighlightedPath, @"Pulse state is negative, but not using the mHighlightedPath");
            
            if ([mHighlightedPath Finished])
            {
                mPulseState = PULSE_STATE_NORMAL;
                mUsePath = mEnabledPath;
                
                [mEnabledPath SetTime:0.0];
            }
            
            break;
        }
        
        case PULSE_STATE_TRANSITION_TO_PAUSE:
        {
            NSAssert(mUsePath == mHighlightedPath, @"Pulse state is transitioning to pause, but not using the mHighlightedPath");
            
            if ([mHighlightedPath Finished])
            {
                mPulseState = PULSE_STATE_PAUSED;
            }
            
            break;
        }
        
        case PULSE_STATE_TRANSITION_FROM_PAUSE:
        {
            NSAssert(mUsePath == mHighlightedPath, @"Pulse state is transitioning from pause, but not using the mHighlightedPath");
            
            if ([mHighlightedPath Finished])
            {
                mPulseState = PULSE_STATE_NORMAL;
                mUsePath = mEnabledPath;
                
                [mEnabledPath SetTime:0.0];
            }
            
            break;
        }
    }
    
    [mUsePath GetValueScalar:&mBlurLevel];
    [mUsePath Update:inTimeStep];
    
    [super Update:inTimeStep];
}

-(void)DrawOrtho
{
    QuadParams quadParams;
    
    [UIObject InitQuadParams:&quadParams];
    
    quadParams.mColorMultiplyEnabled = TRUE;
    quadParams.mBlendEnabled = TRUE;
        
    // Draw background blur layers
    int count = [mBlurLayers count];
    
    float stepAmount = 1.0 / (float)count;
    float accumulatedStep = 1.0;
    
    if ((mParams.mBloomBackground) || (mPregeneratedGlow))
    {
        SetVec2(&quadParams.mTranslation, -BORDER_SIZE, -BORDER_SIZE);
    }
    
    int arrayIndex = 0;
    
    if (mPregeneratedGlow)
    {
        quadParams.mTexture = mBackgroundTexture;
        
        for (int i = 0; i < 4; i++)
        {
            SetColorFloat(&quadParams.mColor[i], 1.0f, 1.0f, 1.0f, mBlurLevel * mAlpha);
        }
                
        [self DrawQuad:&quadParams withIdentifier:PREGENERATED_GLOW_IDENTIFIER];
    }
    else
    {
        for (int curTexIndex = 0; curTexIndex < sNumDownsampleLevels[NEON_BUTTON_QUALITY_HIGH]; curTexIndex++)
        {
            int mask = (1 << (sNumDownsampleLevels[NEON_BUTTON_QUALITY_HIGH] - curTexIndex - 1));
            
            if ((sDiscardField[mParams.mQuality] & mask) == 0)
            {
                continue;
            }
            
            Texture* curTexture = [mBlurLayers objectAtIndex:arrayIndex];
            
            quadParams.mScaleType = QUAD_PARAMS_SCALE_BOTH;
            SetVec2(&quadParams.mScale, [curTexture GetGLWidth] * pow(2, (sNumDownsampleLevels[NEON_BUTTON_QUALITY_HIGH] - curTexIndex - 1)),
                    [curTexture GetGLHeight] * pow(2, (sNumDownsampleLevels[NEON_BUTTON_QUALITY_HIGH] - curTexIndex - 1)));
                        
            accumulatedStep -= stepAmount;
            
            float useAlpha = 1.0;

            if ((accumulatedStep + stepAmount) < mBlurLevel)
            {
                useAlpha = mAlpha;
            }
            else
            {
                float amount = (mBlurLevel - accumulatedStep) / stepAmount;
                
                if (amount < 0.0)
                {
                    amount = 0.0;
                }
                
                useAlpha = amount * mAlpha;
            }
            
            if (useAlpha > 0.0)
            {
                for (int i = 0; i < 4; i++)
                {
                    SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, useAlpha);
                }
                
                quadParams.mTexture = curTexture;
                
                static const int BLUR_BUFFER_SIZE = 64;
                char identifier[BLUR_BUFFER_SIZE];
                
                snprintf(identifier, BLUR_BUFFER_SIZE, "%s_%d", BLUR_LEVEL_PREFIX_IDENTIFIER, curTexIndex);
                
                [self DrawQuad:&quadParams withIdentifier:identifier];
            }
            
            quadParams.mScaleType = QUAD_PARAMS_SCALE_NONE;
            
            arrayIndex++;
        }
    }

    // Button itself and text don't honor the mBlur value.  They work only on alpha.
    for (int i = 0; i < 4; i++)
    {
        SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, mAlpha);
    }
    
    SetVec2(&quadParams.mTranslation, 0.0, 0.0);
    
    if (mToggleTexture != NULL)
    {
        switch(mToggleState)
        {
            case TOGGLE_STATE_FIRST:
            {
                quadParams.mTexture = mBaseTexture;
                break;
            }
            
            case TOGGLE_STATE_SECOND:
            {
                quadParams.mTexture = mToggleTexture;
                break;
            }
        }
    }
    else
    {
        quadParams.mTexture = mBaseTexture;
    }
    
    [self DrawQuad:&quadParams withIdentifier:BASE_LEVEL_PREFIX_IDENTIFIER];

    // Draw text (if applicable)
    if (mTextTexture)
    {
        s32 hAlign = GetHAlignPixels(&mParams.mTextPlacement);
        s32 vAlign = GetVAlignPixels(&mParams.mTextPlacement);
        
        SetVec2(&quadParams.mTranslation, (float)hAlign, (float)vAlign);
        quadParams.mTexture = mTextTexture;
        
        [self DrawQuad:&quadParams withIdentifier:TEXT_PREFIX_IDENTIFIER];
    }
        
    NeonGLError();
}

+(void)InitDefaultParams:(NeonButtonParams*)outParams
{
    outParams->mTexName					= NULL;
    outParams->mToggleTexName			= NULL;
    outParams->mBackgroundTexName		= NULL;
    outParams->mPregeneratedGlowTexName = NULL;
    outParams->mBloomBackground			= TRUE;
    outParams->mQuality					= NEON_BUTTON_QUALITY_HIGH;
    outParams->mFadeSpeed				= BUTTON_DEFAULT_FADE_SPEED;
	outParams->mUISoundId				= SFX_MISC_UNIMPLEMENTED;
    
    outParams->mText					= NULL;
    outParams->mFontType				= NEON_FONT_STYLISH;
    outParams->mTextSize				= 12;
    outParams->mBorderSize				= 0;
    
    SetColor(&outParams->mBorderColor, 0x00, 0x00, 0x00, 0xFF);
    SetColor(&outParams->mTextColor, 0x00, 0x00, 0x00, 0xFF);
    SetAbsolutePlacement(&outParams->mTextPlacement, 0, 0);
    
    outParams->mBoundingBoxCollision = FALSE;
    SetVec2(&outParams->mBoundingBoxBorderSize, 0.0f, 0.0f);
    
    outParams->mUIGroup = NULL;
}

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint
{
    Texture* useTexture = [self GetUseTexture];
	
    BOOL buttonTouched = FALSE;
    
    int testXMin = 0;
    int testYMin = 0;
    int testXMax = [useTexture GetEffectiveWidth];
    int testYMax = [useTexture GetEffectiveHeight];
    
    testXMin -= mParams.mBoundingBoxBorderSize.mVector[x];
    testYMin -= mParams.mBoundingBoxBorderSize.mVector[y];
    testXMax += mParams.mBoundingBoxBorderSize.mVector[x];
    testYMax += mParams.mBoundingBoxBorderSize.mVector[y];
	
    if ((inPoint->x >= testXMin) && (inPoint->y >= testYMin) && (inPoint->x < testXMax) && (inPoint->y < testYMax))
    {
        if (mParams.mBoundingBoxCollision)
        {
            buttonTouched = TRUE;
        }
        else
        {
            NSAssert(   ((testXMin >= 0) && (testYMin >= 0) && (testXMax <= ([useTexture GetEffectiveWidth])) && (testYMax <= [useTexture GetEffectiveHeight])),
                        @"Bounding Box Border was specified for this button, but we're not using bounding box collisions" );
                        
            // If we're inside the bounding box, let's get the texel associated with this point
            
            u32 texel = [useTexture GetTexel:inPoint];
            // Only a touch if we hit a part of the button with non-zero alpha.  Otherwise we clicked a transparent part.
            if ((texel & 0xFF) != 0)
            {
                buttonTouched = TRUE;
            }
        }
    }

    return buttonTouched;
}

-(BOOL)ProjectedHitTestWithRay:(Vector4*)inWorldSpaceRay
{
	// non-Bounding box collisions would involve calculating a texture coordinate and sampling it.
	// Not a big deal, just additional work.  We don't support that yet.
	NSAssert(mParams.mBoundingBoxCollision, @"We don't support non-bounding box collision yet.");
	
	Texture* useTexture = [self GetUseTexture];
	Rect3D	projectedCoords;
	
	[self GetProjectedCoordsForTexture:useTexture border:&mParams.mBoundingBoxBorderSize coords:&projectedCoords];
	
	Vector3 cameraPosition;
	[[CameraStateMgr GetInstance] GetPosition:&cameraPosition];
	
	Vector3 directionVector;
	SetVec3From4(&directionVector, inWorldSpaceRay);
	
	BOOL pointInRect = RayIntersectsRect3D(&cameraPosition, &directionVector, &projectedCoords);
	
	return pointInRect;
}

-(Texture*)GetUseTexture
{
	return mBaseTexture;
}

-(void)StatusChanged:(UIObjectState)inState
{
    [super StatusChanged:inState];
    
    switch(inState)
    {
        case UI_OBJECT_STATE_HIGHLIGHTED:
        {
            [UISounds PlayUISound:mParams.mUISoundId];
            
            [self BuildPositiveHighlightedPath];
            
            mPulseState = PULSE_STATE_POSITIVE;
            mUsePath = mHighlightedPath;
            break;
        }
        
        case UI_OBJECT_STATE_ENABLED:
        {
            if ((mPulseState == PULSE_STATE_POSITIVE) || (mPulseState == PULSE_STATE_HIGHLIGHTED))
            {
                mPulseState = PULSE_STATE_NEGATIVE;
                [self BuildNegativeHighlightedPath];
                
                mUsePath = mHighlightedPath;
            }
            
            break;
        }
    }
}

-(void)DispatchEvent:(ButtonEvent)inEvent
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            if (mToggleTexture != NULL)
            {
                switch(mToggleState)
                {
                    case TOGGLE_STATE_FIRST:
                    {
                        mToggleState = TOGGLE_STATE_SECOND;
                        break;
                    }
                    
                    case TOGGLE_STATE_SECOND:
                    {
                        mToggleState = TOGGLE_STATE_FIRST;
                        break;
                    }
                }
            }
            
            break;
        }
    }
    
    [super DispatchEvent:inEvent];
}

-(void)SetToggleOn:(BOOL)inToggleOn
{
    if (inToggleOn)
    {
        mToggleState = TOGGLE_STATE_SECOND;
    }
    else
    {
        mToggleState = TOGGLE_STATE_FIRST;
    }
}

-(BOOL)GetToggleOn
{
    if (mToggleState == TOGGLE_STATE_FIRST)
    {
        return FALSE;
    }
    
    return TRUE;
}

-(void)BuildEnabledPath
{
    [mEnabledPath AddNodeScalar:0.0 atTime:0.0];
    [mEnabledPath AddNodeScalar:0.0 atTime:BUTTON_IDLE_LEAD_TIME];
    [mEnabledPath AddNodeScalar:BUTTON_IDLE_ACCELERATE_INTENSITY atTime:BUTTON_IDLE_LEAD_TIME + BUTTON_IDLE_SEGMENT_TIME];
    [mEnabledPath AddNodeScalar:BUTTON_IDLE_MAX_INTENSITY atTime:BUTTON_IDLE_LEAD_TIME + 2 * BUTTON_IDLE_SEGMENT_TIME];
    [mEnabledPath AddNodeScalar:BUTTON_IDLE_ACCELERATE_INTENSITY atTime:BUTTON_IDLE_LEAD_TIME + 3 * BUTTON_IDLE_SEGMENT_TIME];
    [mEnabledPath AddNodeScalar:0.0 atTime:BUTTON_IDLE_LEAD_TIME + 4 * BUTTON_IDLE_SEGMENT_TIME];
    
    [mEnabledPath SetPeriodic:TRUE];
}

-(void)BuildPositiveHighlightedPath
{
    float curVal;
    
    [mUsePath GetValueScalar:&curVal];
    
    [mHighlightedPath Reset];
    [mHighlightedPath AddNodeScalar:curVal atIndex:0 withSpeed:BUTTON_HIGHLIGHT_SPEED];
    [mHighlightedPath AddNodeScalar:1.0 atIndex:1 withSpeed:BUTTON_HIGHLIGHT_SPEED];
}

-(void)BuildNegativeHighlightedPath
{
    float curVal;
    
    [mUsePath GetValueScalar:&curVal];
    
    [mHighlightedPath Reset];
    [mHighlightedPath AddNodeScalar:1.0 atIndex:0 withSpeed:BUTTON_HIGHLIGHT_SPEED];
    [mHighlightedPath AddNodeScalar:1.0 atIndex:1 withSpeed:BUTTON_HIGHLIGHT_SPEED];
    [mHighlightedPath AddNodeScalar:0.0 atIndex:2 withSpeed:BUTTON_HIGHLIGHT_SPEED];
}

-(void)BuildPathToTarget:(float)inTarget withTime:(float)inTime
{
    [mHighlightedPath Reset];
    [mHighlightedPath AddNodeScalar:mBlurLevel atTime:0.0f];
    [mHighlightedPath AddNodeScalar:inTarget atTime:inTime];
}

-(void)CalculateTextPlacement
{
    u32 outerWidth = [mBaseTexture GetEffectiveWidth];
    u32 outerHeight = [mBaseTexture GetEffectiveHeight];
    
    u32 innerWidth = mTextEndX - mTextStartX;
    u32 innerHeight = mTextEndY - mTextStartY;
    
    CalculatePlacement(&mParams.mTextPlacement, outerWidth, outerHeight, innerWidth, innerHeight);
}

-(u32)GetWidth
{
    return [mBaseTexture GetEffectiveWidth];
}

-(u32)GetHeight
{
    return [mBaseTexture GetEffectiveHeight];
}

-(void)SetPulseAmount:(float)inPercent time:(float)inTime
{
    [self BuildPathToTarget:inPercent withTime:inTime];
    
    mPulseState = PULSE_STATE_TRANSITION_TO_PAUSE;
    mUsePath = mHighlightedPath;
}

-(void)ResumePulse:(float)inTime
{
    float timeOffset = (((float)(arc4random_uniform(1000-1))) / 1000.0f * (float)BUTTON_IDLE_LEAD_TIME);
    [self BuildPathToTarget:0.0f withTime:(inTime + timeOffset)];
    
    mPulseState = PULSE_STATE_TRANSITION_FROM_PAUSE;
    mUsePath = mHighlightedPath;
}

@end