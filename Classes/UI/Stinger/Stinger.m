//
//  Stinger.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "Stinger.h"

#import "TextTextureBuilder.h"
#import "BloomGaussianFilter.h"
#import "GameObjectManager.h"
#import "GameStateMgr.h"

#import "PNGTexture.h"

#import "ImageProcessorDefines.h"
#import "AnimatedIcon.h"

#import "Event.h"
#import "UISounds.h"

#import "RenderGroup.h"
#import "Framebuffer.h"
#import "UINeonEngineDefines.h"

#import "ModelManager.h"
#import "NeonColorDefines.h"

#import "SplitTestingSystem.h"

#define STINGER_DEBUG_LOAD_TIME (0)

#define FADE_OUT_PERCENT    (0.75)
#define ANIMATE_IN_PERCENT  (0.25)

#define NUM_PHASES  (9)

#define STINGER_DEFAULT_CAPACITY (2)
#define STINGER_ENTRIES_DEFAULT_CAPACITY (5)

#define STINGER_PRIMARY_POINT_SIZE (32)
#define STINGER_SECONDARY_POINT_SIZE (16)

#define STINGER_TEXTURE_BORDER_SIZE         (16.0f)
#define STINGER_SEPARATION                  (4.0f)

#define DEALER_DIALOG_TEXTURE_BORDER_SIZE   (0.0f)
#define DEALER_DIALOG_FONT_SIZE             (12.0f)
#define DEALER_DIALOG_BAR_BORDER_SIZE       (8.0f)

static float DEALER_DIALOG_CLICK_FADE_OUT_TIME = 0.75f;
static float DEALER_DIALOG_CLICK_FADE_IN_TIME = 0.5f;

#define DEALER_DIALOG_CLICK_PHASE_IN_TIME   (0.5f)

#define DEALER_DIALOG_CONTINUE_INDICATOR_FRAME_TIME (0.25f)

#define TAP_TO_CONTINUE_FADE_IN_SPEED          (2.0f)
#define TAP_TO_CONTINUE_FADE_OUT_SPEED         (4.0f)
#define TAP_TO_CONTINUE_PERIOD                 (1.0f)

#define STINGER_COUNTDOWN_FRAMES            (3)

#define STINGER_GUTTER_SIZE                 (16)

@implementation StingerParameter

-(StingerParameter*)Init
{
    mParameterData = NULL;
    mParameterType = STINGER_PARAMETER_INVALID;
    
    return self;
}

+(StingerParameter*)MakeStingerParameter:(NSString*)inParameterData type:(StingerParameterType)inParameterType
{
    StingerParameter* parameter = [(StingerParameter*)[StingerParameter alloc] Init];
    [parameter autorelease];
    
    [inParameterData retain];
    
    parameter->mParameterData = inParameterData;
    parameter->mParameterType = inParameterType;
    
    return parameter;
}

-(void)dealloc
{
    [mParameterData release];
    [super dealloc];
}

@end

@implementation StingerEntry

-(StingerEntry*)Init
{
    mTextures = [[NSMutableArray alloc] initWithCapacity:STINGER_ENTRIES_DEFAULT_CAPACITY];
    mContentWidth = 0;
    mContentHeight = 0;
    mBorderSize = 0;
    mRetinaScaleFactor = 1.0;
    mForcePremultipliedAlpha = TRUE;
    
    return self;
}

-(void)dealloc
{
    [mTextures release];
    
    [super dealloc];
}

-(void)AddTextureLayer:(Texture*)inTexture
{
    [mTextures addObject:inTexture];
}

@end

@implementation Stinger

