//
//  CompanionEntity.h
//  Neon21
//
//  Copyright 2010 Neon Games. All rights reserved.
//

#import "GameObject.h"
#import "CompanionManager.h"
#import "MessageChannel.h"

@class AnimationController;
@class AnimationTransformerModifierList;

typedef enum
{
    COMPANION_ANIMATION_IDLE,
    COMPANION_ANIMATION_FAT_IDLE,
    COMPANION_ANIMATION_HAPPY,
    COMPANION_ANIMATION_BIG_HAPPY,
    COMPANION_ANIMATION_SAD,
    COMPANION_ANIMATION_WALK,
    COMPANION_ANIMATION_NUM,
    COMPANION_ANIMATION_INVALID = COMPANION_ANIMATION_NUM
} CompanionAnimationType;

typedef enum
{
    COMPANION_ACTION_WALK_FROM_TABLE_LEFT,
    COMPANION_ACTION_WALK_FROM_TABLE_RIGHT,
    COMPANION_ACTION_WALK_TO_TABLE_LEFT,
    COMPANION_ACTION_WALK_TO_TABLE_RIGHT,
	COMPANION_ACTION_ABILITY
} CompanionAction;

typedef enum
{
    COMPANION_STATE_IDLE,
    COMPANION_STATE_OTHER,
    COMPANION_STATE_NUM,
    COMPANION_STATE_INVALID = COMPANION_STATE_NUM
} CompanionState;

typedef enum
{
    COMPANION_GLOW_OFF,
    COMPANION_GLOW_TRANSITION_ON,
    COMPANION_GLOW_TRANSITION_OFF,
    COMPANION_GLOW_ON
} CompanionGlowState;

typedef enum
{
    COMPANION_PULSE_OFF,
    COMPANION_PULSE_ON
} CompanionPulseState;

@interface CompanionEntity : GameObject<MessageChannelListener>
{
    @public
        CompanionID             mCompanionID;
    @protected
        CompanionPosition       mCompanionPosition;
        AnimationController*    mAnimationController;
        CompanionState          mCompanionState;
        
        CompanionGlowState      mGlowState;
        Path*                   mGlowPath;
        
        CompanionPulseState     mPulseState;
        int                     mNumPulses;
}

-(CompanionEntity*)InitWithCompanionID:(CompanionID)inCompanionID position:(CompanionPosition)inPosition;
-(void)ReinitWithPosition:(CompanionPosition)inPosition;
-(void)dealloc;
-(void)Remove;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)InitAnimation;

-(void)PerformAction:(CompanionAction)inAction;
-(AnimationTransformerModifierList*)BuildTransformerParams;

-(void)SetGlowEnabled:(BOOL)inEnabled;
-(void)Pulse:(int)inNumPulses;
-(CompanionPulseState)GetPulseState;

-(NSString*)GetAnimationFilename:(CompanionAnimationType)inAnimationType;
-(NSString*)GetAbilityAnimationFilename;

-(void)ProcessMessage:(Message*)inMsg;

-(CompanionState)GetCompanionState;

-(void)SetupRenderState:(RenderStateParams*)inRenderStateParams;
-(void)TeardownRenderState:(RenderStateParams*)inRenderStateParams;

@end
