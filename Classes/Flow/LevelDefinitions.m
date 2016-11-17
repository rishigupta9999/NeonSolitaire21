//
//  LevelDefinitions.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "LevelDefinitions.h"
#import "TutorialScript.h"
#import "SplitTestingSystem.h"
#import "SaveSystem.h"

static const char* MUSIC_BG_MAINMENU				= "BG_MainMenu.mp3";
static const char* MUSIC_BG_ICHACHING				= "BG_IChaChing.m4a";
static const char* MUSIC_BG_FJORDKNOX				= "BG_FjordKnox.m4a";
static const char* MUSIC_BG_GUMMYSLOTS				= "BG_GummySlots.m4a";

#define NUM_SKYBOXES							(6)

static const char* SKYBOX_GUMMYSLOTS[NUM_SKYBOXES]	= {    "gummyslots_plus_x.pvrtc",	"gummyslots_minus_x.pvrtc", NULL, "gummyslots_minus_y.pvrtc",	"gummyslots_plus_z.pvrtc",	"gummyslots_minus_z.pvrtc"   };
static const char* SKYBOX_ICHACHING[NUM_SKYBOXES]	= {    "ichaching_plus_x.pvrtc",	"ichaching_minus_x.pvrtc",	NULL, "ichaching_minus_y.pvrtc",	"ichaching_plus_z.pvrtc",	"ichaching_minus_z.pvrtc"    };
static const char* SKYBOX_FJORDKNOX[NUM_SKYBOXES]	= {    "fjordknox_plus_x.pvrtc",	"fjordknox_minus_x.pvrtc",	NULL, "fjordknox_minus_y.pvrtc",	"fjordknox_plus_z.pvrtc",	"fjordknox_minus_z.pvrtc"    };

static const char* MINIGAME_UV_RUN21				= "Run21.pvrtc";

#if NEON_SOLITAIRE_21
static const char* LCD_RUN21_ACTIVE					= "Solitaire21_LCD_Active.pvrtc";
static const char* LCD_RUN21_INACTIVE               = "Solitaire21_LCD_Inactive.pvrtc";
#else
static const char* LCD_RUN21_ACTIVE					= "Run21_LCD_Active.pvrtc";
static const char* LCD_RUN21_INACTIVE				= "Run21_LCD_Inactive.pvrtc";
#endif

static const char* LCD_RUN21_BLANK					= "Run21_LCD_Blank.pvrtc"	;
static const char* LCD_RUN21_TABLET                 = "Run21_Tablet_Blank.pvrtc";

LevelInfo*  sLevelInfo[RUN21_LEVEL_NUM];

@implementation LevelInfo

@synthesize CasinoID = mCasinoID;
@synthesize DealerID = mDealerID;
@synthesize Clubs = mClubs;
@synthesize Spades = mSpades;
@synthesize Diamonds = mDiamonds;
@synthesize Hearts = mHearts;
@synthesize NumDecks = mNumDecks;
@synthesize NumCards = mNumCards;
@synthesize NumJokers = mNumJokers;
@synthesize PrioritizeHighCards = mPrioritizeHighCards;
@synthesize AddClubs = mAddClubs;
@synthesize JokersAvailable = mJokersAvailable;
@synthesize XrayAvailable = mXrayAvailable;
@synthesize TornadoAvailable = mTornadoAvailable;
@synthesize NumRunners = mNumRunners;
@synthesize XraysGranted = mXraysGranted;
@synthesize TornadoesGranted = mTornadoesGranted;
@synthesize TimeLimitSeconds = mTimeLimitSeconds;

-(LevelInfo*)init
{
    mCasinoID = CasinoID_GummySlots;
    mDealerID = CompID_Igunaq;
    
    mClubs = FALSE;
    mSpades = FALSE;
    mDiamonds = FALSE;
    mHearts = FALSE;
    
    mNumDecks = 1;
    mNumCards = 0;
    mNumJokers = 2;
    
    mPrioritizeHighCards = FALSE;
    
    mAddClubs = FALSE;
    mJokersAvailable = TRUE;
    mXrayAvailable = TRUE;
    mTornadoAvailable = TRUE;
    
    mNumRunners = 4;
    mXraysGranted = 0;
    mTornadoesGranted = 0;
    
    mTimeLimitSeconds = 0;
    
    return self;
}

