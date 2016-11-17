//
//  Flow.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Flow.h"

#import "GameCutscene.h"
#import "GameRun21.h"
#import "GameTripleSwitch.h"
#import "GameTwentyOneSquared.h"

#import "FMVState.h"
#import "GameStateMgr.h"
#import "MainMenu.h"
#import "SaveSystem.h"
#import "CardManager.h"
#import "TutorialScript.h"
#import "LevelDefinitions.h"

#import "FacebookLoginMenu.h"
#import "SplitTestingSystem.h"

FlowStateParams	sFlowStateParams[] =    { {   @"MainMenu", TRUE  } };
														
static Flow* sInstance = NULL;

@implementation Flow

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Trying to create Flow when one already exists.");
    
    sInstance = [Flow alloc];
    [sInstance Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"No Flow exists.");
    
    [sInstance release];
}

+(Flow*)GetInstance
{
    return sInstance;
}

-(void)Init
{
    mPrevLevel = LEVEL_INDEX_INVALID;
    mLevel = LEVEL_INDEX_INVALID;
    
    mGameModeType = GAMEMODE_TYPE_INVALID;
    mPrevGameModeType = GAMEMODE_TYPE_INVALID;

    mRequestedFacebookLogin = FALSE;
    
    mLevelDefinitions = [(LevelDefinitions*)[LevelDefinitions alloc] Init];
}

-(void)dealloc
{
    [super dealloc];
    
    [mLevelDefinitions release];
}

-(GameModeType)GetGameMode
{
    return mGameModeType;
}

-(int)GetLevel
{
    return mLevel;
}

-(BOOL)IsInRun21
{
    return (mGameModeType == GAMEMODE_TYPE_RUN21 || mGameModeType == GAMEMODE_TYPE_RUN21_MARATHON);
}
-(BOOL)IsInRainbow
{
    NSAssert(FALSE, @"This is deprecated");
    return FALSE;
}

-(TableCompanionPlacement*)GetCompanionLayout
{
	return &mCompanionLayout;
}

-(void)AdvanceLevel
{
    [self EnterGameMode:mGameModeType level:(mLevel + 1)];
}

-(void)RestartLevel
{
    [self EnterGameMode:mGameModeType level:mLevel];
}

-(void)AppRate
{
    NSString* RateAppURL = NULL;
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        RateAppURL = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%d", NEON_APP_ID];
    }
    else
    {
        RateAppURL = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%d", NEON_APP_ID];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:RateAppURL]];
    
    [[SaveSystem GetInstance] SetRatedGame:1];
    [[SaveSystem GetInstance] SetNumWinsSinceRatePrompt:0];
    
    int numXrays = [[SaveSystem GetInstance] GetNumXrays];
    int numTornadoes = [[SaveSystem GetInstance] GetNumTornadoes];
    
    [[SaveSystem GetInstance] SetNumXrays:[NSNumber numberWithInt:(numXrays + 2)]];
    [[SaveSystem GetInstance] SetNumTornadoes:[NSNumber numberWithInt:(numTornadoes + 2)]];
    
    LevelSelectRoom maxRoomUnlocked = [[SaveSystem GetInstance] GetMaxRoomUnlocked];
    
    if (maxRoomUnlocked < LEVELSELECT_ROOM_LAST)
    {
        [[SaveSystem GetInstance] SetMaxRoomUnlocked:[NSNumber numberWithInt:(maxRoomUnlocked + 1)]];
    }
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_RATED_GAME withData:NULL];
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NULL message:NSLocalizedString(@"LS_RatingAwardMessage", NULL) delegate:NULL cancelButtonTitle:NSLocalizedString(@"LS_OK", NULL) otherButtonTitles:NULL];
    [alertView show];
    [alertView release];
}

-(void)AppGift
{
    NSString *GiftAppURL    = [NSString stringWithFormat:@"itms-appss://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/giftSongsWizard?gift=1&salableAdamId=%d&productType=C&pricingParameter=STDQ&mt=8&ign-mscache=1", NEON_APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GiftAppURL]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:NSLocalizedString(@"LS_Prompt_RateApp_Cancel", NULL)])
    {
        [[NeonMetrics GetInstance] logEvent:@"Rate App Declined" withParameters:NULL];
    }
    else if([title isEqualToString:NSLocalizedString(@"LS_Prompt_RateApp_OK", NULL)])
    {
        [[NeonMetrics GetInstance] logEvent:@"Rate App Accepted" withParameters:NULL];
        [self AppRate];
    }
    else if([title isEqualToString:NSLocalizedString(@"LS_Prompt_RateApp_Never", NULL)])
    {
        [[NeonMetrics GetInstance] logEvent:@"Rate App Never" withParameters:NULL];
        [[SaveSystem GetInstance] SetRatedGame:1];
    }
    else
    {
        NSLog(@"Unknown response from Rating Prompt");
    }
}

