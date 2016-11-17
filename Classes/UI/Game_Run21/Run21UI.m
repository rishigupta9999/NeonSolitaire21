//
//  Run21UI.m
//  Neon Engine
//
//  c. Neon Games LLC - 2011, All rights reserved.


#import "Run21UI.h"
#import "GameRun21.h"
#import "UINeonEngineDefines.h"
#import "Flow.h"
#import "Run21Environment.h"
#import "MiniGameTableEntity.h"
#import "MultiStateButton.h"
#import "StringCloud.h"

#import "AchievementManager.h"
#import "HistogramFilter.h"

#import "SaveSystem.h"
#import "IAPStore.h"
#import "RegenerationManager.h"
#import "ExperienceManager.h"
#import "NeonAccountManager.h"
#import "LevelDefinitions.h"
#import "MainMenu.h"
#import "TutorialScript.h"

#define RUN21_RightUI_Row1                      -3.00f
#define RUN21_RightUI_Row2                      -2.00f
#define RUN21_RightUI_Row3                      -0.35f

#define RUN21_UI_DECK_X_Col1                    2.50f                               // x column1 is where the the power ups go
#define RUN21_UI_DECK_X_Col2                    RUN21_UI_DECK_X_Col1 + 1.5f         // x column2 is where the Jokers go
#define RUN21_UI_DECK_X_Col3                    RUN21_UI_DECK_X_Col2 + 1.3f         // x column3 is where the Placer and the NumCardsLeft image go
#define RUN21_UI_DECK_X_Col4                    RUN21_UI_DECK_X_Col3 + 1.3f         // x column4 is where the numCardsLeft number goes


#define RUN21_UI_DECK_Y_Col1                    -0.40f                              // y column1 (row1) is where the NumCardsLeft indicator goes
#define RUN21_UI_DECK_Y_Col2                    RUN21_UI_DECK_Y_Col1 + 1.45f        // y column2 (row2) is where the 1st Joker and the placer go
#define RUN21_UI_DECK_Y_Col3                    RUN21_UI_DECK_Y_Col2 + 1.50f        // y column3 (row3) is where the 2nd Joker goes

#define RUN21_UI_PLACER_X                       RUN21_UI_DECK_X_Col3 - 0.5f
#define RUN21_UI_PLACER_Y                       RUN21_UI_DECK_Y_Col2 + 0.2f

#define RUN21_UI_JIMAGE_X                       RUN21_UI_DECK_X_Col2
#define RUN21_UI_POWERUP_Y_Col1                 RUN21_UI_DECK_Y_Col1 + 1.35f
#define RUN21_UI_POWERUP_Y_Col2                 RUN21_UI_DECK_Y_Col2 + 1.35f

#define RUN21_UI_JHOLDER_X_Col1                 RUN21_UI_DECK_X_Col1
#define RUN21_UI_JHOLDER_X_Col2                 RUN21_UI_DECK_X_Col1 + 1.25
#define RUN21_UI_JHOLDER_Y                      -2.85
#define RUN21_UI_JHOLDER_XOffset                -0.3f

#define RUN21_UI_CARDSLEFT_X                    RUN21_UI_DECK_X_Col1 
#define RUN21_UI_CARDSLEFT_Y                    RUN21_UI_DECK_Y_Col1 - 0.3

#define RUN21_UI_SCORE_X                        0.8f
#define RUN21_UI_SCORE_Y                        RUN21_RightUI_Row1 + .15


#define RUN21_UI_OUTCOME_SCALER                 .02f
#define RUN21_UI_OUTCOME_SCALER_X1              RUN21_UI_OUTCOME_SCALER * 2

#define RUN21_UI_CARDLOCATION_X                 RUN21_UI_DECK_X_Col1 - 4.75f

#define RUN21_FADE_OUT_DURATION                 0.5f;

static Vector3 sLevelCardLocation				= { { RUN21_UI_CARDLOCATION_X ,        RUN21_RightUI_Row2,     0.0 } };
static Vector3 sLevelStarLocation				= { { RUN21_UI_CARDLOCATION_X + 0.15f ,RUN21_RightUI_Row2 + 0.1f, 0.0 } };
static Vector3 sLevelCardScaler					= { { RUN21_UI_OUTCOME_SCALER , RUN21_UI_OUTCOME_SCALER, 1.0 } };
static Vector3 sLevelStarScaler					= { { RUN21_UI_OUTCOME_SCALER , RUN21_UI_OUTCOME_SCALER, 1.0 } };

static Vector3 x1_sLevelCardScaler				= { { RUN21_UI_OUTCOME_SCALER_X1 , RUN21_UI_OUTCOME_SCALER_X1, 1.0 } };
static Vector3 x1_sLevelStarScaler				= { { RUN21_UI_OUTCOME_SCALER_X1 , RUN21_UI_OUTCOME_SCALER_X1, 1.0 } };

static Vector3 PlacerHolderLocation				= { { RUN21_UI_PLACER_X,        RUN21_UI_PLACER_Y,      0.0 } };

static Vector3 Joker1ImageLocation				= { { RUN21_UI_JHOLDER_X_Col1,   RUN21_UI_JHOLDER_Y,      0.0 } };
static Vector3 Joker2ImageLocation				= { { RUN21_UI_JHOLDER_X_Col2,   RUN21_UI_JHOLDER_Y,      0.0 } };

static Vector3 Joker1HolderLocation				= { { RUN21_UI_JHOLDER_X_Col1,  RUN21_UI_JHOLDER_Y,     0.0 } };
static Vector3 Joker2HolderLocation				= { { RUN21_UI_JHOLDER_X_Col2,  RUN21_UI_JHOLDER_Y,     0.0 } };

static Vector3 numCardsHolderLocation			= { { RUN21_UI_DECK_X_Col3 - 0.7f,  RUN21_UI_CARDSLEFT_Y,       -0.1 } };
static Vector3 numCardsTextLocation				= { { RUN21_UI_DECK_X_Col3 - 0.3f,  RUN21_UI_CARDSLEFT_Y + 0.6, -0.15 } };
static Vector3 numCardsTextLocationSingleDigit  = { { RUN21_UI_DECK_X_Col3 - 0.2f,  RUN21_UI_CARDSLEFT_Y + 0.5, -0.15 } };
static Vector3 numCardsRotation                 = { { 0.0, 0.0f, -12.0f } };

static Vector3 sRunnerScaler					= { { 0.0350 , 0.0320, 1.0 } };
static float   sRunnerScalerCompressedHeight    = 0.026;

static Vector3 sEndGameButtonScaler				= { { 0.0300 , 0.0300, 1.0 } };
static Vector3 sEndGameStarScaler				= { { 0.0175 , 0.0175, 1.0 } };
static float   sEndGameStarCompressedHeight     = 0.0125;

static Vector3 sJokerScale                      = { { 0.030, 0.030, 1.0 } };
static Vector3 sXrayScale                       = { { 0.025, 0.035, 1.0 } };
static Vector3 sTornadoScale                    = { { 0.025, 0.025, 1.0 } };

static Vector3 PlacerScaleValue					= { { 0.030, 0.022, 1.0 } };

static Vector3 sXRayButtonLocation              = { { RUN21_UI_DECK_X_Col1,   RUN21_UI_POWERUP_Y_Col1 - 1.4,  0.0 } };
static Vector3 sXRayNumUsesLocation             = { { RUN21_UI_DECK_X_Col1,   RUN21_UI_POWERUP_Y_Col1 - 1.0,  0.0 } };
static Vector3 sXRayNumUsesScaler               = { { 0.025, 0.025, 1.0 } };

static Vector3 sTallXRayBuyMoreIndicatorLocation    = { { 320, 150, 0.0 } };
static Vector3 sXRayBuyMoreIndicatorLocation        = { { 310, 150, 0.0 } };

static Vector3 sTallTornadoBuyMoreIndicatorLocation    = { { 320, 230, 0.0 } };
static Vector3 sTornadoBuyMoreIndicatorLocation        = { { 310, 230, 0.0 } };

static Vector3 sWhirlwindButtonLocation         = { { RUN21_UI_DECK_X_Col1, RUN21_UI_POWERUP_Y_Col2 - 1.4, 0.0 } };
static Vector3 sWhirlwindNumUsesLocation        = { { RUN21_UI_DECK_X_Col1, RUN21_UI_POWERUP_Y_Col2, 0.0 } };
static Vector3 sWhirlwindNumUsesScaler          = { { 0.025, 0.025, 1.0 } };

static Vector3 sLevelBarHolderLocation          = { { -5.00, RUN21_RightUI_Row1 - .3 ,0.0 } };
static Vector3 sLevelBarHolderScaler            = { { .02, .02, 1.0 } };
static Vector3 x1_sLevelBarHolderScaler         = { { .04, .04, 1.0 } };

static const int CARD_WIDTH_PROJECTED = 2.4;
static const int STAR_WIDTH_PROJECTED = 0.5;

static const CFTimeInterval sCriticalTime = 30.0f;

static Vector3 sEndGamePowerupCounterLocations[ENDGAME_POWERUP_NUM] =
{
#if USE_LIVES
    { -7.0  , 2.8  , 0.0 },
#endif
#if USE_TORNADOES
    { -2.8  , 2.8  , 0.0 },
#endif
    { -0.0  , 2.8 , 0.0 }
};

static Vector3 sEndGamePowerupTextBoxLocations[ENDGAME_POWERUP_NUM] =
{
#if USE_LIVES
    { -6.8  , 2.9  , 0.0 },
#endif
#if USE_TORNADOES
    { -1.8  , 3.1  , 0.0 },
#endif
    { 1.8  , 3.1 , 0.0 }
};

static Vector3  sEndGamePowerupCounterScaler = { {.02,.02,1.0} };

static Vector3  sSkipTutorialButtonLocation  = { { 0.0, 100.0, 0.0 } };

static Vector3  sJumbotronScaleValue         = { { 1.06, 1.07, 1.0 } };

#define MAX_JUMBOTRON_LINES (4)
static float    sJumbotronFontSizes[MAX_JUMBOTRON_LINES] = { 36, 36, 28, 22 };
static float    sJumbotronSpacing[MAX_JUMBOTRON_LINES] = { 40, 40, 30, 22 };

#define RUNNER_ORIGIN_X		-7.220
#define RUNNER_ORIGIN_Y		-3.425

#define ENDGAME_STAR_ORIGIN_X	.75f
#define ENDGAME_STAR_ORIGIN_Y	RUNNER_ORIGIN_Y + .60
#define RUNNER_ORIGIN_Z		0.000
#define RUNNER_OFFSET_Y		1.75

#define ENDGAME_LEFT_X		-7.00
#define ENDGAME_RIGHT_X		.9
#define ENDGAME_ORIGIN_Y	RUN21_RightUI_Row2

#define ENDGAME_STAR_OFFSET_Y	RUNNER_OFFSET_Y

static const CFTimeInterval AUTO_EXIT_TIME_DELAY = 0.5;

static Vector3 sEndGameButtonLocations[ENDGAMEBUTTON_NUM] = {
							{ ENDGAME_LEFT_X  ,ENDGAME_ORIGIN_Y, 0.0 },
							{ ENDGAME_RIGHT_X ,ENDGAME_ORIGIN_Y, 0.0 },
							{ ENDGAME_RIGHT_X ,ENDGAME_ORIGIN_Y, 0.0 }
															};

static const char*  sJokerFileNames[JokerStatus_MAX] = 
{   "run21_joker_DifficultyIneligible.papng",	// JokerStatus_TableTurnedOff [ todo: Transparent image ]
	"run21_joker_DifficultyIneligible.papng",	// JokerStatus_DifficultyIneligible
	"run21_joker_inDeck.papng",					// JokerStatus_InDeck
	"run21_joker_inPlacer.papng",				// JokerStatus_InPlacer
	"run21_joker_outDeck.papng",				// JokerStatus_NotInDeck
};

static const char*  sJokerHolderFileNames[JokerStatus_MAX] = 
{   "run21_jholder_tableoff.papng",				// JokerStatus_TableTurnedOff
	"run21_jholder_ineligible.papng",			// JokerStatus_DifficultyIneligible
	"run21_jholder_indeck.papng",				// JokerStatus_InDeck
	"run21_jholder_inplacer.papng",				// JokerStatus_InPlacer
	"run21_jholder_outdeck.papng",				// JokerStatus_NotInDeck
};

static const char*  sNumCardsLeftFileNames[NUMCARDSLEFT_NUM] = 
{   "r21_numcards_grey.papng",					// NUMCARDSLEFT_Inactive
	"r21_numcards_blue.papng",					// NUMCARDSLEFT_ClubsRemove
	"r21_numcards_blue.papng",					// NUMCARDSLEFT_DealRainbow
	"r21_numcards_yellow.papng",				// NUMCARDSLEFT_PlayerActive
	"r21_numcards_red.papng",					// NUMCARDSLEFT_SuddenDeath
};

static const char* sRASFileNames[RAS_NUM] = 
{   "ras_busted.papng",							// RAS_INACTIVE		-> RAS_BUSTED
	"ras_busted.papng",							// RAS_BUSTED
	"ras_busted.papng",							// RAS_UNAVAILABLE	-> RAS_BUSTED
	"ras_available.papng",						// RAS_AVAILABLE
	"ras_selected.papng",						// RAS_SELECTED
	"ras_willclear.papng",						// RAS_WILLCLEAR
	"ras_willbust.papng",
};

static const char* sEndGameButtonTextures[ENDGAMEBUTTON_NUM] = 
{   "r21_endgame_levelselect.papng",			// ENDGAMEBUTTON_LEVELSELECT
	"r21_endgame_retry.papng",					// ENDGAMEBUTTON_RETRY
	"r21_endgame_progress.papng",				// ENDGAMEBUTTON_ADVANCE
};

