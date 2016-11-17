//
//  StingerSpawner.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "MessageChannel.h"
#import "CompanionDefines.h"
#import "StateMachine.h"
#import "GameObject.h"
#import "UISounds.h"
#import "TutorialScript.h"

@class RenderGroup;
@class Stinger;

typedef enum
{
    STINGER_SPAWNER_IDLE,
    STINGER_SPAWNER_WAITING_FOR_TIMER
} StingerSpawnerState;

typedef enum
{
    DEALER_DIALOGUE_STATE_IDLE,
    DEALER_DIALOGUE_STATE_WAITING_FOR_TIMER,
    DEALER_DIALOGUE_STATE_INTRO,
    DEALER_DIALOGUE_STATE_MAINTAIN,
    DEALER_DIALOGUE_STATE_OUTRO
} StingerSpawnerDealerDialogueState;

typedef enum
{
    R21_STINGER_21,
	R21_STINGER_CHARLIE,
	R21_STINGER_BUST,
	R21_STINGER_CLEARING_CLUBS,
	R21_STINGER_RUNNING_RAINBOW,
	R21_STINGER_PLAYER_PHASE,
	R21_STINGER_SUDDEN_DEATH,
    R21_STINGER_RUN,
	R21_STINGER_NUM,
} Run21StingerID;

typedef enum
{
    STINGERSPAWNER_MODE_ALL,
    STINGERSPAWNER_MODE_GAMEOPERATIONS,
    STINGERSPAWNER_MODE_DEALERDIALOG
} StingerSpawnerMode;

typedef struct
{
	RenderGroup*        mRenderGroup;
    Vector2             mRenderOffset;
    Vector2             mRenderScale;
	BOOL                mDrawBar;
    StingerSpawnerMode  mStingerSpawnerMode;
} StingerSpawnerParams;

typedef struct
{
    NSString**                  mStrings;
    u32                         mNumStrings;
    CompanionPosition           mCompanionPosition;
    BOOL                        mClickToContinue;
    id<StateMachinePausable>    mPausable;
    Vector2                     mRenderOffset;
    float                       mFontSize;
    NSString*                   mFontName;
    Color                       mFontColor;
    CTTextAlignment             mFontAlignment;
} StingerSpawnerDealerDialogueParams;

@interface StingerSpawner : GameObject<MessageChannelListener>
{
    StingerSpawnerDealerDialogueParams  mDealerDialogueParams;
    StingerSpawnerDealerDialogueState   mDealerDialogueState;

    Stinger*                mDealerStinger;
    StingerSpawnerState		mStingerSpawnerState;
    float					mTimer;
	
	StingerSpawnerParams	mParams;
}

-(StingerSpawner*)InitWithParams:(StingerSpawnerParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(StingerSpawnerParams*)outParams;
+(void)InitDefaultDealerDialogueParams:(StingerSpawnerDealerDialogueParams*)outParams;
-(void)Remove;

-(void)Update:(CFTimeInterval)inTimeInterval;

-(void)ProcessMessage:(Message*)inMsg;

-(void)EvaluateGenericMajorStingerWithFileName:(const char*)inFileName;
-(void)PlayDynamicMajorStinger:(NSString*)nsStr stayOnScreen:(BOOL)bStayOnScreen withSoundID:(UISoundId)soundID;
-(void)EvaluateBigWinWithHiScore:(BOOL)bHiScore;
-(void)EvaluateTutorialDialogue:(Neon21TutorialDialogueMessage*)msg;

-(void)SpawnRun21Stinger:(Run21StingerID)inStingerID;
-(void)SpawnDealerDialogTimed:(const char*)inString;
-(void)SpawnDealerDialogClick:(NSString**)inStrings numStrings:(int)inNumStrings;
-(void)SpawnDealerDialogClick:(NSString**)inStrings numStrings:(int)inNumStrings dialoguePosition:(CompanionPosition)inCompanionPosition;
-(void)SpawnDealerDialogClick:(StingerSpawnerDealerDialogueParams*)inParams;

-(void)EvaluateDealerDialogClick:(NSString**)inStrings numStrings:(int)inNumStrings clickToContinue:(BOOL)inClickToContinue;
-(BOOL)TerminateDealerStinger;
-(void)TerminateDealerStingerSync;

-(StingerSpawnerDealerDialogueState)GetDealerDialogueState;

-(GameObjectCollection*)GetGameObjectCollection;

@end