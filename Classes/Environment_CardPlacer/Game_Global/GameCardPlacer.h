//
//  GameCardPlacer.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "MessageChannel.h"
#import "PlayerHand.h"

@class Path;
@class GameObject;

@interface GameCardPlacer : NSObject<MessageChannelListener>
{
    float           mLeft;
    float           mRight;
    float           mTop;
    float           mBottom;
    
    NSMutableArray* mCardArrays[MAX_PLAYER_HANDS + 1]; // Add 1 for the placer
}

-(GameCardPlacer*)InitWithTable:(GameObject*)inTable;
-(void)dealloc;

-(void)ProcessMessage:(Message*)inMsg;

-(void)AddCard:(Card*)inCard ToHand:(PlayerHand*)inHandIndex;
-(void)PositionForCard:(Card*)inCard Hand:(PlayerHand*)inHand x:(float*)outX y:(float*)outY;
-(void)RemoveAllCards:(PlayerHand*)inHand;
-(void)CardFaceChanged:(Card*)inCard;

-(void)SplitCardWithOldHand:(PlayerHand*)inOldHand NewHand:(PlayerHand*)inNewHand Card:(Card*)inCard;

-(Path*)BuildPathFromStartToPosition:(Vector3*)inEndPos;

@end