static const char* sEndGameButtonNames[ENDGAMEBUTTON_NUM] =
{
    "Main Menu",
    "Retry",
    "Next Level"
};

static const Vector2 sEndGameButtonTextPositions[ENDGAMEBUTTON_NUM] =
{   { 30, 120 },
    { 52, 120 },
    { 30, 120 }
};


static const char*  sEndGameButtonTextures_Glow[CARDSUIT_NumSuits] = 
{   "r21_endgame_levelselect_glow.papng",		// ENDGAMEBUTTON_LEVELSELECT
	"r21_endgame_retry_glow.papng",				// ENDGAMEBUTTON_RETRY
	"r21_endgame_progress_glow.papng",			// ENDGAMEBUTTON_ADVANCE
};

static const char* sCardPlacerFileName[R21UI_NUM] =
{
	"r21cp_poweredoff.papng",					// R21UI_PoweredOff
	"r21cp_startup.papng",						// R21UI_Startup
	"r21cp_confirmnotavailable.papng",			// R21UI_ConfirmNotAvailable
	"r21cp_confirmavailable.papng",				// R21UI_ConfirmAvailable
	"r21cp_inbetween.papng",					// R21UI_InBetweenStates
};

static const char* sLevelupHolderFilename       = "menu_levelup_holder.papng";
static const char* sLevelupMeterFilename        = "menu_levelup_meter.papng";
static const char* sDefaultProfilePictureName   = "defaultUser.papng";

static const NSString* sJumbotronTextureFilename = @"progress_run21.papng";

static const char* sEndGamePowerupCountersFiles[ENDGAME_POWERUP_NUM] =
{
#if USE_LIVES
    "levelselect_lives_projected.papng",
#endif
#if USE_TORNADOES
    "levelselect_tornado_projected.papng",
#endif
    "levelselect_xray_projected.papng"
};
static const char* sEndGamePowerupCountersGlow[ENDGAME_POWERUP_NUM] =
{
#if USE_LIVES
    "levelselect_lives_glow_projected.papng",
#endif
#if USE_TORNADOES
    "levelselect_tornado_glow_projected.papng",
#endif
    "levelselect_xray_glow_projected.papng"
};
static const char* sWhirlwindButtonFileName = "powerup_tornado_active.papng";
static const char* sWhirlwindBuyMoreFileName = "powerup_tornado_buymore.papng";
static const char* sWhirlwindButtonGlowFileName = "powerup_tornado_glow.papng";

static const char* sXRayButtonFileName          = "powerup_xray_active.papng";
static const char* sXRayBuyMoreFileName         = "powerup_xray_buymore.papng";
static const char* sXRayButtonGlowFileName      = "powerup_xray_glow.papng";
static const char* sXRayBuyMoreGlowFileName   = "powerup_xray_buymore_glow.papng";

static const char* sRunnerPrefix                = "Runner";

static const char* sSkipTutorialButtonFileName = "tutorial_skip.papng";
static const char* sSkipTutorialButtonGlowFileName = "tutorial_skip_glow.papng";

@implementation Run21UI

-(Run21UI*)InitWithEnvironment:(Run21Environment*)inEnvironment gameState:(GameRun21*)inGameRun21
{
	mEnvironment = inEnvironment;
    mGameRun21 = inGameRun21;
    
    memset(mRow, 0, sizeof(mRow));

    // Projected UI coordinate system
    GenerateTranslationMatrix(0.0, ([mEnvironment GetTableHeight] + EPSILON), 0.0, &mTableLTWTransform);
    
    Matrix44 rotationMatrix;
    GenerateRotationMatrix([mEnvironment GetTableRotationDegrees], 1.0f, 0.0f, 0.0f, &rotationMatrix);
    
    MatrixMultiply(&mTableLTWTransform, &rotationMatrix, &mTableLTWTransform);
	
    [self InitInterfaceGroups];
    [self InitPauseButton];

	[self InitNumCardsHolder];
	[self InitRunnerHolders];
	[self InitPlacer];
	[self InitScorerHolders];
    
    [self InitPowerupButtons];
    
    mJokers.status[CARDSUIT_JOKER_1] = JokerStatus_TableTurnedOff;
	mJokers.status[CARDSUIT_JOKER_2] = JokerStatus_TableTurnedOff;
    
    if ([[[Flow GetInstance] GetLevelDefinitions] GetJokersAvailable])
    {
        [self InitJokerHolders];
    }

	// By this being registered last it takes bottom priority. Disabling buttons above it does not seem to allow us to get clicked if we're overlapped.
    
	[self InitEndGameButtons];
    [self InitEndGamePowerupCounters]; 
	[self InitEndGameStars];
	[self InitEndGameLevelCard];    // This needs to be removed for Marathon.
    [self InitTabletScoreboard];
    [self InitJumbotron];

#if USE_LIVES
    [self InitLevelUpBar];
#endif

    // Set our interface mode
	[self InterfaceMode:R21UI_Startup];
    
    TutorialGameState* curState = (TutorialGameState*)[[GameStateMgr GetInstance] GetActiveState];
    
    if ((curState->mTutorialScript != NULL) && ([curState->mTutorialScript->mPhaseInfo count] > 0))
    {
        [self InitTutorialSkipButton];
    }
    
    [[(GameState*)[[GameStateMgr GetInstance] GetActiveState] GetMessageChannel] AddListener:self];
	
	// Finalize the interface
    [mUserInterface[UIGROUP_2D] Finalize];
    [mUserInterface[UIGROUP_Projected3D	] Finalize];
    
    mGameOver = FALSE;
    mTimerShakingPositionPath = NULL;
    mUIState = RUN21_UI_STATE_NORMAL;
    
	return self;
}

-(void)dealloc
{
    [[GameObjectManager GetInstance] Remove:mCardsLeft.strTextbox];
    [[GameObjectManager GetInstance] Remove:mPauseButton];
    [[GameObjectManager GetInstance] Remove:mAdButton];
    [[GameObjectManager GetInstance] Remove:mLevelUpBar.mProfilePic];
    [[GameObjectManager GetInstance] Remove:mXRayButton.mNumUsesText];
    [[GameObjectManager GetInstance] Remove:mWhirlwindButton.mNumUsesText];
    
    for ( int nHolder = 0 ; nHolder < NUMCARDSLEFT_NUM ; nHolder++ )
	{
        [[GameObjectManager GetInstance] Remove:mCardsLeft.images[nHolder]];
    }
    
    [mAdButton Remove];
    [mPauseButton Remove];
    [mTutorialSkipButton Remove];
	
    [super dealloc];
}

