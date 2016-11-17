//
//  Run21UI.h
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011

// Imports
#import "GlobalUI.h"
#import "InAppPurchaseManager.h"
#import "Fader.h"

#define ENDGAME_ID_OFFSET    (100)

#define ENABLE_TABLET_AS_BUTTON (0)
#define MAX_UNSCALED_RUNNERS    (4)

@class StringCloud;

typedef enum
{
    TABLETSCOREBOARD_LOCATION_TOP,
    TABLETSCOREBOARD_LOCATION_BOTTOM,
    TABLETSCOREBOARD_LOCATION_NUM,
} ETabletScoreboardLocation;

typedef enum
{
	RAS_INACTIVE,				// No texture
	RAS_BUSTED,					// Gray Outline w/ lock
	RAS_UNAVAILABLE,			// No texture , for when a row is not selectable ( in between states )
	RAS_AVAILABLE,				// Blue , for when a row is selectable ( card in play )
	RAS_SELECTED,				// Yellow , for when the placer card does not bust or clear a row
	RAS_WILLCLEAR,				// Green , for when the placer card would cause a clear event
	RAS_WILLBUST,				// Red , for when the placer card would cause a bust.
	RAS_NUM,
} ERowActiveState;

typedef enum
{
	R21UI_PoweredOff,
	R21UI_Startup,
	R21UI_ConfirmNotAvailable,
	R21UI_ConfirmAvailable,
	R21UI_InBetweenStates,
	R21UI_NUM,
	
} ERun21UIStatus;

typedef enum
{
	NUMCARDSLEFT_Inactive,
	NUMCARDSLEFT_ClubsRemove,
	NUMCARDSLEFT_DealRainbow,
	NUMCARDSLEFT_PlayerActive,
	NUMCARDSLEFT_SuddenDeath,
	NUMCARDSLEFT_NUM,
	
} ENumCardsLeftHolderStatus;

typedef enum
{
	STARSTATUS_FIRST,
	STARSTATUS_NOTAWARDED = STARSTATUS_FIRST,
	STARSTATUS_AWARDED,
	STARSTATUS_LAST = STARSTATUS_AWARDED,
	STARSTATUS_NUM,
} EStarStatus;

typedef enum
{
	ENDGAMEBUTTON_FIRST = 0,
	ENDGAMEBUTTON_LEVELSELECT = ENDGAMEBUTTON_FIRST,
	ENDGAMEBUTTON_RETRY,
	ENDGAMEBUTTON_ADVANCE,
	ENDGAMEBUTTON_LAST = ENDGAMEBUTTON_ADVANCE,
	ENDGAMEBUTTON_NUM,
	
} EEndGameButtons;

typedef enum
{
    MARATHONEVENT_FIRST         = 0,
    MARATHONEVENT_21            = MARATHONEVENT_FIRST,
    MARATHONEVENT_CHARLIE,
    MARATHONEVENT_ROW_PASSED,
    MARATHONEVENT_ROW_LOCKED,
    MARATHONEVENT_MULTIPLIER_UP,
    MARATHONEVENT_STARTSESSION,
    MARATHONEVENT_END_SESSION,
    MARATHONEVENT_LAST          = MARATHONEVENT_21,
    MARATHONEVENT_NUM,
} EMarathonEvent;

typedef enum
{
    POWERUPSTATE_DISABLED,
    POWERUPSTATE_UNAVAILABLE,
    POWERUPSTATE_AVAILABLE,
    POWERUPSTATE_NUM
}EPowerUpStates;

typedef enum
{
    RUN21_UI_STATE_NORMAL,
    RUN21_UI_STATE_WAITING_TO_AUTOEXIT
} Run21UIState;

typedef enum
{
    ENDGAME_POWERUP_FIRST,
#if USE_LIVES && USE_TORNADOES
    ENDGAME_POWERUP_LIVES = ENDGAME_POWERUP_FIRST,
    ENDGAME_POWERUP_TORNADO,
#elif USE_TORNADOES
    ENDGAME_POWERUP_TORNADO = ENDGAME_POWERUP_FIRST,
#else
    ENDGAME_POWERUP_XRAY = ENDGAME_POWERUP_FIRST,
#endif

#if USE_LIVES || USE_TORNADOES
    ENDGAME_POWERUP_XRAY,
#endif
    ENDGAME_POWERUP_NUM
}EEndGamePowerupCounter;

typedef struct
{
    TextBox*					mTextBox;
	ERowActiveState				status;
	MultiStateButton*			mRunnerButton;
} Run21Row;

typedef struct
{
	ImageWell*					images[NUMCARDSLEFT_NUM];
    TextBox*					strTextbox;
	ENumCardsLeftHolderStatus	statusOfCardsLeft;
	
} sRun21NumCardsHolder;

typedef struct
{
	EJokerStatus				status[CARDSUIT_JOKER_MAX];
	ImageWell*					imageSlot1[JokerStatus_MAX];
	ImageWell*					imageSlot2[JokerStatus_MAX];
	ImageWell*					holderSlot1[JokerStatus_MAX];
	ImageWell*					holderSlot2[JokerStatus_MAX];
	
} sJokerHolder;

typedef struct
{
	ImageWell*					starImage[STARSTATUS_NUM];
} sEndGameStar;

typedef struct
{
    ImageWell*                  levelCard;
    ImageWell*					emptyStar;
    ImageWell*                  fullStar;
} sEndGameLevelCard;

