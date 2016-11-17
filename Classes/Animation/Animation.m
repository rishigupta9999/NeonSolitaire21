//
//  Animation.m
//  Neon21
//
//  Copyright 2010 Neon Games. All rights reserved.
//


#import "Animation.h"
#import "AnimationTransformer.h"

#import "ModelExporterDefines.h"

#define DEFAULT_JOINT_ANIMATION_CAPACITY    (8)

@implementation AnimationKeyframe
@end

@implementation BezierAnimationKeyframe
@end

@implementation Animation

-(Animation*)InitWithSkeleton:(Skeleton*)inSkeleton jointName:(NSString*)inName component:(int)inComponent
                                targetTransformName:(NSString*)inTargetTransformName numCurves:(int)inNumCurves
{
    BOOL success = FALSE;
    
    int numJoints = [inSkeleton GetNumJoints];
    mTime = 0.0;
    mDuration = 0.0;
    mNumCurves = inNumCurves;
    
    for (int curJointIndex = 0; curJointIndex < numJoints; curJointIndex++)
    {
        Joint* curJoint = [inSkeleton GetJointWithIdentifier:curJointIndex];
        
        if ([curJoint->mName compare:inName] == NSOrderedSame)
        {
            mTargetJoint = [curJoint retain];
            mTargetComponent = inComponent;
            mJointName = [inName retain];
            mSkeleton = [inSkeleton retain];
            mTargetTransformName = [inTargetTransformName retain];
            
            for (int i = 0; i < ANIMATION_MAX_CURVE_COUNT; i++)
            {
                if (i < inNumCurves)
                {
                    mPath[i] = [(Path*)[Path alloc] Init];
                }
                else
                {
                    mPath[i] = NULL;
                }
            }
            
            int numTransforms = NeonArray_GetNumElements(mTargetJoint->mTransforms);
            
            for (int curTransformIndex = 0; curTransformIndex < numTransforms; curTransformIndex++)
            {
                JointTransform* curTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(mTargetJoint->mTransforms, curTransformIndex);
                NSString* transformName = [NSString stringWithUTF8String:curTransform->mTransformName];
                                
                if ([transformName compare:mTargetTransformName] == NSOrderedSame)
                {
                    mTargetTransform = curTransform;
                    [mTargetTransform retain];
                    break;
                }
            }
            
            NSAssert(mTargetTransform != NULL, @"Target transform was not found");
            
            mKeyframes = [[NSMutableArray alloc] initWithCapacity:0];
            mAnimationName = NULL;
                        
            success = TRUE;
            
            break;
        }
    }
    
    NSAssert(success, @"Joint wasn't found");
    
    return self;
}

