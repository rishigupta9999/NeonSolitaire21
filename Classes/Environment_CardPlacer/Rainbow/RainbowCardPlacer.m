//
//  RainbowCardPlacer.m
//  Neon Engine
//
//  Copyright Neon Games 2012
//

#import "RainbowCardPlacer.h"

#import "Event.h"

#import "Card.h"
#import "Path.h"

#define ROW_LOCATION_ORIGIN_X					(1.75)
#define ROW_LOCATION_ORIGIN_Y					(0.30)
#define CARD_SPACING_X							(2.40)
#define CARD_SPACING_Y							(3.15)
#define CARD_SCALE_LARGE						(1.66)
#define CARD_SCALE_SMALL						(0.3)
#define CARD_FLIP_TIME							(0.5)
#define CARD_FLIP_HEIGHT                        (-1.00)

#define CARDS_PER_HAND 4

static const Vector2 sStartPosition				= { { 3.0f, -2.5f } };
static const float CARD_ANIMATION_SPEED			= 10.0f;
static const float CARD_SCALE_ANIMATION_SPEED	= 7.5f;

@implementation RainbowCardPlacer

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_PLAYERHAND_SWAP:
        {
            PlayerHandSwapMessage *swapMsg = (PlayerHandSwapMessage*)inMsg->mData;

            [self ResetCardPosInHand:swapMsg->mLeftHand];
        }
    }
    [super ProcessMessage:inMsg];
}

-(void)SplitCardWithOldHand:(PlayerHand*)inOldHand NewHand:(PlayerHand*)inNewHand Card:(Card*)inCard
{
	// Scale card down back from 2.0 to 1.0
	Path* scalePath = [(Path*)[Path alloc] Init];
	[ scalePath AddNodeScalar:CARD_SCALE_LARGE atIndex:0 withSpeed:CARD_SCALE_ANIMATION_SPEED ];
	[ scalePath AddNodeScalar:CARD_SCALE_SMALL atIndex:1 withSpeed:CARD_SCALE_ANIMATION_SPEED ];
	[inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_SCALE withPath:scalePath];
	[scalePath autorelease];
	
	// Translate card from placer to hand row
	Path* translatePath = [(Path*)[Path alloc] Init];
	Vector3 startPosition, endPosition;
	[ inCard->mEntity GetPosition:&startPosition ];
    if (inNewHand->mHandIndex != MAX_PLAYER_HANDS)
    {
        [ self PositionForCard:inCard Hand:inNewHand x:&endPosition.mVector[x] y:&endPosition.mVector[y]];
    }
    else
    {
        endPosition = startPosition;
    }
	endPosition.mVector[z] = -EPSILON;
	[translatePath AddNodeVec3:&startPosition	atIndex:0 withSpeed:CARD_ANIMATION_SPEED];
	[translatePath AddNodeVec3:&endPosition		atIndex:1 withSpeed:CARD_ANIMATION_SPEED];
	[inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:translatePath];
	[translatePath autorelease];
        
    [self ResetCardPosInHand:inOldHand];
    
	return;
}

-(void)ResetCardPosInHand:(PlayerHand*)inHand
{
    Card* curCard;
    Vector3 startPosition, endPosition;
    Path* translatePath;
    
    for (int i = 0; i < [inHand count]; i++)
    {
        translatePath = [(Path*)[Path alloc] Init];
        curCard = (Card*)[inHand objectAtIndex:i];
        
        //Get the start and end location for the path
        [ curCard->mEntity GetPosition:&startPosition ];
        [ self PositionForCard:curCard Hand:inHand inIndex:i  x:&endPosition.mVector[x] y:&endPosition.mVector[y]];
        endPosition.mVector[z] = -EPSILON;
        
        //Do the Translation
        [translatePath AddNodeVec3:&startPosition	atIndex:0 withSpeed:CARD_ANIMATION_SPEED];
        [translatePath AddNodeVec3:&endPosition		atIndex:1 withSpeed:CARD_ANIMATION_SPEED];
        [curCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:translatePath];
        [translatePath autorelease];
    }
    
}
-(void)PositionForCard:(Card*)inCard Hand:(PlayerHand*)inHand x:(float*)outX y:(float*)outY
{

    float cardX			= ( mLeft + ROW_LOCATION_ORIGIN_X ) + (float)( ([ inHand count ] - 1) * CARD_SPACING_X);
    float cardY			= ( mTop  + ROW_LOCATION_ORIGIN_Y )	+ (float)( ( inHand->mHandIndex ) * CARD_SPACING_Y);

    if ( inHand->mHandIndex == MAX_PLAYER_HANDS )
    {
        cardX = sStartPosition.mVector[x];
        cardY = sStartPosition.mVector[y];
    }
    
    *outX = cardX;
    *outY = cardY;
}

