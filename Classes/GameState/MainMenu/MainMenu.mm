//
//  MainMenu.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "MainMenu.h"
#import "TextTextureBuilder.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "ResourceManager.h"
#import "ModelManager.h"
#import "TextureManager.h"
#import "GameObjectManager.h"
#import "GameCutscene.h"
#import "SaveSystem.h"
#import "ExperienceManager.h"

#import "InAppPurchaseManager.h"
#import "AchievementManager.h"
#import "RegenerationManager.h"

#import "Texture.h"
#import "NeonButton.h"
#import "ImageWell.h"
#import "TextBox.h"
#import "NeonArrow.h"
#import "Card.h"
#import "Flow.h"
#import "NeonAccountManager.h"

#import "SoundPlayer.h"
#import "NeonMusicPlayer.h"
#import "UINeonEngineDefines.h"
#import "Neon21AppDelegate.h"

#import <sys/utsname.h>
#import "IAPStore.h"
#import "FacebookLoginMenu.h"
#import "SplitTestingSystem.h"
#import "StringCloud.h"

#import "HintSystem.h"
#import "OverlayState.h"
#import "TutorialScript.h"
#import "AdvertisingManager.h"

#define LOG_MAINMENU            1

#define BUTTON_FADE_SPEED		(7.0)
#define NUM_MENU_SLOTS			5

#define BIGSTAR_ORIGIN_X 89
#define BIGSTAR_ORIGIN_Y 60
#define BIGSTAR_ORIGIN_Z 0

#define BIGSTAR_OFFSET_X 82

#define iAD_Shift_SmallY 16
#define iAD_Shift_LargeY 32

#define GAME_ORIENTATION                UIInterfaceOrientationLandscapeRight

// Previously used the same colors as the buttons backgrounds, switching to white for readability.
static const int    mainMenuButtonFontColors[CARDSUIT_NumSuits]			= { 0xFFFFFFFF,	// 0x158dfaFF
																			0xFFFFFFFF, // 0xee2929FF
																			0xFFFFFFFF, // 0xe1df24FF
																			0xFFFFFFFF};// 0x33f08fFF
                                                                            
static const int    mainMenuButtonFontBorderColors[CARDSUIT_NumSuits]   = { 0x0d52dfFF,
																			0x7f1010FF,
																			0xa9a616FF,
																			0x20c55aFF};

static const char*  mainMenuButtonTextureLogo						= { "bg_run21_nomarathon.papng" };

static const char*  levelselectBGImage[LEVELSELECT_ROOM_NUM]        = { "bg_ls_bronze.papng",
                                                                        "bg_ls_silver.papng",
                                                                        "bg_ls_gold.papng",
                                                                        "bg_ls_emerald.papng",
                                                                        "bg_ls_sapphire.papng",
                                                                        "bg_ls_ruby.papng",
                                                                        "bg_ls_diamond.papng"};

static const char*  levelselectRoomNames[LEVELSELECT_ROOM_NUM]      = { "LS_Room_Bronze",
                                                                        "LS_Room_Silver",
                                                                        "LS_Room_Gold",
                                                                        "LS_Room_Emerald",
                                                                        "LS_Room_Sapphire",
                                                                        "LS_Room_Ruby",
                                                                        "LS_Room_Diamond"};

static const char*  fullStarIconNames[LEVELSELECT_ROOM_NUM]         = { "bronzestar_full.papng",
                                                                        "silverstar_full.papng",
                                                                        "goldstar_full.papng",
                                                                        "emeraldstar_full.papng",
                                                                        "sapphirestar_full.papng",
                                                                        "rubystar_full.papng",
                                                                        "shootingstar_full.papng" };

static const char*  emptyStarIconName                               = "star_empty.papng";

static Vector3		sLogoPosition										= {0, 0, 0};
static Vector3		sLevelSelectSmallStarOffset							= {4, 4, 0};
static Vector3		sLS_RoomNameLoc										= {240, 38 - iAD_Shift_SmallY, 0};
static const int    sLSCardWidth                                        = 60;
static const int    sLSStarWidth                                        = 14;

static Vector3		sLS_LevelPos[NUM_LEVELS_IN_ROOM]                    = { { 113, 120 - iAD_Shift_LargeY, 0 }, { 204, 120 - iAD_Shift_LargeY, 0}, { 295, 120 - iAD_Shift_LargeY, 0} };

static const char*  MMOff[MMButton_Num]                                 = { "menu_marathon.papng",                      // MMButton_Marathon
                                                                            "menu_run21.papng",                         // MMButton_Run21
                                                                            "menu_cog_closed.papng",                    // MMButton_Rainbow
                                                                            "neongames.papng",                          // MMButton_NeonWeb
                                                                            "menu_cog_closed.papng",                    // MMButton_Options
                                                                            "menu_music_off.papng",                     // MMButton_BGM
                                                                            "menu_sfx_off.papng",                       // MMButton_SFX
                                                                            "menu_deletesave_off.papng",                // MMButton_ClearData
                                                                            "menu_iap.papng",                           // MMButton_IAP_NoAds
                                                                            "menu_neon.papng",                          // MMButton_Contact_Us
                                                                            "menu_facebook.papng",                      // MMButton_Facebook
                                                                            "menu_gamecenter.papng",                    // MMButton_GameCenter
                                                                            "menu_levelselect_xray.papng",
                                                                            "menu_levelselect_tornado.papng",
                                                                            "menu_levelselect_lives.papng"};


static const char*  MMUnlit[MMButton_Num]                               = { "menu_marathon.papng",                      // MMButton_Marathon
                                                                            "menu_run21.papng",                         // MMButton_Run21
                                                                            "menu_cog_closed.papng",                    // MMButton_Rainbow
                                                                            "neongames.papng",                          // MMButton_NeonWeb
                                                                            "menu_cog_closed.papng",                    // MMButton_Options
                                                                            "menu_music_on.papng",                      // MMButton_BGM
                                                                            "menu_sfx_on.papng",                        // MMButton_SFX
                                                                            "menu_deletesave_on.papng",                 // MMButton_ClearData
                                                                            "menu_iap.papng",                           // MMButton_IAP_NoAds
                                                                            "menu_neon.papng",                          // MMButton_Contact_Us
                                                                            "menu_facebook.papng",                      // MMButton_Facebook
                                                                            "menu_gamecenter.papng",                    // MMButton_GameCenter
                                                                            "menu_levelselect_xray.papng",
                                                                            "menu_levelselect_tornado.papng",
                                                                            "menu_levelselect_lives.papng"};

static const char*  MMLit[MMButton_Num]                                 = { "menu_marathon_glow.papng",                 // MMButton_Marathon
                                                                            "menu_run21_glow.papng",                    // MMButton_Run21
                                                                            "menu_cog_glow.papng",                      // MMbuttton_Rainbow
                                                                            "neongames_glow.papng",                     // MMButton_NeonWeb
                                                                            "menu_cog_glow.papng",                      // MMButton_Options
                                                                            "menu_options_glow.papng",                  // MMButton_BGM
                                                                            "menu_options_glow.papng",                  // MMButton_SFX
                                                                            "menu_options_glow.papng",                  // MMButton_ClearData
                                                                            "menu_iap_glow.papng",                      // MMButton_IAP_NoAds
                                                                            "menu_options_glow.papng",                  // MMButton_Contact_Us
                                                                            "menu_options_glow.papng",                  // MMButton_Facebook
                                                                            "menu_options_glow.papng",                  // MMButton_GameCenter
                                                                            "menu_levelselect_xray_glow.papng",
                                                                            "menu_levelselect_tornado_glow.papng",
                                                                            "menu_levelselect_lives_glow.papng"};


#define TOPBAR_IMAGE_EXT        480
#define TOPBAR_IMAGE_WIDTH      29
#define TOPBAR_IMAGE_MARGIN     30
#define TOPBAR_LOC_Y            10

#define ATLAS_PADDING_SIZE          (4)

static const float topbar_y               = 10;
static const float topbar_left            = TOPBAR_IMAGE_MARGIN;
static const float topbar_center          = ((TOPBAR_IMAGE_EXT - TOPBAR_IMAGE_WIDTH) / 2 );
static const float topbar_right           = TOPBAR_IMAGE_EXT - TOPBAR_IMAGE_MARGIN - TOPBAR_IMAGE_WIDTH;
static const float topbar_leftcenter      = (( topbar_center - topbar_left ) / 2) + topbar_left;
static const float topbar_rightcenter     = (( topbar_right - topbar_center) / 2) + topbar_center;

static Vector3		MMPos[MMButton_Num]                                 = {
                                                                            { 0 , 201, 0	},                      // MMButton_Marathon
                                                                            { 310, 201, 0	},                      // MMButton_Run21
                                                                            { 200, 100, 0   },                      // MMButton_Rainbow
                                                                            { 0 , 0  , 0	},                      // MMButton_NeonWeb
                                                                            { 425, 0  , 0	},                      // MMButton_Options
                                                                            { topbar_rightcenter,   topbar_y , 0},  // MMButton_BGM
                                                                            { topbar_right,         topbar_y , 0},  // MMButton_SFX
                                                                            { 230, 10 , 0	},                      // MMButton_ClearData
                                                                            { 165, 201 , 0	},                      // MMButton_IAP_NoAds
                                                                            { topbar_leftcenter,    topbar_y, 0 },  // MMButton_Contact_Us
                                                                            { topbar_left,          topbar_y, 0 },  // MMButton_Facebook
                                                                            { topbar_center,        topbar_y, 0 },  // MMButton_GameCenter
                                                                            { 380, 292, 0   },                      // MMButton_Powerup_XRay
                                                                            { 305, 292, 0   },                      // MMButton_Powerup_Tornado
                                                                            { 225, 292, 0   }};                     // MMButton_Powerup_Lives

static const char*  levelSelectButtonTextureLitName[LSButton_Num]		= { "levelSelect_back_glow.papng"	,"levelSelect_play_glow.papng"  ,"levelSelect_room_prev_glow.papng" ,"levelSelect_room_next_glow.papng"};
static const char*  levelSelectButtonTextureUnlitName[LSButton_Num]		= { "levelSelect_back.papng"		,"levelSelect_play.papng"       ,"levelSelect_room_prev.papng"      ,"levelSelect_room_next.papng"};
static const char*  levelSelectButtonTextureOffName[LSButton_Num]		= { "levelSelect_back.papng"		,"levelSelect_play.papng"       ,"levelSelect_room_prev.papng"      ,"levelSelect_room_next.papng"};
static Vector3		slevelSelectButtonPositions[LSButton_Num]			= { { 214, 269 - iAD_Shift_LargeY, 0	}   , { 0, 0, 0	}                   , { 16, 0, 0	}                   , { 419, 0, 0	}   };

static const char*  levelSelectBottomBarName    = "menu_bottombar.papng";
static const char*  levelUpMeterHolderName      = "menu_levelup_holder.papng";
static const char*  levelUpMeterContentsName    = "menu_levelup_meter.papng";
static const char*  defaultProfilePicture       = "defaultUser.papng";

static Vector3      sLevelSelectBottomBarPosistion  = {  0, 290, 0 };
static Vector3      sLeveupHolderPosistion          = { 14, 292, 0 };
static Vector3      sLeveupMeterPosistion           = { 74, 297, 0 };
static Vector3      sProfilePicturePosition         = { 14, 290, 0 };
//static Vector3      sProfilePictureScale            = { 32.0f / 50.0f, 32.0f / 50.0f, 1.0f };

static const int    sTopBarMenuPadding = 5;
static const int    sTopBarButtonWidth = 29;

static Vector3      sRoomLockDescriptionPositions[ROOM_UNLOCK_STATE_NUM]    = { { 380, 45, 0 },
                                                                                { 380, 85, 0 } };

typedef enum
{
    USERDATA_TYPE_FLOW,
    USERDATA_TYPE_MENU,
    USERDATA_TYPE_POP,
    USERDATA_TYPE_PUSH,
    USERDATA_MAX,
    USERDATA_INVALID = USERDATA_MAX
} UserDataType;

typedef struct
{
    UserDataType mType;
    u32          mData;
    u32          mDataTwo;
} UserData;

static UserData sUserData;

NSString* machineName()
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@implementation MainMenuParams

