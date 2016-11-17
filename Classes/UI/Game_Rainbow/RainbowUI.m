//
//  RainbowUI.h
//  Neon21
//
//  Copyright (c) 2012 Neon Games.
//

#import "RainbowUI.h"
#import "GameRainbow.h"
#import "UINeonEngineDefines.h"
#import "Flow.h"
#import "RainbowEnvironment.h"
#import "MiniGameTableEntity.h"
#import "MultiStateButton.h"



#define HAND_STATES 4
#define CONFIRM_STATES 2


#define HANDHOLDER_ORIGIN_X -6.6
#define HANDHOLDER_ORIGIN_Y -3.4
#define HANDHOLDER_OFFSET_X 2.4
#define HANDHOLDER_OFFSET_Y 3.2

#define RAINBOWUI_col1 3.2
#define RAINBOWUI_col2 4.2
#define RAINBOWUI_col3 5.7

#define RAINBOWLETTERS_ORIGIN_X -7.0
#define RAINBOWLETTERS_ORIGIN_Y 3.35
#define RAINBOWLETTERS_OFFSET_X 1.5

#define ENDGAME_LEFT_X		-6.0
#define ENDGAME_RIGHT_X		0.125
#define ENDGAME_ORIGIN_Y	-2.30

#define STARHOLDER_ORIGIN_X HANDHOLDER_ORIGIN_X + .4
#define STARHOLDER_ORIGIN_Y HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y + .75

#define NUM_TUTORIAL_BUTTONS RAINBOW_NUM_PLAYERS * RAINBOW_NUM_CARDS_IN_HAND + 1

#if 0
static Vector3 sLevelCardLocation				= { { .5, -3.0, 0.0 } };
static Vector3 sLevelStarLocation				= { { .6 ,-2.9 ,0.0 } };

static Vector3 sLevelCardScaler					= { { .025, .025, 1.0 } };
static Vector3 x1_sLevelCardScaler              = { { .05 , .05 , 1.0 } };
static Vector3 sLevelStarScaler					= { { .025, .025, 1.0 } };
static Vector3 x1_sLevelStarScaler              = { { .05 , .05 , 1.0 } };
#endif

static Vector3 sRunnerScaler					= { { 0.0230  , 0.0230 , 1.0 } };
static Vector3 sConfirmScaler                   = { { 0.0300  , 0.0115 , 1.0 } };
static Vector3 sStandScaler                     = { { 0.0150  , 0.0100 , 1.0 } };
static Vector3 sUniqueScaler                    = { { 0.0150  , 0.0100 , 1.0 } };

static Vector3 sEndGameButtonScaler				= { { 0.030 , 0.030, 1.0 } };

#if 0
static Vector3 sEndGameStarScaler				= { { 0.025 , 0.025, 1.0 } };
#endif

static Vector3 sConfirmLocation     = { { RAINBOWUI_col2 , 2.25 , 0.0 } };
static Vector3 sStandLocation       = { { RAINBOWUI_col2 , 0.70 , 0.0 } };
static Vector3 sUniqueLocation      = { { RAINBOWUI_col3 , 0.70 , 0.0 } };

static Vector3 numTurnsHolderLocation = { { RAINBOWUI_col2 , -0.3 , 0.0 } };
static Vector3 numTurnsTextLocation   = { { RAINBOWUI_col3 , -0.3 , 0.0 } };

static Vector3 numTurnsHolderDealer = { { RAINBOWUI_col1 , -2.5 , 0.0 } };
static Vector3 numTurnsHolderPlayer = { { RAINBOWUI_col1 , 0.5 , 0.0 } };
static Vector3 numTurnsTextDealer   = { { RAINBOWUI_col2 + 0.5 , -2.5 , 0.0 } };
static Vector3 numTurnsTextPlayer   = { { RAINBOWUI_col2 + 0.5 , 0.5 , 0.0 } };

static Vector3 sHandHolderLocations[RAINBOW_NUM_PLAYERS*RAINBOW_NUM_CARDS_IN_HAND] =
{
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 0, HANDHOLDER_ORIGIN_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 1, HANDHOLDER_ORIGIN_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 2, HANDHOLDER_ORIGIN_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 3, HANDHOLDER_ORIGIN_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 0, HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 1, HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 2, HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y, 0.0},
    { HANDHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 3, HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y, 0.0},
};

static Vector3 sRainbowLetterLocations[(RAINBOW_NUM_ROUNDS_PER_GAME * RAINBOW_NUM_PLAYERS)-1] =
{
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 0, RAINBOWLETTERS_ORIGIN_Y, 0.0},
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 1, RAINBOWLETTERS_ORIGIN_Y, 0.0},
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 2, RAINBOWLETTERS_ORIGIN_Y, 0.0},
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 3, RAINBOWLETTERS_ORIGIN_Y, 0.0},
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 4, RAINBOWLETTERS_ORIGIN_Y, 0.0},
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 5, RAINBOWLETTERS_ORIGIN_Y, 0.0},
    {RAINBOWLETTERS_ORIGIN_X + RAINBOWLETTERS_OFFSET_X * 6, RAINBOWLETTERS_ORIGIN_Y, 0.0},
};

static Vector3 sStandStatusLocations[RAINBOW_NUM_PLAYERS] =
{
    { RAINBOWUI_col1 , HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y * 0.5, 0.0 },
    { RAINBOWUI_col1 , HANDHOLDER_ORIGIN_Y + HANDHOLDER_OFFSET_Y * 1.5, 0.0 }
};

static Vector3 sEndGameButtonLocations[ENDGAMEBUTTON_NUM] =
{
    { ENDGAME_LEFT_X  ,ENDGAME_ORIGIN_Y, 0.0 },
    { ENDGAME_RIGHT_X ,ENDGAME_ORIGIN_Y, 0.0 },
    { ENDGAME_RIGHT_X ,ENDGAME_ORIGIN_Y, 0.0 }
};

#if 0
static Vector3 sEndGameStarLocations[STAR_NUM] =
{
    { STARHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 0, STARHOLDER_ORIGIN_Y, 0.0},
    { STARHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 0, STARHOLDER_ORIGIN_Y, 0.0},
    { STARHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 1, STARHOLDER_ORIGIN_Y, 0.0},
    { STARHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 2, STARHOLDER_ORIGIN_Y, 0.0},
    { STARHOLDER_ORIGIN_X + HANDHOLDER_OFFSET_X * 3, STARHOLDER_ORIGIN_Y, 0.0},
};
#endif

static const char*  sPlayerHandFileNames[PLACER_NUM] =
{
    "rainbow_placer_disabled.papng",                //PLACER_DISABLED
    "rainbow_placer_notscored_inactive.papng",      //PLACER_NOTSCORED_INACTIVE
    "rainbow_placer_notscored_active.papng",        //PLACER_NOTSCORED_ACTIVE
    "rainbow_placer_scored_inactive.papng",         //PLACER_SCORED_INACTIVE
    "rainbow_placer_scored_active.papng",           //PLACER_SCORED_ACTIVE
};

