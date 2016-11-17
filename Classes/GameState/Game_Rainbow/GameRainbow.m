
//
//  GameRainbow.m
//  Neon Engine
//
//  Copyright Neon Games LLC - 2012

#import "GameRainbow.h"
#import "GameObjectManager.h"
#import "Flow.h"
#import "TextureButton.h"
#import "DebugManager.h"

#import "RainbowUI.h"
#import "RainbowEnvironment.h"

#import "CameraStateMgr.h"
#import "Run21IntroCamera.h"

#import "CardManager.h"
#import "CardRenderManager.h"
#import "Card.h"
#import "UINeonEngineDefines.h"

#import "SaveSystem.h"

#define DEBUG_SHOW_BUTTON_NAMES 0
#define DEBUG_DEALER_CARDS_FACEUP 0
#define DEBUG_DEALER_DOESNT_BLUFF 1


// -----------------------------------------------------------------------------------------------------
// GSM
// -----------------------------------------------------------------------------------------------------

@implementation GameRainbow

static RainbowUI		*sRainbowUI;
static const float	TIME_BETWEEN_STATES			= 0.5;
static const float	TIME_BETWEEN_STATES_FAST	= 0.05;
static const float	TIME_BETWEEN_STATES_SLOW	= 1.0;

-(void)Startup
{
    [super Startup];
    
    mRainbowStateMachine			= [ (HandStateMachineRainbow*   ) [HandStateMachineRainbow      alloc] InitWithGameRainbow:self];
    mRainbowEnvironment             = [ (RainbowEnvironment*        ) [RainbowEnvironment			alloc] Init];
    
    sRainbowUI                      = [(RainbowUI*) [RainbowUI alloc] InitWithEnvironment:mRainbowEnvironment];
    
    [[CardRenderManager GetInstance] SetGameEnvironment:mRainbowEnvironment];
    
	[ [CardManager			GetInstance		]	SetShuffleEnabled:FALSE				];
    [ [CameraStateMgr		GetInstance		]	Push:[Run21IntroCamera		alloc	]];
	[ mRainbowStateMachine						Push:[HandStateRainbow_Init	alloc	]];
    
    [self RegisterTutorialUI];
    [self SetStingerSpawner:NULL];
    [self SetTriggerEvaluator:self];
}

-(void)Shutdown
{
    [[CardRenderManager GetInstance] SetGameEnvironment:NULL];
    [mRainbowEnvironment release];
	
	[sRainbowUI			release];
    [mRainbowStateMachine release];
	
	[[CameraStateMgr GetInstance] Pop];
	[[CardManager GetInstance] SetShuffleEnabled:TRUE];
    
    [self ReleaseTutorialUI];
    
    [super Shutdown];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mTutorialPauseProcessingCount == 0)
    {
        [mRainbowStateMachine Update:inTimeStep];
    }
    
    [super Update:inTimeStep];
}

-(void)Suspend
{
    // Remove non-projected UI elements from screen
    [ sRainbowUI TogglePause:FALSE];
    [self ReleaseTutorialUI];
}

-(void)Resume
{
    [ sRainbowUI TogglePause:TRUE];
    [self RegisterTutorialUI];
}

-(void)DrawOrtho
{
    //uncomment this to hide on screen text
    //return;
#if DEBUG_SHOW_BUTTON_NAMES == 1
    int	  textSize = 14;
    float fRed = 1.0, fBlue = 0.0, fGreen = 1.0;
    int HandStart = 50;
    int HandEnd = 300;
    int DealerHand = 150;
    int PlayerHand = 220;
    int ButtonClusterStart = 360;
    int ButtonClusterTop = 190;
    int RainbowLetters = 290;
    /*
    int UIRight = 340;
    int UITop = 150;
    int UIMiddle = 220;
    int UIBottom = 290;
    */

    [[DebugManager GetInstance] DrawString: @"Dealer Hand Holders" locX:HandStart locY:DealerHand size:textSize red:fRed blue:fBlue green:fGreen];
    [[DebugManager GetInstance] DrawString: @"Player Hand Holders" locX:HandStart locY:PlayerHand size:textSize red:fRed blue:fBlue green:fGreen];

    [[DebugManager GetInstance] DrawString: @"Turns Left" locX:ButtonClusterStart locY:ButtonClusterTop size:textSize red:fRed blue:fBlue green:fGreen];
    [[DebugManager GetInstance] DrawString: @"Dealer Stand Indicator" locX:HandEnd locY:DealerHand size:textSize red:fRed blue:fBlue green:fGreen];
    //[[DebugManager GetInstance] DrawString: @"Player Stand Indicator" locX:UIRight locY:UITop + 20 size:textSize red:fRed blue:fBlue green:fGreen];
    
    [[DebugManager GetInstance] DrawString: @"Stand Button" locX:ButtonClusterStart locY:ButtonClusterTop + 25 size:textSize red:fRed blue:fBlue green:fGreen];
    [[DebugManager GetInstance] DrawString: @"Unique Button" locX:ButtonClusterStart + 50 locY:ButtonClusterTop + 40 size:textSize red:fRed blue:fBlue green:fGreen];
    [[DebugManager GetInstance] DrawString: @"Draw Button" locX:ButtonClusterStart locY:ButtonClusterTop + 75 size:textSize red:fRed blue:fBlue green:fGreen];

    [[DebugManager GetInstance] DrawString: @"\"RAINBOW\" score indicator" locX:HandStart locY:RainbowLetters size:textSize red:fRed blue:fBlue green:fGreen];
#endif
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
    int intData    = (int) inData;
    int discardNum = 0;
    
    //Figure out how many cards we have face down, used for updating the UI
    if (inEventId == EVENT_RAINBOW_TOGGLE_DISCARD || inEventId == EVENT_RAINBOW_DISCARD)
    {
        for (int i = 0;  i < [mRainbowStateMachine->curHand count]; i++)
        {
            if (((Card*)[mRainbowStateMachine->curHand objectAtIndex:i])->bDiscard)
            {
                discardNum++;
            }
        }
    }
    if (inEventId == EVENT_RAINBOW_TOGGLE_DISCARD)
    {
        int intData     = (int) inData;
        int playerIndex = intData / RAINBOW_NUM_CARDS_IN_HAND;
        int cardIndex   = intData % RAINBOW_NUM_CARDS_IN_HAND;
        Card* discard = NULL;
        
        if (playerIndex == mRainbowStateMachine->curPlayer)
        {
            discard = ((Card*)[mRainbowStateMachine->curHand objectAtIndex:cardIndex]);
            
            if (discard->bDiscard)
            {
                discard->bDiscard = FALSE;
                [discard SetFaceUp:TRUE];
                discardNum--;
            }
            else
            {
                discard->bDiscard = TRUE;
                [discard SetFaceUp:FALSE];
                discardNum++;
            }
            //only change the buttons if it is the players turn,
            if (mRainbowStateMachine->curHand->mHandOwner == HAND_OWNER_PLAYER)
            {
                [sRainbowUI SetStatusForButtonArray:discardNum != 0];
            }
            [mRainbowStateMachine ReplaceTop:[HandStateRainbow_ScoreHand alloc]];
        }
    }
    else if (inEventId == EVENT_RAINBOW_NEW_ROUND)
    {
        if (mRainbowStateMachine->mHandPlayer[1]->mRainbowRoundsWon < RAINBOW_NUM_ROUNDS_PER_GAME)
        {
            [mRainbowStateMachine ReplaceTop:[HandStateRainbow_Cleanup alloc]];
        }
    }
    else if (inEventId == EVENT_RAINBOW_DISCARD)
    {
        if(mRainbowStateMachine->curHand->mHandOwner == HAND_OWNER_PLAYER)
        {
            if (discardNum > 0)
            {
                [mRainbowStateMachine ReplaceTop:[HandStateRainbow_PreDiscard alloc]];
            }
        }
    }
    else if(inEventId == EVENT_RAINBOW_STAND)
    {
        [self StandWithEndTurn:(BOOL)inData];
    }
    else if(inEventId == EVENT_RAINBOW_UNIQUE)
    {
        [mRainbowStateMachine ReplaceTop:[HandStateRainbow_Unique alloc]];
    }
    
    else if (inEventId == EVENT_RAINBOW_END_OPTION_SELECTED)
    {
        EEndGameButtons endAction = intData - ENDGAME_ID_OFFSET;
        Flow            *gameFlow = [Flow GetInstance];
        if (endAction == ENDGAMEBUTTON_LEVELSELECT)
        {
            NSAssert(FALSE, @"Need to replace below with new flow functions");
//            [gameFlow ProgressToMenu];
            gameFlow->mMenuToLoad = Rainbow_Main_LevelSelect;
            
            [[GameStateMgr GetInstance] Pop];
        }
        else if (endAction == ENDGAMEBUTTON_RETRY)
        {
            NSAssert(FALSE, @"Unhandled case");
#if 0
            [ gameFlow JumpProgress:NeonEngine_Bankrupt ];
#endif
        }
        return; // TODO: Crashes if the super process this event for some reason.
    }

    
    [super ProcessEvent:inEventId withData:inData];
}
-(HandStateMachineRainbow*)GetHSM
{
    return mRainbowStateMachine;
}

