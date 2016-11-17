//
//  AnimationController.m
//  Neon21
//
//  Copyright 2010 Neon Games. All rights reserved.
//

#import "AnimationController.h"
#import "Animation.h"
#import "Skeleton.h"
#import "Stack.h"

#define ANIMATION_CONTROLLER_DEFAULT_TRANSITION_TIME    (0.25)

@implementation AnimationStackEntry

-(AnimationStackEntry*)Init;
{
    mAnimationClip = NULL;
    mSkeleton = NULL;
    mTransitionTime = ANIMATION_CONTROLLER_DEFAULT_TRANSITION_TIME;
    
    return self;
}

-(void)dealloc
{
    [mAnimationClip release];
    [mSkeleton release];
    
    [super dealloc];
}

-(void)SetAnimationClip:(AnimationClip*)inClip
{
    [mAnimationClip release];
    mAnimationClip = [inClip retain];
}

-(void)SetSkeleton:(Skeleton*)inSkeleton
{
    [mSkeleton release];
    mSkeleton = [inSkeleton retain];
}

-(void)SetTransitionTime:(float)inTransitionTime
{
    mTransitionTime = inTransitionTime;
}

-(void)SetLiveBlend:(BOOL)inLiveBlend
{
    mLiveBlend = inLiveBlend;
}

-(AnimationClip*)GetAnimationClip
{
    return mAnimationClip;
}

-(Skeleton*)GetSkeleton
{
    return mSkeleton;
}

-(float)GetTransitionTime
{
    return mTransitionTime;
}

-(BOOL)GetLiveBlend
{
    return mLiveBlend;
}

@end

@implementation AnimationController

-(AnimationController*)InitWithSkeleton:(Skeleton*)inSkeleton
{
    mLeftClip = NULL;
    mRightClip = NULL;
    
    mCurrentSkeleton = [inSkeleton retain];
    mLeftSkeleton = [(Skeleton*)[Skeleton alloc] InitWithSkeleton:mCurrentSkeleton];
    mRightSkeleton = NULL;
    
    mBlendMode = ANIMATION_CONTROLLER_BLEND_INVALID;
    
    mTransitionTime = 0.0f;
    mElapsedTime = 0.0f;
    
    mAnimationStack = [(Stack*)[Stack alloc] Init];
    
    return self;
}

