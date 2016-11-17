//
//  Queue.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Queue.h"

@implementation Queue

-(Queue*)Init
{
    mArray = [[NSMutableArray alloc] initWithCapacity:5];
	
	return self;
}

-(void)dealloc
{    
    [mArray release];
    
    [super dealloc];
}

-(void)Enqueue:(NSObject*)inObject
{
    [mArray addObject:inObject];
}

-(NSObject*)Dequeue
{
    NSObject* retVal = NULL;
	
	if ([mArray count] > 0)
	{
		retVal = [mArray objectAtIndex:0];
		
		if (retVal != NULL)
		{
            [retVal retain];
			[mArray removeObjectAtIndex:0];
            
            [retVal autorelease];
		}
	}
    
    return retVal;
}

-(NSObject*)PeekAtIndex:(int)inIndex
{
    return [mArray objectAtIndex:inIndex];
}

-(u32)QueueSize
{
    return [mArray count];
}

-(void)Clear
{
    [mArray removeAllObjects];
}

@end