-(void)PromptForUserRatingTally
{
    if ([[SaveSystem GetInstance] GetRatedGame] == 1)
        return;
    
    if ([[SaveSystem GetInstance] GetMaxLevelStarted] < RUN21_LEVEL_7)
    {
        return;
    }
    
    // Increase our Sessions Count
    int nSessionsWonWithoutRating = 1 + [[SaveSystem GetInstance] GetNumWinsSinceRatePrompt];

    // Ask user to rate the game.
    if ( nSessionsWonWithoutRating >= NUM_SESSIONS_WON_BEFORE_RATING_PROMPT )
    {
        nSessionsWonWithoutRating = 0;
        
        // Prompt user here.  LS_Prompt_RateApp_Message
        [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LS_Prompt_RateApp_Title", NULL)
                                                        message:NULL
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"LS_Prompt_RateApp_Never", NULL)
                                              otherButtonTitles:NSLocalizedString(@"LS_Prompt_RateApp_OK", NULL),
                                                                NSLocalizedString(@"LS_Prompt_RateApp_Cancel", NULL),
                              nil];
        
        [[NeonMetrics GetInstance] logEvent:@"Rate App Presented" withParameters:NULL];
        
        [alert show];
    }

    [[SaveSystem GetInstance] SetNumWinsSinceRatePrompt:nSessionsWonWithoutRating];
}

-(void)CycleOutCompanionsWithDealer:(CompanionID)dealer Seat1:(CompanionID)companion1 Seat2:(CompanionID)companion2 
{
	mCompanionLayout.seatPlayer = CompID_Polly;
	mCompanionLayout.seatDealer = dealer;
	
	// If both seats are requested, fill them with the new companions.
	if ( CompID_MAX != companion2 && CompID_MAX != companion1 )
	{
		mCompanionLayout.seatLeft	= companion1;
		mCompanionLayout.seatRight	= companion2; 
	}
	// If neither seats are requested, do not change the companion layouts.
	else if ( CompID_MAX == companion2 && CompID_MAX == companion1 )
	{
		// no-op
	}
	// Otherwise, only seat 1 is requested, seat the new companion
	else 
	{
		// Are they already seated in the left space?
		if ( mCompanionLayout.seatLeft == companion1 )
		{
			mCompanionLayout.seatRight = companion1;
		}
		else 
		{
			mCompanionLayout.seatLeft = companion1;
		}
	}
}

-(void)EnterGameMode:(GameModeType)inGameModeType level:(int)inLevel
{
    mPrevLevel = mLevel;
    mPrevGameModeType = mGameModeType;
    
    mLevel = inLevel;
    mGameModeType = inGameModeType;
    
    [self SetupGame];
}

-(void)ExitGameMode
{
    [[GameStateMgr GetInstance] ResumeProcessing];

    int numPops = 1;
    
    GameState* curState = (GameState*)[[GameStateMgr GetInstance] GetActiveStateAfterOperations];
    
    while(true)
    {
        mPrevLevel = [curState GetLevel];
        mPrevGameModeType = [curState GetGameModeType];
        
        GameState* parentState = (GameState*)curState->mParentState;
        
        if (parentState == NULL)
        {
            mLevel = LEVEL_INDEX_INVALID;
            mGameModeType = GAMEMODE_TYPE_INVALID;
            
            break;
        }
        
        mLevel = [parentState GetLevel];
        mGameModeType = [parentState GetGameModeType];
        
        if (mGameModeType != mPrevGameModeType)
        {
            break;
        }

        curState = parentState;
        
        numPops++;
    }

    for (int i = 0; i < (numPops - 1); i++)
    {
        [[GameStateMgr GetInstance] PopTruncated:TRUE];
    }
    
    [[GameStateMgr GetInstance] Pop];
}