static const char*  sConfirmButtonFileNames[CONFIRM_BUTTON_NUM] =
{
    "rainbow_discard_disabled.papng",
    "rainbow_discard_enabled.papng",
};

static const char* sStandButtonFileNames[STAND_BUTTON_NUM] =
{
    "rainbow_stand_disabled.papng",
    "rainbow_stand_inactive.papng",
	"rainbow_stand_active.papng",
};

static const char* sUniqueButtonFileNames[UNIQUE_BUTTON_NUM] =
{
    "rainbow_unique_disabled.papng",
	"rainbow_unique_enabled.papng",
};

static const char* sNumTurnssLeftFileNames[NUMTURNSLEFT_NUM] =
{
    "rainbow_turnsleft_disabled.papng",
    "rainbow_turnsleft_player_begin.papng",
    "rainbow_turnsleft_player_end.papng",
    "rainbow_turnsleft_dealer_begin.papng",
    "rainbow_turnsleft_dealer_end.papng",
    "rainbow_turnsleft_tie.papng",
};

static const char* sEndGameButtonTextures[ENDGAMEBUTTON_NUM] =
{   "r21_endgame_levelselect.papng",			// ENDGAMEBUTTON_LEVELSELECT
	"r21_endgame_retry.papng",					// ENDGAMEBUTTON_RETRY
	"r21_endgame_progress.papng",				// ENDGAMEBUTTON_ADVANCE
};

static const char*  sEndGameButtonTextures_Glow[ENDGAMEBUTTON_NUM] =
{   "r21_endgame_levelselect_glow.papng",		// ENDGAMEBUTTON_LEVELSELECT
	"r21_endgame_retry_glow.papng",				// ENDGAMEBUTTON_RETRY
	"r21_endgame_progress_glow.papng",			// ENDGAMEBUTTON_ADVANCE
};

static const char*  sRainbowLetterTextures[RAINBOWLETTER_NUM] =
{
    "rainbow_letter_r_dealer.papng",       //RAINBOWLETTER_R_DEALER
    "rainbow_letter_r_player.papng",       //RAINBOWLETTER_R_PLAYER
    "rainbow_letter_r_unscored.papng",      //RAINBOWLETTER_R_UNSCORED
    "rainbow_letter_a_dealer.papng",       //RAINBOWLETTER_A_DEALER
    "rainbow_letter_a_player.papng",       //RAINBOWLETTER_A_PLAYER
    "rainbow_letter_a_unscored.papng",      //RAINBOWLETTER_A_UNSCORED
    "rainbow_letter_i_dealer.papng",       //RAINBOWLETTER_I_DEALER
    "rainbow_letter_i_player.papng",         //RAINBOWLETER_I_PLAYER
    "rainbow_letter_i_unscored.papng",      //RAINBOWLETTER_I_UNSCORED,
    "rainbow_letter_n_dealer.papng",       //RAINBOWLETTER_N_DEALER,
    "rainbow_letter_n_player.papng",      //RAINBOWLETTER_N_PLAYER,
    "rainbow_letter_n_unscored.papng",      //RAINBOWLETTER_N_UNSCORED,
    "rainbow_letter_b_dealer.papng",      //RAINBOWLETTER_B_DEALER,
    "rainbow_letter_b_player.papng",      //RAINBOWLETTER_B_PLAYER,
    "rainbow_letter_b_unscored.papng",      //RAINBOWLETTER_B_UNSCORED,
    "rainbow_letter_o_dealer.papng",      //RAINBOWLETTER_O_DEALER,
    "rainbow_letter_o_player.papng",      //RAINBOWLETTER_O_PLAYER,
    "rainbow_letter_o_unscored.papng",      //RAINBOWLETTER_O_UNSCORED,
    "rainbow_letter_w_dealer.papng",      //RAINBOWLETTER_W_DEALER,
    "rainbow_letter_w_player.papng",      //RAINBOWLETTER_W_PLAYER,
    "rainbow_letter_w_unscored.papng",      //RAINBOWLETTER_W_UNSCORED,
};

static const char*  sStandStatusTextures[STANDSTATUS_NUM] =
{
    "rainbow_standstatus_disabled.papng",      // STANDSTATUS_HAS_NOT_STOOD
    "rainbow_standstatus_player.papng",      // STANDSTATUS_PLAYER_STOOD
    "rainbow_standstatus_dealer.papng",       // STANDSTATUS_DEALER_STOOD
};

static const char* sButtonIDs[NUM_TUTORIAL_BUTTONS] =
{
	"Dealer_1",
    "Dealer_2",
    "Dealer_3",
    "Dealer_4",
    "Player_1",
    "Player_2",
    "Player_3",
    "Player_4",
    "Discard",
};

@implementation RainbowUI

-(RainbowUI*)InitWithEnvironment:(RainbowEnvironment*)inEnvironment
{
    mEnvironment = inEnvironment;
    
    //Set up the Matrix for the projected UI coordinate system
    GenerateTranslationMatrix(0.0, ([mEnvironment GetTableHeight] + EPSILON), 0.0, &mTableLTWTransform);
    
    Matrix44 rotationMatrix;
    GenerateRotationMatrix([mEnvironment GetTableRotationDegrees], 1.0f, 0.0f, 0.0f, &rotationMatrix);
    
    MatrixMultiply(&mTableLTWTransform, &rotationMatrix, &mTableLTWTransform);
    
    [self InitInterfaceGroups];
    [self InitPauseButton];
    
    [self InitHandHolders];
    [self InitDiscardButton];
    [self InitStandButton];
    [self InitUniqueButton];
    [self InitTurnCounter];
    [self InitWinCounter];
    
    // By this being registered last it takes bottom priority. Disabling buttons above it does not seem to allow us to get clicked if we're overlapped.
	[self InitEndGameButtons];
	[self InitEndGameStars];
	[self InitEndGameLevelCard];
    [self InitStandIndicators];
    //[self InterfaceMode:R21UI_Startup];
	
	// Finalize the interface
	[mUserInterface[UIGROUP_2D			] Finalize];
    [mUserInterface[UIGROUP_Projected3D	] Finalize];
    
    return self;
}

-(BOOL)HackIsRetinaProjected
{
    // TODO: Doesn't handle iPhone 5 or iPad 3 native.
    return GetScreenRetina() || GetDevicePad();
}

/*---------------------------------------------------------------------------------
 * InitInterfaceGroups
 * This function sets up the interface groups so that it can keep track of the UI
 * No inputs, No outputs
 *----------------------------------------------------------------------------------*/
