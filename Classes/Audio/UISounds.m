//
//  UISounds.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "UISounds.h"
#import "SoundPlayer.h"

// SFX File Names
UISound sUISounds[SFX_NUM] = { 
	// Companion UI Sounds
		{"n21comp_amberdd.wav"},				// SFX_COMPANION_AMBER_DD,
		{"n21comp_capposplit.wav"},				// SFX_COMPANION_CAPPO_SPLIT,
		{"n21comp_igunaqredo.wav"},				// SFX_COMPANION_IGUNAQ_REDO,
		{"n21comp_johnnyswap.wav"},				// SFX_COMPANION_JOHNNY_SWAP,
		{"n21comp_pandasurrender.wav"},			// SFX_COMPANION_PANDA_SURRENDER,
		{"n21comp_vuthit.wav"},					// SFX_COMPANION_VUT_HIT,
	
	// Blackjack Game UI Sounds
		{"n21ui_betminus.wav"},					// SFX_BLACKJACK_BET_MINUS,
		{"n21ui_betplus.wav"},					// SFX_BLACKJACK_BET_PLUS,
		{"n21ui_betmodify.wav"},				// SFX_BLACKJACK_BET_PLUS,
		{"n21ui_dd.wav"},						// SFX_BLACKJACK_DOUBLEDOWN,
		{"n21ui_deal.wav"},						// SFX_BLACKJACK_DEAL,
		{"n21ui_hit.wav"},						// SFX_BLACKJACK_HIT,
		{"n21ui_split.wav"},					// SFX_BLACKJACK_SPLIT,
		{"n21ui_stay.wav"},						// SFX_BLACKJACK_STAND,
	
	// Run-21 Game UI Sounds
		{"Run21UI_CardPlace_Green.wav"},		// SFX_RUN21_PLACECARD_GREEN,
		{"Run21UI_CardPlace_Yellow.wav"},		// SFX_RUN21_PLACECARD_YELLOW,
		{"Run21UI_CardPlace_Red.wav"},			// SFX_RUN21_PLACECARD_RED,
	
	// 21-Squared Game UI Sounds
		{"21SqUI_CardPlace.wav"},				// SFX_21SQUARED_PLACECARD,
		
	// Global UI Game Sounds
		{"GlobalUI_CardConfirm.wav"},			// SFX_GLOBALUI_CARDCONFIRM,
	
	// In-Game Table/Card/Deck Sounds
		{"n21game_bust.wav"},					// SFX_DECK_BUST,
		{"n21game_carddealt.wav"},				// SFX_DECK_CARD_DEALT,
		{"n21game_cardflipped.wav"},			// SFX_DECK_CARD_FLIPPED,
	
	// Menu UI Sounds
		{"n21menu_back.wav"},					// SFX_MENU_BACK,
		{"n21menu_buttonpress.wav"},			// SFX_MENU_BUTTON_PRESS,
		{"n21menu_slideframe.wav"},				// SFX_MENU_SLIDE_FRAME
	
	// Outcome UI Sounds
		{"n21outcome_loss.wav"},				// SFX_OUTCOME_LOSS,
		{"n21outcome_push.wav"},				// SFX_OUTCOME_PUSH,
		{"n21outcome_surrender.wav"},			// SFX_OUTCOME_SURRENDER,
		{"n21outcome_win.wav"},					// SFX_OUTCOME_WIN_NORMAL,
		{"n21outcome_winDD.wav"},				// SFX_OUTCOME_WIN_DD,
		{"n21outcome_winSpecial.wav"},			// SFX_OUTCOME_WIN_SPECIAL
	
	// Stingers
		// 21 Squared
			{"n21sting_21squaredcol.wav"},		// SFX_STINGER_21SQUARED_COMPLETED_COLUMN,
			{"n21sting_21squaredrow.wav"},		// SFX_STINGER_21SQUARED_COMPLETED_ROW,
			{"n21sting_21squaredloss.wav"},		// SFX_STINGER_21SQUARED_LOSS,
			{"n21sting_21squaredwin.wav"},		// SFX_STINGER_21SQUARED_WIN,
		// Neon Blackjack
			{"n21sting_bankrupt.wav"},			// SFX_STINGER_BLACKJACK_BANKRUPT,
			{"n21sting_bigwin.wav"},			// SFX_STINGER_BLACKJACK_BIGWIN,
			{"n21sting_bj.wav"},				// SFX_STINGER_BLACKJACK_BJ,
			{"n21sting_brokethebank.wav"},		// SFX_STINGER_BLACKJACK_BROKETHEBANK,
			{"n21sting_charlie.wav"},			// SFX_STINGER_BLACKJACK_CHARLIE,
			{"n21sting_lose.wav"},				// SFX_STINGER_BLACKJACK_LOSE,
			{"n21sting_push.wav"},				// SFX_STINGER_BLACKJACK_PUSH,
			{"n21sting_win.wav"},				// SFX_STINGER_BLACKJACK_WIN,
		// Tutorial
			{"n21sting_tutorialcomplete.wav"},	// SFX_STINGER_TUTORIAL_COMPLETE,
		// Run 21
			{"n21sting_run21lose.wav"},			// SFX_STINGER_RUN21_LOSE,
			{"n21sting_run21win.wav"},			// SFX_STINGER_RUN21_WIN,
	
	// Tutorial UI Sounds
		{"n21tutorial_button.wav"},				// SFX_TUTORIAL_BUTTON,
		{"n21tutorial_dialogue.wav"},			// SFX_TUTORIAL_DIALOGUE,
		{"n21tutorial_presstoconfirm.wav"},		// SFX_TUTORIAL_PRESSTOCONFIRM,
	
	// Other Sounds
		{"n21ui_pause.wav"},					// SFX_MISC_PAUSE,
		{"dummysound.wav"},						// SFX_MISC_UNIMPLEMENTED,

};

