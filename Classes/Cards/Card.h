//
//  Card.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

/*
	Card represents a playing card.  Each card has a suit, rank, and label for gameplay purposes.
	Each card also has a entity that is rendered when the card is on the playfield.
	This class acts as a container, and should not be used to shuffle, play, move cards which is handled by the CardManager
 */
 
#import "CardEntity.h"
#import "CardDefines.h"

@interface Card : NSObject
{
@public
	CardLabel		mLabel;
	CardSuit		mSuit;
	int				mValue;
	int				mHighValue;	// Cards such as an Ace can be played with an optional high value.  Ex.  Kd + Ah = 10 + 1/11 = 21. 
	CardEntity*     mEntity;
	char			mText[3];	// Textual Rep of a card Ex. Kd, Ah, 2c
    bool			mFaceUp;	// False For Double Down, Dealer 1st Card
    bool            bIsScored;  // True means the card scores points
    bool            bDiscard;   // True means the card should be discarded at the end of the turn
}

@property(nonatomic) CardMode cardMode;

-(Card*)InitWithLabel:(int)in_label Suit:(int)in_suit;
-(void)dealloc;
-(void)SetValue;	 //Set the point value of the card based off its label 
-(void)ChangeCardto:(int)in_Rank;
-(void)SetCardString;
-(char*)GetCardString;
-(bool)GetFaceUp;
-(void)SetFaceUp:(bool)in_faceUp;

-(CardSuit)GetSuit;
-(CardLabel)GetLabel;
-(int)GetScore;
-(int)GetHighScore;

-(void)setCardMode:(CardMode)inCardMode;

@end