//
//  AnimationDebugState.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "GameState.h"
#import "CameraUVN.h"
#import "StateMachine.h"

#import "Skeleton.h"

#import "Button.h"
#import "Light.h"

@class TextBox;
@class DebugCamera;
@class UIList;
@class AnimationClip;

typedef struct
{
    float   mX;
    float   mY;
    char*   mText;
    u32     mButtonIdentifier;
} ButtonInitParams;

@interface AnimationState : State<ButtonListenerProtocol>
{
}

-(void)Draw;
-(void)DrawOrtho;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugStateMachine : StateMachine<ButtonListenerProtocol>
{
    @public
        CameraUVN*      mAnimCamera;
        Model*          mDebugModel;
        AnimationClip*  mDebugAnimationClip;
        int             mActiveJointIndex;
        
        NSMutableArray* mPersistentButtons;
        
        BOOL            mRotationEnabled;
        float           mRotationAmount;
}

-(AnimationDebugStateMachine*)InitWithModel:(Model*)inModel skeleton:(Skeleton*)inSkeleton;
-(void)dealloc;
-(Skeleton*)GetDebugSkeleton;

-(void)InitPersistentUI;
-(void)SetActiveJointIndex:(int)inJointIndex;
-(Joint*)GetActiveJoint;
-(void)Draw;
-(void)DrawOrtho;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
+(void)CreateButtons:(ButtonInitParams*)inButtonParams numButtons:(int)inNumButtons
                        referenceArray:(NSMutableArray*)inReferenceArray listener:(NSObject<ButtonListenerProtocol>*)inListener;
+(void)RemoveButtons:(NSMutableArray*)inButtonArray;

@end

@interface AnimationDebugChooseModel : AnimationState<ButtonListenerProtocol>
{
    TextBox*        mChooseModelTextBox;
    NSMutableArray* mModelButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugChooseModelAction : AnimationState<ButtonListenerProtocol>
{
    NSMutableArray* mActionButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugChooseSkeleton : AnimationState<ButtonListenerProtocol>
{
    NSMutableArray* mSkeletonButtons;
    TextBox*        mChooseSkeletonTextBox;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)CreateUI;
-(void)TeardownUI;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugChooseSkeletonAction : AnimationState<ButtonListenerProtocol>
{
    NSMutableArray* mSkeletonActionButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)CreateUI;
-(void)TeardownUI;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugChooseJoint : AnimationState<ButtonListenerProtocol>
{
    Button*         mShowAxesButton;
    BOOL            mShowAxes;
    
    UIList*         mJointButtonsList;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugManipulateJoint : AnimationState<ButtonListenerProtocol>
{
    NSMutableArray* mManipulationButtons;
    u32             mActiveButtonIdentifier;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Draw;
-(void)Update:(CFTimeInterval)inTimeStep;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugChooseAnimation : AnimationState<ButtonListenerProtocol>
{
    NSMutableArray* mAnimationButtons;
    TextBox*        mChooseAnimationTextBox;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)CreateUI;
-(void)TeardownUI;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugPlayAnimation : AnimationState<ButtonListenerProtocol>
{
    NSMutableArray* mAnimationPlayButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)CreateUI;
-(void)TeardownUI;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface AnimationDebugFreeCamera : AnimationState<ButtonListenerProtocol>
{
    DebugCamera*    mDebugCamera;
    NSMutableArray* mFreeCameraButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)DrawOrtho;

@end

@interface AnimationDebugState : GameState
{
    Light*      mLight;
    AnimationDebugStateMachine* mAnimationDebugStateMachine;
}

-(void)Startup;
-(void)Shutdown;
-(void)Draw;
-(void)Update:(CFTimeInterval)inTimeStep;

@end