-(void)dealloc
{
    [mCurrentSkeleton release];
    [mLeftSkeleton release];
    [mRightSkeleton release];
    
    [mLeftClip release];
    [mRightClip release];
    
    [mAnimationStack release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mLeftClip Update:inTimeStep];
    [mRightClip Update:inTimeStep];

    switch(mBlendMode)
    {
        case ANIMATION_CONTROLLER_BLEND_LEFT:
        {
            int numJoints = [mLeftSkeleton GetNumJoints];
            
            for (int curJointIndex = 0; curJointIndex < numJoints; curJointIndex++)
            {
                Joint* curLeftJoint = [mLeftSkeleton GetJointAtIndex:curJointIndex];
                Joint* curTargetJoint = [mCurrentSkeleton GetJointAtIndex:curJointIndex];
                
                int numTransforms = NeonArray_GetNumElements(curLeftJoint->mTransforms);
                
                for (int curTransformIndex = 0; curTransformIndex < numTransforms; curTransformIndex++)
                {
                    JointTransform* curLeftTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curLeftJoint->mTransforms, curTransformIndex);
                    JointTransform* curTargetTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curTargetJoint->mTransforms, curTransformIndex);
                    
                    CloneVec3(&curLeftTransform->mTransformModifier, &curTargetTransform->mTransformModifier);
                    curTargetTransform->mModifierDirty = curLeftTransform->mModifierDirty;
                }
            }
            
            AnimationStackEntry* stackEntry = (AnimationStackEntry*)[mAnimationStack Peek];
            
            BOOL liveBlend = FALSE;
            
            if (stackEntry != NULL)
            {
                // Determine if it's time to start a live blend.
                BOOL liveBlendInterval = ([mLeftClip GetDuration] - [mLeftClip GetTime]) <= ([stackEntry GetTransitionTime]);
                liveBlend = liveBlendInterval && ([stackEntry GetLiveBlend]);
            }
            
            if ([mLeftClip GetFinished] || liveBlend)
            {
                stackEntry = (AnimationStackEntry*)[mAnimationStack Pop];
                
                if (stackEntry != NULL)
                {
                    [self SetTargetAnimationClip:[stackEntry GetAnimationClip] skeleton:[stackEntry GetSkeleton] transitionTime:[stackEntry GetTransitionTime]];
                }
                else
                {
                    [mLeftClip release];
                    [mLeftSkeleton release];
                    
                    mLeftClip = NULL;
                    mLeftSkeleton = NULL;
                }
            }
            
            break;
        }
        
        case ANIMATION_CONTROLLER_BLEND_MIX:
        {
            BOOL blendComplete = FALSE;
            int numJoints = [mLeftSkeleton GetNumJoints];
            
            for (int curJointIndex = 0; curJointIndex < numJoints; curJointIndex++)
            {
                Joint* curLeftJoint = [mLeftSkeleton GetJointAtIndex:curJointIndex];
                Joint* curRightJoint = [mRightSkeleton GetJointAtIndex:curJointIndex];
                Joint* curTargetJoint = [mCurrentSkeleton GetJointAtIndex:curJointIndex];
                
                int numTransforms = NeonArray_GetNumElements(curLeftJoint->mTransforms);
                
                for (int curTransformIndex = 0; curTransformIndex < numTransforms; curTransformIndex++)
                {
                    JointTransform* curLeftTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curLeftJoint->mTransforms, curTransformIndex);
                    JointTransform* curRightTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curRightJoint->mTransforms, curTransformIndex);
                    JointTransform* curTargetTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curTargetJoint->mTransforms, curTransformIndex);
                    
                    // The percentage of the destination transform that will be used (goes from 0 to 1)
                    float destMixFactor = mElapsedTime / mTransitionTime;
                    
                    if (destMixFactor >= 1.0)
                    {
                        destMixFactor = 1.0;
                        blendComplete = TRUE;
                    }
                    
                    // If neither transform modifier is dirty, then we don't need to do anything to this transform.
                    // The default transform (specified in the Collada file) will be used.
                    
                    // Otherwise, we have 3 cases.
                    
                    // 1) When both transform modifiers are dirty, interpolate between them.
                    if ((curLeftTransform->mModifierDirty) && (curRightTransform->mModifierDirty))
                    {
                        NSAssert(curLeftTransform->mTransformType == curRightTransform->mTransformType, @"Transforms must be the same type");
                        NSAssert(curLeftTransform->mTransformType != TRANSFORM_TYPE_MATRIX, @"Interpolation between matrix transforms is unimplemented");
                        
                        curTargetTransform->mModifierDirty = TRUE;
                        
                        switch(curLeftTransform->mTransformType)
                        {
                            case TRANSFORM_TYPE_ROTATION:
                            case TRANSFORM_TYPE_TRANSLATION:
                            {
                                LerpVec3(   &curLeftTransform->mTransformModifier, &curRightTransform->mTransformModifier,
                                            destMixFactor, &curTargetTransform->mTransformModifier  );
                                break;
                            }
                            
                            default:
                            {
                                NSAssert(FALSE, @"Unimplemented transform type");
                                break;
                            }
                        }
                    }
                    // 2) Left modifier is dirty, but Right isn't
                    else if ((curLeftTransform->mModifierDirty) && (!curRightTransform->mModifierDirty))
                    {
                        NSAssert(curLeftTransform->mTransformType == curRightTransform->mTransformType, @"Transforms must be the same type");
                        NSAssert(curLeftTransform->mTransformType != TRANSFORM_TYPE_MATRIX, @"Interpolation between matrix transforms is unimplemented");
                        
                        curTargetTransform->mModifierDirty = TRUE;
                        
                        switch(curLeftTransform->mTransformType)
                        {
                            case TRANSFORM_TYPE_ROTATION:
                            {
                                float left = 0;
                                float right = curRightTransform->mTransformParameters.mVector[w];
                                
                                if ((curLeftTransform->mTransformParameters.mVector[x] == 1.0) &&
                                    (curLeftTransform->mTransformParameters.mVector[y] == 0.0) &&
                                    (curLeftTransform->mTransformParameters.mVector[z] == 0.0))
                                {
                                    left = curLeftTransform->mTransformModifier.mVector[x];
                                    Set(    &curTargetTransform->mTransformModifier,
                                            LerpFloat(left, right, destMixFactor), 0, 0 );
                                }
                                else if ((curLeftTransform->mTransformParameters.mVector[x] == 0.0) &&
                                    (curLeftTransform->mTransformParameters.mVector[y] == 1.0) &&
                                    (curLeftTransform->mTransformParameters.mVector[z] == 0.0))
                                {
                                    left = curLeftTransform->mTransformModifier.mVector[y];
                                    Set(    &curTargetTransform->mTransformModifier,
                                            0, LerpFloat(left, right, destMixFactor), 0 );
                                }
                                else if ((curLeftTransform->mTransformParameters.mVector[x] == 0.0) &&
                                    (curLeftTransform->mTransformParameters.mVector[y] == 0.0) &&
                                    (curLeftTransform->mTransformParameters.mVector[z] == 1.0))
                                {
                                    left = curLeftTransform->mTransformModifier.mVector[z];
                                    Set(    &curTargetTransform->mTransformModifier,
                                            0, 0, LerpFloat(left, right, destMixFactor) );
                                }
                                else
                                {
                                    NSAssert(FALSE, @"Unsupported rotation");
                                }
                                
                                break;
                            }
                            
                            case TRANSFORM_TYPE_TRANSLATION:
                            {
                                Vector3 tempRightTransform;
                                SetVec3From4(&tempRightTransform, &curRightTransform->mTransformParameters);
                                
                                LerpVec3(&curLeftTransform->mTransformModifier, &tempRightTransform, destMixFactor, &curTargetTransform->mTransformModifier);
                                break;
                            }
                            
                            default:
                            {
                                NSAssert(FALSE, @"Unimplemented transform type");
                                break;
                            }
                        }
                    }
                    // 3) Left modifier is not dirty, but Right is
                    else if ((!curLeftTransform->mModifierDirty) && (curRightTransform->mModifierDirty))
                    {
                        NSAssert(curLeftTransform->mTransformType == curRightTransform->mTransformType, @"Transforms must be the same type");
                        NSAssert(curLeftTransform->mTransformType != TRANSFORM_TYPE_MATRIX, @"Interpolation between matrix transforms is unimplemented");
                        
                        curTargetTransform->mModifierDirty = TRUE;
                        
                        switch(curLeftTransform->mTransformType)
                        {
                            case TRANSFORM_TYPE_ROTATION:
                            {
                                float left = curLeftTransform->mTransformParameters.mVector[w];
                                float right = 0;
                                
                                if ((curRightTransform->mTransformParameters.mVector[x] == 1.0) &&
                                    (curRightTransform->mTransformParameters.mVector[y] == 0.0) &&
                                    (curRightTransform->mTransformParameters.mVector[z] == 0.0))
                                {
                                    right = curRightTransform->mTransformModifier.mVector[x];
                                    Set(    &curTargetTransform->mTransformModifier,
                                            LerpFloat(left, right, destMixFactor), 0, 0 );
                                }
                                else if ((curRightTransform->mTransformParameters.mVector[x] == 0.0) &&
                                    (curRightTransform->mTransformParameters.mVector[y] == 1.0) &&
                                    (curRightTransform->mTransformParameters.mVector[z] == 0.0))
                                {
                                    right = curRightTransform->mTransformModifier.mVector[y];
                                    Set(    &curTargetTransform->mTransformModifier,
                                            0, LerpFloat(left, right, destMixFactor), 0 );
                                }
                                else if ((curRightTransform->mTransformParameters.mVector[x] == 0.0) &&
                                    (curRightTransform->mTransformParameters.mVector[y] == 0.0) &&
                                    (curRightTransform->mTransformParameters.mVector[z] == 1.0))
                                {
                                    right = curRightTransform->mTransformModifier.mVector[z];
                                    Set(    &curTargetTransform->mTransformModifier,
                                            0, 0, LerpFloat(left, right, destMixFactor) );
                                }
                                else
                                {
                                    NSAssert(FALSE, @"Unsupported rotation");
                                }
                                
                                break;
                            }
                            
                            case TRANSFORM_TYPE_TRANSLATION:
                            {
                                Vector3 tempLeftTransform;
                                SetVec3From4(&tempLeftTransform, &curLeftTransform->mTransformParameters);
                                
                                LerpVec3(&tempLeftTransform, &curRightTransform->mTransformModifier, destMixFactor, &curTargetTransform->mTransformModifier);
                                break;
                            }
                            
                            default:
                            {
                                NSAssert(FALSE, @"Unimplemented transform type");
                                break;
                            }
                        }
                    }
                }
            }
        
            mElapsedTime += inTimeStep;
            
            if (blendComplete)
            {
                [self EndCurrentBlend];
            }
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown animation blend mode");
            break;
        }
    }
}

