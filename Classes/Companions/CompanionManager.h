//
//  CompanionManager.m
//  Neon21
//
//  Copyright Neon Games 2009 All rights reserved.

#import "Companion.h"
#import "CompanionDefines.h"
		
typedef enum						//	Companion	Explanation
{
	RuleID_Empty			= 0,	//	None.		No effect.
	RuleID_Polly			= 1,	//	None.		No effect.
	RuleID_DDAny			= 2,	//	Amber		Double Down any 2-card hand, (except a split aces hand)
	RuleID_BJBonus			= 3,	//	Betty		Blackjacks pay 3:1 as o pposed to 3:2
	RuleID_TiesWin			= 4,	//	Cathy		Player wins on ties
	RuleID_DealerSwap		= 5,	//	Johnny		Swap starting hand with dealer ( with unknown hole card )
	RuleID_Surrender		= 6,	//	Panda		Allows player to surrender at any time, losing 1/2 bet.
	RuleID_16Hit			= 7,	//	NunaVut		If player reaches 16, free hit with stripped A-5 deck.
	RuleID_22Bust			= 8,	//	Igunaq		One do-over after busting on 22.
	RuleID_SplitAny			= 9,	//	DonCappo	Split any 2 card hand.
	RuleID_MAX				= 10
	// ------------------- CUT Rules ----------------- // 
	//RuleID_4Charlie		= XX,	//	Blade		If player has four cards, automatic win
	//RuleID_DealerBJSteal	= XX,	//	Ninja		Dealer Blackjack stolen to become player Blackjack
	//RuleID_Dealer18Stand	= XX,	//	Jack		Dealer only stands on 18 or higher.
	//RuleID_ThirdDiamond	= XX,	//	Jill		If three diamonds are in-play, player wins back initial bet
	// ------------------- CUT Rules ----------------- // 
	
} RuleIDs;

typedef enum
{                                                   // Casino		Stakes	Name				Description
	CompID_Empty			= 0,                    // -none-		-none-	-none-				Empty Seat
    CompID_FirstActive      = 1,
	CompID_Polly			= CompID_FirstActive,   // -none-		-none-	Polly Ibus			Main character, descendant of Greek Historian Polyibus, name also refers to Tempest Game Polyibus
	CompID_Amber			= 2,                    // Gracy's		-none-	Amber XXXX			
	CompID_Betty			= 3,                    // Gracy's		-none-	Betty XXXX			
	CompID_Cathy			= 4,                    // Gracy's		-none-	Cathy XXXX			
	CompID_Johnny			= 5,                    // I-Cha-Ching	Low		Johnny Five-Aces	Australian Cheat
	CompID_Panda			= 6,                    // I-Cha-Ching	High	Panda XXXX			Vegan Panda, Bored.
	CompID_NunaVut			= 7,                    // Fjord Knox	Low		Nuna & Vut Aqqiaruq	Inuit mother with boy in amauti
	CompID_Igunaq			= 8,                    // Fjord Knox	High	Igunaq Aiviq		Walrus who is always hungry
	CompID_DonCappo			= 9,                    // Gummy Slots	ALL		Don Cappo			Giant, Suit Wearing Mobster, Cigar Smoker, Watched Godfafther too many times.
	CompID_MAX				= 10
	// ------------------- CUT Characters ----------------- // 
	//CompID_Blade			= XX,                   // Fjord Knox: Wolf, Arrogant, Always an Asshole
	//CompID_Ninja			= XX,                   // I-Cha-Ching: Ninja
	//CompID_Jack			= XX,                   // Gummy Slots: Irish, Black, Lucky, Superstitious
	//CompID_Jill			= XX,                   // Gummy Slots: Old-timey Vegas Girl chain smoker, Giant Hat
	// ------------------- CUT Characters ----------------- // 
	
} CompanionID;

@class CompanionEntity;

@interface CompanionManager : NSObject
{
@public 
    Companion*          mActiveCompanions[COMPANION_POSITION_MAX];
    BOOL                mAbilitiesEnabled;
}

+(void)InitCompanionInfo;
+(Companion**)GetCompanionInfoArray;

// Class methods that manage creation and access
+(void)CreateInstance;
+(void)DestroyInstance;
+(CompanionManager*)GetInstance;
-(void)dealloc;

-(BOOL)IsCompanionActive:(CompanionID)in_CompanionID;
-(BOOL)IsRuleActive:(RuleIDs)ruleID;
-(void)InitCompanions;
-(void)UnlockCompanion:(CompanionID)in_CompanionID;
-(BOOL)CompanionUnlocked:(CompanionID)in_CompanionID;
-(void)SeatCompanion:(CompanionPosition)inPosition withID:(CompanionID)inCompanionID;
-(Companion*)GetCompanionForPosition:(CompanionPosition)inPosition;
+(CompanionID)GetCompanionWithName:(NSString*)inName;

-(void)SetAbilitiesEnabled:(BOOL)inEnabled;

@end