-(void)InitFromTutorialScript:(TutorialScript*)inTutorialScript
{
	[ CompanionManager CreateInstance ];
    
	[super InitFromTutorialScript:inTutorialScript];
}

-(void)RegisterTutorialUI
{
    [self RegisterUIObjects:[sRainbowUI GetButtonArray]];
}

-(void)ReleaseTutorialUI
{
    [self ReleaseUIObjects];
}

-(BOOL)TriggerCondition:(NSString*)inTrigger
{
    State* curState = [mRainbowStateMachine GetActiveState];
    NSString *stateName = NSStringFromClass([curState class]);
    
    return ([stateName compare:inTrigger] == NSOrderedSame);
}

-(void)EnableTutorialUIObject:(UIObject*)inObject
{
    [inObject SetActive:TRUE];
    [inObject Enable];
    [inObject BeginPulse];
}

-(void)DisableTutorialUIObject:(UIObject*)inObject
{
	[inObject SetActive:FALSE];
}

-(void)StandWithEndTurn:(BOOL)readyToEnd
{
    BOOL bIsDiscard = FALSE;
    
    for (int i = 0;  i < [mRainbowStateMachine->curHand count]; i++)
    {
        if (((Card*)[mRainbowStateMachine->curHand objectAtIndex:i])->bDiscard)
        {
            [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_TOGGLE_DISCARD withData:(void*)(mRainbowStateMachine->curHand->mHandIndex * RAINBOW_NUM_CARDS_IN_HAND + i)];
            bIsDiscard = TRUE;
        }
    }
    
    if (readyToEnd)
    {
        [mRainbowStateMachine ReplaceTop:[HandStateRainbow_PreDiscard alloc]];
    }
    else
    {
        [mRainbowStateMachine ReplaceTop:[HandStateRainbow_Decision alloc]];
    }
}

@end
// -----------------------------------------------------------------------------------------------------
// HSM
// -----------------------------------------------------------------------------------------------------

@implementation HandStateMachineRainbow

-(HandStateMachineRainbow*)InitWithGameRainbow:(GameRainbow*)inGameRainbow
{
    for(int i = 0; i <= RAINBOW_NUM_PLAYERS; i++)
    {
        mHandPlayer[i]						= [(PlayerHand*)[PlayerHand alloc] Init];
        
        mHandPlayer[i]->mHandIndex			= i;
		mHandPlayer[i]->mBet				= 0;
		mHandPlayer[i]->mOutcome			= Outcome_Initial;
        mHandPlayer[i]->mRainbowTurnsLeft   = RAINBOW_NUM_DEALS_PER_ROUND;
        
    }
    
    mHandPlayer[1]->mHandOwner = HAND_OWNER_PLAYER;
    
    mDeck                   = [(PlayerHand*) [PlayerHand alloc] Init];
    mDeck->mHandOwner       = HAND_OWNER_DEALER;
    mDeck ->mHandIndex      = MAX_PLAYER_HANDS;
    mDeck->mBet				= 0;
	mDeck->mOutcome			= Outcome_Initial;

    curPlayer               = 0;
    curHand                 = mHandPlayer[curPlayer];
    mTurnNumber             = 0;
    mGameRainbow			= inGameRainbow;
    mCompanionManager		= [ CompanionManager GetInstance ];
    
    return (HandStateMachineRainbow*)[super Init];
}

-(void)WipeTable
{}

-(void)EndGameTable
{}

-(void)NextTurn
{
    if (!bFirstDeal)
    {
        curHand->mRainbowTurnsLeft--;
        [sRainbowUI SetHandStatusForHand:curHand WithTurn:FALSE];
    }
    
    mTurnNumber ++;
    if (bFirstDeal || bPostStand || (mTurnNumber+1)%2 == 0)
    {
        curPlayer ++;
    }
    curPlayer %= RAINBOW_NUM_PLAYERS;
    curHand   = mHandPlayer[curPlayer];
    if (!bFirstDeal)
    {
        [sRainbowUI ChangeTurnNumber:curHand];
        [sRainbowUI SetHandStatusForHand:curHand WithTurn:TRUE];

    }
}
-(PlayerHand*)playerForNextTurn
{
    if (bFirstDeal || bPostStand || (mTurnNumber+1)%2 == 0)
    {
        return mHandPlayer[(curPlayer+1)%RAINBOW_NUM_PLAYERS];
    }
    else
    {
        return curHand;
    }
}
-(void)dealloc
{
    for (int i = 0; i < RAINBOW_NUM_PLAYERS;i++)
    {
        //set the currentHand, so that messages dont get sent to the hands we previously released
        curHand = mHandPlayer[i];
        [ mHandPlayer[i] removeAllObjects ];
		[ mHandPlayer[i] release ];
    }
    
    [CompanionManager DestroyInstance];
    [ [CardManager GetInstance] RegisterDeckWithShuffle:TRUE TotalJokers:0 ];
    [super dealloc];
}

@end

// -----------------------------------------------------------------------------------------------------
// Hand State for Rainbow
// -----------------------------------------------------------------------------------------------------

@implementation HandStateRainbow

-(void)Startup
{
    mStateTime = 0.0f;
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    mStateTime += inTimeStep;
	
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_Base";
}

-(PlayerHand*)GetCurrentPlayerHand
{
    HandStateMachineRainbow *hsm = (HandStateMachineRainbow*) mStateMachine;
    
    return hsm->mHandPlayer[hsm->curPlayer];
}


-(void)Shutdown
{
    [super Shutdown];
}

-(int)GetRemainingCards
{
    return 0;
}

@end

// --------------------------------------------------
// HS: Init
//* registers a deck with the cardMan and set up the tutorial conditions
// --------------------------------------------------
@implementation HandStateRainbow_Init
-(void) Startup
{
    CardManager				*cardMan			= [CardManager GetInstance];
//    HandStateMachineRainbow	*hsm	= (HandStateMachineRainbow*) mStateMachine;

    [super Startup];
    
    NSAssert(FALSE, @"Need to use new flow function");
    
    //cardMan->mNumDecks = [[ Flow GetInstance ] GetNumDecks];

    [cardMan RegisterDeckWithShuffle:TRUE TotalJokers:0];

#if 0
    if ( [[ Flow GetInstance ] InTutorialMode] )
    {
        hsm->curPlayer = 1;
        hsm->curHand = hsm->mHandPlayer[1];
        
        //Set the player to have 3 wins, so the tutorial is short
        while(hsm->mHandPlayer[1]->mRainbowRoundsWon < 3)
        {
            hsm->mHandPlayer[1]->mRainbowRoundsWon ++;
            [sRainbowUI EndRoundWithWinningPlayer:hsm->mHandPlayer[1] WithNumCards:4];
        }
        
        [sRainbowUI InterfaceMode:RAINUI_DONE_SCORING];
        //Dealer's last drawn card
        [ cardMan MoveCardToTopWithRank:CardLabel_Seven   out_Suit:CARDSUIT_Hearts  ];
        
        //Player's last drawn card
        [ cardMan MoveCardToTopWithRank:CardLabel_Four   out_Suit:CARDSUIT_Clubs  ];
        
        //Dealer's first two actions
        [ cardMan MoveCardToTopWithRank:CardLabel_Jack   out_Suit:CARDSUIT_Spades  ];
        [ cardMan MoveCardToTopWithRank:CardLabel_Jack   out_Suit:CARDSUIT_Hearts  ];

        //Player's First drawn Card
        [ cardMan MoveCardToTopWithRank:CardLabel_Two   out_Suit:CARDSUIT_Diamonds ];

        //Alternating player and dealer starting cards, with Dealer cards on the left and player cards on the right
        [ cardMan MoveCardToTopWithRank:CardLabel_Jack   out_Suit:CARDSUIT_Diamonds ];  [ cardMan MoveCardToTopWithRank:CardLabel_Five   out_Suit:CARDSUIT_Spades  ];
        [ cardMan MoveCardToTopWithRank:CardLabel_Jack   out_Suit:CARDSUIT_Clubs  ];    [ cardMan MoveCardToTopWithRank:CardLabel_Five   out_Suit:CARDSUIT_Diamonds  ];
        [ cardMan MoveCardToTopWithRank:CardLabel_Seven   out_Suit:CARDSUIT_Diamonds ]; [ cardMan MoveCardToTopWithRank:CardLabel_Three   out_Suit:CARDSUIT_Spades  ];
        [ cardMan MoveCardToTopWithRank:CardLabel_Two   out_Suit:CARDSUIT_Spades ];     [ cardMan MoveCardToTopWithRank:CardLabel_Ace   out_Suit:CARDSUIT_Hearts  ];

        
    }
#endif
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES )
	{
		[ mStateMachine ReplaceTop:[HandStateRainbow_TableSetup alloc]];

	}
    
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Rainbow_Init";
}

