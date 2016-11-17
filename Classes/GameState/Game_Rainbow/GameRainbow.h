//
//  GameRainbow.h
//  Neon Engine
//
//  Copyright Neon Games LLC - 2012

#import "TutorialGameState.h"
#import "GameState.h"
#import "StateMachine.h"
#import "DebugManager.h"
#import "PlayerHand.h"
#import "CardDefines.h"


#define RAINBOW_NUM_ROUNDS_PER_GAME 4
#define RAINBOW_NUM_DEALS_PER_ROUND 4

#define HAND_DEALER 0
#define HAND_PLAYER 1

@class HandStateMachineRainbow;
@class CompanionManager;
@class RainbowEnvironment;




// -----------------------------------------------------------------------------------------------------
// GSM
// -----------------------------------------------------------------------------------------------------

@interface GameRainbow : TutorialGameState <TriggerEvaluator>
{
@public
    HandStateMachineRainbow     *mRainbowStateMachine;
    RainbowEnvironment          *mRainbowEnvironment;
    
}

-(void)Startup;
-(void)Shutdown;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Suspend;
-(void)Resume;
-(void)DrawOrtho;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;
-(HandStateMachineRainbow*)GetHSM;

-(BOOL)TriggerCondition:(NSString*)inTrigger;
-(void)InitFromTutorialScript:(TutorialScript*)inTutorialScript;
-(void)RegisterTutorialUI;
-(void)ReleaseTutorialUI;
-(void)EnableTutorialUIObject:(UIObject*)inObject;
-(void)DisableTutorialUIObject:(UIObject*)inObject;
-(void)StandWithEndTurn:(BOOL)readyToEnd;

@end

// -----------------------------------------------------------------------------------------------------
// HSM
// -----------------------------------------------------------------------------------------------------

@interface HandStateMachineRainbow : StateMachine
{
@public
	GameRainbow             *mGameRainbow;						// GSM
	PlayerHand				*mHandPlayer[RAINBOW_NUM_PLAYERS];     // There are two hands, one controlled by the player, one, by the CP
    int                     curPlayer;                          // Whose turn is it?
    PlayerHand              *curHand;
    PlayerHand              *mDeck;
    int                     mFirstPlayer;                       // The Player that went first this round
    
    CompanionManager		*mCompanionManager;					// Audience who watches the game from background, and seating positions for dealer/player
    BOOL                    bFirstDeal;                         // Determines whether we are in the initial deal, and we switch players between dealing each card
    BOOL                    bPostStand;
    
    int                     mTurnNumber;                        //how many turns have we been through in the round
    int                     mRoundNumber;                       // how may rounds have we been through in the Game
    BOOL                    bWonGame;
    //StarLevel				previousScore;
    int                     mNumStars;
	BOOL					bHiScore;
}

-(HandStateMachineRainbow*)InitWithGameRainbow:(GameRainbow*)inGameRainbow;
-(void)WipeTable;
-(void)EndGameTable;
-(void)dealloc;
-(void)NextTurn;
-(PlayerHand*)playerForNextTurn;
@end

// -----------------------------------------------------------------------------------------------------
// Hand State for Rainbow
// -----------------------------------------------------------------------------------------------------

@interface HandStateRainbow : State
{
@public
	float	mStateTime;
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(PlayerHand*)GetCurrentPlayerHand;
-(void)Shutdown;
-(int)GetRemainingCards;
@end

// --------------------------------------------------
// HS: Init
// --------------------------------------------------
@interface HandStateRainbow_Init : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Table Setup
// --------------------------------------------------
@interface HandStateRainbow_TableSetup : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Pre-Deal
// --------------------------------------------------
@interface HandStateRainbow_PreDeal : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end


// --------------------------------------------------
// HS: Begin Player Turn
// --------------------------------------------------
@interface HandStateRainbow_BeginPlayerTurn: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Begin Dealer Turn
// --------------------------------------------------
@interface HandStateRainbow_BeginDealerTurn: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end


// --------------------------------------------------
// HS: Decision
// --------------------------------------------------
@interface HandStateRainbow_Decision : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(BOOL)BronzeBluff;
-(BOOL)SilverBluff;
-(BOOL)GoldBluff;
-(BOOL)PlatinumBluff;
-(void)DoBronzeAI;
-(void)DoSilverAI;
-(void)DoGoldAI;
-(void)DoPlatinumAI;
-(void)DoAIWithFirstFilter:(CardLabel)inFirst SecondFilter:(CardLabel)inSecond ThirdFiter:(CardLabel)inThird FourthFilter:(CardLabel)inFourth;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Stand
// --------------------------------------------------
@interface HandStateRainbow_Stand : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Unique
// --------------------------------------------------
@interface HandStateRainbow_Unique : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Pre-Discard
// --------------------------------------------------
@interface HandStateRainbow_PreDiscard : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Discard
// --------------------------------------------------
@interface HandStateRainbow_Discard : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Score Hand
// --------------------------------------------------
@interface HandStateRainbow_ScoreHand : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(Card*)GetSmallest:(NSMutableArray*)inArray;
-(Card*)GetLargest:(NSMutableArray*)inArray;
-(void)RemoveSuit:(int)inSuit FromArray:(NSMutableArray*)inArray;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Sort Hand
// --------------------------------------------------
@interface HandStateRainbow_SortHand : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Evaluate Round
// --------------------------------------------------
@interface HandStateRainbow_EvaluateRound : HandStateRainbow
{
    int cardIndex;
}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)AnimateScoring;
-(PlayerHand*)GetWinner;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: End Round
// --------------------------------------------------
@interface HandStateRainbow_EndRound : HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Cleanup
// --------------------------------------------------
@interface HandStateRainbow_Cleanup: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Evaluate Game
// --------------------------------------------------
@interface HandStateRainbow_EvaluateGame: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Lose
// --------------------------------------------------
@interface HandStateRainbow_Lose: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Win
// --------------------------------------------------
@interface HandStateRainbow_Win: HandStateRainbow
{
    int  mIndex;
    float mStartAnimation;
    float mWaitTime;
    bool bTableCleared;
    bool bDoneScoring;
}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Post Win Wait
// --------------------------------------------------
@interface HandStateRainbow_PostWinWait: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Game Over
// --------------------------------------------------
@interface HandStateRainbow_GameOver: HandStateRainbow
{}

-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end
