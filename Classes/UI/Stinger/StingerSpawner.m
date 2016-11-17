//
//  StingerSpawner.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "StingerSpawner.h"
#import "Stinger.h"
#import "GameStateMgr.h"
#import "ResourceManager.h"
#import "Color.h"
#import "UISounds.h"
#import "GameObjectManager.h"

// Kking - Translate (TODO in Tool for Pregen)
static const char* HISCORE_STINGER_NAME				= "Run21_HiScore.stinger";

static Color sWinColor								= { 0x00FF00B0 };
static Color sDealerDialogColor						= { 0xFFFFF0FF };	// Off-White

static const CFTimeInterval sStingerDuration				= 3.0;
static const CFTimeInterval sDealerDialogDuration			= 4.0;

// Todo encapsulate into a class.
static const CFTimeInterval sRun21TimeIntervals[R21_STINGER_NUM]=	{ 
	0.5,							// R21_STINGER_21
	1.0,							// R21_STINGER_CHARLIE
	2.0,							// R21_STINGER_BUST
	3.0,							// R21_STINGER_CLEARING_CLUBS       // Removed
	1.0,							// R21_STINGER_RUNNING_RAINBOW
	1.5,							// R21_STINGER_PLAYER_PHASE         // Removed
	3.0,							// R21_STINGER_SUDDEN_DEATH
    1.0,                            // R21_STINGER_RUN
																	};

static const char* sRun21FileNames[R21_STINGER_NUM]=			{ 
	"Run21_Hand21.stinger",			// R21_STINGER_21
	"Run21_HandCharlie.stinger",	// R21_STINGER_CHARLIE
	"Run21_HandBust.stinger",		// R21_STINGER_BUST					// Removed
	"Run21_ClearingClubs.stinger",	// R21_STINGER_CLEARING_CLUBS
	"Run21_RunningRainbow.stinger",	// R21_STINGER_RUNNING_RAINBOW
	"Run21_PlayerPhase.stinger",	// R21_STINGER_PLAYER_PHASE
	"Run21_SuddenDeath.stinger",	// R21_STINGER_SUDDEN_DEATH
    "Run21_run.stinger",            // R21_STINGER_RUN
																	};
static UISoundId		sRun21SoundID[R21_STINGER_NUM]=				{ 
	SFX_OUTCOME_WIN_NORMAL,			// R21_STINGER_21
	SFX_OUTCOME_WIN_SPECIAL,		// R21_STINGER_CHARLIE
	SFX_OUTCOME_LOSS,				// R21_STINGER_BUST
	SFX_TUTORIAL_DIALOGUE,			// R21_STINGER_CLEARING_CLUBS
	SFX_TUTORIAL_DIALOGUE,			// R21_STINGER_RUNNING_RAINBOW
	SFX_TUTORIAL_DIALOGUE,			// R21_STINGER_PLAYER_PHASE
	SFX_STINGER_BLACKJACK_PUSH,		// R21_STINGER_SUDDEN_DEATH
    SFX_OUTCOME_WIN_NORMAL,         // R21_STINGER_RUN
																	};
	
#define STINGER_SPAWNER_DIALOG_DELAY				(0.3f)

@implementation StingerSpawner

-(StingerSpawner*)InitWithParams:(StingerSpawnerParams*)inParams
{    
    [[(GameState*)[[GameStateMgr GetInstance] GetActiveState] GetMessageChannel] AddListener:self];
    [GetGlobalMessageChannel() AddListener:self];
	
	memcpy(&mParams, inParams, sizeof(StingerSpawnerParams));
    
    memset(&mDealerDialogueParams, 0, sizeof(mDealerDialogueParams));

    mDealerStinger = NULL;
    mDealerDialogueState = DEALER_DIALOGUE_STATE_IDLE;
    
    mStingerSpawnerState = STINGER_SPAWNER_IDLE;
    mTimer = 0.0f;
	
	[mParams.mRenderGroup retain];
        
    return self;
}

-(void)dealloc
{
	[mParams.mRenderGroup release];
	
    [super dealloc];
}