-(Animation*)InitWithAnimation:(Animation*)inAnimation transformer:(AnimationTransformer*)inTransformer
{
    // Copy over all the easy instance variables
    mJointName = [inAnimation->mJointName retain];
    mAnimationName = [inAnimation->mAnimationName retain];
    mTargetJoint = [inAnimation->mTargetJoint retain];
    mTargetComponent = inAnimation->mTargetComponent;
    mTargetTransformName = [inAnimation->mTargetTransformName retain];
    mTargetTransform = [inAnimation->mTargetTransform retain];
    mSkeleton = [inAnimation->mSkeleton retain];
    mTime = inAnimation->mTime;
    mDuration = inAnimation->mDuration;
    mNumCurves = inAnimation->mNumCurves;
    
    // If no AnimationTransformer was specified, then simply clone the animation paths.  Otherwise we'll
    // need to transform the keyframes and regenerate the paths
    
    if (inTransformer == NULL)
    {
        for (int i = 0; i < ANIMATION_MAX_CURVE_COUNT; i++)
        {
            if (inAnimation->mPath[i] != NULL)
            {
                mPath[i] = [(Path*)[Path alloc] InitWithPath:inAnimation->mPath[i]];
            }
            else
            {
                mPath[i] = NULL;
            }
        }
    }
    else
    {
        for (int curCurveIndex = 0; curCurveIndex < ANIMATION_MAX_CURVE_COUNT; curCurveIndex++)
        {
            if (curCurveIndex < mNumCurves)
            {
                mPath[curCurveIndex] = [(Path*)[Path alloc] Init];
            }
            else
            {
                mPath[curCurveIndex] = NULL;
            }
        }
                
        mKeyframes = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
    NSMutableArray* keyframeArray = NULL;
    
    if (inTransformer != NULL)
    {
        keyframeArray = [[NSMutableArray alloc] initWithCapacity:[inAnimation->mKeyframes count]];
    }
            
    for (AnimationKeyframe* curKeyframe in inAnimation->mKeyframes)
    {
        AnimationKeyframe* newKeyframe = NULL;
        
        switch(curKeyframe->mKeyframeType)
        {
            case KEYFRAME_TYPE_LINEAR:
            {
                newKeyframe = [AnimationKeyframe alloc];
                break;
            }
            
            case KEYFRAME_TYPE_BEZIER:
            {
                newKeyframe = [BezierAnimationKeyframe alloc];
                BezierAnimationKeyframe* srcKeyframe = (BezierAnimationKeyframe*)curKeyframe;
                BezierAnimationKeyframe* destKeyframe = (BezierAnimationKeyframe*)newKeyframe;
                
                // Only copy bezier specific data here.  Common data will be copied below.
                for (int i = 0; i < ANIMATION_MAX_CURVE_COUNT; i++)
                {
                    CloneVec2(&srcKeyframe->mInTangent[i], &destKeyframe->mInTangent[i]);
                    CloneVec2(&srcKeyframe->mOutTangent[i], &destKeyframe->mOutTangent[i]);
                }
                                
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown keyframe type");
                break;
            }
        }
            
        newKeyframe->mKeyframeType = curKeyframe->mKeyframeType;
        newKeyframe->mAnimation = curKeyframe->mAnimation;
        newKeyframe->mTime = curKeyframe->mTime;
        newKeyframe->mKeyframeDataType = curKeyframe->mKeyframeDataType;
            
        switch(newKeyframe->mKeyframeDataType)
        {
            case KEYFRAME_DATA_OUTPUT_FLOAT:
            {
                newKeyframe->mOutputValue.mAngle = curKeyframe->mOutputValue.mAngle;
                break;
            }
            
            case KEYFRAME_DATA_OUTPUT_VECTOR:
            {
                CloneVec3(&curKeyframe->mOutputValue.mVector, &newKeyframe->mOutputValue.mVector);
                break;
            }
            
            default:
            {
                NSAssert(FALSE, @"Unknown keyframe data type");
                break;
            }
        }
        
        if (inTransformer != NULL)
        {
            [inTransformer Operate:newKeyframe];
        }
        
        [keyframeArray addObject:newKeyframe];
        [newKeyframe release];
    }
    
    if (inTransformer != NULL)
    {
        [inTransformer PostOperate:keyframeArray withAnimation:self];
    }
    
    // The path generation logic relies on a keyframe to be "added" for each curve in the animation.
    
    for (AnimationKeyframe* curKeyframe in keyframeArray)
    {
        for (int curCurve = 0; curCurve < mNumCurves; curCurve++)
        {
            [self AddKeyframe:curKeyframe forIndex:curCurve];
        }
    }
    
    [keyframeArray release];
    
    return self;
}

-(void)dealloc
{
    [mJointName release];
    [mTargetJoint release];
    [mTargetTransformName release];
    [mSkeleton release];
    [mKeyframes release];
    [mTargetTransform release];
    
    for (int i = 0; i < ANIMATION_MAX_CURVE_COUNT; i++)
    {
        [mPath[i] release];
    }
    
    [mAnimationName release];
    
    [super dealloc];
}

-(void)SetAnimationName:(NSString*)inName
{
    mAnimationName = inName;
    [inName retain];
}

-(void)AddKeyframe:(AnimationKeyframe*)inKeyframe forIndex:(int)inIndex
{
    // Note:  inIndex refers to the curve index.  It does not refer to the index of the keyframe in the mKeyframes array.
    NSUInteger arrayIndex = [mKeyframes indexOfObject:inKeyframe];
    
    if (inIndex == 0)
    {
        NSAssert(arrayIndex == NSNotFound, @"For the first index, this should be the first index of the keyframe");
    }
    else
    {
        NSAssert(arrayIndex != NSNotFound, @"For subsequent indices, they keyframe should already have been added");
    }
    
    if (arrayIndex == NSNotFound)
    {
        [mKeyframes addObject:inKeyframe];
    }
    
    PathNodeParams pathNodeParams;
    [Path InitPathNodeParams:&pathNodeParams];
    
    pathNodeParams.mTime = inKeyframe->mTime;
    
    if (inKeyframe->mTime > mDuration)
    {
        mDuration = inKeyframe->mTime;
    }
    
    switch(inKeyframe->mKeyframeType)
    {
        case KEYFRAME_TYPE_LINEAR:
        {
            pathNodeParams.mInterpolationMethod = PATH_INTERPOLATION_LINEAR;
            break;
        }
        
        case KEYFRAME_TYPE_BEZIER:
        {
            pathNodeParams.mInterpolationMethod = PATH_INTERPOLATION_BEZIER;
            
            BezierAnimationKeyframe* bezierKeyframe = (BezierAnimationKeyframe*)inKeyframe;
            
            CloneVec2(&bezierKeyframe->mInTangent[inIndex], &pathNodeParams.mPathTypeSpecificData.mBezierData.mInTangent);
            CloneVec2(&bezierKeyframe->mOutTangent[inIndex], &pathNodeParams.mPathTypeSpecificData.mBezierData.mOutTangent);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown keyframe type.");
            break;
        }
    }
        
    [mPath[inIndex] SetUserData:(u32)inKeyframe];
    
    if (inKeyframe->mKeyframeDataType == KEYFRAME_DATA_OUTPUT_FLOAT)
    {
        [mPath[inIndex] AddNodeScalar:inKeyframe->mOutputValue.mAngle withParams:&pathNodeParams];
    }
    else if (inKeyframe->mKeyframeDataType == KEYFRAME_DATA_OUTPUT_VECTOR)
    {
        [mPath[inIndex] AddNodeScalar:inKeyframe->mOutputValue.mVector.mVector[inIndex] withParams:&pathNodeParams];
    }
}

-(AnimationKeyframe*)GetKeyframe:(int)inIndex
{
    return [mKeyframes objectAtIndex:inIndex];
}

-(BOOL)GetFinished
{
    BOOL finished = TRUE;
    
    for (int curCurveIndex = 0; curCurveIndex < ANIMATION_MAX_CURVE_COUNT; curCurveIndex++)
    {
        if ((mPath[curCurveIndex] != NULL) && (![mPath[curCurveIndex] Finished]))
        {
            finished = FALSE;
            break;
        }
    }
    
    return finished;
}

-(void)Update:(CFTimeInterval)inTimeInterval
{
    [self SetTime:(mTime + inTimeInterval)];
}

-(void)SetTime:(CFTimeInterval)inTime
{
    mTime = ClampFloat(inTime, 0.0, mDuration);
    
    if (mTargetComponent != w)
    {
        float curValue;
        
        [mPath[0] SetTime:inTime];
        [mPath[0] GetValueScalar:&curValue];
            
        mTargetTransform->mTransformModifier.mVector[mTargetComponent] = curValue;
        mTargetTransform->mModifierDirty = TRUE;
    }
    else
    {
        for (int i = 0; i < ANIMATION_MAX_CURVE_COUNT; i++)
        {
            NSAssert(mPath[i] != NULL, @"We have a component with no path in a translation animation");
            
            float curValue;
            
            [mPath[i] SetTime:inTime];
            [mPath[i] GetValueScalar:&curValue];
            
            mTargetTransform->mTransformModifier.mVector[i] = curValue;
            mTargetTransform->mModifierDirty = TRUE;
        }
    }
}

@end

@implementation AnimationClip

-(AnimationClip*)Init
{
    [self CommonInit];
    
    mAnimations = [[NSMutableArray alloc] initWithCapacity:DEFAULT_JOINT_ANIMATION_CAPACITY];
    mTime = 0.0;
    mDestTime = 0.0;
    
    return self;
}

-(AnimationClip*)InitWithAnimationClip:(AnimationClip*)inAnimationClip transformer:(AnimationTransformer*)inTransformer
{
    // Init base structures
    AnimationClip* newClip = [self Init];
    NSAssert(newClip != NULL, @"We never fail initialization of AnimationClips. WTF?");
    newClip = newClip;
    
    mName = [inAnimationClip->mName retain];
    mDuration = inAnimationClip->mDuration;
    
    for (Animation* curAnimation in inAnimationClip->mAnimations)
    {
        Animation* cloneAnimation = [(Animation*)[Animation alloc] InitWithAnimation:curAnimation transformer:inTransformer];
        [mAnimations addObject:cloneAnimation];
        [cloneAnimation release];
    }
    
    return self;
}

-(AnimationClip*)InitWithData:(NSData*)inData skeleton:(Skeleton*)inSkeleton;
{
	NSAssert(inSkeleton != NULL, @"Attempting to pass NULL skeleton to an animation clip.  This isn't very useful.");
	
    [self CommonInit];
    
    mSkeleton = inSkeleton;
    [mSkeleton retain];
    
    mAnimations = [[NSMutableArray alloc] initWithCapacity:[inSkeleton GetNumJoints]];
    
    [self ParseAnimationData:inData];
    
    // Update the animations to their first frame
    for (Animation* curAnimation in mAnimations)
    {
        [curAnimation Update:0.0];
    }
    
    return self;
}

-(void)CommonInit
{
    mFinished = FALSE;
    mName = NULL;
    mSkeleton = NULL;
    
    mAnimationPlaybackState = ANIMATION_PLAYBACK_STATE_STOPPED;
    
    mLoop = FALSE;
    mTime = 0.0;
}

-(void)dealloc
{
    [mAnimations release];
    [mName release];
    [mSkeleton release];
    
    [super dealloc];
}

-(void)ParseAnimationData:(NSData*)inData
{
    char* data = (char*)[inData bytes];
    
    AnimationClipHeader clipHeader;
    
    memcpy(&clipHeader, data, sizeof(clipHeader));
    data += sizeof(clipHeader);
    
    mName = [[NSString alloc] initWithUTF8String:clipHeader.mName];
    mDuration = 0.0f;
    
    for (int curAnimationIndex = 0; curAnimationIndex < clipHeader.mNumAnimations; curAnimationIndex++)
    {
        AnimationHeader animationHeader;
        Animation* animation;
        
        memcpy(&animationHeader, data, sizeof(animationHeader));
        data += sizeof(animationHeader);
        
        animation = [[Animation alloc]    InitWithSkeleton:mSkeleton
                                          jointName:[NSString stringWithUTF8String:animationHeader.mJointName]
                                          component:animationHeader.mComponent
                                          targetTransformName:[NSString stringWithUTF8String:animationHeader.mTargetTransformName]
                                          numCurves:animationHeader.mNumCurves ];
                                          
        [mAnimations addObject:animation];
        [animation release];
                                                    
        [animation SetAnimationName:[NSString stringWithUTF8String:animationHeader.mName]];
                
        for (int curCurveIndex = 0; curCurveIndex < animationHeader.mNumCurves; curCurveIndex++)
        {
            AnimationCurveHeader animationCurveHeader;
            
            memcpy(&animationCurveHeader, data, sizeof(animationCurveHeader));
            data += sizeof(animationCurveHeader);
            
            for (int curKeyframeIndex = 0; curKeyframeIndex < animationCurveHeader.mNumKeyframes; curKeyframeIndex++)
            {
                AnimationKeyframeCommon keyframeCommon;
                
                memcpy(&keyframeCommon, data, sizeof(keyframeCommon));
                data += sizeof(keyframeCommon);
                
                if (keyframeCommon.mKeyframeTime > mDuration)
                {
                    mDuration = keyframeCommon.mKeyframeTime;
                }
                
                if (curCurveIndex == 0)
                {
                    switch(keyframeCommon.mKeyframeType)
                    {
                        case NEON21_ANIMATION_KEYFRAME_BEZIER:
                        {
                            BezierAnimationKeyframe* bezierKeyframe = [BezierAnimationKeyframe alloc];
                            BezierKeyframeData bezierKeyframeData;
                            
                            memcpy(&bezierKeyframeData, data, sizeof(bezierKeyframeData));
                            data += sizeof(bezierKeyframeData);
                            
                            bezierKeyframe->mTime = keyframeCommon.mKeyframeTime;
                            bezierKeyframe->mAnimation = animation;
                            bezierKeyframe->mKeyframeType = KEYFRAME_TYPE_BEZIER;
                            
                            bezierKeyframe->mInTangent[0].mVector[x] = bezierKeyframeData.mInTangentX;
                            bezierKeyframe->mInTangent[0].mVector[y] = bezierKeyframeData.mInTangentY;
                            bezierKeyframe->mOutTangent[0].mVector[x] = bezierKeyframeData.mOutTangentX;
                            bezierKeyframe->mOutTangent[0].mVector[y] = bezierKeyframeData.mOutTangentY;
                            
                            if (animationHeader.mNumCurves == 1)
                            {
                                bezierKeyframe->mKeyframeDataType = KEYFRAME_DATA_OUTPUT_FLOAT;
                                bezierKeyframe->mOutputValue.mAngle = keyframeCommon.mKeyframeValue;
                            }
                            else if (animationHeader.mNumCurves == 3)
                            {
                                bezierKeyframe->mKeyframeDataType = KEYFRAME_DATA_OUTPUT_VECTOR;
                                bezierKeyframe->mOutputValue.mVector.mVector[x] = keyframeCommon.mKeyframeValue;
                                
                                // Init rest of the structure to sane values.  These values will be overwritten
                                // in subsequent loop iterations.
                                
                                for (int i = 1; i < 3; i++)
                                {
                                    bezierKeyframe->mOutputValue.mVector.mVector[i] = 0.0f;
                                    
                                    bezierKeyframe->mInTangent[i].mVector[x] = 0.0f;
                                    bezierKeyframe->mInTangent[i].mVector[y] = 0.0f;
                                    bezierKeyframe->mOutTangent[i].mVector[x] = 0.0f;
                                    bezierKeyframe->mOutTangent[i].mVector[y] = 0.0f;
                                }
                            }
                            else
                            {
                                NSAssert(FALSE, @"Invalid number of curves");
                            }
                            
                            [animation AddKeyframe:bezierKeyframe forIndex:0];
                            [bezierKeyframe release];
                            
                            break;
                        }
                        
                        default:
                        {
                            NSAssert(FALSE, @"Unknown keyframe type received");
                            break;
                        }
                    }
                }
                else
                {
                    NSAssert(curCurveIndex < 3, @"Curve index is too high");
                    
                    switch(keyframeCommon.mKeyframeType)
                    {
                        case NEON21_ANIMATION_KEYFRAME_BEZIER:
                        {
                            BezierAnimationKeyframe* bezierKeyframe = (BezierAnimationKeyframe*)[animation GetKeyframe:curKeyframeIndex];
                            BezierKeyframeData bezierKeyframeData;
                            
                            memcpy(&bezierKeyframeData, data, sizeof(bezierKeyframeData));
                            data += sizeof(bezierKeyframeData);

                            bezierKeyframe->mOutputValue.mVector.mVector[curCurveIndex] = keyframeCommon.mKeyframeValue;
                            
                            bezierKeyframe->mInTangent[curCurveIndex].mVector[x] = bezierKeyframeData.mInTangentX;
                            bezierKeyframe->mInTangent[curCurveIndex].mVector[y] = bezierKeyframeData.mInTangentY;
                            bezierKeyframe->mOutTangent[curCurveIndex].mVector[x] = bezierKeyframeData.mOutTangentX;
                            bezierKeyframe->mOutTangent[curCurveIndex].mVector[y] = bezierKeyframeData.mOutTangentY;
                            
                            [animation AddKeyframe:bezierKeyframe forIndex:curCurveIndex];

                            break;
                        }
                        
                        default:
                        {
                            NSAssert(FALSE, @"Unknown keyframe type received");
                            break;
                        }
                    }
                }
            }
        }
    }
}

-(void)AddAnimation:(Animation*)inAnimation
{
    [mAnimations addObject:inAnimation];
}

-(void)Update:(CFTimeInterval)inTimeInterval
{
    if ( ((!mFinished) && (mAnimationPlaybackState == ANIMATION_PLAYBACK_STATE_PLAYING)) ||
         (mAnimationPlaybackState == ANIMATION_PLAYBACK_STATE_SEEK) )
    {
        BOOL finished = TRUE;
                
        switch(mAnimationPlaybackState)
        {
            case ANIMATION_PLAYBACK_STATE_SEEK:
            {
                mTime = mDestTime;
                mAnimationPlaybackState = mPrevAnimationPlaybackState;
                
                break;
            }
            
            case ANIMATION_PLAYBACK_STATE_PLAYING:
            {
                mTime += inTimeInterval;
                break;
            }
            
            default:
            {
                break;
            }
        }
                
        for (Animation* curAnimation in mAnimations)
        {
            [curAnimation SetTime:mTime];
            
            if (![curAnimation GetFinished])
            {
                finished = FALSE;
            }
        }
        
        // A looping animation can never finish
        if ((finished) && (mLoop))
        {
            finished = FALSE;
            mTime = 0.0f;
        }
                
        mFinished = finished;
        
        switch(mAnimationPlaybackState)
        {
            case ANIMATION_PLAYBACK_STATE_PLAYING:
            {
                if (mFinished)
                {
                    mAnimationPlaybackState = ANIMATION_PLAYBACK_STATE_STOPPED;
                }
                
                break;
            }
            
            default:
            {
                break;
            }
        }
    }
}

-(CFTimeInterval)GetTime
{
    return mTime;
}

-(float)GetDuration
{
    return mDuration;
}

-(void)Play
{
    mAnimationPlaybackState = ANIMATION_PLAYBACK_STATE_PLAYING;
    
    if (mFinished)
    {
        mTime = 0.0;
        mFinished = FALSE;
    }
}

-(void)Pause
{
    mAnimationPlaybackState = ANIMATION_PLAYBACK_STATE_STOPPED;
}

-(BOOL)GetFinished
{
    return mFinished;
}

-(void)SetLoop:(BOOL)inLoop
{
    mLoop = inLoop;
}

#if FUNCTION_DISPATCH_OPTIMIZATION
void AnimationClip_SetTime(AnimationClip* inClip, CFTimeInterval inTime)
{
    inClip->mDestTime = ClampFloat(inTime, 0.0, inClip->mDuration);
    
    inClip->mPrevAnimationPlaybackState = inClip->mAnimationPlaybackState;
    inClip->mAnimationPlaybackState = ANIMATION_PLAYBACK_STATE_SEEK;
}
#endif

@end