//
//  TutorialGameState.m
//  Neon21
//
//  Copyright Neon Games 2012. All rights reserved.
//

#import "GameState.h"
#import "StateMachine.h"

@class TutorialScript;
@class StingerSpawner;
@class UIObject;
@class NeonSpinner;
@class UIGroup;
@class TextureAtlas;

typedef enum
{
    TUTORIAL_GAME_STATE_NORMAL,
    TUTORIAL_GAME_STATE_DEALER_DIALOG,
    TUTORIAL_GAME_STATE_TRIGGER_WAIT,
    TUTORIAL_GAME_STATE_CAMERA_WAIT
} TutorialGameStateStatus;

typedef enum
{
    TUTORIAL_GAME_STATE_PULSE_OFF,
    TUTORIAL_GAME_STATE_PULSE_WAITING,
    TUTORIAL_GAME_STATE_PULSE_ON
} TutorialGameStatePulse;

typedef enum
{
    TUTORIAL_STATUS_RUNNING,
    TUTORIAL_STATUS_COMPLETE
} TutorialStatus;

@protocol TriggerEvaluator

-(BOOL)TriggerCondition:(NSString*)inTrigger;

@end


@interface TutorialGameState : GameState<StateMachinePausable>
{
    @public
        TutorialScript*         mTutorialScript;
        NSMutableArray*         mUIObjects;
        
        s32                     mCurrentPhase;
        StingerSpawner*         mStingerSpawner;
        
        TutorialGameStateStatus mTutorialGameStateStatus;
        
        id<TriggerEvaluator>    mTriggerEvaluator;
        BOOL                    mTriggerWasHit;
        int                     mTriggerCount;
        
        TutorialGameStatePulse  mTutorialGameStatePulse;
		BOOL					mTerminateInitialize;		// Set by TutorialGameState
		BOOL					mTerminateInProgress;		// Set by Parent Game State
        
        int                     mTutorialPauseProcessingCount;
        
        BOOL                    mUINeedsEvaluating;
        BOOL                    mSpinnerNeedsEvaluating;
    
        NSMutableArray*         mNeonSpinners;
        UIGroup*                mSpinnerUIGroup;
        TextureAtlas*           mSpinnerAtlas;
    
        TutorialStatus          mTutorialStatus;
}

-(void)Startup;
-(void)Shutdown;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)InitFromTutorialScript:(TutorialScript*)inTutorialScript;

-(void)RegisterUIObjects:(NSMutableArray*)inUIObjects;
-(void)ReleaseUIObjects;

-(void)BeginTutorials;
-(void)LoadNextTutorialPhase;
-(void)CleanupTutorialPhase:(BOOL)inForceTerminate;
-(void)SkipTutorial;

-(void)SetStingerSpawner:(StingerSpawner*)inStingerSpawner;
-(void)SetTriggerEvaluator:(id<TriggerEvaluator>)inTriggerEvaluator;

-(void)EvaluatePhase;
-(void)EvaluateUI;
-(void)EvaluateDialogue;
-(void)EvaluateCamera;
-(void)EvaluateSpinner;

-(void)EvaluateCameraRestore:(BOOL)inForce;
-(void)EvaluateSpinnerRestore;

-(void)TutorialComplete;

-(void)EnableTutorialUIObject:(UIObject*)inObject;
-(void)DisableTutorialUIObject:(UIObject*)inObject;

-(void)PauseProcessing;
-(void)ResumeProcessing;

-(NeonSpinner*)CreateSpinner;

@end