-(void)SetupGame
{
    [mLevelDefinitions StartLevel];
	
	// What type of mode are we in?
	switch (mGameModeType)
	{
		case GAMEMODE_TYPE_MENU:
        {
            FlowStateParams* params = &sFlowStateParams[mLevel];
            FlowStateParams* prevParams = NULL;
            
            if ((mPrevLevel != LEVEL_INDEX_INVALID) && (mPrevGameModeType == GAMEMODE_TYPE_MENU))
            {
                prevParams = &sFlowStateParams[mPrevLevel];
            }

            GameState* newState = [NSClassFromString(params->mStateName) alloc];
            
            if ((prevParams != NULL) && (prevParams->mKeepSuspended))
            {
                [[GameStateMgr GetInstance] Push:newState];
            }
            else
            {
                [[GameStateMgr GetInstance] ReplaceTop:newState];
            }
            
			break;
        }
			
		case GAMEMODE_TYPE_RUN21_MARATHON:
        case GAMEMODE_TYPE_RUN21:
        {
            [self CycleOutCompanionsWithDealer:[mLevelDefinitions GetDealerId] Seat1:CompID_Empty Seat2:CompID_Empty];
            
            GameRun21* newState = [GameRun21 alloc];
            
            switch(mPrevGameModeType)
            {
                case GAMEMODE_TYPE_RUN21_MARATHON:
                case GAMEMODE_TYPE_RUN21:
                {
                    GameState* pendingState = NULL;
                    
                    while(true)
                    {
                        pendingState = (GameState*)[[GameStateMgr GetInstance] GetActiveStateAfterOperations];
                        
                        if ((pendingState == NULL) || ([((GameState*)pendingState->mParentState) class] == [MainMenu class]) || ([pendingState class] == [MainMenu class]))
                        {
                            break;
                        }
                        else
                        {
                            [[GameStateMgr GetInstance] Pop];
                        }
                    }
                    
                    [[GameStateMgr GetInstance] ReplaceTop:newState];
                    break;
                }
                
                case GAMEMODE_TYPE_MENU:
                case GAMEMODE_TYPE_INVALID:
                {
                    [[GameStateMgr GetInstance] Push:newState];
                    break;
                }
                
                default:
                {
                    NSAssert(FALSE, @"Unknown game mode");
                }
            }
            
			break;
        }

		default:
			NSAssert(FALSE, @"Undefined Flow Type"); 
			break;	
	}
	
}

-(BOOL)UnlockNextLevel
{
    NSAssert(mGameModeType == GAMEMODE_TYPE_RUN21, @"This function is only supported in Run21 mode");
    
    int level = [[Flow GetInstance] GetLevel];
    int initialLevel = [[SaveSystem GetInstance] GetMaxLevel];
    
    if (level < RUN21_LEVEL_NUM)
    {
        if (initialLevel < (level + 1))
        {
            [[SaveSystem GetInstance] SetMaxLevel:(level + 1)];
        }
    }

    int xrayLevel = [[[Flow GetInstance] GetLevelDefinitions] GetXrayUnlockLevel];
    
    if ((initialLevel <= xrayLevel) && (level == xrayLevel))
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LS_Level6CompleteTitle", NULL)
                                                        message:NSLocalizedString(@"LS_Level6Complete", NULL)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"LS_OK", NULL)
                                              otherButtonTitles:nil];

        [alert show];
        [alert release];
        
        // TRUE, we did show a dialog
        return TRUE;
    }
    
    // FALSE, didn't show a dialog
    return FALSE;
}


-(void)EvaluateCompanionUnlocks
{
    for (int i = 0; i < CompID_MAX; i++)
    {
        [[CompanionManager GetInstance] UnlockCompanion:i];
    }
}

-(CasinoID)GetCasinoId
{
    NSAssert(mGameModeType == GAMEMODE_TYPE_RUN21 || mGameModeType == GAMEMODE_TYPE_RUN21_MARATHON, @"Invalid game mode type");
    
    return [mLevelDefinitions GetCasinoId:mLevel];
}

-(LevelDefinitions*)GetLevelDefinitions
{
    return mLevelDefinitions;
}

-(void)SetRequestedFacebookLogin:(BOOL)inRequested
{
    mRequestedFacebookLogin = inRequested;
}

-(BOOL)GetRequestedFacebookLogin
{
    return mRequestedFacebookLogin;
}

@end