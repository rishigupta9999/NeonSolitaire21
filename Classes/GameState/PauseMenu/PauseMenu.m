//
//  PauseMenu.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

// TODO: KKing - Really need to clean this up and intergrate this with MainMenu as there is tons of overlap and redundant code.

#import "PauseMenu.h"

#import "GameObjectManager.h"
#import "GameStateMgr.h"
#import "ModelManager.h"
#import "CompanionSelect.h"
#import "UIGroup.h"
#import "UIObject.h"
#import "NeonButton.h"
#import "TextBox.h"
#import "TextTextureBuilder.h"
#import "Fader.h"

#import "CardDefines.h"
#import "MainMenu.h"
#import "UINeonEngineDefines.h"
#import "Flow.h"
#import "MenuFlowTypes.h"

#import "SoundPlayer.h"
#import "NeonMusicPlayer.h"

#import "GameStateMgr.h"
#import "IAPStore.h"
#import "RegenerationManager.h"
#import "NeonAccountManager.h"

#define BUTTON_FADE_SPEED   (7.0)

typedef enum
{
	USERDATA_TYPE_RESTART,
    USERDATA_TYPE_STATE_ACTION,
    USERDATA_TYPE_MENU,
    USERDATA_MAX,
    USERDATA_INVALID = USERDATA_MAX
} UserDataType;

typedef enum
{
    STATE_ACTION_PUSH,
    STATE_ACTION_POP,
    STATE_ACTION_EXIT_GAMEMODE,
    STATE_ACTION_REPLACE_TOP
} StateActionType;

typedef struct
{
    StateActionType mStateActionType;
    u32             mStateActionData;
    u32             mStateActionData2;
} StateAction;

typedef struct
{
    UserDataType mType;
    u32          mData[2];
} UserData;

static UserData sUserData;

#if NEON_SOLITAIRE_21
static const char*  mainMenuButtonTextureLogo						= { "bg_solitaire21_pause.papng" };
#else
static const char*  mainMenuButtonTextureLogo						= { "bg_run21.papng" };
#endif

// Kking - Translation verified.												
static const char*  sButtonNames[PAUSE_SUB_MENU_ACTION_NUM]		= {	"LS_Seating",	// PAUSE_SUB_MENU_ACTION_COMPANIONS
																	"LS_Options",	// PAUSE_SUB_MENU_ACTION_OPTIONS
																	"LS_Back",		// PAUSE_SUB_MENU_ACTION_MAIN
																	"LS_Resume",	// PAUSE_SUB_MENU_RESUME_GAME
																	"LS_No",		// PAUSE_SUB_MENU_ACTION_RETURN_TO_PAUSE
																	"LS_Yes",		// PAUSE_SUB_MENU_ACTION_EXIT_GAME
																	"LS_Retry",		// PAUSE_SUB_MENU_ACTION_RESTART_GAME
																	"LS_Leave",		// PAUSE_SUB_MENU_ACTION_LEAVE
																	"LS_MainMenu",	// PAUSE_SUB_MENU_ACTION_LEAVE_MAINMENU
																	"LS_SkipAhead",	// PAUSE_SUB_MENU_ACTION_LEAVE_SKIPAHEAD
																	"LS_Retry",		// PAUSE_SUB_MENU_ACTION_LEAVE_RETRY
                                                                    "LS_SFX",       // PAUSE_SUB_MENU_ACTION_TOGGLE_SOUND
                                                                    "LS_Music",     // PAUSE_SUB_MENU_ACTION_TOGGLE_MUSIC
																	};

static const int    sButtonFontColors[CARDSUIT_NumSuits]		= { 0x158dfaFF,
																	0xee2929FF,
																	0xe1df24FF,
																	0x33f08fFF};
                                                                            
static const int    sButtonFontBorderColors[CARDSUIT_NumSuits]  = { 0x0d52dfFF,
                                                                    0x7f1010FF,
                                                                    0xa9a616FF,
                                                                    0x20c55aFF};
																	
