//
//  MiniGameTableEntity.m
//  Neon21
//
//  Copyright 2011 Neon Games. All rights reserved.
//

#import "MiniGameTableEntity.h"
#import "ModelManager.h"
#import "GameObjectManager.h"
#import "GameStateMgr.h"
#import "ReflectiveModel.h"

#import "TextureManager.h"
#import "Framebuffer.h"
#import "RenderGroupManager.h"
#import "RenderGroup.h"
#import "CameraStateMachine.h"
#import "StaticOrthoCameraState.h"
#import "PNGTexture.h"
#import "JPEGTexture.h"

#import "Flow.h"

#import "ImageWell.h"
#import "UINeonEngineDefines.h"
#import "NeonColorDefines.h"
#import "JumbotronFilter.h"

#import "GameEnvironment.h"
#import "LightManager.h"
#import "InAppPurchaseManager.h"
#import "LevelDefinitions.h"

#import <libkern/OSAtomic.h>

#import "NeonLightShaft.h"

static const char* MINIGAME_TABLE_STRING = "MiniGameTable";

static const CFTimeInterval AD_FADE_TIME        = 2.0;
static const CFTimeInterval AD_MAINTAIN_TIME    = 20.0;

static const float TABLET_REDUCTION_FACTOR      = 2.0;

const int JUMBOTRON_WIDTH = 417;
const int JUMBOTRON_HEIGHT  = 216;
static const float JUMBOTRON_MIN_NOISE = 0.20f;
static const float JUMBOTRON_MAX_NOISE = 0.35f;
static const float JUMBOTRON_RENDERGROUP_SCALE = 2.0f;

#define TABLET_LIGHT_CA (0.0)
#define TABLET_LIGHT_LA (0.0)
#define TABLET_LIGHT_QA (0.0)

#define TABLET_LIGHT_FLICKER_INTENSITY  (0.6)
#define TABLET_LIGHT_AMBIENT_SCALE      (0.15)

@implementation MiniGameTableEntity

