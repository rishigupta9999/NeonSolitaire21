//
//  Card.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//
#import "Card.h"
#import "GameStateMgr.h"
#import "PlayerHand.h"

@implementation Card

@synthesize cardMode = mCardMode;

-(Card*)InitWithLabel:(int)in_label Suit:(int)in_suit
{
	mLabel	= in_label;
	mSuit	= in_suit; 
	[self SetValue];
	[self SetCardString];
    
    mCardMode = CARDMODE_NORMAL;
	
    mEntity = [[CardEntity alloc] InitWithCard:self];
	
	return self;
}

-(void)dealloc
{
    [mEntity Remove];
    
    [super dealloc];
}

// Rishi, this updates the card but doesn't update its rendering.
-(void)ChangeCardto:(int)in_Rank
{
	mLabel = in_Rank;
	[self SetValue];
	[self SetCardString];
}

/*
 SetValue sets the point value of the card based off its label 
 
 ex.	Two of Hearts	= 2
		Ace of Clubs	= 1 , optional high value of = 11
		Jack of Spades  = 10
		Joker of Hearts = 0
 
 */
-(void)SetValue
{
	mHighValue	= -1;	// Cards do not have a high value unless specifically toggled on
	
	if ( mLabel == CardLabel_Ace )
	{
		mValue		= 1;
		mHighValue	= 11;	// Aces can optionally be played as an '11'
	}
	else if ( mLabel >= CardLabel_Two && mLabel <= CardLabel_Nine )
	{
		// Add 1 due to 0-based indexing in the enumeration
		mValue = mLabel + 1;
	}
	else if ( mLabel >= CardLabel_Ten && mLabel <= CardLabel_King )
	{
		mValue = 10;
	}
	else if ( mLabel == CardLabel_Joker )
	{
		mValue = 0; 
	}
	
	// TODO: Assign Texture
}

-(char*)GetCardString
{
	return mText;
}

-(void)SetCardString
{
	// The first character is the Label
	switch ( mLabel )
	{
		case CardLabel_Ace:
			mText[0] = 'A';	
			break;
		case CardLabel_Two:
			mText[0] = '2';	
			break;
		case CardLabel_Three:
			mText[0] = '3';	
			break;
		case CardLabel_Four:
			mText[0] = '4';	
			break;
		case CardLabel_Five:
			mText[0] = '5';	
			break;
		case CardLabel_Six:
			mText[0] = '6';	
			break;
		case CardLabel_Seven:
			mText[0] = '7';	
			break;
		case CardLabel_Eight:
			mText[0] = '8';	
			break;
		case CardLabel_Nine:
			mText[0] = '9';	
			break;
		case CardLabel_Ten:
			mText[0] = 'T';	
			break;
		case CardLabel_Jack:
			mText[0] = 'J';	
			break;
		case CardLabel_Queen:
			mText[0] = 'Q';	
			break;
		case CardLabel_King:
			mText[0] = 'K';	
			break;
		case CardLabel_Joker:
			mText[0] = 'X';	
			break;
        default:
            NSAssert(FALSE, @"Unknown card label");
            break;
	}
	
	switch ( mSuit )
	{
		case CARDSUIT_Spades:
			mText[1] = 's';
			break;
			
		case CARDSUIT_Hearts:
			mText[1] = 'h';
			break;
		
		case CARDSUIT_Diamonds:
			mText[1] = 'd';
			break;
		
		case CARDSUIT_Clubs:
			mText[1] = 'c';
			break;
            
        default:
            NSAssert(FALSE, @"Unknown card suit");
            break;
			
	}
	
	mText[2] = 0;

	// The second character is the Suit
	
}

-(CardSuit)GetSuit
{
    return mSuit;
}

-(CardLabel)GetLabel
{
    return mLabel;
}

-(int)GetScore
{
	return mValue;
}

-(int)GetHighScore
{
	return mHighValue;
}

-(bool)GetFaceUp
{
	return mFaceUp;
}

-(void)SetFaceUp:(bool)in_faceUp
{
    if (mFaceUp != in_faceUp)
    {
        mFaceUp = in_faceUp;
        
        PlayerHandCardMessage msg;
        
        msg.mHand = NULL;
        msg.mCard = self;
        
        [[GameStateMgr GetInstance] SendEvent:EVENT_PLAYERHAND_CARD_FACE_CHANGED withData:&msg];
    }
}

-(void)setCardMode:(CardMode)inCardMode
{
    if (mCardMode != inCardMode)
    {
        mCardMode = inCardMode;
        
        [mEntity UpdateCardMode];
    }
}

@end