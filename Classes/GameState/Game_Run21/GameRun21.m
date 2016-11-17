 //
//  GameRun21.m
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011, All rights reserved.

#import "GameRun21.h"
#import "GameObjectManager.h"
#import "Flow.h"
#import "TextureButton.h"
#import "DebugManager.h"

#import "Run21UI.h"
#import "Run21Environment.h"

#import "CameraStateMgr.h"
#import "Run21IntroCamera.h"

#import "CardManager.h"
#import "CardRenderManager.h"
#import "Card.h"
#import "UINeonEngineDefines.h"
#import "SaveSystem.h"
#import "InAppPurchaseManager.h"
#import "AchievementManager.h"
#import "AdvertisingManager.h"
#import "RegenerationManager.h"
#import "ExperienceManager.h"
#import "NeonAccountManager.h"
#import "IAPStore.h"
#import "SplitTestingSystem.h"
#import "FacebookLoginMenu.h"
#import "LevelDefinitions.h"

#import "TutorialScript.h"

#define FLURRY_LOG_POWERUPS    (0)

static const float XRAY_CARD_ALPHA = 0.3;
static const int TORNADO_TIME_BONUS = 20;

@implementation Run21RefillLivesDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
#if !NEON_SOLITAIRE_21
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:NSLocalizedString(@"LS_Wait",NULL)])
    {
        NSLog(@"Player out of lives popup, canceled purchase");
    }
    
    else if ([title isEqualToString:NSLocalizedString(@"LS_FillLives",NULL)])
    {
        [[GameStateMgr GetInstance] Push:[[IAPStore alloc] InitWithTab:IAPSTORE_TAB_LIVES]];
    }
#endif
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"LS_AskAFriend",NULL)])
    {
#if FACEBOOK_ASK_FOR_LIVES
        [[NeonAccountManager GetInstance] FB_SendLifeRequest];
#endif
    }
}
@end

@implementation GameRun21

static Run21UI		*sRun21UI;
static const float	TIME_BETWEEN_STATES			= 0.5;
static const float	TIME_BETWEEN_STATES_FAST	= 0.05;
static const float	TIME_BETWEEN_STATES_SLOW	= 1.5;


#define DEBUG_JOKER_TEXT	0	// Uncomment to debug jokers
#define DEBUG_RAS_STATE		0	// Uncomment to draw run21 row status

#if DEBUG_RAS_STATE
static const char*  sDebugRASStates[RAS_NUM] = 
{   "<INACTIVE>",
	"{BUSTED}",
	"Unavailable",
	"Available",
	"Selected",
	"Will Clear",
	"Will Bust",
};
#endif

#if DEBUG_JOKER_TEXT
static const char*  sDebugJokerStates[JokerStatus_MAX] = 
{   "Table Off",						// JokerStatus_TableTurnedOff
	"Difficulty - Ineligible",			// JokerStatus_DifficultyIneligible
	"In Deck",							// JokerStatus_InDeck
	"In Placer",						// JokerStatus_InPlacer
	"Not Acquired / Been Played",		// JokerStatus_NotInDeck
};
#endif

-(void)Startup
{
    [super Startup];
    
    NeonStartTimer();
    
	// TODO: Get Jokers from Flow State
    mRun21Environment       = [(Run21Environment*)[Run21Environment alloc] Init];
	mRun21StateMachine      = [(HandStateMachineRun21*)[HandStateMachineRun21 alloc] InitWithGameRun21:self];
    sRun21UI                = [(Run21UI*)[Run21UI alloc] InitWithEnvironment:mRun21Environment gameState:self];
    mRefillLivesDelegate    = [Run21RefillLivesDelegate alloc];

    [[CardRenderManager GetInstance] SetGameEnvironment:mRun21Environment];

	[[CardManager GetInstance] SetShuffleEnabled:FALSE];
    [[CameraStateMgr GetInstance] Push:[Run21IntroCamera alloc]];
    
    if ([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON)
    {
        [mRun21StateMachine ShuffleMarathonLevelUp];
        [self FlurryTimedEvent:Flurry_Marathon_Play withStart:TRUE];
    }
    else
    {
        mRun21StateMachine->mLevel = 1;
        [self FlurryTimedEvent:Flurry_Run21_Play withStart:TRUE];
    }
    
	[mRun21StateMachine Push:[HandStateRun21_Init alloc]];
    
    [self RegisterTutorialUI];
    [self SetStingerSpawner:NULL];
    [self SetTriggerEvaluator:self];
    
    [[RegenerationManager GetInstance] SetNumLives_LevelStart];
    
    mStartMaxLevel = [[SaveSystem GetInstance] GetMaxLevel];
    [[SaveSystem GetInstance] SetMaxLevelStarted:[[Flow GetInstance] GetLevel]];
    
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    
    [[NeonMetrics GetInstance] logEvent:@"Game Run 21 Startup" withParameters:NULL];
}

-(void)FlurryTimedEvent:(FEvent)event withStart:(BOOL)bStart
{
    NSString*   flurryEventLabel = NULL;
    Flow*       gameFlow = [Flow GetInstance];

    switch ( event )
    {
        case Flurry_Run21_Play:
        {
            {
                // One based Indexing for Levels, offset by Run21_Level1 as the game's "Level 1"
                int nDifficultyLevel = [gameFlow GetLevel];
                
                if ( 10 == nDifficultyLevel )
                    flurryEventLabel = [NSString stringWithFormat:@"Run21_Level_X"];
                else
                    flurryEventLabel = [NSString stringWithFormat:@"Run21_Level_%d",nDifficultyLevel];
                
            }
            break;
        }
        case Flurry_Marathon_Play:
        {
            flurryEventLabel    = [NSString stringWithFormat:@"Run21_Marathon"];
            break;
        }
        case Flurry_Tablet_Impression:
        {
            NSAssert(FALSE, @"CANNOT Time event Flurry_Tablet_Impression from Game. Use [AdvertisingManager FlurryTabletEvent] %d", event);
            break;
        }
        default:
        {
            NSAssert(FALSE, @"FlurryTimedEvent - Invalid Flurry Event to log id: %d", event);
            break;
        }
    }

    if ( bStart )
    {
        [[NeonMetrics GetInstance] logEvent:flurryEventLabel withParameters:NULL timed:YES];
    }
    else
    {
        [[NeonMetrics GetInstance] endTimedEvent:flurryEventLabel withParameters:NULL];
    }
}

-(void)Shutdown
{
    [self SetMainMenuToLoad];
    
	// Todo: Cards aren't removed from the screen.
    [[CardRenderManager GetInstance] SetGameEnvironment:NULL];
	[mRun21Environment release];
	
	[sRun21UI			release];
    [mRun21StateMachine release];
    
    [mRefillLivesDelegate release];
	
	[[CameraStateMgr GetInstance] Pop];
	[[CardManager GetInstance] SetShuffleEnabled:TRUE];
    
    [self ReleaseTutorialUI];
    
    [[[GameStateMgr GetInstance] GetMessageChannel] RemoveListener:self];
    
    [[NeonMetrics GetInstance] logEvent:@"Game Run 21 Shutdown" withParameters:NULL];

    [super Shutdown];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mTutorialPauseProcessingCount == 0)
    {
        [mRun21StateMachine	Update:inTimeStep];
    }
    
    [sRun21UI Update:inTimeStep];
    
    [super Update:inTimeStep];
}

-(void)Suspend
{
	// Remove non-projected UI elements from screen
	[ sRun21UI TogglePause:TRUE];
    [self ReleaseTutorialUI];
}

-(void)Resume
{
    BOOL origXRayActive = mRun21StateMachine.xrayActive;
    
	// Restore projected UI elements from screen
	[ sRun21UI TogglePause:FALSE];
    [self RegisterTutorialUI];
    
    if (mRun21StateMachine.xrayActive && !origXRayActive)
    {
        if ([[mRun21StateMachine GetActiveState] class] != [HandStateGameOver class])
        {
            [mRun21StateMachine EvaluateXrayCard:[CardManager GetInstance]->mIndexNextCardDealt];
        }
    }
}

-(void)TutorialComplete
{
    [sRun21UI TutorialComplete];

    [super TutorialComplete];
}

-(void)RegisterTutorialUI
{
    [self RegisterUIObjects:[sRun21UI GetButtonArray]];
}

-(void)ReleaseTutorialUI
{
    [self ReleaseUIObjects];
}

-(void)InitFromTutorialScript:(TutorialScript*)inTutorialScript
{
	[ CompanionManager CreateInstance ]; 

	[super InitFromTutorialScript:inTutorialScript];
}