-(MiniGameTableEntity*)InitWithEnvironment:(GameEnvironment*)inEnvironment
{
    [super Init];
    
    // Set puppet to be the center for bounding box calculations.  We'll manage the drawing of the the bezel ourselves.
    
    ModelParams modelParams;
    [ModelManager InitDefaultParams:&modelParams];
    
    modelParams.mFilename = [self GetAssetNameFromBaseName:@"MiniGameTableCenter" withExtension:@"STM"];
    modelParams.mReflective = TRUE;
    modelParams.mOwnerObject = self;
    
    mTableCenter = [[ModelManager GetInstance] ModelWithParams:&modelParams];
    [mTableCenter retain];
    
    [(ReflectiveModel*)mTableCenter SetReflectiveSurfaceTransform:[inEnvironment GetTableHeight] rotation:([inEnvironment GetTableRotationDegrees] - 90.0f)];
    
    modelParams.mFilename = [self GetAssetNameFromBaseName:@"MiniGameTableBezel" withExtension:@"STM"];
    modelParams.mReflective = FALSE;
    
    SetIdentity(&mBezelTransform);
    SetIdentity(&mTableSurfaceTransform);
    SetIdentity(&mScoreboardTransform);
    SetIdentity(&mTabletTransform);
    
    Matrix44 scale;
    GenerateTranslationMatrix(0.0, 1.0, 0.0, &mTabletTransform);
    GenerateScaleMatrix(1.0, 0.65, 1.0, &scale);
    MatrixMultiply(&mTabletTransform, &scale, &mTabletTransform);

    Matrix44 translation;
    Matrix44 rotation;
    
    GenerateTranslationMatrix(-7.786, 4.5, -2.914, &translation);
    GenerateRotationMatrix(RadiansToDegrees(0.823), 0, 1, 0, &rotation);
    
    // Taken from the Apple SceneKit editor.  Open the DAE file in Xcode and it'll give you the translation and axis/angle transform
    MatrixMultiply(&translation, &rotation, &mScoreboardTransform);
        
    mTableBezel = [[ModelManager GetInstance] ModelWithParams:&modelParams];
    [mTableBezel retain];
    
    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    
	// TODO: use 21Squared.pvrtc if in 21-Squared ; Run21.pvrtc in Run21
    Texture* texture = [[TextureManager GetInstance] TextureWithName:[[[Flow GetInstance] GetLevelDefinitions] GetMinitableTextureFilename]
                                                       textureParams:&textureParams];
    [mTableCenter SetTexture:texture];
    [mTableBezel SetTexture:texture];
	
	modelParams.mFilename = [self GetAssetNameFromBaseName:@"MiniGameTableScoreboard" withExtension:@"STM"];
	modelParams.mReflective = FALSE;
	
	// Create scoreboard resources    
	mTableScoreboard = [[ModelManager GetInstance] ModelWithParams:&modelParams];
	[mTableScoreboard retain];
		
	[self CreateScoreboardRenderGroup];
    [self CreateTabletRenderGroup];
    [self CreateJumbotronRenderGroup];

	[mTableScoreboard SetTexture:[[mScoreboardRenderGroup GetFramebuffer] GetColorAttachment]];

    // Create tablet resources
    modelParams.mFilename = [self GetAssetNameFromBaseName:@"MiniGameTableTablet" withExtension:@"STM"];
	modelParams.mReflective = FALSE;

#if USE_TABLET
	mTableTablet = [[ModelManager GetInstance] ModelWithParams:&modelParams];
	[mTableTablet retain];
    
    [mTableTablet SetTexture:[[mTabletRenderGroup GetFramebuffer] GetColorAttachment]];
#endif

    // Other misc setup
    mIdentifier = [MiniGameTableEntity GetHashForClass];
    
    mUsesLighting = FALSE;
    
    [[(GameState*)[[GameStateMgr GetInstance] GetActiveState] GetMessageChannel] AddListener:self];
    [GetGlobalMessageChannel() AddListener:self];
    
    mAdvertisingState = ADVERTISING_STATE_IDLE;
    
#if NEONGAM_PHP_ENABLED 
    if ([[AdvertisingManager GetInstance] ShouldShowAds])
    {
        [[AdvertisingManager GetInstance] IssueRequestAggregateAsync:self];
    }
 #endif       
    mTabletState = TABLET_STATE_RUN21;
    mTabletStateTime = 0;


    mTabletLight = [[LightManager GetInstance] CreateLight];
    
    LightParams* tabletLightParams = [mTabletLight GetParams];
    
    tabletLightParams->mDirectional = FALSE;
    Set(&tabletLightParams->mVector, 0.0, 3.0, -5.5);
    Set(&tabletLightParams->mSpotDirection, 0.0f, 0.0f, 1.0f);
    tabletLightParams->mConstantAttenuation      = 0.0;
    tabletLightParams->mLinearAttenuation        = 0.05;
    tabletLightParams->mQuadraticAttenuation     = 0.0;
    tabletLightParams->mSpotCutoff = 180.0f;
    
    Set(&tabletLightParams->mDiffuseRGB, 0.0, 0.0, 0.0);
    Set(&tabletLightParams->mAmbientRGB, 0.0, 0.0, 0.0);

    Set(&mTabletColor, 0.0, 0.0, 0.0);
    
    
    NeonLightShaftParams neonLightShaftParams;
    [NeonLightShaft InitDefaultParams:&neonLightShaftParams];
    
    neonLightShaftParams.mWidth = 1.2f;
    neonLightShaftParams.mDepth = 1.3f;
    mXrayLightShaft = [[NeonLightShaft alloc] initWithParams:&neonLightShaftParams];
    
    [[GameObjectManager GetInstance] Add:mXrayLightShaft withRenderBin:RENDERBIN_XRAY_EFFECT];
    [mXrayLightShaft release];
    
    [mXrayLightShaft SetVisible:FALSE];
    [mXrayLightShaft SetPositionX:6.3 Y:0.8 Z:0.6];
    [mXrayLightShaft SetOrientationX:36.0 Y:0.0 Z:0.0];
    
    mStingerCount = 0;
    
    return self;
}

