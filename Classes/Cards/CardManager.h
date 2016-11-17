//
//  CardManager.h
//  Neon21
//
//  Created by Kevin King on 12/25/08.
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Card.h"

/*
 CardManager represents a deck of cards.  In addition to the standard 52 card deck, we support other deck types ( jokers, reduced cut ) for minigames
 The CardManager should be used for card logic, such as shuffling, rendering active cards, and scoring hands
 The CardManager should NOT be used to modify individual cards.
 */

typedef enum
{
	DECKTYPE_52Card = 52,	// Standard Blackjack Deck
	DECKTYPE_21Card = 21,	// Twenty-One^2 Deck.  Jokers come in later in the game, never expanding the deck past twenty-one.
} DECKTYPE;

typedef enum
{
	GAMETYPE_NEONBJ,
	GAMETYPE_21SQUARED,
	GAMETYPE_NUM,
} GAMETYPE;

typedef enum
{
	CARD_Left	= 0,	// The first card
	CARD_Right	= 1,	// The second card
	CARD_Both	= 2,	// Both cards
} CARD_SWAPINDEX;		// Which cards are two hands trying to swap ( This only happens in starting two card hands )

@interface CardManager : NSObject
{
@public
	int				mNumDecks;				// How many whole decks make up the master deck ( Casinos use more than 1 deck per shoe )
	DECKTYPE		mTypeDeck;				// What type of deck is this?  Enumeration also equals the amount of unique cards per deck
	int				mDifficultyDeck;		// Decks such as Twenty-One^2 support multiple difficulty levels, changing the cards present in the deck
	int				mIndexNextCardDealt;	// Where are we in the deck, this index is the next card in the shoe we deal out
	int				mIndexReshuffle;		// At what point do we reshuffle?  Note: Certain decks such as Twenty-One^2 don't reshuffle, and use index = INT_MAX;
	NSMutableArray *mShoe;					// The deck of cards
    NSMutableArray *mHoldover;              // Cards carried from one game to another.
	BOOL            mShuffleEnabled;		// Does the deck automatically shuffle if running low on cards?
	int				mJokersInShoe;			// How many Jokers are currently in the shoe
}

// Class methods that manage creation and access
+(void)CreateInstance;
+(void)DestroyInstance;
+(CardManager*)GetInstance;
-(void)dealloc;

-(void)RegisterDeckWithShuffle:(BOOL)bShuffle TotalJokers:(int)numJokers;
-(void)PreShuffleDeck:(GAMETYPE)myGameType;
-(void)ShuffleDeck;
-(bool)DeckNeedsReshuffle;
-(void)SetShuffleEnabled:(BOOL)inEnabled;

-(void)RemoveJokersFromDeck;
-(void)InsertJokerAtTopOfDeck:(BOOL)bInsertTop JokerSuit:(CardSuit)suitID;

-(Card*)DealCardWithFaceUp:(bool)faceUp out_Hand:(PlayerHand*)hand cardMode:(CardMode)inCardMode;
-(Card*)DealSpecificCardWithFaceUp:(bool)faceUp out_Label:(CardLabel)newCardLabel out_Suit:(CardSuit)newCardSuit out_Hand:(PlayerHand*)hand;
-(void)SwapCardsBetweenHands:(CARD_SWAPINDEX)cardIndex out_Hand1:(PlayerHand*)hand1 out_Hand2:(PlayerHand*)hand2;
-(void)MoveCardToTopWithRank:(CardLabel)labelID out_Suit:(CardSuit)suitID;
-(void)InsertCardAtTopWithRank:(CardLabel)inLabel suit:(CardSuit)suitID;

-(void)HoldoverTransferFromShoe:(Card*)card;
-(void)HoldoverTransferToShoe:(Card*)card;
-(int)HoldoverTransferAll;
-(void)HoldoverClear;

-(void)ShoeClear;
-(void)ShoeClearWithNumRemaining:(int)inNumRemaining prioritizeHighCards:(BOOL)inPrioritizeHighCards;
-(void)ShoeClearWithLabel:(CardLabel)inLabel numRemaining:(int)inNumRemaining;

-(BOOL)RemoveCardFromDeck:(CardLabel)inLabel suit:(CardSuit)inSuit;
-(void)RemoveSuitsFromDeckExcept:(CardLabel)saveCardLabel withSuit:(CardSuit)saveSuit removeSpades:(BOOL)rSpades removeHearts:(BOOL)rHearts removeDiamonds:(BOOL)rDiamonds removeClubs:(BOOL)rClubs;

+(void)ScoreWithHand:(PlayerHand*)hand out_score:(int*)score out_highScore:(int*)highScore;
-(void)VisibleScoreWithHand:(PlayerHand*)hand out_score:(int*)score out_highScore:(int*)highScore;
+(int)FinalScoreWithHand:(PlayerHand*)hand;

-(bool)Has21WithHand:(PlayerHand*)hand;
-(bool)HasBJWithHand:(PlayerHand*)hand;
-(bool)HasBustWithHand:(PlayerHand*)hand;
-(bool)HasCharlieWithHand:(PlayerHand*)hand;
-(bool)HasJokerWithHand:(PlayerHand*)hand;

-(void)TurnOverWithHand:(PlayerHand*)hand;
-(void)SetStatusForHand:(PlayerHand*)hand out_canCharlie:(bool)canCharlie out_canBJ:(bool)canBJ;
-(void)OptionswithHand:(PlayerHand*)hand out_canSplit:(bool*)canSplit out_canDouble:(bool*)canDouble out_CanHit:(bool*)canHit out_ForceHit:(bool*)forceHit out_handsNotUsed:(int)handsNotUsed;
-(bool)ShouldHitwithHand:(PlayerHand*)hand;
-(bool)IsInPlayWithHand:(PlayerHand*)hand;

-(void)GetLabel:(CardLabel*)outLabel suit:(CardSuit*)outSuit forCode:(char*)inCode;
-(void)InsertCardWithLabel:(CardLabel)inLabel suit:(CardSuit)inSuit atIndex:(int)inIndex;

@end