-(Stinger*)InitWithParams:(StingerParams*)inParams
{
#if STINGER_DEBUG_LOAD_TIME
    CFTimeInterval start = CFAbsoluteTimeGetCurrent();
#endif
    
    [super Init];
	
	// Save off params
	memcpy(&mParams, inParams, sizeof(StingerParams));
	
	[mParams.mRenderGroup retain];
    
	// Create other necessary structures
    mPrimaryStingerEntries = [[NSMutableArray alloc] initWithCapacity:STINGER_DEFAULT_CAPACITY];
    mSecondaryStingerEntries = [[NSMutableArray alloc] initWithCapacity:STINGER_DEFAULT_CAPACITY];
    
    mStingerType = inParams->mType;
    mTimeRemaining = inParams->mDuration;
    
    mCurPhase = 0;
    mNumPhases = 1;
    
    mPrevTotalHeight = 0;
    
    mCountdown = STINGER_COUNTDOWN_FRAMES;
    
    mRetina = GetScreenRetina();
    
    mDealerDialogFadeOutTime = DEALER_DIALOG_CLICK_FADE_OUT_TIME;
    mDealerDialogFadeInTime = DEALER_DIALOG_CLICK_FADE_IN_TIME;
    
    mDealerDialogFadeOutTime = 0.25f;
    mDealerDialogFadeInTime = 0.25f;
    
    // Set duration
    switch(mStingerType)
    {
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            mIndefiniteStinger = TRUE;
            mStingerState = STINGER_STATE_INTRO;
            break;
        }
        
        default:
        {
            mIndefiniteStinger = FALSE;
            mCountdown = STINGER_COUNTDOWN_FRAMES;
            mStingerState = STINGER_STATE_PENDING_EXPIRATION;
            break;
        }
    }
    
    mTapToContinueAlphaPath = [(Path*)[Path alloc] Init];
    [self BuildTapToContinueAlphaPath];
    
    // Touch handling for indefinite stingers (stingers that will stay up forever until there is user input)
    if (mIndefiniteStinger)
    {
        if (mStingerType == STINGER_TYPE_DEALER_DIALOG_CLICKTHRU)
        {
            [[TouchSystem GetInstance] AddListener:self withPriority:TOUCHSYSTEM_PRIORITY_STINGER];
            
            TextBoxParams tbParams;
            
            [TextBox InitDefaultParams:&tbParams];
            
            SetColorFromU32(&tbParams.mColor,		NEON_WHI);
            SetColorFromU32(&tbParams.mStrokeColor, NEON_BLA);
            
            tbParams.mStrokeSize	= 2;
            tbParams.mString		= NSLocalizedString(@"LS_TapToContinue", NULL);
            tbParams.mFontSize		= 12;
            tbParams.mFontType		= NEON_FONT_NORMAL;
            
            mTapToContinueIndicator = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
            
            PlacementValue placementValue;
            SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
            
            [mTapToContinueIndicator SetPlacement:&placementValue];
            [[self GetGameObjectCollection] Add:mTapToContinueIndicator withRenderBin:RENDERBIN_UI];
            
            [mTapToContinueIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_IN_SPEED];
            [mTapToContinueIndicator SetVisible:FALSE];
            [mTapToContinueIndicator Enable];
            
            [mTapToContinueAlphaPath SetTime:0.0f];
            [mTapToContinueIndicator AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:mTapToContinueAlphaPath];
        }
        
        mNumPhases = [inParams->mPrimary count];
    }
    else
    {
        mTapToContinueIndicator = NULL;
    }
	
	float framebufferWidth = 480.0f;
	float framebufferHeight = 320.0f;
	
	if (mParams.mRenderGroup != NULL)
	{
		Framebuffer* framebuffer = [mParams.mRenderGroup GetFramebuffer];
		
		framebufferWidth = [framebuffer GetWidth];
		framebufferHeight = [framebuffer GetHeight];
	}
    
    // Set position
    switch(mStingerType)
    {
        case STINGER_TYPE_DEALER_DIALOG_TIMED:
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            NSAssert([inParams->mSecondary count] == 0, @"No secondary parameters are supported for dealer dialog");
            
            [self SetPositionX:((framebufferWidth / 2.0f) + mParams.mRenderOffset.mVector[x]) Y:(50.0 + mParams.mRenderOffset.mVector[y]) Z:0.0];
            
            break;
        }
        
        default:
        {
            [self SetPositionX:((framebufferWidth / 2.0f) + mParams.mRenderOffset.mVector[x]) Y:(120.0 + mParams.mRenderOffset.mVector[y]) Z:0.0];
            break;
        }
    }
    
    // Set scale
    [self SetScaleX:mParams.mRenderScale.mVector[x] Y:mParams.mRenderScale.mVector[y] Z:1.0f];
    
    switch(mStingerType)
    {
        case STINGER_TYPE_MAJOR:
        {
            mColorMultiplyPath = NULL;
            
            for (int i = 0; i < 4; i++)
            {
                mColorPath[i] = [(Path*)[Path alloc] Init];
            }
            
            [self BuildColorPath];
            
            break;
        }
        
        case STINGER_TYPE_MINOR:
        case STINGER_TYPE_DEALER_DIALOG_TIMED:
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            memset(mColorPath, 0, sizeof(mColorPath));
            
            mColorMultiplyPath = [(Path*)[Path alloc] Init];
            mColor = inParams->mColor;

            [self BuildColorTransitionPath];
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown stinger type");
            break;
        }
    }
    
    for (int i = 0; i < 4; i++)
    {
        SetColorFloat(&mDrawColors[i], 0.0, 0.0, 0.0, 0.0);
    }
    
    [self GenerateStingerData];
                
    mBarTopPath = [(Path*)[Path alloc] Init];
    mBarBottomPath = [(Path*)[Path alloc] Init];
    mBarAlphaPath = [(Path*)[Path alloc] Init];
    
    [self BuildBarPath];
    [self BuildBarAlphaPath];
    
    if (mStingerType == STINGER_TYPE_MAJOR)
    {
        mSizePath = [((Path*)[Path alloc]) Init];        
        [self BuildSizePath];
    }
        
    mOrtho = TRUE;
    
    mStingerCausedPause = FALSE;
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_STINGER_CREATED withData:self];

#if STINGER_DEBUG_LOAD_TIME        
    CFTimeInterval end = CFAbsoluteTimeGetCurrent();
            
    NSLog(@"Load time is %f\n", end - start);
#endif
        
    return self;
}

-(void)dealloc
{
    [mBarTopPath release];
    [mBarBottomPath release];
    [mBarAlphaPath release];
    [mColorMultiplyPath release];
    [mTapToContinueAlphaPath release];
    
    [mSizePath release];
    
    [mPrimaryStingerEntries release];
    [mSecondaryStingerEntries release];
    
    [mParams.mPrimary release];
    [mParams.mSecondary release];
	
	[mParams.mRenderGroup release];
        
    for (int i = 0; i < 4; i++)
    {
        [mColorPath[i] release];
    }
    
    [mTapToContinueIndicator release];
    [mTapToContinueIconIndicator release];
    
    [super dealloc];
}

-(GameObject*)Remove
{
    if (mIndefiniteStinger)
    {
        [[TouchSystem GetInstance] RemoveListener:self];
    }
    
    return [super Remove];
}