@end


@implementation LevelDefinitions

-(LevelDefinitions*)Init
{
    mCasinoId = CasinoID_GummySlots;
    mTutorialScript = NULL;
    
    for (int level = 0; level < RUN21_LEVEL_NUM; level++)
    {
        LevelInfo* curLevel = [[LevelInfo alloc] init];
        sLevelInfo[level] = curLevel;
        
        switch(level)
        {
            case RUN21_LEVEL_1:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Igunaq;
                curLevel.NumCards = 9;
                curLevel.JokersAvailable = FALSE;
                curLevel.XrayAvailable = FALSE;
                curLevel.TornadoAvailable = FALSE;
                curLevel.NumRunners = 2;
                curLevel.NumJokers = 0;
                
                break;
            }
            
            case RUN21_LEVEL_2:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_Betty;
                curLevel.NumCards = 12;
                curLevel.JokersAvailable = FALSE;
                curLevel.XrayAvailable = FALSE;
                curLevel.TornadoAvailable = FALSE;
                curLevel.NumRunners = 2;
                curLevel.NumJokers = 0;
                break;
            }
            
            case RUN21_LEVEL_3:
            {
                curLevel.CasinoID = CasinoID_FjordKnox;
                curLevel.DealerID = CompID_NunaVut;
                curLevel.NumCards = 16;
                curLevel.XrayAvailable = FALSE;
                curLevel.TornadoAvailable = FALSE;
                curLevel.NumRunners = 2;
                curLevel.NumJokers = 1;
                break;
            }
            
            case RUN21_LEVEL_4:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Johnny;
                curLevel.NumCards = 28;
                curLevel.XrayAvailable = FALSE;
                curLevel.TornadoAvailable = FALSE;
                curLevel.NumRunners = 3;
                break;
            }
            
            case RUN21_LEVEL_5:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_Panda;
                curLevel.NumCards = 13;
                curLevel.TornadoAvailable = FALSE;
                curLevel.NumRunners = 3;
                curLevel.XraysGranted = 2;
                break;
            }
            
            case RUN21_LEVEL_6:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Cathy;
                curLevel.NumCards = 18;
                curLevel.PrioritizeHighCards = TRUE;
                curLevel.TornadoAvailable = FALSE;
                curLevel.NumRunners = 3;
                break;
            }
            
            case RUN21_LEVEL_7:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_Amber;
                curLevel.NumCards = 22;
                curLevel.PrioritizeHighCards = TRUE;
                curLevel.NumRunners = 3;
                curLevel.TornadoesGranted = 2;
                break;
            }
            
            case RUN21_LEVEL_8:
            {
                curLevel.CasinoID = CasinoID_FjordKnox;
                curLevel.DealerID = CompID_DonCappo;
                curLevel.NumCards = 30;
                curLevel.PrioritizeHighCards = TRUE;
                curLevel.NumJokers = 1;
                break;
            }
            
            case RUN21_LEVEL_9:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_DonCappo;
                curLevel.Spades = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                break;
            }
            
            case RUN21_LEVEL_10:
            {
                curLevel.CasinoID = CasinoID_FjordKnox;
                curLevel.DealerID = CompID_DonCappo;
                curLevel.Clubs = TRUE;
                curLevel.Spades = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                break;
            }
            
            case RUN21_LEVEL_11:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Igunaq;
                curLevel.Clubs = TRUE;
                curLevel.Spades = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.AddClubs = TRUE;
                break;
            }

            case RUN21_LEVEL_12:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_Betty;
                curLevel.Clubs = TRUE;
                curLevel.Spades = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.NumJokers = 0;
                curLevel.NumRunners = 5;
                break;
            }
            
            case RUN21_LEVEL_13:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_NunaVut;
                curLevel.Clubs = TRUE;
                curLevel.TimeLimitSeconds = 45;
                curLevel.XraysGranted = 1;
                curLevel.TornadoesGranted = 1;
                break;
            }
            
            case RUN21_LEVEL_14:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Johnny;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.TimeLimitSeconds = 55;
                break;
            }
            
            case RUN21_LEVEL_15:
            {
                curLevel.CasinoID = CasinoID_FjordKnox;
                curLevel.DealerID = CompID_Panda;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.TimeLimitSeconds = 75;
                curLevel.NumRunners = 4;
                break;
            }
            
            case RUN21_LEVEL_16:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Betty;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.Spades = TRUE;
                curLevel.TimeLimitSeconds = 90;
                curLevel.NumRunners = 4;
                break;
            }
            
            case RUN21_LEVEL_17:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_Amber;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.Spades = TRUE;
                curLevel.AddClubs = TRUE;
                curLevel.TimeLimitSeconds = 90;
                curLevel.NumRunners = 5;
                break;
            }
            
            case RUN21_LEVEL_18:
            {
                curLevel.CasinoID = CasinoID_IChaChing;
                curLevel.DealerID = CompID_Igunaq;
                curLevel.NumJokers = 1;
                curLevel.NumCards = 40;
                curLevel.TimeLimitSeconds = 70;
                curLevel.NumRunners = 3;
                break;
            }
            
            case RUN21_LEVEL_19:
            {
                curLevel.CasinoID = CasinoID_FjordKnox;
                curLevel.DealerID = CompID_Betty;
                curLevel.NumJokers = 1;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.Spades = TRUE;
                curLevel.AddClubs = TRUE;
                curLevel.TimeLimitSeconds = 85;
                curLevel.NumRunners = 4;
                break;
            }
            
            case RUN21_LEVEL_20:
            {
                curLevel.CasinoID = CasinoID_FjordKnox;
                curLevel.DealerID = CompID_NunaVut;
                curLevel.NumJokers = 1;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.TimeLimitSeconds = 40;
                curLevel.NumRunners = 5;
                break;
            }
            
            case RUN21_LEVEL_21:
            {
                curLevel.CasinoID = CasinoID_GummySlots;
                curLevel.DealerID = CompID_Johnny;
                curLevel.NumJokers = 0;
                curLevel.Clubs = TRUE;
                curLevel.Diamonds = TRUE;
                curLevel.Hearts = TRUE;
                curLevel.Spades = TRUE;
                curLevel.TimeLimitSeconds = 50;
                curLevel.NumRunners = 5;
                break;
            }
        }
    }
    
    return self;
}

