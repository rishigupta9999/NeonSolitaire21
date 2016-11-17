//
//  GameEnvironment.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "GameEnvironment.h"

#import "GameStateMgr.h"
#import "GameObjectManager.h"

#import "CompanionEntity.h"
#import "MiniGameTableEntity.h"
#import "StingerSpawner.h"
#import "Fader.h"
#import "Skybox.h"
#import "Flow.h"
#import "LevelDefinitions.h"
#import "LightManager.h"
#import "ReflectiveModel.h"


#define COMPANION_FADE_LENGTH   (1.0f)
#define COMPANION_FADE_AMOUNT   (0.5f)

@implementation GameEnvironment

-(GameEnvironment*)Init
{
    mOwningState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    [[mOwningState GetMessageChannel] AddListener:self];
    
    // Create and set up the table
    mTableEntity = [((MiniGameTableEntity*)[MiniGameTableEntity alloc]) InitWithEnvironment:self];
    [[GameObjectManager GetInstance] Add:mTableEntity];
    [mTableEntity release];


	for (int companionPosition = 0; companionPosition < COMPANION_POSITION_MAX; companionPosition++)
	{
		Companion* curCompanion = [[CompanionManager GetInstance] GetCompanionForPosition:companionPosition];
		
        if (curCompanion != NULL)
        {
            [(ReflectiveModel*)[mTableEntity GetPuppet] AddReflectedObject:[curCompanion->mEntity GetPuppet]];
            
            if (companionPosition == COMPANION_POSITION_PLAYER)
            {
                [(ReflectiveModel*)[mTableEntity GetPuppet] SetReflectionIntensity:0.5 forModel:[curCompanion->mEntity GetPuppet]];
            }
        }
	}
    
    [(ReflectiveModel*)[mTableEntity GetPuppet] AddReflectedObject:[mTableEntity GetTableScoreboard] localTransform:[mTableEntity GetScoreboardTransform]];
#if USE_TABLET
    [(ReflectiveModel*)[mTableEntity GetPuppet] AddReflectedObject:[mTableEntity GetTableTablet]];
#endif
    
    // Fade in
    FaderParams faderParams;
    [Fader InitDefaultParams:&faderParams];

    faderParams.mDuration = 0.5f;
    faderParams.mFadeType = FADE_FROM_BLACK;
    faderParams.mFrameDelay = 2;
    faderParams.mCancelFades = TRUE;
    faderParams.mCallback = self;

    [[Fader GetInstance] StartWithParams:&faderParams];
    
    // Create Skybox
    SkyboxParams skyboxParams;
    
    [Skybox InitDefaultParams:&skyboxParams];
    
    char** skyboxFilenames = [[[Flow GetInstance] GetLevelDefinitions] GetSkyboxFilenames];

    for (int curTex = 0; curTex < SKYBOX_NUM; curTex++)
    {
        if (skyboxFilenames[curTex] != NULL)
        {
            skyboxParams.mFiles[curTex] = [NSString stringWithUTF8String:skyboxFilenames[curTex]];
        }
        else
        {
            skyboxParams.mFiles[curTex] = NULL;
        }
        
        skyboxParams.mTranslateFace[curTex] = FALSE;
    }
    
    mSkybox = [(Skybox*)[Skybox alloc] InitWithParams:&skyboxParams];
    [[GameObjectManager GetInstance] Add:mSkybox];
    [mSkybox release];
    
    [mSkybox SetPositionX:0.0 Y:-3.5 Z:0.0];
		
	// Setup the Stinger Spawner
	StingerSpawnerParams stingerSpawnerParams;
	[StingerSpawner InitDefaultParams:&stingerSpawnerParams];
	
	stingerSpawnerParams.mRenderGroup = [mTableEntity GetScoreboardRenderGroup];
    SetVec2(&stingerSpawnerParams.mRenderOffset, 0.0f, 100.0f);
    SetVec2(&stingerSpawnerParams.mRenderScale, 2.0f, 2.0f);
	stingerSpawnerParams.mDrawBar = FALSE;
    stingerSpawnerParams.mStingerSpawnerMode = STINGERSPAWNER_MODE_GAMEOPERATIONS;
	
	mStingerSpawner = [(StingerSpawner*)[StingerSpawner alloc] InitWithParams:&stingerSpawnerParams];
    
    // Create card placer
    mCardPlacer = [(GameCardPlacer*)[GameCardPlacer alloc] InitWithTable:mTableEntity];

    // Create lights
    mUnderLight = [[LightManager GetInstance] CreateLight];
    
    LightParams* underLightParams = [mUnderLight GetParams];
    underLightParams->mDirectional = FALSE;
    Set(&underLightParams->mVector, Light_Mini_Pos_X, Light_Mini_Pos_Y, Light_Mini_Pos_Z);
    Set(&underLightParams->mSpotDirection, 0.0f, -1.0f, 0.0f);
    underLightParams->mConstantAttenuation      = Light_Mini_Att_C;
    underLightParams->mLinearAttenuation        = Light_Mini_Att_L;
    underLightParams->mQuadraticAttenuation     = Light_Mini_Att_Q;
    underLightParams->mSpotCutoff = 90.0f;

    
    Set(&underLightParams->mDiffuseRGB, 0.45, 0.45, 0.45);
    Set(&underLightParams->mAmbientRGB, 0.25, 0.25, 0.25);

    return self;
}

-(void)dealloc
{
	// GameManaged Objects
    [mTableEntity Remove];
    [[GameObjectManager GetInstance] Remove:mSkybox];
    
	// Internal Objects
    [mCardPlacer release];
    [[LightManager GetInstance] RemoveLight:mUnderLight];
    
    [mStingerSpawner Remove];
	[mStingerSpawner release];
    
    [super dealloc];
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_RUN21_BEGIN_DURINGPLAY_CAMERA:
        {
            Companion* player = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_PLAYER];
            
            if (player != NULL)
            {
                CompanionEntity* entity = player->mEntity;
                
                Path* path = [(Path*)[Path alloc] Init];
                
                [path AddNodeScalar:1.0f atTime:0.0f];
                [path AddNodeScalar:COMPANION_FADE_AMOUNT atTime:COMPANION_FADE_LENGTH];
                
                [entity AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:path];
                [path release];
            }
            
            break;
        }
        
        case EVENT_RUN21_BEGIN_CELEBRATION_CAMERA:
        {
            Companion* player = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_PLAYER];
            
            if (player != NULL)
            {
                CompanionEntity* entity = player->mEntity;
                
                Path* path = [(Path*)[Path alloc] Init];
                
                [path AddNodeScalar:COMPANION_FADE_AMOUNT atTime:0.0f];
                [path AddNodeScalar:1.0f atTime:COMPANION_FADE_LENGTH];
                
                [entity AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:path];
                [path release];
            }
            
            break;
        }
    }
}

-(StingerSpawner*)GetStingerSpawner
{
    return mStingerSpawner;
}

-(float)GetTableHeight
{
    return 1.19f;
}

-(float)GetTableRotationDegrees
{
    return 126.0f;
}

-(void)FadeComplete:(NSObject*)inObject
{
    NSLog(@"Level Load Time is %f", NeonEndTimer());
}

@end