//
//  GameStateMgr.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameStateMgr.h"
#import "Queue.h"
#import "Flow.h"

@implementation GameStateMgr

static GameStateMgr* sInstance = NULL;

-(void)Init
{
	[super Init];
}

+(void)CreateInstance
{
    sInstance = [GameStateMgr alloc];
    
    [sInstance Init];
}

+(void)DestroyInstance
{
    [sInstance release];
    
    sInstance = NULL;
}

+(GameStateMgr*)GetInstance
{
    return sInstance;
}

-(void)Update:(CFAbsoluteTime)inTimeStep
{
	[super Update:inTimeStep];
}

-(void)Draw
{
    [(GameState*)mActiveState Draw];
}

-(void)DrawOrtho
{
	[(GameState*)mActiveState DrawOrtho];
}

-(void)SendEvent:(EventId)inEventId withData:(void*)inData
{
    [(GameState*)mActiveState ProcessEvent:inEventId withData:inData];
}

-(void)StartupState:(State*)inNewState
{
    [(GameState*)inNewState SetGameMode:[[Flow GetInstance] GetGameMode]];
    [(GameState*)inNewState SetLevel:[[Flow GetInstance] GetLevel]];
}

@end
