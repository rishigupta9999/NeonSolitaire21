//
//  SKUFlowTypes_Generic.h
//
//  Copyright Neon Games 2011
//

#ifndef SUPPRESS_FLOW_ERROR
    #error "Do not directly #include this file.  Use MenuFlowTypes.h instead."
#endif

#error "Neon 21 or Generic is an undefined SKU.  Check your build target."

#define NEON_APP_ID 500000000    

typedef enum
{
	// Game Global [0 - 3]
	NeonGlobalState_Init,
	N21GameState_UI_CompanyLogo,
	N21GameState_UI_MainMenu,
	NGS_Bankrupt,
	
	// Chapter 0 [4 - 8]
	NeonGlobalState_GameStart,
	NGS_CasinoIntro_GummySlots,
	NGS_N21Tutorial_Objective,
	NGS_N21Tutorial_BJCharlie,
	NGS_N21Tutorial_HitStand,
	
	// Chapter 1 [9 - 13]
	NGS_Companion_Intro_Cathy,
	NeonGlobalState_Neon21_CopperStakes,
	NGS_Companion_Outro_Cathy,
	NGS_CompTutorial_WinOnTies,
	NGS_N21Intro_DoubleDown,
	
	// Chapter 2 [13 - 17]
	NGS_Companion_Intro_Betty,
	NeonGlobalState_Neon21_BronzeStakes,
	NGS_Companion_Outro_Betty,
	NGS_CompTutorial_BlackjackPays2X,
	NGS_N21Intro_Split, 
	
	// Chapter 3 [18 - 22]
	NGS_Companion_Intro_Amber,
	NeonGlobalState_Neon21_SilverStakes,
	NGS_Companion_Outro_Amber,
	NGS_CompTutorial_DDAny,
	NGS_N21Intro_PartyManagement,
	
	// Chapter 4 [23 - 26]
	NGS_Companion_Intro_Johnny,
	NeonGlobalState_Neon21_GoldStakes,
	NGS_Companion_Outro_Johnny,
	NGS_CompTutorial_SwapHand,
	
	// Chapter 5 [27 -  30]
	NGS_Companion_Intro_Panda,
	NeonGlobalState_Neon21_DiamondStakes,
	NGS_Companion_Outro_Panda,
	NGS_CompTutorial_Surrender,
	
	// Chapter 6 [31 - 32]
	NGS_GameOutro,
	NGS_TrailerNeonEscape,

	// End of Defines
	NeonGlobalState_MAX,
	
} ENeonGameState;

typedef enum
{
	NeonMenu_NONE,
	NeonMenu_AppStart,
	NeonMenu_NeonLogo,
	NeonMenu_PressStart,
	NeonMenu_Main,
	NeonMenu_Main_NewGame,
    NeonMenu_Main_NewGame_OverwriteNo,
    NeonMenu_Main_NewGame_OverwriteYes,
    NeonMenu_Main_Continue,
    NeonMenu_Main_Options,
    NeonMenu_Main_Options_Sound,
    NeonMenu_Main_Options_Music,
    NeonMenu_HowToPlay,
    NeonMenu_HowToPlay_Basics,
    NeonMenu_HowToPlay_Basics_Story,
    NeonMenu_HowToPlay_Basics_Objective,
    NeonMenu_HowToPlay_Companions,
    NeonMenu_HowToPlay_Companions_HowWork,
    NeonMenu_HowToPlay_Companions_WhoAreThey,
    NeonMenu_HowToPlay_Companions_HowGetMore,
    NeonMenu_HowToPlay_GameRules,
    NeonMenu_HowToPlay_GameRules_Neon21,
    NeonMenu_HowToPlay_GameRules_TripleSwitch,
    NeonMenu_HowToPlay_GameRules_Run21,
    NeonMenu_HowToPlay_GameRules_21Squared,
    NeonMenu_Overworld,
    NeonMenu_Overworld_Gracys,
    NeonMenu_Overworld_IChaChing,
    NeonMenu_Overworld_FjordKnox,
    NeonMenu_Overworld_GummySlots,
    NeonMenu_Overworld_CharacterCloseup,
    NeonMenu_Pop,
	NeonMenu_MAX,
} ENeonMenu;