-(void)Shutdown
{
	[super Shutdown];
}
@end
// --------------------------------------------------
// HS: Table Setup
// * Set up the starting conditions of the table
// --------------------------------------------------

@implementation HandStateRainbow_TableSetup
-(void)Startup
{
	HandStateMachineRainbow	*hsm	= (HandStateMachineRainbow*) mStateMachine;

	hsm->bFirstDeal					= TRUE;
    hsm->bPostStand                 = FALSE;

#if RAINBOW_WIN
    /* Instant win */
     hsm->curHand = hsm->mHandPlayer[RAINBOW_WIN - 1];
     hsm->curPlayer = RAINBOW_WIN - 1;
    
    while(hsm->curHand->mRainbowRoundsWon < 3)
    {
        hsm->curHand->mRainbowRoundsWon ++;
        [sRainbowUI EndRoundWithWinningPlayer:hsm->curHand WithNumCards:4];
    }
    
     CardManager				*cardMan			= [CardManager GetInstance];
     
     //Alternating player and dealer starting cards
     [ cardMan MoveCardToTopWithRank:CardLabel_Six   out_Suit:CARDSUIT_Diamonds ]; [ cardMan MoveCardToTopWithRank:CardLabel_Jack   out_Suit:CARDSUIT_Spades  ];
     [ cardMan MoveCardToTopWithRank:CardLabel_Eight   out_Suit:CARDSUIT_Hearts  ];   [ cardMan MoveCardToTopWithRank:CardLabel_Queen  out_Suit:CARDSUIT_Clubs  ];
     [ cardMan MoveCardToTopWithRank:CardLabel_Jack  out_Suit:CARDSUIT_Clubs ]; [ cardMan MoveCardToTopWithRank:CardLabel_King   out_Suit:CARDSUIT_Diamonds  ];
     [ cardMan MoveCardToTopWithRank:CardLabel_Ace  out_Suit:CARDSUIT_Spades ]; [ cardMan MoveCardToTopWithRank:CardLabel_Ace    out_Suit:CARDSUIT_Hearts  ];
#endif
    
    [super Startup];
    
    [ sRainbowUI InterfaceMode:RAINUI_STARTUP ];
	
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_SLOW )
	{
        [ sRainbowUI InterfaceMode:RAINUI_DEALING ];
		[ mStateMachine ReplaceTop:[HandStateRainbow_PreDeal alloc]];
	}
    
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Rainbow_TableSetup";
}

-(void)Shutdown
{
	[super Shutdown];
}
@end
// --------------------------------------------------
// HS: PreDeal
// * Checks how many cards the user has and draws a card if they need it
// --------------------------------------------------
@implementation HandStateRainbow_PreDeal
-(void)Startup
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
	CardManager				*cardMan			= [CardManager GetInstance];

    [super Startup];
    
    //If the player doesn't have the max cards, give them more
    while ([hsm->curHand count] < RAINBOW_NUM_CARDS_IN_HAND)
    {
        //Don't show the player the dealers cards untill the end
        BOOL faceUp = (hsm->curHand->mHandOwner != HAND_OWNER_DEALER) || DEBUG_DEALER_CARDS_FACEUP;
        
        [cardMan DealCardWithFaceUp:faceUp out_Hand:hsm->curHand cardMode:CARDMODE_NORMAL];
        [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:[hsm->curHand count]-1 ScoredStatus:PLACER_NOTSCORED_INACTIVE];
        hsm->curHand->bRainbowResort = TRUE;
        
        // if this is the first deal of the game, we alternate who gets the card.
        if (hsm->bFirstDeal)
        {
            [hsm NextTurn];
        }
    }
    
    if (hsm->bFirstDeal)
    {
        hsm->bFirstDeal = FALSE;
        hsm->mTurnNumber = 0;
        [sRainbowUI ChangeTurnNumber:hsm->curHand];
        hsm->mFirstPlayer = hsm->curPlayer;
    }
    else
    {
        [hsm NextTurn];
    }
    
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
        if (hsm->curHand->mHandOwner == HAND_OWNER_DEALER)
        {
            [mStateMachine ReplaceTop:[HandStateRainbow_BeginDealerTurn alloc]];
        }
        if (hsm->curHand->mHandOwner == HAND_OWNER_PLAYER)
        {
            [mStateMachine ReplaceTop:[HandStateRainbow_BeginPlayerTurn alloc]];
        }
    }
    
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_PreDeal";
}

-(void)Shutdown
{
    [super Shutdown];
}
@end


// --------------------------------------------------
// HS: Begin Player Turn
// * This state does some debug, but is mostly a dummy state for the tutorial
// --------------------------------------------------
@implementation HandStateRainbow_BeginPlayerTurn: HandStateRainbow
{}

-(void)Startup
{
    [super Startup];
    
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;

    NSLog(@"player %d's Turn, Hand %d",hsm->curPlayer,hsm->mTurnNumber);

}
-(void)Update:(CFTimeInterval)inTimeStep
{
    [mStateMachine ReplaceTop:[HandStateRainbow_ScoreHand alloc]];
}
-(NSString*)GetId
{
    return @"Rainbow_BeginPlayerTurn";

}
-(void)Shutdown
{
    [super Shutdown];
}
@end

// --------------------------------------------------
// HS: Begin Dealer Turn
// * This state does some debug, but is mostly a dummy state for the tutorial
// --------------------------------------------------
@implementation HandStateRainbow_BeginDealerTurn: HandStateRainbow
{}

-(void)Startup
{
    [super Startup];
    
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    NSLog(@"player %d's Turn, Hand %d",hsm->curPlayer,hsm->mTurnNumber);
}
-(void)Update:(CFTimeInterval)inTimeStep
{
    [mStateMachine ReplaceTop:[HandStateRainbow_ScoreHand alloc]];
}
-(NSString*)GetId
{
    return @"Rainbow_BeginDealerTurn";
    
}
-(void)Shutdown
{
    [super Shutdown];
}
@end


// --------------------------------------------------
// HS: Decision
// * does AI for computer players or sets the UI mode so that the player can make decisions
// --------------------------------------------------
@implementation HandStateRainbow_Decision

-(void)Startup
{
    [super Startup];
    
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if (hsm->curHand->mHandOwner == HAND_OWNER_DEALER)
    {
        NSAssert(FALSE, @"Need to use new flow functions");
#if 0
        Flow *gameFlow = [Flow GetInstance];

        //based on the difficulty level the dealer will play at different skill levels
        switch ([gameFlow GetDifficultyLevel])
        {
            //levels 1 and 2 are bronze
            case(Difficulty_Rainbow_Level1):
            case(Difficulty_Rainbow_Level2):
            {
                if (![self BronzeBluff] || DEBUG_DEALER_DOESNT_BLUFF)
                {
                    [self DoBronzeAI];
                }
                break;
            }
            //levels 3, 4 and 5 are silver
            case(Difficulty_Rainbow_Level3):
            case(Difficulty_Rainbow_Level4):
            case(Difficulty_Rainbow_Level5):
            {
                if(![self SilverBluff] || DEBUG_DEALER_DOESNT_BLUFF)
                {
                    [self DoSilverAI];
                }
                break;
            }
            //Levels 6, 7 and 8 are Gold
            case(Difficulty_Rainbow_Level6):
            case(Difficulty_Rainbow_Level7):
            case(Difficulty_Rainbow_Level8):
            {
                if(![self GoldBluff] || DEBUG_DEALER_DOESNT_BLUFF)
                {
                    [self DoGoldAI];
                }
                break;
            }
            //Levels 9 and 10 are Platinum
            case(Difficulty_Rainbow_Level9):
            case(Difficulty_Rainbow_Level10):
            {
                if(![self PlatinumBluff] || DEBUG_DEALER_DOESNT_BLUFF)
                {
                    [self DoPlatinumAI];
                }
                break;
            }
        }
#endif
        //after the AI is done decing which cards to discard, go ahead and discard
        [mStateMachine ReplaceTop:[HandStateRainbow_PreDiscard alloc]];
    }
    else
    {
        [sRainbowUI InterfaceMode:RAINUI_DECISION];
    }

}