-(void)DrawOrtho
{
    char		myStr[256];
	CardManager *cardMan;
	Card		*nextCardToBeDealt;
	int			posX	= SidebarX;
	
	cardMan				= [CardManager GetInstance];
	
	// Enable to see which card will be dealt next.  ( Future ability in Run21 content patch )
	if ( FALSE )
	{
		
		if ( [cardMan-> mShoe count] - cardMan->mIndexNextCardDealt >= 1 )
		{
			nextCardToBeDealt	= [ cardMan->mShoe objectAtIndex:cardMan->mIndexNextCardDealt ];
			snprintf(myStr, 256, "Next [%s]", nextCardToBeDealt->mText );
		}
		else 
		{
			snprintf(myStr, 256, "End of Shoe" );
		}
    [[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:posX-115 locY:Sbar_Y5 - 35 ];
	}
	
	
#if MENU_FLOW_LABELING
	snprintf(myStr, 256, "%s - (%4.2f)", [[(HandStateRun21*)[mRun21StateMachine GetActiveState] GetId] UTF8String], ((HandStateRun21*)[mRun21StateMachine GetActiveState])->mStateTime );
    [[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:75 locY:Sbar_Y1 + 80 ];
#endif

#if DEBUG_JOKER_TEXT
	snprintf(myStr, 256, "GS-J #1: %s", sDebugJokerStates[ mRun21StateMachine->mJokers.status[CARDSUIT_JOKER_1] ] );
    [[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:50 locY:Sbar_Y1 + 0];
	
	snprintf(myStr, 256, "GS-J #2: %s", sDebugJokerStates[ mRun21StateMachine->mJokers.status[CARDSUIT_JOKER_2] ] );
    [[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:50 locY:Sbar_Y1 + 20 ];
	
	snprintf(myStr, 256, "UI-J #1: %s", sDebugJokerStates[sRun21UI->mJokers.status[ CARDSUIT_JOKER_1 ] ] );
    [[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:50 locY:Sbar_Y1 + 40];
	
	snprintf(myStr, 256, "UI-J #2: %s", sDebugJokerStates[sRun21UI->mJokers.status[ CARDSUIT_JOKER_2 ] ] );
    [[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:50 locY:Sbar_Y1 + 60 ];
#endif
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
		case EVENT_RUN21_END_OPTION_SELECTED:
		{
            int dataInt = (int)inMsg->mData;
			EEndGameButtons endAction = dataInt - ENDGAME_ID_OFFSET;
			Flow			*gameFlow = [ Flow GetInstance ];
			
			if ( ENDGAMEBUTTON_LEVELSELECT == endAction )
			{
                [[AdvertisingManager GetInstance] ShowAd];

                [self SetMainMenuToLoad];
				[[Flow GetInstance] ExitGameMode];
			}
            else if ( [[SaveSystem GetInstance] GetNumLives] >= 1 )
            {
                if (ENDGAMEBUTTON_RETRY == endAction)
                {
                    [gameFlow RestartLevel];
                }
                
                if (ENDGAMEBUTTON_ADVANCE == endAction)
                {
                    [[AdvertisingManager GetInstance] ShowAd];
                    [[Flow GetInstance] AdvanceLevel];
                }
            }
            else
            {
                NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"LS_NextLife",NULL) , [[RegenerationManager GetInstance] GetHealthRegenTimeString]];
                
                UIAlertView* getMoreLives = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_OutOfLives", NULL)
                                                                       message: msg
                                                                      delegate: mRefillLivesDelegate
                                                             cancelButtonTitle: NSLocalizedString(@"LS_Wait", NULL)
                                                             otherButtonTitles: NSLocalizedString(@"LS_FillLives", NULL),
                                                                                NSLocalizedString(@"LS_AskAFriend",NULL),nil];
                [getMoreLives show];
            }
			
			break;
		}
    }
    
    return;
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
	int dataInt = (int)inData;
	
	switch ( inEventId )
	{
		case EVENT_RUN21_CONFIRM:
			[ mRun21StateMachine ReplaceTop:[HandStatePlacementConfirm alloc]];
			break;
			
		// Called from HandStatePlacementConfirm & HandStatePlacementTest currently in GameRun21.m
		case EVENT_PLAYERHAND_SPLIT:
			break;
			
		// Called from Run21UI.m -> ButtonEvent for Row Press
		case EVENT_RUN21_PLACE_CARD:
			// A card can only be split into hands 0-3
			if ( dataInt >= mRun21StateMachine->mNumRunners || dataInt < 0 )
			{
				NSAssert(FALSE, @"Run21 - ProcessEvent // Place->Test, invalid inData index passed in");
			}
			
			mRun21StateMachine->mLastHandDealtTo	= dataInt;
			[ mRun21StateMachine ReplaceTop:[HandStatePlacementTest alloc]];
			break;
            
        case EVENT_USE_POWERUP:
        {
            switch (dataInt)
            {
                //TODO: change these to IAP ENUMS
                case 1:
                {
                    int numberOfTornadoes = [[SaveSystem GetInstance] GetNumTornadoes];
                    if (numberOfTornadoes > 0)
                    {
                        #if FLURRY_LOG_POWERUPS
                        [[NeonMetrics GetInstance] logEvent:@"Powerup_Use_Tornado" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithFormat:@"%d", [[SaveSystem GetInstance] GetNumTornadoes]] ,@"numLeft"   , nil]];
                        #endif
                        
                        if(!( mRun21StateMachine->mJokerStatus[CARDSUIT_JOKER_1] == JokerStatus_InPlacer || mRun21StateMachine->mJokerStatus[CARDSUIT_JOKER_2] == JokerStatus_InPlacer))
                        {
                            if (([mRun21StateMachine GetNumCardsOnTable] > 0) || (mRun21StateMachine->mTimeRemaining > 0))
                            {
                                [[SaveSystem GetInstance] SetNumTornadoes:[NSNumber numberWithInt: numberOfTornadoes - 1]];
                                [mRun21StateMachine ReplaceTop:[HandStateRun21_Tornado alloc]];
                            }
                        }
                    }
                    else
                    {
                        [[GameStateMgr GetInstance] Push:[IAPStore alloc]];
                    }
                    break;
                }
                case 2:
                {
                    [[GameStateMgr GetInstance] SendEvent:EVENT_OPEN_STORE withData:NULL];

                    #if FLURRY_LOG_POWERUPS
                    [[NeonMetrics GetInstance] logEvent:@"Powerup_Use_Xray" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%d", [[SaveSystem GetInstance] GetNumTornadoes] ] ,@"numLeft"   , nil]];
                    #endif
                    break;
                }
            }
            break;
        }
        
        case EVENT_OPEN_STORE:
        {
            if (mTutorialStatus == TUTORIAL_STATUS_COMPLETE)
            {
                [[GameStateMgr GetInstance] Push:[IAPStore alloc]];
                
                Message msg;
                msg.mId = EVENT_OPEN_STORE;
                msg.mData = NULL;
                
                [GetGlobalMessageChannel() BroadcastMessageSync:&msg];
            }
            break;
        }
        
        case EVENT_POWERUPS_AWARDED:
        {
            [sRun21UI UpdatePowerupAmounts];
            break;
        }
        
		default:
			break;
	}
    
    [super ProcessEvent:inEventId withData:inData];
}

-(HandStateMachineRun21*)GetHSM
{
	return mRun21StateMachine;
}

-(BOOL)TriggerCondition:(NSString*)inTrigger
{
    State* curState = [mRun21StateMachine GetActiveState];
    NSString *stateName = NSStringFromClass([curState class]);

    return ([stateName compare:inTrigger] == NSOrderedSame);
}

-(void)EnableTutorialUIObject:(UIObject*)inObject
{
    [inObject SetActive:TRUE];
    [inObject Enable];
}

-(void)DisableTutorialUIObject:(UIObject*)inObject
{
	[inObject SetActive:FALSE];
}

-(void)SetMainMenuToLoad
{
    Flow*   gameFlow = [ Flow GetInstance ];

    if([[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON)
    {
        gameFlow->mMenuToLoad = Run21_Main_LevelSelect;
        
        LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
        int mainMenuUnlockLevel = [levelDefinitions GetMainMenuUnlockLevel];
        
        if ((mStartMaxLevel == mainMenuUnlockLevel) && ([[SaveSystem GetInstance] GetMaxLevel] == (mainMenuUnlockLevel + 1)))
        {
            gameFlow->mMenuToLoad = NeonMenu_Main;
        }
    }
    else
    {
        gameFlow->mMenuToLoad = Run21_Main_Marathon;
    }
}

@end

@implementation HandStateMachineRun21

@synthesize xrayActive = bIsXRayActive;

-(void)GameOver
{
    mGameOver = TRUE;
    mTimerState = TIMERSTATE_COMPLETED;
}

-(void)ShuffleMarathonWithLevel:(int)level
{
    LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
    LevelInfo* levelInfo = [levelDefinitions GetLevelInfo:(level + RUN21_LEVEL_1)];
    
    mRemoveClubs = !levelInfo.Clubs;
    mRemoveHearts = !levelInfo.Hearts;
    mRemoveSpades = !levelInfo.Spades;
    mRemoveDiamonds = !levelInfo.Diamonds;
    
    mAddClubs = levelInfo.AddClubs;
    
    mNumDecks = levelInfo.NumDecks;
    mNumJokers = levelInfo.NumJokers;
        
    [ [CardManager GetInstance]	ShoeClear ];
    [ [CardManager GetInstance]	SetShuffleEnabled:FALSE ];
    
}

-(void)ShuffleMarathonLevelUp
{
    if ( mLevel >= 10 )
        mLevel = 9;     // The game doesn't progress past level 10.  It just plays level 10 until the player loses.
    
    // Add flow offset & Shuffle a new difficulty level of cards into the shoe
    [self ShuffleMarathonWithLevel:mLevel];
    
    // Level up the Marathon Level.
    mLevel++;

}

-(BOOL)isCardInHand:(Card*)playingCard
{
    for ( int i = 0 ; i < mNumRunners ; i++ )
    {
        PlayerHand  *iHand = mHandPlayer[i];
        
        for ( int j = 0; j < [iHand count]; j++ )
        {
            Card *pCard = [ iHand objectAtIndex:j ];
            
            if ( playingCard == pCard )
                return TRUE;
        }
    }
        
    return FALSE;
}

-(HandStateMachineRun21*)InitWithGameRun21:(GameRun21*)inGameRun21
{
    int numberOfXRays = [[SaveSystem GetInstance] GetNumXrays];
    
    mNumRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
    memset(mHandPlayer, 0, sizeof(mHandPlayer));
    
	for (int i = 0; i < mNumRunners; i++)
	{
        mHandPlayer[i]						= [(PlayerHand*)[PlayerHand alloc] Init];
		
        mHandPlayer[i]->mHandOwner			= HAND_OWNER_PLAYER;
        mHandPlayer[i]->mHandIndex			= i;
		mHandPlayer[i]->mBet				= 0;
		mHandPlayer[i]->mOutcome			= Outcome_Initial;
	}
	
	mHandToPlace					= [(PlayerHand*)[PlayerHand alloc] Init];
	mHandToPlace->mHandOwner		= HAND_OWNER_PLAYER;
	mHandToPlace->mHandIndex		= mNumRunners;
	mHandToPlace->mBet				= 0;
	mHandToPlace->mOutcome			= Outcome_Initial;

	mGameRun21						= inGameRun21;
	mLastHandDealtTo				= mNumRunners;
	mCompanionManager				= [ CompanionManager GetInstance ];
	mPlacerCard						= NULL;
	mHandContainingPlacerCard		= NULL;
	
	mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_DifficultyIneligible; // First called ; JokerStatus_TableTurnedOff;
	mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_TableTurnedOff;
	
	mCardsToPrePlay					= mNumRunners;
	mAutoPlayLastHand				= mNumRunners;
    powerUpUsed_Tornados            = 0;
    
    if(numberOfXRays > 0 && [[[Flow GetInstance] GetLevelDefinitions] GetXrayAvailable])
    {
        self.xrayActive = TRUE;
        [[SaveSystem GetInstance] SetNumXrays:[NSNumber numberWithInt:(numberOfXRays - 1)]];
    }
    else
    {
        self.xrayActive = FALSE;
    }
    
    LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
    
    mAddClubs = [levelDefinitions GetAddClubs];
    
    mRemoveClubs = ![levelDefinitions GetClubs];
    mRemoveSpades = ![levelDefinitions GetSpades];
    mRemoveDiamonds = ![levelDefinitions GetDiamonds];
    mRemoveHearts = ![levelDefinitions GetHearts];
    
    mNumDecks = [levelDefinitions GetNumDecks];
    
    if (mNumDecks == 0)
    {
        mNumDecks = 1;
    }
    
    mNumJokers = [levelDefinitions GetNumJokers];
    
    mXrayCardEvaluated = FALSE;
    
    mTimerState = TIMERSTATE_WAITING;
    mTimeRemaining = [levelDefinitions GetTimeLimitSeconds];
    
	return (HandStateMachineRun21*)[super Init];
}

-(void)SyncJokerStatusFromFlow
{
    if (mNumJokers >= 1)
    {
		mJokerStatus[CARDSUIT_JOKER_1] = JokerStatus_NotInDeck;
    }
	else
    {
		mJokerStatus[CARDSUIT_JOKER_1] = JokerStatus_DifficultyIneligible;
    }
	
	if (mNumJokers >= 2)
    {
		mJokerStatus[CARDSUIT_JOKER_2] = JokerStatus_NotInDeck;
    }
	else
    {
		mJokerStatus[CARDSUIT_JOKER_2] = JokerStatus_DifficultyIneligible;
    }
}

-(void)PrintDeckWithHeader:(NSString*)strHeader
{
#if START_CARD_DEBUG_LEVEL
    CardManager *cardMan = [ CardManager GetInstance ];
    NSLog(@"%@", strHeader);
    NSLog(@"======================");
    for ( int nIndex = 0 ; nIndex < [cardMan->mShoe count] ; nIndex++ )
    {
        Card* nCard = [ cardMan->mShoe objectAtIndex:nIndex ];
        char myStr[16];
        
        snprintf(myStr, 16, "%s",[ nCard GetCardString ] );
        
        NSLog(@"%d) %s", nIndex, myStr);
    }
#endif
}

-(void)dealloc
{
	mHandContainingPlacerCard	= NULL;
	mPlacerCard					= NULL;
	
	
	for ( int i = 0 ; i < MAX_PLAYER_HANDS ; i++ )
	{
		[ mHandPlayer[i] removeAllObjects ];
		[ mHandPlayer[i] release ];
	}
	
	[ mHandToPlace	removeAllObjects ];
	[ mHandToPlace	release];
	
    [CompanionManager DestroyInstance];
	
	[ [CardManager GetInstance] RegisterDeckWithShuffle:TRUE TotalJokers:0 ];
	[super dealloc];
}

-(void)EndGameTable
{
    if ([[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON)
    {
        for ( int nRow = 0 ; nRow < mNumRunners ; nRow++ )
        {
            // loop through hand, prevent bug where cards are redealt face down.
            for ( int nCard = 0; nCard < [ mHandPlayer[nRow] count ] ; nCard++ )
            {
                
                Card *pCard = [ mHandPlayer[nRow] objectAtIndex:nCard ];
                
                // flip card over in case card reference reuused.
                [ pCard SetFaceUp:TRUE ];
            }
            
            [ mHandPlayer[nRow] removeAllObjects ];
        }
        
        [ mHandToPlace removeAllObjects ];
    }

	mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_TableTurnedOff;
	mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_TableTurnedOff;
    
    endHandsScored = 0;
    
    // Do not display things on the right side of the table.
    [sRun21UI EndGamePreClear];
    
    
}

-(void)WipeTable
{
    //NSLog(@"Wiping Table.");
    
    if ( [[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON || bWonGame)
    {
        for ( int nRow = 0 ; nRow < mNumRunners ; nRow++ )
        {
            // loop through hand, prevent bug where cards are redealt face down.
            for ( int nCard = 0; nCard < [ mHandPlayer[nRow] count ] ; nCard++ )
            {
                
                Card *pCard = [ mHandPlayer[nRow] objectAtIndex:nCard ];
                
                // flip card over
                [ pCard SetFaceUp:TRUE ];
            }
            
            // TODO: Cards that were face down stay face down when redealt.
            [ mHandPlayer[nRow] removeAllObjects ]; // This is a problem.
        }
    }
	//Clear out the placer if there is an Xray card in the placer
	[ mHandToPlace removeAllObjects ];
	
	
	//[ [CardManager GetInstance] RegisterDeckWithShuffle:TRUE TotalJokers:0 ];	// Don't reinit the base deck anymore
	
	mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_TableTurnedOff;
	mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_TableTurnedOff;
}

-(int)GetRemainingCards
{
	CardManager				*cardMan	= [CardManager GetInstance];
	int numJokersInPlay					= 0;
    
    int xRayOffset = self.xrayActive ? 1 : 0;
    
    //We are out of cards, and the xRay card is not in the placer
    if ([cardMan->mShoe count] - cardMan->mIndexNextCardDealt == 0)
    {
        xRayOffset = 0;
    }
	
	for ( int i = 0 ; i < CARDSUIT_JOKER_MAX ; i++ )
		numJokersInPlay += ( mJokerStatus[i] == JokerStatus_InDeck || JokerStatus_InPlacer == mJokerStatus[i] );
	
	// Jokers shouldn't be counted in hands that they occupy, or they'll be double counted.
	if ( [mPlacerCard GetLabel] == CardLabel_Joker && [mHandToPlace count] == xRayOffset )
		numJokersInPlay--;
    
    if (numJokersInPlay < 0)
    {
        NSLog(@"Negative jokers");
    }
    
    NSAssert(numJokersInPlay >= 0, @"Negative jokers?");
    
    int cardsInHand = [mHandToPlace countForMode:CARDMODE_NORMAL];
    
	int cardsLeft = [cardMan->mShoe count] - cardMan->mIndexNextCardDealt + cardsInHand - numJokersInPlay/* - xRayOffset*/;
    
    return cardsLeft;
}

-(int)GetNumCardsOnTable
{
    int retval = 0;
    
    for(int i = 0; i < mNumRunners;i++)
    {
        retval += [mHandPlayer[i] count];
    }
    return retval;
}

-(void)EvaluateXrayCard:(int)inCardIndex;
{
    CardManager* cardMan = [CardManager GetInstance];
    
    // If xray is active, we need to peek at the card that comes next
    if(self.xrayActive)
    {
        if([self GetRemainingCards] > 0)
        {
            int nextIndex = inCardIndex;
            
            Card* xRayCard = NULL;
            
            if (nextIndex < [cardMan->mShoe count])
            {
                xRayCard = [cardMan->mShoe objectAtIndex:nextIndex];
                Card* expectedXrayCard = [cardMan->mShoe objectAtIndex:(nextIndex - 1)];
                
                // If we already have an X-Ray card in here, then remove it.  This scenario happens if the user busts, and the next
                // two jokers are two in a row.  The X-Ray card is then invalid
                
                int numCards = [mHandToPlace count];
                Card* placerXrayCard = NULL;
                int xRayCardIndex = 0;
                
                for (int i = 0; i < numCards; i++)
                {
                    Card* curCard = [mHandToPlace objectAtIndex:i];
                    
                    if (curCard.cardMode == CARDMODE_XRAY)
                    {
                         placerXrayCard = curCard;
                         xRayCardIndex = i;
                         break;
                    }
                }
                
                BOOL removeCard = FALSE;
                
                if (placerXrayCard != NULL)
                {
                    if (expectedXrayCard != NULL)
                    {
                        if ((placerXrayCard != expectedXrayCard) && (placerXrayCard != xRayCard))
                        {
                            removeCard = TRUE;
                        }
                    }
                }
                
                if (removeCard)
                {
                    [mHandToPlace removeObjectAtIndex:xRayCardIndex];
                }
                
                xRayCard.cardMode = CARDMODE_XRAY;
                [mHandToPlace addCard:xRayCard];
            }
        }
        
        mXrayCardEvaluated = TRUE;
    }
    else
    {
        mXrayCardEvaluated = FALSE;
    }
}

-(void)setXrayActive:(BOOL)inXrayActive
{
	[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_XRAY_ACTIVE withData:[NSNumber numberWithInt:inXrayActive]];
    bIsXRayActive = inXrayActive;
}

-(BOOL)xrayActive
{
    return bIsXRayActive;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mTimerState)
    {
        case TIMERSTATE_WAITING:
        {
            break;
        }
        
        case TIMERSTATE_RUNNING:
        {
            mTimeRemaining -= inTimeStep;
            
            if (mTimeRemaining < 0.0)
            {
                mTimeRemaining = 0.0;
                mTimerState = TIMERSTATE_COMPLETED;
                [self ReplaceTop:[HandStateRun21_Lose alloc]];
            }
            
            break;
        }
        
        case TIMERSTATE_COMPLETED:
        {
            break;
        }
    }
    
    [super Update:inTimeStep];
}

-(CFTimeInterval)GetTimeRemaining
{
    return mTimeRemaining;
}

@end

@implementation HandStateRun21
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
	return @"Run21_Base";
}
-(void)Shutdown
{
	[super Shutdown];
}

-(PlayerHand*)GetActiveHand
{
	HandStateMachineRun21	*hsm = (HandStateMachineRun21*) mStateMachine;
	
	return hsm->mHandPlayer[hsm->mLastHandDealtTo];
}

@end

// --------------------------------------------------
// HS: Init
// --------------------------------------------------
@implementation HandStateRun21_Init
-(void)Startup
{
	CardManager				*cardMan			= [CardManager GetInstance];
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    
    if (cardMan == NULL)
    {
        [CardManager CreateInstance];
        cardMan = [CardManager GetInstance];
        
        [[CardRenderManager GetInstance] SetGameEnvironment:hsm->mGameRun21->mRun21Environment];
    }
	
	[super Startup];
	
	cardMan->mNumDecks = hsm->mNumDecks;
	[cardMan RegisterDeckWithShuffle:TRUE TotalJokers:hsm->mNumJokers];
	
	hsm->mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_DifficultyIneligible; // Second called, before visible , JokerStatus_TableTurnedOff;
	hsm->mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_TableTurnedOff;
	
	[ sRun21UI InterfaceMode:R21UI_PoweredOff ];
	[ sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_Inactive ]; 
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateRun21_TableSetup alloc]];
	}

	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_Init";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Table Setup
// --------------------------------------------------
@implementation HandStateRun21_TableSetup
-(void)Startup
{
	BOOL			bRainbowValid;
	CardManager		*cardMan						= [CardManager GetInstance];
	int				rainbowRank[MAX_PLAYER_HANDS]	= {CardLabel_Ace, CardLabel_Num, CardLabel_Num, CardLabel_Num, CardLabel_Num};
	int				rainbowSuit[MAX_PLAYER_HANDS]	= {CARDSUIT_Clubs, CARDSUIT_Diamonds, CARDSUIT_Hearts, CARDSUIT_Spades, CARDSUIT_Clubs};
	HandStateMachineRun21	*hsm					= (HandStateMachineRun21*) mStateMachine;
	hsm->inputMode									= eInput_CPU_Preplay;
    int             nIndex                          = 0;
    TutorialScript* tutorialScript                  = hsm->mGameRun21->mTutorialScript;
    NSMutableArray* shoeEntries                     = (tutorialScript == NULL) ? 0 : tutorialScript->mShoeEntries;
    int             numCards                        = [[[Flow GetInstance] GetLevelDefinitions] GetNumCards];
	
	[super Startup];
	
	[ sRun21UI InterfaceMode:R21UI_Startup ];
	
	// Sync Joker Status from the game to the table.
    [ hsm SyncJokerStatusFromFlow ];
	
	// Deprecated stinger.
	if (!hsm->mRemoveClubs)
	{
		// This message is a no-op now.
		[sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_ClubsRemove];
	}
	
	BOOL bRemoveHearts		= hsm->mRemoveHearts;
	BOOL bRemoveDiamonds	= hsm->mRemoveDiamonds;
	BOOL bRemoveSpades		= hsm->mRemoveSpades;
	BOOL bRemoveClubs		= hsm->mRemoveClubs;
	
	// Rainbow is done with { Ac, #d, #h/d, #s/d }
	if ( bRemoveHearts )
	{
		rainbowSuit[2] = CARDSUIT_Diamonds;
	}
	if ( bRemoveSpades )
	{
		rainbowSuit[3] = CARDSUIT_Diamonds;
	}
	if ( bRemoveDiamonds && bRemoveHearts && bRemoveSpades )
	{
		rainbowSuit[1] = CARDSUIT_Clubs;
		rainbowSuit[2] = CARDSUIT_Clubs;
		rainbowSuit[3] = CARDSUIT_Clubs;
	}
    
    BOOL bNeedRainbow = TRUE;
    
    if (((shoeEntries != NULL) && ([shoeEntries count] != 0)) || (numCards != 0))
        bNeedRainbow = FALSE;
    
    if ( [[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON && hsm->mLevel > 1 )
    {
        hsm->mInterruptRainbow = TRUE;  // We cannot be sure what card # to interrupt the rainbow.
        bNeedRainbow = FALSE;
    }
        
	
	if ( bNeedRainbow )
	{
		[ cardMan RemoveSuitsFromDeckExcept:CardLabel_Ace withSuit:CARDSUIT_Clubs removeSpades:bRemoveSpades removeHearts:bRemoveHearts removeDiamonds:bRemoveDiamonds removeClubs:bRemoveClubs ];

        // We'll need a single card to start each hand, rainbow rules, Ace through Ten only.
        for ( int nRainbowIndex = 0 ; nRainbowIndex < MAX_PLAYER_HANDS ; nRainbowIndex++ )
        {
            do
            {
                bRainbowValid = TRUE;
                
                // Populate the Rank and Suit ( First card is pre-populated as the Ace of Clubs )
                if ( nRainbowIndex != 0 )
                {
                    // Do not select an Ace, Jack, Queen, or King.
                    rainbowRank[nRainbowIndex] = arc4random_uniform(CardLabel_Ten) + 1;
                }
                
                for ( int nCompareIndex = nRainbowIndex - 1 ; nCompareIndex >= 0 ; nCompareIndex-- )
                {
                    if ( rainbowRank[nRainbowIndex] == rainbowRank[nCompareIndex] )
                    {
                        bRainbowValid = FALSE;
                        break;
                    }
                }
                
                
            } while ( !bRainbowValid );
        }

        
        // Move stack the rainbowed cards in reverse order so the Ace of clubs is at the top of the Deck.
        for ( int stackedIndex = (hsm->mNumRunners - 1) ; stackedIndex >= 0 ; stackedIndex-- )
        {
            [ cardMan MoveCardToTopWithRank:rainbowRank[stackedIndex] out_Suit:rainbowSuit[stackedIndex] ];
        }
		
	}
	else if ((shoeEntries != NULL) || (numCards != 0))
    {
        int totalCards = numCards;
        int randomCardsRequired = totalCards - [shoeEntries count];
        
        if (randomCardsRequired > 0)
        {
            int level = [[Flow GetInstance] GetLevel];
            LevelInfo* levelInfo = [[[Flow GetInstance] GetLevelDefinitions] GetLevelInfo:level];
            
            [cardMan ShoeClearWithNumRemaining:randomCardsRequired prioritizeHighCards:levelInfo.PrioritizeHighCards];
        }
        else
        {
            [cardMan ShoeClear];
        }
        
        int numShoeEntries = [shoeEntries count];
        
        for (int i = 0; i < numShoeEntries; i++)
        {
            ShoeEntry* shoeEntry = [shoeEntries objectAtIndex:i];
            
            if (shoeEntry->mCardLabel == CardLabel_Joker)
            {
                hsm->mJokerStatus[CARDSUIT_JOKER_2] = JokerStatus_InDeck;
                [cardMan InsertJokerAtTopOfDeck:TRUE JokerSuit:CARDSUIT_JOKER_2];
            }
            else
            {
                [cardMan InsertCardAtTopWithRank:shoeEntry->mCardLabel suit:shoeEntry->mCardSuit];
            }
        }
    }
    else
    {
        [ cardMan RemoveSuitsFromDeckExcept:CardLabel_Ace withSuit:CARDSUIT_Clubs removeSpades:bRemoveSpades removeHearts:bRemoveHearts removeDiamonds:bRemoveDiamonds removeClubs:bRemoveClubs ];
    }
	
	// Should we add a set of clubs to the bottom of the deck? ( this allows us to have 1.25 decks, 2.25 decks, etc. )
	if (hsm->mAddClubs)
	{
		
		// Add these to the bottom of the deck shuffled.  Dirty hack shuffle, but not major enough to correct.
		CardLabel club[CARDS_IN_STANDARD_SUIT] = {	CardLabel_Num,CardLabel_Num,CardLabel_Num,CardLabel_Num,CardLabel_Num,  /* A-5 */
													CardLabel_Num,CardLabel_Num,CardLabel_Num,CardLabel_Num,                /* 6-9 */
                                                    CardLabel_Num,CardLabel_Num,CardLabel_Num,CardLabel_Num};               /* T-K */
		
		for ( nIndex = 0 ; nIndex < CARDS_IN_STANDARD_SUIT  ; nIndex++ )
		{
			BOOL bRedoRand = FALSE;
			club[nIndex] = arc4random_uniform(CARDS_IN_STANDARD_SUIT);
			
			// Has this card been taken already?
			for ( int matchedIndex = 0; matchedIndex < CARDS_IN_STANDARD_SUIT ; matchedIndex++ )
			{
				// Don't check against ourself
				if ( nIndex == matchedIndex )
					continue;
				
				if ( club[nIndex] == club[matchedIndex] )
				{
					bRedoRand = TRUE;
					break;
				}
			}
			
			// The wrong way of doing it, but I never planned for adding only part of a deck and needed something quick and safe.
			if ( bRedoRand )
			{
				nIndex--;
				continue;
			}
			
		}
	
		for ( nIndex = 0 ; nIndex < CARDS_IN_STANDARD_SUIT ; nIndex++ )
		{
			CardLabel	clubLabel		= club[nIndex];
			int			nLastCardIndex	= [cardMan->mShoe count]; 
			[cardMan InsertCardWithLabel:clubLabel suit:CARDSUIT_Clubs atIndex:nLastCardIndex ];
		}
	}
    
    [ hsm PrintDeckWithHeader:@"Table Setup"];
    
    // If in marathon
    if ( [[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON )
    {
        int nCardsHeld = 0;
        // Move cards from the Holdover to the Deck
        nCardsHeld = [ cardMan HoldoverTransferAll];
        
        // Advance the Dealt Index
        cardMan->mIndexNextCardDealt = nCardsHeld;
        
        // Skip out of preplay if we are not in level 1.
        if ( hsm->mLevel != 1 )
        {
            if(hsm->numHandsActive > 1)
            {
                hsm->inputMode = eInput_Human_Game;
                [ sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_PlayerActive ];
            }
            else
            {
                hsm->inputMode = eInput_CPU_Postplay;
                [ sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_SuddenDeath ];
            }

            
            // Remove the stars from the playfield.
        }
        else
        {
            [sRun21UI MarathonClearStars];
            //[sRun21UI InterfaceMode:R21UI_ConfirmNotAvailable ];
            //[sRun21UI RAS_DeselectAll];
            //[sRun21UI Placer_UpdateStatus];
            //[sRun21UI UpdateJokerHolders];
            
            for ( int i = 0 ; i < hsm->mNumRunners ; i++ )
            {
                // Don't reactivate busted hands.
                if ( false == [ [CardManager GetInstance] HasBustWithHand: hsm->mHandPlayer[i] ] )
                {
                    [sRun21UI PlayerDecisionForHand:hsm->mHandPlayer[i]
                                          handIndex:i
                                     remainingCards:[hsm GetRemainingCards]
                                       JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ]
                                       JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
                }
                else
                {
                    [sRun21UI DeactivateRow:i];
                }
                
            }
            
        }
        
    }
    else
    {
        hsm->mLevel = [[Flow GetInstance] GetLevel];
        hsm->numHandsActive = hsm->mNumRunners;
    }

	// Remove suits from stripped decks, without removing the rainbow.
	int nJokersInDeck	= ( hsm->mJokerStatus[CARDSUIT_JOKER_1] == JokerStatus_InDeck ) + ( hsm->mJokerStatus[CARDSUIT_JOKER_2] == JokerStatus_InDeck );
	int nCardsInDeck	= [cardMan->mShoe count] - cardMan->mIndexNextCardDealt - nJokersInDeck;
    
	
	// Add this to right after the rainbow gets dealt. :: HandStateRun21_CPU_Mode_Switch_RunRainbow
	[ sRun21UI CardsLeftWith:nCardsInDeck ];
	[ sRun21UI JokerStatus:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];	
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateRun21_DealPlacerCard alloc]];
	}

	[super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Run21_TableSetup";
}

-(void)Shutdown
{
	[super Shutdown];
}

@end


// --------------------------------------------------
// HS: Deal Placer Card
// --------------------------------------------------
@implementation HandStateRun21_DealPlacerCard
-(void)Startup
{
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
	CardManager				*cardMan			= [CardManager GetInstance];
    
	[super Startup];
    
    int nTopCard			= [CardManager GetInstance]->mIndexNextCardDealt;
    
    // Interrupt Rainbow is set via TableSetup in a Marathon Game that has passed level 1 ( reshuffle )
    BOOL bNoInterrupt       = ( [[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON && hsm->mLevel > 1 );
    
    if ( !bNoInterrupt && !hsm->mInterruptSkipMidgame && !hsm->mInterruptRainbow && nTopCard == hsm->mNumRunners )
    {
        hsm->mInterruptRainbow = TRUE;
    }

	// If we're in CPU controlled pre-play, the first four cards dealt that are not stripped needs to update the UI.
	if ( hsm->inputMode == eInput_CPU_Preplay && ![ sRun21UI IsInStatus:NUMCARDSLEFT_DealRainbow] )
	{
		// Standard Deal
		if ( hsm->mNumRunners == hsm->mCardsToPrePlay )
		{
            [ sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_DealRainbow ];
		}
	}
    
    [hsm EvaluateXrayCard:(cardMan->mIndexNextCardDealt + 1)];
    
    // Place card in hand.
    hsm->mLastHandDealtTo			= hsm->mNumRunners;
    hsm->mPlacerCard				= [cardMan DealCardWithFaceUp:true out_Hand:hsm->mHandToPlace cardMode:CARDMODE_NORMAL];
    hsm->mHandContainingPlacerCard	= hsm->mHandToPlace;

    hsm->mPlacerCard.cardMode = CARDMODE_NORMAL;

	if ( [hsm->mPlacerCard GetLabel] == CardLabel_Joker )
	{
		hsm->mJokerStatus[ [hsm->mPlacerCard GetSuit] ]	= JokerStatus_InPlacer;
	}
	
	
	[ sRun21UI RAS_DeselectAll ];
	[ sRun21UI InterfaceMode:R21UI_InBetweenStates ];
	
	// Debugging Jokers
	//[ cardMan DealSpecificCardWithFaceUp:true out_Label:CardLabel_Joker out_Suit:(CardSuit)CARDSUIT_JOKER_1 out_Hand:hsm->mHandToPlace ];
	
}
-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
        if ( hsm->mInterruptRainbow )
        {
            [ mStateMachine ReplaceTop:[HandStateRun21_CPU_Mode_Switch_RunRainbow alloc]];   
        }
        else if ( hsm->mInterruptSkipMidgame )
        {
            [ mStateMachine ReplaceTop:[HandStateRun21_CPU_Mode_Switch_SkipMidgame alloc]];   
        }
        else
        {
            [ mStateMachine ReplaceTop:[HandStateRun21_Decision alloc]];
        
        }
		
	}
	
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Run21_DealPlacerCard";
}

-(void)Shutdown
{
	HandStateMachineRun21	*hsm = (HandStateMachineRun21*) mStateMachine;
    
    if ([hsm GetStateMachineState] != STATE_MACHINE_STATE_SHUTTING_DOWN)
    {
        // Are we done being controled by the CPU in the preplay portion of the game?
        if ( hsm->inputMode == eInput_CPU_Preplay )
        {
            if ( [CardManager GetInstance]->mIndexNextCardDealt > hsm->mCardsToPrePlay)
            {
                hsm->inputMode = eInput_Human_Game;
                [ sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_PlayerActive ]; 
            }
        }

        if ( hsm->inputMode == eInput_Human_Game )
        {
            [ sRun21UI InterfaceMode:R21UI_ConfirmNotAvailable ];
            
        }
        else
        {
            [ sRun21UI InterfaceMode:R21UI_InBetweenStates ];
        }
    }

	[super Shutdown];
}

@end

// --------------------------------------------------
// HS: CPU Mode Switch ( Run Rainbow )
// --------------------------------------------------
@implementation HandStateRun21_CPU_Mode_Switch_RunRainbow

-(void)Startup
{
	HandStateMachineRun21 *hsm  = (HandStateMachineRun21*) mStateMachine;
    hsm->mInterruptRainbow      = FALSE;
	
	// New Rule: Jokers get inserted at beginning of game.  Both are shuffled in instead of being at top
	{
		CardManager				*cardMan				= [CardManager GetInstance];
		
		// If we're in Rapid Mode for debugging
#if RAPID_RUN21
		// Remove every card but the last cards in the deck ( the 4 dealt cards, and the # of RAPID_RUN21 cards in the shoe )
		int nBottomCard = [ cardMan->mShoe count ];
		
		while ( nBottomCard-- > hsm->mNumRunners + RAPID_RUN21)
        {
            [ cardMan->mShoe removeObjectAtIndex:nBottomCard ];
        } 
		
		hsm->mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_NotInDeck;
		hsm->mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_NotInDeck;
#else
		
		// Joker #2 appears in the top 1/2 of the deck, except the very top.
		if (hsm->mNumJokers >= 2)
		{
			[ cardMan InsertJokerAtTopOfDeck:FALSE	JokerSuit:CARDSUIT_JOKER_2];
			hsm->mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_InDeck;
		}
	 
		// Joker #1 is shuffled in, instead of being put on top like bust events.
		if (hsm->mNumJokers >= 1)
		{
			[ cardMan InsertJokerAtTopOfDeck:FALSE	JokerSuit:CARDSUIT_JOKER_1];
			hsm->mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_InDeck;
		}
        
        [ hsm PrintDeckWithHeader:@"After Joker Insert"];
#endif
	}
    
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateRun21_Decision alloc]];
	}
    
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Run21_CPU_Mode_Switch_RunRainbow";
}
-(void)Shutdown
{
	[super Shutdown];
}

@end

// --------------------------------------------------
// HS: CPU Mode Switch ( Skip Midgame )
// --------------------------------------------------
@implementation HandStateRun21_CPU_Mode_Switch_SkipMidgame

-(void)Startup
{
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateRun21_Decision alloc]];
	}
    
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Run21_CPU_Mode_Switch_SkipMidgame";
}
-(void)Shutdown
{
	[super Shutdown];
}

