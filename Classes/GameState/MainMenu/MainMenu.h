//
//  MainMenu.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "TutorialGameState.h"
#import "Model.h"
#import "GameStateMgr.h"
#import "DebugManager.h"
#import "Button.h"
#import "MenuFlowTypes.h"
#import "UIGroup.h"
#import "SaveSystem.h"
#import "Fader.h"
#import "MultiStateButton.h"
#import "NeonButton.h"
#import "GameRun21.h"
#import "LevelDefinitions.h"

#define NUM_LS_BOTTOM_BUTTONS	2		// How many Level Select Buttons occupy the bottom bar?
#define LS_BUTTON_OFFSET		100		// For IDs
#define OPTIONS_GRADIENT_ID     99

@class Flow;
@class ImageWell;
@class TextBox;
@class StringCloud;
@class NeonArrow;

typedef enum
{
    PUSH_MENU_IAPSTORE,
    PUSH_MENU_NUM
} PushMenus;

typedef struct
{
	UIGroup         *uiObjects;
    UIGroup         *secondaryObjects;
	ENeonMenu		menuID;
} NeonMenu;

typedef enum
{
    LSButton_Back,
    LSButton_Play,
    LSButton_Prev,
    LSButton_Next,
    LSButton_Num
} LevelSelectButtons;

typedef enum
{
    MMButton_Marathon,
    MMButton_Run21,
    MMButton_Rainbow,
    MMButton_NeonWeb,
    MMButton_Options,
    MMButton_BGM,
    MMButton_SFX,
    MMButton_ClearData,
    MMButton_IAP_NoAds,
    MMButton_Contact_Us,
    MMButton_Facebook,
    MMButton_GameCenter,
    MMButton_Powerup_XRay,
    MMButton_Powerup_Tornado,
    MMButton_Powerup_Lives,
    MMButton_Num
} MainMenuButtons;

typedef enum
{
	LSSTATUS_FIRST,
	LSSTATUS_LOCKED = LSSTATUS_FIRST,
	LSSTATUS_AVAILABLE,
	LSSTATUS_NUM
} LevelSelectStatus;


typedef enum
{
    LSID_Back = LS_BUTTON_OFFSET,
    LSID_Play,
    LSID_Prev,
    LSID_Next,
    LSID_LevelButtonBase,
    LSID_NUM
} LevelSelectIDs;

// User Top Level Menu Actions, Right->Left for Aanlytics Tracking
typedef enum
{
    UMA_Main,
    UMA_Options_Start,
    UMA_SFX_OFF = UMA_Options_Start,
    UMA_SFX_ON,
    UMA_BGM_OFF,
    UMA_BGM_ON,
    UMA_Gamecenter,
    UMA_NeonCommunity_UIAlert,
    UMA_NeonCommunity_ContactUs,
    UMA_NeonCommunity_WebComic,
    UMA_NeonCommunity_Cancel,
    UMA_Facebook_UIAlert,
    UMA_Facebook_Login,
    UMA_Facebook_Logout,
    UMA_Facebook_Community,
    UMA_Facebook_Cancel,
    UMA_Options_End = UMA_Facebook_Cancel,
    UMA_Card_Run21,
    UMA_Card_Store,
    UMA_Card_Marathon,
    UMA_Card_Tutorial,
    UMA_NUM
} UserMenuAction;

typedef enum
{
    MAINMENU_SUSPEND_PARTIAL,
    MAINMENU_SUSPEND_FULL
} MainMenuSuspendType;

typedef struct
{
	char*               headerName;
	int                 bestScore;
	MultiStateButton*   button;
	NSMutableArray*     stars;
} LevelSelectHolder;

#define NUM_LEVELS_IN_LEVELSELECT	(LSID_LEVEL_SELECT_LAST - LSID_LEVEL_SELECT_FIRST + 1)

typedef struct
{
	int                     nLevelSelected;
	
	NeonButton*             mBackButton;
    NeonButton*             mNextButton;
    NeonButton*             mPrevButton;
	
	LevelSelectHolder		mLevelButton[RUN21_LEVEL_NUM];
    TextBox*                mLevelDescription[RUN21_LEVEL_NUM];
    ImageWell*              mBG[LEVELSELECT_ROOM_NUM];
    TextBox*                mRoomName[LEVELSELECT_ROOM_NUM];
    LevelSelectRoom         mLevelSelectPage;
    
    TextBox*                mBottomMessage;
} LevelSelectMenu;

typedef struct
{
    ImageWell               *mBG;       //uiObject

 
    TextBox                 *mHiScoreText;
    TextBox                 *mBottomMessage;     //uiObject
} MarathonMenu;

typedef struct
{
    TextBox*        mTornadoAmount;
    TextBox*        mXRayAmount;
    
    StringCloud*    mXRayBuyMore;
    StringCloud*    mTornadoBuyMore;
    
    NeonButton*     mXRayButton;
    NeonButton*     mTornadoButton;
    
    TextBox*        mRemoveAds;
    NeonArrow*      mArrow;
    
    NeonButton*     mRoomUnlockButton;
    StringCloud*    mRoomUnlockStringCloud;
    TextBox*        mConnectingTextBox;
} BottomBarMenu;