+(void)InitDefaultParams:(StingerParams*)outParams
{
    outParams->mPrimary = [[NSMutableArray alloc] initWithCapacity:STINGER_DEFAULT_CAPACITY];
    outParams->mSecondary = [[NSMutableArray alloc] initWithCapacity:STINGER_DEFAULT_CAPACITY];
    outParams->mDuration = 1.0;
    outParams->mType = STINGER_TYPE_MINOR;
    SetColor(&outParams->mColor, 255, 255, 255, 255);
	outParams->mRenderGroup = NULL;
    SetVec2(&outParams->mRenderOffset, 0.0f, 0.0f);
    SetVec2(&outParams->mRenderScale, 1.0f, 1.0f);
	outParams->mDrawBar = TRUE;
    outParams->mFontSize = 0.0f;
    outParams->mFontName = NULL;
    outParams->mFontAlignment = kCTTextAlignmentLeft;
}

-(void)BuildStingerTexture:(StingerRow)inStingerRow stingerEntry:(StingerEntry*)inStingerEntry params:(StingerParameter*)inParams
{
    // If we were provided a string, then we have to generate the text texture now
    // and perform a Gaussian Blur.
    
    // First generate the text.
    TextTextureParams textParams;
    
    [TextTextureBuilder InitDefaultParams:&textParams];
    
    switch(inStingerRow)
    {
        case STINGER_ROW_PRIMARY:
        {
            textParams.mPointSize = STINGER_PRIMARY_POINT_SIZE;
            break;
        }
        
        case STINGER_ROW_SECONDARY:
        {
            textParams.mPointSize = STINGER_SECONDARY_POINT_SIZE;
            break;
        }
        
        default:
        {
            break;
        }
    }
    
    switch(mStingerType)
    {
        case STINGER_TYPE_DEALER_DIALOG_TIMED:
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
			// Kking - Make clear. 
            textParams.mFontName = [NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
            textParams.mPointSize = DEALER_DIALOG_FONT_SIZE;
            textParams.mStrokeSize = 20;
			textParams.mStrokeColor = 0x000000FF;
            textParams.mColor = GetRGBAU32(&mColor);
            
            if (mStingerType == STINGER_TYPE_DEALER_DIALOG_TIMED)
            {
                textParams.mWidth = GetScreenVirtualWidth() * GetTextScaleFactor();
            }
            else
            {
                textParams.mWidth = (GetScreenVirtualWidth() - (2 * STINGER_GUTTER_SIZE)) * GetTextScaleFactor();
            }
            
            break;
        }
        
        default:
        {
            textParams.mFontName	= [NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_STYLISH]];
            textParams.mStrokeSize	= 3;
            textParams.mColor		= 0;
			textParams.mStrokeColor = 0xFFFFFFFF;
            break;
        }
    }
    
    int borderSize = 0;
    
    switch(mStingerType)
    {
        case STINGER_TYPE_DEALER_DIALOG_TIMED:
        {
            borderSize = DEALER_DIALOG_TEXTURE_BORDER_SIZE;
            break;
        }
        
        default:
        {
            borderSize = STINGER_TEXTURE_BORDER_SIZE;
            break;
        }
    }
    
    if (mParams.mFontSize != 0)
    {
        textParams.mPointSize = mParams.mFontSize;
    }
    
    if (mParams.mFontName != NULL)
    {
        textParams.mFontName = mParams.mFontName;
    }
    
	textParams.mPointSize *= GetTextScaleFactor();
	borderSize *= GetTextScaleFactor();
    
    textParams.mString = inParams->mParameterData;
    textParams.mLeadWidth = borderSize;
    textParams.mLeadHeight = borderSize;
    textParams.mTrailWidth = borderSize;
    textParams.mTrailHeight = borderSize;
    textParams.mPremultipliedAlpha = TRUE;
    textParams.mAlignment = mParams.mFontAlignment;
    
    Texture* textTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&textParams];
                
    inStingerEntry->mContentWidth = (float)(textParams.mEndX - textParams.mStartX) / GetTextScaleFactor();
    inStingerEntry->mContentHeight = (float)(textParams.mEndY - textParams.mStartY) / GetTextScaleFactor();
    inStingerEntry->mBorderSize = borderSize / GetTextScaleFactor();
    inStingerEntry->mForcePremultipliedAlpha = TRUE;
	
	[textTexture SetScaleFactor:GetTextScaleFactor()];
	inStingerEntry->mRetinaScaleFactor = GetTextScaleFactor();
    
    if ((mStingerType == STINGER_TYPE_MAJOR) || (mStingerType == STINGER_TYPE_MINOR))
    {
        // Now perform the Gaussian Blur
        BloomGaussianParams params;

        [BloomGaussianFilter InitDefaultParams:&params];
        
        params.mInputTexture = textTexture;
        params.mBorder = 0;
                
        BloomGaussianFilter* bloomFilter = [(BloomGaussianFilter*)[BloomGaussianFilter alloc] InitWithParams:&params];
        [bloomFilter Update:0.0];
        
        NSMutableArray* textureLayers = [bloomFilter GetTextureLayers];
        
        for (Texture* texture in textureLayers)
        {
            [inStingerEntry AddTextureLayer:texture];
        }
                    
        [bloomFilter release];
    }
    else
    {
        [textTexture SetMagFilter:GL_NEAREST minFilter:GL_NEAREST];
        [inStingerEntry AddTextureLayer:textTexture];
    }
}