+(void)InitDefaultTransitionParams:(AnimationTransitionParams*)outParams
{
    outParams->mTransitionToTime = ANIMATION_CONTROLLER_DEFAULT_TRANSITION_TIME;
    outParams->mTransitionFromTime = ANIMATION_CONTROLLER_DEFAULT_TRANSITION_TIME;
    outParams->mLoop = FALSE;
    outParams->mLiveBlend = FALSE;
}

-(void)SetTargetAnimationClipData:(NSData*)inAnimationClipData params:(AnimationTransitionParams*)inParams;
{
    mTransitionTime = inParams->mTransitionToTime;
    mElapsedTime = 0;
    
    // If this is the first time we're setting an animation, then this animation drives the left skeleton and no blending
    // is required.  The left skeleton's transforms will be copied to the current skeleton.
    
    if ((mLeftClip == NULL) || (inParams->mTransitionToTime == 0.0))
    {
        [mLeftClip release];
        
        mBlendMode = ANIMATION_CONTROLLER_BLEND_LEFT;
        
        mLeftClip = [(AnimationClip*)[AnimationClip alloc] InitWithData:inAnimationClipData skeleton:mLeftSkeleton];
        [mLeftClip SetLoop:inParams->mLoop];
        [mLeftClip Play];
    }
    else
    {
        if (mRightClip != NULL)
        {
            [self EndCurrentBlend];
        }
        
        //NSAssert(mRightClip == NULL, @"We don't currently support blending an animation that is already in the process of being blended.");
        
        mRightSkeleton = [(Skeleton*)[Skeleton alloc] InitWithSkeleton:mCurrentSkeleton];
        [mRightSkeleton Reset];
        
        mRightClip = [(AnimationClip*)[AnimationClip alloc] InitWithData:inAnimationClipData skeleton:mRightSkeleton];
        [mRightClip SetLoop:inParams->mLoop];
        [mRightClip Play];
        
        [mLeftClip Pause];
        
        mBlendMode = ANIMATION_CONTROLLER_BLEND_MIX;
    }
}