-(void)dealloc
{
    [mPuppet Remove];
    [mPuppet release];
    
    [mTableBezel release];
	[mTableScoreboard release];
    [mTableCenter release];
    [mTableTablet release];
    
    [mXrayLightShaft Remove];
    
    for (NSObject* curBanner in mAdHolder.mAdvertisingBannerArray)
    {
        if ([curBanner isKindOfClass:([ImageWell class])])
        {
            [(ImageWell*)curBanner Remove];
        }
    }
    
    [mAdHolder.mAdvertisingBannerArray      release];
    [mAdHolder.mAdvertisingGameNameArray    release];   // @TODO: Remove GameNameArray members individually.
    [mAdHolder.mAdvertisingURLArray         release];   // @TODO: Remove URL members individually.
    
	
	[[RenderGroupManager GetInstance] RemoveRenderGroup:mScoreboardRenderGroup];
    [[RenderGroupManager GetInstance] RemoveRenderGroup:mTabletRenderGroup];
    [[RenderGroupManager GetInstance] RemoveRenderGroup:mJumbotronRenderGroup];
    
    [mJumbotronOutputFramebuffer release];
    [mJumbotronFilter release];
    
    [[LightManager GetInstance] RemoveLight:mTabletLight];
    
    [super dealloc];
}

-(void)Remove
{
    [GetGlobalMessageChannel() RemoveListener:self];
    [super Remove];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
        
    float flickerAmount = [mJumbotronFilter GetFlickerAmount];
    
    if (flickerAmount < 1.0f)
    {
        flickerAmount *= TABLET_LIGHT_FLICKER_INTENSITY;
    }
    
    LightParams* tabletLightParams = [mTabletLight GetParams];
    
    float r = flickerAmount * mTabletColor.mVector[0];
    float g = flickerAmount * mTabletColor.mVector[1];
    float b = flickerAmount * mTabletColor.mVector[2];
    
    Set(&tabletLightParams->mDiffuseRGB, r, g, b);
    Set(&tabletLightParams->mAmbientRGB, r * TABLET_LIGHT_AMBIENT_SCALE, g * TABLET_LIGHT_AMBIENT_SCALE, b * TABLET_LIGHT_AMBIENT_SCALE);

    switch(mTabletState)
    {
        case TABLET_STATE_RUN21:
        {
            if (mTabletStateTime > AD_MAINTAIN_TIME)
            {
                if ([self BannerAvailable])
                {
                    NSAssert([mAdHolder.mAdvertisingBannerArray count] == 1, @"We only support one ad at a time");
                    
                    ImageWell* adImageWell = [mAdHolder.mAdvertisingBannerArray objectAtIndex:0];
                    [adImageWell Enable];
                    
                    mTabletStateTime = 0.0;
                    mTabletState = TABLET_STATE_AD;
                }
            }
            
            break;
        }

        case TABLET_STATE_AD:
        {
            if (mTabletStateTime > AD_MAINTAIN_TIME)
            {
                ImageWell* adImageWell = [mAdHolder.mAdvertisingBannerArray objectAtIndex:0];
                [adImageWell Disable];
                
                mTabletStateTime = 0.0;
                mTabletState = TABLET_STATE_RUN21;
            }
            
            break;
        }
    }
    
    mTabletStateTime += inTimeStep;
}

