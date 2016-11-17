//
//  RainbowCardPlacer.h
//  Neon21
//
//  Copyright Neon Games 2012. All rights reserved.
//

#import "GameCardPlacer.h"

@interface RainbowCardPlacer : GameCardPlacer
{
    
}
-(void)ResetCardPosInHand:(PlayerHand*)inHand;

-(void)PositionForCard:(Card*)inCard Hand:(PlayerHand*)inHand inIndex:(int)index x:(float*)outX y:(float*)outY;


@end