-(void)SetTargetAnimationClip:(AnimationClip*)inAnimationClip skeleton:(Skeleton*)inSkeleton transitionTime:(float)inTransitionTime
{
    mTransitionTime = inTransitionTime;
    mElapsedTime = 0;
    
    if ((mLeftClip == NULL) || (inTransitionTime == 0.0))
    {
        mBlendMode = ANIMATION_CONTROLLER_BLEND_LEFT;
        
        mLeftClip = [inAnimationClip retain];
        mLeftSkeleton = [inSkeleton retain];
        
        [mLeftClip Play];
    }
    else
    {
        if (mRightClip != NULL)
        {
            [self EndCurrentBlend];
        }

        //NSAssert(mRightClip == NULL, @"We don't currently support blending an animation that is already in the process of being blended.");
        
        mRightSkeleton = [inSkeleton retain];
        mRightClip = [inAnimationClip retain];
        
        [mRightClip Play];
        [mLeftClip Pause];
        
        mBlendMode = ANIMATION_CONTROLLER_BLEND_MIX;
    }
}

-(void)PushTargetAnimationClip:(AnimationClip*)inAnimationClip skeleton:(Skeleton*)inSkeleton params:(AnimationTransitionParams*)inParams
{
    [self PushCurrentAnimation:(AnimationTransitionParams*)inParams];
    [self SetTargetAnimationClip:inAnimationClip skeleton:inSkeleton transitionTime:inParams->mTransitionToTime];
}

