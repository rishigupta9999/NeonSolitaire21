//
//  Stack.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

@interface Stack : NSObject
{
    NSMutableArray*  mArray;
}

-(Stack*)Init;
-(void)dealloc;

-(void)Push:(NSObject*)inObject;
-(NSObject*)Pop;
-(NSObject*)Peek;

-(void)Reverse;

-(unsigned int)GetNumElements;

@end