-(void)LoadPregeneratedStingerTexture:(StingerEntry*)inStingerEntry filename:(NSString*)inFilename
{
    NSAssert( ([[inFilename pathExtension] caseInsensitiveCompare:@"stinger"] == NSOrderedSame),
                @"Stinger files must be of type .stinger" );
    
    NSNumber* resourceHandle = [[ResourceManager GetInstance] LoadAssetWithName:inFilename];
    NSData* stingerData = [[ResourceManager GetInstance] GetDataForHandle:resourceHandle];
    
    unsigned const char* stingerDataBytes = [stingerData bytes];
    
    StingerHeader header;
    
    memcpy(&header, stingerDataBytes, sizeof(header));
    
    NSAssert(header.mMagicNumber == STINGER_HEADER_MAGIC_NUMBER, @"Stinger magic number not present. This is most likely not a stinger file");
    NSAssert(header.mMajorVersion == STINGER_MAJOR_VERSION, @"Stinger major version mismatch");
    NSAssert(header.mMinorVersion == STINGER_MINOR_VERSION, @"Stinger minor version mismatch");
    
    int stingerIndex = 0;
    
    if ((header.mNumEmbeddedStingers > 1) && (mRetina))
    {
        stingerIndex = 1;
        inStingerEntry->mRetinaScaleFactor = GetContentScaleFactor();
    }
    
    inStingerEntry->mContentWidth = header.mContentWidth[stingerIndex];
    inStingerEntry->mContentHeight = header.mContentHeight[stingerIndex];
    inStingerEntry->mBorderSize = header.mBorderSize[stingerIndex];
    
    float divideFactor = (stingerIndex == 1) ? 2.0 : 1.0;
    
    inStingerEntry->mContentWidth /= divideFactor;
    inStingerEntry->mContentHeight /= divideFactor;
    inStingerEntry->mBorderSize /= divideFactor;
    
    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    textureParams.mMagFilter = GL_LINEAR;
    textureParams.mMinFilter = GL_LINEAR;
    
    Texture* texture = [(PNGTexture*)[PNGTexture alloc] InitWithBytes:(u8*)(stingerDataBytes + header.mStingerOffsets[stingerIndex])
                                                        bufferSize:([stingerData length] - header.mStingerOffsets[stingerIndex]) textureParams:&textureParams];
                                                        
    [inStingerEntry AddTextureLayer:texture];
    [texture release];
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:resourceHandle];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mStingerState)
    {
        case STINGER_STATE_PENDING_EXPIRATION:
        {
            mCountdown--;
            
            if (mCountdown <= 0)
            {
                mStingerState = STINGER_STATE_EXPIRING;
            }
            
            break;
        }
        
        case STINGER_STATE_EXPIRING:
        {
            if (mTimeRemaining <= 0.0)
            {
                [self Remove];
                
                if ((mStingerType == STINGER_TYPE_DEALER_DIALOG_CLICKTHRU) || (mStingerType == STINGER_TYPE_DEALER_DIALOG_INDEFINITE))
                {
                    [[GameStateMgr GetInstance] SendEvent:EVENT_STINGER_DISMISSED withData:self];
                }
                else
                {
                    [[GameStateMgr GetInstance] SendEvent:EVENT_STINGER_EXPIRED withData:self];
                }
            }
            
            [mBarAlphaPath Update:inTimeStep];
            
            mTimeRemaining -= inTimeStep;

            break;
        }
        
        case STINGER_STATE_INTRO:
        {
            if ([mBarTopPath Finished])
            {
                mStingerState = STINGER_STATE_MAINTAIN;
            }
            
            break;
        }
        
        case STINGER_STATE_PHASE_OUT:
        {
            if ([mColorMultiplyPath Finished])
            {
                [self PhaseIn];
            }
            
            break;
        }
        
        case STINGER_STATE_PHASE_IN:
        {
            if ([mColorMultiplyPath GetPathState] == PATH_STATE_PAUSED)
            {
                mStingerState = STINGER_STATE_MAINTAIN;
            }
            
            break;
        }
    }
    
    [mBarTopPath Update:inTimeStep];
    [mBarBottomPath Update:inTimeStep];

    for (int i = 0; i < 4; i++)
    {
        [mColorPath[i] Update:inTimeStep];
    }
    
    [mColorMultiplyPath Update:inTimeStep];
    
    [mSizePath Update:inTimeStep];
}

-(void)DrawOrtho
{
    NeonGLEnable(GL_BLEND);
    NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    float continueIndicatorX = GetScreenVirtualWidth() / 2.0f;
    float continueIndicatorY = (mTotalHeight / 2.0f) + DEALER_DIALOG_BAR_BORDER_SIZE;
    
    [mTapToContinueIndicator SetPositionX:continueIndicatorX Y:(mPosition.mVector[y] + continueIndicatorY - [mTapToContinueIndicator GetHeight]) Z:0.0];
    
	if (mParams.mDrawBar)
	{
		[self DrawBar];
	}
            
    Vector4 curColorVec;
    
    switch(mStingerType)
    {
        case STINGER_TYPE_MAJOR:
        {
            Color colors[4];
            
            for (int i = 0; i < 4; i++)
            {
                [mColorPath[i] GetValueVec4:&curColorVec];
                SetColorFromVec4(&colors[i], &curColorVec);
            }
            
            [self SetColorPerVertex:colors];

            break;
        }
        
        case STINGER_TYPE_MINOR:
        case STINGER_TYPE_DEALER_DIALOG_TIMED:
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            Color color;
            
            [mColorMultiplyPath GetValueVec4:&curColorVec];
            
            SetColorFromVec4(&color, &curColorVec);
            
            [self SetColor:&color];

            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown stinger type");
            break;
        }
    }
        
    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    {     
        Vector3 curSize = { { 1.0, 1.0, 1.0 } };
        
        if (mStingerType == STINGER_TYPE_MAJOR)
        {
            [mSizePath GetValueVec3:&curSize];
            
            glScalef(curSize.mVector[x], curSize.mVector[y], curSize.mVector[z]);
        }
                
        glPushMatrix();
        {
            if ([mSecondaryStingerEntries count] > 0)
            {
                glTranslatef(   (-(float)mPrimaryWidth / 2.0f) - mPrimaryBorderSize, 
                                (-(float)mTotalHeight / 2.0f) + mPrimaryBorderSize,
                                0.0f );
            }
            else
            {
                glTranslatef((-(float)mPrimaryWidth / 2.0) - mPrimaryBorderSize, -floor(((float)mTotalHeight / 2)), 0.0);
            }
            
            StingerEntry* primaryEntry = (StingerEntry*)[mPrimaryStingerEntries objectAtIndex:0];
            [self DrawBloom:primaryEntry->mTextures scale:(primaryEntry->mRetinaScaleFactor) forcePremultipliedAlpha:primaryEntry->mForcePremultipliedAlpha];
        }
        glPopMatrix();
        
        if ([mSecondaryStingerEntries count] > 0)
        {
            glPushMatrix();
            {
                glTranslatef(   -((float)mSecondaryWidth / 2.0) - mSecondaryBorderSize,
                                -((float)mTotalHeight / 2) + mSecondaryBorderSize + (float)mPrimaryHeight + STINGER_SEPARATION, 0.0);
                                
                StingerEntry* secondaryEntry = (StingerEntry*)[mSecondaryStingerEntries objectAtIndex:0];
                [self DrawBloom:secondaryEntry->mTextures scale:(secondaryEntry->mRetinaScaleFactor) forcePremultipliedAlpha:secondaryEntry->mForcePremultipliedAlpha];
            }
            glPopMatrix();
        }
    }
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();

    NeonGLDisable(GL_BLEND);
    
    NeonGLError();
}