-(void)dealloc
{
    for (int level = 0; level < RUN21_LEVEL_NUM; level++)
    {
        [sLevelInfo[level] release];
    }
    
    [mTutorialScript release];
    [super dealloc];
}

-(void)StartLevel
{
    GameModeType gameMode = [[Flow GetInstance] GetGameMode];
    int level = [[Flow GetInstance] GetLevel];
    int numXrays = [[SaveSystem GetInstance] GetNumXrays];
    int numTornadoes = [[SaveSystem GetInstance] GetNumTornadoes];
    
    int xRaysGranted = sLevelInfo[level].XraysGranted;
    
    if (xRaysGranted > 0)
    {
        if ([[SaveSystem GetInstance] GetMaxLevel] <= level)
        {
            if (numXrays < xRaysGranted)
            {
                numXrays = xRaysGranted;
            }
            else
            {
                numXrays++;
            }
        }
        else
        {
            numXrays++;
        }
        
        [[SaveSystem GetInstance] SetNumXrays:[NSNumber numberWithInt:numXrays]];
    }
    
    int tornadoesGranted = sLevelInfo[level].TornadoesGranted;
    
    if (tornadoesGranted > 0)
    {
        if ([[SaveSystem GetInstance] GetMaxLevel] <= level)
        {
            if (numTornadoes < tornadoesGranted)
            {
                numTornadoes = tornadoesGranted;
            }
        }
        
        [[SaveSystem GetInstance] SetNumTornadoes:[NSNumber numberWithInt:numTornadoes]];
    }
    
    if (mTutorialScript != NULL)
    {
        [mTutorialScript release];
        mTutorialScript = NULL;
    }
    
    switch(gameMode)
    {
        case GAMEMODE_TYPE_RUN21:
        {
            mCasinoId = sLevelInfo[level].CasinoID;
            
            switch(level)
            {
                case RUN21_LEVEL_1:
                {
                    mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];
                    
                    TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    
                    phase->mDialogueKey = @"Tut_NeonR21_1";
                    phase->mTriggerState = @"HandStateRun21_TableSetup";
                    [phase SetCameraPositionX:-5.6 y:7.08 z:24.35];
                    [phase SetCameraLookAtX:5.6 y:3.8 z:-2.0];
                    [phase SetCameraFov:14.0];
                    [phase SetDialogueOffsetX:0.0f y:200.0f];
                    [phase SetDialogueFontSize:22.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_STYLISH]];
                    [phase SetDialogueFontColorR:0.47f g:1.0 b:0.2 a:1.0];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"Tut_NeonR21_2";
                    [phase SetCameraLookAtX:5.8 y:0.4 z:-2.0];
                    [phase SetCameraFov:19.0f];
                    [phase SetDialogueFontSize:22.0f];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetDialogueAlignment:kCTTextAlignmentCenter];
                    [phase SetSpinnerPositionX:220 positionY:105 sizeX:160 sizeY:85];
                    [phase SetTallSpinnerPositionX:220 positionY:100 sizeX:160 sizeY:90];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"Tut_NeonR21_4";
                    [phase SetCameraPositionX:-0.4 y:6.5 z:9.4];
                    [phase SetCameraLookAtX:-0.4 y:2.0 z:0.0];
                    [phase SetCameraFov:77.0];
                    [phase SetDialogueFontSize:17.0f];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:57 positionY:118 sizeX:250 sizeY:51];
                    [phase SetSpinnerPositionX:27 positionY:203 sizeX:290 sizeY:65];
                    [phase SetTallSpinnerPositionX:57 positionY:113 sizeX:250 sizeY:60];
                    [phase SetTallSpinnerPositionX:28 positionY:215 sizeX:292 sizeY:76];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"Tut_NeonR21_5";
                    [phase SetDialogueFontSize:17.0f];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:67 positionY:118 sizeX:225 sizeY:55];
                    [phase SetSpinnerPositionX:42 positionY:198 sizeX:255 sizeY:60];
                    [phase SetTallSpinnerPositionX:72 positionY:115 sizeX:220 sizeY:50];
                    [phase SetTallSpinnerPositionX:48 positionY:200 sizeX:250 sizeY:70];
                    phase.AnyButton = TRUE;
                    [phase RestoreCamera];
                    phase->mTriggerState = @"HandStateRun21_CPU_Mode_Switch_RunRainbow";
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"Tut_NeonR21_7";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    phase->mButtonIdentifier = @"Confirm";
                    [phase SetDialogueFontSize:16.0f];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:370 positionY:202 sizeX:95 sizeY:95];
                    [phase SetTallSpinnerPositionX:365 positionY:205 sizeX:90 sizeY:100];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    [mTutorialScript AddCardLabel:CardLabel_Jack    suit:CARDSUIT_Spades];
                    [mTutorialScript AddCardLabel:CardLabel_Two     suit:CARDSUIT_Hearts];
                    [mTutorialScript AddCardLabel:CardLabel_Nine    suit:CARDSUIT_Clubs];
                    [mTutorialScript AddCardLabel:CardLabel_Two     suit:CARDSUIT_Spades];
                    [mTutorialScript AddCardLabel:CardLabel_Ace     suit:CARDSUIT_Hearts];
                    
                    mTutorialScript.Indeterminate = TRUE;
                    mTutorialScript.EnableUI = TRUE;

                    break;
                }
                    
                case RUN21_LEVEL_2:
                {
                    mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];

                    [mTutorialScript AddCardLabel:CardLabel_Ace    suit:CARDSUIT_Spades];
                    [mTutorialScript AddCardLabel:CardLabel_Two    suit:CARDSUIT_Diamonds];

                    break;
                }
                
                case RUN21_LEVEL_3:
                {
                    mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];

                    [mTutorialScript AddCardLabel:CardLabel_Joker  suit:CARDSUIT_Hearts];
                    [mTutorialScript AddCardLabel:CardLabel_Two    suit:CARDSUIT_Spades];
                    [mTutorialScript AddCardLabel:CardLabel_Five   suit:CARDSUIT_Diamonds];
                    
                    TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L3_NeonR21_1";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    phase->mTriggerCount = 3;
                    [phase SetDialogueFontSize:22.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:370 positionY:202 sizeX:95 sizeY:95];
                    [phase SetTallSpinnerPositionX:365 positionY:205 sizeX:90 sizeY:100];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L3_NeonR21_2";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    [phase SetDialogueFontSize:20.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    phase.AnyButton = TRUE;
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L3_NeonR21_3";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    [phase SetDialogueFontSize:18.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    phase.AnyButton = TRUE;
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L3_NeonR21_4";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    [phase SetDialogueFontSize:18.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:292 positionY:103 sizeX:60 sizeY:45];
                    [phase SetTallSpinnerPositionX:290 positionY:103 sizeX:60 sizeY:45];
                    [mTutorialScript AddPhase:phase];
                    [phase release];

                    mTutorialScript.Indeterminate = TRUE;
                    mTutorialScript.EnableUI = TRUE;
                    
                    break;
                }
                
                case RUN21_LEVEL_5:
                {
                    mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];
                    
                    TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L6_NeonR21_1";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    phase->mTriggerCount = 4;
                    [phase SetDialogueFontSize:16.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:390 positionY:155 sizeX:45 sizeY:45];
                    [phase SetTallSpinnerPositionX:385 positionY:155 sizeX:45 sizeY:45];
                    [mTutorialScript AddPhase:phase];
                    [phase release];

                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L6_NeonR21_2";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    [phase SetDialogueFontSize:15.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L6_NeonR21_3";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    [phase SetDialogueFontSize:15.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetSpinnerPositionX:295 positionY:152 sizeX:55 sizeY:45];
                    [phase SetTallSpinnerPositionX:295 positionY:152 sizeX:55 sizeY:45];
                    [mTutorialScript AddPhase:phase];
                    [phase release];

                    mTutorialScript.Indeterminate = TRUE;
                    mTutorialScript.EnableUI = TRUE;

                    break;
                }
                
                case RUN21_LEVEL_7:
                {
                    mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];
                    
                    TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L7_NeonR21_1";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    phase->mTriggerCount = 4;
                    [phase SetDialogueFontSize:16.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [mTutorialScript AddPhase:phase];
                    [phase release];

                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L7_NeonR21_2";
                    phase->mTriggerState = @"HandStateRun21_Decision";
                    [phase SetDialogueFontSize:15.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetTallSpinnerPositionX:302 positionY:190 sizeX:55 sizeY:105];
                    [phase SetSpinnerPositionX:302 positionY:190 sizeX:60 sizeY:95];
                    [mTutorialScript AddPhase:phase];
                    [phase release];

                    mTutorialScript.Indeterminate = TRUE;
                    mTutorialScript.EnableUI = TRUE;
                    break;
                }
                
                case RUN21_LEVEL_9:
                {
                    // Only show this the first time through since this is a basically a more complex hint with a custom camera
                    //if ([[SaveSystem GetInstance] GetMaxLevel] < RUN21_LEVEL_9)
                    {
                        mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];
                        
                        TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                        phase->mDialogueKey = @"L8_NeonR21_1";
                        phase->mTriggerState = @"HandStateRun21_TableSetup";
                        [phase SetCameraPositionX:2.00 y:3.68 z:6.15];
                        [phase SetCameraLookAtX:5.8 y:4.8 z:-2.0];
                        [phase SetCameraFov:45.0];
                        [phase SetDialogueOffsetX:0.0f y:200.0f];
                        [phase SetDialogueFontSize:22.0f];
                        [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                        [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                        [mTutorialScript AddPhase:phase];
                        [phase release];
                        
                        phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                        phase->mDialogueKey = @"L8_NeonR21_2";
                        [phase SetCameraPositionX:0.0 y:4.28 z:3.954];
                        [phase SetCameraLookAtX:0.0 y:3.6 z:-2.0];
                        [phase SetCameraFov:79.0];
                        [phase SetDialogueOffsetX:0.0f y:200.0f];
                        [phase SetDialogueFontSize:22.0f];
                        [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                        [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                        [phase SetTallSpinnerPositionX:120 positionY:64 sizeX:240 sizeY:50];
                        [phase SetSpinnerPositionX:120 positionY:77 sizeX:240 sizeY:45];
                        [mTutorialScript AddPhase:phase];

                        phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                        phase->mDialogueKey = @"L8_NeonR21_3";
                        [phase SetDialogueOffsetX:0.0f y:200.0f];
                        [phase SetDialogueFontSize:20.0f];
                        [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                        [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                        [mTutorialScript AddPhase:phase];
                        [phase RestoreCamera];
                        [phase release];
                        
                        mTutorialScript.Indeterminate = TRUE;
                        mTutorialScript.EnableUI = TRUE;
                    }
                    
                    break;
                }
                
                case RUN21_LEVEL_13:
                {
                    mTutorialScript = [(TutorialScript*)[TutorialScript alloc] InitDynamic];
                    
                    TutorialPhaseInfo* phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L13_NeonR21_1";
                    phase->mTriggerState = @"HandStateRun21_TableSetup";
                    [phase SetCameraPositionX:2.00 y:3.68 z:6.15];
                    [phase SetCameraLookAtX:5.8 y:4.8 z:-2.0];
                    [phase SetCameraFov:45.0];
                    [phase SetDialogueOffsetX:0.0f y:200.0f];
                    [phase SetDialogueFontSize:22.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [mTutorialScript AddPhase:phase];
                    [phase release];
                    
                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L13_NeonR21_2";
                    [phase SetCameraPositionX:0.0 y:4.28 z:3.954];
                    [phase SetCameraLookAtX:0.0 y:3.6 z:-2.0];
                    [phase SetCameraFov:79.0];
                    [phase SetDialogueOffsetX:0.0f y:200.0f];
                    [phase SetDialogueFontSize:20.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [phase SetTallSpinnerPositionX:160 positionY:114 sizeX:160 sizeY:40];
                    [phase SetSpinnerPositionX:163 positionY:120 sizeX:160 sizeY:35];
                    [mTutorialScript AddPhase:phase];

                    phase = [(TutorialPhaseInfo*)[TutorialPhaseInfo alloc] Init];
                    phase->mDialogueKey = @"L13_NeonR21_3";
                    [phase SetDialogueOffsetX:0.0f y:180.0f];
                    [phase SetDialogueFontSize:20.0f];
                    [phase SetDialogueFontName:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
                    [phase SetDialogueFontColorR:1.0 g:0.91 b:0.27 a:1.0];
                    [mTutorialScript AddPhase:phase];
                    [phase RestoreCamera];
                    [phase release];

                    mTutorialScript.Indeterminate = TRUE;
                    mTutorialScript.EnableUI = TRUE;

                    break;
                }
                                
                default:
                {
                    [mTutorialScript release];
                    mTutorialScript = NULL;
                    break;
                }
            }
            
            break;
        }
        
        case GAMEMODE_TYPE_RUN21_MARATHON:
        {
            int numCasinos = CasinoID_Family1_Last - CasinoID_Family1_Start + 1;
            mCasinoId = arc4random_uniform(numCasinos) + CasinoID_Family1_Start;
            break;
        }
    }
}

-(NSString*)GetBGMusicFilename
{
    GameModeType    gameMode    = [[Flow GetInstance] GetGameMode];
    
	if (gameMode == GAMEMODE_TYPE_RUN21 || gameMode == GAMEMODE_TYPE_RUN21_MARATHON)
	{
        switch (mCasinoId)
        {
            case CasinoID_IChaChing:
                return [NSString stringWithUTF8String:MUSIC_BG_ICHACHING];
                
            case CasinoID_FjordKnox:
                return [NSString stringWithUTF8String:MUSIC_BG_FJORDKNOX];
                
            case CasinoID_GummySlots:
                return [NSString stringWithUTF8String:MUSIC_BG_GUMMYSLOTS];
                
            default:
                NSAssert(FALSE, @"Unknown BMG, invalid casino name");
                break;
        }
    }
    else if (gameMode == GAMEMODE_TYPE_MENU)
    {
        return [NSString stringWithUTF8String:MUSIC_BG_MAINMENU];
    }
    
	return NULL;
}

-(char**)GetSkyboxFilenames
{
    switch (mCasinoId)
    {
        case CasinoID_IChaChing:
            return (char**)SKYBOX_ICHACHING;
            
        case CasinoID_FjordKnox:
            return (char**)SKYBOX_FJORDKNOX;
            
        case CasinoID_GummySlots:
            return (char**)SKYBOX_GUMMYSLOTS;
            
        default:
            NSAssert(FALSE, @"Invalid Skybox, Unknown Casino ID");
            break;
    }
	
	// No Skybox is needed since we're not inside a casino.
	return NULL;
}

-(CompanionID)GetDealerId
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    if (sLevelInfo[levelIndex].DealerID == CompID_MAX)
    {
        CompanionID compID = CompID_Empty;
    
        while (compID == CompID_Empty || compID == CompID_Polly)
        {
            compID = arc4random_uniform(CompID_MAX);
        }
        
        return compID;
    }
    
    return sLevelInfo[levelIndex].DealerID;
}

-(TutorialScript*)GetTutorialScript
{
    return mTutorialScript;
}

-(NSString*)GetLevelDescription:(int)inLevel
{
    switch(inLevel)
    {
        default:
        {
            return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"LS_Level", NULL), (inLevel + 1)];
            break;
        }
    }
}

-(BOOL)GetHearts
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].Hearts;
}