-(void)InitNumCardsHolder
{
	char		fileName[maxIconFileName];
	
	for ( int nHolder = 0 ; nHolder < NUMCARDSLEFT_NUM ; nHolder++ )
	{
		ImageWellParams imageWellparams;
		
		strncpy(fileName, sNumCardsLeftFileNames[nHolder], maxIconFileName );	
		[ImageWell InitDefaultParams:&imageWellparams];
		imageWellparams.mTextureName						= [NSString stringWithUTF8String:fileName];
		
		mCardsLeft.images[nHolder]	= [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
        [[GameObjectManager GetInstance] Add:mCardsLeft.images[nHolder] withRenderBin:RENDERBIN_UI];
		[mCardsLeft.images[nHolder]	SetPosition:&numCardsHolderLocation];
		[mCardsLeft.images[nHolder]	SetScaleX:0.050f Y:0.040f Z:1.0f];
		[mCardsLeft.images[nHolder]	SetProjected:TRUE];
		
		CloneMatrix44(&mTableLTWTransform, &mCardsLeft.images[nHolder]->mLTWTransform);
		[mCardsLeft.images[nHolder] release];
	}
    
    // Num Cards Textbox
    mCardsLeft.strTextbox = [self InitTextBoxWithFontColor:NEONFONT_YELLOW fontType:NEON_FONT_INVALID uiGroup:NULL];
    [[GameObjectManager GetInstance] Add:mCardsLeft.strTextbox withRenderBin:RENDERBIN_UI];
    [mCardsLeft.strTextbox SetProjected:TRUE];
    [mCardsLeft.strTextbox SetPosition:&numCardsTextLocation];
    [mCardsLeft.strTextbox SetOrientation:&numCardsRotation];
    [mCardsLeft.strTextbox SetScaleX:0.020f Y:0.020f Z:1.0f];
    
    CloneMatrix44(&mTableLTWTransform, &mCardsLeft.strTextbox->mLTWTransform);

	// Cards Status
	mCardsLeft.statusOfCardsLeft = NUMCARDSLEFT_Inactive;
}

-(void)InitScorerHolders
{
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
	for (int row = 0; row < numRunners; row++)
    {
		Vector3 textLoc;
		textLoc.mVector[x] = RUN21_UI_SCORE_X;
		textLoc.mVector[y] = RUN21_UI_SCORE_Y + [Run21UI GetRunnerYOrigin] + (row * [Run21UI GetRunnerSpacing]);
		textLoc.mVector[z] = 0.0f;
        
        if (numRunners > MAX_UNSCALED_RUNNERS)
        {
            textLoc.mVector[y] -= 0.1;
        }
        
		mRow[row].mTextBox = [self InitTextBoxWithFontColor:NEONFONT_BLUE uiGroup:mUserInterface[UIGROUP_Projected3D]];
        [mRow[row].mTextBox SetPosition:&textLoc];
        [mRow[row].mTextBox SetScaleX:0.025f Y:0.025f Z:1.0f];
        
        if (numRunners > MAX_UNSCALED_RUNNERS)
        {
            [mRow[row].mTextBox SetScaleX:0.020f Y:0.020f Z:1.0f];
        }

        CloneMatrix44(&mTableLTWTransform, &mRow[row].mTextBox->mLTWTransform);
	}
}

-(void)InitRunnerHolders
{
	NSMutableArray* textureFilenames = [[NSMutableArray alloc] initWithCapacity:RAS_NUM];
	
	for (int i = 0; i < RAS_NUM; i++)
	{
		NSString* curString = [NSString stringWithUTF8String:sRASFileNames[i]];
		[textureFilenames addObject:curString];
	}

    float spacing = [Run21UI GetRunnerSpacing];
    float origin = [Run21UI GetRunnerYOrigin];
    
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
	for ( int i = 0 ; i < numRunners ; i++ )
	{
		MultiStateButtonParams multiStateButtonParams;
		[MultiStateButton InitDefaultParams:&multiStateButtonParams];
		
		multiStateButtonParams.mButtonTextureFilenames = textureFilenames;
		multiStateButtonParams.mBoundingBoxCollision = TRUE;
		multiStateButtonParams.mUIGroup = mUserInterface[UIGROUP_Projected3D];
		
		mRow[i].mRunnerButton = [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&multiStateButtonParams];
		
		mRow[i].mRunnerButton->mIdentifier = i;
		[mRow[i].mRunnerButton SetVisible:TRUE];
		[mRow[i].mRunnerButton SetListener:self];
		[mRow[i].mRunnerButton SetProjected:TRUE];
		
		[mRow[i].mRunnerButton SetPositionX:RUNNER_ORIGIN_X Y:(origin + RUNNER_ORIGIN_Y + spacing * i) Z:RUNNER_ORIGIN_Z];
		[mRow[i].mRunnerButton SetScaleX:sRunnerScaler.mVector[x] Y:sRunnerScaler.mVector[y] Z:sRunnerScaler.mVector[z] ];
        
        if (numRunners > MAX_UNSCALED_RUNNERS)
        {
            [mRow[i].mRunnerButton SetScaleX:sRunnerScaler.mVector[x] Y:sRunnerScalerCompressedHeight Z:sRunnerScaler.mVector[z] ];
        }
		
		CloneMatrix44(&mTableLTWTransform, &mRow[i].mRunnerButton->mLTWTransform);

		[mRow[i].mRunnerButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
		[mRow[i].mRunnerButton release];
	}

	[textureFilenames release];
}

-(void)InitPlacer
{
	NSMutableArray* textureFilenames = [[NSMutableArray alloc] initWithCapacity:RAS_NUM];
	
	for (ERun21UIStatus i = 0; i < R21UI_NUM; i++)
	{
		NSString* curString = [NSString stringWithUTF8String:sCardPlacerFileName[i]];
		[textureFilenames addObject:curString];
	}
	
	MultiStateButtonParams multiStateButtonParams;
	[MultiStateButton InitDefaultParams:&multiStateButtonParams];
		
	multiStateButtonParams.mButtonTextureFilenames = textureFilenames;
	multiStateButtonParams.mBoundingBoxCollision = TRUE;
	multiStateButtonParams.mUIGroup = mUserInterface[UIGROUP_Projected3D];
		
	mPlacerButton = [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&multiStateButtonParams];
	
	[mPlacerButton SetVisible:TRUE];
	[mPlacerButton SetListener:self];
	[mPlacerButton SetProjected:TRUE];
		
	[mPlacerButton SetPosition:&PlacerHolderLocation];	// static Locations on i'th iterator
	[mPlacerButton SetScale:&PlacerScaleValue];

	CloneMatrix44(&mTableLTWTransform, &mPlacerButton->mLTWTransform);
	
	// Test for touchsystem.
	[mPlacerButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
    // Retained by UIGroup
    [mPlacerButton release];
    
	[textureFilenames release];
}

-(NeonButton*)InitNeonButtonWithTexture:(NSString*)texture withGlow:(NSString*)glow withPosition:(Vector3)inPos withScale:(Vector3)inScale
{
    //Setup the Use Button
    NeonButtonParams				buttonParams;
    [NeonButton InitDefaultParams:	&buttonParams];
    NeonButton* retval;
    
    buttonParams.mTexName					= texture;
    buttonParams.mToggleTexName             = texture;
    buttonParams.mPregeneratedGlowTexName	= glow;
    buttonParams.mBoundingBoxCollision		= TRUE;
    SetVec2(&buttonParams.mBoundingBoxBorderSize, 25, 25);
    buttonParams.mUIGroup					= mUserInterface[UIGROUP_Projected3D];
    
    retval				= [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
    
	[retval SetVisible:TRUE];
	[retval SetListener:self];
	[retval SetProjected:TRUE];
	[retval SetStringIdentifier:@"Powerup"];
    
    [retval SetPosition:&inPos];
	[retval SetScale:&inScale];
    CloneMatrix44(&mTableLTWTransform, &retval->mLTWTransform);
    
	// Test for touchsystem.
	[retval SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
    return retval;
}

-(void)PowerupButton:(PowerupButton)inButton withOn:(BOOL)isOn
{
    if (isOn)
    {
        [inButton.mBuyMoreButton SetAlpha:0.0];
        [inButton.mUseButton SetAlpha:1.0];
        [inButton.mNumUsesText SetAlpha:1.0];
    }
    else
    {
        [inButton.mUseButton SetAlpha:0.0];
        [inButton.mBuyMoreButton SetAlpha:1.0];
        [inButton.mNumUsesText SetAlpha:0.0];
    }
}

-(void)InitTornadoButton
{
    mWhirlwindButton.mNumUsesLeft = [[SaveSystem GetInstance] GetNumTornadoes];

    //Set up the buttons
    mWhirlwindButton.mUseButton = [self InitNeonButtonWithTexture:[NSString stringWithUTF8String:sWhirlwindButtonFileName] withGlow:[NSString stringWithUTF8String:sWhirlwindButtonGlowFileName] withPosition:sWhirlwindButtonLocation withScale:sTornadoScale];
    [mWhirlwindButton.mUseButton release];
    
    mWhirlwindButton.mBuyMoreButton = [self InitNeonButtonWithTexture:[NSString stringWithUTF8String:sWhirlwindBuyMoreFileName] withGlow:[NSString stringWithUTF8String:sWhirlwindButtonGlowFileName] withPosition:sWhirlwindButtonLocation withScale:sTornadoScale];
    [mWhirlwindButton.mBuyMoreButton release];
    
    //TODO: Change this to IAP ENUMS
    mWhirlwindButton.mConsumableType = 1;
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    
    tbParams.mMutable    = TRUE;
    tbParams.mFontType   = NEON_FONT_NORMAL;
    tbParams.mFontSize   = 24;
    tbParams.mWidth      = 0;
    tbParams.mStrokeSize = 10;
    tbParams.mMaxWidth  = 200;
    tbParams.mMaxHeight = 100;
	tbParams.mString = [NSString stringWithFormat:@""];
    SetColorFloat(&tbParams.mColor, 1.0, 1.0, 1.0, 1.0);
    SetColorFloat(&tbParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);
    
    mWhirlwindButton.mNumUsesText = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [[GameObjectManager GetInstance] Add:mWhirlwindButton.mNumUsesText];
    [mWhirlwindButton.mNumUsesText release];
    
    [mWhirlwindButton.mNumUsesText SetProjected:TRUE];
    [mWhirlwindButton.mNumUsesText SetPosition:&sWhirlwindNumUsesLocation];
    [mWhirlwindButton.mNumUsesText SetScale:&sWhirlwindNumUsesScaler];
    [mWhirlwindButton.mNumUsesText SetString:[NSString stringWithFormat:@"<B>%d</B>",mWhirlwindButton.mNumUsesLeft]];
    
    CloneMatrix44(&mTableLTWTransform, &mWhirlwindButton.mNumUsesText->mLTWTransform);
    
    [self PowerupButton:mWhirlwindButton withOn:mWhirlwindButton.mNumUsesLeft > 0];
    
    StringCloudParams* stringCloudParams = [[StringCloudParams alloc] init];
    
    stringCloudParams = [[StringCloudParams alloc] init];
    
    stringCloudParams->mUIGroup = mUserInterface[UIGROUP_2D];
    [stringCloudParams->mStrings addObject:@"<B>Tornadoes</B>"];
    [stringCloudParams->mStrings addObject:@"<B>Get More</B>"];
    [stringCloudParams->mStrings addObject:@"<B><color=0xFFE845>Tap Here!</color></B>"];
    stringCloudParams->mFontSize = 12.0f;
    
    mWhirlwindButton.mBuyMoreIndicator = [[StringCloud alloc] initWithParams:stringCloudParams];
    [mWhirlwindButton.mBuyMoreIndicator release];
    [stringCloudParams release];
    
    if (GetDeviceiPhoneTall())
    {
        [mWhirlwindButton.mBuyMoreIndicator SetPosition:&sTallTornadoBuyMoreIndicatorLocation];
    }
    else
    {
        [mWhirlwindButton.mBuyMoreIndicator SetPosition:&sTornadoBuyMoreIndicatorLocation];
    }
    
    [mWhirlwindButton.mBuyMoreIndicator SetVisible:FALSE];
}

-(void)InitXRayButton
{
    mXRayButton.mNumUsesLeft = [[SaveSystem GetInstance] GetNumXrays];

    //Set up the button
    mXRayButton.mUseButton = [self InitNeonButtonWithTexture:[NSString stringWithUTF8String:sXRayButtonFileName] withGlow:[NSString stringWithUTF8String:sXRayButtonGlowFileName] withPosition:sXRayButtonLocation withScale:sXrayScale];
    [mXRayButton.mUseButton release];
    
    mXRayButton.mBuyMoreButton = [self InitNeonButtonWithTexture:[NSString stringWithUTF8String:sXRayBuyMoreFileName] withGlow:[NSString stringWithUTF8String:sXRayBuyMoreGlowFileName] withPosition:sXRayButtonLocation withScale:sXrayScale];
    [mXRayButton.mBuyMoreButton release];
    
    //TODO: Change this to IAP ENUMS
    mXRayButton.mConsumableType = 2;
    
	TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    
    tbParams.mMutable    = TRUE;
    tbParams.mFontType   = NEON_FONT_NORMAL;
    tbParams.mFontSize   = 24;
    tbParams.mWidth      = 0;
    tbParams.mStrokeSize = 10;
    tbParams.mMaxWidth  = 200;
    tbParams.mMaxHeight = 100;
	tbParams.mString = [NSString stringWithFormat:@""];
    SetColorFloat(&tbParams.mColor, 1.0, 1.0, 1.0, 1.0);
    SetColorFloat(&tbParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);

	mXRayButton.mNumUsesText = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [[GameObjectManager GetInstance] Add:mXRayButton.mNumUsesText];
    [mXRayButton.mNumUsesText release];

    [mXRayButton.mNumUsesText SetProjected:TRUE];
    [mXRayButton.mNumUsesText SetPosition:&sXRayNumUsesLocation];
    [mXRayButton.mNumUsesText SetScale:&sXRayNumUsesScaler];
    [mXRayButton.mNumUsesText SetString:[NSString stringWithFormat:@"<B>%d</B>",mXRayButton.mNumUsesLeft]];
    
    CloneMatrix44(&mTableLTWTransform, &mXRayButton.mNumUsesText->mLTWTransform);
    
    [self PowerupButton:mXRayButton withOn:mXRayButton.mNumUsesLeft > 0];
    
    StringCloudParams* stringCloudParams = [[StringCloudParams alloc] init];
    
    stringCloudParams->mUIGroup = mUserInterface[UIGROUP_2D];
    [stringCloudParams->mStrings addObject:@"<B>X-Rays</B>"];
    [stringCloudParams->mStrings addObject:@"<B>Get More</B>"];
    [stringCloudParams->mStrings addObject:@"<B><color=0xFFE845>Tap Here!</color></B>"];
    stringCloudParams->mFontSize = 12.0f;
    
    mXRayButton.mBuyMoreIndicator = [[StringCloud alloc] initWithParams:stringCloudParams];
    [mXRayButton.mBuyMoreIndicator release];
    [stringCloudParams release];
    
    if (GetDeviceiPhoneTall())
    {
        [mXRayButton.mBuyMoreIndicator SetPosition:&sTallXRayBuyMoreIndicatorLocation];
    }
    else
    {
        [mXRayButton.mBuyMoreIndicator SetPosition:&sXRayBuyMoreIndicatorLocation];
    }
    
    [mXRayButton.mBuyMoreIndicator SetVisible:FALSE];
}

-(void)InitPowerupButtons
{
    BOOL xRayAvailable = [[[Flow GetInstance] GetLevelDefinitions] GetXrayAvailable];
    BOOL tornadoAvailable = [[[Flow GetInstance] GetLevelDefinitions] GetTornadoAvailable];

    if (tornadoAvailable)
    {
        [self InitTornadoButton];
    }

    if (xRayAvailable)
    {
        [self InitXRayButton];
    }
}

-(void)InitTutorialSkipButton
{
    NeonButtonParams				buttonParams;
    [NeonButton InitDefaultParams:	&buttonParams];
    
    buttonParams.mTexName					= [NSString stringWithUTF8String:sSkipTutorialButtonFileName];
    buttonParams.mToggleTexName             = [NSString stringWithUTF8String:sSkipTutorialButtonFileName];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:sSkipTutorialButtonGlowFileName];
    
    mTutorialSkipButton                     = [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
          
    [mTutorialSkipButton SetListener:self];
    [mTutorialSkipButton SetUsage:FALSE];
    [mTutorialSkipButton SetVisible:FALSE];
    
    [mTutorialSkipButton SetPosition:&sSkipTutorialButtonLocation];
    
    [[GameObjectManager GetInstance] Add:mTutorialSkipButton withRenderBin:RENDERBIN_FOREMOST];
    [mTutorialSkipButton release];
}

-(void)InitJumbotron
{
    MiniGameTableEntity *miniTable = mEnvironment->mTableEntity;
    GameObjectCollection* jumbotronCollection = [[miniTable GetJumbotronRenderGroup] GetGameObjectCollection];
    
    ImageWellParams imageWellparams;
    [ImageWell InitDefaultParams:&imageWellparams];
    imageWellparams.mTextureName = (NSString*)sJumbotronTextureFilename;
    
    ImageWell* imageWell = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
    
    [imageWell SetScale:&sJumbotronScaleValue];
    [imageWell SetProjected:FALSE];
    [imageWell SetVisible:TRUE];
    
    [jumbotronCollection Add:imageWell];
    [imageWell release];
    
    TextBoxParams textBoxParams;
    [TextBox InitDefaultParams:&textBoxParams];
    
    SetColorFloat(&textBoxParams.mColor, 1.0, 1.0, 1.0, 1.0);
    SetColorFloat(&textBoxParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);
    
    LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
    int numCards = [levelDefinitions GetNumCards];
    int numJokers = [levelDefinitions GetNumJokers];
    int timeLimit = [levelDefinitions GetTimeLimitSeconds];
    
    BOOL lowCards = FALSE;
    
    float fontSize = 36;
    float yOffset = 40;
    
    int numLines = 2;
    
    if (numJokers > 0)
    {
        numLines++;
    }
    
    if (timeLimit > 0)
    {
        numLines++;
    }
    
    mNumJumbotronRows = numLines;
    
    fontSize = sJumbotronFontSizes[numLines - 1];
    yOffset = sJumbotronSpacing[numLines - 1];
    
    LevelInfo* levelInfo = [levelDefinitions GetLevelInfo:[[Flow GetInstance] GetLevel]];
    
    if ((numCards != 0) && (!levelInfo.PrioritizeHighCards))
    {
        lowCards = TRUE;
    }
    
    int numSuits = 0;
    
    if (numCards == 0)
    {
        if ([levelDefinitions GetHearts])
        {
            numCards += CardLabel_NumStandard;
            numSuits++;
        }
        
        if ([levelDefinitions GetSpades])
        {
            numCards += CardLabel_NumStandard;
            numSuits++;
        }
        
        if ([levelDefinitions GetDiamonds])
        {
            numCards += CardLabel_NumStandard;
            numSuits++;
        }
        
        if ([levelDefinitions GetClubs])
        {
            numCards += CardLabel_NumStandard;
            numSuits++;
        }
        
        if ([levelDefinitions GetAddClubs])
        {
            numCards += CardLabel_NumStandard;
            numSuits++;
        }
    }
    
    TutorialGameState* curState = (TutorialGameState*)[[GameStateMgr GetInstance] GetActiveState];
    
    if (curState->mTutorialScript != NULL)
    {
        NSArray* shoeEntries = curState->mTutorialScript->mShoeEntries;
        
        for (ShoeEntry* curShoeEntry in shoeEntries)
        {
            if (curShoeEntry->mCardLabel == CardLabel_Joker)
            {
                numJokers++;
            }
        }
    }
    
    textBoxParams.mStrokeSize	= 4;
    textBoxParams.mString		= [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"LS_Level", NULL), ([[Flow GetInstance] GetLevel] + 1)];
    textBoxParams.mFontSize		= fontSize;
    textBoxParams.mFontType		= NEON_FONT_STYLISH;

    TextBox* textBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    [textBox SetPositionX:((JUMBOTRON_WIDTH - [textBox GetWidth]) / 2.0f) Y:10 Z:0.0];
    
    [jumbotronCollection Add:textBox];
    [textBox release];
    
    SetColorFloat(&textBoxParams.mColor, 1.0, 0.91, 0.27, 1.0);
    
    NSString* cardDescriptor = NULL;
    
    if ([levelDefinitions GetNumCards] != 0)
    {
        NSString* cardType = lowCards ? NSLocalizedString(@"LS_Low", NULL) : NSLocalizedString(@"LS_Random", NULL);
        cardDescriptor = [NSString stringWithFormat:@"<B>%d %@ %@</B>", numCards, cardType, NSLocalizedString(@"LS_Key_Cards", NULL)];
    }
    else
    {
        int numDecks = numSuits / 4;
        numSuits = numSuits % 4;
        
        NSString* deckString = NULL;
        NSString* suitString = NULL;
        
        if (numDecks > 1)
        {
            deckString = @"Decks";
        }
        else
        {
            deckString = @"Deck";
        }
        
        if (numSuits > 1)
        {
            suitString = @"Suits";
        }
        else
        {
            suitString = @"Suit";
        }
                
        if ((numDecks > 0) && (numSuits > 0))
        {
            cardDescriptor = [NSString stringWithFormat:@"<B>%d %@+%d %@ (%d Cards)</B>", numDecks, deckString, numSuits, suitString, numCards];
        }
        else if (numDecks > 0)
        {
            cardDescriptor = [NSString stringWithFormat:@"<B>%d %@ (%d Cards)</B>", numDecks, deckString, numCards];
        }
        else if (numSuits > 0)
        {
            cardDescriptor = [NSString stringWithFormat:@"<B>%d %@ (%d Cards)</B>", numSuits, suitString, numCards];
        }
    }
    
    textBoxParams.mString       = cardDescriptor;
    textBoxParams.mFontType		= NEON_FONT_NORMAL;
    
    textBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    [textBox SetPositionX:((JUMBOTRON_WIDTH - [textBox GetWidth]) / 2.0f) Y:(10 + yOffset) Z:0.0];
    
    [jumbotronCollection Add:textBox];
    [textBox release];
    
    if (numJokers > 0)
    {
        SetColorFloat(&textBoxParams.mColor, 1.0, 1.0, 1.0, 1.0);
        
        if (numJokers > 1)
        {
            textBoxParams.mString       = [NSString stringWithFormat:@"<B>%d Jokers</B>", numJokers];
        }
        else
        {
            textBoxParams.mString       = [NSString stringWithFormat:@"<B>%d Joker</B>", numJokers];
        }
        
        textBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
        [textBox SetPositionX:((JUMBOTRON_WIDTH - [textBox GetWidth]) / 2.0f) Y:(10 + 2 * yOffset) Z:0.0];
        
        [jumbotronCollection Add:textBox];
        [textBox release];
    }
    
    if (timeLimit > 0)
    {
        int minutes = timeLimit / 60;
        int seconds = timeLimit % 60;
        
        textBoxParams.mString       = [NSString stringWithFormat:@"<B>Time Left: %d:%d</B>", minutes, seconds];
        textBoxParams.mFontType		= NEON_FONT_NORMAL;
        SetColorFloat(&textBoxParams.mColor, 1.0, 0.91, 0.27, 1.0);
        
        mTimeRemaining = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
        [mTimeRemaining SetPositionX:((JUMBOTRON_WIDTH - [mTimeRemaining GetWidth]) / 2.0f) Y:(10 + 3 * yOffset) Z:0.0];
        
        [jumbotronCollection Add:mTimeRemaining];
        [mTimeRemaining release];
    }
    
    mUITimerState = UI_TIMERSTATE_NORMAL;
}

-(void)TutorialComplete
{
    [mTutorialSkipButton Disable];
}

+(float)GetRunnerHeight
{
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
    if (numRunners > MAX_UNSCALED_RUNNERS)
    {
        return (sRunnerScalerCompressedHeight / sRunnerScaler.mVector[y]) * RUNNER_OFFSET_Y;
    }
    
    return RUNNER_OFFSET_Y;
}

+(float)GetRunnerSpacing
{
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
    float numSpace = RUNNER_OFFSET_Y * MAX_UNSCALED_RUNNERS;
    float spacing = numSpace / (float)numRunners;

    return spacing;
}

+(float)GetRunnerYOrigin
{
    float spacing = [Run21UI GetRunnerSpacing];
    float origin = 0.5 * (spacing - (float)[Run21UI GetRunnerHeight]);

    return origin;
}

-(UIGroup*)GetEndGameUIGroup
{
    return mUserInterface[UIGROUP_Projected3D];
    // return mEndGameUIGroup;
}

-(ImageWell*)InitLevelUpImageWithFile:(const char *)imageFilename texture:(Texture*)inTexture withLocation:(Vector3*)loc uiGroup:(UIGroup*)inUIGroup
{
    ImageWellParams imageWellParams;
    ImageWell*      retval;
    
    [ImageWell InitDefaultParams:&imageWellParams];
    
    if (inTexture == NULL)
    {
        imageWellParams.mTextureName = [NSString stringWithUTF8String:imageFilename];
    }
    else
    {
        imageWellParams.mTexture = inTexture;
    }
    
    imageWellParams.mUIGroup		= inUIGroup;
    
    retval = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellParams];
    [retval SetPosition:loc];
    [retval SetScale:[self HackIsRetinaProjected] ? &sLevelBarHolderScaler : &x1_sLevelBarHolderScaler ];
    [retval SetProjected:TRUE];
    [retval	SetVisible:FALSE];
    CloneMatrix44(&mTableLTWTransform, &(retval->mLTWTransform));
    
    return retval;
}
-(void)InitLevelUpBar
{
    //init the level up bar holder
    mLevelUpBar.mHolder = [self InitLevelUpImageWithFile:sLevelupHolderFilename texture:NULL withLocation:&sLevelBarHolderLocation uiGroup:[self GetEndGameUIGroup]];
    [mLevelUpBar.mHolder release];
    
    //init the level up bar contents
    Vector3 levelBarMeterPos = { sLevelBarHolderLocation.mVector[x] + 2.4,
                                 sLevelBarHolderLocation.mVector[y] + 0.2,
                                 0.0 };
    
    Vector3 levelTextLoc = {    levelBarMeterPos.mVector[x] - 0.82,
                                levelBarMeterPos.mVector[y] - 0.10,
                                0.0 };
    
    mLevelUpBar.mMeter = [self InitLevelUpImageWithFile:sLevelupMeterFilename texture:NULL withLocation:&levelBarMeterPos uiGroup:[self GetEndGameUIGroup]];
    [mLevelUpBar.mMeter release];
    
    mLevelUpBar.mCurrentLevelText  = [self InitTextBoxWithFontColor:NEONFONT_YELLOW uiGroup:[self GetEndGameUIGroup]];
    [mLevelUpBar.mCurrentLevelText SetPosition:&levelTextLoc];
    [mLevelUpBar.mCurrentLevelText SetVisible:FALSE];
    CloneMatrix44(&mTableLTWTransform, &mLevelUpBar.mCurrentLevelText->mLTWTransform);
    

    levelTextLoc.mVector[x] += 5.41;
    mLevelUpBar.mNextLevelText  = [self InitTextBoxWithFontColor:NEONFONT_YELLOW uiGroup:[self GetEndGameUIGroup]];
    [mLevelUpBar.mNextLevelText SetPosition:&levelTextLoc];
    [mLevelUpBar.mNextLevelText	SetVisible:FALSE];
    CloneMatrix44(&mTableLTWTransform, &mLevelUpBar.mNextLevelText->mLTWTransform);
    
    mLevelUpBar.mProfilePic = [self InitLevelUpImageWithFile:sDefaultProfilePictureName texture:NULL withLocation:&sLevelBarHolderLocation uiGroup:NULL];
    [mLevelUpBar.mProfilePic SetScaleX:.040 Y:.040 Z:1.0];
    
    [self CalculateLevel];
}
-(void)ShowLevelUpBar:(BOOL)isOn
{
    [mLevelUpBar.mHolder            SetVisible:isOn];
    [mLevelUpBar.mMeter             SetVisible:isOn];

    [mLevelUpBar.mNextLevelText     SetVisible:mLevelUpBar.mCurrentLevel < MAX_PLAYER_LEVEL];
    [mLevelUpBar.mCurrentLevelText  SetVisible:isOn];
    
    [mLevelUpBar.mProfilePic        SetVisible:isOn];
    
}

// @TODO - Clean
-(void)CalculateLevel
{
    int currentLevel;
    float levelProgress;
    [ [ExperienceManager GetInstance] GetPlayerWithLevel:&currentLevel WithPercent:&levelProgress];
    mLevelUpBar.mCurrentLevel = currentLevel;

    //set the strings for the current and next level
    // @TODO: Handle max level.
    [mLevelUpBar.mNextLevelText     SetString:[NSString stringWithFormat:@"%d",currentLevel + 1]];
    [mLevelUpBar.mCurrentLevelText	SetString:[NSString stringWithFormat:@"%d",currentLevel]];
    
    //figure out the scaler for the meter
    mLevelUpBar.mPercentFilled = levelProgress;
    
    float meterScaleY =[self HackIsRetinaProjected] ? sLevelBarHolderScaler.mVector[1] : x1_sLevelBarHolderScaler.mVector[1];
    float meterScaleX = [self HackIsRetinaProjected] ? sLevelBarHolderScaler.mVector[0] : x1_sLevelBarHolderScaler.mVector[0];
    meterScaleX *= mLevelUpBar.mPercentFilled;
    [mLevelUpBar.mMeter SetScaleX:meterScaleX Y:meterScaleY Z:1.0];
}

-(BOOL)HackIsRetinaProjected
{
    // TODO: Doesn't iPad Native Retina, gives warning. ( Works though )
    return GetScreenRetina() || GetDevicePad();
}

-(void)InitEndGameLevelCard
{
    if ([[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21)
        return;
    
    int nLevelIndex = [[Flow GetInstance ] GetLevel];
    NSString* textureName = [LevelDefinitions GetCardTextureForLevel:nLevelIndex];
    
    ImageWellParams imageWellparams;
    [ImageWell InitDefaultParams:&imageWellparams];
    imageWellparams.mTextureName					= textureName;
    imageWellparams.mUIGroup						= mUserInterface[UIGROUP_Projected3D];
    
    mEndGameLevelCard.levelCard	= [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
    [mEndGameLevelCard.levelCard	SetPosition:&sLevelCardLocation];
    [mEndGameLevelCard.levelCard	SetScale: [self HackIsRetinaProjected] ? &sLevelCardScaler : &x1_sLevelCardScaler ];
    [mEndGameLevelCard.levelCard	SetProjected:TRUE];
    [mEndGameLevelCard.levelCard	SetVisible:FALSE];
    CloneMatrix44(&mTableLTWTransform,	&mEndGameLevelCard.levelCard->mLTWTransform);
    [mEndGameLevelCard.levelCard	release];

    // Full star
    ImageWellParams                     params;
    [ImageWell                          InitDefaultParams:&params];
    
    params.mTextureName					= [MainMenu fullStarFilenameForLevel:nLevelIndex];
    params.mUIGroup						= mUserInterface[UIGROUP_Projected3D];
    
    mEndGameLevelCard.fullStar	= [(ImageWell*)[ImageWell alloc] InitWithParams:&params];
    
    [mEndGameLevelCard.fullStar	SetPosition:&sLevelStarLocation];
    [mEndGameLevelCard.fullStar	SetScale:[self HackIsRetinaProjected] ? &sLevelStarScaler : &x1_sLevelStarScaler ];
    [mEndGameLevelCard.fullStar	SetProjected:TRUE];
    [mEndGameLevelCard.fullStar	SetVisible:FALSE];
    CloneMatrix44(&mTableLTWTransform, &mEndGameLevelCard.fullStar->mLTWTransform);
    [mEndGameLevelCard.fullStar release];
}

-(void)SetEndGamePowerupStrings
{
    SaveSystem* saveSystem = [SaveSystem GetInstance];
#if USE_LIVES
    [ mPowerupCounters[ENDGAME_POWERUP_LIVES].mNumLeft SetString: [NSString stringWithFormat:@"%d",[saveSystem GetNumLives] ]];
#endif
    [ mPowerupCounters[ENDGAME_POWERUP_TORNADO].mNumLeft SetString: [NSString stringWithFormat:@"%d",[saveSystem GetNumTornadoes] ]];
    [ mPowerupCounters[ENDGAME_POWERUP_XRAY].mNumLeft SetString: [NSString stringWithFormat:@"%d",[saveSystem GetNumXrays] ]];
    [ mTimeUntilNextLife SetString:[[RegenerationManager GetInstance] GetHealthRegenTimeString] ];
}

-(TextBox*)InitEndGamePowerupTextBoxWithPosition:(Vector3)position
{
    TextBox* retval;
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,		NEON_WHI );
    SetColorFromU32(&tbParams.mStrokeColor, NEON_BLA);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= @" ";
    tbParams.mFontSize		= 40;
    tbParams.mFontType		= NEON_FONT_STYLISH;
    tbParams.mWidth			= 480;
    tbParams.mMaxWidth      = 480;
    tbParams.mMaxHeight     = 128;
    tbParams.mMutable		= TRUE;                         // May need to remove the UI group for this to work.
    tbParams.mUIGroup       = mUserInterface[UIGROUP_Projected3D];
    
    retval   = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [retval SetVisible:FALSE];
    [retval SetPosition:&position];
    [retval SetScaleX:.0125 Y:.0125 Z:1.0];
    CloneMatrix44(&mTableLTWTransform, &retval->mLTWTransform);
    
    [retval release];
    
    return retval;
}

-(void)InitEndGamePowerupCounters
{
    //setup the buttons
    for ( int i = ENDGAME_POWERUP_FIRST ; i < ENDGAME_POWERUP_NUM ; i++ )
	{
		NeonButtonParams				buttonParams;
		[NeonButton InitDefaultParams:	&buttonParams];
		
		buttonParams.mTexName					= [NSString stringWithUTF8String:sEndGamePowerupCountersFiles[i]];
        buttonParams.mToggleTexName             = [NSString stringWithUTF8String:sEndGamePowerupCountersFiles[i]];
		buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:sEndGamePowerupCountersGlow[i]];
		
		buttonParams.mBoundingBoxCollision		= TRUE;
		buttonParams.mUIGroup					= mUserInterface[UIGROUP_Projected3D];
		
		mPowerupCounters[i].mButton				= [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
		      
		[mPowerupCounters[i].mButton			SetListener:self];
		[mPowerupCounters[i].mButton			SetProjected:TRUE];
		[mPowerupCounters[i].mButton			SetUsage:FALSE];

		
		[mPowerupCounters[i].mButton			SetPosition:&sEndGamePowerupCounterLocations[i]];
		[mPowerupCounters[i].mButton			SetScale:&sEndGamePowerupCounterScaler];
		CloneMatrix44							(&mTableLTWTransform, &mPowerupCounters[i].mButton->mLTWTransform);
		
		[mPowerupCounters[i].mButton			SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
		
		[mPowerupCounters[i].mButton						release];

        mPowerupCounters[i].mNumLeft = [self InitEndGamePowerupTextBoxWithPosition:sEndGamePowerupTextBoxLocations[i]];

	}
    
    Vector3 textLoc;
    textLoc.mVector[0] = -6.0;
    textLoc.mVector[1] = 3.1;
    textLoc.mVector[2] = 0.0;
    
    mTimeUntilNextLife = [self InitEndGamePowerupTextBoxWithPosition:textLoc];
    
    [self SetEndGamePowerupStrings];
}

-(void)InitEndGameStars
{
	// Todo use pointer to reduce copy/paste
	for ( int nStarNum = 0 ; nStarNum < MAX_PLAYER_HANDS; nStarNum++ )
	{
		for ( EStarStatus nStarStatus = STARSTATUS_FIRST ; nStarStatus <= STARSTATUS_LAST; nStarStatus++ )
		{
			char        fileName[maxIconFileName];
			int         nFileIndex = ( nStarStatus == STARSTATUS_FIRST ) ? 0 : 1;	// 0 == EMPTY, 1 = FILLED
            
            int         curLevel = [[Flow GetInstance] GetLevel];
            
            LevelSelectRoom room = ([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON) ? LEVELSELECT_ROOM_DIAMOND : [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:curLevel];
			
			switch ( room )
			{
				case LEVELSELECT_ROOM_BRONZE:
					snprintf(fileName, maxIconFileName, "starbronze_outcome_%d.papng"	, nFileIndex );	
					break;
				case LEVELSELECT_ROOM_SILVER:
					snprintf(fileName, maxIconFileName, "starsilver_outcome_%d.papng"	, nFileIndex );	
					break;
				case LEVELSELECT_ROOM_GOLD:
					snprintf(fileName, maxIconFileName, "stargold_outcome_%d.papng"		, nFileIndex );
					break;
                case LEVELSELECT_ROOM_EMERALD:
					snprintf(fileName, maxIconFileName, "staremerald_outcome_%d.papng"	, nFileIndex );
                    break;
                case LEVELSELECT_ROOM_SAPPHIRE:
                    snprintf(fileName, maxIconFileName, "starsapphire_outcome_%d.papng"	, nFileIndex );
                    break;
                case LEVELSELECT_ROOM_RUBY:
                    snprintf(fileName, maxIconFileName, "starruby_outcome_%d.papng"     , nFileIndex );
                    break;
                case LEVELSELECT_ROOM_DIAMOND:
					snprintf(fileName, maxIconFileName, "starshooting_outcome_%d.papng"	, nFileIndex );
					break;
				default:
					NSAssert(FALSE, @"Unsupported Large Star Type");
					return;
			}
            
            ImageWellParams imageWellparams;
			
			[ImageWell InitDefaultParams:&imageWellparams];
			imageWellparams.mTextureName					= [NSString stringWithUTF8String:fileName];
			imageWellparams.mUIGroup						= mUserInterface[UIGROUP_Projected3D]; 
			
			mEndGameStars[nStarNum].starImage[nStarStatus]	= [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
			[mEndGameStars[nStarNum].starImage[nStarStatus]	SetPositionX:ENDGAME_STAR_ORIGIN_X Y:(ENDGAME_STAR_ORIGIN_Y + [Run21UI GetRunnerYOrigin] + ([Run21UI GetRunnerSpacing] * (nStarNum))) Z:0.0];
			
            int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
            
            if (numRunners > MAX_UNSCALED_RUNNERS)
            {
                [mEndGameStars[nStarNum].starImage[nStarStatus] SetScaleX:sEndGameStarScaler.mVector[x] Y:sEndGameStarCompressedHeight Z:sEndGameStarScaler.mVector[z]];
            }
            else
            {
                [mEndGameStars[nStarNum].starImage[nStarStatus]	SetScale:&sEndGameStarScaler];
            }
            
            [mEndGameStars[nStarNum].starImage[nStarStatus]	SetProjected:TRUE];
			[mEndGameStars[nStarNum].starImage[nStarStatus]	SetVisible:FALSE];
			CloneMatrix44(&mTableLTWTransform,	&mEndGameStars[nStarNum].starImage[nStarStatus]->mLTWTransform);
			[mEndGameStars[nStarNum].starImage[nStarStatus]	release];
		}
	}
}

-(void)InitEndGameButtons
{
	for ( int i = ENDGAMEBUTTON_FIRST ; i <= ENDGAMEBUTTON_LAST ; i++ )
	{
		NeonButtonParams				buttonParams;
		[NeonButton InitDefaultParams:	&buttonParams];
		
		buttonParams.mTexName					= [NSString stringWithUTF8String:sEndGameButtonTextures[i]];
        buttonParams.mToggleTexName             = [NSString stringWithUTF8String:sEndGameButtonTextures[i]];
		buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:sEndGameButtonTextures_Glow[i]];
		
		buttonParams.mBoundingBoxCollision		= TRUE;
		buttonParams.mUIGroup					= mUserInterface[UIGROUP_Projected3D];
        
        buttonParams.mText = [NSString stringWithUTF8String:sEndGameButtonNames[i]];
        buttonParams.mTextSize = 16.0f;
        buttonParams.mFontType = NEON_FONT_NORMAL;
        SetAbsolutePlacement(&buttonParams.mTextPlacement, sEndGameButtonTextPositions[i].mVector[x], sEndGameButtonTextPositions[i].mVector[y]);
        SetColorFloat(&buttonParams.mTextColor, 1.0, 1.0, 1.0, 1.0);
        SetColorFloat(&buttonParams.mBorderColor, 0.0, 0.0, 0.0, 1.0);
        buttonParams.mBorderSize = 16.0f / GetTextScaleFactor();
		
		mEndGameButton[i]						= [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
		
		mEndGameButton[i]->mIdentifier			= ENDGAME_ID_OFFSET + i;

		[mEndGameButton[i]						SetListener:self];
		[mEndGameButton[i]						SetProjected:TRUE];
		[mEndGameButton[i]						SetUsage:FALSE];
		
		[mEndGameButton[i]						SetPosition:&sEndGameButtonLocations[i]];
		[mEndGameButton[i]						SetScale:&sEndGameButtonScaler];
		CloneMatrix44							(&mTableLTWTransform, &mEndGameButton[i]->mLTWTransform);
        
        mEndGameButton[i]->mForceTextureScale = TRUE;
		
		[mEndGameButton[i]						SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
		
		[mEndGameButton[i]						release];	
	}
}

-(void)InitInterfaceGroups
{
    [super uiAlloc];
	
	GameObjectBatchParams uiGroupParams;
    [GameObjectBatch InitDefaultParams:&uiGroupParams];
    uiGroupParams.mUseAtlas = TRUE;
    
    mUserInterface[UIGROUP_Projected3D] = [(UIGroup*)[UIGroup alloc] InitWithParams:&uiGroupParams];
    [[GameObjectManager GetInstance] Add:mUserInterface[UIGROUP_Projected3D]];
    [mUserInterface[UIGROUP_Projected3D] release];
    [mUserInterface[UIGROUP_Projected3D] SetProjected:TRUE];
    
    mUserInterface[UIGROUP_2D] = [(UIGroup*)[UIGroup alloc] InitWithParams:&uiGroupParams];
    [[GameObjectManager GetInstance] Add:mUserInterface[UIGROUP_2D]];
    [mUserInterface[UIGROUP_2D] release];

}

// @TODO - Make the Pause and AdButton 3D.
-(void)InitPauseButton
{
    float posX, posY;
    float extX, extY;
    
    // Create the Confirmation button
	TextureButtonParams				buttonParams;
    [TextureButton InitDefaultParams:&buttonParams];
    
    MiniGameTableEntity* miniTable = mEnvironment->mTableEntity;
    
    Matrix44* scoreboardTransform = [miniTable GetScoreboardTransform];
    
    // Create the Pause button
    buttonParams.mBoundingBoxCollision		= TRUE;
    posX									= 232;
    posY                                    = 7;
    
    buttonParams.mUISoundId					= SFX_MISC_PAUSE;
    
    mPauseButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
    [mPauseButton release];
    
    [mPauseButton SetListener:self];
    [mPauseButton SetPositionX:-0.3 Y:1.25f Z:0.46f];
    [mPauseButton SetVisible:TRUE];
    [mPauseButton SetProjected:TRUE];
    [mPauseButton SetScaleX:1.5f Y:1.5f Z:1.0f];
    CloneMatrix44(scoreboardTransform, &mPauseButton->mLTWTransform);
    
    [mPauseButton SetProxy:TRUE];
    
    [[GameObjectManager GetInstance] Add:mPauseButton];
    
    // Create the Ad button
	TextureButtonParams adbuttonParams;
    [TextureButton InitDefaultParams:&adbuttonParams];
    
    adbuttonParams.mBoundingBoxCollision	= TRUE;
	
    posX									= 175;
    posY                                    = 37;
    extX                                    = 0;
    extY                                    = 0;
    
    // TODO: This should be projected based on the Run21 LCD Image.
    if( GetDevicePad() )
    {
        posY-= 15;
        extX = 10;
        extY = 10;
    }
    if ( GetDeviceiPhoneTall() )
    {
        posY += 5;
        extX =  10;
        extY =  0;
    }
        
    
    //SetVec2(&adbuttonParams.mBoundingBoxBorderSize, extX, extY);    // doesn't seem to do anything.
    
    adbuttonParams.mUISoundId				= SFX_GLOBALUI_CARDCONFIRM;
    
    mAdButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&adbuttonParams];
    
    [[GameObjectManager GetInstance] Add:mAdButton];
    [mAdButton release];
    
    [mAdButton SetProjected:TRUE];
    
#if ENABLE_TABLET_AS_BUTTON
    [mAdButton SetListener:self];
    [mAdButton SetPositionX:-4.4f Y:4.0 Z:-2.5f];
    [mAdButton SetScaleX:8.8f Y:4.3f Z:1.0f];
    [mAdButton SetProxy:TRUE];
#else 
    [mAdButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
#endif
}

-(void)InitTabletScoreboard
{
}

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    [inButton EndPulse];
    
    if (inEvent == BUTTON_EVENT_UP)
    {
        {
            if( [mPlacerButton GetActiveIndex] == R21UI_ConfirmNotAvailable || [mPlacerButton GetActiveIndex] == R21UI_ConfirmAvailable)
            {
                if( inButton == mWhirlwindButton.mUseButton)
                {
                    [[GameStateMgr GetInstance] SendEvent:EVENT_USE_POWERUP withData:(void*)mWhirlwindButton.mConsumableType];
                    [self UpdatePowerupAmounts];
                }
                else if( inButton == mXRayButton.mUseButton)
                {
                    [[GameStateMgr GetInstance] SendEvent:EVENT_USE_POWERUP withData:(void*)mXRayButton.mConsumableType];
                }
                else if (inButton == mWhirlwindButton.mBuyMoreButton || inButton == mXRayButton.mBuyMoreButton)
                {
                    [[GameStateMgr GetInstance] SendEvent:EVENT_OPEN_STORE withData:NULL];
                }
            }
        }

        if (inButton == mTutorialSkipButton)
        {
            TutorialGameState* gameState = (TutorialGameState*)[[GameStateMgr GetInstance] GetActiveState];
            
            [gameState SkipTutorial];
            [mTutorialSkipButton Disable];
        }
        
		if ( inButton == mPauseButton )
		{
			[ [GameStateMgr GetInstance] Push:[PauseMenu alloc] ];
		}
#if ENABLE_TABLET_AS_BUTTON
        else if ( inButton == mAdButton )
        {
            MiniGameTableEntity *miniTable = mEnvironment->mTableEntity;
            
            if ( [miniTable IsScoreboardAdDisplaying] )
            {
                // Check AdvertisingManager for current URL
                #if NEONGAM_PHP_ENABLED
                AdvertisingManager *adMan = [AdvertisingManager GetInstance];
                [adMan SetTabletAd_Clicked_WithIndex:AD_AppStoreGame];
                [adMan NeonPHP_Call:ENeonJSONType_3_Click async:TRUE];
                #endif
                
                
                NSString        *adURLStr    = [ miniTable GetScoreboardAdURL];
                NSURL           *neonGamesUS = [ NSURL URLWithString:adURLStr];
                UIApplication   *neonApp     = [ UIApplication sharedApplication ];
                [ neonApp openURL:neonGamesUS ];
            }
        }
#endif
		else if ( inButton == mPlacerButton )
		{
			if ( [ mPlacerButton GetActiveIndex ] == R21UI_ConfirmAvailable ) 
            {
				[ [GameStateMgr GetInstance] SendEvent:EVENT_RUN21_CONFIRM withData:NULL ];
                return TRUE;
            }
            
            return FALSE;
		}
	}
	else if (inEvent == BUTTON_EVENT_DOWN)
	{
        BOOL runnerHit = FALSE;
        
        for (int i = 0; i < MAX_PLAYER_HANDS; i++)
        {
            if (inButton == mRow[i].mRunnerButton)
            {
                runnerHit = TRUE;
                break;
            }
        }
        
		if ( inButton == mEndGameButton[ENDGAMEBUTTON_LEVELSELECT]	||
			 inButton == mEndGameButton[ENDGAMEBUTTON_RETRY]		||
			 inButton == mEndGameButton[ENDGAMEBUTTON_ADVANCE]		)
		{
            if ((([[SaveSystem GetInstance] GetNumLives]) > 0) || (inButton == mEndGameButton[ENDGAMEBUTTON_LEVELSELECT]))
            {
                FaderParams faderParams;
                [Fader InitDefaultParams:&faderParams];
                
                faderParams.mDuration = RUN21_FADE_OUT_DURATION;
                faderParams.mFadeType = FADE_TO_BLACK_HOLD;
                faderParams.mCallback = self;
                faderParams.mCallbackObject = [NSNumber numberWithInt:inButton->mIdentifier];
                
                [[Fader GetInstance] StartWithParams:&faderParams];
                
                Message msg;
                
                msg.mId = EVENT_RUN21_PENDING_TERMINATE;
                msg.mData = NULL;
                
                [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];
            }
            else
            {
                [self FadeComplete:[NSNumber numberWithInt:inButton->mIdentifier]];
            }

        }
        else if (runnerHit)
		{
			// In the Gamestate, we need to switch over to deal card.
			if ( uiStatus == R21UI_ConfirmAvailable || uiStatus == R21UI_ConfirmNotAvailable  )
			{
				if ( RAS_BUSTED != mRow[inButton->mIdentifier].status && RAS_INACTIVE != mRow[inButton->mIdentifier].status )
				{
					[ [GameStateMgr GetInstance] SendEvent:EVENT_RUN21_PLACE_CARD withData:(void*)(inButton->mIdentifier) ];
				}
			}
		}	
	}
    //Check if the any of the endgame powerup counters were tapped
    for(int i = ENDGAME_POWERUP_FIRST; i < ENDGAME_POWERUP_NUM; i++)
    {
        if (inButton == mPowerupCounters[i].mButton)
        {
            [[GameStateMgr GetInstance] SendEvent:EVENT_OPEN_STORE withData:NULL];
        }
    }
    
    return TRUE;
}

-(HandStateMachineRun21*)GetHSM
{
	HandStateMachineRun21	*hsm					= [ mGameRun21 GetHSM ];
	
	return hsm;
}

-(void)Placer_UpdateStatus
{
    //NSLog(@"Setting placer button status to %d", uiStatus);

	[mPlacerButton SetActiveIndex:uiStatus];
}

-(void)InterfaceVisibleWithConfirm:(BOOL)bConfirmPlacement CardRows:(BOOL)bActiveRowsVisible CardsLeftHolder:(BOOL)bCardsLeftHolderVisible Scoreboard:(BOOL)bScoreboardVisible
{
	// If neither the confirm or row buttons are available, then the Pause shoudn't be either as we're in between something important.
	BOOL bAllowPause = (bConfirmPlacement || bActiveRowsVisible);
	
	[mPauseButton   SetUsage:bAllowPause];
    
#if ENABLE_TABLET_AS_BUTTON
    [mAdButton      SetUsage:TRUE]; // Tablet can be pressed unless it's tutorial
    [mAdButton      SetVisible:FALSE]; // Never display the actual ad button
#endif
    
    // Light the pause button only when the scoreboard lights up
    if ( bAllowPause )
       [mPauseButton SetVisible:FALSE];

	[mCardsLeft.strTextbox SetVisible:bCardsLeftHolderVisible];
	
	for (int i = 0 ; i < NUMCARDSLEFT_NUM ; i++ )
	{
		BOOL bEnableNumCards = FALSE;

		if ( bCardsLeftHolderVisible && mCardsLeft.statusOfCardsLeft == i )
		{
			bEnableNumCards = TRUE;
		}
		
		[ mCardsLeft.images[i] SetVisible:bEnableNumCards ];
	}
    
    BOOL active = TRUE;
    
    if (uiStatus == R21UI_InBetweenStates)
    {
        active = FALSE;
    }
    
    for (int i = 0; i < ENDGAMEBUTTON_NUM; i++)
    {
        if ([mEndGameButton[i] GetVisible])
        {
            [mEndGameButton[i] SetActive:active];
        }
    }
    
    for (int i = ENDGAME_POWERUP_FIRST; i < ENDGAME_POWERUP_NUM; i++)
    {
        if ([mPowerupCounters[i].mButton GetVisible])
        {
            [mPowerupCounters[i].mButton SetActive:active];
        }
        
        if ([mPowerupCounters[i].mNumLeft GetVisible])
        {
            [mPowerupCounters[i].mNumLeft SetActive:active];
        }
    }
}

-(void)InterfaceMode:(ERun21UIStatus)status
{
	uiStatus = status;
	
	[ self Placer_UpdateStatus ];
	
	switch ( uiStatus )
	{
		case R21UI_PoweredOff:
			[self InterfaceVisibleWithConfirm:FALSE CardRows:FALSE	CardsLeftHolder:TRUE	Scoreboard:TRUE ];
			break;
			
		// Eventually Light up everything over a period of time randomly.
		case R21UI_Startup:
			[self InterfaceVisibleWithConfirm:FALSE CardRows:FALSE	CardsLeftHolder:TRUE	Scoreboard:TRUE ];
			break;
		
		// Todo: Discern between the placer and the rows.
		case R21UI_ConfirmAvailable:
			[self InterfaceVisibleWithConfirm:TRUE	CardRows:TRUE	CardsLeftHolder:TRUE	Scoreboard:TRUE ];
			break;
			
		case R21UI_ConfirmNotAvailable:
			[self InterfaceVisibleWithConfirm:FALSE CardRows:TRUE	CardsLeftHolder:TRUE	Scoreboard:TRUE ];
			break;
			
		case R21UI_InBetweenStates:
			[self RAS_DeselectAll ];
			[self InterfaceVisibleWithConfirm:FALSE CardRows:FALSE	CardsLeftHolder:TRUE	Scoreboard:TRUE ];
			break;
			
		default:
			NSAssert(FALSE, @"Run21UI::InterfaceMode - Invalid status enumeration");
			
	}
}

-(void)UpdateJokerHolders
{
	int		i;
	BOOL	bVisible;
	
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		if ( mJokers.status[CARDSUIT_JOKER_1] == i )
			bVisible = TRUE;
		else
			bVisible = FALSE;

		[mJokers.imageSlot1[i] SetVisible:bVisible];
		[mJokers.holderSlot1[i] SetVisible:bVisible];
	}
	
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		if ( mJokers.status[CARDSUIT_JOKER_2] == i )
			bVisible = TRUE;
		else
			bVisible = FALSE;
		
		[mJokers.imageSlot2[i] SetVisible:bVisible];
		[mJokers.holderSlot2[i] SetVisible:bVisible];
	}
	
}

-(void)CardsLeftWith:(int)nCardsLeft
{
	if ( nCardsLeft >= 0 )
	{
		TextBoxParams newParams;
		[mCardsLeft.strTextbox InitFromExistingParams:&newParams];
		newParams.mString = [NSString stringWithFormat:@"%d" , nCardsLeft ];
		[mCardsLeft.strTextbox SetParams:&newParams];
        
        // If we're down to single digit cards, tweak the textbox position
        if (nCardsLeft <= 9)
        {
            [mCardsLeft.strTextbox SetPosition:&numCardsTextLocationSingleDigit];
        }
        else
        {
            [mCardsLeft.strTextbox SetPosition:&numCardsTextLocation];
        }
	}
}

-(void)JokerStatus:(EJokerStatus)joker1 JokerStatus2:(EJokerStatus)joker2
{
	mJokers.status[CARDSUIT_JOKER_1] = joker1;
	mJokers.status[CARDSUIT_JOKER_2] = joker2;
	[self UpdateJokerHolders];
}

-(void)PlayerDecisionForHand:(PlayerHand*)inHand handIndex:(int)inHandIndex remainingCards:(int)inRemainingCards JokerStatus1:(EJokerStatus)joker1 JokerStatus2:(EJokerStatus)joker2
{
	[self JokerStatus:joker1 JokerStatus2:joker2 ];
	[self CardsLeftWith:inRemainingCards ];
    
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
	
	if ((inHand != NULL) && (inHandIndex != numRunners))
    {
        NSAssert(inHandIndex >= 0 && inHandIndex < MAX_PLAYER_HANDS, @"Invalid card index");
		
		[ self RAS_DeselectAll ];

		if ( RAS_BUSTED != mRow[inHandIndex].status )
		{
			int handScore = [CardManager FinalScoreWithHand:inHand];
			ERowActiveState RASStatus = RAS_INACTIVE;
			
			// Jokers automatically cause a hand to be valued at 21.
			if ( [ [ CardManager GetInstance] HasJokerWithHand:inHand ] )
				handScore = 21;
			
			// Charlies occur when you have less than 21 points, and 5 or more cards, and use a $$ instead of the actual score
			if ( handScore < 21 && [inHand count] >= 5  )
			{
				// Charlie
				RASStatus = RAS_WILLCLEAR;
				[ mRow[inHandIndex].mTextBox SetString:[NSString stringWithFormat:@"$$"] ];
                
                [[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_CHARLIE_DISPLAYED withData:NULL];
			}
			else
			{
				// Check for bust
				if ( handScore > 21 )
				{
					RASStatus = RAS_WILLBUST;
				}
				// Check for 21, which 
				else if ( handScore == 21 )
				{
					RASStatus = RAS_WILLCLEAR;
				}
				// Treat as if we were selected ( make any previous selected hands as simply available.
				else
				{
					RASStatus = RAS_SELECTED;
				}
				
				// Otherwise we are available. ( May need to see if we're in an unavailable state ala InterfaceMode:R21UI_InBetweenStates
				[ mRow[inHandIndex].mTextBox SetString:[NSString stringWithFormat:@"%d", handScore] ];
			}	
			
			[ self UpdateRASStatusWithRow:inHandIndex Status:RASStatus ];
		}
    }
    
}

-(void)InitJokerHolders
{
	int				i;
	char			fileName[maxIconFileName];
	ImageWellParams imageWellparams;
	
	// Todo use pointer to reduce copy/paste
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		strncpy(fileName, sJokerFileNames[i], maxIconFileName );
		[ImageWell InitDefaultParams:&imageWellparams];
		imageWellparams.mTextureName	= [NSString stringWithUTF8String:fileName];
		imageWellparams.mUIGroup		= mUserInterface[UIGROUP_Projected3D];
		
		mJokers.imageSlot1[i]			=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
		[mJokers.imageSlot1[i]			SetPosition:&Joker1ImageLocation];
		[mJokers.imageSlot1[i]			SetScale:&sJokerScale];
		[mJokers.imageSlot1[i]			SetProjected:TRUE];
		[mJokers.imageSlot1[i]			SetVisible:FALSE];
		CloneMatrix44(&mTableLTWTransform, &mJokers.imageSlot1[i]->mLTWTransform);
		[mJokers.imageSlot1[i]			release];
	}
	
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		strncpy(fileName, sJokerHolderFileNames[i], maxIconFileName );
		[ImageWell InitDefaultParams:&imageWellparams];
		imageWellparams.mTextureName	= [NSString stringWithUTF8String:fileName];
		imageWellparams.mUIGroup		= mUserInterface[UIGROUP_Projected3D];
		
		mJokers.holderSlot1[i]			=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
		[mJokers.holderSlot1[i]			SetPosition:&Joker1HolderLocation];
		[mJokers.holderSlot1[i]			SetScale:&sJokerScale];
		[mJokers.holderSlot1[i]			SetProjected:TRUE];
		[mJokers.holderSlot1[i]			SetVisible:FALSE];
		CloneMatrix44(&mTableLTWTransform, &mJokers.holderSlot1[i]->mLTWTransform);
		[mJokers.holderSlot1[i]			release];
	}
		 
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		strncpy(fileName, sJokerFileNames[i], maxIconFileName );
		[ImageWell InitDefaultParams:&imageWellparams];
		imageWellparams.mTextureName	= [NSString stringWithUTF8String:fileName];
		imageWellparams.mUIGroup		= mUserInterface[UIGROUP_Projected3D];
		 
		mJokers.imageSlot2[i]			=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
		[mJokers.imageSlot2[i]			SetPosition:&Joker2ImageLocation];
		[mJokers.imageSlot2[i]			SetScale:&sJokerScale];
		[mJokers.imageSlot2[i]			SetProjected:TRUE];
		[mJokers.imageSlot2[i]			SetVisible:FALSE];
		CloneMatrix44(&mTableLTWTransform, &mJokers.imageSlot2[i]->mLTWTransform);
		[mJokers.imageSlot2[i]			release];
	}
	
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		strncpy(fileName, sJokerHolderFileNames[i], maxIconFileName );
		[ImageWell InitDefaultParams:&imageWellparams];
		imageWellparams.mTextureName	= [NSString stringWithUTF8String:fileName];
		imageWellparams.mUIGroup		= mUserInterface[UIGROUP_Projected3D];
		
		mJokers.holderSlot2[i]			=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
		[mJokers.holderSlot2[i]			SetPosition:&Joker2HolderLocation];
		[mJokers.holderSlot2[i]			SetScale:&sJokerScale];
		[mJokers.holderSlot2[i]			SetProjected:TRUE];
		[mJokers.holderSlot2[i]			SetVisible:FALSE];
		CloneMatrix44(&mTableLTWTransform, &mJokers.holderSlot2[i]->mLTWTransform);
		[mJokers.holderSlot2[i]			release];
	}
	
	[ self UpdateJokerHolders];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    BOOL timedLevel = [[[Flow GetInstance] GetLevelDefinitions] GetTimeLimitSeconds] > 0;
    
    if (timedLevel)
    {
        CFTimeInterval timeRemaining = [[mGameRun21 GetHSM] GetTimeRemaining];
        int minutes = (int)timeRemaining / 60;
        int seconds = (int)timeRemaining % 60;
        
        if ((mUITimerState == UI_TIMERSTATE_NORMAL) || ([mTimeRemaining AnyPropertyIsAnimating]))
        {
            [mTimeRemaining SetString:[NSString stringWithFormat:@"<B>Time Left: %d:%02d</B>", minutes, seconds]];
        }
        else
        {
            TextBoxParams textBoxParams;
            [mTimeRemaining InitFromExistingParams:&textBoxParams];
            
            if (timeRemaining > sCriticalTime)
            {
                timeRemaining = sCriticalTime;
            }
            
            float criticalTimeRatio = (sCriticalTime - timeRemaining) / sCriticalTime;
            
            float g = 0.91 * (1.0 - criticalTimeRatio);
            float b = 0.27 * (1.0 - criticalTimeRatio);
            
            SetColorFloat(&textBoxParams.mColor, 1.0, g, b, 1.0);
            
            textBoxParams.mString = [NSString stringWithFormat:@"<B>Time Left: %d:%02d</B>", minutes, seconds];
            [mTimeRemaining SetParams:&textBoxParams];
        }
        
        int normalX = ((JUMBOTRON_WIDTH - [mTimeRemaining GetWidth]) / 2.0f);
        int normalY = (10 + (mNumJumbotronRows - 1) * sJumbotronFontSizes[mNumJumbotronRows - 1]);
        
        int criticalX = ((JUMBOTRON_WIDTH / 2) - [mTimeRemaining GetWidth]);
        int criticalY = ((JUMBOTRON_HEIGHT / 4) - [mTimeRemaining GetHeight]);
        
        if ((timeRemaining < sCriticalTime) && (mUITimerState == UI_TIMERSTATE_NORMAL))
        {
            MiniGameTableEntity *miniTable = mEnvironment->mTableEntity;
            GameObjectCollection* jumbotronCollection = [[miniTable GetJumbotronRenderGroup] GetGameObjectCollection];

            int numObjects = [jumbotronCollection GetSize];
            
            for (int i = 0; i < numObjects; i++)
            {
                GameObject* curObject = [jumbotronCollection GetObject:i];
                
                if ((curObject != mTimeRemaining) && ([curObject class] == [TextBox class]))
                {
                    [(UIObject*)curObject Disable];
                }
            }
            
            Path* scalePath = [[Path alloc] Init];
            
            [scalePath AddNodeX:1.0 y:1.0 z:1.0 atTime:0.0];
            [scalePath AddNodeX:2.0 y:2.0 z:1.0 atTime:1.0];
            
            [mTimeRemaining AnimateProperty:GAMEOBJECT_PROPERTY_SCALE withPath:scalePath];
            [scalePath release];
            
            Path* positionPath = [[Path alloc] Init];
            
            [positionPath AddNodeX:normalX y:normalY z:1.0 atTime:0.0];
            [positionPath AddNodeX:criticalX y:criticalY z:1.0 atTime:1.0];
            
            [mTimeRemaining AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:positionPath];
            [positionPath release];
            
            mUITimerState = UI_TIMERSTATE_CRITICAL;
            
            mTimerShakingPositionPath = [[Path alloc] Init];
            
            [mTimerShakingPositionPath AddNodeX:0.0 y:0.0 z:0.0 atTime:0.0];
            [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:0.25];
            [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:0.75];
            [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:1.25];
            [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:1.75];
            [mTimerShakingPositionPath AddNodeX:0.0 y:0.0 z:0.0 atTime:2.0];
            
            [[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_CRITICAL_TIME withData:NULL];
        }
        
        if (mUITimerState == UI_TIMERSTATE_NORMAL)
        {
            [mTimeRemaining SetPositionX:normalX Y:normalY Z:0.0];
        }
        else
        {
            if (![mTimeRemaining AnyPropertyIsAnimating])
            {
                if (timeRemaining > sCriticalTime)
                {
                    timeRemaining = sCriticalTime;
                }
                
                float criticalTimeScale = 1.0 + (sCriticalTime - timeRemaining) / 7.0f;
                [mTimerShakingPositionPath Update:(inTimeStep * criticalTimeScale)];
                
                Vector3 offset;
                [mTimerShakingPositionPath GetValueVec3:&offset];

                float criticalPositionScale = 1.0 + (sCriticalTime - timeRemaining) / 12.0f;
                
                [mTimeRemaining SetPositionX:criticalX + criticalPositionScale * offset.mVector[x] Y:criticalY + criticalPositionScale * offset.mVector[y] Z:0.0];
                
                if ([mTimerShakingPositionPath Finished])
                {
                    [mTimerShakingPositionPath Reset];
                    [mTimerShakingPositionPath AddNodeX:0.0 y:0.0 z:0.0 atTime:0.0];
                    [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:0.25];
                    [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:0.75];
                    [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:1.25];
                    [mTimerShakingPositionPath AddNodeX:RandFloat(-5.0, 5.0) y:RandFloat(-5.0, 5.0) z:0.0 atTime:1.75];
                    [mTimerShakingPositionPath AddNodeX:0.0 y:0.0 z:0.0 atTime:2.0];
                }
            }
        }
    }
    
    switch(mUIState)
    {
        case RUN21_UI_STATE_WAITING_TO_AUTOEXIT:
        {
            mTimeRemainingUntilAutoExit -= inTimeStep;
            
            if (mTimeRemainingUntilAutoExit < 0.0)
            {
                Message msg;
                
                msg.mId = EVENT_RUN21_END_OPTION_SELECTED;
                msg.mData = (void*)(ENDGAMEBUTTON_LEVELSELECT + ENDGAME_ID_OFFSET);
                
                [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];

            }
            
            break;
        }
    }
}

-(void)TogglePause:(BOOL)bSuspend
{
	if ( bSuspend )
	{
		restoredUIStatus = uiStatus;
		[ self InterfaceMode:R21UI_InBetweenStates ];
	}
	else
	{
		[ self InterfaceMode:restoredUIStatus ];
		restoredUIStatus = R21UI_NUM;
        
        mWhirlwindButton.mNumUsesLeft = [[SaveSystem GetInstance] GetNumTornadoes];
        if (mWhirlwindButton.mNumUsesLeft > 0)
        {
            [self PowerupButton:mWhirlwindButton withOn:TRUE];
            [mWhirlwindButton.mNumUsesText SetString: [NSString stringWithFormat:@"%d",mWhirlwindButton.mNumUsesLeft]];
        }
        
        mXRayButton.mNumUsesLeft = [[SaveSystem GetInstance] GetNumXrays];

        BOOL xRayUnlockLevel = [[[Flow GetInstance] GetLevelDefinitions] GetXrayUnlockLevel];
        BOOL showXray = [[Flow GetInstance] GetLevel] >= xRayUnlockLevel;
        
        if ((mXRayButton.mNumUsesLeft > 0) && (showXray))
        {
            [self PowerupButton:mXRayButton withOn:TRUE];
            
            [self GetHSM].xrayActive = TRUE;
            [mXRayButton.mNumUsesText SetString: [NSString stringWithFormat:@"%d",mXRayButton.mNumUsesLeft]];
            [mXRayButton.mBuyMoreIndicator SetVisible:FALSE];
        }
        else
        {
            if ((!mGameOver) && (showXray))
            {
                [mXRayButton.mBuyMoreIndicator SetVisible:TRUE];
            }
        }
        
        BOOL tornadoUnlockLevel = [[[Flow GetInstance] GetLevelDefinitions] GetTornadoUnlockLevel];
        BOOL showTornado = [[Flow GetInstance] GetLevel] >= tornadoUnlockLevel;
        
        if ((mWhirlwindButton.mNumUsesLeft > 0) && (showTornado))
        {
            [self PowerupButton:mWhirlwindButton withOn:TRUE];
            [mWhirlwindButton.mNumUsesText SetString:[NSString stringWithFormat:@"%d",mWhirlwindButton.mNumUsesLeft]];
            [mWhirlwindButton.mBuyMoreIndicator SetVisible:FALSE];
        }
        else
        {
            if ((!mGameOver) && (showTornado))
            {
                [mWhirlwindButton.mBuyMoreIndicator SetVisible:TRUE];
            }
        }
        
        if (mGameOver)
        {
            [self EndGamePreClear];
        }
    }
}

-(void)DeactivateRow:(int)nButtonID
{
	[ self UpdateRASStatusWithRow:(nButtonID) Status:RAS_BUSTED ];
}

-(void)RAS_DeselectAll
{
	for ( int i = 0 ; i < MAX_PLAYER_HANDS ; i++ )
	{
		if ( RAS_SELECTED == mRow[i].status )
			[ self UpdateRASStatusWithRow:i Status:RAS_AVAILABLE ];
	}

}

-(void)UpdateRASStatusWithRow:(int)nRowID Status:(ERowActiveState)inStatus
{
	mRow[nRowID].status = inStatus;
	[mRow[nRowID].mRunnerButton SetActiveIndex:inStatus];

	// Don't draw the score if we are busted or inactive.
	if ( inStatus == RAS_BUSTED || inStatus == RAS_INACTIVE )
	{
		[ mRow[nRowID].mTextBox SetString:[NSString stringWithFormat:@""] ];
	}

}

-(void)UpdateNumCardsStatus:(ENumCardsLeftHolderStatus)status
{
	// Play stinger based on status change.
	if ( status != mCardsLeft.statusOfCardsLeft )
	{
		mCardsLeft.statusOfCardsLeft = status;
		
		switch ( status )
		{
			case NUMCARDSLEFT_Inactive:
				break;
			case NUMCARDSLEFT_ClubsRemove:
				[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_CLEARING_CLUBS withData:NULL];
				break;
			case NUMCARDSLEFT_DealRainbow:
				[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_RUNNING_RAINBOW withData:NULL];
				break;
			case NUMCARDSLEFT_PlayerActive:
				[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_PLAYER_PHASE withData:NULL];
				break;
			case NUMCARDSLEFT_SuddenDeath:
				[[GameStateMgr GetInstance] SendEvent:EVENT_RUN21_SUDDEN_DEATH withData:NULL];
				break;
		}
	}
}

-(BOOL)IsInStatus:(ENumCardsLeftHolderStatus)status
{
	return status == mCardsLeft.statusOfCardsLeft;
}

-(NSMutableArray*)GetButtonArray
{
    NSMutableArray* retArray = [NSMutableArray array];
    
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
    for (int i = 0; i < numRunners; i++)
    {
        [retArray addObject:mRow[i].mRunnerButton];
    }
    
    if (mWhirlwindButton.mUseButton != NULL)
    {
        [retArray addObject:mWhirlwindButton.mUseButton];
    }
    
    if (mWhirlwindButton.mBuyMoreButton)
    {
        [retArray addObject:mWhirlwindButton.mBuyMoreButton];
    }
    
    if (mXRayButton.mUseButton != NULL)
    {
        [retArray addObject:mXRayButton.mUseButton];
    }
    
    if (mXRayButton.mBuyMoreButton != NULL)
    {
        [retArray addObject:mXRayButton.mBuyMoreButton];
    }
    
    [retArray addObject:mPlacerButton];
    [retArray addObject:mAdButton];
    
    return retArray;
}

-(BOOL)IsRunner:(UIObject*)inObject
{
    NSString* identifier = [inObject GetStringIdentifier];
    
    if (strstr([identifier UTF8String], sRunnerPrefix) != NULL)
    {
        return TRUE;
    }
    
    return FALSE;
}

-(void)MarathonClearStars
{
    for ( int nHand = 0 ; nHand < MAX_PLAYER_HANDS ; nHand++ )
	{
		[ mEndGameStars[nHand].starImage[STARSTATUS_NOTAWARDED ] SetVisible:FALSE];
        [ mEndGameStars[nHand].starImage[STARSTATUS_AWARDED    ] SetVisible:FALSE];
        
        //[ mRow[i].mTextBox SetString:[NSString stringWithFormat:@""] ];
	}
    
    // Set the game's UI mode back to active.
}

-(void)EndGameClearRow:(int)nRow
{
    BOOL bShowFullStar;
    
    if ( mRow[nRow].status != RAS_BUSTED )
	{
        [self UpdateRASStatusWithRow:nRow Status:RAS_WILLCLEAR];
        
        [UISounds PlayUISound:SFX_STINGER_21SQUARED_COMPLETED_COLUMN];
        bShowFullStar = TRUE;
    }
    else
    {
        [self UpdateRASStatusWithRow:nRow Status:RAS_WILLBUST];
        [UISounds PlayUISound:SFX_BLACKJACK_STAND];
        bShowFullStar = FALSE;
    }
    
    [ mRow[nRow].mTextBox SetString:[NSString stringWithFormat:@""] ];
    
    [mEndGameStars[nRow].starImage[STARSTATUS_NOTAWARDED ]	SetVisible:!bShowFullStar];
    [mEndGameStars[nRow].starImage[STARSTATUS_AWARDED	 ]	SetVisible: bShowFullStar];
    
}

-(void)ResetGameMarathon
{
    int i;
    // Turn on the Placer
	[mPlacerButton SetUsage:TRUE];
	[mPlacerButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
    
    // Turn on the Jokers
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		[mJokers.imageSlot1[i]		SetVisible:TRUE];
		[mJokers.holderSlot1[i]		SetVisible:TRUE];
		
		[mJokers.imageSlot2[i]		SetVisible:TRUE];
		[mJokers.holderSlot2[i]		SetVisible:TRUE];
	}
    
    // Turn on the Cards Left and Text
    for ( i = 0; i < NUMCARDSLEFT_NUM ; i++ )
    {
        [ mCardsLeft.images[i] SetVisible:TRUE ];
    }
    [ mCardsLeft.strTextbox SetVisible:TRUE ];
}

-(void)EndGamePreClear
{
    int i;
    // Turn off the Placer
	[mPlacerButton SetUsage:FALSE];
	[mPlacerButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
    
    // Turn off the Jokers
	for ( i = 0 ; i < JokerStatus_MAX; i++ )
	{
		[mJokers.imageSlot1[i]		SetVisible:FALSE];
		[mJokers.holderSlot1[i]		SetVisible:FALSE];
		
		[mJokers.imageSlot2[i]		SetVisible:FALSE];
		[mJokers.holderSlot2[i]		SetVisible:FALSE];
	}
    
    // Turn off the Cards Left and Text
    for ( i = 0; i < NUMCARDSLEFT_NUM ; i++ )
    {
        [ mCardsLeft.images[i] SetVisible:FALSE ];
    }
    [ mCardsLeft.strTextbox SetVisible:FALSE ];
    
    // Create a level select card and score.
}

-(void)EndGameWithWin:(BOOL)bWonGame WithHiScore:(BOOL)bHiScore WithStars:(int)nStars
{
    mGameOver = TRUE;
	
		// If out of order, the Score holder doesn't go gray.
	[ self UpdateNumCardsStatus:NUMCARDSLEFT_Inactive ];

	for ( int nHand = 0 ; nHand < MAX_PLAYER_HANDS ; nHand++ )
	{
		[ self UpdateRASStatusWithRow:nHand Status:RAS_INACTIVE ];
		
		[ mRow[nHand].mRunnerButton SetUsage:FALSE ];
		[ mRow[nHand].mRunnerButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
        
        [ mEndGameStars[nHand].starImage[STARSTATUS_NOTAWARDED ] SetVisible:FALSE];
        [ mEndGameStars[nHand].starImage[STARSTATUS_AWARDED    ] SetVisible:FALSE];

	}
		
	
	[ self InterfaceMode:R21UI_PoweredOff ];
	[ self RAS_DeselectAll ];
		// Keep this order.
	
	// Turn off the Jokers
	for (int i = 0 ; i < JokerStatus_MAX; i++ )
	{
		[mJokers.imageSlot1[i]		SetVisible:FALSE];
		[mJokers.holderSlot1[i]		SetVisible:FALSE];
		
		[mJokers.imageSlot2[i]		SetVisible:FALSE];
		[mJokers.holderSlot2[i]		SetVisible:FALSE];
	}
	
	/* @TODO RG,KK - Setting the usage of previously registered buttons to false, does not allow overlapped buttons that are enabled
	   after the creation of the false usage'd buttons to receive input.  The mEndGameButton were created last, and don't receive 
	   touch events because the placer and rows while not receiving the input, eat the touchsystem's control as their coords are still hit.*/
	
	
	// Turn off the Placer
	[mPlacerButton SetUsage:FALSE];
	[mPlacerButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];	// Todo, use other function.
	
	// Turn off the Runners
	for (int i = 0 ; i < MAX_PLAYER_HANDS ; i++ )
	{
		// Need to deactivate input, it's overtaking my buttons.
		[mRow[i].mRunnerButton SetUsage:FALSE];
	}
    
    if ( !bWonGame )
    {
        // Move the cards left to the bottom of the table
        for (int i = 0; i < NUMCARDSLEFT_NUM ; i++ )
        {
            [ mCardsLeft.images[i] SetPositionX:numCardsHolderLocation.mVector[x] Y:numCardsHolderLocation.mVector[y] + 5 Z:numCardsHolderLocation.mVector[z] ];
        }
        [ mCardsLeft.strTextbox SetPositionX:numCardsTextLocation.mVector[x] Y:numCardsTextLocation.mVector[y] + 5 Z:numCardsTextLocation.mVector[z] ];
        
    }
    else
    {
        for (int i = 0; i < NUMCARDSLEFT_NUM ; i++ )
        {
            [ mCardsLeft.images[i] SetVisible:FALSE ];
        }
        [ mCardsLeft.strTextbox SetVisible:FALSE];
        
    }
    
    BOOL requiresAutoExit = FALSE;
    
    LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
    LevelSelectRoom roomForNextLevel = [levelDefinitions GetRoomForLevel:([[Flow GetInstance] GetLevel] + 1) % RUN21_LEVEL_LAST];
    
    if ((roomForNextLevel > [[SaveSystem GetInstance] GetMaxRoomUnlocked]) && (bWonGame))
    {
        requiresAutoExit = TRUE;
        mUIState = RUN21_UI_STATE_WAITING_TO_AUTOEXIT;
        mTimeRemainingUntilAutoExit = AUTO_EXIT_TIME_DELAY;
    }
    
    if (!requiresAutoExit)
    {
        // Make the end game buttons visible
        for (int i = ENDGAMEBUTTON_FIRST ; i <= ENDGAMEBUTTON_LAST ; i++ )
        {
            BOOL bInUse = TRUE;
            
            // If you beat the level, we don't display the retry 
            if ( bWonGame && ENDGAMEBUTTON_RETRY == i  )
            {
                bInUse = false;
            }
            
            // If you didn't beat the level, we don't display the advance button
            if ( !bWonGame && ENDGAMEBUTTON_ADVANCE == i )
            {
                bInUse = false;	
            }
            //  Don't display advance if this is the last level in the game.
            else if ((GAMEMODE_TYPE_RUN21_MARATHON == [[Flow GetInstance] GetGameMode]) && ENDGAMEBUTTON_ADVANCE == i)
            {
                bInUse = false;
            }
            else if (([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21) && ([[Flow GetInstance] GetLevel] == RUN21_LEVEL_LAST) && (i == ENDGAMEBUTTON_ADVANCE))
            {
                bInUse = false;
            }
            
            [mEndGameButton[i] SetUsage:bInUse];
            
            if ( !bInUse )
                [ mEndGameButton[i] SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
        }
    }
    
    //make all of the powerup buttons invisble, if we are not in a game of marathon
    if(TRUE)
    {
        [self SetEndGamePowerupStrings];

        int maxLevel = [[SaveSystem GetInstance] GetMaxLevel];

        for (int i = ENDGAME_POWERUP_FIRST; i < ENDGAME_POWERUP_NUM; i ++)
        {
            if (i == ENDGAME_POWERUP_XRAY)
            {
                int xrayLevel = [[[Flow GetInstance] GetLevelDefinitions] GetXrayUnlockLevel];
                
                BOOL showXray = ((maxLevel > xrayLevel) || ((maxLevel == xrayLevel) && (bWonGame)));
                
                if (!showXray)
                {
                    continue;
                }
            }
            else if (i == ENDGAME_POWERUP_TORNADO)
            {
                int tornadoLevel = [[[Flow GetInstance] GetLevelDefinitions] GetTornadoUnlockLevel];
                
                BOOL showTornado = ((maxLevel > tornadoLevel) || ((maxLevel == tornadoLevel) && (bWonGame)));
                
                if (!showTornado)
                {
                    continue;
                }
            }
            
            [mPowerupCounters[i].mButton SetUsage:TRUE];
            [mPowerupCounters[i].mNumLeft SetVisible:TRUE];
        }
        
#if USE_LIVES
        [mTimeUntilNextLife SetVisible:TRUE];
#endif

#if USE_EXPERIENCE
        [self CalculateLevel];
        [self ShowLevelUpBar:TRUE];
#endif

        [self PowerupButton:mXRayButton withOn:TRUE];
        [self PowerupButton:mWhirlwindButton withOn:TRUE];
        [mXRayButton.mUseButton                SetVisible:FALSE];
        [mXRayButton.mUseButton                SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
        
        [mXRayButton.mBuyMoreButton            SetVisible:FALSE];
        [mXRayButton.mBuyMoreButton            SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
        
        [mXRayButton.mBuyMoreIndicator Disable];
        [mWhirlwindButton.mBuyMoreIndicator Disable];
        
        [mWhirlwindButton.mUseButton           SetVisible:FALSE];
        [mWhirlwindButton.mUseButton           SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
        
        [mWhirlwindButton.mBuyMoreButton       SetVisible:FALSE];
        [mWhirlwindButton.mBuyMoreButton       SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
        
        [mXRayButton.mNumUsesText               SetVisible:FALSE];
        [mWhirlwindButton.mNumUsesText          SetVisible:FALSE];
    }
    
    if ( bWonGame && ([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21))
    {
        //Show the level card and the score
        [mEndGameLevelCard.levelCard    SetVisible:TRUE];

        PlacementValue placementValue;
        SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);  // May have to recenter on each scoring event?
        
        [UISounds PlayUISound:SFX_STINGER_BLACKJACK_BIGWIN];
    }
    
    if (bWonGame)
    {
        int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
        
        float step = 0, start = 0;
        
        DistributeItemsOverRange(CARD_WIDTH_PROJECTED, numRunners, STAR_WIDTH_PROJECTED, &start, &step);
        
        for (int curStar = 0; curStar < numRunners; curStar++)
        {
            if (curStar == 0)
            {
                if (bWonGame)
                {
                    [mEndGameLevelCard.fullStar SetVisible:TRUE];
                    [mEndGameLevelCard.fullStar SetPositionX:(sLevelStarLocation.mVector[x] + start + (curStar * step)) Y:(sLevelStarLocation.mVector[y]) Z:0.0];
                }
                else
                {
                    [mEndGameLevelCard.emptyStar SetVisible:TRUE];
                }
            }
            else
            {
                ImageWell* imageWell = [[ImageWell alloc] InitWithImageWell:mEndGameLevelCard.fullStar];
                
                [imageWell SetPositionX:(sLevelStarLocation.mVector[x] + start + (curStar * step)) Y:(sLevelStarLocation.mVector[y]) Z:0.0];
                [imageWell	SetScale:[self HackIsRetinaProjected] ? &sLevelStarScaler : &x1_sLevelStarScaler ];
                [imageWell	SetProjected:TRUE];
                [imageWell	SetVisible:TRUE];
                CloneMatrix44(&mTableLTWTransform, &imageWell->mLTWTransform);
                [imageWell release];
            }
        }
    }
    
    [[mUserInterface[UIGROUP_Projected3D] GetTextureAtlas] SetMipmapGenerationEnabled:FALSE];
}

-(void)UpdatePowerupAmounts
{
    mWhirlwindButton.mNumUsesLeft = [[SaveSystem GetInstance] GetNumTornadoes];
    
    if (mWhirlwindButton.mNumUsesLeft == 0)
    {
        [self PowerupButton:mWhirlwindButton withOn:FALSE];
        [mWhirlwindButton.mBuyMoreIndicator Enable];
    }
    else
    {
        [self PowerupButton:mWhirlwindButton withOn:TRUE];

        [mWhirlwindButton.mNumUsesText SetString:[NSString stringWithFormat:@"<B>%d</B>",mWhirlwindButton.mNumUsesLeft]];
    }
    
    mXRayButton.mNumUsesLeft = [[SaveSystem GetInstance] GetNumXrays];
    
    if (mXRayButton.mNumUsesLeft > 0)
    {
        [self PowerupButton:mXRayButton withOn:TRUE];
        
        [self GetHSM].xrayActive = TRUE;

        [mXRayButton.mNumUsesText SetString:[NSString stringWithFormat:@"<B>%d</B>",mXRayButton.mNumUsesLeft]];
    }
    else
    {
        [self PowerupButton:mXRayButton withOn:FALSE];

        [mXRayButton.mNumUsesText SetString:[NSString stringWithFormat:@"<B>%d</B>",mXRayButton.mNumUsesLeft]];
    }

}

-(void)FadeComplete:(NSObject*)inObject
{
    Message msg;
    
    msg.mId = EVENT_RUN21_END_OPTION_SELECTED;
    msg.mData = (void*)([(NSNumber*)inObject intValue]);
    
    [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_RUN21_BEGIN_DURINGPLAY_CAMERA:
        {
            if ([[SaveSystem GetInstance] GetNumXrays] <= 0)
            {
                [mXRayButton.mBuyMoreIndicator Enable];
            }
            
            if ([[SaveSystem GetInstance] GetNumTornadoes] <= 0)
            {
                [mWhirlwindButton.mBuyMoreIndicator Enable];
            }
            
            break;
        }
        
        case EVENT_TUTORIAL_EVALUATE_PHASE:
        {
            if (mGameRun21->mTutorialStatus != TUTORIAL_STATUS_COMPLETE)
            {
                [mTutorialSkipButton Enable];
            }
            break;
        }
        
        case EVENT_RUN21_BEGIN_CELEBRATION_CAMERA:
        {
            [mXRayButton.mBuyMoreIndicator Disable];
            [mWhirlwindButton.mBuyMoreIndicator Disable];
            break;
        }
        
        case EVENT_RATED_GAME:
        {
            [self SetEndGamePowerupStrings];
            break;
        }
    }
}

@end