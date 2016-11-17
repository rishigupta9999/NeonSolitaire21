//
//  GameState.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameState.h"

@implementation GameState

-(GameState*)Init
{
    NSAssert(mMessageChannel == NULL, @"Init called more than once");
    mMessageChannel = [(MessageChannel*)[MessageChannel alloc] Init];
        
    return self;
}

-(void)dealloc
{
    [mMessageChannel release];
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

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
    Message msg;
    
    msg.mId = inEventId;
    msg.mData = (void*)inData;
    
    [mMessageChannel BroadcastMessageSync:&msg];
}

-(MessageChannel*)GetMessageChannel
{
    return mMessageChannel;
}

-(int)GetLevel
{
    return mLevel;
}

-(GameModeType)GetGameModeType
{
    return mGameModeType;
}

-(void)SetLevel:(int)inLevel
{
    mLevel = inLevel;
}

-(void)SetGameMode:(GameModeType)inGameModeType
{
    mGameModeType = inGameModeType;
}

@end