-(BOOL)GetSpades
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].Spades;
}

-(BOOL)GetClubs
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].Clubs;
}

-(BOOL)GetDiamonds
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].Diamonds;
}

-(BOOL)GetAddClubs
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].AddClubs;
}

-(int)GetNumDecks
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].NumDecks;
}

-(int)GetNumCards
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].NumCards;
}

-(int)GetNumJokers
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].NumJokers;
}

-(BOOL)GetJokersAvailable
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].JokersAvailable;
}

-(BOOL)GetXrayAvailable
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].XrayAvailable;
}

-(BOOL)GetTornadoAvailable
{
    int levelIndex = [[Flow GetInstance] GetLevel];
    
    return sLevelInfo[levelIndex].TornadoAvailable;
}

-(LevelInfo*)GetLevelInfo:(int)inLevel
{
    return sLevelInfo[inLevel];
}

-(NSString*)GetMinitableTextureFilename
{
    return [NSString stringWithUTF8String:MINIGAME_UV_RUN21];
}


-(NSString*)GetScoreboardActiveTextureFilename
{
    return [NSString stringWithUTF8String:LCD_RUN21_ACTIVE];
}

-(NSString*)GetScoreboardInactiveTextureFilename
{
    return [NSString stringWithUTF8String:LCD_RUN21_INACTIVE];
}

