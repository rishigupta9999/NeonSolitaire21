//
//  GameTripleSwitch.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "GameTripleSwitch.h"
#import "GameObjectManager.h"
#import "Flow.h"
#import "TextureButton.h"

@implementation GameTripleSwitch

-(void)Startup
{
	[super Startup];
}
-(void)Shutdown
{
	[super Shutdown];
}
-(void)Update:(CFTimeInterval)inTimeStep
{
	[super Update:inTimeStep];
	//[mTwentyOneSquaredStateMachine Update:inTimeStep];
}

-(void)Suspend
{
	// Remove non-projected UI elements from screen
	//[ sRun21UI TogglePause:TRUE];
}
-(void)Resume
{
	// Restore projected UI elements from screen
	//[ sRun21UI TogglePause:FALSE];
}

-(void)DrawOrtho
{
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        //[ [Flow GetInstance] ProgressForward ];
    }
}

@end