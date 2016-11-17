//
//  Flow.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "MenuFlowTypes.h"
#import "CompanionManager.h"
#import "Card.h"
#import "GameRun21.h"
#import "FlowTypes.h"

#define NUM_SESSIONS_WON_BEFORE_RATING_PROMPT   2
#define LEVEL_INDEX_INVALID (-1)

typedef enum
{
	Difficulty_21Sq_A234,
	Difficulty_21Sq_2345,
	Difficulty_21Sq_3456,
	Difficulty_21Sq_4567,
	Difficulty_21Sq_5678,
	Difficulty_21Sq_6789,
	Difficulty_21Sq_789T,
	Difficulty_21Sq_89TJ,
	Difficulty_21Sq_9TJQ,
	Difficulty_21Sq_TJQK,
	Difficulty_21Sq_JQKE,	// Eleven of Clubs
	Difficulty_21Sq_MAX
} Difficulty_21Sq_Enum;

// Family 2
typedef enum
{
    Difficulty_Rainbow_Level1,
    Difficulty_Rainbow_Level2,
    Difficulty_Rainbow_Level3,
    Difficulty_Rainbow_Level4,
    Difficulty_Rainbow_Level5,
    Difficulty_Rainbow_Level6,
    Difficulty_Rainbow_Level7,
    Difficulty_Rainbow_Level8,
    Difficulty_Rainbow_Level9,
    Difficulty_Rainbow_Level10,
	Difficulty_Rainbow_MAX
} Difficulty_Rainbow_Enum;

typedef enum
{
	CasinoID_None,
	CasinoID_Family1_Start,
	CasinoID_IChaChing = CasinoID_Family1_Start,
	CasinoID_FjordKnox,
	CasinoID_GummySlots,
	CasinoID_Family1_Last = CasinoID_GummySlots,
	CasinoID_MAX
} CasinoID;

typedef struct
{
	CompanionID seatLeft;
	CompanionID seatRight;
	CompanionID seatDealer;
	CompanionID seatPlayer;
} TableCompanionPlacement;

typedef struct
{
    NSString*       mStateName;
    BOOL            mKeepSuspended;
} FlowStateParams;


@class TutorialScript;
@class LevelDefinitions;

@interface Flow : NSObject
{
    @public
		ENeonMenu					mMenuToLoad;
    @private
		TableCompanionPlacement		mCompanionLayout;
    
        GameModeType                mGameModeType;
        GameModeType                mPrevGameModeType;
    
        int                         mLevel;
        int                         mPrevLevel;
	   
        LevelDefinitions*           mLevelDefinitions;
    
        BOOL                        mRequestedFacebookLogin;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(Flow*)GetInstance;

-(void)Init;

-(GameModeType)GetGameMode;
-(int)GetLevel;

-(TableCompanionPlacement*)GetCompanionLayout;

-(void)PromptForUserRatingTally;
-(void)AppRate;
-(void)AppGift;

-(void)SetupGame;
-(void)CycleOutCompanionsWithDealer:(CompanionID)dealer Seat1:(CompanionID)companion1 Seat2:(CompanionID)companion2;

// Progress Flow
-(void)EvaluateCompanionUnlocks;
-(BOOL)UnlockNextLevel;
-(void)AdvanceLevel;
-(void)RestartLevel;

-(void)EnterGameMode:(GameModeType)inGameModeType level:(int)inLevel;
-(void)ExitGameMode;

-(BOOL)IsInRun21;
-(BOOL)IsInRainbow;

-(CasinoID)GetCasinoId;

-(LevelDefinitions*)GetLevelDefinitions;

-(void)SetRequestedFacebookLogin:(BOOL)inRequested;
-(BOOL)GetRequestedFacebookLogin;

@end