-(void)DrawBar
{
    if (GetDevicePad())
    {
        // TODO: Do this only for iPad and calculate the values programmatically
        
        if ((mStingerType != STINGER_TYPE_DEALER_DIALOG_INDEFINITE) && (mStingerType != STINGER_TYPE_DEALER_DIALOG_CLICKTHRU))
        {
            NeonGLViewport(64, 0, 640, 1024);
        }
    }
    
    float regularVertex[12] = { -240, 0, 0,
                                -240, 1, 0,
                                 240, 0, 0,
                                 240, 1, 0 };
                             
    float color[16] = { 0.0, 0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0, 1.0,
                        0.0, 0.0, 0.0, 1.0 };
                        
    float* vertex = NULL;
    
    Vector3 curTopVec, curBottomVec;
    
    [mBarTopPath GetValueVec3:&curTopVec];
    [mBarBottomPath GetValueVec3:&curBottomVec];
    
    switch(mStingerType)
    {     
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            float gutterSize = 2 * (GetScreenVirtualWidth() - STINGER_GUTTER_SIZE);
                
            float extent = (GetScreenVirtualWidth() - gutterSize) / 2;
            
            regularVertex[0] = -extent;
            regularVertex[3] = -extent;
            regularVertex[6] = extent;
            regularVertex[9] = extent;
        }
        // Intentional fallthrough
        default:
        {
            vertex = regularVertex;
            
            vertex[1] = curBottomVec.mVector[y];
            vertex[4] = curTopVec.mVector[y];
            vertex[7] = curBottomVec.mVector[y];
            vertex[10] = curTopVec.mVector[y];
            break;
        }
    }
                                                
    Vector4 curAlpha;
    
    [mBarAlphaPath GetValueVec4:&curAlpha];
    
    for (int i = 0; i < 4; i++)
    {
         memcpy(color + (4 * i), curAlpha.mVector, 4 * sizeof(float));
    }
                        
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, 0, vertex);
    glColorPointer(4, GL_FLOAT, 0, color);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    if (GetDevicePad())
    {
        if ((mStingerType != STINGER_TYPE_DEALER_DIALOG_INDEFINITE) && (mStingerType != STINGER_TYPE_DEALER_DIALOG_CLICKTHRU))
        {
            NeonGLViewport(64, 32, 640, 960);
        }
    }
}

