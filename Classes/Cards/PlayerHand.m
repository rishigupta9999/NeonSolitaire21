//
//  PlayerHand.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "PlayerHand.h"
#import "GameStateMgr.h"
#import "Card.h"
#import "DebugManager.h"

@implementation PlayerHand

-(PlayerHand*)Init
{
    mHand = [[NSMutableArray alloc] initWithCapacity:0];
    
    return self;
}

-(void)dealloc
{    
    [mHand release];
    
    [super dealloc];
}

-(void)addCard:(Card*)anObject
{
    PlayerHandCardMessage msg;
    
    msg.mHand = self;
    msg.mCard = anObject;
    
    BOOL cardExists = FALSE;
    
    for (Card* inCard in mHand)
    {
        if (inCard == anObject)
        {
            cardExists = TRUE;
        }
    }

    if (!cardExists)
    {
        [mHand addObject:anObject];
    }
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_PLAYERHAND_CARD_ADDED withData:&msg];
}

-(void)addCard:(Card*)anObject withFaceUp:(BOOL)inFaceUp
{
    anObject->mFaceUp = inFaceUp;

    [self addCard:anObject];
}

-(NSUInteger)count
{
    return [mHand count];
}

-(int)countForMode:(CardMode)inMode
{
    int count = 0;
    
    for (Card* curCard in mHand)
    {
        if (curCard.cardMode == inMode)
        {
            count++;
        }
    }
    
    return count;
}

-(id)objectAtIndex:(NSUInteger)index
{
    return [mHand objectAtIndex:index];
}

-(NSUInteger)indexOfObject:(id)inObject
{
    return [mHand indexOfObject:inObject];
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    PlayerHandCardMessage msg;
    
    msg.mHand = self;
    msg.mCard = [mHand objectAtIndex:index];
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_PLAYERHAND_CARD_REMOVED withData:&msg];

    [mHand removeObjectAtIndex:index];
}

-(void)removeAllObjects
{
    PlayerHandCardMessage msg;
    
    msg.mHand = self;
    msg.mCard = NULL;
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_PLAYERHAND_REMOVE_ALL withData:&msg];

    [mHand removeAllObjects];
}

-(void)removeObject:(id)inObject
{
	u32 objIndex = [mHand indexOfObject:inObject];
	NSAssert(objIndex != NSNotFound, @"Card was not found in hand.");
	
	[self removeObjectAtIndex:objIndex];
}

-(void)swapCard:(Card*)inLeftCard withCard:(Card*)inRightCard fromHand:(PlayerHand*)inHand
{
    u32 objIndex = [mHand indexOfObject:inLeftCard];
    NSAssert(objIndex != NSNotFound, @"Card was not found in hand.");
    
    [mHand replaceObjectAtIndex:objIndex withObject:inRightCard];
    
    objIndex = [inHand indexOfObject:inRightCard];
    NSAssert(objIndex != NSNotFound, @"Card was not found in hand.");
    
    [inHand->mHand replaceObjectAtIndex:objIndex withObject:inLeftCard];
    
    // Notify listeners of what we've done.
    
    PlayerHandSwapMessage msg;
    
    msg.mLeftHand = self;
    msg.mRightHand = inHand;
    
    msg.mLeftCard = inLeftCard;
    msg.mRightCard = inRightCard;
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_PLAYERHAND_SWAP withData:&msg];
}

-(void)splitCard:(Card*)inCard fromHand:(PlayerHand*)inHand
{
    [inHand->mHand removeObject:inCard];
    [mHand addObject:inCard];
    
    // Notify listeners of what we've done
    
    PlayerHandSplitMessage msg;
    
    msg.mOldHand = inHand;
    msg.mNewHand = self;
    msg.mCard = inCard;
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_PLAYERHAND_SPLIT withData:&msg];
}

-(void)DrawTextHandwithPosX:(int)inPosX withPosY:(int)inPosY
{
	char			myStr[16];
	int				handLength;
	Card			*pCard;
	
	handLength = [ mHand count];
	
	for ( int nCard = 0 ; nCard < handLength ; nCard++ )
	{
		pCard = [ mHand objectAtIndex:nCard ];
		if ( [ pCard GetFaceUp ] )
		{
			snprintf(myStr, 16, "[ %s ]", pCard->mText);
		}
		else
		{
			snprintf(myStr, 16, "X[ %s ]X", pCard->mText);
		}
		
		[[DebugManager GetInstance] DrawString: [NSString stringWithUTF8String:myStr] locX:inPosX locY:inPosY ];	
		inPosX += 70;
	}
	
}


-(NSUInteger)getDiscardIndexFromLeft:(BOOL)inLeft
{
    int i ;
    int ending;
    int direction;
    if (inLeft)
    {
        i = 0;
        ending = [self count];
        direction = 1;
        
    }
    else
    {
        i = [self count]-1;
        ending = -1;
        direction = -1;
        
    }
    
    for (; i != ending;i += direction)
    {
        if( ((Card*)mHand[i])->bDiscard)
            return i;
    }
    return -1;
}


@end