-(void)Draw
{
	NeonGLMatrixMode(GL_MODELVIEW);
    
    glPushMatrix();
    {
        glMultMatrixf(mTableSurfaceTransform.mMatrix);
        [mTableCenter Draw];
    }
    glPopMatrix();
    
	glPushMatrix();
	{
        glMultMatrixf(mBezelTransform.mMatrix);
        [mTableBezel Draw];
    }
    glPopMatrix();
    
    glPushMatrix();
    {
		glMultMatrixf(mScoreboardTransform.mMatrix);
		[mTableScoreboard Draw];
	}
	glPopMatrix();

#if USE_TABLET
    glPushMatrix();
    {
		glMultMatrixf(mTabletTransform.mMatrix);
		[mTableTablet Draw];
	}
	glPopMatrix();
#endif
}

-(void)CycleAd
{
    int numAds = [mAdHolder.mAdvertisingBannerArray count];
    
    // Wrap around 0-based index
    if (numAds > 0)
    {
        mAdHolder.mAdvertisingBannerIndex = (mAdHolder.mAdvertisingBannerIndex + 1) % numAds;
    }
    
    mScoreboardCurrentImageWell = [mAdHolder.mAdvertisingBannerArray objectAtIndex:mAdHolder.mAdvertisingBannerIndex];
    [mScoreboardCurrentImageWell Enable];
}

-(BOOL)BannerAvailable
{
    return [mAdHolder.mAdvertisingBannerArray count] > 0;
}

-(void)CreateScoreboardRenderGroup
{
	// Create ImageWell that contains the inactive texture
	ImageWellParams imageWellParams;
	[ImageWell InitDefaultParams:&imageWellParams];

	imageWellParams.mTextureName = [[[Flow GetInstance] GetLevelDefinitions] GetScoreboardInactiveTextureFilename];
	mScoreboardInactiveImageWell = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellParams];

	imageWellParams.mTextureName = [[[Flow GetInstance] GetLevelDefinitions] GetScoreboardActiveTextureFilename];
	mScoreboardActiveImageWell = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellParams];

	// Create offscreen framebuffer for compositing stingers
	FramebufferParams framebufferParams;
	[Framebuffer InitDefaultParams:&framebufferParams];
	
	framebufferParams.mWidth = [[mScoreboardActiveImageWell GetTexture] GetRealWidth];
	framebufferParams.mHeight = [[mScoreboardActiveImageWell GetTexture ]GetRealHeight];
	framebufferParams.mColorFormat = GL_RGBA;
	framebufferParams.mColorType = GL_UNSIGNED_BYTE;
	
	Framebuffer* framebuffer = [(Framebuffer*)[Framebuffer alloc] InitWithParams:&framebufferParams];
	
	// Create GameObjectCollection for storing game objects that will be rendered on the scoreboard
	GameObjectCollection* gameObjectCollection = [(GameObjectCollection*)[GameObjectCollection alloc] Init];
	
	// Create CameraStateMachine for storing the camera used for rendering scoreboard objects
	CameraStateMachine* cameraStateMachine = [(CameraStateMachine*)[CameraStateMachine alloc] Init];
	
	// We'll use the ortho camera state since this is just an orthographic projection of UI
	StaticOrthoCameraStateParams* orthoCameraParams = [(StaticOrthoCameraStateParams*)[StaticOrthoCameraStateParams alloc] Init];
	
	orthoCameraParams->mWidth = [[mScoreboardActiveImageWell GetTexture] GetRealWidth];
	orthoCameraParams->mHeight = [[mScoreboardActiveImageWell GetTexture] GetRealHeight];
	
	[cameraStateMachine Push:[StaticOrthoCameraState alloc] withParams:orthoCameraParams];
	
	[orthoCameraParams release];
	
	// Finally create the RenderGroup itself
	RenderGroupParams renderGroupParams;
	[RenderGroup InitDefaultParams:&renderGroupParams];
	
	renderGroupParams.mFramebuffer = framebuffer;
	renderGroupParams.mGameObjectCollection = gameObjectCollection;
	renderGroupParams.mCameraStateMachine = cameraStateMachine;
	
	mScoreboardRenderGroup = [(RenderGroup*)[RenderGroup alloc] InitWithParams:&renderGroupParams];
		
    // Add the Active and Inactive image wells to the game object collection so that they're rendered
    [gameObjectCollection Add:mScoreboardInactiveImageWell];
	[gameObjectCollection Add:mScoreboardActiveImageWell];
    
    [mScoreboardInactiveImageWell release];
    [mScoreboardActiveImageWell release];
	
	// Create Imagewell that contains the active texture
		
	[[RenderGroupManager GetInstance] AddRenderGroup:mScoreboardRenderGroup];
	[mScoreboardRenderGroup release];
	
	[framebuffer release];
	[gameObjectCollection release];
	[cameraStateMachine release];
    
    [mScoreboardRenderGroup SetDebugName:@"ScoreboardRenderGroup"];
    
    mScoreboardCurrentImageWell = mScoreboardActiveImageWell;
}

