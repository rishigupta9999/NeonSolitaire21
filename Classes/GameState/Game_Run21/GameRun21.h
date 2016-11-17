//
//  GameRun21.h
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011, All rights reserved.

#import "TutorialGameState.h"
#import "GameState.h"
#import "StateMachine.h"
#import "DebugManager.h"
#import "PlayerHand.h"
#import "CardDefines.h"

#pragma mark -
#pragma mark States

@class HandStateMachineRun21;
@class CompanionManager;
@class Run21Environment;

// -----------------------------------------------------------------------------------------------------
// Enumerations
// -----------------------------------------------------------------------------------------------------
typedef enum
{
	eHandStateRun21_Init				= 0,
	eHandStateRun21_TableSetup,
	eHandStateRun21_DealCard,
	eHandStateRun21_Decision,
	eHandStateRun21_HandBust,
	eHandStateRun21_Hand21,
	eHandStateRun21_HandCharlie,
	eHandStateRun21_AutoPlay,
	eHandStateRun21_Lose,
	eHandStateRun21_Win,
	eHandStateRun21_NumHandStates,		// This must be the last enum
} EHandStateRun21;

typedef enum
{
    Flurry_Run21_Play,                      // impl.
    Flurry_Marathon_Play,                   // impl.
    //Flurry_Tablet_Chartboost,               // Not timed in this version.
   // Flurry_Tablet_NeonGamES,                // Not timed in this version.
    Flurry_Tablet_Impression,               // The entirety of the ad impression for now ( later do this step->step )
    Flurry_Tablet_ADPICK_UNTIMED_FIRST,
    Flurry_Tablet_AdClicked             = Flurry_Tablet_ADPICK_UNTIMED_FIRST,
    Flurry_Tablet_Bypassed,                 // @TODO: on Adblock.
    Flurry_Tablet_NotChosen_Duplicate,      // Impl.
    Flurry_Tablet_NotChosen_MissingAsset,   // Impl.
    Flurry_Tablet_CampaignRequest,          // Impl.
    Flurry_Tablet_DownloadError,            // Impl.
    Flurry_Tablet_ADPICK_UNTIMED_LAST   = Flurry_Tablet_DownloadError,
    Flurry_NUMEVENTS,
} FEvent;

#define NUM_CARDS_RUN21_TUTORIAL        7   // Shoe isn't parsed from the tutorial doc.

#define STARTUP_POWERUP_XRAY            1
#define STARTUP_POWERUP_TORNADO         1
#define STARTUP_POWERUP_LIVES           3   // Change to 0 to test purchase lives

@interface Run21RefillLivesDelegate : NSObject <UIAlertViewDelegate>

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end


// -----------------------------------------------------------------------------------------------------
// GSM
// -----------------------------------------------------------------------------------------------------
@interface GameRun21 : TutorialGameState<TriggerEvaluator, MessageChannelListener>
{
@public
    HandStateMachineRun21	*mRun21StateMachine;				// HSM->Run21 Gameplay
    Run21Environment		*mRun21Environment;					// Run21 UI
    Run21RefillLivesDelegate     *mRefillLivesDelegate;
    
    int                     mStartMaxLevel;
}

-(void)Startup;
-(void)FlurryTimedEvent:(FEvent)event withStart:(BOOL)bStart;
-(void)Shutdown;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Suspend;
-(void)Resume;
-(void)DrawOrtho;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;
-(void)ProcessMessage:(Message*)inMsg;
-(HandStateMachineRun21*)GetHSM;

-(BOOL)TriggerCondition:(NSString*)inTrigger;
-(void)RegisterTutorialUI;
-(void)ReleaseTutorialUI;

-(void)SetMainMenuToLoad;

@end

// -----------------------------------------------------------------------------------------------------
// HSM
// -----------------------------------------------------------------------------------------------------

typedef enum
{
    TIMERSTATE_WAITING,
    TIMERSTATE_RUNNING,
    TIMERSTATE_COMPLETED
} TimerState;

@interface HandStateMachineRun21 : StateMachine
{
@public
	GameRun21				*mGameRun21;						// GSM
	PlayerHand				*mHandPlayer[MAX_PLAYER_HANDS];		// The player has four hands that they control simultaneously
	PlayerHand				*mHandToPlace;						// The card that was dealt for the player to play.
	CompanionManager		*mCompanionManager;					// Audience who watches the game from background, and seating positions for dealer/player						
	int						mLastHandDealtTo;					// Last active hand.
	int						mAutoPlayLastHand;					// Which hand is the last hand available to play on
	int						mCardsToPrePlay;					// How many cards will be played by the CPU before handing off control to the player.		
	EInputMethod			inputMode;							// If we have only one hand remaining, have the CPU take over as there are no player options available.
	Card					*mPlacerCard;						// The active card initially dealt to the placer holder.
	PlayerHand				*mHandContainingPlacerCard;			// Which hand is the Placer Card in?
	EJokerStatus			mJokerStatus[CARDSUIT_JOKER_MAX];	// The status of both jokers in the game
    BOOL                    mInterruptSkipMidgame, mInterruptRainbow;   // Tutorial flag interrupts.
	
