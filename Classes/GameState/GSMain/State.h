//
//  State.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

@class StateMachine;

@interface State : NSObject
{
	@public
		State*			mParentState;
		StateMachine*	mStateMachine;
        NSObject*       mParams;
}

-(void)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;


@end