// Default Volume multiplier
float sUIVolumes[SFX_NUM] = {
	// Companion UI Sounds
	1.0,										// SFX_COMPANION_AMBER_DD,
	1.0,										// SFX_COMPANION_CAPPO_SPLIT,
	1.0,										// SFX_COMPANION_IGUNAQ_REDO,
	1.0,										// SFX_COMPANION_JOHNNY_SWAP,
	1.0,										// SFX_COMPANION_PANDA_SURRENDER,
	1.0,										// SFX_COMPANION_VUT_HIT,
	
	// Blackjack Game UI Sounds
	1.0,										// SFX_BLACKJACK_BET_MINUS,
	1.0,										// SFX_BLACKJACK_BET_PLUS,
	1.0,										// SFX_BLACKJACK_DOUBLEDOWN,
	1.0,										// SFX_BLACKJACK_DEAL,
	1.0,										// SFX_BLACKJACK_HIT,
	1.0,										// SFX_BLACKJACK_SPLIT,
	1.0,										// SFX_BLACKJACK_STAND,
	
	// Run-21 Game UI Sounds
	1.0,										// SFX_RUN21_PLACECARD,
	
	// 21-Squared Game UI Sounds
	1.0,										// SFX_RUN21_PLACECARD_GREEN,
	1.0,										// SFX_RUN21_PLACECARD_YELLOW,
	1.0,										// SFX_RUN21_PLACECARD_RED,
	
	// Global UI Sounds
	1.0,										// SFX_GLOBALUI_CARDCONFIRM
	
	// In-Game Table/Card/Deck Sounds
	1.0,										// SFX_DECK_BUST,
	1.0,										// SFX_DECK_CARD_DEALT,
	1.0,										// SFX_DECK_CARD_FLIPPED,
	
	// Menu UI Sounds
	1.0,										// SFX_MENU_BACK,
	1.0,										// SFX_MENU_BUTTON_PRESS,
	1.0,										// SFX_MENU_SLIDE_FRAME
	
	// Outcome UI Sounds
	1.0,										// SFX_OUTCOME_LOSS,
	1.0,										// SFX_OUTCOME_PUSH,
	1.0,										// SFX_OUTCOME_SURRENDER,
	1.0,										// SFX_OUTCOME_WIN_NORMAL,
	1.0,										// SFX_OUTCOME_WIN_DD,
	1.0,										// SFX_OUTCOME_WIN_SPECIAL
	
	// Stingers
		// 21 Squared
		1.0,									// SFX_STINGER_21SQUARED_COMPLETED_COLUMN,
		1.0,									// SFX_STINGER_21SQUARED_COMPLETED_ROW,
		1.0,									// SFX_STINGER_21SQUARED_LOSS,
		1.0,									// SFX_STINGER_21SQUARED_WIN,
		// Neon Blackjack
		1.0,									// SFX_STINGER_BLACKJACK_BANKRUPT,
		1.0,									// SFX_STINGER_BLACKJACK_BIGWIN,
		1.0,									// SFX_STINGER_BLACKJACK_BJ,
		1.0,									// SFX_STINGER_BLACKJACK_BROKETHEBANK,
		1.0,									// SFX_STINGER_BLACKJACK_CHARLIE,
		1.0,									// SFX_STINGER_BLACKJACK_LOSE,
		1.0,									// SFX_STINGER_BLACKJACK_PUSH,
		1.0,									// SFX_STINGER_BLACKJACK_WIN,
		// Tutorial
		1.0,									// SFX_STINGER_TUTORIAL_COMPLETE,
		// Run 21
		1.0,									// SFX_STINGER_RUN21_LOSE,
		1.0,									// SFX_STINGER_RUN21_WIN,
		
	// Tutorial UI Sounds
		1.0,									// SFX_TUTORIAL_BUTTON,
		1.0,									// SFX_TUTORIAL_DIALOGUE,
		1.0,									// SFX_TUTORIAL_PRESSTOCONFIRM,
	
	// Other Sounds
		1.0,									// SFX_MISC_PAUSE,
		1.0,									// SFX_MISC_UNIMPLEMENTED,
};