-(void)InitInterfaceGroups
{
    [super uiAlloc];
    
    // Alloc the UIGroup
	GameObjectBatchParams uiGroupParams;
    [GameObjectBatch InitDefaultParams:&uiGroupParams];
    uiGroupParams.mUseAtlas = TRUE;
    
    mUserInterface[UIGROUP_2D] = [(UIGroup*)[UIGroup alloc] InitWithParams:&uiGroupParams];
    [[GameObjectManager GetInstance] Add:mUserInterface[UIGROUP_2D]];
    [mUserInterface[UIGROUP_2D] release];
	
    mUserInterface[UIGROUP_Projected3D] = [(UIGroup*)[UIGroup alloc] InitWithParams:&uiGroupParams];
    [[GameObjectManager GetInstance] Add:mUserInterface[UIGROUP_Projected3D]];
    [mUserInterface[UIGROUP_Projected3D] release];
    [mUserInterface[UIGROUP_Projected3D] SetProjected:TRUE];
    
}

/*--------------------------------------------------------------------------------------------------------------
 * InitHandHolders
 * The Hand Holders are the array of buttons that allow the user to discard or not discard cards in thier hands
 * This function sets up the buttons, gives them pictures and registers them with the UIGroups
 * No inputs, No outputs
 *---------------------------------------------------------------------------------------------------------------*/