static Vector3		sMenuButtonPositions[CARDSUIT_NumSuits]		= { 
																	{ 328, 168, 0	},	// Spades	/ BR
																	{ 8, 8,	0	},	// Hearts	/ UL
																	{ 8, 168, 0	},	// Diamonds	/ BL
																	{ 328, 8,	0	}};	// Clubs	/ BR
																	
static Vector3		sLogoPosition										= {0, 0, 0};
																	

static const char*  mainMenuButtonTextureUnlitName[CARDSUIT_NumSuits]	= { "menu_br.papng",
                                                                            "menu_ul.papng",
                                                                            "menu_bl.papng",
                                                                            "menu_ur.papng"};

static const char*  mainMenuButtonTextureLitName[CARDSUIT_NumSuits]		= { "menu_br_glow.papng",
                                                                            "menu_ul_glow.papng",
                                                                            "menu_bl_glow.papng",
                                                                            "menu_ur_glow.papng"};
																			
static const char*  mainMenuButtonTextureOffName[CARDSUIT_NumSuits]		= { "menu_br_inactive.papng",
                                                                            "menu_ul_inactive.papng",
                                                                            "menu_bl_inactive.papng",
                                                                            "menu_ur_inactive.papng"};

@implementation PauseMenu

-(void)Startup
{
    mRefillLivesDelegate = [PauseMenuRefillLivesDelegate alloc];
    GameObjectBatchParams groupParams;
    
    [GameObjectBatch InitDefaultParams:&groupParams];
    
    groupParams.mUseAtlas = TRUE;
    
	mUIGroup = [(UIGroup*)[UIGroup alloc] InitWithParams:&groupParams];
    [[GameObjectManager GetInstance] Add:mUIGroup];
    [mUIGroup release];
        
    mNumButtons = 0;

    sUserData.mType = USERDATA_INVALID;
    memset(sUserData.mData, 0, sizeof(sUserData.mData));
    
    mActiveMenu = PAUSE_SUB_MENU_INVALID;
    
	[self ActivateMenu:PAUSE_SUB_MENU_MAIN]; 

#if defined(NEON_RUN_21)
    // Don't draw the game environment while in Pause mode.  But don't tear down the entire environment either.
    [[ModelManager GetInstance] SetDrawingMode:ModelManagerDrawingMode_ActiveGameState];

    FaderParams faderParams;
    [Fader InitDefaultParams:&faderParams];
    
    faderParams.mFadeType = FADE_FROM_BLACK;
    
    [[Fader GetInstance] StartWithParams:&faderParams];
#endif

}

-(void)Resume
{
}

-(void)Shutdown
{
    [[ModelManager GetInstance] SetDrawingMode:ModelManagerDrawingMode_All];
    
    [mRefillLivesDelegate release];
    
    [mUIGroup Remove];
}

-(void)Suspend
{
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
}