-(MainMenuParams*)Init
{
    mMainMenuMode = MAIN_MENU_MODE_INVALID;
    return self;
}

@end

@implementation MainMenu

-(void)Startup
{
    [super Startup];
    
    GameObjectBatchParams groupParams;
    
    [GameObjectBatch InitDefaultParams:&groupParams];
    
    groupParams.mUseAtlas = TRUE;
    
	mActiveMenu.uiObjects = [(UIGroup*)[UIGroup alloc] InitWithParams:&groupParams];
    mActiveMenu.secondaryObjects = [(UIGroup*)[UIGroup alloc] InitWithParams:&groupParams];
    
    [[mActiveMenu.secondaryObjects GetTextureAtlas] SetPaddingSize:ATLAS_PADDING_SIZE];
    
    [[GameObjectManager GetInstance] Add:mActiveMenu.uiObjects];
    [[GameObjectManager GetInstance] Add:mActiveMenu.secondaryObjects];
    
    flowPtr =  [ Flow GetInstance];
    flowPtr->mMenuToLoad = NeonMenu_Main;
    
    mNumButtons = 0;
    mSentTerminateMessage = FALSE;

    sUserData.mType = USERDATA_INVALID;
    sUserData.mData = 0;
    
    memset(levelSelect.mLevelButton, 0, sizeof(levelSelect.mLevelButton));
    
    for (int i = 0; i < RUN21_LEVEL_NUM; i++)
    {
        levelSelect.mLevelButton[i].stars = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    mMaxLevel = [[SaveSystem GetInstance] GetMaxLevel];
    
    mSavedSoundOn               = [[SaveSystem GetInstance] GetSoundOn];
    mSavedMusicOn               = [[SaveSystem GetInstance] GetMusicOn];
    
    levelSelect.mLevelSelectPage = [self GetLevelSelectPage];
    
    mMenuTerminateDelay = 0;
    
    mNextRoomButton = NULL;
    mPrevRoomButton = NULL;
    mRoomUnlockDescription = NULL;

    // Change level based on flow state.
    
	// KK->RG : We need to EvaluateMusicForState in the Music Manager in the event we're returning to the main menu.
    [self EvaluateAudioOptions];
    [self SetStingerSpawner:NULL];

#if (UNLOCK_LEVELS > 0)
    [[SaveSystem GetInstance] SetMaxLevel:UNLOCK_LEVELS];
    [[SaveSystem GetInstance] SetMaxLevelStarted:(UNLOCK_LEVELS - 1)];
    
    LevelSelectRoom room = [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:UNLOCK_LEVELS];
    
    [[SaveSystem GetInstance] SetMaxRoomUnlocked:[NSNumber numberWithInt:room]];
    
    for (int level = 0; level < UNLOCK_LEVELS; level++)
    {
        [[SaveSystem GetInstance] SetStarsForLevel:level withStars:1];
    }
#endif
    
    // If we're doing the split test where we show the tutorial immediately, then we're going to skip some initialization
    BOOL skipMainMenu = FALSE;

    if ([[SaveSystem GetInstance] GetMaxLevel] <= RUN21_LEVEL_1)
    {
        skipMainMenu = TRUE;
    }
    
    if (skipMainMenu)
    {
        sUserData.mType = USERDATA_TYPE_FLOW;
        sUserData.mData = RUN21_LEVEL_1;
        sUserData.mDataTwo = GAMEMODE_TYPE_RUN21;
        
        Message msg;
        
        msg.mId = EVENT_MAIN_MENU_PENDING_TERMINATE;
        msg.mData = NULL;
        
        [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];
        
        mSentTerminateMessage = TRUE;
        mMenuTerminateDelay = 2;
    }
    else
    {
        if (mParams != NULL)
        {
            if (((MainMenuParams*)mParams)->mMainMenuMode == MAIN_MENU_MODE_SOUND)
            {
                [self ActivateMenu:NeonMenu_Main_Options];
            }
            else if (((MainMenuParams*)mParams)->mMainMenuMode == MAIN_MENU_MODE_HELP)
            {
                #ifdef NEON_21
                [self ActivateMenu:NeonMenu_HowToPlay];
                #endif
            }
        }
        else
        {
#if NEON_SOLITAIRE_21
            if (![[[Flow GetInstance] GetLevelDefinitions] GetMainMenuUnlocked])
#else
            if (([[SaveSystem GetInstance] GetMaxLevel] <= RUN21_LEVEL_1))
#endif
            {
                [self ActivateMenu:Run21_Main_LevelSelect];
            }
            else
            {
                [self ActivateMenu:NeonMenu_Main];
            }
        }
    }
    
    mDeleteData             = [[DeleteDataUIDelegate    alloc] init];    
    mCommunityDelegate      = [[CommunityDelegate       alloc] init];
    mFacebookDelegate       = [[FacebookUIDelegate      alloc] init];
    mRefillLivesDelegate    = [[RefillLivesDelegate     alloc] init];
    
    mHintDisabledObjects = [[NSMutableArray alloc] init];
    
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    
    [[NeonMetrics GetInstance] logEvent:@"Main Menu Startup" withParameters:NULL];
}

-(void)Resume
{
    if (mSuspendType == MAINMENU_SUSPEND_FULL)
    {
        mNumButtons				= 0;
        mSentTerminateMessage	= FALSE;
        mMaxLevel               = [[SaveSystem GetInstance] GetMaxLevel];
        
        // Deactivate all level select cards
        
        /*for ( int nCard = 0; nCard < NUM_LEVELS_IN_LEVELSELECT; nCard++ )
        {
            [levelSelect.mLevelButton[nCard].button SetActiveIndex:LSSTATUS_AVAILABLE];
        }*/
        
        Flow *gameFlow = [ Flow GetInstance ];
        
        
        //Setup the levelSelectGameOffset, so that the levels select menu can be created correctlys
        if ( Run21_Main_LevelSelect == gameFlow->mMenuToLoad )
        {
            levelSelect.mLevelSelectPage = [self GetLevelSelectPage];
        }

        [[GameObjectManager GetInstance] Add:mActiveMenu.uiObjects];
        [[GameObjectManager GetInstance] Add:mActiveMenu.secondaryObjects];
        
        LevelSelectRoom maxUnlockedRoom = [[SaveSystem GetInstance] GetMaxRoomUnlocked];
        LevelSelectRoom maxLevelRoom = [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:[[SaveSystem GetInstance] GetMaxLevel]];
        
        if (maxLevelRoom > maxUnlockedRoom)
        {
            [[RegenerationManager GetInstance] SetRoomUnlockState:ROOM_UNLOCK_STATE_COUNTDOWN];
        }
        
        [self ActivateMenu:gameFlow->mMenuToLoad];
    
        FaderParams faderParams;
        [Fader InitDefaultParams:&faderParams];
        
        faderParams.mFadeType = FADE_FROM_BLACK;
        faderParams.mFrameDelay = 2;
        faderParams.mCancelFades = TRUE;
        
        [[Fader GetInstance] StartWithParams:&faderParams];
    }
    else
    {
        [self SetCurrentMenuActive:TRUE];
        [self EvaluateXrayIndicators];
        [self EvaluateTornadoIndicators];
        
        BOOL showUnlockButton = [self ShouldShowBottomBarRoomUnlockButton];
        
        if (!showUnlockButton)
        {
            [bottomBar.mRoomUnlockButton SetVisible:FALSE];
            [bottomBar.mRoomUnlockStringCloud SetVisible:FALSE];
        }
        
        if (![[AdvertisingManager GetInstance] ShouldShowAds])
        {
            [bottomBar.mRemoveAds SetVisible:FALSE];
            [bottomBar.mArrow SetVisible:FALSE];
        }
        
        levelSelect.mLevelSelectPage = [self GetLevelSelectPage];
    }
    
    [[NeonMetrics GetInstance] logEvent:@"Main Menu Resume" withParameters:NULL];
}

-(void)Shutdown
{
	[ self LeaveMenu ];
    
    for (int i = 0; i < RUN21_LEVEL_NUM; i++)
    {
        [levelSelect.mLevelButton[i].stars release];
    }
    
    [mActiveMenu.uiObjects removeAllObjects];
    [mActiveMenu.secondaryObjects removeAllObjects];
    
    [[GameObjectManager GetInstance] Remove:mActiveMenu.uiObjects];
    [[GameObjectManager GetInstance] Remove:mActiveMenu.secondaryObjects];
    
    [[GameObjectManager GetInstance] Remove:mRoomUnlockDescription];
    
    [mDeleteData                release];
    [mCommunityDelegate         release];
    [mFacebookDelegate          release];
    [mRefillLivesDelegate       release];
    
    [mHintDisabledObjects release];
    
    [[[GameStateMgr GetInstance] GetMessageChannel] RemoveListener:self];
}

-(void)Suspend
{
    Class nextClass = [[[GameStateMgr GetInstance] GetActiveState] class];
    
    if ((nextClass != [IAPStore class]) && (nextClass != [OverlayState class]))
    {
        Flow *gameFlow = [ Flow GetInstance ];
        gameFlow->mMenuToLoad = mActiveMenu.menuID;

        [self LeaveMenu];
    
        [mActiveMenu.uiObjects removeAllObjects];
        [mActiveMenu.secondaryObjects removeAllObjects];
        
        [[GameObjectManager GetInstance] Remove:mActiveMenu.uiObjects];
        [[GameObjectManager GetInstance] Remove:mActiveMenu.secondaryObjects];
        
        [[GameObjectManager GetInstance] Remove:mRoomUnlockDescription];
        
        mSuspendType = MAINMENU_SUSPEND_FULL;
    }
    else
    {
        if (nextClass == [IAPStore class])
        {
            [self SetCurrentMenuActive:FALSE];
        }
        
        mSuspendType = MAINMENU_SUSPEND_PARTIAL;
    }
}

-(void)UpdateBottomBar
{
    // The bottom bar is active and init'ed in every menu but Main.
    if ( mActiveMenu.menuID != NeonMenu_Main && [mActiveMenu.uiObjects GroupCompleted] )
    {
        [bottomBar.mXRayAmount      SetString:[NSString stringWithFormat:@"%d", [[ SaveSystem GetInstance] GetNumXrays]]];
        [bottomBar.mTornadoAmount   SetString:[NSString stringWithFormat:@"%d", [[ SaveSystem GetInstance] GetNumTornadoes]]];
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ([[InAppPurchaseManager GetInstance] GetIAPState] == IAP_STATE_PENDING)
    {
        return;
    }
    
    [self UpdateBottomBar];
    
    if ((sUserData.mType == USERDATA_TYPE_FLOW) && (!mSentTerminateMessage))
    {
        mSentTerminateMessage = TRUE;
        
        Message msg;
        
        msg.mId = EVENT_MAIN_MENU_PENDING_TERMINATE;
        msg.mData = NULL;
        
        [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];
    }
    
    if (mMenuTerminateDelay > 0)
    {
        mMenuTerminateDelay--;
    }
    
    if ([mActiveMenu.uiObjects GroupCompleted] && [mActiveMenu.secondaryObjects GroupCompleted] && (mMenuTerminateDelay == 0))
    {
        if (sUserData.mType != USERDATA_INVALID)
        {
            [mActiveMenu.uiObjects removeAllObjects];
            [mActiveMenu.secondaryObjects removeAllObjects];

            UserDataType userDataType = sUserData.mType;
            
            sUserData.mType = USERDATA_INVALID;
            
            switch(userDataType)
            {
                case USERDATA_TYPE_FLOW:
                {
                    int level = sUserData.mData;
                    GameModeType gameMode = (GameModeType)sUserData.mDataTwo;
                    
                    if (gameMode == GAMEMODE_TYPE_RUN21_MARATHON)
                    {
                        NSAssert(level == 0, @"Marathon only has one level (level 0)");
                        [[Flow GetInstance] EnterGameMode:GAMEMODE_TYPE_RUN21_MARATHON level:0];
                    }
                    else
                    {
                        NSAssert((level >= 0) && (level < RUN21_LEVEL_NUM), @"Invalid user data");
                        [[Flow GetInstance] EnterGameMode:GAMEMODE_TYPE_RUN21 level:level];
                    }
                    
                    break;
                }
                
                case USERDATA_TYPE_MENU:
                {
                    [self ActivateMenu:(ENeonMenu)sUserData.mData];
                    break;
                }
                
                case USERDATA_TYPE_POP:
                {
                    [[GameStateMgr GetInstance] Pop];
                    break;
                }
                    
                case USERDATA_TYPE_PUSH:
                {
                    switch ( sUserData.mData )
                    {
                        case PUSH_MENU_IAPSTORE:
                        {
                            [[GameStateMgr GetInstance] Push:[IAPStore alloc]];
                            break;
                        } 
                        default:
                        {
                            NSAssert(FALSE, @"Unknown USERDATA_TYPE_PUSH mData type.");
                            break;
                        }
                            
                    }
                    break;
                }
                
                default:
                {
                    NSAssert(FALSE, @"Unknown user data type");
                    break;
                }
            }
        }
    }
    
    if ([[RegenerationManager GetInstance] GetRoomUnlockState] == ROOM_UNLOCK_STATE_COUNTDOWN)
    {
        NSString* newString = [MainMenu GetRoomLockDescription];
        
        [mRoomUnlockDescription SetString:newString];
        RoomUnlockState roomUnlockState = [[RegenerationManager GetInstance] GetRoomUnlockState];
        [mRoomUnlockDescription SetPosition:&sRoomLockDescriptionPositions[roomUnlockState]];
    }
    
    if (([mConnectingTextBox GetVisible]) || ([bottomBar.mConnectingTextBox GetVisible]))
    {
        if ([[InAppPurchaseManager GetInstance] GetIAPState] == IAP_STATE_IDLE)
        {
            [mConnectingTextBox SetVisible:FALSE];
            [bottomBar.mConnectingTextBox SetVisible:FALSE];
            
            if ([[RegenerationManager GetInstance] GetRoomUnlockState] == ROOM_UNLOCK_STATE_COUNTDOWN)
            {
                [mRoomUnlockButton SetActive:TRUE];
                [mRoomUnlockStringCloud SetVisible:TRUE];
            }
            
            if ([[AdvertisingManager GetInstance] ShouldShowAds])
            {
                [bottomBar.mRoomUnlockButton SetActive:TRUE];
                [bottomBar.mRoomUnlockStringCloud SetVisible:TRUE];
            }
        }
    }
    
    [super Update:inTimeStep];
}

-(void)OutOfLivesAlert
{
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"LS_NextLife",NULL) , [[RegenerationManager GetInstance] GetHealthRegenTimeString]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_OutOfLives", NULL)
                                                    message: msg
                                                   delegate: mRefillLivesDelegate
                                          cancelButtonTitle: NSLocalizedString(@"LS_Wait", NULL)
                                          otherButtonTitles: NSLocalizedString(@"LS_FillLives",NULL),
                                                             NSLocalizedString(@"LS_AskAFriend",NULL),
                                                            nil];
    [alert show];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if ([[GameStateMgr GetInstance] GetActiveState] != self)
    {
        return;
    }
    
    if (inEvent == BUTTON_EVENT_UP)
    {
        BOOL audioOptionSelected = FALSE;
        
        // Global buttons, these aren't associated with a particular submenu
        switch (inButton->mIdentifier)
        {
            case NeonMenu_Main_Options_Sound:
            {
                mSavedSoundOn = [(NeonButton*)inButton GetToggleOn];
                [[SaveSystem GetInstance] SetSoundOn:mSavedSoundOn];
                                    
                [self EvaluateAudioOptions];
                audioOptionSelected = TRUE;
                break;
            }
				
            case NeonMenu_Main_Options_Music:
            {
                mSavedMusicOn = [(NeonButton*)inButton GetToggleOn];
                [[SaveSystem GetInstance] SetMusicOn:mSavedMusicOn];
                                
                [self EvaluateAudioOptions];
                audioOptionSelected = TRUE;
                break;
            }
        }
        
        if (audioOptionSelected)
        {
            return;
        }

        BOOL leaveMenu = TRUE;
        
		if ((mActiveMenu.menuID == Run21_Main_LevelSelect || mActiveMenu.menuID == Rainbow_Main_LevelSelect) )
		{
			if ( inButton->mIdentifier >= LSID_LevelButtonBase)
			{
				int nLevelButtonSelected	= inButton->mIdentifier - LSID_LevelButtonBase;	// 0-Based index of Level
				
				// Is this level unlocked?
				if ( LSSTATUS_LOCKED != [levelSelect.mLevelButton[nLevelButtonSelected].button GetActiveIndex] )
				{
                    if ( [[SaveSystem GetInstance] GetNumLives] )
                    {
                        // Play this level.
                        sUserData.mType = USERDATA_TYPE_FLOW; // kk
                        sUserData.mData = nLevelButtonSelected;
                        sUserData.mDataTwo = GAMEMODE_TYPE_RUN21;
                        
                        leaveMenu = TRUE;
                    }
                    else
                    {
                        leaveMenu = FALSE;
                        [self OutOfLivesAlert];
                    }
                    
                    
				}
				else
				{
					// Do nothing, user cannot access locked levels.
                    return;
				}
			}
            
            switch ( inButton->mIdentifier )
            {
                case LSID_Prev:
                    leaveMenu = FALSE;
                    
                    if ( levelSelect.mLevelSelectPage > LEVELSELECT_ROOM_BRONZE )
                    {
                        levelSelect.mLevelSelectPage = (LevelSelectRoom)(levelSelect.mLevelSelectPage - 1);
                    }
                    else
                    {
                        levelSelect.mLevelSelectPage = LEVELSELECT_ROOM_DIAMOND;
                    }

                    [self ActivateLevelSelectRoom];
                    
                    break;
                case LSID_Next:
                    leaveMenu = FALSE;
                    
                    if ( levelSelect.mLevelSelectPage < LEVELSELECT_ROOM_DIAMOND )
                    {
                        levelSelect.mLevelSelectPage = (LevelSelectRoom)(levelSelect.mLevelSelectPage + 1);
                    }
                    else
                    {
                        levelSelect.mLevelSelectPage = LEVELSELECT_ROOM_BRONZE;
                    }
                    
                    [self ActivateLevelSelectRoom];
                    break;
                case LSID_Back:
                    leaveMenu       = TRUE;
                    sUserData.mType = USERDATA_TYPE_MENU;
                    sUserData.mData = NeonMenu_Main;
                    
                    break;
                case LSID_Play:
                    NSAssert(FALSE, @"Do we even use this?");
                    leaveMenu       = TRUE;
                    sUserData.mType = USERDATA_TYPE_FLOW;
                    sUserData.mData = levelSelect.nLevelSelected;
                    break;
                case NeonMenu_Main_Extras_IAP_Store:
                {
                    [[GameStateMgr GetInstance] Push:[IAPStore alloc] ];
                    leaveMenu = FALSE;
                    break;
                }
                
                case NeonMenu_Unlock_Next_Room:
                {
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        [[InAppPurchaseManager GetInstance] RequestProduct:IAP_PRODUCT_UNLOCK_ALL];
                    } );
                    
                    if ([mRoomUnlockButton GetVisible])
                    {
                        [mConnectingTextBox SetVisible:TRUE];
                        [mRoomUnlockStringCloud SetVisible:FALSE];
                        [mRoomUnlockButton SetActive:FALSE];
                    }
                    
                    if ([bottomBar.mRoomUnlockButton GetVisible])
                    {
                        [bottomBar.mConnectingTextBox SetVisible:TRUE];
                        [bottomBar.mRoomUnlockStringCloud SetVisible:FALSE];
                        [bottomBar.mRoomUnlockButton SetActive:FALSE];
                    }
                    
                    leaveMenu = FALSE;
                    break;
                }
                
#if !NEON_SOLITAIRE_21
                case NeonMenu_Main_Extras_IAP_Lives:
                {
                    [[GameStateMgr GetInstance] Push:[[IAPStore alloc] InitWithTab:IAPSTORE_TAB_LIVES]];
                    break;
                }
#endif
            }
			
			if (leaveMenu)
			{
				[self LeaveMenu];
			}
			
			return;
		}
		
        switch ( inButton->mIdentifier )
        {
            case NeonMenu_Main_Options:
            {
                leaveMenu = FALSE;
                // Toggle the status of the Options Buttons.
                // We need to make the SFX, BGM, and Clear Data Buttons Visible
                int  numObjects = [mActiveMenu.uiObjects count];
                NeonButton *inButtonNeon = (NeonButton*)inButton;
                BOOL bOptionsButtonWasOn = [ inButtonNeon GetToggleOn ];
                
                for (int i = 0; i < numObjects; i++)
                {
                    UIObject *nObject = [ mActiveMenu.uiObjects objectAtIndex:i ];
                    
                    switch ( nObject->mIdentifier )
                    {
                        case OPTIONS_GRADIENT_ID:
                        {
                            ImageWell*  nImage = (ImageWell*)nObject;
                            BOOL        bVisible = TRUE;
                            
                            if ( bOptionsButtonWasOn )
                                bVisible = FALSE;
                            
                            [ nImage SetVisible:bVisible ];
                            break;
                        }
   
                        case NeonMenu_Main_Options_Music:
                        case NeonMenu_Main_Options_Sound:
                        case NeonMenu_Main_Options_ClearData:
                        {
                            NeonButton *nButton = (NeonButton*)nObject;
                            
                            if ( bOptionsButtonWasOn )
                            {
                                [nButton SetListener:NULL];
                                [nButton Disable];
                                [nButton SetVisible:FALSE];
                            }
                            else
                            {
                                [nButton SetListener:self];
                                [nButton Enable];
                                [nButton SetVisible:TRUE];
                            }
                            break;
                        }
                            
                    }
                }
                
                break;
            }
                
            case NeonMenu_NeonLogo:
			case NeonMenu_Main_Extras_Website:
            {
				leaveMenu = FALSE;
				NeonButton *webbutton = (NeonButton*)inButton;
				[webbutton SetToggleOn:TRUE];

				UIApplication *neonApp	= [ UIApplication sharedApplication ];
				NSURL *neonGamesUS		= [ NSURL URLWithString:@"http://neongam.es/"];
				[ neonApp openURL:neonGamesUS ];

                break;
            }
				
			case NeonMenu_Main_Extras_Contact_Us:
            {
                [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_Community",NULL)
                                                                message: NULL
                                                               delegate: mCommunityDelegate
                                                      cancelButtonTitle: NSLocalizedString(@"LS_Back", NULL)
                                                      otherButtonTitles: NSLocalizedString(@"LS_Email_Us",NULL),
                                                                         NSLocalizedString(@"LS_WebComic",NULL),nil];
                [alert show];

                leaveMenu = FALSE;
                break;
            }
            case NeonMenu_Main_Extras_IAP_Store:
            {
                [[GameStateMgr GetInstance] Push:[IAPStore alloc] ];
                leaveMenu = FALSE;
                break;
            }
#if !NEON_SOLITAIRE_21
            case NeonMenu_Main_Extras_IAP_Lives:
            {
                [[GameStateMgr GetInstance] Push:[[IAPStore alloc] InitWithTab:IAPSTORE_TAB_LIVES]];
                break;
            }
#endif
			case NeonMenu_Main_Extras_RateAppOrOtherGames:
            {
                leaveMenu = FALSE;
                NeonButton *webbutton = (NeonButton*)inButton;
				[webbutton SetToggleOn:TRUE];
                [[Flow GetInstance] AppRate];
                break;
            }
                
            case NeonMenu_Main_Options_ClearData_Yes:
            {
                [ [SaveSystem GetInstance] Reset ];
                
                // Known issue, the levels remain unlocked but the scores are cleared.  Don't care...
                
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = NeonMenu_Main_Options;
                break;
            }
				
            case NeonMenu_Main_Options_ClearData_No:
            {
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = NeonMenu_Main_Options;
                break;
            }
			case NeonMenu_Main_Options_ClearData:
			{
                NeonButton *webbutton       = (NeonButton*)inButton;
                BOOL       bDeleteGuarded   = [webbutton GetToggleOn];
                
                // Only prompt user if they have have pressed this button twice ( red state )
                if ( !bDeleteGuarded )
                {
                    [UIApplication sharedApplication].statusBarOrientation = GAME_ORIENTATION;
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_EraseProgress", NULL)
                                                                    message: NULL
                                                                   delegate: mDeleteData
                                                          cancelButtonTitle: NSLocalizedString(@"LS_No", NULL)
                                                          otherButtonTitles: NSLocalizedString(@"LS_Yes",NULL),nil];
                    [alert show];
                }
                
                leaveMenu = FALSE;
                break;
			}
            case Run21_Main_Marathon:
            {
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = Run21_Main_Marathon;
                break;
            }
            case Run21_Main_Marathon_Play:
            {
                if ( [[SaveSystem GetInstance] GetNumLives] )
                {
                    sUserData.mType = USERDATA_TYPE_FLOW;
                    sUserData.mData = 0;
                    sUserData.mDataTwo = GAMEMODE_TYPE_RUN21_MARATHON;
                    
                    leaveMenu = TRUE;
                }
                else
                {
                    [self OutOfLivesAlert];
                    leaveMenu       = FALSE;
                }
                break;
            }
