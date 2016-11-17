//
//  LightEditorState.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "GameState.h"
#import "StateMachine.h"
#import "Button.h"

@interface LightingEditorStateMachine : StateMachine
{
    int     mActiveLightIndex;
    BOOL    mVisible;
}

-(void)SetActiveLight:(int)inLightIndex;
-(int)GetActiveLight;

-(void)SetVisible:(int)inVisible;
-(int)GetVisible;

-(LightingEditorStateMachine*)Init;

@end

@interface LightingEditorRootState : State<ButtonListenerProtocol>
{
    NSMutableArray* mLightButtons;
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)Startup;
-(void)Resume;

-(void)Shutdown;
-(void)Suspend;

@end

@interface LightingEditorEditState : State<ButtonListenerProtocol, TouchListenerProtocol>
{
    NSMutableArray* mButtons;
    u32 mActiveButtonIdentifier;
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)Startup;
-(void)Shutdown;

-(void)Update:(CFTimeInterval)inTimeStep;

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;

@end


@interface LightingEditorState : GameState
{
    LightingEditorStateMachine*   mLightingEditorStateMachine;
}

-(void)Startup;
-(void)Shutdown;
-(void)Update:(CFTimeInterval)inTimeStep;

@end