// --------------------------------------------------
// Bronze Bluff
// This function that will tell the AI to Bluff based on certain conditions
// The Bronze AI does not bluff
// --------------------------------------------------
-(BOOL)BronzeBluff
{
    return FALSE;
}

// --------------------------------------------------
// Silver Bluff
// This function that will tell the AI to Bluff based on certain conditions
// The Silver AI Bluffs on the first turn some times
// --------------------------------------------------
-(BOOL)SilverBluff
{
    BOOL retval    = FALSE;
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if (hsm->curHand->mRainbowTurnsLeft == 4)
    {
        if (hsm->curHand->mRainbowCardsUnique == 3 && arc4random_uniform(99) > 50)
        {
            retval = TRUE;
        }
        else if(hsm->curHand->mRainbowCardsUnique == 2 && hsm->curHand->mRainbowValue[1] < CardLabel_Nine && arc4random_uniform(99) > 50)
        {
            retval = TRUE;
        }
    }
    return retval;
}

// --------------------------------------------------
// Gold Bluff
// This function that will tell the AI to Bluff based on certain conditions
// The Gold AI Bluffs Very Aggresively
// --------------------------------------------------
-(BOOL)GoldBluff
{
    BOOL retval    = FALSE;
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if (hsm->curHand->mRainbowCardsUnique == 3)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            if (hsm->curHand->mRainbowValue[0] <= CardLabel_Eight && hsm->curHand->mRainbowValue[1] <= CardLabel_Nine && hsm->curHand->mRainbowValue[2] <= CardLabel_Ten)
            {
                if (arc4random_uniform(99) < 75)
                {
                    retval = TRUE;
                }
            }
        }
        else if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            if (hsm->curHand->mRainbowValue[0] <= CardLabel_Nine && hsm->curHand->mRainbowValue[1] <= CardLabel_Ten && hsm->curHand->mRainbowValue[2] <= CardLabel_Jack)
            {
                if (arc4random_uniform(99) < 25)
                {
                    retval = TRUE;
                }
            }
        }
    }
    else if (hsm->curHand->mRainbowCardsUnique == 2)
    {
        if (hsm->curHand->mRainbowValue[1] <= CardLabel_Four)
        {
            if (arc4random_uniform(99) < 50)
            {
                retval = TRUE;
            }
        }
    }
    return retval;
}

// --------------------------------------------------
// Platinum Bluff
// This function that will tell the AI to Bluff based on certain conditions
// The Platinum AI Bluffs Smartly based on filters
// --------------------------------------------------
-(BOOL)PlatinumBluff
{
    BOOL retval    = FALSE;
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if(hsm->curHand->mRainbowCardsUnique == 3)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            if (hsm->curHand->mRainbowValue[0] <= CardLabel_Eight && hsm->curHand->mRainbowValue[1] <= CardLabel_Nine && hsm->curHand->mRainbowValue[2] <= CardLabel_Ten)
            {
                if (arc4random_uniform(99) <= 50)
                {
                    retval = TRUE;
                }
            }
        }
        else if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            if (hsm->curHand->mRainbowValue[0] <= CardLabel_Nine && hsm->curHand->mRainbowValue[1] <= CardLabel_Ten && hsm->curHand->mRainbowValue[2] <= CardLabel_Jack)
            {
                if (arc4random_uniform(99) <= 25)
                {
                    retval = TRUE;
                }
            }
        }
    }
    return retval;
}

