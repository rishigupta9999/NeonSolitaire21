//
//  Ticker.m
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.
//

#import "Ticker.h"

@interface TickerEntry : NSObject
{
    NSString*               mString;
    TickerEntryOrientation  mOrientation;
}

@end

@interface TickerParams : NSObject
{
    @public
        UIGroup*    mUIGroup;
}

@end

@implementation TickerEntry
@end

@implementation TickerParams
@end

@implementation Ticker

-(Ticker*)InitWithParams:(TickerParams*)inParams
{
    [super InitWithUIGroup:inParams->mUIGroup];
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end