-(void)DrawBloom:(NSArray*)inTextureLayers scale:(float)inScale forcePremultipliedAlpha:(BOOL)inForcePremultipliedAlpha
{
    GLState glState;
    SaveGLState(&glState);
    
    float vertex[12] = {    0, 0, 0,
                            0, 1, 0,
                            1, 0, 0,
                            1, 1, 0 };
                            
    float texCoord[8] = {   0, 0,
                            0, 1,
                            1, 0,
                            1, 1  };
    
    BOOL premultipliedAlpha = (([inTextureLayers count] == 1) && ((mStingerType == STINGER_TYPE_MINOR) || (mStingerType == STINGER_TYPE_MAJOR))) || inForcePremultipliedAlpha;
    
    if (premultipliedAlpha)
    {
        NeonGLBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    }
    else
    {
        NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
           
    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    {
        u32 numTextures = [inTextureLayers count];
        
        Texture* baseTexture = (Texture*)[inTextureLayers objectAtIndex:(numTextures - 1)];
        glScalef( (float)[baseTexture GetGLWidth] / inScale, (float)[baseTexture GetGLHeight] / inScale, 0.0);
        
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
        
        float colorArray[16];
                                            
        for (int i = 0; i < 4; i++)
        {
            float r = GetRedFloat(&mDrawColors[i]);
            float g = GetGreenFloat(&mDrawColors[i]);
            float b = GetBlueFloat(&mDrawColors[i]);
            float a = GetAlphaFloat(&mDrawColors[i]);
			
            // Hack: We should only have to do this is premultiplied alpha is on.  But for minor stingers, this looks
            // better without.
            if ((premultipliedAlpha) && (mStingerType == STINGER_TYPE_MAJOR))
            {
                r *= a;
                g *= a;
                b *= a;
            }

            colorArray[(4 * i) + 0] = r;
            colorArray[(4 * i) + 1] = g;
            colorArray[(4 * i) + 2] = b;
            colorArray[(4 * i) + 3] = a;
        }
                
        glColorPointer(4, GL_FLOAT, 0, colorArray);
        glVertexPointer(3, GL_FLOAT, 0, vertex);
        glTexCoordPointer(2, GL_FLOAT, 0, texCoord);
        
        for (Texture* curTexture in inTextureLayers)
        {
            [curTexture Bind];
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }
                    
        [Texture Unbind];
    }
    glPopMatrix();
    
    RestoreGLState(&glState);
        
    NeonGLError();
}

-(void)BuildBarPath
{
    Vector3 startTop = { { 0.0, 0.0, 0.0 } };
    Vector3 startBottom = { { 0.0, 0.0, 0.0 } };
    Vector3 endTop = { { 0.0, -40.0, 0.0 } };
    Vector3 endBottom = { { 0.0, 40.0, 0.0 } };
    
    switch(mStingerType)
    {
        case STINGER_TYPE_MAJOR:
        {
            endTop.mVector[y] = -60.0;
            endBottom.mVector[y] = 60.0;
            break;
        }
        case STINGER_TYPE_DEALER_DIALOG_TIMED:
        {
            float barDistance = -((mTotalHeight / 2.0f) + DEALER_DIALOG_BAR_BORDER_SIZE);
            
            endTop.mVector[y] = -barDistance;
            endBottom.mVector[y] = barDistance;
                        
            break;
        }
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            float barDistance = -((mTotalHeight / 2.0f) + DEALER_DIALOG_BAR_BORDER_SIZE);
            
            endTop.mVector[y] = barDistance;
            endBottom.mVector[y] = (mTotalHeight / 2.0f) + DEALER_DIALOG_BAR_BORDER_SIZE;
            
            if (mCurPhase > 0)
            {
                float prevBarDistance = -((mPrevTotalHeight / 2.0f) + DEALER_DIALOG_BAR_BORDER_SIZE);
                
                startTop.mVector[y] = prevBarDistance;
                startBottom.mVector[y] = (mPrevTotalHeight / 2.0f) + DEALER_DIALOG_BAR_BORDER_SIZE;;
            }

            break;
        }
    }
    
    float endTime = (ANIMATE_IN_PERCENT * mTimeRemaining);
    
    if (mIndefiniteStinger)
    {
        switch(mStingerType)
        {
            case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
            case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
            {
                endTime = mDealerDialogFadeInTime;
                break;
            }
            default:
            {
                NSAssert(FALSE, @"Unknown stinger type");
                break;
            }
        }
    }

    [mBarTopPath AddNodeVec3:&startTop atTime:0.0];
    [mBarTopPath AddNodeVec3:&endTop atTime:endTime];
    
    [mBarBottomPath AddNodeVec3:&startBottom atTime:0.0];
    [mBarBottomPath AddNodeVec3:&endBottom atTime:endTime];
}

-(void)BuildBarAlphaPath
{
    Vector4 nearOpaque = { { 0.0, 0.0, 0.0, 0.625 } };
    Vector4 transparent = { { 0.0, 0.0, 0.0, 0.0 } };
    
    if (mIndefiniteStinger)
    {
        switch(mStingerType)
        {
            case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
            case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
            {
                [mBarAlphaPath AddNodeVec4:&nearOpaque atTime:0.0];
                [mBarAlphaPath AddNodeVec4:&transparent atTime:mDealerDialogFadeOutTime];
                break;
            }
            default:
            {
                NSAssert(FALSE, @"Unknown stinger type");
                break;
            }
        }
    }
    else
    {
        [mBarAlphaPath AddNodeVec4:&nearOpaque atTime:0.0];
        [mBarAlphaPath AddNodeVec4:&nearOpaque atTime:(FADE_OUT_PERCENT * mTimeRemaining)];
        [mBarAlphaPath AddNodeVec4:&transparent atTime:mTimeRemaining];
    }
}

-(void)BuildColorPath
{
    Vector4 green  = { { 0.0, 1.0, 0.0, 1.0 } };
    Vector4 red    = { { 1.0, 0.0, 0.0, 1.0 } };
    Vector4 yellow = { { 1.0, 1.0, 0.0, 1.0 } };
    Vector4 blue   = { { 0.0, 0.0, 1.0, 1.0 } };
    
    Vector4* colors[4] = { &green, &red, &yellow, &blue };
    
    float segmentTime = mTimeRemaining / 3;
    
    if (mIndefiniteStinger)
    {
        switch(mStingerType)
        {
            case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
            case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
            {
                segmentTime = mDealerDialogFadeInTime / 3;
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown stinger type");
                break;
            }
        }
    }
    
    for (int vertex = 0; vertex < 4; vertex++)
    {
        for (int color = 0; color < 4; color++)
        {
            Vector4 finalColor;
            
            CloneVec4(colors[(color + vertex) % 4], &finalColor);
            
            // Fade out towards the end
            if (color == 3)
            {
                finalColor.mVector[w] = 0.0;
            }
            
            [mColorPath[vertex] AddNodeVec4:&finalColor atTime:(segmentTime * color)];
        }
    }
}