-(void)InitHandHolders
{
    NSMutableArray* textureFilenames = [[NSMutableArray alloc] initWithCapacity:HAND_STATES];

    for (int i = 0; i < PLACER_NUM; i++)
	{
		NSString* curString = [NSString stringWithUTF8String:sPlayerHandFileNames[i]];
		[textureFilenames addObject:curString];
	}
    
    for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
    {
        for (int j = 0; j < RAINBOW_NUM_CARDS_IN_HAND; j++)
        {
            MultiStateButtonParams multiStateButtonParams;
        
            [MultiStateButton InitDefaultParams:&multiStateButtonParams];
            
            multiStateButtonParams.mButtonTextureFilenames = textureFilenames;
            multiStateButtonParams.mBoundingBoxCollision = TRUE;
            multiStateButtonParams.mUIGroup = mUserInterface[UIGROUP_Projected3D];
            
            mHands[i].mCardButton[j] = [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&multiStateButtonParams];
            
            mHands[i].mCardButton[j]->mIdentifier = i*RAINBOW_NUM_CARDS_IN_HAND + j;
            [mHands[i].mCardButton[j] SetVisible:TRUE];
            [mHands[i].mCardButton[j] SetListener:self];
            [mHands[i].mCardButton[j] SetProjected:TRUE];
            [mHands[i].mCardButton[j] SetStringIdentifier:[NSString stringWithUTF8String:sButtonIDs[i*RAINBOW_NUM_CARDS_IN_HAND + j]] ];
            
            [mHands[i].mCardButton[j] SetPosition:&sHandHolderLocations[i*RAINBOW_NUM_CARDS_IN_HAND +j]];	// static Locations on i'th iterator
            [mHands[i].mCardButton[j] SetScaleX:sRunnerScaler.mVector[x] Y:sRunnerScaler.mVector[y] Z:sRunnerScaler.mVector[z] ];
            
            CloneMatrix44(&mTableLTWTransform, &mHands[i].mCardButton[j]->mLTWTransform);
            
            [mHands[i].mCardButton[j] SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
            
            [mHands[i].mCardButton[j] SetActiveIndex:0];

            [mHands[i].mCardButton[j] release];
        }
    }
    [textureFilenames release];
}

/*--------------------------------------------------------------------------------------------------------------
 * InitDiscardButton
 * The Conrim Button is a button that lets the user end thier turn, based on the status of the HandHolderArray,
 * The game will either discard cards, or just end thier turn
 * This function sets up the button, gives it pictures and registers it with the UIGroup
 * No inputs, No outputs
 *---------------------------------------------------------------------------------------------------------------*/
-(void)InitDiscardButton
{
    NSMutableArray* textureFilenames = [[NSMutableArray alloc] initWithCapacity:CONFIRM_BUTTON_NUM];
    
    for (int i = 0; i < CONFIRM_BUTTON_NUM; i++)
	{
		NSString* curString = [NSString stringWithUTF8String:sConfirmButtonFileNames[i]];
		[textureFilenames addObject:curString];
	}
    
    MultiStateButtonParams multiStateButtonParams;
	[MultiStateButton InitDefaultParams:&multiStateButtonParams];
    
    multiStateButtonParams.mButtonTextureFilenames = textureFilenames;
	multiStateButtonParams.mBoundingBoxCollision = TRUE;
	multiStateButtonParams.mUIGroup = mUserInterface[UIGROUP_Projected3D];
    
    mDiscardButton = [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&multiStateButtonParams];
    
    mDiscardButton->mIdentifier = 0;
	[mDiscardButton SetVisible:TRUE];
	[mDiscardButton SetListener:self];
	[mDiscardButton SetProjected:TRUE];
	[mDiscardButton SetStringIdentifier:[NSString stringWithUTF8String:sButtonIDs[NUM_TUTORIAL_BUTTONS - 1]]];
    
	[mDiscardButton SetPosition:&sConfirmLocation];
	[mDiscardButton SetScale:&sConfirmScaler];
    
    
    CloneMatrix44(&mTableLTWTransform, &mDiscardButton->mLTWTransform);
    
    [mDiscardButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
    [mDiscardButton release];
}

-(void)InitStandButton
{
    NSMutableArray* textureFilenames = [[NSMutableArray alloc] initWithCapacity:STAND_BUTTON_NUM];
    
    for (int i = 0; i < STAND_BUTTON_NUM; i++)
	{
		NSString* curString = [NSString stringWithUTF8String:sStandButtonFileNames[i]];
		[textureFilenames addObject:curString];
	}
    
    MultiStateButtonParams multiStateButtonParams;
	[MultiStateButton InitDefaultParams:&multiStateButtonParams];
    
    multiStateButtonParams.mButtonTextureFilenames = textureFilenames;
	multiStateButtonParams.mBoundingBoxCollision = TRUE;
	multiStateButtonParams.mUIGroup = mUserInterface[UIGROUP_Projected3D];
    
    mStandButton = [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&multiStateButtonParams];
    
    mStandButton->mIdentifier = 0;
	[mStandButton SetVisible:TRUE];
	[mStandButton SetListener:self];
	[mStandButton SetProjected:TRUE];
	[mStandButton SetStringIdentifier:@""];
    [mStandButton SetPosition:&sStandLocation];
	[mStandButton SetScale:&sStandScaler];
    
    
    CloneMatrix44(&mTableLTWTransform, &mStandButton->mLTWTransform);
    
    [mStandButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
    [mStandButton release];
}

-(void)InitUniqueButton
{
    NSMutableArray* textureFilenames = [[NSMutableArray alloc] initWithCapacity:UNIQUE_BUTTON_NUM];
    
    for (int i = 0; i < UNIQUE_BUTTON_NUM; i++)
	{
		NSString* curString = [NSString stringWithUTF8String:sUniqueButtonFileNames[i]];
		[textureFilenames addObject:curString];
	}
    
    MultiStateButtonParams multiStateButtonParams;
	[MultiStateButton InitDefaultParams:&multiStateButtonParams];
    
    multiStateButtonParams.mButtonTextureFilenames = textureFilenames;
	multiStateButtonParams.mBoundingBoxCollision = TRUE;
	multiStateButtonParams.mUIGroup = mUserInterface[UIGROUP_Projected3D];
    
    mUniqueButton = [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&multiStateButtonParams];
    
    mUniqueButton->mIdentifier = 0;
	[mUniqueButton SetVisible:TRUE];
	[mUniqueButton SetListener:self];
	[mUniqueButton SetProjected:TRUE];
	[mUniqueButton SetStringIdentifier:@""];
    [mUniqueButton SetPosition:&sUniqueLocation];
	[mUniqueButton SetScale:&sUniqueScaler];
    
    
    CloneMatrix44(&mTableLTWTransform, &mUniqueButton->mLTWTransform);
    
    [mUniqueButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
    [mUniqueButton release];
}
/*------------------------------------------------------------------------------------------
 * InitTurnCounter
 * The Turn Counter Lets the User know how many turns they have left untill the round is over
 * This function sets up the text box, gives it pictures and registers it with the UIGroup
 * No inputs, No outputs
 *------------------------------------------------------------------------------------------*/
-(void)InitTurnCounter
{
    char fileName[maxIconFileName];
	
	for ( int nHolder = 0 ; nHolder < NUMTURNSLEFT_NUM ; nHolder++ )
	{
		ImageWellParams imageWellparams;
		
		strncpy(fileName, sNumTurnssLeftFileNames[nHolder], maxIconFileName );
		[ImageWell InitDefaultParams:&imageWellparams];
		imageWellparams.mTextureName						= [NSString stringWithUTF8String:fileName];
		imageWellparams.mUIGroup							= mUserInterface[UIGROUP_Projected3D];
		
		mTurnsLeft.images[nHolder]	= [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
		[mTurnsLeft.images[nHolder]	SetPosition:&numTurnsHolderLocation];
		[mTurnsLeft.images[nHolder]	SetScaleX:0.020f Y:0.020f Z:1.0f];
		[mTurnsLeft.images[nHolder]	SetProjected:TRUE];
        [mTurnsLeft.images[nHolder] SetVisible:FALSE];

		CloneMatrix44(&mTableLTWTransform, &mTurnsLeft.images[nHolder]->mLTWTransform);
		[mTurnsLeft.images[nHolder] release];
	}
    
    [mTurnsLeft.images[0] SetVisible:TRUE];

	// Num Cards Textbox
    mTurnsLeft.strTextbox = [self InitTextBoxWithFontColor:NEONFONT_YELLOW uiGroup:mUserInterface[UIGROUP_Projected3D]];
    [mTurnsLeft.strTextbox SetPosition:&numTurnsTextLocation];
    
    CloneMatrix44(&mTableLTWTransform, &mTurnsLeft.strTextbox->mLTWTransform);

	// Cards Status
	mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_DISABLED;

}
/*------------------------------------------------------------------------------------------
 * InitWinCounter
 * The win counter keeps track of how many rounds each player has won in a pictoral view
 * This function sets up the counter gives it pictures and registers it with the UIGroup
 * No inputs, No outputs
 *------------------------------------------------------------------------------------------*/
-(void)InitWinCounter
{
    char fileName[maxIconFileName];
    for (int letterNum = 0; letterNum < (RAINBOW_NUM_ROUNDS_PER_GAME * RAINBOW_NUM_PLAYERS)-1; letterNum++)
    {
        for (int nHolder = RAINBOWLETTER_FIRST; nHolder < RAINBOWLETTER_NUM; nHolder++)
        {
            ImageWellParams imageWellparams;

            strncpy(fileName,sRainbowLetterTextures[nHolder],maxIconFileName);
            
            [ImageWell InitDefaultParams:&imageWellparams];
            imageWellparams.mTextureName						= [NSString stringWithUTF8String:fileName];
            imageWellparams.mUIGroup							= mUserInterface[UIGROUP_Projected3D];
            
            mRoundsWon.letters[letterNum].images[nHolder] = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
            [mRoundsWon.letters[letterNum].images[nHolder]	SetPosition:&sRainbowLetterLocations[letterNum]];
            [mRoundsWon.letters[letterNum].images[nHolder]	SetScaleX:0.020f Y:0.020f Z:1.0f];
            [mRoundsWon.letters[letterNum].images[nHolder]	SetProjected:TRUE];
            [mRoundsWon.letters[letterNum].images[nHolder]  SetVisible:FALSE];
            
            CloneMatrix44(&mTableLTWTransform, &mRoundsWon.letters[letterNum].images[nHolder]->mLTWTransform);
            [mRoundsWon.letters[letterNum].images[nHolder] release];
        }
    }
    
    [mRoundsWon.letters[0].images[RAINBOWLETTER_R_UNSCORED] SetVisible:TRUE];
    [mRoundsWon.letters[1].images[RAINBOWLETTER_A_UNSCORED] SetVisible:TRUE];
    [mRoundsWon.letters[2].images[RAINBOWLETTER_I_UNSCORED] SetVisible:TRUE];
    [mRoundsWon.letters[3].images[RAINBOWLETTER_N_UNSCORED] SetVisible:TRUE];
    [mRoundsWon.letters[4].images[RAINBOWLETTER_B_UNSCORED] SetVisible:TRUE];
    [mRoundsWon.letters[5].images[RAINBOWLETTER_O_UNSCORED] SetVisible:TRUE];
    [mRoundsWon.letters[6].images[RAINBOWLETTER_W_UNSCORED] SetVisible:TRUE];
    
    mRoundsWon.dealerWins = 0;
    mRoundsWon.playerWins = 0;
    
}

-(void)InitStandIndicators
{
    char fileName[maxIconFileName];
    for (int playerNum = 0; playerNum < RAINBOW_NUM_PLAYERS; playerNum++)
    {
        for (int imageNum = STANDSTATUS_FIRST; imageNum < STANDSTATUS_NUM; imageNum++)
        {
            ImageWellParams imageWellparams;
            
            strncpy(fileName,sStandStatusTextures[imageNum],maxIconFileName);
            
            [ImageWell InitDefaultParams:&imageWellparams];
            imageWellparams.mTextureName						= [NSString stringWithUTF8String:fileName];
            imageWellparams.mUIGroup							= mUserInterface[UIGROUP_Projected3D];
            
            mStandStatus[playerNum].images[imageNum] = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
            [mStandStatus[playerNum].images[imageNum]	SetPosition:&sStandStatusLocations[playerNum]];
            [mStandStatus[playerNum].images[imageNum]	SetScaleX:0.050f Y:0.050f Z:1.0f];
            [mStandStatus[playerNum].images[imageNum]	SetProjected:TRUE];
            [mStandStatus[playerNum].images[imageNum]    SetVisible:FALSE];
            
            CloneMatrix44(&mTableLTWTransform, &mStandStatus[playerNum].images[imageNum]->mLTWTransform);
            [mStandStatus[playerNum].images[imageNum] release];
        }
    }
    
    [mStandStatus[0].images[STANDSTATUS_HAS_NOT_STOOD] SetVisible:TRUE];
    [mStandStatus[1].images[STANDSTATUS_HAS_NOT_STOOD] SetVisible:TRUE];
}
/*------------------------------------------------------------------------------------------
 * InitPauseButton
 * The pause button lets you pause the game
 * This function sets up the button, gives it pictures and registers it with the UIGroup
 * No inputs, No outputs
 *------------------------------------------------------------------------------------------*/
-(void)InitPauseButton
{
    float posX, posY;
    
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
    
    mPauseButton = [[TextureButton alloc] InitWithParams:&buttonParams];
    [mPauseButton release];
    
    [mPauseButton SetListener:self];
    [mPauseButton SetPositionX:-0.3 Y:1.25f Z:0.46f];
    [mPauseButton SetVisible:TRUE];
    [mPauseButton SetProjected:TRUE];
    [mPauseButton SetScaleX:1.5f Y:1.5f Z:1.0f];
    CloneMatrix44(scoreboardTransform, &mPauseButton->mLTWTransform);
    
    [mPauseButton SetProxy:TRUE];
    
    [[GameObjectManager GetInstance] Add:mPauseButton];
}
// @TODO: Handle Stars / Endgame
-(void)InitEndGameButtons
{
    for ( int i = ENDGAMEBUTTON_FIRST ; i <= ENDGAMEBUTTON_LAST ; i++ )
	{
		NeonButtonParams				buttonParams;
		[NeonButton InitDefaultParams:	&buttonParams];
		
		buttonParams.mTexName					= [NSString stringWithUTF8String:sEndGameButtonTextures[i]];
		buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:sEndGameButtonTextures_Glow[i]];
		
		buttonParams.mBoundingBoxCollision		= TRUE;
		buttonParams.mUIGroup					= mUserInterface[UIGROUP_Projected3D];
		
		mEndGameButton[i]						= [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
		
		mEndGameButton[i]->mIdentifier			= ENDGAME_ID_OFFSET + i;
        
		[mEndGameButton[i]						SetListener:self];
		[mEndGameButton[i]						SetProjected:TRUE];
		[mEndGameButton[i]						SetUsage:FALSE];
		
		[mEndGameButton[i]						SetPosition:&sEndGameButtonLocations[i]];
		[mEndGameButton[i]						SetScale:&sEndGameButtonScaler];
		CloneMatrix44							(&mTableLTWTransform, &mEndGameButton[i]->mLTWTransform);
		
		[mEndGameButton[i]						SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
		
		[mEndGameButton[i]						release];
	}
}

-(void)InitEndGameStars
{
    // Todo use pointer to reduce copy/paste
	for ( StarLevel nStarNum = STAR_FIRST ; nStarNum <= STAR_LAST; nStarNum++ )
	{
		// Do not do anything with the empty star.
		if ( nStarNum == STAR_NONE )
			continue;
		
		for ( EStarStatus nStarStatus = STARSTATUS_FIRST ; nStarStatus <= STARSTATUS_LAST; nStarStatus++ )
		{
#if 0
			char			fileName[maxIconFileName];
			ImageWellParams imageWellparams;
			int				nFileIndex = ( nStarStatus == STARSTATUS_FIRST ) ? 0 : 1;	// 0 == EMPTY, 1 = FILLED
#endif
            
            NSAssert(FALSE, @"Need to replace below iwth the new flow code");
#if 0
            StarLevel       roomStar = [ [Flow GetInstance] GetRoomStarForCurrentGameState ];
			
			switch ( roomStar )
			{
				case STAR_NONE:
					break;	// We don't draw NONE stars at Large Size
				case STAR_BRONZE:
					snprintf(fileName, maxIconFileName, "starbronze_outcome_%d.papng"	, nFileIndex );
					break;
				case STAR_SILVER:
					snprintf(fileName, maxIconFileName, "starsilver_outcome_%d.papng"	, nFileIndex );
					break;
				case STAR_GOLD:
					snprintf(fileName, maxIconFileName, "stargold_outcome_%d.papng"		, nFileIndex );
					break;
				case STAR_SHOOTING:
					snprintf(fileName, maxIconFileName, "starshooting_outcome_%d.papng"	, nFileIndex );
					break;
				default:
					NSAssert(FALSE, @"Unsupported Large Star Type");
					return;
			}
			
			[ImageWell InitDefaultParams:&imageWellparams];
			imageWellparams.mTextureName					= [NSString stringWithUTF8String:fileName];
			imageWellparams.mUIGroup						= mUserInterface[UIGROUP_Projected3D];
			
			mEndGameStars[nStarNum].starImage[nStarStatus]	= [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
			[mEndGameStars[nStarNum].starImage[nStarStatus]	SetPosition:&sEndGameStarLocations[nStarNum]];
			[mEndGameStars[nStarNum].starImage[nStarStatus]	SetScale:&sEndGameStarScaler];
			[mEndGameStars[nStarNum].starImage[nStarStatus]	SetProjected:TRUE];
			[mEndGameStars[nStarNum].starImage[nStarStatus]	SetVisible:FALSE];
			CloneMatrix44(&mTableLTWTransform,	&mEndGameStars[nStarNum].starImage[nStarStatus]->mLTWTransform);
			[mEndGameStars[nStarNum].starImage[nStarStatus]	release];
#endif
		}
		
		
		
	}
    
}

-(void)InitEndGameLevelCard
{
    NSAssert(FALSE, @"Need to use new level indexing functions");
#if 0
    char			fileName[maxIconFileName];
    
    int nLevelIndex = [[ Flow GetInstance ] GetProgress] - Tutorial_Rainbow_HowToPlay;
    snprintf(fileName, maxIconFileName, "r21_level_%d_available.papng"	, nLevelIndex );
    
    ImageWellParams imageWellparams;
    [ImageWell InitDefaultParams:&imageWellparams];
    imageWellparams.mTextureName					= [NSString stringWithUTF8String:fileName];
    imageWellparams.mUIGroup						= mUserInterface[UIGROUP_Projected3D];
    
    mEndGameLevelCard.levelCard	= [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
    [mEndGameLevelCard.levelCard	SetPosition:&sLevelCardLocation];
    [mEndGameLevelCard.levelCard	SetScale: [self HackIsRetinaProjected] ? &sLevelCardScaler : &x1_sLevelCardScaler ];
    [mEndGameLevelCard.levelCard	SetProjected:TRUE];
    [mEndGameLevelCard.levelCard	SetVisible:FALSE];
    CloneMatrix44(&mTableLTWTransform,	&mEndGameLevelCard.levelCard->mLTWTransform);
    [mEndGameLevelCard.levelCard	release];
    
    // Loop through the ratings.
    for ( StarLevel ratingStar = STAR_FIRST ; ratingStar < STAR_NUM ; ratingStar++ )
    {
        StarLevel nRoom = [ [Flow GetInstance] GetRoomStarForCurrentGameState ];
        snprintf(fileName, 256, "lsaward_room%d_%dstars.papng", nRoom , ratingStar );
        imageWellparams.mTextureName	= [NSString stringWithUTF8String:fileName];
        
        ImageWellParams                     params;
        [ImageWell                          InitDefaultParams:&params];
        params.mTextureName					= [NSString stringWithUTF8String:fileName];
        params.mUIGroup						= mUserInterface[UIGROUP_Projected3D];
        
        mEndGameLevelCard.rating[ratingStar]	= [(ImageWell*)[ImageWell alloc] InitWithParams:&params];
        [mEndGameLevelCard.rating[ratingStar]	SetPosition:&sLevelStarLocation];
        [mEndGameLevelCard.rating[ratingStar]	SetScale: [self HackIsRetinaProjected] ? &sLevelStarScaler : &x1_sLevelStarScaler ];
        [mEndGameLevelCard.rating[ratingStar]	SetProjected:TRUE];
        [mEndGameLevelCard.rating[ratingStar]	SetVisible:FALSE];
        CloneMatrix44(&mTableLTWTransform,      &mEndGameLevelCard.rating[ratingStar]->mLTWTransform);
        [mEndGameLevelCard.rating[ratingStar]	release];
    }
#endif
}

/*------------------------------------------------------------------------------------------
 * InterfaceMode
 * This changes how the user can interact with the table
 * different states means different actions are allowed
 * Input: inMode should be the desired UI State
 * No ouputs
 *------------------------------------------------------------------------------------------*/
-(void)InterfaceMode:(ERainbowUIStatus)inMode
{
    uiStatus = inMode;
    switch (inMode)
    {
        case RAINUI_STARTUP:
        {
            [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:FALSE];
            mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_DISABLED;
            [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:TRUE];
            [mTurnsLeft.strTextbox SetString:@""];
            [mTurnsLeft.strTextbox SetVisible:TRUE];
            
            for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
            {
                [mStandStatus[i].images[STANDSTATUS_HAS_NOT_STOOD] SetVisible:TRUE];
            }

            break;
        }
        case RAINUI_SCORING:
        {
            [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:FALSE];
            [mTurnsLeft.strTextbox SetVisible:FALSE];
            
            //Turn off all stand status images
            for (int playerNum = 0; playerNum < RAINBOW_NUM_PLAYERS; playerNum++)
            {
                for (int i = STANDSTATUS_FIRST; i < STANDSTATUS_NUM; i++)
                {
                    [mStandStatus[playerNum].images[i] SetVisible:FALSE];
                }
            }
            //Remove the button array from the sceen, as it gets in the way of the scoring
            [mStandButton SetVisible:FALSE];
            [mUniqueButton SetVisible:FALSE];
            [mDiscardButton SetVisible:FALSE];
            [mDiscardButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
            break;
        }
        case RAINUI_DONE_SCORING:
        {
            //Show the Button Array again, we need to show it so the user can continue to the next round
            [mStandButton SetVisible:TRUE];
            [mStandButton SetActiveIndex:STAND_BUTTON_DISABLED];
            [mUniqueButton SetVisible:TRUE];
            [mUniqueButton SetActiveIndex:UNIQUE_BUTTON_DISABLED];
            [mDiscardButton SetVisible:TRUE];
            [mDiscardButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_PROJECTED];
            [mTurnsLeft.strTextbox SetVisible:FALSE];
            
            //return the numTurn Pictures back to the starting location
            for (int i = NUMTURNSLEFT_DISABLED; i < NUMTURNSLEFT_NUM ; i++)
            {
                [mTurnsLeft.images[i] SetVisible:FALSE];
                [mTurnsLeft.images[i] SetPosition:&numTurnsHolderLocation];
            }
            
            [mTurnsLeft.strTextbox	SetPosition:&numTurnsTextLocation];
            break;
        }
    }
}




/*------------------------------------------------------------------------------------------
 * GetButtonArray
 * The button array is an array of all the buttons, needed for drawing them
 * No inputs
 * Returns: a NSMutableArray that contains the buttons that needed to be drawn
 *          except the pause button for some reason
 *------------------------------------------------------------------------------------------*/
-(NSMutableArray*)GetButtonArray
{
    // @TODO: Take into account other buttons.
    NSMutableArray* retArray = [NSMutableArray arrayWithCapacity:RAINBOW_NUM_PLAYERS*RAINBOW_NUM_CARDS_IN_HAND + 1];
    
    for (int i = 0; i < RAINBOW_NUM_PLAYERS; i++)
    {
        for (int j = 0; j<RAINBOW_NUM_CARDS_IN_HAND; j++)
        {
            [retArray addObject:mHands[i].mCardButton[j]];
        }
    }
    
    [retArray addObject:mDiscardButton];
    return retArray;
}

-(HandStateMachineRainbow*)GetHSM
{
	GameRainbow				*gState					= (GameRainbow*) [[ GameStateMgr GetInstance ] GetActiveState ];
	HandStateMachineRainbow	*hsm					= [ gState GetHSM ];
	
	return hsm;
}

/*------------------------------------------------------------------------------------------
 * UpdateScoredStatus
 * Changes the image on for the Card Holders
 * Inputs: the Button index of the card, and whether or not the card is scored
 * Outputs: None
 *------------------------------------------------------------------------------------------*/
-(void)UpdateScoredStatusForCard:(int)ButtonIndex ScoredStatus:(EPlacerStatus)inStatus
{
    int playerIndex = ButtonIndex / RAINBOW_NUM_CARDS_IN_HAND;
    int cardIndex   = ButtonIndex % RAINBOW_NUM_CARDS_IN_HAND;
    [mHands[playerIndex].mCardButton[cardIndex] SetActiveIndex:inStatus];
}

/*------------------------------------------------------------------------------------------
 * UpdateScoredStatus
 * Changes the image on for the Card Holders
 * Inputs: the Player that owns the card, the index of the card, and whether or not the card is scored
 * Outputs: None
 *------------------------------------------------------------------------------------------*/
-(void)UpdateScoredStatusForPlayer:(PlayerHand*)player ForCard:(int)cardIndex ScoredStatus:(EPlacerStatus)inStatus
{
    [mHands[player->mHandIndex].mCardButton[cardIndex] SetActiveIndex:inStatus];
}

/*------------------------------------------------------------------------------------------
 * ChangeTurnNumber
 * Changes the Textfield for the number of turns left
 * Inputs: the player whose turn it is
 * Outputs: None
 *------------------------------------------------------------------------------------------*/
-(void)ChangeTurnNumber:(PlayerHand*) inPlayer
{
    BOOL isVisible = [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] GetVisible];
    
    [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:FALSE];
    
    //If we are in any of these modes, the turns left counter should be disabled
    if (uiStatus == RAINUI_STARTUP || uiStatus == RAINUI_SCORING || uiStatus == RAINUI_DONE_SCORING)
    {
        [mTurnsLeft.strTextbox SetString:@""];
        mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_DISABLED;
    }
    else
    {
        [mTurnsLeft.strTextbox SetString:[NSString stringWithFormat:@"%d",inPlayer->mRainbowTurnsLeft]];

        if (inPlayer->mHandOwner == HAND_OWNER_DEALER)
        {
            //Since it is the dealer's turn, the button array should be diabled
            [mDiscardButton SetActiveIndex:CONFIRM_BUTTON_DISABLED];
            [mStandButton SetActiveIndex:STAND_BUTTON_DISABLED];
            [mUniqueButton SetActiveIndex:UNIQUE_BUTTON_DISABLED];
            
            // then set the turn counter according to who goes next
            if([[self GetHSM] playerForNextTurn] == inPlayer)
            {
                mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_DEALERBEGIN;
            }
            else
            {
                mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_DEALEREND;

            }
        }
        else
        {
            //When the player starts thier turn, they have no cards face down so the discard button is disabled, and the stand button is active
            [mUniqueButton SetActiveIndex:UNIQUE_BUTTON_ENABLED];
            [mStandButton SetActiveIndex:STAND_BUTTON_INACTIVE];
            [mDiscardButton SetActiveIndex:CONFIRM_BUTTON_DISABLED];
            
            // then set the turn counter according to who goes next
            if([[self GetHSM] playerForNextTurn] == inPlayer)
            {
                mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_PLAYERBEGIN;
            }
            else
            {
                mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_PLAYEREND;
            }
        }
    }

    [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:isVisible];
}

/*------------------------------------------------------------------------------------------
 * SetHandStatus
 * Changes how bright the hand holders are
 * Inputs: the hand to change, and whether it is thier turn or not
 * Outputs: None
 *------------------------------------------------------------------------------------------*/
-(void)SetHandStatusForHand:(PlayerHand*)inHand WithTurn:(BOOL)isYourTurn
{
    ENumTurnsLeftStatus comparer;
    for (int i = 0; i < [inHand count]; i++)
    {
        comparer = [mHands[inHand->mHandIndex].mCardButton[i] GetActiveIndex];
    
        if (comparer != NUMTURNSLEFT_DISABLED && comparer != NUMTURNSLEFT_NUM)
        {
            if (isYourTurn)
            {
                if (comparer == PLACER_NOTSCORED_INACTIVE)
                {
                    [mHands[inHand->mHandIndex].mCardButton[i] SetActiveIndex:PLACER_NOTSCORED_ACTIVE];
                }
                if (comparer == PLACER_SCORED_INACTIVE)
                {
                    [mHands[inHand->mHandIndex].mCardButton[i] SetActiveIndex:PLACER_SCORED_ACTIVE];
                }
            }
            else
            {
                if (comparer == PLACER_NOTSCORED_ACTIVE)
                {
                    [mHands[inHand->mHandIndex].mCardButton[i] SetActiveIndex:PLACER_NOTSCORED_INACTIVE];
                }
                if (comparer == PLACER_SCORED_ACTIVE)
                {
                    [mHands[inHand->mHandIndex].mCardButton[i] SetActiveIndex:PLACER_SCORED_INACTIVE];
                }
            }
            
        }
    }
}

-(void) SetStandStatusForPlayer:(PlayerHand*)player
{
    ERainbowStandIconStatus owner;
    if (player->mHandOwner == HAND_OWNER_DEALER)
        owner = STANDSTATUS_DEALER_STOOD;
    else
        owner = STANDSTATUS_PLAYER_STOOD;
    
    [mStandStatus[player->mHandIndex].images[STANDSTATUS_HAS_NOT_STOOD] SetVisible:FALSE];
    [mStandStatus[player->mHandIndex].images[owner] SetVisible:TRUE];
}
-(void)dealloc
{
    [super dealloc];
}

/*------------------------------------------------------------------------------------------
 * ButtonEvent
 *
 *------------------------------------------------------------------------------------------*/
-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    [inButton EndPulse];
    
    if (inEvent == BUTTON_EVENT_UP)
    {
        if (inButton == mPauseButton)
        {
            [ [GameStateMgr GetInstance] Push:[PauseMenu alloc] ];
        }
        //The discard button preforms different actions depending on the uistatus
        else if (inButton == mDiscardButton)
        {
            if (uiStatus == RAINUI_DECISION)
            {
                [ [GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_DISCARD withData:NULL ];
            }
            else if (uiStatus == RAINUI_DONE_SCORING)
            {
                [ [GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_NEW_ROUND withData:NULL ];
            }
        }
        //The other buttons, stand and unique, should only be available when it is the players turn
        if (uiStatus == RAINUI_DECISION)
        {
            if (inButton == mStandButton)
            {
                if ([mStandButton GetActiveIndex] == STAND_BUTTON_ACTIVE)
                {
                    [ [GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_STAND withData:(void*)(TRUE)];
                }
                else
                {
                    [ [GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_STAND withData:(void*)(FALSE)];
                    [mStandButton SetActiveIndex:STAND_BUTTON_ACTIVE];
                }
            }
            else if (inButton == mUniqueButton)
            {
                [ [GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_UNIQUE withData:NULL ];
            }
        }
    }
    
    else if (inEvent == BUTTON_EVENT_DOWN)
    {
        //Show the end game buttons
        if ( inButton == mEndGameButton[ENDGAMEBUTTON_LEVELSELECT]	||
            inButton == mEndGameButton[ENDGAMEBUTTON_RETRY]		||
            inButton == mEndGameButton[ENDGAMEBUTTON_ADVANCE]		)
		{
            [ [GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_END_OPTION_SELECTED withData:(void*)(inButton->mIdentifier) ];

        }
        // the player has pressed on of the card placers
        if (inButton != mPauseButton && inButton != mDiscardButton && inButton != mStandButton && inButton != mUniqueButton)
        {
            if (uiStatus == RAINUI_DECISION)
            {
                [ [ GameStateMgr GetInstance] SendEvent:EVENT_RAINBOW_TOGGLE_DISCARD withData:(void*)inButton->mIdentifier];
            }
        }
    }
    
    return TRUE;
}

-(void)TogglePause:(BOOL)bSuspend
{
    [mPauseButton SetUsage:bSuspend];
}
-(void)SetStatusForButtonArray:(BOOL) isDiscard
{
    if (isDiscard)
    {
        [mStandButton SetActiveIndex:STAND_BUTTON_INACTIVE];
        [mDiscardButton SetActiveIndex:CONFIRM_BUTTON_ENABLED];
    }
    else
    {
        [mDiscardButton SetActiveIndex:CONFIRM_BUTTON_DISABLED];
    }
}

-(void)EndRoundWithWinningPlayer:(PlayerHand*)inHand WithNumCards:(int)inCards
{
    //Turn Counter Stuff
    if (inHand == NULL)
    {
        mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_TIE;
    }
    else
    {
        if (inHand->mHandOwner == HAND_OWNER_DEALER)
        {
            mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_DEALERBEGIN;
            [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft]	SetPosition:&numTurnsHolderDealer];
            [mTurnsLeft.strTextbox	SetPosition:&numTurnsTextDealer];
        }
        else
        {
            mTurnsLeft.statusOfCardsLeft = NUMTURNSLEFT_PLAYERBEGIN;
            [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft]	SetPosition:&numTurnsHolderPlayer];
            [mTurnsLeft.strTextbox	SetPosition:&numTurnsTextPlayer];
        }
    }
    [mTurnsLeft.strTextbox SetString:[NSString stringWithFormat:@"%d",inCards]];

    [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:TRUE];
    [mTurnsLeft.strTextbox SetVisible:TRUE];
    
    [mDiscardButton SetActiveIndex:CONFIRM_BUTTON_ENABLED];
    
    //Win Counter Stuff
    if (inHand != NULL)
    {
        [self SetWinCounterForPlayer:inHand forLetterNumber:inHand->mRainbowRoundsWon-1 withWin:TRUE];
    }
}

-(void)SetWinCounterForPlayer:(PlayerHand*)inHand forLetterNumber:(int)inNumber withWin:(BOOL)didWin
{
    if(inHand->mHandOwner == HAND_OWNER_PLAYER)
    {
        switch (inNumber)
        {
            case 0:
            {
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_R_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_R_PLAYER] SetVisible:didWin];
                break;
            }
            case 1:
            {
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_A_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_A_PLAYER] SetVisible:didWin];
                break;
            }
            case 2:
            {
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_I_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_I_PLAYER] SetVisible:didWin];
                break;
            }
            case 3:
            {
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_N_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[inNumber].images[RAINBOWLETTER_N_PLAYER] SetVisible:didWin];
                break;
            }
        }
    }
    else if(inHand->mHandOwner == HAND_OWNER_DEALER)
    {
        int index = (RAINBOW_NUM_PLAYERS * RAINBOW_NUM_ROUNDS_PER_GAME )-2 - inNumber;
        switch (inNumber)
        {
            case 0:
            {
                
                [mRoundsWon.letters[index].images[RAINBOWLETTER_W_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[index].images[RAINBOWLETTER_W_DEALER] SetVisible:didWin];
                break;
            }
            case 1:
            {
                [mRoundsWon.letters[index].images[RAINBOWLETTER_O_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[index].images[RAINBOWLETTER_O_DEALER] SetVisible:didWin];
                break;
            }
            case 2:
            {
                [mRoundsWon.letters[index].images[RAINBOWLETTER_B_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[index].images[RAINBOWLETTER_B_DEALER] SetVisible:didWin];
                break;
            }
            case 3:
            {
                [mRoundsWon.letters[index].images[RAINBOWLETTER_N_UNSCORED] SetVisible:!didWin];
                [mRoundsWon.letters[index].images[RAINBOWLETTER_N_DEALER] SetVisible:didWin];
                break;
            }
        }
    }
}

-(void)EndGameWithWin:(BOOL)bWin
{
    int i,j;
    
    [mDiscardButton SetVisible:FALSE];
    [mDiscardButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
    [mStandButton SetVisible:FALSE];
    [mStandButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
    [mUniqueButton SetVisible:FALSE];
    [mUniqueButton SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
    
    [mTurnsLeft.images[mTurnsLeft.statusOfCardsLeft] SetVisible:FALSE];
    
    if (bWin)
    {
        for (i = 0; i < RAINBOW_NUM_CARDS_IN_HAND; i++)
        {
            [mHands[0].mCardButton[i] SetVisible:FALSE];
            [mHands[0].mCardButton[i] SetUsage:FALSE];
            [mHands[0].mCardButton[i] SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
            [mHands[1].mCardButton[i] SetActiveIndex:PLACER_DISABLED];

        }
    }
    else
    {
        for (i = 0; i < RAINBOW_NUM_PLAYERS; i++)
        {
            for ( j = 0; j < RAINBOW_NUM_CARDS_IN_HAND; j++)
            {
                [mHands[i].mCardButton[j] SetVisible:FALSE];
                [mHands[i].mCardButton[j] SetUsage:FALSE];
                [mHands[i].mCardButton[j] SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
            }
        }
        [mEndGameButton[ENDGAMEBUTTON_RETRY] SetVisible:TRUE];
        [mEndGameButton[ENDGAMEBUTTON_RETRY] SetUsage:TRUE];
        [mEndGameButton[ENDGAMEBUTTON_LEVELSELECT] SetVisible:TRUE];
        [mEndGameButton[ENDGAMEBUTTON_LEVELSELECT] SetUsage:TRUE];

    }
}

-(void)ShowEndGameStar:(int)StarNum WithScored:(BOOL)bShowFullStar
{
    [mEndGameStars[StarNum+1].starImage[STARSTATUS_NOTAWARDED]	SetVisible:!bShowFullStar];
    [mEndGameStars[StarNum+1].starImage[STARSTATUS_AWARDED]     SetVisible: bShowFullStar];
}

-(void)ShowEndGameButtonsWithStars:(StarLevel) inStar
{
    [mEndGameButton[ENDGAMEBUTTON_LEVELSELECT] SetVisible:TRUE];
    [mEndGameButton[ENDGAMEBUTTON_LEVELSELECT] SetUsage:TRUE];
    [mEndGameLevelCard.levelCard SetVisible:TRUE];
    [mEndGameLevelCard.rating[inStar]  SetVisible:TRUE];
    
    for(int i = 0 ; i < STAR_NUM; i++)
    {
        [mEndGameStars[i].starImage[STARSTATUS_NOTAWARDED]	SetVisible:FALSE];
        [mEndGameStars[i].starImage[STARSTATUS_AWARDED]     SetVisible:FALSE];
    }
    
    for (int i = 0; i < RAINBOW_NUM_CARDS_IN_HAND; i++)
    {
        [mHands[1].mCardButton[i] SetVisible:FALSE];
        [mHands[1].mCardButton[i] SetUsage:FALSE];
        [mHands[1].mCardButton[i] SetConsumesTouchEvents:TOUCHSYSTEM_CONSUME_NONE];
    }
    
    for (int i = 0; i < (RAINBOW_NUM_ROUNDS_PER_GAME * RAINBOW_NUM_PLAYERS) - 1; i++)
    {
        for (int j = 0; j < RAINBOWLETTER_NUM; j++)
        {
            [mRoundsWon.letters[i].images[j] SetVisible:FALSE];
        }
    }
}


@end