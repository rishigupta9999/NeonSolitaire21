//
//  CardManager.m
//  Neon21
//
//  Created by Kevin King on 12/25/08.
//  Copyright Neon Games 2008. All rights reserved.
//
#import "CardManager.h"
#import "Card.h"
#import "Time.h"

#import "CardRenderManager.h"
#import "CompanionManager.h"
#import "Flow.h"
#import "CardDefines.h"

static char sCardLabelCodes[CardLabel_Num]		= { 'A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'X' };
static char sCardSuitCodes[CARDSUIT_NumSuits]	= { 'S', 'H', 'D', 'C' };
static const float	sJokerShuffledPositionInDeck = 2.0;	// Jokers shuffled are in the top 1/n of the deck

@implementation CardManager

/*
 Debug - Stacking the Deck. 
*/

#define NUM_STACKED_CARDS               (9)


// Starting Player Hand
const CardLabel STACK_PLAYER_LEFT_LABEL  = CardLabel_Queen;	const CardSuit STACK_PLAYER_LEFT_SUIT	= CARDSUIT_Clubs;
const CardLabel STACK_PLAYER_RIGHT_LABEL = CardLabel_Jack;	const CardSuit STACK_PLAYER_RIGHT_SUIT	= CARDSUIT_Diamonds;

// Starting Dealer Hand
const CardLabel STACK_DEALER_LEFT_LABEL  = CardLabel_King;	const CardSuit STACK_DEALER_LEFT_SUIT	= CARDSUIT_Spades;
const CardLabel STACK_DEALER_RIGHT_LABEL = CardLabel_Ten;	const CardSuit STACK_DEALER_RIGHT_SUIT	= CARDSUIT_Hearts;


static u32 nIndexIntoStackedDeck        = 0;
// The deck
const CardLabel STACK_DECK_LABELS   [NUM_STACKED_CARDS] = { CardLabel_Two,		CardLabel_Two,		CardLabel_Two	, 
                                                            CardLabel_Two,      CardLabel_Two,      CardLabel_Two	, 
                                                            CardLabel_Two,      CardLabel_Two,      CardLabel_Two   };

const CardSuit  STACK_DECK_SUITS    [NUM_STACKED_CARDS] = { CARDSUIT_Clubs,     CARDSUIT_Clubs,     CARDSUIT_Clubs	, 
                                                            CARDSUIT_Clubs,     CARDSUIT_Clubs,     CARDSUIT_Clubs	, 
                                                            CARDSUIT_Clubs,     CARDSUIT_Clubs,     CARDSUIT_Clubs  };



/*
End Debug - Stacking the Deck. 
*/

// The most cards possible that can be in-play for standard Blackjack 
// ( 8 twos for dealer + extra card ; 4 split hands of 5 card charlies for player ) 52 - 9 - 5*4 = 23 
static const int CARDS_LEFT_IN_52CARD_BJ_DECK_FOR_RESHUFFLE	= 23;	



static CardManager* sInstance = NULL;

+(void)CreateInstance
{
    if (sInstance == NULL)
    {
        sInstance					= [CardManager alloc];
        sInstance->mShoe			= NULL;
        sInstance->mHoldover        = NULL;
        
        [CardRenderManager CreateInstance];
        
        // Use a standard 52 card deck unless the game mode later changes the deck logic. 
        sInstance->mNumDecks		= 1;							// A shoe can contain any number of "decks." made up of unique cards.  
        sInstance->mDifficultyDeck	= -1;							// Don't set the difficulty
        sInstance->mTypeDeck		= DECKTYPE_52Card;				// Standard 52 Card Deck
        [ sInstance RegisterDeckWithShuffle:TRUE TotalJokers:0 ];	// Shuffle the shoe, auto shuffle enabled.
    }
}

+(void)DestroyInstance
{
    [sInstance release];
    
    sInstance = NULL;
}

+(CardManager*)GetInstance
{
    return sInstance;
}

-(void)dealloc
{
    if ( mShoe != NULL )
	{
		// Clear out the deck
		[ mShoe release ];
	}
    if ( mHoldover != NULL )
	{
		// Clear out the deck
		[ mHoldover release ];
	}
    
    [CardRenderManager DestroyInstance];
    [super dealloc];
}

-(void)HoldoverTransferFromShoe:(Card*)card
{
    for ( Card *shoeCard in mShoe )
    {
        if ( card == shoeCard )
        {
            [ mHoldover addObject:card ];
            [ mShoe     removeObject:card ];
            return;
        }
    }
}
-(void)HoldoverTransferToShoe:(Card*)card
{
    for ( Card *holdCard in mHoldover )
    {
        if ( card == holdCard )
        {
            [ mShoe      insertObject:card atIndex:0 ]; // Always add to the front of the deck.
            [ mHoldover  removeObject:card ];
            return;
        }
    }
}

-(int)HoldoverTransferAll
{
    int i = [mHoldover count];
    int nCardsTransfered = 0;
    
    // If we don't have any cards, don't bother 
    if ( i == 0 )
        return nCardsTransfered;
    do
    {
        i           = [ mHoldover count] - 1;
        Card *pCard = [ mHoldover objectAtIndex:i ];    // Always extract from the end of the deck.
        [ mShoe     insertObject:pCard atIndex:0 ];     // Always add to the front of the deck.
        [ mHoldover removeObjectAtIndex:i];             // Remove the card
        nCardsTransfered++;
        
    } while ( i );
    
    return nCardsTransfered;
    // Get the last object from the Holdover
    // Insert it to the front of the shoe.

}

-(void)HoldoverClear
{
    [mHoldover release];
    mHoldover  = [ [ NSMutableArray alloc ] initWithCapacity:0 ];
}

-(void)ShoeClear
{
    [mShoe release];
    mShoe  = [ [ NSMutableArray alloc ] initWithCapacity:0 ];
}

-(void)ShoeClearWithNumRemaining:(int)inNumRemaining prioritizeHighCards:(BOOL)inPrioritizeHighCards
{
    if (!inPrioritizeHighCards)
    {
        CardLabel   curLabel = CardLabel_King;

        while(curLabel >= CardLabel_Nine)
        {
            [self ShoeClearWithLabel:curLabel numRemaining:inNumRemaining];
            curLabel--;
            
            if ([mShoe count] <= inNumRemaining)
            {
                break;
            }
        }
    }
    
    while([mShoe count] > inNumRemaining)
    {
        [mShoe removeObjectAtIndex:0];
    }
}

-(void)ShoeClearWithLabel:(CardLabel)inLabel numRemaining:(int)inNumRemaining
{
    CardSuit curSuit = CARDSUIT_First;
    int shoeSize = [mShoe count];
    
    while((curSuit < CARDSUIT_NumSuits) && (shoeSize > inNumRemaining))
    {
        BOOL success = FALSE;
        
        while(true)
        {
            success = [self RemoveCardFromDeck:inLabel suit:curSuit];
            
            shoeSize = [mShoe count];
            
            if ((shoeSize <= inNumRemaining) || (!success))
            {
                break;
            }
        }
    
        curSuit++;
        shoeSize = [mShoe count];
    }

}

-(void)PreShuffleDeck:(GAMETYPE)myGameType
{
	switch ( myGameType )
	{
		case GAMETYPE_NEONBJ:
			mTypeDeck = DECKTYPE_52Card;
			[ self RegisterDeckWithShuffle:TRUE TotalJokers:0];
			break;
						
		default:
			NSAssert(false, @"Attempted to pre-shuffle an unsupported game type");
	
	}
	
}
	
/*
	RegisterDeck creates a new shuffled deck for gameplay 
	 
	ex.	Neon 21			- [1-8] decks : 52 standard cards shuffled for omness
		Twenty-One^2	- 1 25 card deck without jokers ( jokers shuffled in later ), 3 Aces through 3 sevens, 4 "High Cards" determined by difficulty
	 
*/
-(void)RegisterDeckWithShuffle:(BOOL)bShuffle TotalJokers:(int)numJokers
{
	int numDeck, numRank, numSuit;
	
	if ( mShoe != NULL )
	{
		// Clear out the deck
		[ mShoe release ];
	}
	
	// Create a new deck
	mShoe			= [ [ NSMutableArray alloc ] initWithCapacity:0 ];
	
	// Decks never start with jokers in them, they are shuffled in manually via game mode logic
	mJokersInShoe	= 0;
	
	// Are we playing a standard game of Blackjack?
	if ( DECKTYPE_52Card == mTypeDeck )
	{
		// Iterate through the # of decks of cards we're shuffling into our master deck ( Casinos use 6 decks, we support [ 1 - 8 ] )
		for ( numDeck = 0 ; numDeck < mNumDecks ; numDeck++ )
		{
			// Iterate through all standard ranks of cards [ A, 2-9, T, J, Q, K ]
			for ( numRank = 0 ; numRank < CardLabel_Joker ; numRank++ )
			{
				// Iterate through all suits of cards [ S, H, D, C ]
				for ( numSuit = 0 ; numSuit < CARDSUIT_NumSuits ; numSuit++ )
				{
					Card *newCard = [ [ Card alloc ] InitWithLabel: numRank Suit: numSuit ];
					[ mShoe addObject : newCard ];
				}
				
			}
		}
		
		mIndexReshuffle = [ mShoe count ] - CARDS_LEFT_IN_52CARD_BJ_DECK_FOR_RESHUFFLE;
	}
	else if ( DECKTYPE_21Card == mTypeDeck )
	{
		// Iterate through the # of decks of cards we're shuffling into our master deck ( Casinos use 6 decks, we support [ 1 - 8 ] )
		for ( numDeck = 0 ; numDeck < mNumDecks ; numDeck++ )
		{
			// Iterate through only the Ace through Seven
			for ( numRank = 0 ; numRank <= CardLabel_Seven ; numRank++ )
			{
				// Iterate through all suits of cards [ S, H, D, C ]
				for ( numSuit = 0 ; numSuit < CARDSUIT_NumSuits ; numSuit++ )
				{
					// Discard any clubs
					if ( CARDSUIT_Clubs == numSuit )
						continue;
						
					Card *newCard = [ [ Card alloc ] InitWithLabel: numRank Suit: numSuit ];
					[ mShoe addObject : newCard ];
				}
				
			}
		}
		
		mShuffleEnabled = FALSE;
	}
	else 
	{
		NSAssert(false, @"Attempted to register an unsupported deck type");
	}

	if ( bShuffle )
	{
		[ self ShuffleDeck ];
	}
	
	return;

}

/*
 ShuffleDeck shuffles the active Cardmanager's deck 
 
 */
-(void)ShuffleDeck
{
	if ( mShoe == NULL )
	{
		// Clear out the deck
		NSAssert(false, @"Attempted to shuffle a NULL deck");
		return;
	}
		
    int numTotalCards = [mShoe count];
    int numSwaps = numTotalCards * 20;
    
    for (int swap = 0; swap < numSwaps; swap++)
    {
        int index1 = arc4random_uniform(numTotalCards - 1);
        int index2 = arc4random_uniform(numTotalCards - 1);

        [mShoe exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    }
		
	mIndexNextCardDealt = 0;
		
	return;
}

-(bool)DeckNeedsReshuffle
{
    if (mShuffleEnabled)
    {
        if ( mIndexReshuffle <= mIndexNextCardDealt )
            return true;
	}
    
	return false;
	
}

-(void)VisibleScoreWithHand:(PlayerHand*)hand out_score:(int*)score out_highScore:(int*)highScore
{
	bool useHighScore = false;
	Card *pCard;
	*score = 0;
	*highScore = -1;
	
	for ( int nCard = 0; nCard < [ hand count ] ; nCard++ )
	{
		pCard = [ hand objectAtIndex:nCard ];
		
		if ( pCard->mFaceUp )
		{
			*score += [ pCard GetScore ];
			
			if ( useHighScore == false && [ pCard GetHighScore ] > -1 )
			{
				useHighScore = true;
			}
		}
		
	}
	
	// Show a split score if the hand has at least one ace, and does not exceed 11.
	if ( useHighScore && *score <= 11 )	// Check for 12 because we already count the ace as 1.
	{
		*highScore = *score + 10; // The 1 is already counted in the score
	}
}

+(void)ScoreWithHand:(PlayerHand*)hand out_score:(int*)score out_highScore:(int*)highScore
{
	bool useHighScore = false;
	Card *pCard;
	*score = 0;
	*highScore = -1;
	
	
	for ( int nCard = 0; nCard < [ hand count ] ; nCard++ )
	{
		pCard = [ hand objectAtIndex:nCard ];
		*score += [ pCard GetScore ];
		
		if ( useHighScore == false && [ pCard GetHighScore ] > -1 )
		{
			useHighScore = true;
		}
	}
	
	// Show a split score if the hand has at least one ace, and does not exceed 11.
	if ( useHighScore && *score <= 11 )	// Check for 12 because we already count the ace as 1.
	{
		*highScore = *score + 10; // The 1 is already counted in the score
	}
}

+(int)FinalScoreWithHand:(PlayerHand*)hand
{
	int score, highScore;
	
	[CardManager ScoreWithHand:hand out_score:&score out_highScore:&highScore ];
	
	// If our highScore ( Ace as 11 ) score qualifies, use that as it'll always be the better half of our score
	if ( highScore > score && highScore <= 21 )
	{
		return highScore;
	}
	
	// Return our score
	return score;
	
}

-(void)TurnOverWithHand:(PlayerHand*)hand
{
	for ( int nCard = 0 ; nCard < [ hand count ] ; nCard++ )
	{
		if ( [ ((Card*)( [ hand objectAtIndex:nCard ] )) GetFaceUp ] == false )
		{
			[ ((Card*)( [ hand objectAtIndex:nCard ] )) SetFaceUp:true ];
		}
	}
	
}

-(BOOL)RemoveCardFromDeck:(CardLabel)inLabel suit:(CardSuit)inSuit
{
    for (Card* curCard in mShoe)
    {
        if (([curCard GetSuit] == inSuit) && ([curCard GetLabel] == inLabel))
        {
            [mShoe removeObject:curCard];
            return TRUE;
        }
    }
    
    return FALSE;
}

// Does not remove Jokers.
-(void)RemoveSuitsFromDeckExcept:(CardLabel)saveCardLabel withSuit:(CardSuit)saveSuit removeSpades:(BOOL)rSpades removeHearts:(BOOL)rHearts removeDiamonds:(BOOL)rDiamonds removeClubs:(BOOL)rClubs
{
	for ( int nIndex = mIndexNextCardDealt ; nIndex < [mShoe count] ; nIndex++ )
	{
		Card *pCard = [ mShoe objectAtIndex:nIndex ];
		
		// If a joker, continue
		if ( [ pCard GetLabel ] == CardLabel_Joker )
			continue;
		
		// If our protected card.
		if ( [ pCard GetLabel ] == saveCardLabel && saveSuit == [ pCard GetSuit ] )
			continue;
		
		// If we are not removing spades
		if ( !rSpades	&& ( CARDSUIT_Spades	== [ pCard GetSuit ] ) ) 
			continue;
		
		// If we are not removing hearts
		if ( !rHearts	&& ( CARDSUIT_Hearts	== [ pCard GetSuit ] ) ) 
			continue;
			
		// If we are not removing diamonds
		if ( !rDiamonds && ( CARDSUIT_Diamonds	== [ pCard GetSuit ] ) ) 
			continue;
			
		// If we are not removing clubs
		if ( !rClubs	&& ( CARDSUIT_Clubs		== [ pCard GetSuit ] ) )
			continue;
		
		// Remove the card.
		[ mShoe removeObjectAtIndex:nIndex ];
		// A new card is now at this index, so don't step forward.
		nIndex--;
	}

}

-(void)SwapCardsBetweenHands:(CARD_SWAPINDEX)cardIndex out_Hand1:(PlayerHand*)hand1 out_Hand2:(PlayerHand*)hand2
{
	Card* origLeftCard = ( (Card*)( [ hand1 objectAtIndex:CARD_Left ] ) );
	Card* newLeftCard = ( (Card*)( [ hand2 objectAtIndex:CARD_Left ] ) );
	Card* origRightCard = ( (Card*)( [ hand1 objectAtIndex:CARD_Right ] ) );
	Card* newRightCard = ( (Card*)( [ hand2 objectAtIndex:CARD_Right ] ) );
	
	// Handle the left card
	if ( CARD_Right != cardIndex )
	{
        [hand1 swapCard:origLeftCard withCard:newLeftCard fromHand:hand2];
	}
	
	// Handle the right card
	if ( CARD_Left != cardIndex )
	{
        [hand1 swapCard:origRightCard withCard:newRightCard fromHand:hand2];
	}
	
	[ CardManager ScoreWithHand : hand1 out_score : &hand1->mHandScore out_highScore : &hand1->mHighHandScore ];
	[ CardManager ScoreWithHand : hand2 out_score : &hand2->mHandScore out_highScore : &hand2->mHighHandScore ];
}

-(void)MoveCardToTopWithRank:(CardLabel)labelID	out_Suit:(CardSuit)suitID
{
	// Find the card index.
	int nIndex;
	Card *pCard;
	
	for ( nIndex = mIndexNextCardDealt ; nIndex < [mShoe count] ; nIndex ++ )
	{
		pCard = [ mShoe objectAtIndex:nIndex ];
		
		if ( [ pCard GetLabel ] == labelID && suitID == [ pCard GetSuit ] )
		{
			[ mShoe removeObjectAtIndex:nIndex		];
			[ mShoe insertObject:pCard atIndex:0	];
			return;
		}
	}
	
	NSAssert(false, @"Attempted to MoveCardToTopWithRank, with a card that was not in the playable deck");
}

-(void)InsertCardAtTopWithRank:(CardLabel)inLabel suit:(CardSuit)suitID
{
    Card* newCard = [[Card alloc] InitWithLabel:inLabel Suit:suitID];
    [mShoe insertObject:newCard atIndex:0];
}

-(void)OptionswithHand:(PlayerHand*)hand out_canSplit:(bool*)canSplit out_canDouble:(bool*)canDouble out_CanHit:(bool*)canHit out_ForceHit:(bool*)forceHit out_handsNotUsed:(int)handsNotUsed 
{
	int handScore;
	CompanionManager *compManager = [CompanionManager GetInstance];
	
	*forceHit	= false;
	*canHit		= true;
	*canSplit	= false;
	
	// If we have more than two cards, then the only options will be hit/stand for the player
	if ( [ hand count ] > 2 )
	{
		*canSplit	= false;
		*canDouble	= false;
		*forceHit	= false;
		*canHit		= true;
		return;
	}
	
	// If we have one card, we are in a force hit scenario
	if ( [ hand count ] == 1 )
	{
		*canSplit	= false;
		*canDouble	= false;
		*forceHit	= true;
		*canHit		= false;
		return;
	}
	
	if ( handsNotUsed > 0 )
	{
		if ( [ compManager IsRuleActive:RuleID_SplitAny ] ||
                ( [ [ hand objectAtIndex:0 ] GetLabel] == [ [ hand objectAtIndex:1 ] GetLabel] ) )
		{
			*canSplit = true;
		}
	}
	
	handScore = [ [ hand objectAtIndex:0 ] GetScore] + [ [ hand objectAtIndex:1 ] GetScore];
	
	// Currently allow double downs only on 9, 10, 11
	if ( handScore == 9 || handScore == 10 || handScore == 11 || [ compManager IsRuleActive:RuleID_DDAny ]  )
	{
		*canDouble = true;
	}
	else
	{
		*canDouble = false;
	}
	
	// This is a split aces hand
	if ( hand->mSplitAces )
	{
		// You can only split, or stand off of a split aces hand.
		*canDouble	= false;
		*canHit		= false;
		
		
	}
	// This is a split  hand
	else if ( hand->mSplit )
	{
		// Non-Aces split hands curently support all actions
		// noop
	}
	
	
}

-(bool)Has21WithHand:(PlayerHand*)hand
{
	int score, highScore;
	
	[ CardManager ScoreWithHand : hand out_score: &score out_highScore: &highScore ];
	
	if ( score == 21 || highScore == 21 )
		return true;
	
	return false;
}

-(bool)HasBJWithHand:(PlayerHand*)hand
{
	if ( [ self Has21WithHand:hand ] && [ hand count ] == 2 && !( hand->mSplit || hand->mSplitAces ) )
		return true;
	
	return false;
}

-(bool)HasBustWithHand:(PlayerHand*)hand
{
	int score, highScore;
	
	[ CardManager ScoreWithHand : hand out_score: &score out_highScore: &highScore ];
	
	if ( score > 21 )
		return true;
	
	return false;
}

-(bool)HasCharlieWithHand:(PlayerHand*)hand
{
	if ( [hand count] >= NUM_CARDS_IN_CHARLIE )
		return true;
	
	return false;
}

-(bool)HasJokerWithHand:(PlayerHand*)hand
{
	for ( int i = 0 ; i < [hand count] ; i++ )
	{
		Card *pCard = [ hand objectAtIndex : i ];
		
		// If this card is a joker
		if ( [pCard GetLabel] == CardLabel_Joker )
		{
			return TRUE;
		}
	}
	
	return FALSE;

}
-(void)SetStatusForHand:(PlayerHand*)hand out_canCharlie:(bool)canCharlie out_canBJ:(bool)canBJ
{
	if ( canCharlie && [ hand count ] >= NUM_CARDS_IN_CHARLIE )
	{
		hand->mCharlie		= true;
	}
	else if ( canBJ && [ self HasBJWithHand:hand ] )
	{
		hand->mBlackjack	= true;
	}
	
}

-(bool)ShouldHitwithHand:(PlayerHand*)hand
{
	int score		= 0;
	int highScore	= 0;
	int standHard	= 17;
	int standSoft	= 18;
	
	
	[ CardManager ScoreWithHand : hand out_score: &score out_highScore: &highScore ];
	
	// Cut rule
	/*if ( [ [CompanionManager GetInstance] IsRuleActive:RuleID_Dealer18Stand] )
	{
		standHard = 18;
	}*/
	
	// Stand on Soft 18 or Hard 17 and lower
	if ( score >= standHard || highScore >= standSoft )
	{
		return false;
	}

	return true;
}

// A hand is in-play if it did not bust and had player action.  ie.  Unnatural 21, 18, 14.  Hands not in play: 24, BJ, SUR
-(bool)IsInPlayWithHand:(PlayerHand*)hand
{
	if ( [ self HasBJWithHand:hand ] || hand->mSurrender || [ self HasBustWithHand:hand ] || hand->mCharlie )
	{
		return false;
	}
	
	return true;
	
}

-(Card*)DealCardWithFaceUp:(bool)faceUp out_Hand:(PlayerHand*)hand cardMode:(CardMode)inCardMode
{		
    if ( STACK_DECK && NUM_STACKED_CARDS > nIndexIntoStackedDeck )
    {
        Card* stackedCard = [self DealSpecificCardWithFaceUp:faceUp out_Label:STACK_DECK_LABELS[nIndexIntoStackedDeck % NUM_STACKED_CARDS] out_Suit:STACK_DECK_SUITS[nIndexIntoStackedDeck % NUM_STACKED_CARDS] out_Hand:hand];   
        stackedCard.cardMode = inCardMode;
        
        nIndexIntoStackedDeck++;
        
        return stackedCard;
    }

    Card *retCard;
    
    retCard = [mShoe objectAtIndex:mIndexNextCardDealt++];
    retCard.cardMode = inCardMode;
	
	if ( [retCard GetLabel ] == CardLabel_Joker )
	{
		mJokersInShoe--;
	}
        
    [ hand addCard:retCard withFaceUp:faceUp];
    [ CardManager ScoreWithHand : hand out_score : &hand->mHandScore out_highScore : &hand->mHighHandScore ];
    
    return retCard;
}

-(Card*)DealSpecificCardWithFaceUp:(bool)faceUp out_Label:(CardLabel)newCardLabel out_Suit:(CardSuit)newCardSuit out_Hand:(PlayerHand*)hand
{
	Card *retCard;
	
	retCard = [ mShoe objectAtIndex : mIndexNextCardDealt++ ];
	
	retCard->mLabel =newCardLabel; 
	retCard->mSuit = newCardSuit;
	
	[ retCard SetValue ];
	[ retCard SetCardString ];
	
	[ hand addCard : retCard withFaceUp:faceUp];
	[ CardManager ScoreWithHand : hand out_score : &hand->mHandScore out_highScore : &hand->mHighHandScore ];
	
	return retCard;
}

-(void)GetLabel:(CardLabel*)outLabel suit:(CardSuit*)outSuit forCode:(char*)inCode
{
    char uppercaseCode[2];
    
    uppercaseCode[0] = toupper(inCode[0]);
    uppercaseCode[1] = toupper(inCode[1]);
    
    *outLabel = CardLabel_Num;
    
    for (CardLabel cardLabel = CardLabel_Ace; cardLabel < CardLabel_Num; cardLabel++)
    {
        if (uppercaseCode[0] == sCardLabelCodes[cardLabel])
        {
            *outLabel = cardLabel;
        }
    }
    
    NSAssert(*outLabel != CardLabel_Num, @"Card label corresponding to %c was not found\n", uppercaseCode[0]);
    
    *outSuit = CARDSUIT_NumSuits;
    
	for (CardSuit cardSuit = CARDSUIT_Spades; cardSuit < CARDSUIT_NumSuits; cardSuit++)
	{
		if (uppercaseCode[1] == sCardSuitCodes[cardSuit])
		{
			*outSuit = cardSuit;
		}
	}
    
    NSAssert(*outSuit != CARDSUIT_NumSuits, @"Card suit corresponding to %c was not found\n", uppercaseCode[1]);
}

-(void)InsertCardWithLabel:(CardLabel)inLabel suit:(CardSuit)inSuit atIndex:(int)inIndex
{
    Card* newCard = [[Card alloc] InitWithLabel:inLabel Suit:inSuit];
    [mShoe insertObject:newCard atIndex:inIndex];
}

-(void)SetShuffleEnabled:(BOOL)inEnabled
{
    mShuffleEnabled = inEnabled;
}

-(void)RemoveJokersFromDeck
{
	// Iterate through all jokers that have yet to be dealt, don't touch cards that are in play or discarded.
	for ( int i = mIndexNextCardDealt; i < [mShoe count] ; i++ )
	{
		Card *pCard = [ mShoe objectAtIndex : i ];
		
		// If this card is a joker
		if ( [pCard GetLabel] == CardLabel_Joker )
		{
			// Remove this card.
			[ mShoe removeObjectAtIndex : i ];
			
			// Go back an index since the array count has shrunk
			i--;
		}
	}
    
	mJokersInShoe = 0;
}

-(void)InsertJokerAtTopOfDeck:(BOOL)bInsertTop JokerSuit:(CardSuit)suitID   
{
	int randOffset;
	mJokersInShoe++;
	
	// Both booleans can be true, do we want to insert a joker into the top of the deck?
	if ( bInsertTop )
	{
		[ self InsertCardWithLabel:CardLabel_Joker suit:suitID atIndex:mIndexNextCardDealt];
	}
	else 
	{
		int numCardsLeftInDeck = [mShoe count] - mIndexNextCardDealt;
		numCardsLeftInDeck = (float)numCardsLeftInDeck / sJokerShuffledPositionInDeck;	// Only want to deal in the top portion of the deck of the deck;
		
		if ( numCardsLeftInDeck <= 1 )
		{
            // If there is 1 or less cards in the deck, the joker mustn't be the last card played.
			randOffset = 0;
		}
		else
		{
			// A shuffled joker should not be in the top position of the deck, so increment by 1 ( index safe as numCardsLeftInDeck is halved )
			randOffset = arc4random_uniform(numCardsLeftInDeck-1) + 1;
		}
			
		int indexToInsert		= mIndexNextCardDealt + randOffset;
		
		[ self InsertCardWithLabel:CardLabel_Joker suit:suitID atIndex:indexToInsert];
	}
}

@end