-(void)BuildColorTransitionPath
{
    // Phases are:
    // - Transparent to black
    // - Wait at black
    // - Black to fully colored
    // - Wait at colored
    // - Fully colored to transparent
    //
    // Some of these phases may take longer than others
    
    float phaseLength = mTimeRemaining / (float)NUM_PHASES;
    
    float fadeInTime = mDealerDialogFadeInTime;
    
    if (mCurPhase > 0)
    {
        fadeInTime = DEALER_DIALOG_CLICK_PHASE_IN_TIME;
    }
    
    if (mIndefiniteStinger)
    {
        switch(mStingerType)
        {
            case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
            case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
            {
                [mColorMultiplyPath InsertPauseAtTime:fadeInTime];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown stinger type");
                break;
            }
        }
    }
    
    Vector4 transparent = { { 0.0, 0.0, 0.0, 0.0 } };
    Vector4 colored;
    
    switch(mStingerType)
    {
        // For dealer dialogue stingers, we apply color in the font (that way we can support font color tags).  So make this pure white.
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            SetVec4(&colored, 1.0f, 1.0f, 1.0f, 1.0f);
            break;
        }
        
        default:
        {
            SetVec4(&colored, GetRedFloat(&mColor), GetGreenFloat(&mColor), GetBlueFloat(&mColor), GetAlphaFloat(&mColor));
            break;
        }
    }
    
    [mColorMultiplyPath AddNodeVec4:&transparent atTime:0.0];
    
    switch(mStingerType)
    {
        case STINGER_TYPE_DEALER_DIALOG_CLICKTHRU:
        case STINGER_TYPE_DEALER_DIALOG_INDEFINITE:
        {
            [mColorMultiplyPath AddNodeVec4:&colored atTime:fadeInTime];
            [mColorMultiplyPath AddNodeVec4:&transparent atTime:(fadeInTime + mDealerDialogFadeOutTime)];
            break;
        }
        default:
        {
            [mColorMultiplyPath AddNodeVec4:&colored atTime:(phaseLength * 1.0)];
            [mColorMultiplyPath AddNodeVec4:&colored atTime:(phaseLength * 7.0)];
            [mColorMultiplyPath AddNodeVec4:&transparent atTime:(phaseLength * 8.0)];
            break;
        }
    }
}

-(void)BuildTapToContinueAlphaPath
{
    [mTapToContinueAlphaPath AddNodeScalar:1.0f atTime:0.0];
    [mTapToContinueAlphaPath AddNodeScalar:0.0f atTime:TAP_TO_CONTINUE_PERIOD];
    [mTapToContinueAlphaPath AddNodeScalar:1.0f atTime:(2.0f * TAP_TO_CONTINUE_PERIOD)];
    
    [mTapToContinueAlphaPath SetPeriodic:TRUE];
}

-(void)BuildSizePath
{
    Vector3 start = { { 1.0, 1.0, 1.0 } };
    Vector3 end = { { 2.0, 2.0, 2.0 } };
    
    [mSizePath AddNodeVec3:&start atTime:0.0];
    [mSizePath AddNodeVec3:&end atTime:mTimeRemaining];
}

-(void)SetColor:(Color*)inColor
{
    for (int i = 0; i < 4; i++)
    {
        mDrawColors[i] = *inColor;
    }
}

-(void)SetColorPerVertex:(Color*)inColors
{
    for (int i = 0; i < 4; i++)
    {
        mDrawColors[i] = inColors[i];
    }
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
    BOOL success = [self Terminate];
        
    return success ? TOUCHSYSTEM_CONSUME_PROJECTED : TOUCHSYSTEM_CONSUME_NONE;
}