#if !NEON_SOLITAIRE_21
            case Run21_Marathon_Leaderboard:
            {
                [[AchievementManager GetInstance] ShowLeaderboard:LEADERBOARD_RUN21_MARATHON];
                leaveMenu = FALSE;
                break;
            }
            case Run21_Marathon_Achievements:
            {
                [[AchievementManager GetInstance] ShowAchievements];
                leaveMenu = FALSE;
                break;
            }
#endif
            case Run21_Main_LevelSelect:
            {
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = Run21_Main_LevelSelect;
                
                Message msg;
                
                msg.mId = EVENT_MAIN_MENU_LEVEL_SELECT_PENDING;
                msg.mData = NULL;
                
                [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];

                break;
            }
            case Rainbow_Main_LevelSelect:
            {
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = Rainbow_Main_LevelSelect;
                NSAssert(FALSE, @"Need to use new flow functions");
                //levelSelectGameOffset = Tutorial_Rainbow_HowToPlay;
                break;
            }

			case NeonMenu_Main_NewGame_OverwriteYes:
            {
                [[SaveSystem GetInstance] Reset];
                NSAssert(FALSE, @"Need to use new flow functions");
                sUserData.mType = USERDATA_TYPE_FLOW;
                //sUserData.mData = NeonEngine_GameStart;
                break;
            }
				
            case NeonMenu_Main_NewGame_OverwriteNo:
            {
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = NeonMenu_Main;
                break;
            }
				            
            case NeonMenu_Main_Extras_Facebook:
            {
                break;
            }
