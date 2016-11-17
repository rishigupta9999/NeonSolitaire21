//
//  PlayerHand.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

// The player can have up to MAX_PLAYER_HANDS hands, each hand self contains data such as how much is bet on this hand, if we surrendered it, etc. 

#import "CardDefines.h"
#import "Card.h"

@class PlayerHand;

#define STARTING_HAND			0
#define MAX_PLAYER_HANDS		5

#define NUM_CARDS_IN_CHARLIE	5

#define RAINBOW_NUM_CARDS_IN_HAND   4
#define RAINBOW_NUM_PLAYERS         2

typedef enum
{
    HAND_OWNER_DEALER,
    HAND_OWNER_PLAYER,
    HAND_OWNER_MAX
} HandOwner;

@class Card;

typedef struct
{
    PlayerHand* mHand;
    Card*       mCard;
} PlayerHandCardMessage;

typedef struct
{
    PlayerHand* mActiveHand;
    int         mNumHands;
} PlayerHandActiveHandChangedMessage;

typedef struct
{
    PlayerHand* mLeftHand;
    PlayerHand* mRightHand;
    Card*       mLeftCard;
    Card*       mRightCard;
} PlayerHandSwapMessage;

typedef struct
{
    PlayerHand* mOldHand;
    PlayerHand* mNewHand;
    Card*       mCard;
} PlayerHandSplitMessage;

typedef enum
{
	Outcome_PWin_BJ,					// In Neon21, only the 1st hand can have this ( Minigames allow for BJ on other hands)
	Outcome_PWin_Charlie,				// 5 card charlie
	Outcome_PWin_CleanSweep,			// Never assigned directly to a hand, used for messages
	Outcome_PWin_DDWin,					// Win off a double down
	Outcome_PWin_DealerBust,			// Win because the dealer bust
	Outcome_PWin_TiesWin,				// Win because of a companion rule allowing for ties to win
	Outcome_PWin_Score,					// Win because player's score better than dealer's score
	Outcome_Push,						// Tie
	Outcome_Initial,					// No previous/current hand outcome 
	Outcome_PLose_Score,				// Lose, the dealer's score surpasses this hand's score
	Outcome_PLose_PlayerBust,			// Lose, this hand busts automatically losing.
	Outcome_PLose_BJ,					// Lose, this hand was a Blackjack
	Outcome_PLose_DDLose,				// Lose, this hand was a double down
	Outcome_PLose_Surrender,			// Lose, + this hand was surrendered 
} EHandOutcome;

@interface PlayerHand : NSObject
{
    @public
        HandOwner       mHandOwner;
        int             mHandIndex;
        bool			bInPlay;		// Has this hand been dealt cards?  If this is the player's 2nd hand, and we have yet to split this will be false and all other struct variables will be invalid.
        int				mBet;			// How many neons were staked on this hand.  ( Wins pay 2:1 x DD , as we deduct the bet from the bankroll immediately )
		float			mPayRate;		// How much is the payout on this hand?  Default is 1:1 ( 1.0f )
		int				mNeonsWon;		// How many neons were won on this hand ( 0 throughout hand, payout determined at end, saved for rendering purposes )
        int				mHandScore;		// How much does this hand score as, with aces always counting as 1.
        int				mHighHandScore;	// How much does this hand score with:  No aces = -1 , First ace = 11, Subsequent aces as 1. ( no point in counting 2 aces as 22 )
        bool			mDoubleDown;	// Was this hand double downed?	( If so, the win will pay double )
        bool			mSplit;			// This hand originated a split, hands that are split are inelligible to be BJ
        bool			mSplitAces;		// This hand originated a split that was from aces, Aces that are split are forced to stand, no resplits allowed
        bool			mSurrender;		// Surrendered hands always lose, but get 1/2 of their bet repaid back
        bool			mBust;			// This hand busted
        bool			mBlackjack;		// This hand blackjacked, ( NOTE: a split hand can only receive 21, it is not a natural Blackjack )
		bool			mHasSwapped;	// This hand has already used its swap ability
		bool			mCharlie;		// This hand has a 4/5 card charlie and is an automatic winner.
		EHandOutcome	mOutcome;		// The outcome of the hand for betting results.
    
        // The number of cards in this hand of unique suit and rank.
        int             mRainbowCardsUnique;
        // The value of the total hand in rainbow scoring ( 4th kicker, 3rd kicker, 2nd kicker, 1st kicker ), Left->Right
        CardLabel       mRainbowValue[RAINBOW_NUM_CARDS_IN_HAND];
        int             mRainbowTurnsLeft;
        int             mRainbowRoundsWon;      // The number of rounds this hand has won
        bool            bRainbowResort;         // This lets us know whether or not we should re-sort the hand
    @private
		NSMutableArray *mHand;			// The player's hand
}

-(PlayerHand*)Init;

-(void)addCard:(Card*)anObject;
-(void)addCard:(Card*)anObject withFaceUp:(BOOL)inFaceUp;

-(NSUInteger)count;
-(int)countForMode:(CardMode)inMode;

-(NSUInteger)indexOfObject:(id)inObject;
-(id)objectAtIndex:(NSUInteger)index;
-(void)removeObjectAtIndex:(NSUInteger)index;
-(void)removeAllObjects;
-(void)removeObject:(id)inObject;
-(void)swapCard:(Card*)inLeft withCard:(Card*)inRight fromHand:(PlayerHand*)inHand;
-(void)splitCard:(Card*)inCard fromHand:(PlayerHand*)inHand;
-(void)DrawTextHandwithPosX:(int)inPosX withPosY:(int)inPosY;
-(NSUInteger)getDiscardIndexFromLeft:(BOOL)inLeft;


@end
