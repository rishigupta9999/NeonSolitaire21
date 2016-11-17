//
//  DebugCameraState.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "GameState.h"
#import "Button.h"
#import "TouchSystem.h"

@class DebugCamera;

@interface DebugCameraState : GameState<TouchListenerProtocol>
{
    DebugCamera*    mDebugCamera;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;

@end