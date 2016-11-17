//
//  RainbowUI.h
//  Neon21
//
//  Copyright (c) 2012 Neon Games.
//

#import "GlobalUI.h"
#import "GameRainbow.h"

#define ENDGAME_ID_OFFSET    (100)


typedef enum
{
    RAINUI_STARTUP,
    RAINUI_DEALING,
    RAINUI_DECISION,
    RAINUI_SCORING,
    RAINUI_DONE_SCORING,
	RAINUI_NUM
	
} ERainbowUIStatus;

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
    PLACER_DISABLED,
    PLACER_NOTSCORED_INACTIVE,
    PLACER_NOTSCORED_ACTIVE,
    PLACER_SCORED_INACTIVE,
    PLACER_SCORED_ACTIVE,
    PLACER_NUM
}EPlacerStatus;

typedef enum
{
    CONFIRM_BUTTON_DISABLED,
    CONFIRM_BUTTON_ENABLED,
    CONFIRM_BUTTON_NUM,
}EConfirmStatus;

typedef enum
{
    STAND_BUTTON_DISABLED,
    STAND_BUTTON_INACTIVE,
    STAND_BUTTON_ACTIVE,
    STAND_BUTTON_NUM
}EStandStatus;

typedef enum
{
    UNIQUE_BUTTON_DISABLED,
    UNIQUE_BUTTON_ENABLED,
    UNIQUE_BUTTON_NUM,
}EUniqueStatus;

typedef enum
{
	NUMTURNSLEFT_DISABLED,
	NUMTURNSLEFT_PLAYERBEGIN,
    NUMTURNSLEFT_PLAYEREND,
    NUMTURNSLEFT_DEALERBEGIN,
    NUMTURNSLEFT_DEALEREND,
    NUMTURNSLEFT_TIE,
	NUMTURNSLEFT_NUM,
	
} ENumTurnsLeftStatus;

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
    RAINBOWLETTER_FIRST,
    RAINBOWLETTER_R_DEALER = RAINBOWLETTER_FIRST,
    RAINBOWLETTER_R_PLAYER,
    RAINBOWLETTER_R_UNSCORED,
    RAINBOWLETTER_A_DEALER,
    RAINBOWLETTER_A_PLAYER,
    RAINBOWLETTER_A_UNSCORED,
    RAINBOWLETTER_I_DEALER,
    RAINBOWLETTER_I_PLAYER,
    RAINBOWLETTER_I_UNSCORED,
    RAINBOWLETTER_N_DEALER,
    RAINBOWLETTER_N_PLAYER,
    RAINBOWLETTER_N_UNSCORED,
    RAINBOWLETTER_B_DEALER,
    RAINBOWLETTER_B_PLAYER,
    RAINBOWLETTER_B_UNSCORED,
    RAINBOWLETTER_O_DEALER,
    RAINBOWLETTER_O_PLAYER,
    RAINBOWLETTER_O_UNSCORED,
    RAINBOWLETTER_W_DEALER,
    RAINBOWLETTER_W_PLAYER,
    RAINBOWLETTER_W_UNSCORED,
    RAINBOWLETTER_NUM,
    
}ERainbowLetter;

typedef enum
{
    STANDSTATUS_FIRST,
    STANDSTATUS_HAS_NOT_STOOD = STANDSTATUS_FIRST,
    STANDSTATUS_PLAYER_STOOD,
    STANDSTATUS_DEALER_STOOD,
    STANDSTATUS_NUM,
}ERainbowStandIconStatus;

typedef struct
{
	ImageWell*				images[NUMTURNSLEFT_NUM];
    TextBox*				strTextbox;
	ENumTurnsLeftStatus     statusOfCardsLeft;
	
} sRainbowNumTurnsLeft;

typedef struct
{
    ImageWell*              images[RAINBOWLETTER_NUM];
}RainbowLetter;

typedef struct
{
    RainbowLetter           letters[(RAINBOW_NUM_ROUNDS_PER_GAME * RAINBOW_NUM_PLAYERS)-1];
    int                     playerWins;
    int                     dealerWins;
} sRainbowWinCounter;

typedef struct
{
    BOOL                    mFaceUp;
    TextBox*                mTextBox;
	MultiStateButton*		mCardButton[RAINBOW_NUM_CARDS_IN_HAND];
} RainbowHand;

typedef struct
{
	ImageWell*				starImage[STARSTATUS_NUM];
} sEndGameStar;

typedef struct
{
    ImageWell*              levelCard;
    ImageWell*				rating[STAR_NUM];
} sEndGameLevelCard;

typedef struct
{
    ImageWell*      images[STANDSTATUS_NUM];
    BOOL            bHasStood;
}RainbowStandStatus;

@class RainbowEnvironment;

@interface RainbowUI : GlobalUI
{
@public
    
    RainbowHand				mHands[RAINBOW_NUM_PLAYERS];

@private
    ERainbowUIStatus		uiStatus;
    ERainbowUIStatus		restoredUIStatus;	// If paused

    TextureButton*			mPauseButton;
    RainbowEnvironment*		mEnvironment;
    MultiStateButton*       mDiscardButton;
    MultiStateButton*       mStandButton;
    MultiStateButton*       mUniqueButton;
    sRainbowNumTurnsLeft    mTurnsLeft;
    RainbowStandStatus      mStandStatus[RAINBOW_NUM_PLAYERS];
    sRainbowWinCounter      mRoundsWon;
    
    NeonButton*				mEndGameButton[ENDGAMEBUTTON_NUM];
    sEndGameLevelCard       mEndGameLevelCard;
    sEndGameStar			mEndGameStars[STAR_NUM];
    
    Matrix44				mTableLTWTransform;
}


-(RainbowUI*)InitWithEnvironment:(RainbowEnvironment*)inEnvironment;
-(BOOL)HackIsRetinaProjected;
-(void)InitInterfaceGroups;
-(void)InitHandHolders;
-(void)InitDiscardButton;
-(void)InitStandButton;
-(void)InitUniqueButton;
-(void)InitTurnCounter;
-(void)InitWinCounter;
-(void)InitStandIndicators;
-(void)InitPauseButton;
-(void)InitEndGameButtons;
-(void)InitEndGameStars;
-(void)InitEndGameLevelCard;

-(void)InterfaceMode:(ERainbowUIStatus)inMode;
-(NSMutableArray*)GetButtonArray;
-(void)UpdateScoredStatusForCard:(int)CardIndex ScoredStatus:(EPlacerStatus)inStatus;
-(void)UpdateScoredStatusForPlayer:(PlayerHand*)player ForCard:(int)cardIndex ScoredStatus:(EPlacerStatus)inStatus;
-(void)ChangeTurnNumber:(PlayerHand*)inPlayer;
-(void)SetHandStatusForHand:(PlayerHand*)inHand WithTurn:(BOOL)isYourTurn;
-(void)SetStandStatusForPlayer:(PlayerHand*)player;
-(void)dealloc;
-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
-(void)TogglePause:(BOOL)bSuspend;
-(void)EndRoundWithWinningPlayer:(PlayerHand*)inPlayer WithNumCards:(int)inCards;
-(void)EndGameWithWin:(BOOL)bWin;
-(void)ShowEndGameStar:(int)StarNum WithScored:(BOOL)bShowFullStar;
-(void)ShowEndGameButtonsWithStars:(StarLevel) inStar;
-(void)SetStatusForButtonArray:(BOOL) isDiscard;
-(void)SetWinCounterForPlayer:(PlayerHand*)inHand forLetterNumber:(int)inNumber withWin:(BOOL)didWin;

@end
