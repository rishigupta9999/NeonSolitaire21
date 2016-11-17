//
//  SKUFlowTypes_NeonEscape.h
//
//  Copyright Neon Games 2011
//

#ifndef SUPPRESS_FLOW_ERROR
    #error "Do not directly #include this file.  Use MenuFlowTypes.h instead."
#endif

#define NEON_APP_ID 792212290

typedef enum
{
	// Game Global [ 0 - 1 ]
    NeonEngine_Facebook_Login,
	NeonEngine_MainMenu,
    
	// End of Defines [ 29 ]
	NeonEngine_MAX,
	
	
} ENeonGameState;


typedef enum
{
	NeonMenu_NONE,
	NeonMenu_Appstart,
	NeonMenu_NeonLogo,
	NeonMenu_PressStart,
	NeonMenu_Main_NewGame_OverwriteYes,	// Unused for now, eventually support wiping of data
	NeonMenu_Main_NewGame_OverwriteNo,	// Unused for now, eventually support wiping of data
        NeonMenu_Main,
            Run21_Main_LevelSelect,
            Rainbow_Main_LevelSelect,
            Run21_Main_Marathon,
                Run21_Main_Marathon_Play,
                Run21_Marathon_Leaderboard,
                Run21_Marathon_Achievements,
            NeonMenu_Main_Options,
                NeonMenu_Main_Options_ClearData,
                    NeonMenu_Main_Options_ClearData_Yes,
                    NeonMenu_Main_Options_ClearData_No,
                NeonMenu_Main_Options_Sound,
                NeonMenu_Main_Options_Music,
            NeonMenu_Main_Extras,
                NeonMenu_Main_Extras_Website,
                NeonMenu_Main_Extras_IAP_Store,
                NeonMenu_Main_Extras_IAP_Lives,
                NeonMenu_Main_Extras_Contact_Us,
                NeonMenu_Main_Extras_Facebook,
                NeonMenu_Main_Extras_GameCenter,
                NeonMenu_Main_Extras_RateAppOrOtherGames,	// If the App has been rated, this button changes to "Other Games"
            NeonMenu_Unlock_Next_Room,
	NeonMenu_MAX,
} ENeonMenu;

