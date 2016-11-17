//
//  GameState.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "State.h"
#import "Event.h"
#import "MessageChannel.h"
#import "FlowTypes.h"

@interface GameState : State
{
    MessageChannel* mMessageChannel;
    
    int             mLevel;
    GameModeType    mGameModeType;
}

-(GameState*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;
-(void)DrawOrtho;

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;

-(MessageChannel*)GetMessageChannel;

-(int)GetLevel;
-(GameModeType)GetGameModeType;

-(void)SetLevel:(int)inLevel;
-(void)SetGameMode:(GameModeType)inGameModeType;

@end