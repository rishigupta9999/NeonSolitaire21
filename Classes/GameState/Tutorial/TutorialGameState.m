//
//  TutorialGameState.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "TutorialGameState.h"
#import "Flow.h"
#import "TutorialScript.h"
#import "CardManager.h"
#import "StingerSpawner.h"
#import "CompanionManager.h"
#import "Companion.h"
#import "CompanionEntity.h"
#import "LevelDefinitions.h"
#import "TutorialCameraState.h"
#import "CameraStateMgr.h"
#import "NeonSpinner.h"
#import "GameObjectBatch.h"
#import "UIGroup.h"
#import "Run21DuringPlayCamera.h"
#import "GameStateMgr.h"
#import "InAppPurchaseManager.h"

#define UNINITIALIZED_PHASE     (-1)
#define COMPANION_NUM_PULSES    (5)

#define TUTORIAL_VERBOSE (0)

@implementation TutorialGameState

-(void)Startup
{
    [super Startup];
    
    mStingerSpawner				= NULL;

    TutorialScript* newScript = [[[Flow GetInstance] GetLevelDefinitions] GetTutorialScript];
    [self InitFromTutorialScript:newScript];
}

-(void)Shutdown
{
    [mUIObjects release];
    
    for (NeonSpinner* curSpinner in mNeonSpinners)
    {
        [curSpinner Remove];
        [mSpinnerUIGroup removeObject:curSpinner];
    }
    
    [mNeonSpinners release];
    
    [[GameObjectManager GetInstance] Remove:mSpinnerUIGroup];

	if (mStingerSpawner != NULL)
	{
		[[GameObjectManager GetInstance] Remove:mStingerSpawner];
        [mStingerSpawner Remove];
    }
    
    // TextureAtlases don't retain the textures they use.  This texture was retained by [NeonSpinner CreateTextureAtlas] so needs to be released.
    Texture* texture = [mSpinnerAtlas GetTexture:0];
    [texture release];
    
    [mSpinnerAtlas release];
	
    [super Shutdown];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ([[InAppPurchaseManager GetInstance] GetIAPState] == IAP_STATE_PENDING)
    {
        return;
    }
    
    if (mTutorialPauseProcessingCount == 0)
    {
        switch(mTutorialGameStateStatus)
        {
            case TUTORIAL_GAME_STATE_DEALER_DIALOG:
            {
                mTutorialGameStateStatus = TUTORIAL_GAME_STATE_NORMAL;
                [self LoadNextTutorialPhase];
                
                break;
            }
            
            case TUTORIAL_GAME_STATE_TRIGGER_WAIT:
            {
                TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

#if TUTORIAL_VERBOSE                
                NSLog(@"Waiting on trigger %@", phaseInfo->mTriggerState);
#endif

                BOOL triggerHit = [mTriggerEvaluator TriggerCondition:phaseInfo->mTriggerState];
                
                if ((triggerHit) && (!mTriggerWasHit))
                {
#if TUTORIAL_VERBOSE
                    NSLog(@"Trigger hit");
#endif
                    mTriggerWasHit = TRUE;
                    mTriggerCount++;
                    
                    if (mTriggerCount >= phaseInfo->mTriggerCount)
                    {
                        [self EvaluatePhase];
                        mTutorialGameStateStatus = TUTORIAL_GAME_STATE_NORMAL;
                    }
                }
                else if (!triggerHit)
                {
                    if (mTriggerWasHit)
                    {
                        mTriggerWasHit = FALSE;
                    }
                }
                
                break;
            }
            
            case TUTORIAL_GAME_STATE_CAMERA_WAIT:
            {
                TutorialCameraState* cameraState = (TutorialCameraState*)[[CameraStateMgr GetInstance] GetActiveState];
                
                if ([cameraState GetFinished])
                {
                    [self LoadNextTutorialPhase];
                }
                
                break;
            }
            
            default:
            {
                [self LoadNextTutorialPhase];
                break;
            }
        }
    }
    
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];
    
    if ([phaseInfo HasSpinners])
    {
        BOOL evaluateSpinner = TRUE;

        CameraState* activeCamera = [[CameraStateMgr GetInstance] GetActiveState];
        
        if ([activeCamera class] == [TutorialCameraState class])
        {
            TutorialCameraState* tutorialCameraState = (TutorialCameraState*)activeCamera;
            
            if (![tutorialCameraState GetFinished])
            {
                evaluateSpinner = FALSE;
            }
        }

        if (evaluateSpinner)
        {
            [self EvaluateSpinner];
        }
    }
    
    switch(mTutorialGameStatePulse)
    {
        case TUTORIAL_GAME_STATE_PULSE_ON:
        {
            CompanionEntity* leftEntity = [[CompanionManager GetInstance] GetCompanionForPosition:COMPANION_POSITION_LEFT]->mEntity;
            
            if ([leftEntity GetPulseState] == COMPANION_PULSE_OFF)
            {
                mTutorialGameStatePulse = TUTORIAL_GAME_STATE_PULSE_OFF;
                mTutorialPauseProcessingCount--;
            }
            
            break;
        }
    }
    
    switch([mStingerSpawner GetDealerDialogueState])
    {
        case DEALER_DIALOGUE_STATE_MAINTAIN:
        {
            if (mUINeedsEvaluating)
            {
                [self EvaluateUI];
                mUINeedsEvaluating = FALSE;
            }
        }
    }
}