	BOOL					bWonGame;							// Did we win or lose the session?
	int                     numHandsActive;
    int                     previousScore;
    int                     endHandsScored;
	BOOL					bHiScore;
    BOOL                    bLeveledUp;
    int                     mLevel;
    
    int                     powerUpUsed_Tornados;
    
    BOOL                    mAddClubs;
    
    BOOL                    mRemoveClubs;
    BOOL                    mRemoveHearts;
    BOOL                    mRemoveDiamonds;
    BOOL                    mRemoveSpades;
    
    int                     mNumDecks;
    int                     mNumJokers;
    
    int                     mNumRunners;
    
    BOOL                    mGameOver;
    
    BOOL                    mXrayCardEvaluated;
    
    CFTimeInterval          mTimeRemaining;
    TimerState              mTimerState;
}

@property BOOL  xrayActive;

-(void)GameOver;

-(void)ShuffleMarathonWithLevel:(int)level;
-(void)ShuffleMarathonLevelUp;
-(BOOL)isCardInHand:(Card*)playingCard;
-(HandStateMachineRun21*)InitWithGameRun21:(GameRun21*)inGameRun21;
-(void)WipeTable;
-(void)EndGameTable;
-(void)dealloc;
-(void)SyncJokerStatusFromFlow;
-(void)PrintDeckWithHeader:(NSString*)strHeader;
-(int)GetRemainingCards;
-(int)GetNumCardsOnTable;
-(void)EvaluateXrayCard:(int)inCardIndex;

-(void)setXrayActive:(BOOL)inXrayActive;
-(BOOL)xrayActive;

-(void)Update:(CFTimeInterval)inTimeStep;
-(CFTimeInterval)GetTimeRemaining;

@end

// -----------------------------------------------------------------------------------------------------
// Hand State for Run 21
// -----------------------------------------------------------------------------------------------------

@interface HandStateRun21 : State
{
@public
	float	mStateTime;
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(PlayerHand*)GetActiveHand;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Init
// --------------------------------------------------

@interface HandStateRun21_Init : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Table Setup
// --------------------------------------------------

@interface HandStateRun21_TableSetup : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Deal Placer Card
// --------------------------------------------------

@interface HandStateRun21_DealPlacerCard : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: CPU Mode Switch ( Run Rainbow )
// --------------------------------------------------
@interface HandStateRun21_CPU_Mode_Switch_RunRainbow : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: CPU Mode Switch ( Skip Midgame )
// --------------------------------------------------
@interface HandStateRun21_CPU_Mode_Switch_SkipMidgame : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: CPU Mode Switch ( Resume Midgame )
// --------------------------------------------------
@interface HandStateRun21_CPU_Mode_Switch_ResueMidgame : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Decision
// --------------------------------------------------

@interface HandStateRun21_Decision : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Hand Outcome - Bust
// --------------------------------------------------

@interface HandStateRun21_HandOutcome_Bust : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Hand Outcome - 21
// --------------------------------------------------

@interface HandStateRun21_HandOutcome_21 : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Hand Outcome - Charlie
// --------------------------------------------------

@interface HandStateRun21_HandOutcome_Charlie : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// TODO: When only 1 live row is left, have the game play on its own, may do better with a flag instead.
// --------------------------------------------------
// HS: Autoplay
// --------------------------------------------------

@interface HandStateRun21_AutoPlay : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Lose
// --------------------------------------------------

@interface HandStateRun21_Lose : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Win
// --------------------------------------------------

@interface HandStateRun21_Win : HandStateRun21
{
    float startAnimationTime;
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Evaluate - Hand
// --------------------------------------------------

@interface HandStateEvaluate_Hand : HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Evaluate - Game
// --------------------------------------------------

@interface HandStateEvaluate_Game: HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: Placement Test
// --------------------------------------------------

@interface HandStatePlacementTest: HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: End Stars
// --------------------------------------------------

@interface HandStateEndStars: HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

// --------------------------------------------------
// HS: GameOver
// --------------------------------------------------

@interface HandStateGameOver: HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
-(void)FlurryEndSession;
@end

// --------------------------------------------------
// HS: Placement Confirm
// --------------------------------------------------

@interface HandStatePlacementConfirm: HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end

@interface Run21TutorialSummary : HandStateRun21
{
}

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Startup;
-(NSString*)GetId;

@end

// --------------------------------------------------
// HS: Tornado
// --------------------------------------------------

@interface HandStateRun21_Tornado: HandStateRun21
{
}
-(void)Startup;
-(void)Update:(CFTimeInterval)inTimeStep;
-(NSString*)GetId;
-(void)Shutdown;
@end