@end

// --------------------------------------------------
// HS: CPU Mode Switch ( Resume Midgame )
// --------------------------------------------------
@implementation HandStateRun21_CPU_Mode_Switch_ResueMidgame : HandStateRun21

-(void)Startup
{
    [super Startup];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
    if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateRun21_Decision alloc]];
	}
    
    [super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_ResumeMidgame";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Decision
// --------------------------------------------------
@implementation HandStateRun21_Decision
-(void)Startup
{
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
	
	[super Startup];

	[sRun21UI PlayerDecisionForHand:hsm->mHandPlayer[hsm->mLastHandDealtTo] handIndex:hsm->mLastHandDealtTo remainingCards:[hsm GetRemainingCards] JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
    
    if (hsm->inputMode == eInput_Human_Game)
    {
        if ((hsm->mTimerState == TIMERSTATE_WAITING) && (hsm->mTimeRemaining > 0))
        {
            hsm->mTimerState = TIMERSTATE_RUNNING;
        }
    }
}
 
-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;

	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
        if ( hsm->inputMode == eInput_CPU_Preplay )
		{
			hsm->mLastHandDealtTo		 = ( [CardManager GetInstance]->mIndexNextCardDealt - 1) % hsm->mNumRunners;	// Since this points at the next card's index.
			[ mStateMachine ReplaceTop:[HandStatePlacementTest alloc]];
		}
		else if ( hsm->inputMode == eInput_CPU_Postplay )
		{
			hsm->mLastHandDealtTo		= hsm->mAutoPlayLastHand;
			[ mStateMachine ReplaceTop:[HandStatePlacementTest alloc]];
		}
	}
	
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_Decision";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Hand Outcome - Bust
// --------------------------------------------------
@implementation HandStateRun21_HandOutcome_Bust
-(void)Startup
{
	Card					*pCard;
	HandStateMachineRun21	*hsm					= (HandStateMachineRun21*) mStateMachine;
	CardManager				*cardMan				= [CardManager GetInstance];
	
	[super Startup];
	
	// Do we need to insert any jokers into the deck?
	[ cardMan RemoveJokersFromDeck ];
    
    int numCardsInHand = [hsm->mHandToPlace count];
    
    for (int i = 0; i < numCardsInHand; i++)
    {
        Card* curCard = [hsm->mHandToPlace objectAtIndex:i];
        
        if ([curCard GetLabel] == CardLabel_Joker)
        {
            [hsm->mHandToPlace removeObjectAtIndex:i];
        }
    }

	// Joker #2 appears in the top 1/2 of the deck, excet the very top.
	if (hsm->mNumJokers >= 2 )
	{
		[ cardMan InsertJokerAtTopOfDeck:FALSE	JokerSuit:CARDSUIT_JOKER_2];
		hsm->mJokerStatus[CARDSUIT_JOKER_2]	= JokerStatus_InDeck;
	}
	
	// Joker #1 always appears at the top of the deck.
	if (hsm->mNumJokers >= 1)
	{
        [ cardMan InsertJokerAtTopOfDeck:TRUE	JokerSuit:CARDSUIT_JOKER_1];
        hsm->mJokerStatus[CARDSUIT_JOKER_1]	= JokerStatus_InDeck;
	}
	
	// Loop through the active hand, and flip over all the cards since it busted.
	for ( int nCard = 0; nCard < [ [self GetActiveHand] count ] ; nCard++ )
	{
		pCard = [ [self GetActiveHand] objectAtIndex:nCard ];
		[ pCard SetFaceUp:FALSE ];
	}
	
	// Deactivate the corresponding button
	[sRun21UI DeactivateRow:hsm->mLastHandDealtTo];
	
	// Play a Bust Stinger
	[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_BUST withData:NULL];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateEvaluate_Game				alloc]];
	}
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_HandOutcome_Bust";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Hand Outcome - 21
// --------------------------------------------------
@implementation HandStateRun21_HandOutcome_21
-(void)Startup
{
	[super Startup];
	[ [self GetActiveHand] removeAllObjects];
	
	// Play a 21 Stinger
	[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_HAND21 withData:NULL];
	
	// Rescore the hand.
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    [sRun21UI PlayerDecisionForHand:hsm->mHandPlayer[hsm->mLastHandDealtTo] handIndex:hsm->mLastHandDealtTo remainingCards:[hsm GetRemainingCards] JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
	[ sRun21UI RAS_DeselectAll ];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateEvaluate_Game				alloc]];
	}
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_HandOutcome_21";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Hand Outcome - Charlie
// --------------------------------------------------
@implementation HandStateRun21_HandOutcome_Charlie
-(void)Startup
{
	[super Startup];
	[ [self GetActiveHand] removeAllObjects];
	
	// Play a Charlie Stinger
	[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_CHARLIE withData:NULL];
	
	// Rescore the hand.
	HandStateMachineRun21	*hsm = (HandStateMachineRun21*) mStateMachine;
    [sRun21UI PlayerDecisionForHand:hsm->mHandPlayer[hsm->mLastHandDealtTo] handIndex:hsm->mLastHandDealtTo remainingCards:[hsm GetRemainingCards] JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
	[ sRun21UI RAS_DeselectAll ];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateEvaluate_Game alloc]];
	}
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_HandOutcome_Charlie";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Autoplay
// --------------------------------------------------
@implementation HandStateRun21_AutoPlay
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
	return @"Run21_AutoPlay";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Lose
