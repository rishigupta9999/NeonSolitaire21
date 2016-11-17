//
//  TwentyOneSquaredEnvironment.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "TwentyOneSquaredEnvironment.h"

/*#import "GameStateMgr.h"
#import "GameObjectManager.h"

#import "MiniGameTableEntity.h"

#import "Fader.h"
#import "Skybox.h"

#import "Flow.h"*/

@implementation TwentyOneSquaredEnvironment

-(TwentyOneSquaredEnvironment*)Init
{
	[ super Init];
	return self;
}
	
/*-(TwentyOneSquaredEnvironment*)Init
{
    mOwningState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    [[mOwningState GetMessageChannel] AddListener:self];
    
    // Create and set up the table
    mTableEntity = [((MiniGameTableEntity*)[MiniGameTableEntity alloc]) Init];
    [[GameObjectManager GetInstance] Add:mTableEntity];
    [mTableEntity release];
    
    // Fade in
    FaderParams faderParams;
    [Fader InitDefaultParams:&faderParams];

    faderParams.mDuration = 1.0f;
    faderParams.mFadeType = FADE_FROM_BLACK;
    faderParams.mFrameDelay = 3;

    [[Fader GetInstance] StartWithParams:&faderParams];
    
    // Create Skybox
    SkyboxParams skyboxParams;
    
    [Skybox InitDefaultParams:&skyboxParams];
        
    for (int curTex = 0; curTex < SKYBOX_NUM; curTex++)
    {
        if ([[Flow GetInstance] GetSkyboxFileNames][curTex] != NULL)
        {
            skyboxParams.mFiles[curTex] = [NSString stringWithUTF8String:[[Flow GetInstance] GetSkyboxFileNames][curTex]];
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
    
    [mSkybox SetPositionX:0.0 Y:-1.0 Z:0.0];

    return self;
}

-(void)dealloc
{
    [[GameObjectManager GetInstance] Remove:mTableEntity];
    [[GameObjectManager GetInstance] Remove:mSkybox];
    
    [super dealloc];
}

-(void)ProcessMessage:(Message*)inMsg
{
}*/

@end