typedef enum
{
    MAIN_MENU_MODE_SOUND,
    MAIN_MENU_MODE_HELP,
    MAIN_MENU_MODE_INVALID
} MainMenuMode;

@interface MainMenuParams : NSObject
{
    @public
        MainMenuMode    mMainMenuMode;
}

-(MainMenuParams*)Init;

@end

@interface DeleteDataUIDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface FacebookUIDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface CommunityDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface RefillLivesDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface ReplayTutorialDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface TutorialPromptDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@interface MainMenu : TutorialGameState <ButtonListenerProtocol, FaderCallback, MessageChannelListener, UIAlertViewDelegate>
{
	@private
	NeonMenu                mActiveMenu;
    Flow                    *flowPtr;
    int                     mMaxLevel;
    BOOL                    mSavedSoundOn;
    BOOL                    mSavedMusicOn;
    int                     mNumButtons;
    BOOL                    mSentTerminateMessage;
	
	LevelSelectMenu         levelSelect;
    MarathonMenu            marathon;
    BottomBarMenu           bottomBar;
    
    CommunityDelegate*      mCommunityDelegate;
    DeleteDataUIDelegate*   mDeleteData;
    FacebookUIDelegate*     mFacebookDelegate;
    RefillLivesDelegate*    mRefillLivesDelegate;

	ImageWell*              mProfilePicture;
    NeonButton*             mRoomUnlockButton;
    
    NeonButton*             mNextRoomButton;
    NeonButton*             mPrevRoomButton;
    TextBox*                mRoomUnlockDescription;
    StringCloud*            mRoomUnlockStringCloud;
    TextBox*                mConnectingTextBox;
    
    int                     mMenuTerminateDelay;
    
    MainMenuSuspendType     mSuspendType;
    
    NSMutableArray*         mHintDisabledObjects;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)ProcessMessage:(Message*)inMsg;

-(void)OutOfLivesAlert;

-(void)LeaveMenu;
-(void)InitLogo;
-(void)InitOptionsGradient;
-(void)InitLevelSelectBG;
-(void)InitLSRoom:(LevelSelectRoom)inRoomIndex;
-(NeonButton*)InitLevelSelectBottomButton:(LevelSelectButtons)linkMenuID levelSelectID:(LevelSelectIDs)lsID;
-(void)InitMenu:(ENeonMenu)menuID;
-(NeonButton*)InitMainMenuButton:(ENeonMenu)linkMenuID MMID:(MainMenuButtons)mmButtonID visible:(BOOL)bVisible on:(BOOL)bToggledOn enabled:(BOOL)bEnabled uiGroup:(UIGroup*)inUIGroup;
-(NeonButton*)InitMainMenuButton:(ENeonMenu)linkMenuID MMID:(MainMenuButtons)mmButtonID visible:(BOOL)bVisible on:(BOOL)bToggledOn enabled:(BOOL)bEnabled uiGroup:(UIGroup*)inUIGroup position:(Vector3*)inPosition;
-(void)InitBackButton:(ENeonMenu)menuID;

-(void)ActivateMenu:(ENeonMenu)menuID;
-(void)ActivateMainMenu;
-(void)ActivateTextBox:(NSString*)prompt;
-(void)ActivateLevelSelectMenu;
-(void)ActivateLevelSelectRoom;
-(void)ActivateLevelSelectRoomLockDescription;
-(void)ActivateLevelSelectTitle;
-(void)ActivateLevelSelectCard:(int)cardID;
-(void)ActivatePlayTutorial:(ENeonMenu)menuID;
-(void)ActivateLevelSelectOptions;
-(void)ActivateRoomUnlockButtonWithPositionX:(float)inX y:(float)inY unlockButton:(NeonButton**)outButton stringCloud:(StringCloud**)outStringCloud connectingTextBox:(TextBox**)outTextBox;

-(void)TutorialComplete;

-(LevelSelectRoom)GetLevelSelectPage;
+(NSString*)GetRoomLockDescription;

-(void)SetCurrentMenuActive:(BOOL)inActive;

-(void)EvaluateAudioOptions;
-(void)EvaluateXrayIndicators;
-(void)EvaluateTornadoIndicators;
-(BOOL)ShouldShowBottomBarRoomUnlockButton;

-(LevelSelectMenu*)GetLevelSelect;

// Player status
-(void)InitBottomBar;
-(void)UpdateBottomBar;

-(void)FadeComplete:(NSObject*)inObject;
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

+(NSString*)emptyStarFilename;
+(NSString*)fullStarFilenameForRoom:(LevelSelectRoom)inRoom;
+(NSString*)fullStarFilenameForLevel:(int)inLevel;

@end