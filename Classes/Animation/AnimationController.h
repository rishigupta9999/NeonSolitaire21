//
//  AnimationController.h
//  Neon21
//
//  Copyright 2010 Neon Games. All rights reserved.
//

@class AnimationClip;
@class Skeleton;
@class Stack;

typedef enum
{
    ANIMATION_CONTROLLER_BLEND_LEFT,
    ANIMATION_CONTROLLER_BLEND_RIGHT,
    ANIMATION_CONTROLLER_BLEND_MIX,
    ANIMATION_CONTROLLER_BLEND_INVALID
} AnimationControllerBlendMode;

typedef struct
{
    float   mTransitionToTime;      // Time to transition to the newly pushed animation
    float   mTransitionFromTime;    // Time to transition back from the newly pushed animation (when we eventually pop it)
    BOOL    mLoop;                  // Whether the animation should loop
    BOOL    mLiveBlend;             // Whether we should transition out of the animation before it's ended.  The time
                                    // the transition will begin is the clip's end time minus mTransitionFromTime.
} AnimationTransitionParams;

@interface AnimationStackEntry : NSObject
{
    @private
        AnimationClip*  mAnimationClip;
        Skeleton*       mSkeleton;
        float           mTransitionTime;
        float           mLiveBlend;
}

-(AnimationStackEntry*)Init;
-(void)dealloc;

-(void)SetAnimationClip:(AnimationClip*)inClip;
-(void)SetSkeleton:(Skeleton*)inSkeleton;
-(void)SetTransitionTime:(float)inTransitionTime;
-(void)SetLiveBlend:(BOOL)inLiveBlend;

-(AnimationClip*)GetAnimationClip;
-(Skeleton*)GetSkeleton;
-(float)GetTransitionTime;
-(BOOL)GetLiveBlend;

@end

@interface AnimationController : NSObject
{
    AnimationClip*  mLeftClip;
    AnimationClip*  mRightClip;
    
    Skeleton*       mLeftSkeleton;
    Skeleton*       mRightSkeleton;
    Skeleton*       mCurrentSkeleton;
    
    AnimationControllerBlendMode mBlendMode;
    
    CFTimeInterval  mTransitionTime;
    CFTimeInterval  mElapsedTime;
    
    Stack*          mAnimationStack;
}

-(AnimationController*)InitWithSkeleton:(Skeleton*)inSkeleton;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;

+(void)InitDefaultTransitionParams:(AnimationTransitionParams*)outParams;
-(void)SetTargetAnimationClip:(AnimationClip*)inAnimationClip skeleton:(Skeleton*)inSkeleton transitionTime:(float)inTransitionTime;
-(void)PushTargetAnimationClip:(AnimationClip*)inAnimationClip skeleton:(Skeleton*)inSkeleton params:(AnimationTransitionParams*)inParams;

-(void)SetTargetAnimationClipData:(NSData*)inAnimationClipData params:(AnimationTransitionParams*)inParams;
-(void)PushTargetAnimationClipData:(NSData*)inAnimationClipData params:(AnimationTransitionParams*)inParams;

-(void)PushCurrentAnimation:(AnimationTransitionParams*)inParams;

-(AnimationClip*)GetActiveAnimationClip;
-(int)StackDepth;

-(AnimationControllerBlendMode)GetBlendMode;

-(void)EndCurrentBlend;

@end