-(void)InitFromTutorialScript:(TutorialScript*)inTutorialScript
{
    mTutorialScript             = inTutorialScript;
    
    mUIObjects					= NULL;
    mCurrentPhase				= UNINITIALIZED_PHASE;
    mTutorialGameStateStatus	= TUTORIAL_GAME_STATE_NORMAL;
    
    mTriggerEvaluator			= NULL;
    mTriggerCount               = 0;
    mTriggerWasHit              = FALSE;
    
    mTutorialGameStatePulse		= TUTORIAL_GAME_STATE_PULSE_OFF;
    
    mTutorialPauseProcessingCount = 0;
	mTerminateInitialize		= FALSE;
	mTerminateInProgress		= FALSE;
    
    mUINeedsEvaluating          = FALSE;
    mSpinnerNeedsEvaluating     = FALSE;
    
    if (mTutorialScript != NULL)
    {
        mNeonSpinners = [[NSMutableArray alloc] init];
        
        GameObjectBatchParams uiGroupParams;
        [GameObjectBatch InitDefaultParams:&uiGroupParams];
        
        mSpinnerUIGroup = [[UIGroup alloc] InitWithParams:&uiGroupParams];
        mSpinnerAtlas = [NeonSpinner CreateTextureAtlas];
        
        [mSpinnerUIGroup SetTextureAtlas:mSpinnerAtlas];
        
        [[GameObjectManager GetInstance] Add:mSpinnerUIGroup];
        [mSpinnerUIGroup release];
        
        mTutorialStatus = TUTORIAL_STATUS_RUNNING;
    }
    else
    {
        mTutorialStatus = TUTORIAL_STATUS_COMPLETE;
    }
}

-(void)RegisterUIObjects:(NSMutableArray*)inUIObjects
{
    mUIObjects = [inUIObjects retain];
}

-(void)ReleaseUIObjects
{
    [mUIObjects release];
    mUIObjects = NULL;
}

-(void)BeginTutorials
{
    [self LoadNextTutorialPhase];
}

-(void)LoadNextTutorialPhase
{
    if (mTutorialScript == NULL || mTerminateInitialize || ([mTutorialScript GetNumPhases] == 0) || ((mCurrentPhase > [mTutorialScript GetNumPhases]) && (mTutorialScript.Indeterminate)))
    {
        return;
    }
    
    // If we're pulsing companions, don't load the next tutorial phase yet
    if (mTutorialGameStatePulse == TUTORIAL_GAME_STATE_PULSE_ON)
    {
        return;
    }
    
    mCurrentPhase++;
    
    [[NeonMetrics GetInstance] logEvent:[NSString stringWithFormat:@"Start Tutorial Phase %d", mCurrentPhase] withParameters:NULL type:NEON_METRIC_TYPE_KISS];
    
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];
    
    if (phaseInfo == NULL)
    {
        [self TutorialComplete];
    }
    
    [self CleanupTutorialPhase:FALSE];
    
    if ((mTutorialScript.Indeterminate) && (phaseInfo == NULL))
    {
        return;
    }
    
    if (phaseInfo->mTriggerState == NULL)
    {
        // If there's no trigger, then we're just waiting for the dealer dialog to go away
        mTutorialGameStateStatus = TUTORIAL_GAME_STATE_DEALER_DIALOG;

        [self EvaluatePhase];
    }
    else
    {
        NSAssert(mTriggerEvaluator != NULL, @"Trigger condition specified, but we have no TriggerEvaulator");
        mTutorialGameStateStatus = TUTORIAL_GAME_STATE_TRIGGER_WAIT;
        
        mTriggerWasHit = FALSE;
        mTriggerCount = 0;
    }
}

-(void)CleanupTutorialPhase:(BOOL)inForceTerminate
{
    for (NeonSpinner* curSpinner in mNeonSpinners)
    {
        [curSpinner Remove];
        [mSpinnerUIGroup removeObject:curSpinner];
    }
    
    [self EvaluateSpinnerRestore];
    [self EvaluateCameraRestore:inForceTerminate];

}

-(void)EndTutorialPhase
{
}

