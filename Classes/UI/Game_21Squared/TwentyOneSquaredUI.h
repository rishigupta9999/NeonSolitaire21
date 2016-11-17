//
//  TwentyOneSquaredUI.h
//  Neon Engine
//
//  Copyright Neon Games LLC - 2011


// Imports
#import "GlobalUI.h"

@interface TwentyOneSquaredUI : GlobalUI
{
	NeonButton*			mDebugButton;
	NeonButton*			mPauseButton;
}

-(TwentyOneSquaredUI*)Init;
-(void)InitDebugButtons;
-(void)dealloc;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
-(void)TogglePause:(BOOL)bSuspend;

@end