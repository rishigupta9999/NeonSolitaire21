//
//  Queue.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

@interface Queue : NSObject
{
    NSMutableArray*  mArray;
}

-(Queue*)Init;
-(void)dealloc;

-(void)Enqueue:(NSObject*)inObject;
-(NSObject*)Dequeue;

-(NSObject*)PeekAtIndex:(int)inIndex;
-(u32)QueueSize;

-(void)Clear;

@end