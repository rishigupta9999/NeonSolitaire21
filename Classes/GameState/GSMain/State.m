//
//  State.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "State.h"

@implementation State

-(void)Init
{
}

-(void)dealloc
{
    [mParams release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    // No processing in the base class
}

-(void)Draw
{
}

-(void)Startup
{
}

-(void)Resume
{
}

-(void)Suspend
{
}

-(void)Shutdown
{
}

-(void)DrawOrtho
{
}

@end