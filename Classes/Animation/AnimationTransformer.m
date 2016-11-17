//
//  AnimationTransformer.m
//  Neon21
//
//  Copyright 2011 Neon Games. All rights reserved.
//

#import "Animation.h"
#import "AnimationTransformer.h"

@implementation AnimationTransformerModifier

-(AnimationTransformerModifier*)Init
{
    mTargetJoint = NULL;
    Set(&mModifier, 0.0f, 0.0f, 0.0f);
    SetVec2(&mTimeRange, 0.0f, 0.0f);
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end

#define DEFAULT_MODIFIER_LIST_SIZE  (3)

@implementation AnimationTransformerModifierList

-(AnimationTransformerModifierList*)Init
{
    mModifierArray = [[NSMutableArray alloc] initWithCapacity:DEFAULT_MODIFIER_LIST_SIZE];
    
    return self;
}

-(void)dealloc
{
    [mModifierArray release];
    
    [super dealloc];
}

-(void)AddTransformerModifier:(AnimationTransformerModifier*)inModifier
{
    int numModifiers = [mModifierArray count];
    
    NSAssert(inModifier->mTimeRange.mVector[1] >= inModifier->mTimeRange.mVector[0], @"Cannot have backwards time ranges.");
    
    if (numModifiers == 0)
    {
        [mModifierArray addObject:inModifier];
    }
    else
    {
        // First validate that the specified time range doesn't overlap with any other time ranges
        for (int curModifierIndex = 0; curModifierIndex < numModifiers; curModifierIndex++)
        {
            AnimationTransformerModifier* curModifier = (AnimationTransformerModifier*)[mModifierArray objectAtIndex:curModifierIndex];
            
            if ((inModifier->mTimeRange.mVector[0] > curModifier->mTimeRange.mVector[0]) &&
                (inModifier->mTimeRange.mVector[0] < curModifier->mTimeRange.mVector[1]))
            {
                NSAssert(FALSE, @"Overlapping range specified.  This is not allowed");
            }
            
            if ((inModifier->mTimeRange.mVector[1] > curModifier->mTimeRange.mVector[0]) &&
                (inModifier->mTimeRange.mVector[1] < curModifier->mTimeRange.mVector[1]))
            {
                NSAssert(FALSE, @"Overlapping range specified.  This is not allowed");
            }
        }
        
        BOOL inserted = FALSE;
        
        // If we passed the validation above, then insert it (jiggity!)
        for (int curModifierIndex = 0; curModifierIndex < numModifiers; curModifierIndex++)
        {
            AnimationTransformerModifier* curModifier = [mModifierArray objectAtIndex:curModifierIndex];
            
            if (inModifier->mTimeRange.mVector[0] >= curModifier->mTimeRange.mVector[1])
            {
                [mModifierArray insertObject:inModifier atIndex:curModifierIndex];
                inserted = TRUE;
            }
        }
        
        NSAssert(inserted, @"Modifier wasn't added for some reason.  This requires debugging.");
    }
}

-(AnimationTransformerModifier*)FindModifierForTime:(float)inTime
{
    AnimationTransformerModifier* retModifier = NULL;
    
    for (AnimationTransformerModifier* curModifier in mModifierArray)
    {
        if ((inTime >= curModifier->mTimeRange.mVector[0]) && (inTime <= curModifier->mTimeRange.mVector[1]))
        {
            retModifier = curModifier;
            break;
        }
    }

    return retModifier;
}

@end

@implementation AnimationTransformer

-(AnimationTransformer*)Init
{
    return self;
}

-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe
{
}

-(void)PostOperate:(NSMutableArray*)inKeyframeArray withAnimation:(Animation*)inAnimation
{
}

@end


@implementation MirrorXAnimationTransformer

-(MirrorXAnimationTransformer*)Init
{
    // This class shouldn't be used, but I'm leaving it in for future reference and possible cleanup.
    //
    // The problem is that the algorithm for "mirroring" an animation is wrong.  The intention is to flip the animation
    // frames along the x-axis (See the CSE169_11.ppt file in the ReferencePapers/AnimationCourse directory).
    //
    // Unfortunately we only have the animation info in the joint's local space.  Flipping along x doesn't make much
    // sense here, since x in a joint's space, could actually be y in world space.
    //
    // For now we are going to actually manipulate the joints themselves rather than the animation.  This is more
    // computationally expensive since this needs to be evaluated every frame, rather than just once.  But it will
    // look correct.
    //
    // A long term solution would be to calculate a world space rotation for each joint, flip that, and store the result
    // as the new animation frame.  This will take work, and I suspect we'll need to go with a quaternion based approach
    // to accumulate rotations at each joint.  This is in contrast to our current approach which just generates a transformation
    // matrix for each joint.  It's hard to extract the rotations from the transformation matrix.
    //
    // Here are some URLs for future reference:
    // http://www.gamedev.net/topic/424870-mirroring-skeletal-animation-using-quaternions/
    // http://www.flipcode.com/documents/matrfaq.html#Q55 (see "How do I convert a rotation matrix to a quaternion")
    // http://cache-www.intel.com/cd/00/00/29/37/293748_293748.pdf (more info on converting a rotation matrix to a quaternion)
    //
    
    NSAssert(FALSE, @"See the comment above.");
    
    [super Init];
    
    return self;
}

-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe
{
    [super Operate:inAnimationKeyframe];
    return;
    
    Joint* curJoint = inAnimationKeyframe->mAnimation->mTargetJoint;
    Skeleton* curSkeleton = inAnimationKeyframe->mAnimation->mSkeleton;
    
    int index = [curSkeleton GetIndexForJoint:curJoint];
    
    if (index != 0)
    {
        //return;
    }
    
    // In the operate phase, we:
    // 1) Negate all translations about x
    // 2) Negate rotations about y and z
    //
    // Ideally we swap right and left animations, but we'll avoid that at the moment for simplicity
        
    if (inAnimationKeyframe->mAnimation->mTargetComponent == w)
    {
        // First transform what's necessary in the base data
        NSAssert(inAnimationKeyframe->mKeyframeDataType == KEYFRAME_DATA_OUTPUT_VECTOR,
                    @"Can't have translation by float.  At least we don't know how to transform it.");
                    
        inAnimationKeyframe->mOutputValue.mVector.mVector[x] *= -1.0f;
    
        // Now transform what's necessary in the data specific to the keyframe type (eg: Bezier keyframe specific data)
        switch(inAnimationKeyframe->mKeyframeType)
        {
            case KEYFRAME_TYPE_BEZIER:
            {
                BezierAnimationKeyframe* bezierKeyframe = (BezierAnimationKeyframe*)inAnimationKeyframe;
                
                // These are the vectors we need to negate
                Vector2* xInTangent = &bezierKeyframe->mInTangent[x];
                Vector2* xOutTangent = &bezierKeyframe->mOutTangent[x];
                
                // The first component of the vector contains time, the second contains the actual value.
                // This is what needs to be negated.
                xInTangent->mVector[1] *= -1.0f;
                xOutTangent->mVector[1] *= -1.0f;
                
                break;
            }
            
            default:
            {
                break;
            }
        }
    }
    else/* if ((inAnimationKeyframe->mAnimation->mTargetComponent == x) || (inAnimationKeyframe->mAnimation->mTargetComponent == y))*/
    {
        // First transform what's necessary in the base data
        NSAssert(inAnimationKeyframe->mKeyframeDataType == KEYFRAME_DATA_OUTPUT_FLOAT,
                    @"Can't have rotation by vector.  At least we don't know how to transform it.");
                    
        inAnimationKeyframe->mOutputValue.mAngle *= -1.0f;
        
        // Now transform what's necessary in the data specific to the keyframe type (eg: Bezier keyframe specific data)
        switch(inAnimationKeyframe->mKeyframeType)
        {
            case KEYFRAME_TYPE_BEZIER:
            {
                BezierAnimationKeyframe* bezierKeyframe = (BezierAnimationKeyframe*)inAnimationKeyframe;
                
                Vector2* inTangent = &bezierKeyframe->mInTangent[0];
                Vector2* outTangent = &bezierKeyframe->mOutTangent[0];
                
                // The first component of the vector contains time, the second contains the actual value.
                // This is what needs to be negated.
                inTangent->mVector[1] *= -1.0f;
                outTangent->mVector[1] *= -1.0f;
                
                break;
            }
            
            default:
            {
                break;
            }
        }
    }
}

@end

@implementation ReverseAnimationTransformer

-(ReverseAnimationTransformer*)Init
{
    [super Init];
    
    return self;
}

-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe
{
    [super Operate:inAnimationKeyframe];
}

-(void)PostOperate:(NSMutableArray*)inKeyframeArray withAnimation:(Animation*)inAnimation
{
    NSMutableArray* tempArray = [NSMutableArray arrayWithArray:inKeyframeArray];
    
    [inKeyframeArray removeAllObjects];
    
    int numObjects = [tempArray count];
    
    // We actually don't have to reverse the order in which the keyframes are in the array
    // (this gets sorted out by the Path class, based on the mTime value), but in the event
    // that something changes in the future, we'll do it this way.  There's no harm in doing so.
    
    for (int i = (numObjects - 1); i >=0; i--)
    {
        AnimationKeyframe* keyframe = [tempArray objectAtIndex:i];
        
        // Reverse the time of the keyframe
        keyframe->mTime = inAnimation->mDuration - keyframe->mTime;
        
        // Reverse the time of the bezier curve times as well
        
        switch(keyframe->mKeyframeType)
        {
            case KEYFRAME_TYPE_BEZIER:
            {
                BezierAnimationKeyframe* bezierKeyframe = (BezierAnimationKeyframe*)keyframe;
                
                for (int curCurve = 0; curCurve < inAnimation->mNumCurves; curCurve++)
                {
                    bezierKeyframe->mInTangent[curCurve].mVector[0] = inAnimation->mDuration - bezierKeyframe->mInTangent[curCurve].mVector[0];
                    bezierKeyframe->mOutTangent[curCurve].mVector[0] = inAnimation->mDuration - bezierKeyframe->mOutTangent[curCurve].mVector[0];
                }
                
                break;
            }
            
            // Nothing to do for linear keyframes
            case KEYFRAME_TYPE_LINEAR:
            {
                break;
            }
            
            // Add code to handle new keyframe types
            default:
            {
                NSAssert(FALSE, @"Unknown keyframe type encountered");
                break;
            }
        }
        
        [inKeyframeArray addObject:[tempArray objectAtIndex:i]];
    }
}

@end

@implementation ReverseAnimationTransformerAngleOffset

-(ReverseAnimationTransformerAngleOffset*)InitWithModifierList:(AnimationTransformerModifierList*)inModifierList
{
    [super Init];
    
    mModifierList = inModifierList;
    [mModifierList retain];
    
    return self;
}

-(void)dealloc
{
    [mModifierList release];
    
    [super dealloc];
}

-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe
{    
    Joint* curJoint = inAnimationKeyframe->mAnimation->mTargetJoint;
    Skeleton* curSkeleton = inAnimationKeyframe->mAnimation->mSkeleton;
    
    int index = [curSkeleton GetIndexForJoint:curJoint];
    
    if (index != 0)
    {
        return;
    }
        
    int component = inAnimationKeyframe->mAnimation->mTargetComponent;
    
    AnimationTransformerModifier* transformerModifier = [mModifierList FindModifierForTime:inAnimationKeyframe->mTime];
    Vector3 modifierVec = { { 0.0f, 0.0f, 0.0f } };
    
    if (transformerModifier != NULL)
    {
        CloneVec3(&transformerModifier->mModifier, &modifierVec);
    }
        
    if (component != w)
    {
        // First transform what's necessary in the base data
        NSAssert(inAnimationKeyframe->mKeyframeDataType == KEYFRAME_DATA_OUTPUT_FLOAT,
                    @"Can't have rotation by vector.  At least we don't know how to transform it.");
                    
        inAnimationKeyframe->mOutputValue.mAngle += modifierVec.mVector[component];
        
        // Now transform what's necessary in the data specific to the keyframe type (eg: Bezier keyframe specific data)
        switch(inAnimationKeyframe->mKeyframeType)
        {
            case KEYFRAME_TYPE_BEZIER:
            {
                BezierAnimationKeyframe* bezierKeyframe = (BezierAnimationKeyframe*)inAnimationKeyframe;
                
                Vector2* inTangent = &bezierKeyframe->mInTangent[0];
                Vector2* outTangent = &bezierKeyframe->mOutTangent[0];
                
                // The first component of the vector contains time, the second contains the actual value.
                // This is what needs to be negated.
                inTangent->mVector[1] += modifierVec.mVector[component];
                outTangent->mVector[1] += modifierVec.mVector[component];
                
                break;
            }
            
            default:
            {
                break;
            }
        }
    }
}

@end