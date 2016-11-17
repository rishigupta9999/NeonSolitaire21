//
//  Ticker.h
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.
//

#import "UIObject.h"

typedef enum
{
    TICKER_ENTRY_ORIENTATION_HORIZONTAL,
    TICKER_ENTRY_ORIENTATION_VERTICAL
} TickerEntryOrientation;

@class TickerParams;

@interface Ticker : UIObject
{
}

-(Ticker*)InitWithParams:(TickerParams*)inParams;
-(void)dealloc;

@end