typedef struct
{
    IapProduct          mConsumableType;
    NeonButton*         mUseButton;
    NeonButton*         mBuyMoreButton;
    int                 mNumUsesLeft;
    TextBox*            mNumUsesText;
    StringCloud*        mBuyMoreIndicator;
} PowerupButton;

typedef struct
{
    ImageWell*  mHolder;
    ImageWell*  mMeter;
    ImageWell*  mProfilePic;
    TextBox*    mCurrentLevelText;
    TextBox*    mNextLevelText;
    float       mPercentFilled;
    int         mCurrentLevel;
}LevelUpBar;

typedef struct
{
    NeonButton* mButton;
    TextBox*    mNumLeft;
}EndGamePowerupCounter;

typedef enum
{
    UI_TIMERSTATE_NORMAL,
    UI_TIMERSTATE_CRITICAL
} UITimerState;

@class Run21Environment;

@interface Run21UI : GlobalUI <FaderCallback, MessageChannelListener>
{
// TODO: Remove Public.
@public
	Run21Row				mRow[MAX_PLAYER_HANDS];
    Run21Environment*		mEnvironment;
@private
	ERun21UIStatus			uiStatus;
	ERun21UIStatus			restoredUIStatus;	// If paused

    TextureButton*          mAdButton;
    TextureButton*          mPauseButton;
    
	MultiStateButton*		mPlacerButton;
	
	sJokerHolder			mJokers;
	sRun21NumCardsHolder	mCardsLeft;
	NeonButton*				mEndGameButton[ENDGAMEBUTTON_NUM];
	sEndGameStar			mEndGameStars[MAX_PLAYER_HANDS];
    sEndGameLevelCard       mEndGameLevelCard;
    
    PowerupButton           mXRayButton;
    PowerupButton           mWhirlwindButton;
	LevelUpBar              mLevelUpBar;
    EndGamePowerupCounter   mPowerupCounters[ENDGAME_POWERUP_NUM];
    TextBox*                mTimeUntilNextLife;
    TextBox*                mTimeRemaining;
    int                     mNumJumbotronRows;
    
	Matrix44				mTableLTWTransform;
    
    GameRun21*              mGameRun21;
    
	NeonButton*             mTutorialSkipButton;
    BOOL                    mGameOver;
    Path*                   mTimerShakingPositionPath;
    
    UITimerState            mUITimerState;
    Run21UIState            mUIState;
    CFTimeInterval          mTimeRemainingUntilAutoExit;
}

-(BOOL)HackIsRetinaProjected;
-(Run21UI*)InitWithEnvironment:(Run21Environment*)inEnvironment gameState:(GameRun21*)inGameRun21;
-(void)InitNumCardsHolder;
-(void)InitRunnerHolders;
-(void)InitScorerHolders;
-(void)InitPlacer;
-(void)InitInterfaceGroups;
-(void)InitPauseButton;
-(void)InitEndGameButtons;
-(void)InitEndGameStars;
-(void)InitEndGameLevelCard;
-(void)InitEndGamePowerupCounters;
-(void)InitPowerupButtons;
-(void)InitTutorialSkipButton;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)TutorialComplete;

+(float)GetRunnerHeight;
+(float)GetRunnerSpacing;
+(float)GetRunnerYOrigin;

-(ImageWell*)InitLevelUpImageWithFile:(const char *)imageFilename texture:(Texture*)inTexture withLocation:(Vector3*)loc uiGroup:(UIGroup*)inUIGroup;
-(void)InitLevelUpBar;
-(void)dealloc;
-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
-(void)InterfaceMode:(ERun21UIStatus)status;
-(void)InterfaceVisibleWithConfirm:(BOOL)bConfirmPlacement CardRows:(BOOL)bActiveRowsVisible CardsLeftHolder:(BOOL)bCardsLeftHolderVisible Scoreboard:(BOOL)bScoreboardVisible;
-(void)DeactivateRow:(int)nButtonID;
-(void)PlayerDecisionForHand:(PlayerHand*)inHand handIndex:(int)inHandIndex remainingCards:(int)inRemainingCards JokerStatus1:(EJokerStatus)joker1 JokerStatus2:(EJokerStatus)joker2;
-(void)UpdateJokerHolders;
-(void)InitJokerHolders;
-(void)TogglePause:(BOOL)bSuspend;
-(void)UpdateNumCardsStatus:(ENumCardsLeftHolderStatus)status;
-(void)UpdateRASStatusWithRow:(int)nRowID Status:(ERowActiveState)inStatus;
-(BOOL)IsInStatus:(ENumCardsLeftHolderStatus)status;
-(void)RAS_DeselectAll;
-(void)Placer_UpdateStatus;
-(void)CardsLeftWith:(int)nCardsLeft;
-(void)JokerStatus:(EJokerStatus)joker1 JokerStatus2:(EJokerStatus)joker2;
-(void)EndGameWithWin:(BOOL)bWonGame WithHiScore:(BOOL)bHiScore WithStars:(int)nStars;
-(void)EndGamePreClear;
-(void)ResetGameMarathon;
-(void)MarathonClearStars;
-(void)EndGameClearRow:(int)nRow;
-(UIGroup*)GetEndGameUIGroup;
-(void)SetEndGamePowerupStrings;
-(void)UpdatePowerupAmounts;

-(NSMutableArray*)GetButtonArray;
-(BOOL)IsRunner:(UIObject*)inObject;
-(void)FadeComplete:(NSObject*)inObject;

-(void)ProcessMessage:(Message*)inMsg;

@end