#if !NEON_SOLITAIRE_21
            case NeonMenu_Main_Extras_GameCenter:
            {
                [[AchievementManager GetInstance] ShowAchievements];
                leaveMenu = FALSE;
                break;
            }
#endif
            default:
            {
                u32 buttonID = (ENeonMenu)inButton->mIdentifier;
                
                sUserData.mType = USERDATA_TYPE_MENU;
                sUserData.mData = buttonID;
                
                break;
            }
        }
        
        if (leaveMenu)
        {
            [self LeaveMenu];
        }
    }
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_HINT_TRIGGERED:
        {
            HintId hintId = (HintId)[(NSNumber*)inMsg->mData intValue];
            
            if (hintId == HINT_ID_LEVEL_SELECT)
            {
                OverlayStateParams* overlayParams = [[OverlayStateParams alloc] init];
                overlayParams.OverlayId = OVERLAY_ID_LEVEL_SELECT;
                
                [[GameStateMgr GetInstance] Push:[OverlayState alloc] withParams:overlayParams];
                [overlayParams release];
            }
            else if (hintId == HINT_ID_UNLOCK_ROOM)
            {
                for (int nCard = 0; nCard < RUN21_LEVEL_NUM; nCard++)
                {
                    if (levelSelect.mLevelSelectPage == [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:nCard])
                    {
                        MultiStateButton* button = levelSelect.mLevelButton[nCard].button;
                        [mHintDisabledObjects addObject:button];
                    }
                }
                
                [mHintDisabledObjects addObject:bottomBar.mXRayButton];
                
                if (bottomBar.mTornadoButton != NULL)
                {
                    [mHintDisabledObjects addObject:bottomBar.mTornadoButton];
                }
                
                [mHintDisabledObjects addObject:mPrevRoomButton];
                [mHintDisabledObjects addObject:levelSelect.mBackButton];
                
                for (UIObject* curObject in mHintDisabledObjects)
                {
                    curObject.FadeWhenInactive = FALSE;
                    [curObject SetActive:FALSE];
                }
                
                TutorialScript* testScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];
                
                TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                phase->mDialogueKey = @"LS_Tut_UnlockRoom_1";
                phase->mTriggerState = NULL;
                phase->mTriggerCount = 4;
                [phase SetDialogueFontSize:16.0f];
                [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                [phase SetDialogueOffsetX:0.0f y:200.0f];
                [testScript AddPhase:phase];
                [phase release];
                
                phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                
                phase->mDialogueKey = @"LS_Tut_UnlockRoom_2";
                
                phase->mTriggerState = NULL;
                phase->mTriggerCount = 4;
                [phase SetDialogueFontSize:16.0f];
                [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                [phase SetDialogueOffsetX:0.0f y:200.0f];
                [phase SetTallSpinnerPositionX:338 positionY:38 sizeX:125 sizeY:45];
                [phase SetSpinnerPositionX:338 positionY:38 sizeX:125 sizeY:48];
                [testScript AddPhase:phase];
                [phase release];

                testScript.Indeterminate = TRUE;
                testScript.EnableUI = TRUE;
            
                [self InitFromTutorialScript:testScript];
            }
            
            break;
        }
    }
}

-(void)LeaveMenu
{
    int  numObjects = [mActiveMenu.uiObjects count];
    
    for (int i = 0; i < numObjects; i++)
    {
        UIObject *nObject = [ mActiveMenu.uiObjects objectAtIndex:i ];
        
        [nObject RemoveAfterOperations];
        [nObject Disable];
    }
    
    numObjects = [mActiveMenu.secondaryObjects count];
    
    for (int i = 0; i < numObjects; i++)
    {
        UIObject *nObject = [ mActiveMenu.secondaryObjects objectAtIndex:i ];
        
        [nObject RemoveAfterOperations];
        [nObject Disable];
    }
    
    [mProfilePicture RemoveAfterOperations];
    [mProfilePicture Disable];
    
    mProfilePicture = NULL;
    
    memset(&bottomBar, 0, sizeof(bottomBar));
    
    // If there are no UIObjects, we're transitioning INTO a menu, so sUserData.mType could be invalid.
    // It's also okay to have no destination state if we're leaving the state (hence the second check)
    if ((numObjects != 0) && ([[GameStateMgr GetInstance] GetActiveState] == self))
    {
        //NSAssert(sUserData.mType != USERDATA_INVALID, @"Trying to leave a menu but no destination was set");
    }
    
    [mRoomUnlockDescription RemoveAfterOperations];
    [mRoomUnlockDescription Disable];
    
    mRoomUnlockDescription = NULL;
    
    mConnectingTextBox = NULL;
}

-(void)InitMenu:(ENeonMenu)menuID
{
    [ self LeaveMenu ];
	mActiveMenu.menuID		= menuID;
}

-(void)InitLSRoom:(LevelSelectRoom)inRoomIndex
{
    int colorText = 0xFFFFFFFF;
    int colorStroke = NEON_BLA;
    
    switch (inRoomIndex)
    {
        case LEVELSELECT_ROOM_DIAMOND:
            colorText   = NEON_BLU;
            break;
            
        case LEVELSELECT_ROOM_SAPPHIRE:
            colorText = 0x21FFF0FF;
            break;
            
        case LEVELSELECT_ROOM_EMERALD:
            colorText = 0x2DFF07FF;
            break;
            
        case LEVELSELECT_ROOM_RUBY:
            colorText = 0xFDA3A2FF;
            break;
            
        case LEVELSELECT_ROOM_GOLD:
            colorText   = NEON_YEL;
            break;
            
        case LEVELSELECT_ROOM_SILVER:
            colorText   = NEON_WHI;
            break;
   
        case LEVELSELECT_ROOM_BRONZE:
        default:
            colorText   = NEON_ORA;
            break;
    }
    
    PlacementValue placementValue;
    SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    
    // Display message asking user to confirm they want to start a new game
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,		colorText);
    SetColorFromU32(&tbParams.mStrokeColor, colorStroke);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= NSLocalizedString([NSString stringWithUTF8String:levelselectRoomNames[inRoomIndex]], NULL);
    tbParams.mFontSize		= 24;
    tbParams.mFontType		= NEON_FONT_STYLISH;
    tbParams.mWidth			= 320;	// Gutter the left and right border of screen
    tbParams.mUIGroup		= mActiveMenu.uiObjects;
    
    levelSelect.mRoomName[inRoomIndex]   = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [levelSelect.mRoomName[inRoomIndex]  SetVisible:FALSE];
    //[levelSelect.mRoomName[starType]  Enable];
    [levelSelect.mRoomName[inRoomIndex]  SetPlacement:&placementValue];
    [levelSelect.mRoomName[inRoomIndex]  SetPosition: &sLS_RoomNameLoc];
    [levelSelect.mRoomName[inRoomIndex]  release];    // May not need this.
}