// --------------------------------------------------
@implementation HandStateRun21_Lose
-(void)Startup
{
	[super Startup];
    
    [((HandStateMachineRun21*)mStateMachine) GameOver];
    	
    [ sRun21UI InterfaceMode:R21UI_PoweredOff ];

    [GetGlobalMessageChannel() SendEvent:EVENT_CONCLUSION_BANKRUPT withData:NULL];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES )
	{
		HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
		[ hsm WipeTable ];
		
		// Play the Bankrupt Stinger and reset the current state.
		
		// Set the ATM Restore Point
		
		
		hsm->bWonGame		= FALSE;
		hsm->bHiScore		= FALSE;
		hsm->numHandsActive	= 0;
		
		[ mStateMachine ReplaceTop:[HandStateGameOver alloc]];
	}
	
	
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_Lose";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Win
// --------------------------------------------------
@implementation HandStateRun21_Win
-(void)Startup
{
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    
    [hsm GameOver];
    
    startAnimationTime = 2.0;
	
	// Play the Broke the Bank stinger
	[ sRun21UI InterfaceMode:R21UI_PoweredOff ];
    
	[GetGlobalMessageChannel() SendEvent:EVENT_CONCLUSION_BROKETHEBANK withData:NULL];
	[sRun21UI PlayerDecisionForHand:NULL handIndex:hsm->mNumRunners remainingCards:0 JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ]];

    Flow *gameFlow      = [ Flow GetInstance ];
    
    // What was our previous score for this level?
    
    int level = [[Flow GetInstance] GetLevel];
    
    hsm->previousScore  = [[SaveSystem GetInstance] GetStarsForLevel:level];
    hsm->numHandsActive = 0;
    hsm->bWonGame		= TRUE;
    // What was our score for this level?
    for ( int nRow = 0 ; nRow < hsm->mNumRunners ; nRow++ )
    {
        // Don't check for a bust since the cards are face down now and don't count towards the score.  Check for 21 or less
        if ( [ CardManager FinalScoreWithHand:hsm->mHandPlayer[nRow] ] <= 21  )
        {
            hsm->numHandsActive++;
        }
    }
    
    hsm->bHiScore		= hsm->numHandsActive > hsm->previousScore;
    
    if ([gameFlow GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON)
    {
        [[RegenerationManager GetInstance] SetNumLives_LevelWin];
        
        // If check probably isn't needed anymore, SetScore won't hardoverride your score by default.
        if ( hsm->bHiScore )
        {
            [[SaveSystem GetInstance] SetStarsForLevel:level withStars:hsm->numHandsActive];	// numHandsActive is our score.
        }
    }
    
    [hsm EndGameTable];
    
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRun21*  hsm = (HandStateMachineRun21*) mStateMachine;
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];

    float waitTime = 0.0;
    
    waitTime = (hsm->endHandsScored == 0) ? 0.0 : 0.7;
    
	if (mStateTime > waitTime)    // Time to play a sound and score a row.
	{
		// Set the score.
        
        if ( hsm->endHandsScored >= numRunners )
        {
            // If not in marathon mode.
            if ([[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON)
            {
                int playerLevelAtStart = 0, playerLevelAtEnd = 0;
                float dummyPercent;
                
                // Add to the player's score and determine whether they have gone up a level
                [[ExperienceManager GetInstance] GetPlayerWithLevel:&playerLevelAtStart WithPercent:&dummyPercent];
                [[ExperienceManager GetInstance] GetPlayerWithLevel:&playerLevelAtEnd WithPercent:&dummyPercent];
                
                hsm->bLeveledUp = playerLevelAtEnd > playerLevelAtStart;

                [ hsm WipeTable ];
            }
            else
            {
                [sRun21UI MarathonClearStars];
                //[sRun21UI InterfaceMode:R21UI_ConfirmNotAvailable ];
                //[sRun21UI RAS_DeselectAll];
                //[sRun21UI Placer_UpdateStatus];
                //[sRun21UI UpdateJokerHolders];
                
                [sRun21UI ResetGameMarathon];
                
                for ( int i = 0 ; i < MAX_PLAYER_HANDS ; i++ )
                {
                    if ( false == [ [CardManager GetInstance] HasBustWithHand: hsm->mHandPlayer[i] ] )
                    {
                        [sRun21UI PlayerDecisionForHand:hsm->mHandPlayer[i]
                                              handIndex:i
                                         remainingCards:[hsm GetRemainingCards]
                                           JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ]
                                           JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
                    }
                    else
                    {
                        [sRun21UI DeactivateRow:i];
                    }
                }  
            }
            [ mStateMachine ReplaceTop:[HandStateGameOver alloc]];
            
        }
        else
        {
            mStateTime = 0.0;
            
            [sRun21UI EndGameClearRow:hsm->endHandsScored];
        }
        
        hsm->endHandsScored++;
		
	}
	
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"Run21_Win";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Placement Test
// --------------------------------------------------
@implementation HandStatePlacementTest
-(void)Startup
{
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
	BOOL					bRescorePrevHand	= FALSE;
	PlayerHand				*fromHand;
    //int xRayOffset = hsm.xrayActive ? 1 : 0;
	
	[super Startup];
    
    int count = [hsm->mHandToPlace count];
    
    BOOL cardInPlacer = FALSE;
    
    for (int i = 0; i < count; i++)
    {
        Card* curCard = [hsm->mHandToPlace objectAtIndex:i];
        
        if (curCard == hsm->mPlacerCard)
        {
            cardInPlacer = TRUE;
        }
    }
	
	// Is the card still in the placer?
	if ( cardInPlacer )
	{
		fromHand = hsm->mHandToPlace;
	}
	else 
	{
		// If not, save a reference to the old hand
		fromHand = hsm->mHandContainingPlacerCard;
		
		// And make sure to rescore it since it will be losing a card.
		bRescorePrevHand = TRUE;
	}
	
	// Move the card
	[ [self GetActiveHand] splitCard:hsm->mPlacerCard fromHand:fromHand ];
	
	// Rescore the old hand the placer card was in if necesseary
	if ( bRescorePrevHand )
	{
		// Rescore the old hand since after the split this hand has lost a card
		[sRun21UI PlayerDecisionForHand:fromHand
							  handIndex:fromHand->mHandIndex 
						 remainingCards:[hsm GetRemainingCards]
						   JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] 
						   JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
	}

	// Score the new hand where the placer card lies
	[sRun21UI PlayerDecisionForHand:[self GetActiveHand]
						  handIndex:[self GetActiveHand]->mHandIndex
					 remainingCards:[hsm GetRemainingCards]
					   JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] 
					   JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
	
	// Update the hand where the placer card is present.
	hsm->mHandContainingPlacerCard = [ self GetActiveHand ];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
		
        if ( hsm->inputMode == eInput_Human_Game )
		{
			[ sRun21UI InterfaceMode:R21UI_ConfirmAvailable ];
			[ mStateMachine ReplaceTop:[HandStateRun21_Decision alloc]];
		}
		else 
		{
			[ sRun21UI InterfaceMode:R21UI_InBetweenStates ];
			[ mStateMachine ReplaceTop:[HandStatePlacementConfirm alloc]];
		}
	}
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_PlacementTest";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Placement Confirm
// --------------------------------------------------
@implementation HandStatePlacementConfirm
-(void)Startup
{
	HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
	[super Startup];
	
	if ( [hsm->mPlacerCard GetLabel] == CardLabel_Joker )
	{
		hsm->mJokerStatus[ [hsm->mPlacerCard GetSuit] ]	= JokerStatus_NotInDeck;
	}

	hsm->mPlacerCard = NULL;
	hsm->mHandContainingPlacerCard = NULL;
	[ sRun21UI InterfaceMode:R21UI_InBetweenStates ];
	// [ sRun21UI RAS_DeselectAll ];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		[ mStateMachine ReplaceTop:[HandStateEvaluate_Hand alloc]];
	}
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_PlacementConfirm";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Evaluate - Hand
// --------------------------------------------------

@implementation HandStateEvaluate_Hand
-(void)Startup
{
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	[super Update:inTimeStep]; 
	
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		// Check if there is a joker in the hand, causing an automatic 21 (topmost priority)
		if		( [ [CardManager GetInstance] HasJokerWithHand:		[self GetActiveHand]	] )
		{
			[ mStateMachine ReplaceTop:[HandStateRun21_HandOutcome_21		alloc]];
		}
		// Check for a bust ( has priority sans jokers, a busted hand cannot win )
		else if		( [ [CardManager GetInstance] HasBustWithHand:		[self GetActiveHand]	] )
		{
			[ mStateMachine ReplaceTop:[HandStateRun21_HandOutcome_Bust		alloc]];
		}
		// Check for a 21 ( has priority over a charlie )
		else if ( [ [CardManager GetInstance] Has21WithHand:		[self GetActiveHand]	] )
		{
			[ mStateMachine ReplaceTop:[HandStateRun21_HandOutcome_21		alloc]];
		}
		// Check for a charlie
		else if ( [ [CardManager GetInstance] HasCharlieWithHand:	[self GetActiveHand]	] )
		{
			[ mStateMachine ReplaceTop:[HandStateRun21_HandOutcome_Charlie	alloc]];
		}
		// The hand states have not changed.
		else
		{
			[ mStateMachine ReplaceTop:[HandStateEvaluate_Game				alloc]];
		}
	}
}
-(NSString*)GetId
{
	return @"Run21_Evaluate_Hand";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: Evaluate - Game
// --------------------------------------------------

@implementation HandStateEvaluate_Game
-(void)Startup
{
	[ sRun21UI InterfaceMode:R21UI_InBetweenStates ];
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	if ( mStateTime > TIME_BETWEEN_STATES_FAST )
	{
		HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
		CardManager				*cardMan			= [CardManager GetInstance];
        BOOL                    bGameEnd            = FALSE;
		
		// Check to see if we do not have any hands left to place cards in
		hsm->numHandsActive = 0;
		for ( int nRow = 0 ; nRow < hsm->mNumRunners ; nRow++ )
		{
			// Don't check for a bust since the cards are face down now and don't count towards the score.  Check for 21 or less
			if ( [ CardManager FinalScoreWithHand:hsm->mHandPlayer[nRow] ] <= 21  )
			{
				hsm->numHandsActive++;
				hsm->mAutoPlayLastHand = nRow;
			}
		}
		
		// Are we down to our last hand?
		if ( 1 == hsm->numHandsActive )
		{
			hsm->inputMode	= eInput_CPU_Postplay;
			[ sRun21UI UpdateNumCardsStatus:NUMCARDSLEFT_SuddenDeath ]; 
			// TODO: Stinger / UI change to holder.
		}
		
		// Final evaulation:
		// Are we out of rows? ( Lose )
		if ( 0 == hsm->numHandsActive )
		{
			[ mStateMachine ReplaceTop:[HandStateRun21_Lose alloc]];
            bGameEnd = TRUE;
		}
		// Are we out of cards? ( Win )
		else if ([cardMan->mShoe count] - cardMan->mIndexNextCardDealt <= 0 )
		{
#if RAPID_LOSE
            [ mStateMachine ReplaceTop:[HandStateRun21_Lose alloc]];
#else
            [ mStateMachine ReplaceTop:[HandStateRun21_Win alloc]];
#endif
            bGameEnd = TRUE;
            
		}
		else 
		{
			// If not, continue the game, go back to the reveal card state. (TODO: Reword )
			[ mStateMachine ReplaceTop:[HandStateRun21_DealPlacerCard alloc]];
		}
	}
    
	[super Update:inTimeStep];
}
-(NSString*)GetId
{
	return @"Run21_Evaluate_Game";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

// --------------------------------------------------
// HS: End Stars
// --------------------------------------------------

@implementation HandStateEndStars: HandStateRun21

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
    return @"Run21_HandStateEndStars";
}
-(void)Shutdown
{
    [super Shutdown];
}
@end

// --------------------------------------------------
// HS: GameOver
// --------------------------------------------------
@implementation HandStateGameOver
-(void)FlurryEndSession
{
    HandStateMachineRun21   *hsm    = (HandStateMachineRun21*) mStateMachine;
    
    FEvent gameEventLabel           = Flurry_Run21_Play;
    
    if ( [[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON )
        gameEventLabel = Flurry_Marathon_Play;
        
    [hsm->mGameRun21 FlurryTimedEvent:gameEventLabel withStart:FALSE];
#if NEONGAM_PHP_ENABLED
    FEvent tabletEventLabel         = Flurry_Tablet_Impression;
    AdvertisingManager      *adMan  = [AdvertisingManager GetInstance];
    if ( adMan )
    {
        [ adMan FlurryTabletEvent:tabletEventLabel withStart:FALSE];
        
        [ adMan NeonPHP_Call:ENeonJSONType_4_End async:TRUE];
    }
#endif
    
}
-(void)Startup
{
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    Message msg;
    
    msg.mId = EVENT_RUN21_SCORING_COMPLETE;
    msg.mData = NULL;
        
    [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];

    if ([[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON)
    {
        [ self FlurryEndSession ];
        
        [ sRun21UI EndGameWithWin: hsm->bWonGame WithHiScore:hsm->bHiScore WithStars:hsm->numHandsActive];
    
        // Play the hi-score Stinger if we received a hi-score
        if ( hsm->bHiScore )
            [[GameStateMgr GetInstance] SendEvent:EVENT_GAME_HISCORE withData:NULL];
        else if ( hsm->numHandsActive == hsm->mNumRunners )
            [[GameStateMgr GetInstance] SendEvent:EVENT_GAME_PERFECT withData:NULL];
        else
            [[GameStateMgr GetInstance] SendEvent:EVENT_GAME_LOSE withData:NULL];
        
        if ( hsm->bWonGame )
        {
            if (![[Flow GetInstance] UnlockNextLevel])
            {
                [[Flow GetInstance] PromptForUserRatingTally];
            }
        }
    }
    else
    {
        if(hsm->numHandsActive == 0)
        {
            [ self FlurryEndSession ];
                        
            [sRun21UI EndGameWithWin:FALSE WithHiScore:hsm->bHiScore WithStars:0];
            hsm->bWonGame = TRUE;
            
            [hsm WipeTable];

            if(hsm->bHiScore)
            {
                [[GameStateMgr GetInstance] SendEvent:EVENT_GAME_HISCORE withData:NULL];
            }
            else
            {
                [[GameStateMgr GetInstance] SendEvent:EVENT_GAME_LOSE withData:NULL];
            }
        }
    }
	
	[super Startup];
}


-(void)reportAchievements
{
#if 0
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    Flow *gameFlow      = [ Flow GetInstance ];
#endif
    NSAssert(FALSE, @"No longer doing achievements");
#if 0
    //we need a minus 1 here because we already advanced the flow when the player beat the level
    StarLevel curStar = [ gameFlow GetRoomStarForLevel:[gameFlow GetProgress] -1];
    float roomScore = [ gameFlow GetScoreForRoom:curStar ];
    
    if ( curStar == STAR_GOLD )
    {
        if ( roomScore == 10 )
            roomScore = 100;
        else
            roomScore *= 10; // Incomplete, 10 stars to beat a non-gold room  * 10 to get ~ 100%
    }
    else
    {
        if ( roomScore == 12 )
            roomScore = 100;
        else
            roomScore *= 8.33; // Incomplete, 12 stars to beat a non-gold room  * 8.33 to get ~ 100%
    }
    
    
    NEON_ACHIEVEMENT curAchievement;
    switch ( curStar )
    {
        case STAR_BRONZE:
            curAchievement = ACHIEVEMENT_RUN21_BRONZE;
            break;
            
        case STAR_SILVER:
            curAchievement = ACHIEVEMENT_RUN21_SILVER;
            break;
            
        case STAR_GOLD:
            curAchievement = ACHIEVEMENT_RUN21_GOLD;
            break;
            
        case STAR_SHOOTING:
        default:
            curAchievement = ACHIEVEMENT_RUN21_DIAMOND;
            break;
            
    }
    
    AchievementManager* achievementMan = [AchievementManager GetInstance];
    // give Achievements for both room progress and Level Progress
    if(hsm->bHiScore)
    {
        [achievementMan ReportProgress:roomScore towardsAchievement:curAchievement];
        if (! [gameFlow InTutorialMode])
        {
            int currentLevel = [gameFlow GetDifficultyLevel] - Difficulty_Run21_Level1 + 1;
            [achievementMan ReportStars:hsm->numHandsActive forLevel:currentLevel];
        }
    }
#endif
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    [sRun21UI SetEndGamePowerupStrings];
    
	if ( mStateTime > TIME_BETWEEN_STATES_SLOW )
	{
		if ([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON && hsm->numHandsActive > 0)
        {
            HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
            CardManager             *cardMan            = [CardManager GetInstance];
            [ cardMan HoldoverClear ];
            
#if START_CARD_DEBUG_LEVEL
            NSLog(@"Printing Old Shoe contents");
            NSLog(@"======================");

            for ( int nIndex = 0 ; nIndex < [cardMan->mShoe count] ; nIndex++ )
            {
                Card* nCard = [ cardMan->mShoe objectAtIndex:nIndex ];
                char myStr[16];
                
                snprintf(myStr, 16, "%s",[ nCard GetCardString ] );
                
                NSLog(@"%d) %s", nIndex, myStr);
            }
            NSLog(@"======================");
#endif           
            // Move all cards from active hands out of the deck to the holdover.
            for ( int i = 0 ; i < hsm->mNumRunners ; i++ )
            {
                PlayerHand  *iHand = hsm->mHandPlayer[i];
                
                for ( int j = 0; j < [iHand count]; j++ )
                {
                    Card *pCard = [ iHand objectAtIndex:j ];
                    
                    [ cardMan HoldoverTransferFromShoe:pCard];
                }
            }
 
#if START_CARD_DEBUG_LEVEL
            NSLog(@"Printing Holdover contents");
            NSLog(@"======================");
            for ( int nIndex = 0 ; nIndex < [cardMan->mHoldover count] ; nIndex++ )
            {
                Card* nCard = [ cardMan->mHoldover objectAtIndex:nIndex ];
                char myStr[16];
                
                snprintf(myStr, 16, "%s",[ nCard GetCardString ] );
                
                NSLog(@"%d) %s", nIndex, myStr);
            }
            NSLog(@"======================");
#endif            
            // Clear the shoe.
            [ cardMan ShoeClear];
         
            // Reshuffle deck, and continue game on next difficulty level. ( TODO )
            [ hsm ShuffleMarathonLevelUp];
            
            [ hsm SyncJokerStatusFromFlow ];
            [ sRun21UI JokerStatus:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ] JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
            
            // Temp for now.
            [ mStateMachine ReplaceTop:[HandStateRun21_Init alloc]];  //  HandStateRun21_DealPlacerCard
        }
	}
	[super Update:inTimeStep];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];

    if ([title isEqualToString:NSLocalizedString(@"LS_OK",NULL)])
    {
        [[GameStateMgr GetInstance] Push:[IAPStore alloc]];
    }
}

-(NSString*)GetId
{
	return @"HandStateGameOver";
}
-(void)Shutdown
{
	[super Shutdown];
}
@end

@implementation Run21TutorialSummary

-(void)Startup
{
	// Eventually bring up a new UI
	[[GameStateMgr GetInstance] SendEvent:EVENT_TUTORIAL_COMPLETED withData:NULL];
	[super Startup];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
	[super Update:inTimeStep];
}

-(NSString*)GetId
{
	return @"TutorialSummary";
}

@end

@implementation  HandStateRun21_Tornado
-(void)Startup
{
    
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;
    CardManager             *cardMan            = [CardManager GetInstance];
    int remainingCards = [hsm GetRemainingCards];
    int xRayOffset = hsm.xrayActive ? 1 : 0;
     
    [sRun21UI InterfaceMode:R21UI_InBetweenStates];
    hsm->powerUpUsed_Tornados++;
    
    
    if (hsm->mTimeRemaining > 0)
    {
        hsm->mTimeRemaining += TORNADO_TIME_BONUS;
    }

    //Do the Placer separately because this is where we are placing the rest of the cards for the animation
    if([hsm->mHandToPlace count] > xRayOffset)
    {
        Card *pCard = [ hsm->mHandToPlace objectAtIndex:0 ];

        int range = arc4random_uniform([cardMan->mShoe count] - cardMan->mIndexNextCardDealt );
        int index = cardMan->mIndexNextCardDealt + range;
        [cardMan InsertCardWithLabel:pCard->mLabel suit:pCard->mSuit atIndex: index];
    }

    for ( int i = 0; i < hsm->mNumRunners ; i++ )
    {
        PlayerHand  *iHand = hsm->mHandPlayer[i];
        // if this hand is bust, then we don't want to shuffle the cards back into the deck
        if ( [cardMan HasBustWithHand: hsm->mHandPlayer[i]]  && hsm->mHandContainingPlacerCard != iHand)
        {
            continue;
        }
        //otherwise go through and reshuffle the cards
        while ( [iHand count] > 0 )
        {
            Card *pCard = [ iHand objectAtIndex:0 ];
            // get a number from 1 to number of cards left, because we do not want to put the card on the top of the deck
            int range = arc4random_uniform([cardMan->mShoe count] - cardMan->mIndexNextCardDealt);
            int index = cardMan->mIndexNextCardDealt + range;
                            
            [cardMan InsertCardWithLabel:pCard->mLabel suit:pCard->mSuit atIndex: index];
            //put the card back into the placer, so it looks like it is being reshuffled
            [hsm->mHandToPlace splitCard:pCard fromHand:iHand];

        }
        
        // we need to update the UI as the score for this hand has been reset to zero
        [sRun21UI PlayerDecisionForHand:iHand
                              handIndex:iHand->mHandIndex
                         remainingCards:remainingCards
                           JokerStatus1:hsm->mJokerStatus[ CARDSUIT_JOKER_1 ]
                           JokerStatus2:hsm->mJokerStatus[ CARDSUIT_JOKER_2 ] ];
    }

    
    [super Startup];

}

-(void)Update:(CFTimeInterval)inTimeStep
{
    HandStateMachineRun21	*hsm				= (HandStateMachineRun21*) mStateMachine;

    if(mStateTime > TIME_BETWEEN_STATES+.3)
    {
        [hsm->mHandToPlace removeAllObjects];
        [sRun21UI InterfaceMode:R21UI_ConfirmNotAvailable];
        [mStateMachine ReplaceTop:[HandStateRun21_DealPlacerCard alloc]];
    }
    
    [super Update:inTimeStep];
}

-(NSString*)GetId
{
 return @"HandStateRun21_Tornado";
}

-(void)Shutdown
{
    [super Shutdown];

}

@end