-(NSString*)GetScoreboardBlankTextureFilename
{
    return [NSString stringWithUTF8String:LCD_RUN21_BLANK];
}

-(NSString*)GetTabletTextureFilename
{
    return [NSString stringWithUTF8String:LCD_RUN21_TABLET];
}

+(NSString*)GetCardTextureForLevel:(int)inLevel
{
	return [NSString stringWithFormat:@"r21_level_%d_available.papng", (inLevel + 1)];
}

-(CasinoID)GetCasinoId:(int)inLevelIndex
{
    NSAssert((inLevelIndex >= 0) && (inLevelIndex < RUN21_LEVEL_NUM), @"Invalid level index");
    
    return sLevelInfo[inLevelIndex].CasinoID;
}

-(LevelSelectRoom)GetRoomForLevel:(int)inLevel
{
    switch(inLevel)
    {
        case RUN21_LEVEL_1:
        case RUN21_LEVEL_2:
        case RUN21_LEVEL_3:
            return LEVELSELECT_ROOM_BRONZE;
            break;
        
        case RUN21_LEVEL_4:
        case RUN21_LEVEL_5:
        case RUN21_LEVEL_6:
            return LEVELSELECT_ROOM_SILVER;
            break;
            
        case RUN21_LEVEL_7:
        case RUN21_LEVEL_8:
        case RUN21_LEVEL_9:
            return LEVELSELECT_ROOM_GOLD;
            break;
            
        case RUN21_LEVEL_10:
        case RUN21_LEVEL_11:
        case RUN21_LEVEL_12:
            return LEVELSELECT_ROOM_EMERALD;
            break;
            
        case RUN21_LEVEL_13:
        case RUN21_LEVEL_14:
        case RUN21_LEVEL_15:
            return LEVELSELECT_ROOM_SAPPHIRE;
            break;
        
        case RUN21_LEVEL_16:
        case RUN21_LEVEL_17:
        case RUN21_LEVEL_18:
            return LEVELSELECT_ROOM_RUBY;
        
        default:
            return LEVELSELECT_ROOM_DIAMOND;
            break;
    }
    
    return LEVELSELECT_ROOM_DIAMOND;
}