-(RenderGroup*)GetScoreboardRenderGroup
{
	return mScoreboardRenderGroup;
}

-(void)CreateTabletRenderGroup
{
    // Create ImageWell that contains the inactive texture
	ImageWellParams imageWellParams;
	[ImageWell InitDefaultParams:&imageWellParams];
    
	imageWellParams.mTextureName = [[[Flow GetInstance] GetLevelDefinitions] GetTabletTextureFilename];
	ImageWell* tabletImageWell = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellParams];

	// Create offscreen framebuffer for compositing stingers
	FramebufferParams framebufferParams;
	[Framebuffer InitDefaultParams:&framebufferParams];
	
	framebufferParams.mWidth = [[tabletImageWell GetTexture] GetRealWidth];
	framebufferParams.mHeight = [[tabletImageWell GetTexture ]GetRealHeight];
	framebufferParams.mColorFormat = GL_RGBA;
	framebufferParams.mColorType = GL_UNSIGNED_BYTE;
	
	mTabletFramebuffer = [(Framebuffer*)[Framebuffer alloc] InitWithParams:&framebufferParams];
	
	// Create GameObjectCollection for storing game objects that will be rendered on the scoreboard
	GameObjectCollection* gameObjectCollection = [(GameObjectCollection*)[GameObjectCollection alloc] Init];
	
	// Create CameraStateMachine for storing the camera used for rendering scoreboard objects
	CameraStateMachine* cameraStateMachine = [(CameraStateMachine*)[CameraStateMachine alloc] Init];
	
	// We'll use the ortho camera state since this is just an orthographic projection of UI
	StaticOrthoCameraStateParams* orthoCameraParams = [(StaticOrthoCameraStateParams*)[StaticOrthoCameraStateParams alloc] Init];
	
	orthoCameraParams->mWidth = [[tabletImageWell GetTexture] GetRealWidth];
	orthoCameraParams->mHeight = [[tabletImageWell GetTexture] GetRealHeight];
	
	[cameraStateMachine Push:[StaticOrthoCameraState alloc] withParams:orthoCameraParams];
	
	[orthoCameraParams release];
	
	// Finally create the RenderGroup itself
	RenderGroupParams renderGroupParams;
	[RenderGroup InitDefaultParams:&renderGroupParams];
	
	renderGroupParams.mFramebuffer = mTabletFramebuffer;
	renderGroupParams.mGameObjectCollection = gameObjectCollection;
	renderGroupParams.mCameraStateMachine = cameraStateMachine;
	
	mTabletRenderGroup = [(RenderGroup*)[RenderGroup alloc] InitWithParams:&renderGroupParams];
		
    // Add the Active and Inactive image wells to the game object collection so that they're rendered
    [gameObjectCollection Add:tabletImageWell];
    
    [tabletImageWell release];
			
	[[RenderGroupManager GetInstance] AddRenderGroup:mTabletRenderGroup];
	[mTabletRenderGroup release];
	
	[mTabletFramebuffer release];
	[gameObjectCollection release];
	[cameraStateMachine release];
    
    [mTabletRenderGroup SetDebugName:@"TabletRenderGroup"];
    
    mScoreboardCurrentImageWell = mScoreboardActiveImageWell;
}