// --------------------------------------------------
// Do Bronze AI
// This is a basic function that always discards any cards that don't score
// the bronze AI doesn't filter
// --------------------------------------------------
-(void)DoBronzeAI
{
    [self DoAIWithFirstFilter:CardLabel_First SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
}

// --------------------------------------------------
// Do Silver AI
// This function discards cards that don't score
// the Silver AI does some filtering
// --------------------------------------------------
-(void)DoSilverAI
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if (hsm->curHand->mRainbowCardsUnique == 2)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            [self DoAIWithFirstFilter:CardLabel_First SecondFilter:CardLabel_Six ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        else
        {
            [self DoAIWithFirstFilter:CardLabel_Five SecondFilter:CardLabel_Four ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
    }
    else
    {
        [self DoAIWithFirstFilter:CardLabel_First SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
    }
}

// --------------------------------------------------
// Do Gold AI
// This function discards cards that don't score
// the Gold AI does more aggresive filtering than silver
// --------------------------------------------------
-(void)DoGoldAI
{
    HandStateMachineRainbow	*hsm	= (HandStateMachineRainbow*) mStateMachine;
    
    if (hsm->curHand->mRainbowCardsUnique == 3)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            [self DoAIWithFirstFilter:CardLabel_Seven SecondFilter:CardLabel_Six ThirdFiter:CardLabel_Five FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            [self DoAIWithFirstFilter:CardLabel_Six SecondFilter:CardLabel_Five ThirdFiter:CardLabel_Four FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 1)
        {
            [self DoAIWithFirstFilter:CardLabel_First SecondFilter:CardLabel_First ThirdFiter:CardLabel_Four FourthFilter:CardLabel_First];
        }
    }
    if (hsm->curHand->mRainbowCardsUnique == 2)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            [self DoAIWithFirstFilter:CardLabel_First SecondFilter:CardLabel_Jack ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            [self DoAIWithFirstFilter:CardLabel_Jack SecondFilter:CardLabel_Nine ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            [self DoAIWithFirstFilter:CardLabel_Ten SecondFilter:CardLabel_Eight ThirdFiter:CardLabel_Four FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 1)
        {
            [self DoAIWithFirstFilter:CardLabel_Five SecondFilter:CardLabel_Four ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
    }
    if (hsm->curHand->mRainbowCardsUnique == 1)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            [self DoAIWithFirstFilter:CardLabel_Jack SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            [self DoAIWithFirstFilter:CardLabel_Ten SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            [self DoAIWithFirstFilter:CardLabel_Nine SecondFilter:CardLabel_First ThirdFiter:CardLabel_Four FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 1)
        {
            [self DoAIWithFirstFilter:CardLabel_Eight SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
    }
    
}

// --------------------------------------------------
// Do Platinum AI
// This function discards cards that don't score
// the Platinum does more aggresive filtering than Gold
// --------------------------------------------------
-(void)DoPlatinumAI
{
    HandStateMachineRainbow	*hsm	= (HandStateMachineRainbow*) mStateMachine;
    
    if (hsm->curHand->mRainbowCardsUnique == 3)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            [self DoAIWithFirstFilter:CardLabel_Seven SecondFilter:CardLabel_Six ThirdFiter:CardLabel_Five FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            [self DoAIWithFirstFilter:CardLabel_Six SecondFilter:CardLabel_Five ThirdFiter:CardLabel_Four FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            [self DoAIWithFirstFilter:CardLabel_Five SecondFilter:CardLabel_Four ThirdFiter:CardLabel_Three FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 1)
        {
            [self DoAIWithFirstFilter:CardLabel_First SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
    }
    if (hsm->curHand->mRainbowCardsUnique == 2)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            [self DoAIWithFirstFilter:CardLabel_Ten SecondFilter:CardLabel_Nine ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            [self DoAIWithFirstFilter:CardLabel_Nine SecondFilter:CardLabel_Eight ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            [self DoAIWithFirstFilter:CardLabel_Eight SecondFilter:CardLabel_Seven ThirdFiter:CardLabel_Four FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 1)
        {
            [self DoAIWithFirstFilter:CardLabel_Seven SecondFilter:CardLabel_Six ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
    }
    if (hsm->curHand->mRainbowCardsUnique == 1)
    {
        if (hsm->curHand->mRainbowTurnsLeft == 4)
        {
            [self DoAIWithFirstFilter:CardLabel_Jack SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 3)
        {
            [self DoAIWithFirstFilter:CardLabel_Ten SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 2)
        {
            [self DoAIWithFirstFilter:CardLabel_Nine SecondFilter:CardLabel_First ThirdFiter:CardLabel_Five FourthFilter:CardLabel_First];
        }
        if (hsm->curHand->mRainbowTurnsLeft == 1)
        {
            [self DoAIWithFirstFilter:CardLabel_Eight SecondFilter:CardLabel_First ThirdFiter:CardLabel_First FourthFilter:CardLabel_First];
        }
    }

}

// --------------------------------------------------
// Do AI
// This function discards cards that don't score or are above a certain filter level
// Inputs: Four labels which correspond the the minimum label the AI will keep in each slot
// Outputs: None
// --------------------------------------------------
-(void)DoAIWithFirstFilter:(CardLabel)inFirst SecondFilter:(CardLabel)inSecond ThirdFiter:(CardLabel)inThird FourthFilter:(CardLabel)inFourth
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    int buttonNumber;
    int filters[4];
    
    filters[0] = inFirst;
    filters[1] = inSecond;
    filters[2] = inThird;
    filters[3] = inFourth;
    
    for (int i = 0; i < RAINBOW_NUM_CARDS_IN_HAND; i++)
    {
        //Aces are the best card in Rainbow
        int cardScore = hsm->curHand->mRainbowValue[i] == CardLabel_Ace ? CardLabel_Num : hsm->curHand->mRainbowValue[i];
        // if the card doesn't pass our filter, or just doesn't score, discard it
        if (cardScore < filters[i] || !((Card*)[hsm->curHand objectAtIndex:i])->bIsScored)
        {
            buttonNumber = hsm->curPlayer * RAINBOW_NUM_CARDS_IN_HAND + i;
            [ [ GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_TOGGLE_DISCARD withData:(void*)buttonNumber];
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_Decision";
}


-(void)Shutdown
{
    [super Shutdown];
}


@end
// --------------------------------------------------
// HS: Stand
// --------------------------------------------------
@implementation HandStateRainbow_Stand : HandStateRainbow
{}

-(void)Startup
{

}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    BOOL bIsDiscard = FALSE;
    
    for (int i = 0;  i < [hsm->curHand count]; i++)
    {
        if (((Card*)[hsm->curHand objectAtIndex:i])->bDiscard)
        {
            [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_TOGGLE_DISCARD withData:(void*)(hsm->curHand->mHandIndex * RAINBOW_NUM_CARDS_IN_HAND + i)];
            bIsDiscard = TRUE;
        }
    }
    
    if (bIsDiscard)
    {
        [mStateMachine ReplaceTop:[HandStateRainbow_Decision alloc]];
    }
    else
    {
        [mStateMachine ReplaceTop:[HandStateRainbow_PreDiscard alloc]];
    }
}

-(NSString*)GetId
{
    return @"Rainbow_Stand";
}

-(void)Shutdown
{
    [super Shutdown];
}
@end

// --------------------------------------------------
// HS: Unique
// --------------------------------------------------
@implementation HandStateRainbow_Unique : HandStateRainbow

-(void)Startup
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    for (int i = 0;  i < RAINBOW_NUM_CARDS_IN_HAND; i++)
    {
        if (i >= hsm->curHand->mRainbowCardsUnique)
        {
            if ( ! ((Card*)[hsm->curHand objectAtIndex:i])->bDiscard )
            {
                [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_TOGGLE_DISCARD withData:(void*)(hsm->curHand->mHandIndex * RAINBOW_NUM_CARDS_IN_HAND + i)];
            }
        }
    }

    
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mStateMachine ReplaceTop:[HandStateRainbow_Decision alloc]];
}

-(NSString*)GetId
{
    return @"Rainbow_Unique";
}


-(void)Shutdown
{
    [super Shutdown];
}
@end
// --------------------------------------------------
// HS: Pre-Discard
// * Determines which cards have been marked for discard, them moves them to the deck
// --------------------------------------------------
@implementation HandStateRainbow_PreDiscard

-(void)Startup
{    
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    [super Startup];

    [sRainbowUI InterfaceMode:RAINUI_DEALING];


    for (int index = [hsm->curHand getDiscardIndexFromLeft:FALSE]; index != -1 ; index = [hsm->curHand getDiscardIndexFromLeft:FALSE])
    {
        index = [hsm->curHand getDiscardIndexFromLeft:FALSE];
        
        [hsm->mDeck splitCard:[hsm->curHand objectAtIndex:index] fromHand:hsm->curHand ];
        [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:index ScoredStatus:PLACER_DISABLED];
    }
    
    if(hsm->curHand->mHandOwner == HAND_OWNER_DEALER)
    {
        for (int i = 0; i < [hsm->curHand count]; i ++)
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:i ScoredStatus:PLACER_NOTSCORED_ACTIVE];
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ( mStateTime > TIME_BETWEEN_STATES )
	{
        [mStateMachine ReplaceTop:[HandStateRainbow_Discard alloc]];
    }
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_PreDiscard";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end

// --------------------------------------------------
// HS: Discard
// * gets rid of any card that is in the deck
// --------------------------------------------------
@implementation HandStateRainbow_Discard
-(void)Startup
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    // if the player didn't discard any cards, no other player has stood and we are not in the last round
    if ([hsm->mDeck  count] == 0 && !hsm->bPostStand && hsm->mTurnNumber < (RAINBOW_NUM_DEALS_PER_ROUND-1) * RAINBOW_NUM_PLAYERS)
    {
        NSLog(@"Going into post Stand Mode");
        hsm->bPostStand = TRUE;
        hsm->mTurnNumber = (RAINBOW_NUM_DEALS_PER_ROUND-1) * RAINBOW_NUM_PLAYERS;
        [sRainbowUI SetStandStatusForPlayer:hsm->curHand];
        for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
        {
            hsm->mHandPlayer[i]->mRainbowTurnsLeft = 1;
        }
    }
    [hsm->mDeck removeAllObjects];
    [super Startup];
    
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    
    if (mStateTime > TIME_BETWEEN_STATES_FAST)
    {
        [mStateMachine ReplaceTop:[HandStateRainbow_PreDeal alloc]];
    }
        

	[super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_Discard";
}


-(void)Shutdown
{
    [super Shutdown];
}
@end

// --------------------------------------------------
// HS: Score Hand
// * scores the hand and lights up the corresponding placers
// --------------------------------------------------
@implementation HandStateRainbow_ScoreHand
-(void)Startup
{
    [super Startup];
    
    int i;
    int j;
    HandStateMachineRainbow	*hsm = (HandStateMachineRainbow*) mStateMachine;

    NSMutableArray* sortingArray    =  [[NSMutableArray alloc] initWithCapacity: [hsm->curHand count]]; // copy of the hand, that we mutate for sorting purposes
    NSMutableArray* scoringCards    =  [[NSMutableArray alloc] initWithCapacity: [hsm->curHand count]]; // the unique cards that score in the hand

    //copy the array for the hand of cards, we don't want to modify the actual hand
    for (i = 0; i < [hsm->curHand count]; i++)
    {
        //if the card is going to be discarded, don't score it.
        if (! ((Card*) [hsm->curHand objectAtIndex:i])->bDiscard )
        {
            [sortingArray addObject: [hsm->curHand objectAtIndex:i]];
        }
        else
        {
            ((Card*) [hsm->curHand objectAtIndex:i])->bIsScored = FALSE;
        }
    }
    
    // scoringCards gets filled with all of the unique cards in order from label low to high
    while ([sortingArray count] > 0)
    {
        Card* smallCard = [self GetLargest:sortingArray];
        
        smallCard->bIsScored = TRUE;
        [scoringCards addObject:smallCard];
        [sortingArray removeObject:smallCard];
        
        // All non-unique cards matching the smallest labeled card should be moved to the nonUniqueArray array as they do not score.
        for (i = 0; i < [sortingArray count]; i++)
        {
            if ( [[sortingArray objectAtIndex:i] GetLabel] == [smallCard GetLabel] ||
                 [[sortingArray objectAtIndex:i] GetSuit] == [smallCard GetSuit]    )
            {
                ((Card*) [sortingArray objectAtIndex:i])->bIsScored = FALSE;
                [sortingArray removeObjectAtIndex:i];
                i--;
            }
        }
    }
    // update the hand's score
    hsm->curHand->mRainbowCardsUnique = [scoringCards count];
    for (i = 0, j = 0; i < [hsm->curHand count]; i++)
    {
        //update the placer for the ith card
        if (hsm->curHand->mHandOwner == HAND_OWNER_PLAYER)
        {
            if ( ((Card*)[hsm->curHand objectAtIndex:i])->bIsScored )
            {
                [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:i ScoredStatus:PLACER_SCORED_ACTIVE];
            }
            else
            {
                [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:i+j ScoredStatus:PLACER_NOTSCORED_ACTIVE];
            }
        }
    }
    
    [sortingArray       release];
    [scoringCards       release];
    
}

-(Card*)GetSmallest:(NSMutableArray*)inArray
{
    Card* retval = nil;
    Card* nextSmallest;
    NSMutableArray* smallest = [[NSMutableArray alloc] initWithCapacity: [inArray count]];
    NSMutableArray* recursionArray = [[NSMutableArray alloc] initWithCapacity: [inArray count]];
    
    // This gets all of the cards with the smallest label in the array
    // There may be multiple cards because cards with different suits may share the same label
    for (int i = 0; i < [inArray count]; i++)
    {
        if ([smallest count] == 0)
        {
            [smallest addObject: [inArray objectAtIndex:i]];
        }
        else if ([[smallest objectAtIndex:0] GetLabel] > [[inArray objectAtIndex:i] GetLabel])
        {
            [smallest removeAllObjects];
            [smallest addObject: [inArray objectAtIndex:i]];
        }
        else if ([[smallest objectAtIndex:0] GetLabel] == [[inArray objectAtIndex:i] GetLabel])
        {
            [smallest addObject: [inArray objectAtIndex:i]];
        }

    }

    
    // if there is more than one card that has the smallest label we want to pick the one that either
    // doesn't have any other cards of the same suit,
    // or has the largest card of the same suit
    if ([smallest count] > 1)
    {
        for (int i = 0; i < [inArray count]; i++)
        {
            [recursionArray addObject:[inArray objectAtIndex:i]];
        }
        for (int i = 0; i < [smallest count]; i++)
        {
            [recursionArray removeObject: [smallest objectAtIndex:i]];
        }
        
        while ([smallest count] > 1 && [recursionArray count] >= 1)
        {
            nextSmallest = [self GetSmallest:recursionArray];
            
            [self RemoveSuit:[nextSmallest GetSuit] FromArray: smallest];
            [recursionArray removeObject:nextSmallest];
        }
    }
    [recursionArray release];
    retval = [smallest objectAtIndex:0];
    [smallest release];
    return retval;
}

-(Card*)GetLargest:(NSMutableArray*)inArray
{
    Card* retval = nil;
    Card* nextLargest;
    NSMutableArray* largestCards = [[NSMutableArray alloc] initWithCapacity: [inArray count]];
    NSMutableArray* recursionArray = [[NSMutableArray alloc] initWithCapacity: [inArray count]];
    
    // This gets all of the cards with the largest label in the array
    // There may be multiple cards because cards with different suits may share the same label
    for (int i = 0; i < [inArray count]; i++)
    {
        if ([largestCards count] == 0)
        {
            [largestCards addObject: [inArray objectAtIndex:i]];
        }
        else if ([[inArray objectAtIndex:i] GetLabel] == CardLabel_Ace)
        {
            if ([[largestCards objectAtIndex:0] GetLabel] == CardLabel_Ace)
            {
                [largestCards addObject: [inArray objectAtIndex:i]];
            }
            else
            {
                [largestCards removeAllObjects];
                [largestCards addObject: [inArray objectAtIndex:i]];
            }
        }
        else if ([[largestCards objectAtIndex:0] GetLabel] == CardLabel_Ace)
        {
            continue;
        }
        else if ([[largestCards objectAtIndex:0] GetLabel] < [[inArray objectAtIndex:i] GetLabel])
        {
            [largestCards removeAllObjects];
            [largestCards addObject: [inArray objectAtIndex:i]];
        }
        else if ([[largestCards objectAtIndex:0] GetLabel] == [[inArray objectAtIndex:i] GetLabel])
        {
            [largestCards addObject: [inArray objectAtIndex:i]];
        }
        
    }
    
    
    // if there is more than one card that has the smallest label we want to pick the one that either
    // doesn't have any other cards of the same suit,
    // or has the largest card of the same suit
    if ([largestCards count] > 1)
    {
        for (int i = 0; i < [inArray count]; i++)
        {
            [recursionArray addObject:[inArray objectAtIndex:i]];
        }
        for (int i = 0; i < [largestCards count]; i++)
        {
            [recursionArray removeObject: [largestCards objectAtIndex:i]];
        }
        
        while ([largestCards count] > 1 && [recursionArray count] >= 1)
        {
            nextLargest = [self GetLargest:recursionArray];
            
            [self RemoveSuit:[nextLargest GetSuit] FromArray: largestCards];
            [recursionArray removeObject:nextLargest];
        }
    }
    [recursionArray release];
    retval = [largestCards objectAtIndex:0];
    [largestCards release];
    
    return retval;
}

-(void)RemoveSuit:(int)inSuit FromArray:(NSMutableArray*)inArray
{
    for (int i = 0; i < [inArray count]; i++)
    {
        if ([[inArray objectAtIndex:i] GetSuit] == inSuit)
        {
            [inArray removeObjectAtIndex:i];
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mStateTime >= TIME_BETWEEN_STATES_FAST)
    {
        [mStateMachine ReplaceTop:[HandStateRainbow_SortHand alloc]];
    }
    [super Update:inTimeStep];

}
-(NSString*)GetId
{
    return @"Rainbow_ScoreHand";
}
-(void)Shutdown
{
    [super Shutdown];
}

@end
// --------------------------------------------------
// HS: Sort Hand
// * if the hand needs to be sorted, it makes it so the smallest scoring card is on the right
// * and the non-scoring cards are on the left
// --------------------------------------------------
@implementation HandStateRainbow_SortHand
-(void)Startup
{
    [super Startup];
    HandStateMachineRainbow	*hsm = (HandStateMachineRainbow*) mStateMachine;
    Card *smallest,*comparer;
    if (hsm->curHand->bRainbowResort)
    {
        for (int i = 0; i < RAINBOW_NUM_CARDS_IN_HAND; i++)
        {
            smallest = (Card*)[hsm->curHand objectAtIndex:i];
            
            for (int j = i+1; j < RAINBOW_NUM_CARDS_IN_HAND;j++)
            {
                comparer = (Card*)[hsm->curHand objectAtIndex:j];
                
                if (comparer->bIsScored)
                {
                    if (!smallest->bIsScored)
                    {
                        smallest = comparer;
                    }
                    else if(smallest->mLabel == CardLabel_Ace)
                    {
                        smallest = comparer;
                    }
                    if (comparer->mLabel == CardLabel_Ace)
                    {
                        continue;
                    }
                    else if(smallest->mLabel > comparer->mLabel)
                    {
                        smallest = comparer;
                    }
                }
            }
            
            [hsm->curHand swapCard:smallest withCard:[hsm->curHand objectAtIndex:i] fromHand:hsm->curHand];
            hsm->curHand->mRainbowValue[i] = smallest->bIsScored ? smallest->mLabel : CardLabel_Num;
            
            //Update the Placers, if it is the player's turn
            if (hsm->curHand->mHandOwner == HAND_OWNER_PLAYER)
            {
                if(smallest->bIsScored)
                {
                    [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:i ScoredStatus:PLACER_SCORED_ACTIVE];
                }
                else
                {
                    [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:i ScoredStatus:PLACER_NOTSCORED_ACTIVE];
                }
            }
        }
        hsm->curHand->bRainbowResort = FALSE;
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;

    if (mStateTime >= TIME_BETWEEN_STATES_FAST)
    {
        if (hsm->mTurnNumber >= RAINBOW_NUM_DEALS_PER_ROUND * RAINBOW_NUM_PLAYERS)
        {
            int startPlayer = hsm->curPlayer;
            BOOL allSorted = TRUE;
            //Make sure all Hands are properly sorted and scored before going on and evaluating the round
            do 
            {
                if (hsm->curHand->bRainbowResort)
                {
                    [mStateMachine ReplaceTop:[HandStateRainbow_ScoreHand alloc]];
                    allSorted = FALSE;
                    break;
                }
                [hsm NextTurn];
                
            } while(hsm->curPlayer != startPlayer);
            
            if (allSorted)
            {
                //All hands are properly sorted and scored now, evaluate the round
                [mStateMachine ReplaceTop:[HandStateRainbow_EvaluateRound alloc]];
            }
        }
        else
        {
            [mStateMachine ReplaceTop:[HandStateRainbow_Decision alloc]];
        }
    }
    
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_SortHand";
}

-(void)Shutdown
{
    [super Shutdown];
}
@end
// --------------------------------------------------
// HS: Evaluate Round
// * Figures out who has won the round, and does a little animation to go with it
// HEADS UP This State de syncs the curPlayer and CurHand Variable
// --------------------------------------------------
@implementation HandStateRainbow_EvaluateRound

-(void)Startup
{
    
    [sRainbowUI InterfaceMode:RAINUI_SCORING];
    
    [super Startup];

}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    float animationTime = 0.8;
    
    if (mStateTime > (cardIndex + 1.0) *animationTime && cardIndex < 4)
    {
        [self AnimateScoring];
    }
    else if (mStateTime > 5.0 * animationTime && cardIndex == 4)
    {
        int numCards;
        //This de syncs the curPlayer and CurHand Variable
        //if its NULL there isn't really a player number to assign
        hsm->curHand = [self GetWinner];
        
        if(hsm->curHand != NULL)
        {
            hsm->curHand->mRainbowRoundsWon ++;
            numCards = hsm->curHand->mRainbowCardsUnique;
            if (hsm->curHand->mHandOwner == HAND_OWNER_DEALER)
            {
                [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_ROUND_LOSE withData:NULL];
            }
            else
            {
                [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_ROUND_WIN withData:NULL];
            }
        }
        else
        {
            [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_ROUND_PUSH withData:NULL];
            numCards = hsm->mHandPlayer[0]->mRainbowCardsUnique;
        }
        [sRainbowUI EndRoundWithWinningPlayer:hsm->curHand WithNumCards:numCards];
    
        //card index is set to five, so that a player does not get more that one win per round
        cardIndex = 5;
    }
    else if (mStateTime > 6.0 * animationTime && cardIndex == 5)
    {
        [mStateMachine ReplaceTop:[HandStateRainbow_EndRound alloc]];
    }
    
    
    [super Update:inTimeStep];
}

-(void)AnimateScoring
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    Card *cardDealer ,*cardPlayer;
    
    cardDealer = (Card*)[hsm->mHandPlayer[HAND_DEALER] objectAtIndex:cardIndex];
    cardPlayer = (Card*)[hsm->mHandPlayer[HAND_PLAYER] objectAtIndex:cardIndex];
    [cardDealer SetFaceUp:TRUE];
    [cardPlayer SetFaceUp:TRUE];
    
    //Color the placers differently based on how the cards score
    if (cardDealer->bIsScored)
    {
        //Both cards are scored, we need to compare the value to see which is better
        if(cardPlayer->bIsScored)
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_DEALER] ForCard:cardIndex ScoredStatus:PLACER_SCORED_INACTIVE];
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_PLAYER] ForCard:cardIndex ScoredStatus:PLACER_SCORED_INACTIVE];
            //Aces are the best card in Rainbow
            int scoreDealer = cardDealer->mLabel == CardLabel_Ace ? CardLabel_Num : cardDealer->mLabel;
            int scorePlayer = cardPlayer->mLabel == CardLabel_Ace ? CardLabel_Num : cardPlayer->mLabel;
            
            //Dealer Card is Worse than Player Card
            if (scoreDealer < scorePlayer)
            {
                [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_PLAYER] ForCard:cardIndex ScoredStatus:PLACER_SCORED_ACTIVE];
                [UISounds PlayUISound:SFX_STINGER_RAINBOW_CARDPLAYER];
            }
            //Player Card is Worse
            else if (scoreDealer > scorePlayer)
            {
                [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_DEALER] ForCard:cardIndex ScoredStatus:PLACER_SCORED_ACTIVE];
                [UISounds PlayUISound:SFX_STINGER_RAINBOW_CARDDEALER];
            }
            //Cards have the same Value
            else
            {
                [UISounds PlayUISound:SFX_STINGER_RAINBOW_CARDPUSH];
            }
        }
        //The players card isn't scored
        else
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_DEALER] ForCard:cardIndex ScoredStatus:PLACER_SCORED_ACTIVE];
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_PLAYER] ForCard:cardIndex ScoredStatus:PLACER_NOTSCORED_ACTIVE];
            [UISounds PlayUISound:SFX_STINGER_RAINBOW_CARDDEALER];

        }
    }
    //The dealer's card isn't scored
    else
    {
        [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_DEALER] ForCard:cardIndex ScoredStatus:PLACER_NOTSCORED_ACTIVE];
        
        if(cardPlayer->bIsScored)
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_PLAYER] ForCard:cardIndex ScoredStatus:PLACER_SCORED_ACTIVE];
            [UISounds PlayUISound:SFX_STINGER_RAINBOW_CARDPLAYER];
        }
        //Neither card is Scored
        else
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[HAND_PLAYER] ForCard:cardIndex ScoredStatus:PLACER_NOTSCORED_ACTIVE];
            [UISounds PlayUISound:SFX_STINGER_RAINBOW_CARDPUSH];

        }
    }
    cardIndex ++;
}

