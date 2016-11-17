//
//  GameEnvironment.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "GameState.h"
#import "GameCardPlacer.h"
#import "Fader.h"

@class MiniGameTableEntity;
@class Skybox;
@class StingerSpawner;
@class Light;
@class CompanionEntity;

#define Light_Mini_Pos_X  0.0f
#define Light_Mini_Pos_Y  3.5f
#define Light_Mini_Pos_Z  0.8f

#define Light_Mini_Att_C  0.30f
#define Light_Mini_Att_L  0.40f
#define Light_Mini_Att_Q  0.00f

@interface GameEnvironment : NSObject<MessageChannelListener, FaderCallback>
{
 @public   
    MiniGameTableEntity*    mTableEntity;
 @private
    
    
    GameState*              mOwningState;
    
	
	StingerSpawner*         mStingerSpawner;
    Skybox*                 mSkybox;
    Light*                  mUnderLight;
@protected
	GameCardPlacer*			mCardPlacer;
}

-(GameEnvironment*)Init;
-(StingerSpawner*)GetStingerSpawner;
-(void)dealloc;

-(float)GetTableHeight;
-(float)GetTableRotationDegrees;

-(void)FadeComplete:(NSObject*)inObject;

@end