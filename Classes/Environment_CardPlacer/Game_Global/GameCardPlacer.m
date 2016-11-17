//
//  GameCardPlacer.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "GameCardPlacer.h"
#import "GameStateMgr.h"
#import "GameObjectManager.h"
#import "Flow.h"
#import "LevelDefinitions.h"

#import "MiniGameTableEntity.h"

#import "Card.h"
#import "Path.h"
#import "Run21UI.h"

#define CARD_ARRAY_INITIAL_SIZE					(6)
#define CARD_FLIP_TIME							(0.5)
#define CARD_FLIP_HEIGHT                        (-0.5)

#define ROW_LOCATION_ORIGIN_X					(.95)
#define ROW_LOCATION_ORIGIN_Y					(-0.20)
#define CARD_SPACING_X							(1.05)
#define CARD_SPACING_Y							(1.75)

static const Vector2 sDealPosition              = { { 6.40f, -0.70f } };
static const Vector2 sPlacerPosition            = { { 5.77f, 2.04f } };

static const Vector3 sDealStartScale            = { { 0.25f, 0.25f, 1.0f } };
static const Vector3 sDealEndScale              = { { 1.25f, 0.85f, 1.0f } };
static const Vector3 sPlacerEndScale            = { { 2.2f, 1.65f, 1.0f } };
static const Vector3 sBoardScale                = { { 0.9f, 0.9f, 1.0f } };
static const Vector3 sSmallBoardScale           = { { 0.8f, 0.8f, 1.0f } };

static const float CARD_ANIMATION_SPEED			= 12.0f;
static const float CARD_ANIMATION_SPEED_FAST	= 20.0f;
static const float CARD_SCALE_ANIMATION_SPEED	= 7.5f;

@implementation GameCardPlacer

-(GameCardPlacer*)InitWithTable:(GameObject*)inTable
{
    // Get the table height
    Box boundingBox;
    Face topFace;
    
    BOOL status = [inTable GetWorldSpaceBoundingBox:&boundingBox];
    NSAssert(status != FALSE, @"Could not get bounding box for the Run 21 table.");
    status = status;
    
    GetTopFaceForBox(&boundingBox, &topFace);
    FaceExtents(&topFace, &mLeft, &mRight, &mTop, &mBottom);
    
    GameState* curState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    [[curState GetMessageChannel] AddListener:self];
    
    int numArrays = (sizeof(mCardArrays) / sizeof(NSMutableArray*));
    
    for (int i = 0; i < numArrays; i++)
    {
        mCardArrays[i] = [[NSMutableArray alloc] initWithCapacity:CARD_ARRAY_INITIAL_SIZE];
    }

    return self;
}

-(void)dealloc
{
    int numArrays = (sizeof(mCardArrays) / sizeof(NSMutableArray*));

    for (int i = 0; i < numArrays; i++)
    {
        [mCardArrays[i] release];
    }
    
    [super dealloc];
}

-(void)ProcessMessage:(Message*)inMsg
{
	PlayerHandCardMessage* msg		= (PlayerHandCardMessage*)inMsg->mData;
	
    switch(inMsg->mId)
    {
        case EVENT_PLAYERHAND_CARD_ADDED:
        {
            [self AddCard:msg->mCard ToHand:msg->mHand];            
            break;
        }
		case EVENT_PLAYERHAND_REMOVE_ALL:
        {
            [self RemoveAllCards:msg->mHand];
            break;
        }
        case EVENT_PLAYERHAND_CARD_REMOVED:
        {
            Path* fadeOutPath = [[Path alloc] Init];
            CardEntity* cardEntity = msg->mCard->mEntity;
            
            [fadeOutPath AddNodeScalar:1.0 atTime:0.0];
            [fadeOutPath AddNodeScalar:0.0 atTime:1.0];
            [cardEntity AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:fadeOutPath];
            [fadeOutPath release];
            
            [cardEntity PerformAfterOperationsInQueue:dispatch_get_main_queue() block:^
            {
                [cardEntity Reset];
            } ];
            
            [mCardArrays[msg->mCard->mEntity->mParentHand->mHandIndex] removeObject:msg->mCard];
            
            break;
        }
		case EVENT_PLAYERHAND_CARD_FACE_CHANGED:
        {
            [self CardFaceChanged:msg->mCard];
            break;
        }
		case EVENT_PLAYERHAND_SPLIT:
        {
			PlayerHandSplitMessage *splitMsg = (PlayerHandSplitMessage*)inMsg->mData;
			[self SplitCardWithOldHand:splitMsg->mOldHand NewHand:splitMsg->mNewHand Card:splitMsg->mCard];
			break;
        }
    }
}

