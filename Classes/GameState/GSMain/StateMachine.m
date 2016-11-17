//
//  StateMachine.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "StateMachine.h"
#import "Queue.h"
#import "Stack.h"
#import "MessageChannel.h"
#import "Event.h"

@implementation StateMachine

-(StateMachine*)Init
{
    mProcessing = FALSE;
    mActiveState = NULL;
    mVerbose = FALSE;
    
    mOperationQueue = [((Queue*)[Queue alloc]) Init];
    
    mMessageChannel = [(MessageChannel*)[MessageChannel alloc] Init];
    
    mTruncatedParentState = NULL;
    
    mLock = [[NSRecursiveLock alloc] init];
    
    mStateMachineState = STATE_MACHINE_STATE_PROCESSING;
	
	return self;
}

-(void)dealloc
{
    [self Term];
    [mLock release];
  
    [mMessageChannel release];
    
    [mOperationQueue release];
    [super dealloc];
}

-(void)Term
{
    [mLock lock];
    
    mStateMachineState = STATE_MACHINE_STATE_SHUTTING_DOWN;
    
    State* curState = mActiveState;
    
    while(curState != NULL)
    {
        [curState Shutdown];
        
        State* parentState = curState->mParentState;
        
        [curState release];
        curState = parentState;
    }
    
    [mOperationQueue release];
    mOperationQueue = NULL;
    
    mActiveState = NULL;
    
    [mLock unlock];
}


-(void)Update:(CFAbsoluteTime)inTimeStep
{
    if (mPaused)
    {
        return;
    }
    
    mProcessing = TRUE;
    [[self GetActiveState] Update:inTimeStep];
    
	mProcessing = FALSE;
    
    // And process the state queue for any transitions that may have occurred during processing
    [self ProcessOperationQueue];
}

-(void)PauseProcessing
{
    mPaused = TRUE;
}

-(void)ResumeProcessing
{
    mPaused = FALSE;
}

-(void)Push:(State*)inState
{
    [self Push:inState withParams:NULL truncated:FALSE];
}

-(void)Push:(State*)inState withParams:(NSObject*)inParams
{
    [self Push:inState withParams:inParams truncated:FALSE];
}

-(void)Push:(State*)inState withParams:(NSObject*)inParams truncated:(BOOL)inTruncated
{
    if (!mProcessing)
    {
        [mLock lock];
        
        mProcessing = TRUE;
        
        [self Log:@"Push" data:inState];
        State* prevActiveState = mActiveState;
            
        mActiveState = inState;
        [self Log:@"Set active state to" data:inState];
        
        [mActiveState Init];

        if (inTruncated)
        {
            prevActiveState = mTruncatedParentState;
            mTruncatedParentState = NULL;
        }

        mActiveState->mParentState = prevActiveState;
        [self Log:@"Set parent state to" data:prevActiveState];
        
        mActiveState->mParams = [inParams retain];
        
        mActiveState->mStateMachine = self;

        if ((prevActiveState != NULL) && (!inTruncated))
        {
            [prevActiveState Suspend];
            [self Log:@"Suspend state" data:prevActiveState];
        }

        [self StartupState:mActiveState];
        [mActiveState Startup];
        
        Message msg;
        msg.mId = EVENT_STATE_STARTED;
        
        StateChangeMessage scMessage;
        scMessage.mNewState = mActiveState;
        scMessage.mStateMachine = self;
        
        msg.mData = &scMessage;
        
        [mMessageChannel BroadcastMessageSync:&msg];
        
        [self Log:@"Startup state" data:mActiveState];
        
        mProcessing = FALSE;
        
        [self ProcessOperationQueue];
        
        [mLock unlock];
    }
    else
    {
        StateOperation* newOp = [(StateOperation*)[StateOperation alloc] Init];
        
        newOp->mOperationType = OPERATION_PUSH;
        newOp->mOperationData = inState;
        newOp->mOperationData2 = [inParams retain];
        newOp->mOperationData3 = [[NSNumber alloc] initWithBool:inTruncated];
                
        [mOperationQueue Enqueue:newOp];
        [self Log:@"Enqueue push for state" data:inState];
    }
}

-(void)ReplaceTop:(State*)inState
{
    [self ReplaceTop:inState withParams:NULL];
}

-(void)ReplaceTop:(State*)inState withParams:(NSObject*)inParams
{
    [self PopTruncated:TRUE];
    [self Push:inState withParams:inParams truncated:TRUE];
}

-(void)Pop
{
    [self PopTruncated:FALSE];
}

