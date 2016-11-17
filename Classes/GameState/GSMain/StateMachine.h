//
//  StateMachine.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "State.h"
#import "Queue.h"

typedef struct
{
    State*          mNewState;
    StateMachine*   mStateMachine;
} StateChangeMessage;

@class MessageChannel;

@protocol StateMachinePausable

-(void)PauseProcessing;
-(void)ResumeProcessing;

@end

typedef enum
{
    STATE_MACHINE_STATE_PROCESSING,
    STATE_MACHINE_STATE_SHUTTING_DOWN
} StateMachineState;

@interface StateMachine : NSObject<StateMachinePausable>
{    
    BOOL            mProcessing;
    BOOL            mPaused;
    
    State*          mActiveState;
    Queue*          mOperationQueue;
    
    MessageChannel* mMessageChannel;
    
    BOOL            mVerbose;
    
    NSRecursiveLock*    mLock;
    
    State*              mTruncatedParentState;
    StateMachineState   mStateMachineState;
}

-(StateMachine*)Init;
-(void)Term;
-(void)Update:(CFAbsoluteTime)inTimeStep;
-(void)PauseProcessing;
-(void)ResumeProcessing;

-(void)Push:(State*)inState;
-(void)Push:(State*)inState withParams:(NSObject*)inParams;
-(void)Push:(State*)inState withParams:(NSObject*)inParams truncated:(BOOL)inTruncated;

-(void)ReplaceTop:(State*)inState;
-(void)ReplaceTop:(State*)inState withParams:(NSObject*)inParams;

-(void)Pop;
-(void)PopTruncated:(BOOL)inTruncated;

-(void)ProcessOperationQueue;

-(State*)GetActiveState;
-(void)SetState:(State*)inState;

-(State*)GetActiveStateAfterOperations;
-(State*)FindInstanceInStack:(Class)inClass;

-(MessageChannel*)GetMessageChannel;

-(void)SetVerbose:(BOOL)inVerbose;
-(void)Log:(NSString*)inString data:(void*)inData;

-(void)StartupState:(State*)inNewState;

-(StateMachineState)GetStateMachineState;

@end

typedef enum OperationType
{
	OPERATION_PUSH,
	OPERATION_POP,
	OPERATION_MAX,
    OPERATION_INVALID = OPERATION_MAX
} OperationType;

@interface StateOperation : NSObject
{
	@public
		OperationType   mOperationType;
		NSObject*       mOperationData;
        NSObject*       mOperationData2;
        NSObject*       mOperationData3;
}

-(StateOperation*)Init;

@end