// GetWinner returns the winning hand, or NULL in case of a tie.
-(PlayerHand*)GetWinner
{
    HandStateMachineRainbow	*hsm    = (HandStateMachineRainbow*) mStateMachine;
    PlayerHand              *retval = NULL;
    
    // Whomever has the most unique cards in their hand, wins.
    if ( hsm->mHandPlayer[HAND_DEALER]->mRainbowCardsUnique != hsm->mHandPlayer[HAND_PLAYER]->mRainbowCardsUnique )
    {
        // If the Dealer has more unique cards
        if (hsm->mHandPlayer[HAND_DEALER]->mRainbowCardsUnique > hsm->mHandPlayer[HAND_PLAYER]->mRainbowCardsUnique)
            retval = hsm->mHandPlayer[HAND_DEALER];
        else
            retval = hsm->mHandPlayer[HAND_PLAYER];
    }
    // Both players have the same amount of unique cards, whomever has the best qualifying cards wins.  Otherwise it is a tie.
    else
    {
        int numUniqueCards = hsm->mHandPlayer[HAND_DEALER]->mRainbowCardsUnique - 1;
        
        // Go through each player's hand, from most significant to least signficant.  Best card in the most significant area wins the game.
        // i.e. (2,3,4,7) beats ( 3,4,5,6 ) as 7 > 6
        for ( int i = numUniqueCards; i >= 0 && retval == NULL ; i --)
        {
            // Get the next most signifiant card in the player's hand
            Card *cardDealer = (Card*)[hsm->mHandPlayer[HAND_DEALER] objectAtIndex:i];
            Card *cardPlayer = (Card*)[hsm->mHandPlayer[HAND_PLAYER] objectAtIndex:i];
            
            // Aces count as the best card in rainbow
            int scoreDealer = cardDealer->mLabel == CardLabel_Ace ? CardLabel_Num : cardDealer->mLabel;
            int scorePlayer = cardPlayer->mLabel == CardLabel_Ace ? CardLabel_Num : cardPlayer->mLabel;
            
            // If one player has a better card they win.  Otherwise retval remains NULL indicating a tie until the next check or a draw if hands are identical.
            if ( scoreDealer > scorePlayer )
                retval = hsm->mHandPlayer[HAND_DEALER];
            else if ( scorePlayer > scoreDealer )
                retval = hsm->mHandPlayer[HAND_PLAYER];
        }
    }

    return retval;
}