-(void)GenerateStingerData
{
    int primaryHeight = 0;
    int primaryWidth = 0;

    int startIndex = 0;
    int endIndex = [mParams.mPrimary count];
    
    if (mIndefiniteStinger)
    {
        startIndex = mCurPhase;
        endIndex = mCurPhase + 1;
    }
    
    for (int primaryIndex = startIndex; primaryIndex < endIndex; primaryIndex++)
    {
        StingerParameter* stingerParameter = [mParams.mPrimary objectAtIndex:primaryIndex];
        StingerEntry* curStingerEntry = [(StingerEntry*)[StingerEntry alloc] Init];
        
        switch(stingerParameter->mParameterType)
        {
            case STINGER_PARAMETER_DYNAMIC:
            {
                [self BuildStingerTexture:STINGER_ROW_PRIMARY stingerEntry:curStingerEntry params:stingerParameter];
                break;
            }
            
            case STINGER_PARAMETER_PREGENERATED:
            {
                [self LoadPregeneratedStingerTexture:curStingerEntry filename:stingerParameter->mParameterData];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown stinger parameter type");
                break;
            }
        }
        
        if (curStingerEntry->mContentHeight > primaryHeight)
        {
            primaryHeight = curStingerEntry->mContentHeight;
        }
        
        primaryWidth += curStingerEntry->mContentWidth;
        
        [mPrimaryStingerEntries addObject:curStingerEntry];
        [curStingerEntry release];
    }
    
    mPrimaryHeight = primaryHeight;
    mPrimaryWidth = primaryWidth;
    
    // Add the border size to the total height, if there is at least one primary entry.  We assume all entries
    // have the same border size for now.  This assumption may change in the future.
    
    if ([mParams.mPrimary count] > 0)
    {
        mPrimaryBorderSize = ((StingerEntry*)[mPrimaryStingerEntries objectAtIndex:0])->mBorderSize;
        primaryHeight += (mPrimaryBorderSize * 2);
    }
    else
    {
        mPrimaryBorderSize = 0;
    }
    
    int secondaryHeight = 0;
    int secondaryWidth = 0;
    
    startIndex = 0;
    endIndex = [mParams.mSecondary count];
    
#if NEON_DEBUG
    if (mIndefiniteStinger)
    {
        NSAssert([mParams.mSecondary count] == 0, @"Indefinite stingers cannot have secondary arguments");
    }
#endif
            
    for (int secondaryIndex = 0; secondaryIndex < endIndex; secondaryIndex++)
    {
        StingerParameter* stingerParameter = [mParams.mSecondary objectAtIndex:secondaryIndex];
        StingerEntry* curStingerEntry = [(StingerEntry*)[StingerEntry alloc] Init];
        
        switch(stingerParameter->mParameterType)
        {
            case STINGER_PARAMETER_DYNAMIC:
            {
                [self BuildStingerTexture:STINGER_ROW_SECONDARY stingerEntry:curStingerEntry params:stingerParameter];
                break;
            }
            
            case STINGER_PARAMETER_PREGENERATED:
            {
                [self LoadPregeneratedStingerTexture:curStingerEntry filename:stingerParameter->mParameterData];
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown stinger parameter type");
                break;
            }
        }
        
        if (curStingerEntry->mContentHeight > secondaryHeight)
        {
            secondaryHeight = curStingerEntry->mContentHeight;
        }
        
        secondaryWidth += curStingerEntry->mContentWidth;
        
        [mSecondaryStingerEntries addObject:curStingerEntry];
        [curStingerEntry release];
    }
    
    mSecondaryHeight = secondaryHeight;
    mSecondaryWidth = secondaryWidth;
    
    // Add the border size to the total height, if there is at least one secondary entry.  Assume that all secondary
    // stinger entries have the same border.  This assumption may prove false in the future.
    
    if ([mParams.mSecondary count] > 0)
    {
        mSecondaryBorderSize = ((StingerEntry*)[mSecondaryStingerEntries objectAtIndex:0])->mBorderSize;
        secondaryHeight += (mSecondaryBorderSize * 2);
    }
    
    // For debug builds, verify that all primary entries have the same border, and all secondary entries have the same
    // border.  If this assumption ever fails, we may need to update the stinger layout math.
    
#if NEON_DEBUG
    for (StingerEntry* curEntry in mPrimaryStingerEntries)
    {
        if (curEntry->mBorderSize != mPrimaryBorderSize)
        {
            NSAssert(FALSE, @"Inconsistent primary stinger border sizes detected");
        }
    }
    
    for (StingerEntry* curEntry in mSecondaryStingerEntries)
    {
        if (curEntry->mBorderSize != mSecondaryBorderSize)
        {
            NSAssert(FALSE, @"Inconsistent secondary stinger border sizes detected");
        }
    }
#endif
    
    mPrevTotalHeight = mTotalHeight;
    mTotalHeight = primaryHeight + secondaryHeight;
}

-(void)PhaseOut
{
    mStingerState = STINGER_STATE_PHASE_OUT;
    [mTapToContinueIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_OUT_SPEED];
    [mTapToContinueIndicator Disable];
    
    [mTapToContinueIconIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_OUT_SPEED];
    [mTapToContinueIconIndicator Disable];
}

-(void)PhaseIn
{
    mStingerState = STINGER_STATE_PHASE_IN;
    
    [mPrimaryStingerEntries removeAllObjects];
    [mSecondaryStingerEntries removeAllObjects];
    
    [self GenerateStingerData];
    
    [mColorMultiplyPath Reset];
    [self BuildColorTransitionPath];
    
    [mBarTopPath Reset];
    [mBarBottomPath Reset];
    [self BuildBarPath];
    
    [mTapToContinueIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_IN_SPEED];
    [mTapToContinueIndicator Enable];
    
    [mTapToContinueIconIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_IN_SPEED];
    [mTapToContinueIconIndicator Enable];


    float continueIndicatorX = ((GetScreenVirtualWidth() - ([mTapToContinueIndicator GetWidth])) / 2.0f);
    float continueIndicatorY = mTotalHeight;

    [mTapToContinueIndicator SetPositionX:continueIndicatorX Y:continueIndicatorY Z:0.0];
}

-(BOOL)Terminate
{
    BOOL success = FALSE;
    
    if (mStingerState == STINGER_STATE_MAINTAIN)
    {
        [mColorMultiplyPath Play];

        mCurPhase++;
        
        // If there are no phases left to display, then start fading out the stinger
        if (mCurPhase >= mNumPhases)
        {
            mTimeRemaining = mDealerDialogFadeOutTime;
            mCountdown = STINGER_COUNTDOWN_FRAMES;
            mStingerState = STINGER_STATE_PENDING_EXPIRATION;
            
            [mTapToContinueIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_OUT_SPEED];
            [mTapToContinueIndicator RemoveAfterOperations];
            [mTapToContinueIndicator Disable];
            
            [mTapToContinueIconIndicator SetFadeSpeed:TAP_TO_CONTINUE_FADE_OUT_SPEED];
            [mTapToContinueIconIndicator RemoveAfterOperations];
            [mTapToContinueIconIndicator Disable];
            
			[UISounds PlayUISound:SFX_TUTORIAL_PRESSTOCONFIRM];
        }
        else
        {
            [self PhaseOut];
        }
        
        // Consume the event.  While a stinger is up, it has the highest input priority and no buttons
        // should respond to this touch event.
        success = TRUE;
    }
        
    return success;
}

-(GameObjectCollection*)GetGameObjectCollection
{
	GameObjectCollection* collection = [GameObjectManager GetInstance];
	
	if (mParams.mRenderGroup != NULL)
	{
		GameObjectCollection* renderGroupCollection = [mParams.mRenderGroup GetGameObjectCollection];
		
		if (renderGroupCollection != NULL)
		{
			collection = renderGroupCollection;
		}
	}
	
	return collection;
}

-(StingerState)GetStingerState
{
    return mStingerState;
}

@end