-(void)PopTruncated:(BOOL)inTruncated
{
    if (!mProcessing)
    {
        [mLock lock];
        
        mProcessing = TRUE;
        
        [self Log:@"Pop" data:NULL];
        
        if (mActiveState == NULL)
        {
            mActiveState = mTruncatedParentState;
            mTruncatedParentState = NULL;
        }
        
        if (mActiveState != NULL)
        {
            [mActiveState Shutdown];
            [self Log:@"Shutdown state" data:mActiveState];
            
            [mActiveState->mParams release];
            mActiveState->mParams = NULL;
            
            if ((mActiveState->mParentState != NULL) && (!inTruncated))
            {   
                State* prevState = mActiveState;
                
                mActiveState = prevState->mParentState;
                [self Log:@"Setting active state to" data:mActiveState];
                
                [prevState release];
                [self Log:@"Releasing state" data:prevState];
                
                Message msg;
                msg.mId = EVENT_STATE_RESUMED;
                
                StateChangeMessage scMessage;
                scMessage.mNewState = mActiveState;
                scMessage.mStateMachine = self;
                
                msg.mData = &scMessage;
                
                [mMessageChannel BroadcastMessageSync:&msg];

                [mActiveState Resume];
                [self Log:@"Resume state" data:mActiveState];
            }
            else
            {
                mTruncatedParentState = mActiveState->mParentState;
                
                [mActiveState release];
                mActiveState = NULL;
            }
        }
        
        mProcessing = FALSE;
        
        [self ProcessOperationQueue];
        
        [mLock unlock];
    }
    else
    {
        StateOperation* newOp = [(StateOperation*)[StateOperation alloc] Init];
        
        newOp->mOperationType = OPERATION_POP;
        newOp->mOperationData = [[NSNumber alloc] initWithBool:inTruncated];
        
        [mOperationQueue Enqueue:newOp];
        
        [self Log:@"Enqueue Pop" data:NULL];
    }
}

-(void)ProcessOperationQueue
{
    do
    {
        StateOperation* curOp = (StateOperation*)[mOperationQueue Dequeue];
        
        if (curOp == NULL)
        {
            break;
        }
        else
        {
            switch(curOp->mOperationType)
            {
                case OPERATION_PUSH:
                {
                    [self Push:(State*)(curOp->mOperationData) withParams:curOp->mOperationData2 truncated:[(NSNumber*)curOp->mOperationData3 boolValue]];
                    
                    // Push did another retain on this, so we'll get rid of our reference
                    [curOp->mOperationData2 release];
					break;

                }
					
                case OPERATION_POP:
                {
                    [self PopTruncated:[(NSNumber*)curOp->mOperationData boolValue]];
                    [curOp->mOperationData release];
                    break;
                }
					
				default:
				{
					NSAssert(FALSE, @"Unknown State Machine operation.");
					break;
				}
            }
            
            [curOp release];
        }
    }
    while(TRUE);
}

-(State*)GetActiveState
{
    State* retState = NULL;
    
    [mLock lock];
    retState = mActiveState;
    [mLock unlock];
    
	return retState;
}

-(void)SetState:(State*)inState
{
    [mLock lock];
    mActiveState = inState;
    [mLock unlock];
}

-(State*)GetActiveStateAfterOperations
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    State* curState = [self GetActiveState];
    State* retState = NULL;    
    
    Stack* stateStack = [(Stack*)[Stack alloc] Init];
    
    // Put current state stack onto a new stack that we can manipulate without fear
    while(curState != NULL)
    {
        [stateStack Push:curState];
        
        curState = curState->mParentState;
    }
    
    [stateStack Reverse];
        
    int queueSize = [mOperationQueue QueueSize];
    
    // Simulate the operation queue to see what the active state will be once we're finished.
    for (int i = 0; i < queueSize; i++)
    {
        StateOperation* curOp = (StateOperation*)[mOperationQueue PeekAtIndex:i];

        switch(curOp->mOperationType)
        {
            case OPERATION_PUSH:
            {
                [stateStack Push:(State*)(curOp->mOperationData)];
                break;
            }
                
            case OPERATION_POP:
            {
                [stateStack Pop];
                break;
            }
                
            default:
            {
                NSAssert(FALSE, @"Unknown State Machine operation.");
                break;
            }
        }
    }
    
    retState = (State*)[stateStack Peek];
    
    [stateStack release];
    
    [pool drain];
    
    return retState;
}

-(State*)FindInstanceInStack:(Class)inClass
{
    NSAssert([mOperationQueue QueueSize] == 0, @"Operation queue isn't empty.  Maybe we should update this function to search the operation queue?");
    
    State* checkState = [self GetActiveState];
    
    while(checkState != NULL)
    {
        if ([checkState class] == inClass)
        {
            return checkState;
        }
        else
        {
            checkState = checkState->mParentState;
        }
    }
    
    return NULL;
}

-(MessageChannel*)GetMessageChannel
{
    return mMessageChannel;
}

-(void)SetVerbose:(BOOL)inVerbose
{
    mVerbose = inVerbose;
}

-(void)Log:(NSString*)inString data:(void*)inData
{
    if (mVerbose)
    {
        NSLog(@"%@ %p", inString, inData);
    }
}

-(void)StartupState:(State*)inNewState
{
}

-(StateMachineState)GetStateMachineState
{
    return mStateMachineState;
}

@end

@implementation StateOperation

-(StateOperation*)Init
{
    mOperationType = OPERATION_INVALID;
    mOperationData = NULL;
    mOperationData2 = NULL;
    
    return self;
}

@end