-(void)ActivateMenu:(PauseSubMenu)inSubMenu
{
    mNumButtons = 0;
	[self InitMenu:inSubMenu];
	
	switch (inSubMenu)
	{
		// Seperate per SKU
		case PAUSE_SUB_MENU_MAIN:
		{
			[self InitMenuToggle:PAUSE_SUB_MENU_RESUME_GAME				withSuit:CARDSUIT_Clubs		withOn:TRUE withEnabled:TRUE    ];
			[self InitMenuToggle:PAUSE_SUB_MENU_ACTION_LEAVE_MAINMENU	withSuit:CARDSUIT_Hearts	withOn:TRUE withEnabled:TRUE    ];
            [self InitMenuToggle:PAUSE_SUB_MENU_ACTION_LEAVE_RETRY		withSuit:CARDSUIT_Diamonds	withOn:TRUE withEnabled:TRUE    ];
            [self InitMenuToggle:PAUSE_SUB_MENU_ACTION_OPTIONS          withSuit:CARDSUIT_Spades	withOn:TRUE withEnabled:TRUE    ];

			break;
		}
        		
		case PAUSE_SUB_MENU_LEAVE:
		{			
			[self InitMenuToggle:PAUSE_SUB_MENU_ACTION_LEAVE_MAINMENU	withSuit:CARDSUIT_Spades	withOn:TRUE withEnabled:TRUE			];
			[self InitMenuToggle:PAUSE_SUB_MENU_ACTION_LEAVE_RETRY		withSuit:CARDSUIT_Diamonds	withOn:TRUE withEnabled:TRUE			];
			
			[ self InitBackButton:PAUSE_SUB_MENU_ACTION_MAIN ];
			break;
		}
            
        case PAUSE_SUB_MENU_OPTIONS:
        {
            
            BOOL currentSoundOn = [[SoundPlayer GetInstance] GetSoundEnabled];
            BOOL currentMusicOn = [[NeonMusicPlayer GetInstance] GetMusicEnabled];

            [self InitMenuToggle:PAUSE_SUB_MENU_ACTION_MAIN             withSuit:CARDSUIT_Clubs		withOn:TRUE             withEnabled:TRUE    ];
			[self InitMenuToggle:PAUSE_SUB_MENU_ACTION_TOGGLE_SOUND		withSuit:CARDSUIT_Spades	withOn:currentSoundOn   withEnabled:TRUE    ];
            [self InitMenuToggle:PAUSE_SUB_MENU_ACTION_TOGGLE_MUSIC		withSuit:CARDSUIT_Diamonds	withOn:currentMusicOn   withEnabled:TRUE    ];
            break;
        }
		
		case PAUSE_SUB_MENU_LEAVE_MAINMENU:
		{
			[ self InitMenuToggle:PAUSE_SUB_MENU_ACTION_EXIT_GAME			withSuit:CARDSUIT_Diamonds	withOn:TRUE		withEnabled:TRUE];
			[ self InitMenuToggle:PAUSE_SUB_MENU_ACTION_RETURN_TO_PAUSE		withSuit:CARDSUIT_Spades	withOn:TRUE		withEnabled:TRUE];
			
			[ self InitTextBox:@"LS_QuitGame" ];
			break;
		}
		
		case PAUSE_SUB_MENU_LEAVE_SKIPAHEAD:
		{
			[ self InitMenuToggle:PAUSE_SUB_MENU_ACTION_RETURN_TO_PAUSE		withSuit:CARDSUIT_Spades	withOn:TRUE		withEnabled:TRUE];
			
			[ self InitTextBox:@"LS_SkipAhead_Prompt" ];
			break;
		}
		
		case PAUSE_SUB_MENU_LEAVE_RETRY:
		{
			[ self InitMenuToggle:PAUSE_SUB_MENU_ACTION_RESTART_GAME		withSuit:CARDSUIT_Diamonds	withOn:TRUE		withEnabled:TRUE];
			[ self InitMenuToggle:PAUSE_SUB_MENU_ACTION_RETURN_TO_PAUSE		withSuit:CARDSUIT_Spades	withOn:TRUE		withEnabled:TRUE];
			
			[ self InitTextBox:@"LS_Retry_Prompt" ];
			break;
		}
    }
    
    [mUIGroup Finalize];
}

-(void)LeaveMenu
{
    int  numObjects = [mUIGroup count];
    
    for (int i = 0; i < numObjects; i++)
    {
        UIObject *nObject = [mUIGroup objectAtIndex:i];
        
        [nObject RemoveAfterOperations];
        [nObject Disable];
    }
}

-(void)InitMenu:(PauseSubMenu)inSubMenu
{
    [self LeaveMenu];
    
	mActiveMenu = inSubMenu;
}