-(void)SkipTutorial
{
    mCurrentPhase = [mTutorialScript->mPhaseInfo count];
    mTutorialGameStateStatus = TUTORIAL_GAME_STATE_NORMAL;
    
    [self CleanupTutorialPhase:TRUE];
    [self TutorialComplete];
}

-(void)SetStingerSpawner:(StingerSpawner*)inStingerSpawner
{
    if (mStingerSpawner != NULL)
    {
        [[GameObjectManager GetInstance] Remove:inStingerSpawner];
    }
    
    StingerSpawner* spawner = inStingerSpawner;
    
    if (inStingerSpawner == NULL)
    {
        StingerSpawnerParams params;
                
        [StingerSpawner InitDefaultParams:&params];
        
        params.mStingerSpawnerMode = STINGERSPAWNER_MODE_DEALERDIALOG;
                
        spawner = [[StingerSpawner alloc] InitWithParams:&params];
    }

    mStingerSpawner = spawner;
    
    [[GameObjectManager GetInstance] Add:spawner];
    [spawner release];
}

-(void)SetTriggerEvaluator:(id<TriggerEvaluator>)inTriggerEvaluator
{
    mTriggerEvaluator = inTriggerEvaluator;
}

-(void)EvaluatePhase
{
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

    if (!mTutorialScript.EnableUI)
    {
        if (phaseInfo->mDialogueKey == NULL)
        {
            [self EvaluateUI];
        }
        else
        {
            for (UIObject* curObject in mUIObjects)
            {
                [self DisableTutorialUIObject:curObject];
            }
            
            mUINeedsEvaluating = TRUE;
        }
    }
    
    [self EvaluateDialogue];
    [self EvaluateCamera];

    mSpinnerNeedsEvaluating = TRUE;
    
    [[GameStateMgr GetInstance] SendEvent:EVENT_TUTORIAL_EVALUATE_PHASE withData:NULL];
}

-(void)EvaluateUI
{
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

    if (phaseInfo->mButtonIdentifier != NULL)
    {
        for (UIObject* curObject in mUIObjects)
        {
            if ( (phaseInfo->mButtonIdentifier != NULL) && 
                 ([[curObject GetStringIdentifier] compare:phaseInfo->mButtonIdentifier] == NSOrderedSame) )
            {
                [self EnableTutorialUIObject:curObject];
            }
            else
            {
                [self DisableTutorialUIObject:curObject];
            }
        }
    }
}

-(void)EvaluateDialogue
{
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

    if (phaseInfo->mDialogueKey != NULL)
    {
        NSString* dialogueString[1];
        
        dialogueString[0] = NSLocalizedString(phaseInfo->mDialogueKey, NULL);
        
        NSAssert(mStingerSpawner != NULL, @"We have dialogue events, but no StingerSpawner");
        
        StingerSpawnerDealerDialogueParams params;
        
        [StingerSpawner InitDefaultDealerDialogueParams:&params];
        
        params.mStrings = dialogueString;
        params.mNumStrings = 1;
        params.mCompanionPosition = phaseInfo->mVoicePosition;
        params.mPausable = self;
        CloneVec2(&phaseInfo->mDialogueOffset, &params.mRenderOffset);
        params.mFontSize = phaseInfo->mDialogueFontSize;
        params.mFontName = phaseInfo->mDialogueFontName;
        params.mFontColor = phaseInfo->mDialogueFontColor;
        params.mFontAlignment = phaseInfo->mDialogueFontAlignment;
        
        // If there's a button associated with this phase, then the stinger isn't a "Tap to Continue" stinger.
        params.mClickToContinue = (phaseInfo->mButtonIdentifier == NULL) && (!phaseInfo.AnyButton);
        
        [mStingerSpawner SpawnDealerDialogClick:&params];
    }
}

-(void)EvaluateCamera
{
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

    if (phaseInfo->mCameraPositionOverride || phaseInfo->mCameraLookAtOverride || phaseInfo->mCameraFovOverride)
    {
        CameraState* activeCamera = [[CameraStateMgr GetInstance] GetActiveState];
        
        if ([activeCamera class] == [TutorialCameraState class])
        {
            TutorialCameraState* tutorialActiveCamera = (TutorialCameraState*)activeCamera;
            
            if (phaseInfo->mCameraFovOverride)
            {
                [tutorialActiveCamera SetFov:phaseInfo->mCameraFov time:1.0f];
            }
            
            if (phaseInfo->mCameraLookAtOverride)
            {
                [tutorialActiveCamera SetLookAt:&phaseInfo->mCameraLookAt time:1.0f];
            }
            
            if (phaseInfo->mCameraPositionOverride)
            {
                [tutorialActiveCamera SetPosition:&phaseInfo->mCameraPosition time:1.0f];
            }
            
            mTutorialGameStateStatus = TUTORIAL_GAME_STATE_CAMERA_WAIT;
        }
        else
        {
            TutorialCameraState* tutorialCameraState = [TutorialCameraState alloc];
            TutorialCameraStateParams* params = [(TutorialCameraStateParams*)[TutorialCameraStateParams alloc] Init];
            
            CloneVec3(&phaseInfo->mCameraPosition, &params->mPosition);
            CloneVec3(&phaseInfo->mCameraLookAt, &params->mLookAt);
            params->mFov = phaseInfo->mCameraFov;
            
            [[CameraStateMgr GetInstance] Push:tutorialCameraState withParams:params];
            [params release];
        }
    }
}

