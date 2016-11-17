//
//  Stack.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Stack.h"

#define STACK_INITIAL_CAPACITY  (5)

@implementation Stack

-(Stack*)Init
{
    mArray = [[NSMutableArray alloc] initWithCapacity:STACK_INITIAL_CAPACITY];
    
    return self;
}

-(void)dealloc
{
    [mArray release];
    
    [super dealloc];
}

-(void)Push:(NSObject*)inObject
{
    [mArray addObject:inObject];
}

-(NSObject*)Peek
{
    return [mArray lastObject];
}

-(NSObject*)Pop
{
    NSObject* retObject = [mArray lastObject];
    
    [retObject retain];
    [retObject autorelease];
    
    if ([mArray count] > 0)
    {
        [mArray removeLastObject];
    }
    
    return retObject;
}

-(unsigned int)GetNumElements
{
    return [mArray count];
}

-(void)Reverse
{
    int size = [mArray count];
    
    for (int i = 0; i < (size / 2); i++)
    {
        int srcIndex = i;
        int destIndex = size - 1 - i;
        
        NSObject* src = [mArray objectAtIndex:srcIndex];
        NSObject* dest = [mArray objectAtIndex:destIndex];
        
        [src retain];
        [dest retain];
        
        [mArray replaceObjectAtIndex:srcIndex withObject:dest];
        [mArray replaceObjectAtIndex:destIndex withObject:src];
        
        [src release];
        [dest release];
    }
}

@end