// TODO: Unify the Main Menu and Pause Menus under one system.
-(void)InitMenuToggle:(PauseSubMenuAction)linkMenuID withSuit:(CardSuit)suitID withOn:(BOOL)bToggledOn withEnabled:(BOOL)bEnabled
{
	NeonButton*         curButton;
	NeonButtonParams    buttonParams;
	
	// Init the Logo FIRST, so it is in the BG
	if ( mNumButtons == 0 )
		[ self InitLogo ];
	
	// TODO: Probably should verify that there is no menu already with this suit.
	
	[NeonButton InitDefaultParams:&buttonParams];
    
    buttonParams.mTexName					= [NSString stringWithUTF8String:mainMenuButtonTextureOffName[suitID]];
    buttonParams.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:mainMenuButtonTextureLitName[suitID]];
	buttonParams.mToggleTexName				= [NSString stringWithUTF8String:mainMenuButtonTextureUnlitName[suitID]];
    buttonParams.mText						= NSLocalizedString([NSString stringWithUTF8String:sButtonNames[linkMenuID]], NULL);     
	buttonParams.mTextSize					= 18;
    buttonParams.mBorderSize				= 5;
    buttonParams.mQuality					= NEON_BUTTON_QUALITY_HIGH;
    buttonParams.mFadeSpeed					= BUTTON_FADE_SPEED;
    buttonParams.mUIGroup					= mUIGroup;
	buttonParams.mUISoundId					= SFX_MENU_BUTTON_PRESS;
    buttonParams.mBoundingBoxCollision		= TRUE;
    SetVec2(&buttonParams.mBoundingBoxBorderSize, 0, 4);
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
    
	[curButton SetVisible:FALSE];
	[curButton Enable];
	
	if ( bEnabled )
	{
		
		[curButton SetListener:self];
	}
	else
	{
		
		[curButton SetListener:NULL];
		[curButton SetPulseAmount:0.0f time:0.25f];
		[curButton SetActive:FALSE];
	}
	
	[curButton SetPosition:&sMenuButtonPositions[suitID] ];
	
	[curButton release];
    mNumButtons++;


}

-(void)InitTextBox:(NSString*)str
{
	TextBoxParams tbParams;
            
	[TextBox InitDefaultParams:&tbParams];

	SetColor(&tbParams.mColor, 0xFF, 0xFF, 0xFF, 0xFF);
	SetColor(&tbParams.mStrokeColor, 0x00, 0x00, 0x00, 0xFF);

	tbParams.mStrokeSize	= 10;
	tbParams.mString		= NSLocalizedString(str, NULL);
	tbParams.mFontSize		= 18;
	tbParams.mFontType		= NEON_FONT_STYLISH;
	tbParams.mWidth			= 320;	// Gutter the left and right border of screen
	tbParams.mUIGroup		= mUIGroup;

	TextBox* textBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
	[textBox SetVisible:FALSE];
	[textBox Enable];

	PlacementValue placementValue;
	SetRelativePlacement(&placementValue, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);

	[textBox SetPlacement:&placementValue];
	[textBox SetPositionX:240 Y:30 Z:0];

	[textBox release];
}

-(void)InitLogo
{
	ImageWell						*logoImage;
	
	ImageWellParams					imageWellparams;
	[ImageWell InitDefaultParams:	&imageWellparams];
	imageWellparams.mUIGroup		= mUIGroup;
	imageWellparams.mTextureName	= [ NSString stringWithUTF8String:mainMenuButtonTextureLogo ];
		
	logoImage	=	[(ImageWell*)[ImageWell alloc] InitWithParams:&imageWellparams];
	[logoImage		SetPosition:&sLogoPosition];
	[logoImage		SetVisible:TRUE];
	[logoImage		release];
}