-(void)AddCard:(Card*)inCard ToHand:(PlayerHand*)inHand
{
    BOOL cardInHand = FALSE;
    
    for (Card* curCard in mCardArrays[inHand->mHandIndex])
    {
        if (inCard == curCard)
        {
            cardInHand = TRUE;
            break;
        }
    }
    
    [inCard->mEntity SetVisible:TRUE];
    inCard->mEntity->mParentHand = inHand;
    inCard->mEntity->mUsesLighting = FALSE;
    
    Vector3 alpha;
    [inCard->mEntity GetProperty:GAMEOBJECT_PROPERTY_ALPHA withVector:&alpha];
    
    if (alpha.mVector[x] < 1.0)
    {
        Path* fadeInPath = [[Path alloc] Init];
        [fadeInPath AddNodeScalar:0.0 atTime:0.0];
        [fadeInPath AddNodeScalar:1.0 atTime:1.0];
        [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:fadeInPath];
        [fadeInPath release];
    }
    
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
    float cardX, cardY, cardZ;
    
    if (inHand->mHandIndex == numRunners)
    {
        cardZ = (inCard.cardMode == CARDMODE_XRAY) ? -EPSILON : -EPSILON - .01;

        Path* positionPath = [(Path*)[Path alloc] Init];
        
        [positionPath AddNodeX:sDealPosition.mVector[x] y:sDealPosition.mVector[y] z:cardZ atTime:0.0f];
        
        if (inCard.cardMode == CARDMODE_NORMAL)
        {
            [positionPath AddNodeX:sPlacerPosition.mVector[x] y:sPlacerPosition.mVector[y] z:cardZ atTime:0.4f];
        }
        
        [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:positionPath];
        [positionPath release];
        
        Path* scalePath = [(Path*)[Path alloc] Init];
        
        if (inCard.cardMode == CARDMODE_XRAY)
        {
            [scalePath AddNodeVec3:(Vector3*)&sDealStartScale atTime:0.0f];
            [scalePath AddNodeVec3:(Vector3*)&sDealEndScale atTime:0.4f];
        }
        else
        {
            [scalePath AddNodeVec3:(Vector3*)&sDealEndScale atTime:0.0f];
            [scalePath AddNodeVec3:(Vector3*)&sPlacerEndScale atTime:0.4f];
        }
        
        [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_SCALE withPath:scalePath];
        
        [scalePath release];
    }
    else
    {
        [self PositionForCard:inCard Hand:inHand x:&cardX y:&cardY];

        cardZ = -EPSILON;
        
        Vector3 endPos = { { cardX, cardY, cardZ} };
        
        Path* path = [self BuildPathFromStartToPosition:&endPos];
        [inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:path];
    }
    
    // If we don't do this, the card will be rendered for one frame at an uninitialized position.  The GameObjects
    // will typically only be updated the following frame.
    [inCard->mEntity Update:0.0f];
    
    NSMutableArray* cardArray = mCardArrays[inCard->mEntity->mParentHand->mHandIndex];
    NSAssert(cardArray != NULL, @"NULL card array");
    
    if (!cardInHand)
    {
        [mCardArrays[inCard->mEntity->mParentHand->mHandIndex] addObject:inCard];
    }
}
 