-(NSString*)GetId
{
    return @"Rainbow_EvaluateRound";
}
-(void)Shutdown
{
    [super Shutdown];
}

@end

// --------------------------------------------------
// HS: EndRound
// * Determines whether the game is over
// --------------------------------------------------
@implementation HandStateRainbow_EndRound: HandStateRainbow

-(void)Startup
{
    [sRainbowUI InterfaceMode:RAINUI_DONE_SCORING];
    [super Startup];

}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
    {
        if (hsm->mHandPlayer[i]->mRainbowRoundsWon >= RAINBOW_NUM_ROUNDS_PER_GAME)
        {
            [mStateMachine ReplaceTop:[HandStateRainbow_EvaluateGame alloc]];
        }
    }

    [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_EndRound";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end

// --------------------------------------------------
// HS: Cleanup
// * Resets the hands so they are ready to start a new game,
// * reseting thier scores and removing all the cards from thier hands
// --------------------------------------------------
@implementation HandStateRainbow_Cleanup
-(void)Startup
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    CardManager				*cardMan			= [CardManager GetInstance];

    [super Startup];
    
    //Set the correct player up to Go First,
    //The player that goes first is the player after the player that gets dealt to first
    if (hsm->curHand == NULL)
    {
        NSLog(@"TIE");
        hsm->curPlayer = hsm->mFirstPlayer;
    }
    else
    {
        NSLog(@"Player%d Wins",hsm->curHand->mHandIndex);
        NSLog(@"Player 0:%d", hsm->mHandPlayer[0]->mRainbowRoundsWon);
        NSLog(@"Player 1:%d", hsm->mHandPlayer[1]->mRainbowRoundsWon);

        
        hsm->curPlayer = hsm->curHand->mHandIndex;
    }
    hsm->curHand = hsm->mHandPlayer[hsm->curPlayer];
    //[hsm NextTurn];

    //Reset the score for all of the players,
    for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
    {
        [hsm->mHandPlayer[i] removeAllObjects];
        hsm->mHandPlayer[i]->mRainbowCardsUnique = 0;
        hsm->mHandPlayer[i]->mRainbowTurnsLeft = RAINBOW_NUM_DEALS_PER_ROUND;
        for (int j = 0; j < RAINBOW_NUM_CARDS_IN_HAND;j++)
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[i] ForCard:j ScoredStatus:PLACER_DISABLED];
            hsm->mHandPlayer[i]->mRainbowValue[j] = CardLabel_Num;
        }
    }
    
    [cardMan RegisterDeckWithShuffle:TRUE TotalJokers:0];
    
    //Reset the UI so that the turn counter and the discard Button are visible

    
}