-(void)PositionForCard:(Card*)inCard Hand:(PlayerHand*)inHand inIndex:(int)index x:(float*)outX y:(float*)outY
{
    
    float cardX			= ( mLeft + ROW_LOCATION_ORIGIN_X ) + (float)( ( index ) * CARD_SPACING_X);
    float cardY			= ( mTop  + ROW_LOCATION_ORIGIN_Y )	+ (float)( ( inHand->mHandIndex ) * CARD_SPACING_Y);
    
    if ( inHand->mHandIndex == MAX_PLAYER_HANDS )
    {
        cardX = sStartPosition.mVector[x];
        cardY = sStartPosition.mVector[y];
    }
    
    *outX = cardX;
    *outY = cardY;
}

-(Path*)BuildPathFromStart:(Vector3*)inEndPos
{
    Path* path				= [(Path*)[Path alloc] Init];
    
    [path AddNodeVec3:inEndPos atIndex:0 withSpeed:CARD_ANIMATION_SPEED];
    [path AddNodeVec3:inEndPos atIndex:1 withSpeed:CARD_ANIMATION_SPEED];
    [path autorelease];
    
    return path;
}
-(void)AddCard:(Card*)inCard ToHand:(PlayerHand*)inHand
{
    [inCard->mEntity SetVisible:TRUE];
    inCard->mEntity->mParentHand = inHand;
    inCard->mEntity->mUsesLighting = FALSE;
    
    float cardX, cardY;
    [self PositionForCard:inCard Hand:inHand x:&cardX y:&cardY];
    
    if (!inCard->mFaceUp)
    {
        [inCard->mEntity SetOrientationX:0.0 Y:180.0 Z:0.0];
    }
    
    Vector3 endPos = { { cardX, cardY, -EPSILON } };
    
    Path* path = [self BuildPathFromStart:&endPos];
    [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:path];

    Path* scalePath = [(Path*)[Path alloc] Init];
    [ scalePath AddNodeScalar:CARD_SCALE_SMALL atIndex:0 withSpeed:CARD_SCALE_ANIMATION_SPEED ];
    [ scalePath AddNodeScalar:CARD_SCALE_LARGE atIndex:1 withSpeed:CARD_SCALE_ANIMATION_SPEED ];
    [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_SCALE withPath:scalePath];
    [scalePath autorelease];

    
    // If we don't do this, the card will be rendered for one frame at an uninitialized position.  The GameObjects
    // will typically only be updated the following frame.
    [inCard->mEntity Update:0.0f];
    
    [mCardArrays[inCard->mEntity->mParentHand->mHandIndex] addObject:inCard];
}

-(void)CardFaceChanged:(Card*)inCard
{
    float orientationY = inCard->mFaceUp ? 0.0 : 180.0;
    Vector3 startOrientation, endOrientation;
    Vector3 startPosition, flipPosition;
    Path *path;
    
    //Set the starting and ending orientation for the flipping part of the animation
    [inCard->mEntity GetOrientation:&startOrientation];
    Set(&endOrientation, 0.0, orientationY, 0.0);
    
    //Set the starting and midpoint for the moving part of the animation
    [inCard->mEntity GetPosition:&startPosition];
    CloneVec3(&startPosition,&flipPosition);
    flipPosition.mVector[2]+=CARD_FLIP_HEIGHT;
    
    //Move the card up and down while flipping, so that it does not go through the table
    path = [(Path*)[Path alloc] Init];
    [path autorelease];
    
    [path AddNodeVec3:&startPosition atTime:0.0];
    [path AddNodeVec3:&flipPosition atTime:CARD_FLIP_TIME/2.0];
    [path AddNodeVec3:&startPosition atTime:CARD_FLIP_TIME];
    
    [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:path];
    
    //Flip the Card over
    path = [(Path*)[Path alloc] Init];
    [path autorelease];
	
    [path AddNodeVec3:&startOrientation atTime:0.0];
    [path AddNodeVec3:&endOrientation atTime:CARD_FLIP_TIME];
    
    [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_ORIENTATION withPath:path];
    
}

@end