-(void)CreateJumbotronRenderGroup
{
	// Create offscreen framebuffer for compositing stingers
	FramebufferParams framebufferParams;
	[Framebuffer InitDefaultParams:&framebufferParams];
	
	framebufferParams.mWidth = JUMBOTRON_WIDTH;
	framebufferParams.mHeight = JUMBOTRON_HEIGHT;
	framebufferParams.mColorFormat = GL_RGBA;
	framebufferParams.mColorType = GL_UNSIGNED_BYTE;
	
	mJumbotronFramebuffer = [(Framebuffer*)[Framebuffer alloc] InitWithParams:&framebufferParams];
    mJumbotronOutputFramebuffer = [(Framebuffer*)[Framebuffer alloc] InitWithParams:&framebufferParams];
    	
	// Create GameObjectCollection for storing game objects that will be rendered on the scoreboard
	GameObjectCollection* gameObjectCollection = [(GameObjectCollection*)[GameObjectCollection alloc] Init];
	
	// Create CameraStateMachine for storing the camera used for rendering scoreboard objects
	CameraStateMachine* cameraStateMachine = [(CameraStateMachine*)[CameraStateMachine alloc] Init];
	
	// We'll use the ortho camera state since this is just an orthographic projection of UI
	StaticOrthoCameraStateParams* orthoCameraParams = [(StaticOrthoCameraStateParams*)[StaticOrthoCameraStateParams alloc] Init];
	
	orthoCameraParams->mWidth = JUMBOTRON_WIDTH;
	orthoCameraParams->mHeight = JUMBOTRON_HEIGHT;
	
	[cameraStateMachine Push:[StaticOrthoCameraState alloc] withParams:orthoCameraParams];
	
	[orthoCameraParams release];
	
	// Finally create the RenderGroup itself
	RenderGroupParams renderGroupParams;
	[RenderGroup InitDefaultParams:&renderGroupParams];
	
	renderGroupParams.mFramebuffer = mJumbotronFramebuffer;
	renderGroupParams.mGameObjectCollection = gameObjectCollection;
	renderGroupParams.mCameraStateMachine = cameraStateMachine;
    renderGroupParams.mListener = self;
    SetColorFloat(&renderGroupParams.mClearColor, 0.0f, 0.0f, 0.0f, 1.0f);
	
	mJumbotronRenderGroup = [(RenderGroup*)[RenderGroup alloc] InitWithParams:&renderGroupParams];
    [mJumbotronRenderGroup SetScaleX:1.0 y:JUMBOTRON_RENDERGROUP_SCALE];
		  
	[[RenderGroupManager GetInstance] AddRenderGroup:mJumbotronRenderGroup];
	[mJumbotronRenderGroup release];
	
	[mJumbotronFramebuffer release];
	[gameObjectCollection release];
	[cameraStateMachine release];
    
    ImageWellParams imageWellParams;

    [ImageWell InitDefaultParams:&imageWellParams];
    
    imageWellParams.mTexture = [mJumbotronOutputFramebuffer GetColorAttachment];
    mJumbotronImageWell = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellParams];
    
    [[mTabletRenderGroup GetGameObjectCollection] Add:mJumbotronImageWell];
    
    JumbotronFilterParams jumbotronFilterParams;
    [JumbotronFilter InitDefaultParams:&jumbotronFilterParams];
    
    jumbotronFilterParams.mSourceTexture = [mJumbotronFramebuffer GetColorAttachment];
    jumbotronFilterParams.mDestFramebuffer = mJumbotronOutputFramebuffer;
    jumbotronFilterParams.mMinNoise = JUMBOTRON_MIN_NOISE;
    jumbotronFilterParams.mMaxNoise = JUMBOTRON_MAX_NOISE;
    jumbotronFilterParams.mUseColorOffsets = FALSE;

