//
//  CompanionSelect.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "GameState.h"
#import "StateMachine.h"
#import "CompanionManager.h"
#import "Button.h"
#import "GlobalUI.h"

@class NeonButton;
@class TextBox;
@class UIGroup;

typedef enum
{
    COMPANION_SELECT_LOADED,
    COMPANION_SELECT_WAITING_TO_FINISH,
} CompanionSelectLoadState;

typedef struct
{
	ImageWell	*mImage;
	TextBox		*mText;
} ImageTextHolder;

@interface CompanionSelectState : State
{
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;
-(void)InitDialogBaloon:(ImageTextHolder*)inToolTip;
-(void)ClearDialogBaloon:(ImageTextHolder*)inToolTip;
-(void)InitToolTip:(ImageTextHolder*)inToolTip WithDialog:(NSString*)inStr;
-(void)ClearToolTip:(ImageTextHolder*)inToolTip;

@end


@interface CompanionSelectRootState : CompanionSelectState
{
    ImageTextHolder	mToolTip_Stage1;
    float			mHackTime;
    BOOL			mHackAnimationStarted;
}

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;
-(void)Update:(CFTimeInterval)inTimeStep;

@end


@interface CompanionSelectTransitionToChangeCompanion : CompanionSelectState
{
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;

@end


@interface CompanionSelectTransitionFromChangeCompanion : CompanionSelectState
{
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;

@end

@interface CompanionSelectAnimateOutCompanion : CompanionSelectState
{
    float   mElapsedTime;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;

@end

@interface CompanionSelectAnimateInCompanion : CompanionSelectState
{
    float   mElapsedTime;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;

@end


@interface CompanionSelectChangeCompanion : CompanionSelectState<ButtonListenerProtocol>
{
    ImageTextHolder	mToolTip_Stage2;
    CompanionID		mNewCompanionId;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)CompanionButtonEvent:(ButtonEvent)inEvent Button:(NeonButton*)inButton;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end


@interface CompanionSelectStateMachine : StateMachine<ButtonListenerProtocol>
{
    @public
        NeonButton*					mLeftButton;
        NeonButton*					mRightButton;
        NeonButton*					mBackButton;
        NeonButton*					mEmptyButton[COMPANION_POSITION_CHANGEABLE_NUM];
		NeonButton*					mCompanionButton[COMPANION_POSITION_MAX];

        ImageWell*					mCompanionAbility[CompID_MAX];
        
        UIGroup*                    mUIGroup;
        CompanionSelectLoadState    mCompanionSelectState;
        CompanionPosition           mEditCompanion;
        CompanionID                 mNewCompanionId;
		BOOL						mCompanionAlreadyChosen;
        
        NSMutableArray*             mCompanionButtons;
}

-(CompanionSelectStateMachine*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)SetActiveCompanionButton:(CompanionPosition)inPosition;
-(NeonButton*)CreateCompanionButton:(CompanionID)inCompanionId;
-(void)SetEditCompanion:(CompanionPosition)inPosition;

-(void)InitBackButton;
-(void)UpdateCompanionButtonVisibility:(Vector3*)inStartPosition animationTime:(float)inAnimationTime;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;
-(BOOL)CompanionIdSwitchable:(CompanionID)inCompanionId;

-(void)UpdateCompanionAbilitySeats;


@end


@interface CompanionSelect : GameState
{
    CompanionSelectStateMachine* mCompanionSelectStateMachine;
}

-(void)Startup;
-(void)Resume;

-(void)Suspend;
-(void)Shutdown;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)ProcessEvent:(EventId)inEventId withData:(void*)inData;

@end