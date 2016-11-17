//
//  GameStateMgr.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameState.h"
#import "Queue.h"
#import "StateMachine.h"
#import "Event.h"

@interface GameStateMgr : StateMachine
{
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(GameStateMgr*)GetInstance;

-(void)Init;
-(void)Update:(CFAbsoluteTime)inTimeStep;
-(void)Draw;
-(void)DrawOrtho;

-(void)SendEvent:(EventId)inEventId withData:(void*)inData;

-(void)StartupState:(State*)inNewState;

@end
