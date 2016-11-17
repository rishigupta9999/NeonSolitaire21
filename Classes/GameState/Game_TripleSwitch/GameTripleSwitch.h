//
//  GameTripleSwitch.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "GameState.h"
#import "StateMachine.h"
#import "Button.h"
#import "DebugManager.h"
#import "PlayerHand.h"
#import "CardDefines.h"

@interface GameTripleSwitch : GameState <ButtonListenerProtocol>
{
    				
}

-(void)Startup;
-(void)Shutdown;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Suspend;
-(void)Resume;
-(void)DrawOrtho;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end