-(int)GetNumRunners
{
    NSAssert(([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21) || ([[Flow GetInstance] GetGameMode] == GAMEMODE_TYPE_RUN21_MARATHON), @"Invalid game mode for getting number of runners");
    int levelIndex = [[Flow GetInstance] GetLevel];

    return sLevelInfo[levelIndex].NumRunners;
}

-(int)GetNumRunnersForGameMode:(GameModeType)inGameModeType level:(int)inLevel
{
    NSAssert((inGameModeType == GAMEMODE_TYPE_RUN21) || (inGameModeType == GAMEMODE_TYPE_RUN21_MARATHON), @"Invalid game mode for getting number of runners");
    
    return sLevelInfo[inLevel].NumRunners;
}

-(int)GetTimeLimitSeconds
{
    int levelIndex = [[Flow GetInstance] GetLevel];

    return sLevelInfo[levelIndex].TimeLimitSeconds;
}

-(BOOL)GetMainMenuUnlocked
{
#if NEON_SOLITAIRE_21
    int xrayLevel = [self GetXrayUnlockLevel];
    
    if ([[SaveSystem GetInstance] GetMaxLevel] > xrayLevel)
    {
        return TRUE;
    }
    
    return FALSE;
#else
    return TRUE;
#endif
}

-(int)GetMainMenuUnlockLevel
{
    return [self GetXrayUnlockLevel];
}

-(BOOL)GetJokerUnlocked
{
    return ([[SaveSystem GetInstance] GetMaxLevelStarted] >= [self GetJokerUnlockLevel]);
}

-(int)GetJokerUnlockLevel
{
    int jokerLevel = 0;
    
    for (int i = 0; i < RUN21_LEVEL_NUM; i++)
    {
        if (sLevelInfo[i].JokersAvailable)
        {
            jokerLevel = i;
            break;
        }
    }

    return jokerLevel;
}

-(BOOL)GetXrayUnlocked
{
    return ([[SaveSystem GetInstance] GetMaxLevelStarted] >= [self GetXrayUnlockLevel]);
}

-(int)GetXrayUnlockLevel
{
    int xrayLevel = 0;
    
    for (int i = 0; i < RUN21_LEVEL_NUM; i++)
    {
        if (sLevelInfo[i].XrayAvailable)
        {
            xrayLevel = i;
            break;
        }
    }

    return xrayLevel;
}

-(BOOL)GetTornadoUnlocked
{
    return ([[SaveSystem GetInstance] GetMaxLevelStarted] >= [self GetTornadoUnlockLevel]);
}

-(int)GetTornadoUnlockLevel
{
    int tornadoLevel = 0;
    
    for (int i = 0; i < RUN21_LEVEL_NUM; i++)
    {
        if (sLevelInfo[i].TornadoAvailable)
        {
            tornadoLevel = i;
            break;
        }
    }

    return tornadoLevel;
}

-(BOOL)GetRoomsUnlocked
{
    int maxLevel = [[SaveSystem GetInstance] GetMaxLevel];
    int firstLockedLevel = (LEVELSELECT_ROOM_SILVER + 1) * NUM_LEVELS_IN_ROOM;
    
    return (maxLevel >= firstLockedLevel);
}

-(int)GetRoomsUnlockLevel
{
    return ((LEVELSELECT_ROOM_SILVER + 1) * NUM_LEVELS_IN_ROOM) - 1;
}

-(BOOL)GetTimedLevelsUnlocked
{
    return ([[SaveSystem GetInstance] GetMaxLevelStarted] >= [self GetTimedUnlockLevel]);
}

-(int)GetTimedUnlockLevel
{
    int timedLevel = 0;
    
    for (int i = 0; i < RUN21_LEVEL_NUM; i++)
    {
        if (sLevelInfo[i].TimeLimitSeconds > 0)
        {
            timedLevel = i;
            break;
        }
    }

    return timedLevel;
}

@end