#if !NEON_SOLITAIRE_21
    if ([[InAppPurchaseManager GetInstance] HasContent:IAP_PRODUCT_NOADS])
    {
        jumbotronFilterParams.mFlickerEnabled = FALSE;
    }
#endif

    mJumbotronFilter = [(JumbotronFilter*)[JumbotronFilter alloc] InitWithParams:&jumbotronFilterParams];
    
    [mJumbotronImageWell SetPositionX:49.0f Y:153.0f Z:0.0f];
    
    [mJumbotronRenderGroup SetDebugName:@"JumbotronRenderGroup"];
}

-(RenderGroup*)GetJumbotronRenderGroup
{
    return mJumbotronRenderGroup;
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_STINGER_CREATED:
        {
            mStingerCount++;
            [mScoreboardCurrentImageWell Disable];
            
            break;
        }
        
        case EVENT_STINGER_DISMISSED:
        case EVENT_STINGER_EXPIRED:
        {
            mStingerCount--;
            
            if (mStingerCount <= 0)
            {
                [mScoreboardCurrentImageWell Enable];
                mStingerCount = 0;
            }
            
            break;
        }
        
        case EVENT_CONCLUSION_BROKETHEBANK:
        case EVENT_CONCLUSION_BANKRUPT:
        {
            Path* fadeOutPath = [[Path alloc] Init];
            
            [fadeOutPath AddNodeScalar:1.0 atTime:0.0];
            [fadeOutPath AddNodeScalar:0.0 atTime:1.0];
            
            [mXrayLightShaft AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:fadeOutPath];
            [fadeOutPath release];
            
            break;
        }
        
        case EVENT_RUN21_XRAY_ACTIVE:
        {
            [mXrayLightShaft SetVisible:[(NSNumber*)inMsg->mData intValue]];
            break;
        }

    }
}

-(Model*)GetTableBezel
{
    return mTableBezel;
}

-(Model*)GetTableScoreboard
{
    return mTableScoreboard;
}

-(Model*)GetTableTablet
{
    return mTableTablet;
}

-(Matrix44*)GetScoreboardTransform
{
    return &mScoreboardTransform;
}

-(BOOL)IsScoreboardAdDisplaying
{
    return (mTabletState != TABLET_STATE_RUN21);
}

-(NSString*)GetScoreboardAdURL
{
    //NSLog(@"Ad Request to Ad# %d", adHolder.mAdvertisingBannerIndex);
    //return @"http://NeonGames.US";
    
    NSString *retURL = [mAdHolder.mAdvertisingURLArray objectAtIndex:mAdHolder.mAdvertisingBannerIndex];
    
    NSLog(@"Click Request on Ad %d: %@", mAdHolder.mAdvertisingBannerIndex, retURL);
    return retURL;
}

-(NSString*)GetAssetNameFromBaseName:(NSString*)inBaseName withExtension:(NSString*)inExtension
{
    return [NSString stringWithFormat:@"%@_%d.%@", inBaseName, MINI_GAME_TABLE_VERSION, inExtension];
}

-(void)AdvertisingManagerRequestComplete:(BOOL)success
{
    if (success)
    {
        OSAtomicCompareAndSwap32(ADVERTISING_STATE_IDLE, ADVERTISING_STATE_NEW_DATA, &mAdvertisingState);
    }
}

+(u32)GetHashForClass
{
    return [[GameObjectManager GetInstance] GenerateHash:MINIGAME_TABLE_STRING];
}

-(Model*)GetPuppet
{
    return mTableCenter;
}

-(void)RenderGroupDrawComplete:(RenderGroup*)inRenderGroup
{
    [mJumbotronFilter Draw];
}

-(void)RenderGroupUpdateComplete:(RenderGroup*)inRenderGroup timeStep:(CFTimeInterval)inTimeStep
{
    [mJumbotronFilter Update:inTimeStep];
}

@end