//
//  Game21Squared.h
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011, All rights reserved.

#import "TutorialGameState.h"
#import "GameState.h"
#import "StateMachine.h"
#import "DebugManager.h"
#import "PlayerHand.h"
#import "Card.h"

#pragma mark -
#pragma mark States

@class HandStateMachine21Sq;
@class CompanionManager;
@class TwentyOneSquaredEnvironment;

#define NUMCARDS_LINE	5

typedef enum
{
	GRID_ROW = 0,
	GRID_COL,
	GRID_NUM,

} EGridPosition;

// -----------------------------------------------------------------------------------------------------
// GSM
// -----------------------------------------------------------------------------------------------------
@interface GameTwentyOneSquared : TutorialGameState
{
    HandStateMachine21Sq			*m21SqStateMachine;
    TwentyOneSquaredEnvironment		*m21SqEnvironment;
}

-(void)Startup;
-(void)Shutdown;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Suspend;
-(void)Resume;
-(void)DrawOrtho;
-(HandStateMachine21Sq*)GetHSM;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;


@end


@interface HandStateMachine21Sq : StateMachine
{
    // Look into using interfaces instead of keeping some of this in the HSM, or hook for init properly
@public
	// Neon Blackjack
	GameTwentyOneSquared	*mGameTwentyOneSquared;
	
	// Companion Information
	CompanionManager		*mCompanionManager;						// Who is sitting next to the player, what are their special abilities?
	
	PlayerHand				*mHand;
	Card					*mCard[NUMCARDS_LINE][NUMCARDS_LINE];	// Card Grid
	int						mGridScore[GRID_NUM][NUMCARDS_LINE];
}

-(HandStateMachine21Sq*)InitWithGameTwentyOneSquared:(GameTwentyOneSquared*)inGameTwentyOneSquared numJokers:(int)inNumJokers;
-(void)dealloc;
-(void)CalculateScores;
@end