-(void)InitBackButton:(PauseSubMenuAction)inBackButtonAction
{
    NeonButtonParams	button;
    [NeonButton InitDefaultParams:&button ];
	
	if ( mNumButtons == 0 )
		[ self InitLogo ];
    
	button.mTexName					= [NSString stringWithUTF8String:mainMenuButtonTextureUnlitName[CARDSUIT_Clubs]];
    button.mPregeneratedGlowTexName	= [NSString stringWithUTF8String:mainMenuButtonTextureLitName[CARDSUIT_Clubs]];
    button.mText					= NSLocalizedString(@"LS_Back", NULL);    
	button.mTextSize				= 18;
    button.mBorderSize				= 1;
    button.mQuality					= NEON_BUTTON_QUALITY_HIGH;
    button.mFadeSpeed				= BUTTON_FADE_SPEED;
	button.mUIGroup                 = mUIGroup;
    button.mBoundingBoxCollision    = TRUE;
	button.mUISoundId				= SFX_MENU_BACK;
	SetColorFromU32(&button.mBorderColor	, NEON_BLA);
    SetColorFromU32(&button.mTextColor		, NEON_WHI);
    SetRelativePlacement(&button.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
    SetVec2(&button.mBoundingBoxBorderSize, 2, 2);
        
    NeonButton* backButton = [ (NeonButton*)[NeonButton alloc] InitWithParams:&button ];
    backButton->mIdentifier = inBackButtonAction;
    [backButton SetVisible:FALSE];
    [backButton Enable];
    [backButton SetPositionX:Sbar_Y1 Y:Sbar_Y1 Z:0.0];
	[backButton SetPosition:&sMenuButtonPositions[CARDSUIT_Clubs] ];
    [backButton SetListener:self];
    [backButton release];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        switch (inButton->mIdentifier)
        {
			case PAUSE_SUB_MENU_ACTION_RESTART_GAME:
			{
                if([[SaveSystem GetInstance] GetNumLives] >= 1)
                {
                    sUserData.mType = USERDATA_TYPE_RESTART;
                    sUserData.mData[0] = 0;
                    sUserData.mData[1] = 0;
				}
                else
                {
                    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"LS_NextLife",NULL) , [[RegenerationManager GetInstance] GetHealthRegenTimeString]];
                    
                    UIAlertView* getMoreLives = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_OutOfLives", NULL)
                                                                           message: msg
                                                                          delegate: mRefillLivesDelegate
                                                                 cancelButtonTitle: NSLocalizedString(@"LS_Wait", NULL)
                                                                 otherButtonTitles: NSLocalizedString(@"LS_FillLives",NULL),
                                                                                    NSLocalizedString(@"LS_AskAFriend",NULL),  nil];
                    [getMoreLives show];
                    sUserData.mType		= USERDATA_TYPE_MENU;
                    sUserData.mData[0]	= PAUSE_SUB_MENU_MAIN;
                }
				break;
			}
            case PAUSE_SUB_MENU_RESUME_GAME:
            {
                sUserData.mType = USERDATA_TYPE_STATE_ACTION;
                
                StateAction* actions = malloc(sizeof(StateAction) * 1);
                
                actions[0].mStateActionType = STATE_ACTION_POP;
                actions[0].mStateActionData = 0;
                
                sUserData.mData[0] = (u32)actions;
                sUserData.mData[1] = 1;
                
                break;
            }
                        
            case PAUSE_SUB_MENU_ACTION_MAIN:
			case PAUSE_SUB_MENU_ACTION_RETURN_TO_PAUSE:
            {
				sUserData.mType		= USERDATA_TYPE_MENU;
                sUserData.mData[0]	= PAUSE_SUB_MENU_MAIN;
                break;
            }
			
			case PAUSE_SUB_MENU_ACTION_LEAVE:
			{
				sUserData.mType		= USERDATA_TYPE_MENU;
                sUserData.mData[0]	= PAUSE_SUB_MENU_LEAVE;
                break;
			}
			
			case PAUSE_SUB_MENU_ACTION_LEAVE_MAINMENU:
			{
				sUserData.mType		= USERDATA_TYPE_MENU;
                sUserData.mData[0]	= PAUSE_SUB_MENU_LEAVE_MAINMENU;
                break;
			}
			
			case PAUSE_SUB_MENU_ACTION_LEAVE_SKIPAHEAD:
			{
				sUserData.mType		= USERDATA_TYPE_MENU;
                sUserData.mData[0]	= PAUSE_SUB_MENU_LEAVE_SKIPAHEAD;
                break;
			}
			
			case PAUSE_SUB_MENU_ACTION_LEAVE_RETRY:
			{
				sUserData.mType		= USERDATA_TYPE_MENU;
                sUserData.mData[0]	= PAUSE_SUB_MENU_LEAVE_RETRY;
                break;
			}
			
            case PAUSE_SUB_MENU_ACTION_OPTIONS:
            {
				sUserData.mType		= USERDATA_TYPE_MENU;
                sUserData.mData[0]	= PAUSE_SUB_MENU_OPTIONS;
                break;
            }
                
			case PAUSE_SUB_MENU_ACTION_TOGGLE_SOUND:
            {
                [[SaveSystem GetInstance] SetSoundOn:[(NeonButton*)inButton GetToggleOn]];

                [[SoundPlayer GetInstance] SetSoundEnabled:[(NeonButton*)inButton GetToggleOn]];
                
                return;
                
            }
                
            case PAUSE_SUB_MENU_ACTION_TOGGLE_MUSIC:
            {
                [[SaveSystem GetInstance] SetMusicOn:[(NeonButton*)inButton GetToggleOn]];
                
                [[NeonMusicPlayer GetInstance] SetMusicEnabled:[(NeonButton*)inButton GetToggleOn]];
                
                return;
                
            }
			
            case PAUSE_SUB_MENU_ACTION_EXIT_GAME:
            {
                sUserData.mType = USERDATA_TYPE_STATE_ACTION;
                
                StateAction* actions = malloc(sizeof(StateAction) * 1);
                
                actions[0].mStateActionType = STATE_ACTION_EXIT_GAMEMODE;
                actions[0].mStateActionData = 0;
                
                sUserData.mData[0] = (u32)actions;
                sUserData.mData[1] = 1;
                
                break;
            }
            
            case PAUSE_SUB_MENU_ACTION_COMPANIONS:
            {
                sUserData.mType = USERDATA_TYPE_STATE_ACTION;
                
                StateAction* actions = malloc(sizeof(StateAction) * 1);
                
                actions[0].mStateActionType = STATE_ACTION_PUSH;
                actions[0].mStateActionData = (u32)[CompanionSelect alloc];
                actions[0].mStateActionData2 = 0;
                
                sUserData.mData[0] = (u32)actions;
                sUserData.mData[1] = 1;
                break;
            }
        }
        
        [self LeaveMenu];
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ([mUIGroup GroupCompleted] && (sUserData.mType != USERDATA_INVALID))
    {
        [mUIGroup removeAllObjects];

        UserDataType userDataType = sUserData.mType;
        
        sUserData.mType = USERDATA_INVALID;
        
        switch(userDataType)
        {
			case USERDATA_TYPE_RESTART:
			{
                [[Flow GetInstance] RestartLevel];
				break;
			}
            case USERDATA_TYPE_MENU:
            {
                [self ActivateMenu:(PauseSubMenu)sUserData.mData[0]];
                break;
            }

            case USERDATA_TYPE_STATE_ACTION:
            {
                int numActions = sUserData.mData[1];
                StateAction* stateActions = (StateAction*)sUserData.mData[0];
                
                for (int i = 0; i < numActions; i++)
                {
                    switch (stateActions[i].mStateActionType)
                    {
                        case STATE_ACTION_PUSH:
                        {
                            NSAssert(FALSE, @"Need to replace with new flow functions");
                            [[GameStateMgr GetInstance] Push:(GameState*)stateActions[i].mStateActionData
                                withParams:(NSObject*)stateActions[i].mStateActionData2];
                                
                            [(NSObject*)stateActions[i].mStateActionData2 release];
                                
                            break;
                        }
                        
                        case STATE_ACTION_POP:
                        {
                            [[GameStateMgr GetInstance] Pop];
                            break;
                        }
                        
                        case STATE_ACTION_EXIT_GAMEMODE:
                        {
                            [[Flow GetInstance] ExitGameMode];
                            break;
                        }
                        
                        case STATE_ACTION_REPLACE_TOP:
                        {
                            NSAssert(FALSE, @"Need to replace with new flow functions");
                            [[GameStateMgr GetInstance] ReplaceTop:(GameState*)stateActions[i].mStateActionData];
                            break;
                        }
                    }
                }
                
                NSAssert(stateActions != NULL, @"stateActions is NULL.  How is this possible?");
                free(stateActions);
                
                break;
            }
        }
    }
}

@end

@implementation PauseMenuRefillLivesDelegate

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