-(void)EvaluateSpinner
{
    if (mSpinnerNeedsEvaluating)
    {
        TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

        if ([phaseInfo HasSpinners])
        {
            int numSpinners = [phaseInfo GetNumSpinners];
            
            for (int spinnerIndex = 0; spinnerIndex < numSpinners; spinnerIndex++)
            {
                NeonSpinner* newSpinner = [self CreateSpinner];
                
                SpinnerEntry* spinnerEntry = [phaseInfo GetSpinnerEntry:spinnerIndex];
                [newSpinner SetPositionX:spinnerEntry->mPosition.mVector[x] Y:spinnerEntry->mPosition.mVector[y] Z:0.0];
                [newSpinner SetSizeWidth:spinnerEntry->mSize.mVector[x] height:spinnerEntry->mSize.mVector[y]];
                
                [newSpinner SetVisible:TRUE];
            }
        }
        
        mSpinnerNeedsEvaluating = FALSE;
    }
}

-(void)EvaluateCameraRestore:(BOOL)inForce
{
    TutorialPhaseInfo* phaseInfo = [mTutorialScript GetTutorialPhase:mCurrentPhase];

    if (((phaseInfo != NULL) && (phaseInfo->mRestoreCamera)) || (inForce))
    {
        [[CameraStateMgr GetInstance] Pop]; // Get rid of tutorial camera
        [[CameraStateMgr GetInstance] Pop]; // Get rid of intro camera
        
        Run21DuringPlayCameraParams* duringPlayParams = [[Run21DuringPlayCameraParams alloc] init];
        duringPlayParams.InterpolateFromPrevious = TRUE;
        
        [[CameraStateMgr GetInstance] Push:[Run21DuringPlayCamera alloc] withParams:duringPlayParams];
        [duringPlayParams release];
    }
}

-(void)EvaluateSpinnerRestore
{
    [mNeonSpinners removeAllObjects];
}

-(void)TutorialComplete
{
    mTutorialStatus = TUTORIAL_STATUS_COMPLETE;

	// It is the parent's responsibility to:
	// 1) Set mTerminateInProgress to TRUE on detection of this flag
	// 2) Send the EVENT_TUTORIAL_COMPLETED to the GameStateMgr for stinger display/audio
	// 3) Handle any camera/timing events appropriate to the game type and board layout
	// 4) Upon completion of the above events, [ [ Flow GetInstance ] ProgressForward ];
	
	mTerminateInitialize = TRUE;	// The tutorial has completed and will return early when parsing states due to this flag.
}

-(void)EnableTutorialUIObject:(UIObject*)inObject
{
    [inObject Enable];
}

-(void)DisableTutorialUIObject:(UIObject*)inObject
{
    [inObject Disable];
}

-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData
{
    switch(inEventId)
    {
        case EVENT_ANY_BUTTON_DOWN:
        {            
            [mStingerSpawner TerminateDealerStingerSync];
            
            for (NeonSpinner* curSpinner in mNeonSpinners)
            {
                [curSpinner SetVisible:FALSE];
            }
            
            break;
        }
    }
    
    [super ProcessEvent:inEventId withData:inData];
}

-(void)PauseProcessing
{
    mTutorialPauseProcessingCount++;
#if TUTORIAL_VERBOSE
    NSLog(@"Pause processing, count is %d\n", mTutorialPauseProcessingCount);
#endif
}

-(void)ResumeProcessing
{
    mTutorialPauseProcessingCount--;
#if TUTORIAL_VERBOSE
    NSLog(@"Resume processing, count is %d\n", mTutorialPauseProcessingCount);
#endif
}

-(NeonSpinner*)CreateSpinner
{
    NeonSpinnerParams   spinnerParams;
    
    [NeonSpinner InitDefaultParams:&spinnerParams];
    
    spinnerParams.mUIGroup = mSpinnerUIGroup;
    
    NeonSpinner* newSpinner = [[NeonSpinner alloc] initWithParams:&spinnerParams];
    [newSpinner release];

    [newSpinner SetVisible:FALSE];
    
    [mNeonSpinners addObject:newSpinner];
    
    return newSpinner;
}

@end