-(void)SplitCardWithOldHand:(PlayerHand*)inOldHand NewHand:(PlayerHand*)inNewHand Card:(Card*)inCard
{
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
	// Scale card down back from 2.0 to 1.0
	Path* scalePath = [(Path*)[Path alloc] Init];
    [ scalePath AddNodeVec3:(Vector3*)&sPlacerEndScale atTime:0.0f ];
    
    if (numRunners <= MAX_UNSCALED_RUNNERS)
    {
        [scalePath AddNodeVec3:(Vector3*)&sBoardScale atTime:0.4f];
    }
    else
    {
        [scalePath AddNodeVec3:(Vector3*)&sSmallBoardScale atTime:0.4f];
    }
    
	[inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_SCALE withPath:scalePath];
	[scalePath autorelease];
	
	// Translate card from placer to hand row, move the cards fast if moving to or from the placer
	float cardSpeed;
    if(inOldHand->mHandIndex == numRunners || inNewHand->mHandIndex == numRunners)
        cardSpeed = CARD_ANIMATION_SPEED_FAST;
    else
        cardSpeed = CARD_ANIMATION_SPEED;
    
	Path* translatePath = [(Path*)[Path alloc] Init];
	Vector3 startPosition, endPosition;
	[ inCard->mEntity GetPosition:&startPosition ];
	[ self PositionForCard:inCard Hand:inNewHand x:&endPosition.mVector[x] y:&endPosition.mVector[y]];
	endPosition.mVector[z] = -EPSILON;
	[translatePath AddNodeVec3:&startPosition	atIndex:0 withSpeed:cardSpeed];
	[translatePath AddNodeVec3:&endPosition		atIndex:1 withSpeed:cardSpeed];
	[inCard->mEntity AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:translatePath];
	[translatePath autorelease];
	 
	return;
}

-(void)PositionForCard:(Card*)inCard Hand:(PlayerHand*)inHand x:(float*)outX y:(float*)outY
{
    float yOrigin   = [Run21UI GetRunnerYOrigin];
    float ySpacing  = [Run21UI GetRunnerSpacing];
    
	float cardX     = ( mLeft + ROW_LOCATION_ORIGIN_X ) + (float)(([ inHand count ] - 1) * CARD_SPACING_X);
    float cardY     = ( mTop  + yOrigin + ROW_LOCATION_ORIGIN_Y ) + (float)(( inHand->mHandIndex ) * ySpacing);
    
    int numRunners = [[[Flow GetInstance] GetLevelDefinitions] GetNumRunners];
    
    if (numRunners > MAX_UNSCALED_RUNNERS)
    {
        cardY -= 0.16;
    }
	
	if ( inHand->mHandIndex == numRunners )
	{
		cardX = sPlacerPosition.mVector[x];
		cardY = sPlacerPosition.mVector[y];
	}
    
    *outX = cardX;
    *outY = cardY;
}

-(Path*)BuildPathFromStartToPosition:(Vector3*)inEndPos
{
    Path* path				= [(Path*)[Path alloc] Init];
    Vector3 startPosition	= { { sPlacerPosition.mVector[x], sPlacerPosition.mVector[y], -EPSILON } };
    
    [path AddNodeVec3:&startPosition atIndex:0 withSpeed:CARD_ANIMATION_SPEED];
    [path AddNodeVec3:inEndPos atIndex:1 withSpeed:CARD_ANIMATION_SPEED];
    [path autorelease];
    
    return path;
}

-(void)RemoveAllCards:(PlayerHand*)inHand
{
    int numCards = [inHand count];
    
    for (int i = 0; i < numCards; i++)
    {
        Card* curCard = [inHand objectAtIndex:i];
        [curCard->mEntity Reset];
    }
    
	[mCardArrays[inHand->mHandIndex] removeAllObjects];
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