+(void)InitDefaultParams:(StingerSpawnerParams*)outParams
{
	outParams->mRenderGroup = NULL;
    SetVec2(&outParams->mRenderOffset, 0.0f, 0.0f);
    SetVec2(&outParams->mRenderScale, 1.0f, 1.0f);
	outParams->mDrawBar = TRUE;
    outParams->mStingerSpawnerMode = STINGERSPAWNER_MODE_ALL;
}

+(void)InitDefaultDealerDialogueParams:(StingerSpawnerDealerDialogueParams*)outParams
{
    outParams->mStrings = NULL;
    outParams->mNumStrings = 0;
    outParams->mCompanionPosition = COMPANION_POSITION_INVALID;
    outParams->mClickToContinue = TRUE;
    outParams->mPausable = [GameStateMgr GetInstance];
    SetVec2(&outParams->mRenderOffset, 0.0f, 0.0f);
    outParams->mFontSize = 12.0f;
    outParams->mFontName = NULL;
    outParams->mFontAlignment = kCTTextAlignmentLeft;
    SetColorFloat(&outParams->mFontColor, 1.0, 0.9, 1.0, 1.0);
}

-(void)Remove
{
    [GetGlobalMessageChannel() RemoveListener:self];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mStingerSpawnerState)
    {
        case STINGER_SPAWNER_WAITING_FOR_TIMER:
        {
            mTimer -= inTimeStep;
            
            if (mTimer < 0.0f)
            {
                mTimer = 0.0f;
                mStingerSpawnerState = STINGER_SPAWNER_IDLE;
                
                [self EvaluateDealerDialogClick:mDealerDialogueParams.mStrings
                                                numStrings:mDealerDialogueParams.mNumStrings
                                                clickToContinue:mDealerDialogueParams.mClickToContinue];
                
                for (int i = 0; i < mDealerDialogueParams.mNumStrings; i++)
                {
                    [mDealerDialogueParams.mStrings[i] release];
                }
                
                free(mDealerDialogueParams.mStrings);
                
                mDealerDialogueParams.mStrings = NULL;
            }
        }
    }
    
    switch(mDealerDialogueState)
    {
        case DEALER_DIALOGUE_STATE_WAITING_FOR_TIMER:
        case DEALER_DIALOGUE_STATE_INTRO:
        {
            StingerState stingerState = [mDealerStinger GetStingerState];
            
            if (stingerState == STINGER_STATE_MAINTAIN)
            {
                mDealerDialogueState = DEALER_DIALOGUE_STATE_MAINTAIN;
            }
            
            break;
        }
    }
}