-(void)InitLevelUpMeter
{
    ImageWell		*levelupImage;
    TextBoxParams   tbParams;
    TextBox*        currentTextBox;
    float           levelProgress;
    int             currentLevel;
    int             totalScore = 4; // tutorial score is not saved to the file

    totalScore = [[SaveSystem GetInstance] GetExperience];
    ExperienceManager *xpManager = [ExperienceManager GetInstance];
    [ xpManager GetPlayerWithLevel:&currentLevel WithPercent:&levelProgress];
    
	ImageWellParams					imageWellparams;
	[ImageWell InitDefaultParams:	&imageWellparams];
	imageWellparams.mUIGroup		= mActiveMenu.secondaryObjects;
    
    //Init the Levelup Bar Holder
    imageWellparams.mTextureName = [ NSString stringWithUTF8String:levelUpMeterHolderName];
    
    levelupImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[levelupImage		SetPosition:&sLeveupHolderPosistion];
	[levelupImage		SetVisible:TRUE];
	[levelupImage		release];
    
    //Init the Leveup Bar Contents
    imageWellparams.mTextureName = [ NSString stringWithUTF8String:levelUpMeterContentsName];
    
    levelupImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[levelupImage		SetPosition:&sLeveupMeterPosistion];
	[levelupImage		SetVisible:TRUE];
    
    [levelupImage SetScaleX:levelProgress Y:1.0 Z:1.0];
	[levelupImage		release];
    
    //Init the level numbers
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mFontSize		= 12;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mUIGroup       = mActiveMenu.secondaryObjects;
    

    tbParams.mString = [NSString stringWithFormat:@"%d",currentLevel ];
    currentTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [currentTextBox    SetVisible:TRUE];
    [currentTextBox    SetPositionX:sLeveupHolderPosistion.mVector[0]+35  Y:sLeveupHolderPosistion.mVector[1]+7 Z:0.0];
    [currentTextBox    release];

    tbParams.mString = [NSString stringWithFormat:@"%d",currentLevel+1 ];
    currentTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [currentTextBox    SetVisible:currentLevel+1 < MAX_PLAYER_LEVEL];
    [currentTextBox    SetPositionX:sLeveupHolderPosistion.mVector[0]+174  Y:sLeveupHolderPosistion.mVector[1]+7 Z:0.0];
    [currentTextBox    release];
    
    // Profile picture can't be part of a UI group since it's RGB texture format (if downloaded from Facebook) and the rest of the texture atlas is RGBA.
    imageWellparams.mUIGroup = NULL;

    imageWellparams.mTextureName = [ NSString stringWithUTF8String:defaultProfilePicture];
    mProfilePicture	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
    
    [mProfilePicture		SetPosition:&sProfilePicturePosition];
	[mProfilePicture		SetVisible:TRUE];
    [[GameObjectManager GetInstance] Add:mProfilePicture];
	[mProfilePicture		release];
    
}
-(void)InitBottomBar
{
    mNumButtons++;
    ImageWell						*logoImage;
	
	ImageWellParams					imageWellparams;
	[ImageWell InitDefaultParams:	&imageWellparams];
	imageWellparams.mUIGroup		= mActiveMenu.secondaryObjects;
    
    imageWellparams.mTextureName = [ NSString stringWithUTF8String:levelSelectBottomBarName ];
    
	logoImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[logoImage		SetPosition:&sLevelSelectBottomBarPosistion];
	[logoImage		SetVisible:TRUE];
	[logoImage		release];

    BOOL xrayUnlocked = [[[Flow GetInstance] GetLevelDefinitions] GetXrayUnlocked];
    BOOL tornadoUnlocked = [[[Flow GetInstance] GetLevelDefinitions] GetTornadoUnlocked];
    
    if (xrayUnlocked)
    {
        bottomBar.mXRayButton = [self InitMainMenuButton:NeonMenu_Main_Extras_IAP_Store	MMID:MMButton_Powerup_XRay  visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.secondaryObjects];
    }
    
    if (tornadoUnlocked)
    {
        bottomBar.mTornadoButton = [self InitMainMenuButton:NeonMenu_Main_Extras_IAP_Store	MMID:MMButton_Powerup_Tornado  visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.secondaryObjects];
    }

#if USE_LIVES
    [self InitMainMenuButton:NeonMenu_Main_Extras_IAP_Lives withMMID:MMButton_Powerup_Lives  withVisible:TRUE withOn:TRUE withEnabled:TRUE withUIGroup:mActiveMenu.secondaryObjects];
#endif

    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 5;
    tbParams.mFontSize		= 14;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mWidth         = 320;
    tbParams.mMaxWidth      = 320;
    tbParams.mMaxHeight     = 32;
    tbParams.mMutable       = TRUE;
    tbParams.mUIGroup       = mActiveMenu.secondaryObjects;

    if (xrayUnlocked)
    {
        tbParams.mString = [NSString stringWithFormat:@"%d",[[SaveSystem GetInstance] GetNumXrays] ];
        bottomBar.mXRayAmount = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
        [bottomBar.mXRayAmount    SetVisible:TRUE];
        [bottomBar.mXRayAmount    SetPositionX:420 Y:300 Z:0.0];
        [bottomBar.mXRayAmount    release];
        
        StringCloudParams* stringCloudParams = [[StringCloudParams alloc] init];
        
        stringCloudParams->mUIGroup = mActiveMenu.secondaryObjects;
        [stringCloudParams->mStrings addObject:@"<B>X-Rays</B>"];
        [stringCloudParams->mStrings addObject:@"<B>Get More</B>"];
        [stringCloudParams->mStrings addObject:@"<B><color=0xFFE845>Tap Here!</color></B>"];
        stringCloudParams->mFontSize = 12.0f;
        
        bottomBar.mXRayBuyMore = [[StringCloud alloc] initWithParams:stringCloudParams];
        [bottomBar.mXRayBuyMore release];
        [stringCloudParams release];
    
        [bottomBar.mXRayBuyMore SetPositionX:(MMPos[MMButton_Powerup_XRay].mVector[x] + 35) Y:280 Z:0.0];
        
        [self EvaluateXrayIndicators];
    }

    if (tornadoUnlocked)
    {
        tbParams.mString = [NSString stringWithFormat:@"%d",[[SaveSystem GetInstance] GetNumTornadoes]];
        bottomBar.mTornadoAmount = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
        [bottomBar.mTornadoAmount    SetVisible:TRUE];
        [bottomBar.mTornadoAmount    SetPositionX:(MMPos[MMButton_Powerup_Tornado].mVector[x] + 25) Y:300 Z:0.0];
        [bottomBar.mTornadoAmount    release];
        
        StringCloudParams* stringCloudParams = [[StringCloudParams alloc] init];
        
        stringCloudParams->mUIGroup = mActiveMenu.secondaryObjects;
        [stringCloudParams->mStrings addObject:@"<B>Tornadoes</B>"];
        [stringCloudParams->mStrings addObject:@"<B>Get More</B>"];
        [stringCloudParams->mStrings addObject:@"<B><color=0xFFE845>Tap Here!</color></B>"];
        stringCloudParams->mFontSize = 12.0f;
        
        bottomBar.mTornadoBuyMore = [[StringCloud alloc] initWithParams:stringCloudParams];
        [bottomBar.mTornadoBuyMore release];
        [stringCloudParams release];
    
        [bottomBar.mTornadoBuyMore SetPositionX:(MMPos[MMButton_Powerup_Tornado].mVector[x] + 12) Y:280 Z:0.0];
        
        [self EvaluateTornadoIndicators];
    }
    
    BOOL showUnlockRoomButton = [self ShouldShowBottomBarRoomUnlockButton];

    if ([[AdvertisingManager GetInstance] ShouldShowAds])
    {
        SetColorFloat(&tbParams.mColor, 1.0, 1.0, 0.0, 1.0);
        
        tbParams.mString = NSLocalizedString(@"LS_AnyPurchaseRemovesAds", NULL);
        tbParams.mFontSize = 12.0f;
        bottomBar.mRemoveAds = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
        [bottomBar.mRemoveAds    SetVisible:TRUE];
        [bottomBar.mRemoveAds    SetPositionX:7 Y:290 Z:0.0];
        [bottomBar.mRemoveAds    release];
        
        bottomBar.mRemoveAds->mPivot.mVector[x] = [bottomBar.mRemoveAds GetWidth] / 2;
        bottomBar.mRemoveAds->mPivot.mVector[y] = [bottomBar.mRemoveAds GetHeight] / 2;
        
        NeonArrowParams neonArrowParams;
        [NeonArrow InitDefaultParams:&neonArrowParams];

        neonArrowParams.mUIGroup = mActiveMenu.secondaryObjects;
        
        if (showUnlockRoomButton)
        {
            neonArrowParams.mLength = 200;
        }
        else
        {
            neonArrowParams.mLength = 1200;
        }
        
        bottomBar.mArrow = [[NeonArrow alloc] initWithParams:&neonArrowParams];
        [bottomBar.mArrow release];
        
        [bottomBar.mArrow SetOrientationX:0.0 Y:0.0 Z:90.0];
        [bottomBar.mArrow SetScaleX:0.15 Y:0.15 Z:1.0];
        
        if (showUnlockRoomButton)
        {
            [bottomBar.mArrow SetPositionX:145.0 Y:296 Z:0.0];
        }
        else
        {
            [bottomBar.mArrow SetPositionX:295.0 Y:296 Z:0.0];
        }
        
        Path* scalePath = [[Path alloc] Init];
        [scalePath AddNodeScalar:1.0 atTime:0.0];
        [scalePath AddNodeScalar:1.15 atTime:0.5];
        [scalePath AddNodeScalar:1.0 atTime:1.0];
        
        [scalePath SetPeriodic:TRUE];
        
        [bottomBar.mRemoveAds AnimateProperty:GAMEOBJECT_PROPERTY_SCALE withPath:scalePath];
        
        [scalePath release];
    }
    else
    {
        bottomBar.mRemoveAds = NULL;
        bottomBar.mArrow = NULL;
    }
    
    if (showUnlockRoomButton)
    {
        [self ActivateRoomUnlockButtonWithPositionX:150 y:293 unlockButton:&bottomBar.mRoomUnlockButton stringCloud:&bottomBar.mRoomUnlockStringCloud connectingTextBox:&bottomBar.mConnectingTextBox];
        
        [bottomBar.mRoomUnlockButton SetScaleX:0.7 Y:0.7 Z:1.0];
        [bottomBar.mRoomUnlockButton SetVisible:TRUE];
        
        [bottomBar.mRoomUnlockStringCloud SetPositionX:175 Y:283 Z:0];
        [bottomBar.mRoomUnlockStringCloud SetVisible:TRUE];
        
        [bottomBar.mConnectingTextBox SetPositionX:175 Y:298 Z:0];
    }
}

