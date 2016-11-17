//
//  Rainbownvironment.m
//  Neon21
//
//  Copyright Neon Games 2012. All rights reserved.
//

#import "RainbowEnvironment.h"
#import "GameStateMgr.h"

#import "MiniGameTableEntity.h"

@implementation RainbowEnvironment

-(RainbowEnvironment*)Init
{
	[ super Init];
    GameState* curState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];

    [[curState GetMessageChannel] RemoveListener:mCardPlacer];
    [mCardPlacer release];
    mCardPlacer = [(RainbowCardPlacer*) [RainbowCardPlacer alloc] InitWithTable:mTableEntity];
    
	return self;
}

@end