-(void)ProcessMessage:(Message*)inMsg
{
    if ((mParams.mStingerSpawnerMode == STINGERSPAWNER_MODE_GAMEOPERATIONS) || (mParams.mStingerSpawnerMode == STINGERSPAWNER_MODE_ALL))
    {
        switch(inMsg->mId)
        {
            case EVENT_RUN21_HAND21:
            {
                [ self SpawnRun21Stinger:R21_STINGER_21 ];
                break;
            }
                
            case EVENT_RUN21_CHARLIE:
            {
                [ self SpawnRun21Stinger:R21_STINGER_CHARLIE ];
                break;
            }
                
            case EVENT_RUN21_BUST:
            {
                [ self SpawnRun21Stinger:R21_STINGER_BUST ];
                break;
            }
            case EVENT_RUN21_CLEARING_CLUBS:
            {
                // Removing from game for speed purposes.
                //[ self SpawnRun21Stinger:R21_STINGER_CLEARING_CLUBS ];
                break;
            }
            case EVENT_RUN21_RUNNING_RAINBOW:
            {
                [ self SpawnRun21Stinger:R21_STINGER_RUNNING_RAINBOW ];
                break;
            }
            case EVENT_RUN21_PLAYER_PHASE:
            {
                // Removing from game for speed purposes.
                //[ self SpawnRun21Stinger:R21_STINGER_PLAYER_PHASE ];
                break;
            }
            case EVENT_RUN21_SUDDEN_DEATH:
            {
                [ self SpawnRun21Stinger:R21_STINGER_SUDDEN_DEATH ];
                break;
            }
            case EVENT_RUN21_MARATHON_ROW_COMPLETE:
            {
                [ self SpawnRun21Stinger:R21_STINGER_RUN ];
                break;
            }
            
            //Begin Rainbow Events
            case EVENT_RAINBOW_ROUND_WIN:
            {
                NSString *nsWin = [NSString stringWithFormat:@"Run21_Winner%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                
                //NSString *nsWin = [NSString stringWithFormat:@"Rainbow_Win%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsWin stayOnScreen:FALSE withSoundID: SFX_STINGER_RAINBOW_OUTCOMEWIN];
                break;
            }
            case EVENT_RAINBOW_ROUND_LOSE:
            {
                NSString *nsLost = [NSString stringWithFormat:@"Run21_Lost%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                
                //NSString *nsLost = [NSString stringWithFormat:@"Rainbow_Lost%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsLost stayOnScreen:FALSE withSoundID:SFX_STINGER_RAINBOW_OUTCOMELOSE];
                break;
            }
            case EVENT_RAINBOW_ROUND_PUSH:
            {
                NSString *nsPush = [NSString stringWithFormat:@"Run21_Lost%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                
                //NSString *nsPush = [NSString stringWithFormat:@"Rainbow_Push%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsPush stayOnScreen:FALSE withSoundID:SFX_STINGER_RAINBOW_OUTCOMEPUSH];
                
                break;
            }
            case EVENT_RAINBOW_GAME_WIN:
            {
                NSString *nsWin = [NSString stringWithFormat:@"Run21_Winner%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                //NSString *nsPush = [NSString stringWithFormat:@"Rainbow_Win%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                switch ((int)inMsg->mData)
                {
                    case 4:
                    {
                        [ self PlayDynamicMajorStinger:nsWin stayOnScreen:FALSE withSoundID:SFX_STINGER_BLACKJACK_CHARLIE];
                        break;
                    }
                    case 3:
                    {
                        [ self PlayDynamicMajorStinger:nsWin stayOnScreen:FALSE withSoundID:SFX_STINGER_BLACKJACK_BIGWIN];
                        break;
                    }
                    case 2:
                    {
                        [ self PlayDynamicMajorStinger:nsWin stayOnScreen:FALSE withSoundID:SFX_STINGER_BLACKJACK_WIN];
                        break;
                    }
                    case 1:
                    {
                        [ self PlayDynamicMajorStinger:nsWin stayOnScreen:FALSE withSoundID:SFX_STINGER_BLACKJACK_BJ];
                        break;
                    }
                }
                break;
                
            }
            case EVENT_RAINBOW_GAME_LOSE:
            {
                NSString *nsLost = [NSString stringWithFormat:@"Run21_Lost%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                
                //NSString *nsLost = [NSString stringWithFormat:@"Rainbow_Lose%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsLost stayOnScreen:FALSE withSoundID:SFX_MISC_UNIMPLEMENTED];
                break;
            }
            
            case EVENT_CONCLUSION_BANKRUPT:
            {
                NSString *nsLost = [NSString stringWithFormat:@"Run21_Lost%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsLost stayOnScreen:FALSE withSoundID:SFX_STINGER_BLACKJACK_BANKRUPT];
                break;
            }
                
            case EVENT_CONCLUSION_BROKETHEBANK:
            {
                NSString *nsWin = [NSString stringWithFormat:@"Run21_Winner%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsWin stayOnScreen:FALSE withSoundID:SFX_STINGER_BLACKJACK_BROKETHEBANK];
                break;
            }
                        
            case EVENT_TUTORIAL_DIALOGUE:
            {
                [self EvaluateTutorialDialogue: (Neon21TutorialDialogueMessage*)inMsg->mData ];
                break;
            }
				
			case EVENT_GAME_HISCORE:
			{
				[self EvaluateBigWinWithHiScore:TRUE];
				break;
			}
			case EVENT_GAME_PERFECT:
			{
				[self EvaluateBigWinWithHiScore:FALSE];
				break;
			}
        }
    }
    
    if ((mParams.mStingerSpawnerMode == STINGERSPAWNER_MODE_DEALERDIALOG) || (mParams.mStingerSpawnerMode == STINGERSPAWNER_MODE_ALL))
    {
        switch(inMsg->mId)
        {
            case EVENT_TUTORIAL_COMPLETED:
            {
                NSString *nsReady = [NSString stringWithFormat:@"Run21_Ready%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
                [ self PlayDynamicMajorStinger:nsReady stayOnScreen:FALSE withSoundID:SFX_STINGER_TUTORIAL_COMPLETE];
                break;
            }
        }
    }
     
    switch(inMsg->mId)
    {
        case EVENT_STINGER_DISMISSED:
        {   
            Stinger* stinger = (Stinger*)inMsg->mData;
            
            if (mDealerDialogueState == DEALER_DIALOGUE_STATE_IDLE)
            {
                if (stinger->mStingerCausedPause)
                {
                    [[GameStateMgr GetInstance] ResumeProcessing];
                }
            }
            else
            {
                if (stinger->mStingerCausedPause)
                {
                    [mDealerDialogueParams.mPausable ResumeProcessing];
                }

                if (mDealerDialogueParams.mCompanionPosition != COMPANION_POSITION_INVALID)
                {
                    Companion* companion = [[CompanionManager GetInstance] GetCompanionForPosition:mDealerDialogueParams.mCompanionPosition];
                    
                    if (companion != NULL)
                    {
                        [companion->mEntity SetGlowEnabled:FALSE];
                    }
                }
                
                mDealerDialogueState = DEALER_DIALOGUE_STATE_IDLE;
                mDealerStinger = NULL;
            }
            
            break;
        }
        
        case EVENT_STINGER_EXPIRED:
        {
            Stinger* stinger = (Stinger*)inMsg->mData;
            
            if (stinger->mStingerCausedPause)
            {
                [[GameStateMgr GetInstance] ResumeProcessing];
            }

            break;
        }
    }
}

-(void)PlayDynamicMajorStinger:(NSString*)nsStr stayOnScreen:(BOOL)bStayOnScreen withSoundID:(UISoundId)soundID
{
	StingerParams params;
    [Stinger InitDefaultParams:&params];
	
	[ params.mPrimary addObject:[StingerParameter MakeStingerParameter:nsStr type:STINGER_PARAMETER_PREGENERATED] ];

	params.mDuration	= bStayOnScreen ? sStingerDuration * 10 : sStingerDuration;
    params.mType		= bStayOnScreen ? STINGER_TYPE_DEALER_DIALOG_INDEFINITE : STINGER_TYPE_MAJOR;
    params.mColor		= bStayOnScreen ? sWinColor : params.mColor;
	params.mRenderGroup = mParams.mRenderGroup;
    CloneVec2(&mParams.mRenderOffset, &params.mRenderOffset);
    CloneVec2(&mParams.mRenderScale, &params.mRenderScale);
	params.mDrawBar		= mParams.mDrawBar;
    
    Stinger* stinger = [(Stinger*)[Stinger alloc] InitWithParams:&params];
    
    [[self GetGameObjectCollection] Add:stinger];
    
    BOOL stingerPause = TRUE;
    
    stinger->mStingerCausedPause = stingerPause;
    
    if (params.mType == STINGER_TYPE_DEALER_DIALOG_INDEFINITE)
    {
        mDealerStinger = [stinger retain];
		mDealerDialogueState = DEALER_DIALOGUE_STATE_INTRO;
    }
	else 
	{
        if (stingerPause)
        {
            [[GameStateMgr GetInstance] PauseProcessing];
        }
        
        [stinger release];
	}
	
    [UISounds PlayUISound:soundID];
}

-(void)EvaluateGenericMajorStingerWithFileName:(const char*)inFileName
{
	StingerParams params;
    
    [Stinger InitDefaultParams:&params];
	
    [params.mPrimary addObject:
	 [StingerParameter MakeStingerParameter:[NSString stringWithUTF8String:inFileName] type:STINGER_PARAMETER_PREGENERATED]];
    
    params.mDuration = sStingerDuration;
    params.mType = STINGER_TYPE_MAJOR;
    params.mRenderGroup = mParams.mRenderGroup;
    CloneVec2(&mParams.mRenderOffset, &params.mRenderOffset);
    CloneVec2(&mParams.mRenderScale, &params.mRenderScale);
	params.mDrawBar = mParams.mDrawBar;
	
    Stinger* stinger = [(Stinger*)[Stinger alloc] InitWithParams:&params];
	
    [[self GetGameObjectCollection] Add:stinger];
    [stinger release];
    
    [[GameStateMgr GetInstance] PauseProcessing];
    
    stinger->mStingerCausedPause = TRUE;
}

-(void)SpawnRun21Stinger:(Run21StingerID)inStingerID
{
	StingerParams	params;
	const char		*fileName;
	UISoundId		soundID		= SFX_MISC_UNIMPLEMENTED;
    
	NSAssert(inStingerID >= 0 && inStingerID < R21_STINGER_NUM, @"SpawnRun21Stinger - Invalid Stinger ID");
	
    [Stinger InitDefaultParams:&params];
	params.mType		= STINGER_TYPE_MAJOR;	// Setting this to STINGER_TYPE_MINOR breaks this.
	params.mDuration	= sRun21TimeIntervals[inStingerID];
	params.mRenderGroup = mParams.mRenderGroup;
    CloneVec2(&mParams.mRenderOffset, &params.mRenderOffset);
    CloneVec2(&mParams.mRenderScale, &params.mRenderScale);
	params.mDrawBar		= mParams.mDrawBar;
    //params.mDuration    = sShortStingerDuration;
	
	soundID				= sRun21SoundID[inStingerID];
	fileName			= sRun21FileNames[inStingerID];

	// Localizing only bust.  Everything else is universal words.
	if ( R21_STINGER_BUST == inStingerID )
	{
        NSString *nsBust = [NSString stringWithFormat:@"Run21_Bust%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
		[ params.mPrimary addObject:[StingerParameter MakeStingerParameter:nsBust type:STINGER_PARAMETER_PREGENERATED] ];
	}
	else 
	{
		[params.mPrimary addObject:[StingerParameter MakeStingerParameter:[NSString stringWithUTF8String:fileName] type:STINGER_PARAMETER_PREGENERATED]];
		
	}
	[UISounds PlayUISound:soundID ];
    
    Stinger* stinger	= [(Stinger*)[Stinger alloc] InitWithParams:&params];
    [[self GetGameObjectCollection] Add:stinger];
    [stinger release];
    
    [[GameStateMgr GetInstance] PauseProcessing];
    stinger->mStingerCausedPause = TRUE;
}

// @TODO - Make this stay on the LCD until the user presses a button
-(void)EvaluateBigWinWithHiScore:(BOOL)bHiScore
{	
	StingerParams params;
    
    [Stinger InitDefaultParams:&params];
	
    NSString *perfectGame = [NSString stringWithFormat:@"Run21_Perfect%@.stinger", NSLocalizedString(@"LS_LANGUAGE_CODE", NULL) ];
    
	if ( bHiScore )
		[params.mPrimary addObject:[StingerParameter MakeStingerParameter:[NSString stringWithUTF8String:HISCORE_STINGER_NAME] type:STINGER_PARAMETER_PREGENERATED]];
    else
		[params.mPrimary addObject:[StingerParameter MakeStingerParameter:perfectGame type:STINGER_PARAMETER_PREGENERATED] ];
	
	params.mDuration = sStingerDuration * 10;	// Hack
    params.mType = FALSE;
    params.mColor = sWinColor;
	params.mRenderGroup = mParams.mRenderGroup;
    CloneVec2(&mParams.mRenderOffset, &params.mRenderOffset);
    CloneVec2(&mParams.mRenderScale, &params.mRenderScale);
	params.mDrawBar = mParams.mDrawBar;
    
    Stinger* stinger = [(Stinger*)[Stinger alloc] InitWithParams:&params];
    
    [[self GetGameObjectCollection] Add:stinger];
    [stinger release];
    
    stinger->mStingerCausedPause = TRUE;
    
    if (params.mType == STINGER_TYPE_DEALER_DIALOG_INDEFINITE)
    {
        mDealerStinger = [stinger retain];
    }
	
    mDealerDialogueState = DEALER_DIALOGUE_STATE_INTRO;
    
	//[UISounds PlayUISound:SFX_STINGER_BLACKJACK_BIGWIN];
}

-(void)EvaluateTutorialDialogue:(Neon21TutorialDialogueMessage*)msg
{
    NSAssert(FALSE, @"This function is depracated");
	//[ self SpawnDealerDialogClick: (const char**)msg->dialogue numStrings: msg->numStrings ];
}

-(void)EvaluateSplit
{
#if DUMMY_DEALER_DIALOG
    [self SpawnDealerDialogClick:SPLIT_STRINGS numStrings:(sizeof(SPLIT_STRINGS) / sizeof(char*))];
#endif
}

-(void)SpawnDealerDialogTimed:(const char*)inString
{
    NSAssert(FALSE, @"This method is untested, make sure it conforms to the proper dealer dialogue states");
    
    StingerParams params;
    
    [Stinger InitDefaultParams:&params];
    
    [params.mPrimary addObject:
        [StingerParameter MakeStingerParameter:[NSString stringWithUTF8String:inString] type:STINGER_PARAMETER_DYNAMIC]];
        
    params.mDuration = sDealerDialogDuration;
    params.mType = STINGER_TYPE_DEALER_DIALOG_TIMED;
    params.mColor = sDealerDialogColor;
    params.mRenderGroup = mParams.mRenderGroup;
    CloneVec2(&mParams.mRenderOffset, &params.mRenderOffset);
    CloneVec2(&mParams.mRenderScale, &params.mRenderScale);
    params.mDrawBar = mParams.mDrawBar;
    
    Stinger* stinger = [(Stinger*)[Stinger alloc] InitWithParams:&params];
        
    [[self GetGameObjectCollection] Add:stinger];
    [stinger release];
}

-(void)SpawnDealerDialogClick:(NSString**)inStrings numStrings:(int)inNumStrings
{    
    [self SpawnDealerDialogClick:inStrings numStrings:inNumStrings dialoguePosition:COMPANION_POSITION_INVALID];
}

-(void)SpawnDealerDialogClick:(NSString**)inStrings numStrings:(int)inNumStrings dialoguePosition:(CompanionPosition)inCompanionPosition
{
    StingerSpawnerDealerDialogueParams params;
    
    [StingerSpawner InitDefaultDealerDialogueParams:&params];
    
    params.mStrings = inStrings;
    params.mNumStrings = inNumStrings;
    params.mCompanionPosition = inCompanionPosition;
    
    [self SpawnDealerDialogClick:&params];
}

-(void)SpawnDealerDialogClick:(StingerSpawnerDealerDialogueParams*)inParams
{
    NSAssert(mDealerDialogueState == DEALER_DIALOGUE_STATE_IDLE, @"Attempting to spawn dealer dialogue while another dealer dialogue stinger is still processing");
    
    [inParams->mPausable PauseProcessing];

    mDealerDialogueParams.mCompanionPosition = inParams->mCompanionPosition;
    CloneVec2(&inParams->mRenderOffset, &mDealerDialogueParams.mRenderOffset);
    mDealerDialogueParams.mFontSize = inParams->mFontSize;
    mDealerDialogueParams.mFontName = [inParams->mFontName retain];
    mDealerDialogueParams.mFontColor = inParams->mFontColor;
    mDealerDialogueParams.mFontAlignment = inParams->mFontAlignment;
    
    if (inParams->mCompanionPosition != COMPANION_POSITION_INVALID)
    {
        Companion* companion = [[CompanionManager GetInstance] GetCompanionForPosition:inParams->mCompanionPosition];
        
        if (companion != NULL)
        {
            [companion->mEntity SetGlowEnabled:TRUE];
        }
        
        mDealerDialogueParams.mStrings = malloc(sizeof(NSString*) * inParams->mNumStrings);
        mDealerDialogueParams.mNumStrings = inParams->mNumStrings;
        
        for (int i = 0; i < inParams->mNumStrings; i++)
        {
            mDealerDialogueParams.mStrings[i] = inParams->mStrings[i];
            [mDealerDialogueParams.mStrings[i] retain];
        }
        
        mTimer = STINGER_SPAWNER_DIALOG_DELAY;
        mStingerSpawnerState = STINGER_SPAWNER_WAITING_FOR_TIMER;
        mDealerDialogueState = DEALER_DIALOGUE_STATE_WAITING_FOR_TIMER;
        
        mDealerDialogueParams.mClickToContinue = inParams->mClickToContinue;
        mDealerDialogueParams.mPausable = inParams->mPausable;
    }
    else
    {
        [self EvaluateDealerDialogClick:inParams->mStrings numStrings:inParams->mNumStrings clickToContinue:inParams->mClickToContinue];
    }
}

-(void)EvaluateDealerDialogClick:(NSString**)inStrings numStrings:(int)inNumStrings clickToContinue:(BOOL)inClickToContinue
{
    StingerParams params;
    
    [Stinger InitDefaultParams:&params];
        
    for (int i = 0; i < inNumStrings; i++)
    {
        [params.mPrimary addObject:
		[StingerParameter MakeStingerParameter:inStrings[i] type:STINGER_PARAMETER_DYNAMIC]];
    }
        
    params.mDuration = 0;
    params.mType = inClickToContinue ? STINGER_TYPE_DEALER_DIALOG_CLICKTHRU : STINGER_TYPE_DEALER_DIALOG_INDEFINITE;
    params.mColor = mDealerDialogueParams.mFontColor;
	params.mRenderGroup = mParams.mRenderGroup;
    CloneVec2(&mParams.mRenderOffset, &params.mRenderOffset);
    CloneVec2(&mParams.mRenderScale, &params.mRenderScale);
	params.mDrawBar = mParams.mDrawBar;
    CloneVec2(&mDealerDialogueParams.mRenderOffset, &params.mRenderOffset);
    params.mFontSize = mDealerDialogueParams.mFontSize;
    params.mFontName = mDealerDialogueParams.mFontName;
    params.mFontAlignment = mDealerDialogueParams.mFontAlignment;
    
    Stinger* stinger = [(Stinger*)[Stinger alloc] InitWithParams:&params];
    
    [[self GetGameObjectCollection] Add:stinger];
    [stinger release];
    
    stinger->mStingerCausedPause = TRUE;
    
    if (params.mType == STINGER_TYPE_DEALER_DIALOG_INDEFINITE)
    {
        mDealerStinger = [stinger retain];
    }
	
    mDealerDialogueState = DEALER_DIALOGUE_STATE_INTRO;
    
	[UISounds PlayUISound:SFX_TUTORIAL_DIALOGUE];
}

-(BOOL)TerminateDealerStinger
{
    if (mDealerStinger != NULL)
    {
        return [mDealerStinger Terminate];
    }

    return TRUE;
}

-(void)TerminateDealerStingerSync
{
    while (![self TerminateDealerStinger])
    {
        [mDealerStinger Update:0.033];
    }
    
    [mDealerStinger release];
    mDealerStinger = NULL;
}

-(StingerSpawnerDealerDialogueState)GetDealerDialogueState
{
    return mDealerDialogueState;
}

-(GameObjectCollection*)GetGameObjectCollection
{
	GameObjectCollection* collection = [GameObjectManager GetInstance];
	
	if (mParams.mRenderGroup != NULL)
	{
		GameObjectCollection* renderGroupCollection = [mParams.mRenderGroup GetGameObjectCollection];
		
		if (renderGroupCollection != NULL)
		{
			collection = renderGroupCollection;
		}
	}
	
	return collection;
}

@end