-(void)Update:(CFTimeInterval)inTimeStep
{    
    if (mStateTime > TIME_BETWEEN_STATES_FAST)
    {
        [mStateMachine ReplaceTop:[HandStateRainbow_TableSetup alloc]];
    }
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_Cleanup";
}


-(void)Shutdown
{
    [super Shutdown];
}


@end

// --------------------------------------------------
// HS: Evaluate Game
// * Determines who has won the game
// --------------------------------------------------
@implementation HandStateRainbow_EvaluateGame
-(void)Startup
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    PlayerHand *winningHand;
    int winningPlayer;
    
    [super Startup];
    
    [sRainbowUI InterfaceMode:RAINUI_DONE_SCORING];
    
    hsm->mTurnNumber = 0;
    winningPlayer = hsm->curPlayer;
    winningHand = hsm->mHandPlayer[hsm->curPlayer];
    NSLog(@"Player:%d has won: %d rounds",winningPlayer,winningHand->mRainbowRoundsWon);
    [hsm NextTurn];
    
    while (hsm->mTurnNumber < RAINBOW_NUM_PLAYERS )
    {
        NSLog(@"Player:%d has won: %d rounds",hsm->curPlayer,hsm->curHand->mRainbowRoundsWon);

        if(hsm->curHand->mRainbowRoundsWon > winningHand->mRainbowRoundsWon)
        {
            winningHand = hsm->curHand;
            winningPlayer = hsm->curPlayer;
        }
        [hsm NextTurn];
    }
    
    if (winningHand->mHandOwner == HAND_OWNER_PLAYER)
    {
        hsm->bWonGame = TRUE;
    }
    else
    {
        hsm->bWonGame = FALSE;
    }
    NSLog(@"Player %d wins",winningPlayer);
    
    
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    if (mStateTime > TIME_BETWEEN_STATES_FAST)
    {
        if (hsm->bWonGame)
        {
            [mStateMachine ReplaceTop:[HandStateRainbow_Win alloc]];
        }
        else
        {
            [mStateMachine ReplaceTop:[HandStateRainbow_Lose alloc]];
        }
    }
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_EvaluateGame";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end

// --------------------------------------------------
// HS: Lose
// * Does the animation for losing as well as clearing the table, and showing the end game cards
// --------------------------------------------------
@implementation HandStateRainbow_Lose: HandStateRainbow

-(void)Startup
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    [super Startup];
    
    //Clear the Cards for all Players
    for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
    {
        [hsm->mHandPlayer[i] removeAllObjects];
    }
    [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_GAME_LOSE withData:NULL];
    

}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mStateTime > TIME_BETWEEN_STATES_SLOW)
    {
        [sRainbowUI EndGameWithWin:FALSE];
        [mStateMachine ReplaceTop:[HandStateRainbow_GameOver alloc]];
    }
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_Lose";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end

// --------------------------------------------------
// HS: Win
// * shows the end game animation for winning, counts up how many start you recieved
// * also shows the end game buttons
// --------------------------------------------------
@implementation HandStateRainbow_Win: HandStateRainbow

-(void)Startup
{
    [super Startup];

    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;

    //Clear the Cards for all Players
    for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
    {
        [hsm->mHandPlayer[i] removeAllObjects];
    }
    
    
	[[GameStateMgr GetInstance] SendEvent:EVENT_CONCLUSION_BROKETHEBANK withData:NULL];
    mStartAnimation = 2.0;
    mIndex = 1;
    mWaitTime = .5;
    bTableCleared = FALSE;
    bDoneScoring = FALSE;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;

    if (mStateTime > mStartAnimation && !bTableCleared)
    {
        [sRainbowUI EndGameWithWin:TRUE];
        bTableCleared = TRUE;
        hsm->curHand = hsm->mHandPlayer[1];
    }
    if(!bDoneScoring && mStateTime > mStartAnimation + mIndex * mWaitTime)
    {
        int cardIndex = (RAINBOW_NUM_CARDS_IN_HAND * RAINBOW_NUM_PLAYERS - mIndex) % RAINBOW_NUM_CARDS_IN_HAND;

        if (hsm->curHand->mHandOwner == HAND_OWNER_PLAYER)
        {
            [sRainbowUI UpdateScoredStatusForPlayer:hsm->curHand ForCard:cardIndex ScoredStatus:PLACER_SCORED_INACTIVE];
            [UISounds PlayUISound:SFX_STINGER_21SQUARED_COMPLETED_COLUMN];
            [sRainbowUI SetWinCounterForPlayer:hsm->curHand forLetterNumber:RAINBOW_NUM_ROUNDS_PER_GAME - cardIndex - 1 withWin:FALSE];
        }
        else
        {
            [sRainbowUI SetWinCounterForPlayer:hsm->curHand forLetterNumber:cardIndex withWin:FALSE];
            if (cardIndex >= hsm->curHand->mRainbowRoundsWon)
            {
                [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[1] ForCard:cardIndex ScoredStatus:PLACER_SCORED_ACTIVE];
                [UISounds PlayUISound:SFX_STINGER_21SQUARED_COMPLETED_ROW];
                [sRainbowUI ShowEndGameStar:cardIndex WithScored:TRUE];
                hsm->mNumStars ++;
            }
            else
            {
                [sRainbowUI UpdateScoredStatusForPlayer:hsm->mHandPlayer[1] ForCard:cardIndex ScoredStatus:PLACER_NOTSCORED_ACTIVE];
                [sRainbowUI ShowEndGameStar:cardIndex WithScored:FALSE];
                [UISounds PlayUISound:SFX_BLACKJACK_STAND];
            }
        }
        if (cardIndex == 0)
        {
            if (mIndex >= RAINBOW_NUM_CARDS_IN_HAND * RAINBOW_NUM_PLAYERS)
            {
                bDoneScoring = TRUE;
            }
            hsm->curHand =hsm->mHandPlayer[0];
        }
        
        mIndex ++;
    }
    else if(bDoneScoring)
    {
        Flow* gameFlow = [Flow GetInstance];
        
        int curLevel = [[Flow GetInstance] GetLevel];
        [[SaveSystem GetInstance] SetStarsForLevel:curLevel withStars:hsm->mNumStars];
        
        [ gameFlow UnlockNextLevel];
        [[GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_GAME_WIN withData:(void*)hsm->mNumStars];
        [mStateMachine ReplaceTop:[HandStateRainbow_PostWinWait alloc]];
    }

       [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_Win";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end

// --------------------------------------------------
// HS: Post Win Wait
// --------------------------------------------------
@implementation HandStateRainbow_PostWinWait: HandStateRainbow

-(void)Startup
{
    [super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRainbow	*hsm				= (HandStateMachineRainbow*) mStateMachine;
    
    if (mStateTime > TIME_BETWEEN_STATES_SLOW)
    {
        [sRainbowUI ShowEndGameButtonsWithStars:hsm->mNumStars];
        [mStateMachine ReplaceTop:[HandStateRainbow_GameOver alloc]];

    }
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_PostWinWait";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end
// --------------------------------------------------
// HS: GameOver
// --------------------------------------------------
@implementation HandStateRainbow_GameOver: HandStateRainbow

-(void)Startup
{    
    [super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
    return @"Rainbow_GameOver";
}


-(void)Shutdown
{
    [super Shutdown];
}

@end