-(void)InitLevelSelectBG
{
    for (int i = 0; i < LEVELSELECT_ROOM_NUM; i++)
    {
        ImageWellParams					imageWellparams;
        [ImageWell InitDefaultParams:	&imageWellparams];
        imageWellparams.mUIGroup		= mActiveMenu.uiObjects;
        imageWellparams.mTextureName	= [ NSString stringWithUTF8String:levelselectBGImage[i] ];
        
        
        levelSelect.mBG[i]=     [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
        [levelSelect.mBG[i]     SetPosition:&sLogoPosition];
        [levelSelect.mBG[i]     SetVisible:FALSE];
        [levelSelect.mBG[i]     release];
        
        [self InitLSRoom:(LevelSelectRoom)i];
    }
    
    [self InitBottomBar];
    
	// Hack to trick the system into not setting up the layout or bg.
	mNumButtons = 1;
}

-(void)InitLogo
{
	ImageWell						*logoImage;
	
	ImageWellParams					imageWellparams;
	[ImageWell InitDefaultParams:	&imageWellparams];
	imageWellparams.mUIGroup		= mActiveMenu.uiObjects;
    
    imageWellparams.mTextureName = [ NSString stringWithUTF8String:mainMenuButtonTextureLogo ];
		
	logoImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[logoImage		SetPosition:&sLogoPosition];
	[logoImage		SetVisible:TRUE];
	[logoImage		release];
}

-(void)InitOptionsGradient
{
    ImageWell						*logoImage;
	
	ImageWellParams					imageWellparams;
	[ImageWell InitDefaultParams:	&imageWellparams];
	imageWellparams.mUIGroup		= mActiveMenu.uiObjects;
	imageWellparams.mTextureName	= @"menu_option_header.papng";
    
	logoImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
    
    Vector3	optionsPos	= { 0, 0, 0};
    logoImage->mIdentifier = OPTIONS_GRADIENT_ID;
	[logoImage		SetPosition:&optionsPos];
	[logoImage		SetVisible:TRUE];
	[logoImage		release];
}

-(NeonButton*)InitMainMenuButton:(ENeonMenu)linkMenuID MMID:(MainMenuButtons)mmButtonID visible:(BOOL)bVisible on:(BOOL)bToggledOn enabled:(BOOL)bEnabled uiGroup:(UIGroup*)inUIGroup
{
    return [self InitMainMenuButton:linkMenuID MMID:mmButtonID visible:bVisible on:bToggledOn enabled:bEnabled uiGroup:inUIGroup position:&MMPos[mmButtonID]];
}

-(NeonButton*)InitMainMenuButton:(ENeonMenu)linkMenuID MMID:(MainMenuButtons)mmButtonID visible:(BOOL)bVisible on:(BOOL)bToggledOn enabled:(BOOL)bEnabled uiGroup:(UIGroup*)inUIGroup position:(Vector3*)inPosition
{
	NeonButton*         curButton;
	NeonButtonParams    buttonParams;
	
	// Init the Logo FIRST, so it is in the BG
	if ( mNumButtons == 0 )
		[ self InitLogo ];
	
	// TODO: Probably should verify that there is no menu already with this suit.
	
	[NeonButton InitDefaultParams:&buttonParams];
    
    buttonParams.mTexName					= [NSString stringWithUTF8String:MMOff[mmButtonID]];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:MMLit[mmButtonID]];
	buttonParams.mToggleTexName				= [NSString stringWithUTF8String:MMUnlit[mmButtonID]];
	buttonParams.mTextSize					= 18;
    buttonParams.mBorderSize				= 1;
    buttonParams.mQuality					= NEON_BUTTON_QUALITY_HIGH;
    buttonParams.mFadeSpeed					= BUTTON_FADE_SPEED;
    buttonParams.mUIGroup					= inUIGroup;
	buttonParams.mUISoundId					= SFX_MENU_BUTTON_PRESS;
    buttonParams.mBoundingBoxCollision		= TRUE;
    SetVec2(&buttonParams.mBoundingBoxBorderSize, 5, 5);
	SetColorFromU32(&buttonParams.mBorderColor	, NEON_BLA);
	SetColorFromU32(&buttonParams.mTextColor	, NEON_WHI);
    
	if ( !bEnabled )
	{
		SetColorFromU32(&buttonParams.mBorderColor	, NEON_BLA);
		SetColorFromU32(&buttonParams.mTextColor	, NEON_GRAY);
	}
	
	SetRelativePlacement(&buttonParams.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    
	curButton = [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
	[curButton SetToggleOn:bToggledOn];
	curButton->mIdentifier = linkMenuID;
    
	[curButton Enable];
	
	if ( bEnabled )
	{
		[curButton SetListener:self];
	}
	else
	{
		
		[curButton SetListener:NULL];
		//[curButton SetPulseAmount:0.0f time:0.25f];
		[curButton SetActive:FALSE];
	}
    

    [curButton SetVisible:bVisible];

	
	[curButton SetPosition:inPosition];
	
	[curButton release];
    mNumButtons++;
    
    return curButton;
}

-(void)ActivateMainMenu
{
    [self InitMainMenuButton:Run21_Main_LevelSelect	MMID:MMButton_Run21 visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.uiObjects];
    // Don't display Neon Logo
    //[self InitMainMenuButton:NeonMenu_NeonLogo      withMMID:MMButton_NeonWeb   withVisible:TRUE withOn:TRUE withEnabled:TRUE];
 
    #if ENABLE_SKU_RAINBOW
        [self InitMainMenuButton:Rainbow_Main_LevelSelect withMMID:MMButton_Rainbow withVisible:TRUE withOn:TRUE withEnabled:TRUE];
    #endif
    
    int usableSpace = GetScreenVirtualWidth() - (2 * sTopBarMenuPadding);
    
    int curX = sTopBarMenuPadding;
    int numButtons = 2;
#if !NEON_SOLITAIRE_21
    numButtons += 3;
#endif
    int spacing = usableSpace / numButtons;
    
    curX += ((spacing - sTopBarButtonWidth) / 2);
    
    Vector3 curPosition;
    
    curPosition.mVector[x] = curX;
    curPosition.mVector[y] = topbar_y;
    curPosition.mVector[z] = 0;
    
    [self InitMainMenuButton:NeonMenu_Main_Options_Music MMID:MMButton_BGM visible:TRUE on:[[SaveSystem GetInstance] GetMusicOn] enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
    
    curPosition.mVector[x] += spacing;
    [self InitMainMenuButton:NeonMenu_Main_Options_Sound MMID:MMButton_SFX visible:TRUE on:[[SaveSystem GetInstance] GetSoundOn] enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
    
#if USE_LIVES
    curPosition.mVector[x] += spacing;
    [self InitMainMenuButton:NeonMenu_Main_Extras_Facebook MMID:MMButton_Facebook visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
#endif     

#if !NEON_SOLITAIRE_21
    curPosition.mVector[x] += spacing;
    [self InitMainMenuButton:NeonMenu_Main_Extras_GameCenter MMID:MMButton_GameCenter visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
    
    curPosition.mVector[x] += spacing;
    [self InitMainMenuButton:NeonMenu_Main_Extras_Contact_Us MMID:MMButton_Contact_Us visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
#endif

    [self InitMainMenuButton:NeonMenu_Main_Extras_IAP_Store MMID:MMButton_IAP_NoAds visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.uiObjects];
#if USE_MARATHON
    [self InitMainMenuButton:Run21_Main_Marathon	MMID:MMButton_Marathon  visible:TRUE on:TRUE enabled:TRUE uiGroup:mActiveMenu.uiObjects];
#endif
	return;
}


-(void)ActivateTextBox:(NSString*)prompt
{
    // Display message asking user to confirm they want to start a new game
    TextBoxParams tbParams;
    
    [TextBox InitDefaultParams:&tbParams];
    
    SetColorFromU32(&tbParams.mColor,		NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor, NEON_BLA);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= NSLocalizedString(prompt, NULL);
    tbParams.mFontSize		= 18;
    tbParams.mFontType		= NEON_FONT_STYLISH;
    tbParams.mWidth			= 320;	// Gutter the left and right border of screen
    tbParams.mUIGroup		= mActiveMenu.uiObjects;
    
    TextBox* textBox		= [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [textBox SetVisible:FALSE];
    [textBox Enable];
    
    PlacementValue placementValue;
    SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    
    [textBox SetPlacement:&placementValue];
    [textBox SetPositionX:320 Y:90 Z:0];
    
    [textBox release];
}


-(void)ActivateLevelSelectCard:(int)cardID
{
	NSString				*textureString;
	
	NSMutableArray			*textureFilenames = [[NSMutableArray alloc] initWithCapacity:LSSTATUS_NUM];
	
	MultiStateButtonParams  buttonParams;
	[MultiStateButton		InitDefaultParams:&buttonParams];
	
	textureString = @"r21level_locked.papng";	// Locked cards are not individually created, we use a global one.
	[ textureFilenames insertObject:textureString atIndex:LSSTATUS_LOCKED ];
	
	textureString = [LevelDefinitions GetCardTextureForLevel:cardID];
	[ textureFilenames insertObject:textureString atIndex:LSSTATUS_AVAILABLE ];
	
	buttonParams.mButtonTextureFilenames	= textureFilenames;
	buttonParams.mBoundingBoxCollision		= TRUE;
	buttonParams.mUIGroup					= mActiveMenu.secondaryObjects;
	
	levelSelect.mLevelButton[cardID].button	= [(MultiStateButton*)[MultiStateButton alloc] InitWithParams:&buttonParams];
	MultiStateButton	*curButton			= levelSelect.mLevelButton[cardID].button;
    [curButton release];
	
	curButton->mIdentifier					= LSID_LevelButtonBase + cardID;
	[curButton								SetVisible:FALSE];
	[curButton								SetListener:self];
	[curButton								SetProjected:FALSE];
    
    int locOffset = cardID % NUM_LEVELS_IN_ROOM;
    
	[ curButton								SetPosition:&sLS_LevelPos[locOffset]	];
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 8;
    tbParams.mString		= [[[Flow GetInstance] GetLevelDefinitions] GetLevelDescription:cardID];
    tbParams.mFontSize		= 14;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mAlignment     = TEXTBOX_ALIGNMENT_CENTER;
    tbParams.mUIGroup		= mActiveMenu.uiObjects;
    
    levelSelect.mLevelDescription[cardID] = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    
    [levelSelect.mLevelDescription[cardID] SetVisible:FALSE];
    [levelSelect.mLevelDescription[cardID] SetPositionX:sLS_LevelPos[locOffset].mVector[x] + 35 Y:sLS_LevelPos[locOffset].mVector[y] + 112 Z:0.0];
    [levelSelect.mLevelDescription[cardID] release];

    // Find out of this card is locked or not.
    if (cardID == 0 || cardID <= [[SaveSystem GetInstance] GetMaxLevel])
    {
        [curButton SetActiveIndex:LSSTATUS_AVAILABLE];
    }
    else
    {
        [curButton SetActiveIndex:LSSTATUS_LOCKED];
    }
    
	[textureFilenames release];
	mNumButtons++;
}

-(NeonButton*)InitLevelSelectBottomButton:(LevelSelectButtons)linkMenuID levelSelectID:(LevelSelectIDs)lsID
{
	NeonButton*         curButton;
	NeonButtonParams    buttonParams;
	//int                 nButtonIndex	= [mActiveMenu.uiObjects count];
	
	//NSAssert(nButtonIndex >= 0 && nButtonIndex < LSButton_Num , @"Invalid Button Index in InitButton");
    //NSAssert(mNumButtons >= 0 && mNumButtons < LSButton_Num, @"Invalid number of buttons already created");
    
	[NeonButton InitDefaultParams:&buttonParams];
    
    buttonParams.mTexName					= [NSString stringWithUTF8String:levelSelectButtonTextureOffName[linkMenuID]];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:levelSelectButtonTextureLitName[linkMenuID]];
	buttonParams.mToggleTexName				= [NSString stringWithUTF8String:levelSelectButtonTextureUnlitName[linkMenuID]];
    buttonParams.mBorderSize				= 1;
    buttonParams.mQuality					= NEON_BUTTON_QUALITY_HIGH;
    buttonParams.mFadeSpeed					= BUTTON_FADE_SPEED;
    buttonParams.mUIGroup					= mActiveMenu.uiObjects;
	buttonParams.mUISoundId					= SFX_MENU_BUTTON_PRESS;
    buttonParams.mBoundingBoxCollision		= TRUE;
    SetVec2(&buttonParams.mBoundingBoxBorderSize, 0, 4);
	
	curButton = [(NeonButton*)[NeonButton alloc] InitWithParams:&buttonParams];
    [curButton release];
	
	curButton->mIdentifier = lsID;	// Might want to change this
    [curButton SetVisible:FALSE];
    
    [curButton Enable];
	[curButton SetPosition:&slevelSelectButtonPositions[linkMenuID] ];
	[curButton SetListener:self];
    
    switch ( linkMenuID )
    {
        case LSButton_Back:
            levelSelect.mBackButton = curButton;
            break;
            
        case LSButton_Next:
            levelSelect.mNextButton = curButton;
            break;
            
        case LSButton_Prev:
            levelSelect.mPrevButton = curButton;
            break;
    }

    mNumButtons++;
    
    return curButton;
}

-(void)LeaveLevelSelectMenu
{
	[levelSelect.mBackButton release];
    [levelSelect.mNextButton release];
    [levelSelect.mPrevButton release];
    
    bottomBar.mTornadoAmount = NULL;
    bottomBar.mXRayAmount = NULL;
    
	return;
}

-(void)ActivateLevelSelectScore
{
	char fileName[maxIconFileName];
	   
	// Iterate through all the levels of the game.
	for ( int level = 0; level < RUN21_LEVEL_NUM; level++)
	{
		Vector3			starLoc;
		ImageWellParams imageWellparams;
        int				nScore = 0;
        
        int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunnersForGameMode:GAMEMODE_TYPE_RUN21 level:level];
        
        nScore = [[SaveSystem GetInstance] GetStarsForLevel:level];
		
		levelSelect.mLevelButton[level].bestScore = nScore;

		snprintf(fileName, 256, "ls_star_score_%d.papng",  nScore );
        
        int locOffset = level % NUM_LEVELS_IN_ROOM;
        
		Add3( &sLevelSelectSmallStarOffset, &sLS_LevelPos[locOffset], &starLoc);
		
		[ImageWell InitDefaultParams:&imageWellparams];
        
        float step = 0;
        float start = 0;
        
        DistributeItemsOverRange((float)sLSCardWidth, numRunners, sLSStarWidth, &start, &step);
        
        for (int star = 0; star < numRunners; star++)
        {
            NSString* smallStarFilename = NULL;
            
            if (star < nScore)
            {
                smallStarFilename = [MainMenu fullStarFilenameForLevel:level];
            }
            else
            {
                smallStarFilename = [MainMenu emptyStarFilename];
            }
            
            imageWellparams.mTextureName	= smallStarFilename;
            imageWellparams.mUIGroup		= mActiveMenu.secondaryObjects;
            
            ImageWell* imageWell = [(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
            
            [imageWell SetProjected:FALSE];
            [imageWell SetVisible:FALSE];
            [imageWell SetPositionX:(starLoc.mVector[x] + start + step*star) Y:starLoc.mVector[y] Z:starLoc.mVector[z]];
            
            [levelSelect.mLevelButton[level].stars addObject:imageWell];
            
            [imageWell release];
        }
	}
	
}

-(void)ActivateLevelSelectRoom
{
    // Deactivate any level choice we've made.
    levelSelect.nLevelSelected = LSID_NUM;
    
    // Only show the Large star that is
    for (int i = 0; i < LEVELSELECT_ROOM_NUM; i++ )
    {
        BOOL    bStarVisible = FALSE;
        
        if (i == levelSelect.mLevelSelectPage)
        {
            bStarVisible = TRUE;
        }
        
        [levelSelect.mBG[i] SetVisible:bStarVisible];
        [levelSelect.mRoomName[i] SetVisible:bStarVisible];
    }
    
    // Deactivate all level select buttons and stars, except the level we are in.
    for ( int nCard = 0 ; nCard < RUN21_LEVEL_NUM ; nCard++ )
	{
        LevelSelectHolder *nLevelCard = &levelSelect.mLevelButton[nCard];
        
        [levelSelect.mLevelDescription[nCard] SetVisible:FALSE];
        
        if (levelSelect.mLevelSelectPage != [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:nCard])
        {
            for (ImageWell* curStar in nLevelCard->stars)
            {
                [curStar  SetVisible:FALSE];
            }
            
            [nLevelCard->button     Disable];
        }
        else
        {
            [nLevelCard->button     Enable];
            
            if ( [nLevelCard->button GetActiveIndex ] != LSSTATUS_LOCKED )
            {
                for (ImageWell* curStar in nLevelCard->stars)
                {
                    [curStar  SetVisible:TRUE];
                }

                [levelSelect.mLevelDescription[nCard] SetVisible:TRUE];
            }
            
        }
	}

    int nextRoom = (levelSelect.mLevelSelectPage + 1) % LEVELSELECT_ROOM_NUM;
    int prevRoom = levelSelect.mLevelSelectPage - 1;
    
    if (prevRoom < 0)
    {
        prevRoom += LEVELSELECT_ROOM_NUM;
    }
    
    int maxRoomUnlocked = [[SaveSystem GetInstance] GetMaxRoomUnlocked];
    
    if (nextRoom > maxRoomUnlocked)
    {
        if (mRoomUnlockDescription != NULL)
        {
            [[GameObjectManager GetInstance] Remove:mRoomUnlockDescription];
        }
        
        [mNextRoomButton SetActive:FALSE];
        [self ActivateLevelSelectRoomLockDescription];
        
        if ([[RegenerationManager GetInstance] GetRoomUnlockState] == ROOM_UNLOCK_STATE_COUNTDOWN)
        {
            [mRoomUnlockButton Enable];
            [mRoomUnlockStringCloud Enable];
        }
        else
        {
            [mRoomUnlockButton Disable];
            [mRoomUnlockStringCloud Disable];
        }
    }
    else
    {
        [[GameObjectManager GetInstance] Remove:mRoomUnlockDescription];
        mRoomUnlockDescription = NULL;
        
        [mRoomUnlockButton Disable];
        [mRoomUnlockStringCloud Disable];
        
        [mNextRoomButton SetActive:TRUE];
    }
    
    if (prevRoom > maxRoomUnlocked)
    {
        [mPrevRoomButton SetActive:FALSE];
    }
    else
    {
        [mPrevRoomButton SetActive:TRUE];
    }
}

-(void)ActivateLevelSelectRoomLockDescription
{
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    NSString* string = [MainMenu GetRoomLockDescription];
    
    tbParams.mStrokeSize	= 8;
    tbParams.mString		= string;
    tbParams.mFontSize		= 11;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mWidth         = 80;
    
    mRoomUnlockDescription = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    
    [mRoomUnlockDescription SetVisible:TRUE];
    
    RoomUnlockState roomUnlockState = [[RegenerationManager GetInstance] GetRoomUnlockState];
    [mRoomUnlockDescription SetPosition:&sRoomLockDescriptionPositions[roomUnlockState]];
    
    [[GameObjectManager GetInstance] Add:mRoomUnlockDescription];
    [mRoomUnlockDescription release];
}

-(void)ActivateLevelSelectTitle
{
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 8;
    tbParams.mString		= NSLocalizedString(@"LS_ChooseLevel", NULL);
    tbParams.mFontSize		= 20;
    tbParams.mFontType		= NEON_FONT_STYLISH;
    tbParams.mUIGroup		= mActiveMenu.uiObjects;
    
    TextBox* title = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    
    [title    SetVisible:TRUE];
    [title    SetPositionX:160 Y:55 Z:0.0];
    [title    release];
}

-(void)ActivateLevelSelectMenu
{
	// 1) Draw the BG - kk
	[self InitLevelSelectBG ];
	
	// 2) Clear the selected level.
	levelSelect.nLevelSelected = LSID_NUM;

#ifdef NEON_SOLITAIRE_21
    if ([[[Flow GetInstance] GetLevelDefinitions] GetMainMenuUnlocked])
#else
    if (([[SaveSystem GetInstance] GetMaxLevel] > RUN21_LEVEL_1))
#endif
    {
        [self InitLevelSelectBottomButton:LSButton_Back		levelSelectID:LSID_Back];
    }
    
    mPrevRoomButton = [self InitLevelSelectBottomButton:LSButton_Prev levelSelectID:LSID_Prev];
    mNextRoomButton = [self InitLevelSelectBottomButton:LSButton_Next levelSelectID:LSID_Next];
    
	// 4) Create the Level Select Cards 0-10.  Enabled=false if the savedLevel is less than it's value.
	for ( int nCard = 0 ; nCard < RUN21_LEVEL_NUM ; nCard++ )
	{
		[ self ActivateLevelSelectCard:nCard ];
	}
    
    [self ActivateLevelSelectScore];
    [self ActivateRoomUnlockButtonWithPositionX:340 y:45 unlockButton:&mRoomUnlockButton stringCloud:&mRoomUnlockStringCloud connectingTextBox:&mConnectingTextBox];
    [self ActivateLevelSelectRoom];
    
    [self ActivateLevelSelectTitle];
    
    [self ActivateLevelSelectOptions];
    
	[mActiveMenu.secondaryObjects Finalize];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        Message msg;
        
        msg.mId = EVENT_MAIN_MENU_ENTER_LEVEL_SELECT;
        msg.mData = NULL;
        
        [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];
    } );
    
    [[NeonMetrics GetInstance] logEvent:@"Level Select Entered" withParameters:NULL];

	// Hack to trick the system into not setting up the layout or bg.
	mNumButtons--;
	return;
}

-(void)ActivateLevelSelectOptions
{
    Vector3 curPosition;
    
    curPosition.mVector[x] = 20.0f;
    curPosition.mVector[y] = 50.0f;
    curPosition.mVector[z] = 0;
    
    [self InitMainMenuButton:NeonMenu_Main_Options_Music MMID:MMButton_BGM visible:TRUE on:[[SaveSystem GetInstance] GetMusicOn] enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
    
    curPosition.mVector[x] += 40.0f;
    [self InitMainMenuButton:NeonMenu_Main_Options_Sound MMID:MMButton_SFX visible:TRUE on:[[SaveSystem GetInstance] GetSoundOn] enabled:TRUE uiGroup:mActiveMenu.uiObjects position:&curPosition];
	return;
}

-(void)ActivateRoomUnlockButtonWithPositionX:(float)inX y:(float)inY unlockButton:(NeonButton**)outButton stringCloud:(StringCloud**)outStringCloud connectingTextBox:(TextBox**)outTextBox
{
    NeonButtonParams neonButtonParams;
    [NeonButton InitDefaultParams:&neonButtonParams];
    
    neonButtonParams.mTexName = @"unlockroom.papng";
    neonButtonParams.mPregeneratedGlowTexName = @"unlockroom_glow.papng";
    neonButtonParams.mBoundingBoxCollision = TRUE;
    neonButtonParams.mUIGroup = mActiveMenu.secondaryObjects;
    
    NeonButton* unlockButton = [[NeonButton alloc] InitWithParams:&neonButtonParams];
    
    unlockButton->mIdentifier = NeonMenu_Unlock_Next_Room;
    [unlockButton SetListener:self];
    [unlockButton SetPositionX:inX Y:inY Z:0];
    [unlockButton SetVisible:FALSE];
    [unlockButton release];
    
    *outButton = unlockButton;
    
    int numRemainingLevels = (LEVELSELECT_ROOM_LAST - [[SaveSystem GetInstance] GetMaxRoomUnlocked]) * NUM_LEVELS_IN_ROOM;
    
    StringCloudParams* stringCloudParams = [[StringCloudParams alloc] init];
    stringCloudParams->mUIGroup = mActiveMenu.secondaryObjects;
    [stringCloudParams->mStrings addObject:@"<B><color=0xFFE845>Tap Here</color></B>"];
    [stringCloudParams->mStrings addObject:[NSString stringWithFormat:@"<B>%d more levels</B>", numRemainingLevels]];
    [stringCloudParams->mStrings addObject:@"<B>Unlock All</B>"];
    stringCloudParams->mFontSize = 12;
    
    StringCloud* stringCloud = [[StringCloud alloc] initWithParams:stringCloudParams];
    [stringCloud release];
    
    [stringCloud SetPositionX:(inX + 40) Y:(inY - 5) Z:0];
    [stringCloud SetVisible:FALSE];
    *outStringCloud = stringCloud;
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    SetColorFromU32(&tbParams.mColor,          NEON_WHI);
    SetColorFromU32(&tbParams.mStrokeColor,    NEON_BLA);
    
    tbParams.mStrokeSize	= 5;
    tbParams.mFontSize		= 12;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mWidth         = 320;
    tbParams.mUIGroup       = mActiveMenu.secondaryObjects;

    tbParams.mString = NSLocalizedString(@"LS_Connecting", NULL);
    TextBox* textBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [textBox SetVisible:FALSE];
    [textBox SetPositionX:(inX + 40) Y:(inY + 13) Z:0.0];
    [textBox release];
    
    *outTextBox = textBox;
}

-(void)TutorialComplete
{
    [super TutorialComplete];
    
    for (UIObject* curObject in mHintDisabledObjects)
    {
        [curObject SetActive:TRUE];
        curObject.FadeWhenInactive = TRUE;
    }
    
    [mHintDisabledObjects removeAllObjects];
}

-(LevelSelectRoom)GetLevelSelectPage
{
    LevelSelectRoom levelSelectPage = [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:mMaxLevel];
    
    if (levelSelectPage > [[SaveSystem GetInstance] GetMaxRoomUnlocked])
    {
        levelSelectPage = [[SaveSystem GetInstance] GetMaxRoomUnlocked];
    }
    
    return levelSelectPage;
}

+(NSString*)GetRoomLockDescription
{
    NSString* description = NULL;
    
    LevelSelectRoom maxRoomUnlocked = [[SaveSystem GetInstance] GetMaxRoomUnlocked];
    int maxRequiredLevel = (maxRoomUnlocked + 1) * NUM_LEVELS_IN_ROOM;
    
    switch ([[RegenerationManager GetInstance] GetRoomUnlockState])
    {
        case ROOM_UNLOCK_STATE_IDLE:
        {
            if (maxRoomUnlocked < LEVELSELECT_ROOM_LAST)
            {
                description = [NSString stringWithFormat:NSLocalizedString(@"LS_LevelSelect_Unlock_Room", NULL), maxRequiredLevel];
            }
            
            break;
        }
        
        case ROOM_UNLOCK_STATE_COUNTDOWN:
        {
            int timeRemaining = [[RegenerationManager GetInstance] GetRoomUnlockTimeRemaining];
            
            int hours = timeRemaining / 60 / 60;
            int minutes = (timeRemaining - (hours * 60 * 60)) / 60;
            int seconds = timeRemaining - (hours * 60 * 60) - (minutes * 60);
            
            NSString* timeString = NULL;
            
            if (hours > 0)
            {
                timeString = [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
            }
            else
            {
                timeString = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
            }
            
            
            description = [NSString stringWithFormat:NSLocalizedString(@"LS_LevelSelect_Unlock_Wait", NULL), timeString];
            
            break;
        }
    }

    return description;
}

-(void)ActivatePlayTutorial:(ENeonMenu)menuID
{
	[ self InitBackButton:NeonMenu_Main];
}

-(void)InitBackButton:(ENeonMenu)menuID
{
    NeonButtonParams	button;
    [NeonButton InitDefaultParams:&button ];
	
	if ( mNumButtons == 0 )
		[ self InitLogo ];
    
	button.mTexName					= [NSString stringWithUTF8String:levelSelectButtonTextureUnlitName[LSButton_Back]];
    button.mToggleTexName			= [NSString stringWithUTF8String:levelSelectButtonTextureUnlitName[LSButton_Back]];
    button.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:levelSelectButtonTextureLitName[LSButton_Back]];
    button.mText					= NULL;
	button.mTextSize				= 18;
    button.mBorderSize				= 1;
    button.mQuality					= NEON_BUTTON_QUALITY_HIGH;
    button.mFadeSpeed				= BUTTON_FADE_SPEED;
	button.mUIGroup                 = mActiveMenu.uiObjects;
    button.mBoundingBoxCollision    = TRUE;
	button.mUISoundId				= SFX_MENU_BACK;
	SetColorFromU32(&button.mBorderColor	, NEON_BLA);
    SetColorFromU32(&button.mTextColor		, NEON_WHI);
    SetRelativePlacement(&button.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    SetVec2(&button.mBoundingBoxBorderSize, 2, 2);
    
    NeonButton* backButton = [ (NeonButton*)[NeonButton alloc] InitWithParams:&button ];
    backButton->mIdentifier = menuID;
    [backButton SetVisible:FALSE];
    [backButton Enable];
    [backButton SetPositionX:Sbar_Y1 Y:Sbar_Y1 Z:0.0];
	[backButton SetPosition:&slevelSelectButtonPositions[LSButton_Back] ];
    [backButton SetListener:self];
    [backButton release];
}

-(void)ActivateMenu:(ENeonMenu)menuID
{
    mNumButtons = 0;

	[ self InitMenu:menuID ];
	
	switch ( menuID )
	{
		case NeonMenu_Main:
		{    
			[ self ActivateMainMenu];
			break;
		}
			
		case NeonMenu_Main_Extras:
		{
			//[ self ActivateExtrasMenu ];
            break;
		}
			
#if defined ( NEON_RUN_21 )
        case NeonMenu_Main_Options:
        {
            // Do nothing now, we don't start a new screen anymore.
            break;
        }
        case Rainbow_Main_LevelSelect:
        case Run21_Main_LevelSelect:
        {
			[ self ActivateLevelSelectMenu ];
			break;
        }
			
        case NeonMenu_Main_Options_ClearData:
        {
            // Prompt.
            [ self ActivateTextBox: @"LS_EraseProgress" ];
            break;
        }

#else
		#error "Unknown sku"
#endif

        default:
        {
            NSAssert(FALSE, @"Attempting to load main menu without an active menu set");
            break;
        }
	}
    
    [mActiveMenu.uiObjects Finalize];
}

-(void)Draw
{
	
}

-(void)DrawOrtho
{
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
    switch ( inEventId )
    {
        case EVENT_MAIN_MENU_ACTIVATE_VIP:
        {
            //if the player has just bought VIP, we need to setup the main menu again
            sUserData.mType = USERDATA_TYPE_MENU;
            sUserData.mData = NeonMenu_Main;
            [self LeaveMenu];
            break;
        }
        
        case EVENT_MAIN_MENU_LEAVE_MENU:
        {
            sUserData.mType = USERDATA_TYPE_FLOW;
            sUserData.mData = 0;
            sUserData.mDataTwo = GAMEMODE_TYPE_RUN21;
            [self LeaveMenu];
            break;
        }
        
        case EVENT_IAP_DELIVER_CONTENT:
        {
            NSString* identifier = (NSString*)inData;
            IapProduct product = [[InAppPurchaseManager GetInstance] GetIAPWithIdentifier:identifier];
            
            if ((product == IAP_PRODUCT_UNLOCK_NEXT) || (product == IAP_PRODUCT_UNLOCK_ALL))
            {
                if (mTutorialStatus == TUTORIAL_STATUS_RUNNING)
                {
                    [self SkipTutorial];
                }

                levelSelect.mLevelSelectPage = (LevelSelectRoom)min(levelSelect.mLevelSelectPage + 1, LEVELSELECT_ROOM_DIAMOND);
                
                if (mActiveMenu.menuID == Run21_Main_LevelSelect)
                {
                    [self ActivateLevelSelectRoom];
                    
                    [bottomBar.mRoomUnlockButton Disable];
                    [bottomBar.mRoomUnlockStringCloud Disable];
                }
            }

            if (mActiveMenu.menuID == Run21_Main_LevelSelect)
            {
                [bottomBar.mArrow Disable];
                [bottomBar.mRemoveAds Disable];
            }
            
            break;
        }
        
        case EVENT_RATED_GAME:
        {
            [self UpdateBottomBar];
            [self EvaluateXrayIndicators];
            [self EvaluateTornadoIndicators];
            break;
        }
        
        default:
            break;
    }
    
    [super ProcessEvent:inEventId withData:inData];
}

-(void)EvaluateAudioOptions
{
    BOOL currentSoundOn = [[SoundPlayer GetInstance] GetSoundEnabled];
    BOOL currentMusicOn = [[NeonMusicPlayer GetInstance] GetMusicEnabled];
    
    if (mSavedSoundOn != currentSoundOn)
    {
        [[SoundPlayer GetInstance] SetSoundEnabled:mSavedSoundOn];
    }
    
    if (mSavedMusicOn != currentMusicOn)
    {
        [[NeonMusicPlayer GetInstance] SetMusicEnabled:mSavedMusicOn];
    }
}

-(void)EvaluateXrayIndicators
{
    if ([[SaveSystem GetInstance] GetNumXrays] > 0)
    {
        [bottomBar.mXRayBuyMore SetVisible:FALSE];
        [bottomBar.mXRayAmount SetVisible:TRUE];
    }
    else
    {
        [bottomBar.mXRayBuyMore SetVisible:TRUE];
        [bottomBar.mXRayAmount SetVisible:FALSE];
    }
}

-(void)EvaluateTornadoIndicators
{
    if ([[SaveSystem GetInstance] GetNumTornadoes] > 0)
    {
        [bottomBar.mTornadoBuyMore SetVisible:FALSE];
        [bottomBar.mTornadoAmount SetVisible:TRUE];
    }
    else
    {
        [bottomBar.mTornadoBuyMore SetVisible:TRUE];
        [bottomBar.mTornadoAmount SetVisible:FALSE];
    }
}

-(BOOL)ShouldShowBottomBarRoomUnlockButton
{
    BOOL showRoomUnlockButton = FALSE;
    
    if (([[SaveSystem GetInstance] GetMaxRoomUnlocked] < LEVELSELECT_ROOM_LAST) && [[[Flow GetInstance] GetLevelDefinitions] GetRoomsUnlocked])
    {
        showRoomUnlockButton = TRUE;
    }
    
    return showRoomUnlockButton;
}

-(void)SetCurrentMenuActive:(BOOL)inActive
{
    int numObjects = [mActiveMenu.uiObjects count];
        
    for (int i = 0; i < numObjects; i++)
    {
        UIObject* curObject = (UIObject*)[mActiveMenu.uiObjects objectAtIndex:i];
        
        if ([curObject GetVisible])
        {
            [curObject SetActive:inActive];
        }
    }
    
    numObjects = [mActiveMenu.secondaryObjects count];
    
    for (int i = 0; i < numObjects; i++)
    {
        UIObject* curObject = (UIObject*)[mActiveMenu.secondaryObjects objectAtIndex:i];
        
        if ([curObject GetVisible])
        {
            [curObject SetActive:inActive];
        }
    }
}

-(LevelSelectMenu*)GetLevelSelect
{
    return &levelSelect;
}

-(void)FadeComplete:(NSObject*)inObject;
{
    if (inObject == NULL)
    {
        [[GameStateMgr GetInstance] Push:[IAPStore alloc] ];
    }
    else if ([inObject class] == [MainMenu class])
    {
        NSLog(@"Application Load Time is %f", NeonEndTimer());
    }
    else
    {
        NSAssert(FALSE, @"Unknown fade path");
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        UITextField* redemptionCode = [alertView textFieldAtIndex:0];
        NSString* text = [redemptionCode text];
        
        if (text != NULL)
        {
            PFQuery *query = [PFQuery queryWithClassName:@"Redemption"];
        
            [query whereKey:@"Key" equalTo:text];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
            {
                if (!error)
                {
                    BOOL objectFound = ([objects count] > 0);
                    
                    if (objectFound)
                    {
                        [[SaveSystem GetInstance] SetMaxLevel:RUN21_LEVEL_LAST];
                        [[SaveSystem GetInstance] SetMaxLevelStarted:RUN21_LEVEL_LAST];
                        
                        for (int level = 0; level < RUN21_LEVEL_NUM; level++)
                        {
                            [[SaveSystem GetInstance] SetStarsForLevel:level withStars:4];
                        }
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NULL
                                                                        message: @"Code redeemed. All levels unlocked! Main menu will now reload."
                                                                       delegate: NULL
                                                              cancelButtonTitle: NULL
                                                              otherButtonTitles: @"OK", NULL];
                        
                        [alert show];
                        
                        [[Flow GetInstance] ExitGameMode];
                        [[Flow GetInstance] EnterGameMode:GAMEMODE_TYPE_MENU level:0];
                    }
                }
                else
                {
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
    }
}

+(NSString*)emptyStarFilename
{
    return [NSString stringWithUTF8String:emptyStarIconName];
}

+(NSString*)fullStarFilenameForRoom:(LevelSelectRoom)inRoom
{
    return [NSString stringWithUTF8String:fullStarIconNames[inRoom]];
}

+(NSString*)fullStarFilenameForLevel:(int)inLevel
{
    LevelSelectRoom room = [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:inLevel];

    return [NSString stringWithUTF8String:fullStarIconNames[room]];
}

@end

@implementation DeleteDataUIDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:NSLocalizedString(@"LS_Yes",NULL)])
    {
        [ [SaveSystem GetInstance] Reset ];
    }
}

@end

@implementation FacebookUIDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString        *title      = [alertView buttonTitleAtIndex:buttonIndex];
    UserMenuAction  uma         = UMA_NUM;
    BOOL            bVisitWeb   = FALSE;
    
    if ([title isEqualToString:NSLocalizedString(@"LS_Login",NULL)])
    {
        uma = UMA_Facebook_Login;
        [[GameStateMgr GetInstance] Push:[FacebookLoginMenu alloc]];
    }
    else if ([title isEqualToString:NSLocalizedString(@"LS_Logout",NULL)])
    {
        uma = UMA_Facebook_Logout;
        //[[NeonAccountManager GetInstance] Logout];
        
    }
    else if ([title isEqualToString:NSLocalizedString(@"LS_Community",NULL)])
    {
        uma         = UMA_Facebook_Community;
        bVisitWeb   = TRUE;
    }
    else
    {
        uma         = UMA_Facebook_Cancel;
        // No-op
    }
        
    if ( bVisitWeb )
    {
        UIApplication *neonApp      = [ UIApplication sharedApplication ];
        NSURL *facebookNativeSite   = [ NSURL URLWithString:@"fb://profile/172787159547068"];                               // FB Page's profile_owner ID, verify with: https://facebook.com/172787159547068
        NSURL *facebookBrowserSite  = [ NSURL URLWithString:@"https://www.facebook.com/SolitaireVsBlackjackCommunity"];     // Browser URL
        
        if ( [neonApp canOpenURL:facebookNativeSite] )
        {
            [ neonApp openURL:facebookNativeSite ];
        }
        else
        {
            [ neonApp openURL:facebookBrowserSite ];
        }
    }
        
}
@end

@implementation CommunityDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString        *title      = [alertView buttonTitleAtIndex:buttonIndex];
    UserMenuAction  uma         = UMA_NUM;
    BOOL            bVisitWeb   = FALSE;
    BOOL            bEmail      = FALSE;
    
    if ([title isEqualToString:NSLocalizedString(@"LS_Email_Us",NULL)])
    {
        uma = UMA_NeonCommunity_ContactUs;
        bEmail = TRUE;
    }
    else if ([title isEqualToString:NSLocalizedString(@"LS_WebComic",NULL)])
    {
        uma         = UMA_NeonCommunity_WebComic;
        bVisitWeb   = TRUE;
    }
    else
    {
        // No-op
        uma         = UMA_NeonCommunity_Cancel;
    }
    
    if ( bVisitWeb )
    {
        UIApplication *neonApp      = [ UIApplication sharedApplication ];
        NSURL *comicSite  = [ NSURL URLWithString:@"http://comic.neongam.es"];
        [ neonApp openURL:comicSite ]; 
    }
    if ( bEmail )
    {
        NSLog(@"NeonMenu_Main_Extras_Contact_Us - Does not Show on Simulator");
        
        NSDictionary *gameInfo = [[NSBundle mainBundle] infoDictionary];
        
        NSString *GameName      = [gameInfo objectForKey:@"CFBundleDisplayName"];
        NSString *GameVersion   = [gameInfo objectForKey:@"CFBundleVersion"];
        NSString *address       = @"support@neongames.us";
        NSString *subject       = [NSString stringWithFormat:@"%@ Feedback",GameName];
        NSString *body          = [NSString stringWithFormat:@"Type your message here\n\n--\n\n%@\nGame Version:%@\n%@ with iOS %@",GameName,GameVersion,machineName(), [[UIDevice currentDevice] systemVersion]];
        
        NSString *URLString     = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",address,subject,body];
        URLString               = [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
    }
    
}
@end

@implementation RefillLivesDelegate

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
//This function is required to call facebook web dialog
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