-(void)PushTargetAnimationClipData:(NSData*)inAnimationClipData params:(AnimationTransitionParams*)inParams
{
    [self PushCurrentAnimation:(AnimationTransitionParams*)inParams];
    [self SetTargetAnimationClipData:inAnimationClipData params:inParams];
}

-(void)PushCurrentAnimation:(AnimationTransitionParams*)inParams
{
    AnimationStackEntry* newEntry = [(AnimationStackEntry*)[AnimationStackEntry alloc] Init];
    
    if (mBlendMode == ANIMATION_CONTROLLER_BLEND_LEFT)
    {
        // Restore back to whatever was playing on the left skeleton
        [newEntry SetAnimationClip:mLeftClip];
        [newEntry SetSkeleton:mLeftSkeleton];
    }
    else if (mBlendMode == ANIMATION_CONTROLLER_BLEND_MIX)
    {
        // Restore to what was playing on the right skeleton
        [newEntry SetAnimationClip:mRightClip];
        [newEntry SetSkeleton:mRightSkeleton];
    }
    else
    {
        NSAssert(FALSE, @"Unsupported case of pushing an animation.  WTF is up with the blend mode we're in?");
    }
    
    [newEntry SetTransitionTime:inParams->mTransitionFromTime];
    [newEntry SetLiveBlend:inParams->mLiveBlend];
    
    [mAnimationStack Push:newEntry];
    [newEntry release];
}

-(AnimationClip*)GetActiveAnimationClip
{
    switch(mBlendMode)
    {
        case ANIMATION_CONTROLLER_BLEND_LEFT:
        {
            return mLeftClip;
            break;
        }
        
        case ANIMATION_CONTROLLER_BLEND_RIGHT:
        {
            return mRightClip;
            break;
        }
        
        case ANIMATION_CONTROLLER_BLEND_MIX:
        {
            NSAssert(FALSE, @"Cannot call this function during an animation blend.");
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unhandled case");
            break;
        }
    }
    
    return NULL;
}

-(int)StackDepth
{
    return [mAnimationStack GetNumElements];
}

-(AnimationControllerBlendMode)GetBlendMode
{
    return mBlendMode;
}

-(void)EndCurrentBlend
{
    mBlendMode = ANIMATION_CONTROLLER_BLEND_LEFT;
    mElapsedTime = 0;
    
    [mLeftSkeleton release];
    [mLeftClip release];
    
    mLeftSkeleton = mRightSkeleton;
    mLeftClip = mRightClip;
    
    mRightSkeleton = NULL;
    mRightClip = NULL;
}

@end