@implementation UISounds

+(void)InitDefaultParams:(UISoundParams*)outParams
{
    outParams->mLoop    = FALSE;
    outParams->mGain    = 1.0f;
}

+(SoundSource*)PlayUISound:(UISoundId)inSoundId
{
    UISoundParams params;
    [UISounds InitDefaultParams:&params];
	params.mGain = sUIVolumes[ inSoundId ];
    
    return [UISounds PlayUISound:inSoundId withParams:&params];
}

+(SoundSource*)PlayUISoundWithFilename:(NSString*)inFilename withParams:(UISoundParams*)inParams
{
    SoundSourceParams params;
    [SoundSource InitDefaultParams:&params];
    
    params.mFilename = inFilename;
    params.mSoundSourceType = SOUND_SOURCE_TYPE_UI;
    params.mLoop = inParams->mLoop;
	params.mGain = inParams->mGain;
    
    return [[SoundPlayer GetInstance] PlaySoundWithParams:&params];
}

+(SoundSource*)PlayUISound:(UISoundId)inSoundId withParams:(UISoundParams*)inParams
{
    NSAssert((inSoundId >= 0) && (inSoundId < SFX_NUM), @"Invalid sound ID");
    
    SoundSourceParams params;
    [SoundSource InitDefaultParams:&params];
    
    params.mFilename = [NSString stringWithUTF8String:sUISounds[inSoundId].mFilename];
    params.mSoundSourceType = SOUND_SOURCE_TYPE_UI;
    params.mLoop = inParams->mLoop;
	params.mGain = inParams->mGain;
    
    return [[SoundPlayer GetInstance] PlaySoundWithParams:&params];
}

@end