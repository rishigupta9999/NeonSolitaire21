//
//  Animation.h
//  Neon21
//
//  Copyright 2010 Neon Games. All rights reserved.
//

#import "Skeleton.h"
#import "Path.h"

#define ANIMATION_MAX_CURVE_COUNT   (3)

typedef enum
{
    KEYFRAME_TYPE_BEZIER,
    KEYFRAME_TYPE_LINEAR
} KeyframeType;

typedef enum
{
    KEYFRAME_DATA_OUTPUT_FLOAT,
    KEYFRAME_DATA_OUTPUT_VECTOR,
} KeyframeDataType;

@class Animation;
@class AnimationTransformer;

@interface AnimationKeyframe : NSObject
{
    @public
        CFTimeInterval  mTime;
        
        union
        {
            float           mAngle;
            Vector3         mVector;
        } mOutputValue;
        
        KeyframeDataType    mKeyframeDataType;
        KeyframeType        mKeyframeType;
        Animation*          mAnimation;
}

@end

@interface BezierAnimationKeyframe : AnimationKeyframe
{
    @public
        Vector2         mInTangent[ANIMATION_MAX_CURVE_COUNT];
        Vector2         mOutTangent[ANIMATION_MAX_CURVE_COUNT];
}

@end

@interface Animation : NSObject
{
    @public
        NSString*       mJointName;
        NSString*       mAnimationName;
        Joint*          mTargetJoint;
        int             mTargetComponent;
        NSString*       mTargetTransformName;
        JointTransform* mTargetTransform;
        u32             mNumCurves;
        
        Skeleton*       mSkeleton;
        Path*           mPath[ANIMATION_MAX_CURVE_COUNT];
        
        CFTimeInterval  mTime;
        float           mDuration;
        
        NSMutableArray* mKeyframes;
}

-(Animation*)InitWithSkeleton:(Skeleton*)inSkeleton jointName:(NSString*)inName component:(int)inComponent
                                targetTransformName:(NSString*)inTargetTransformName numCurves:(int)inNumCurves;
-(Animation*)InitWithAnimation:(Animation*)inAnimation transformer:(AnimationTransformer*)inTransformer;
-(void)dealloc;


-(void)SetAnimationName:(NSString*)inName;
-(void)AddKeyframe:(AnimationKeyframe*)inKeyframe forIndex:(int)inIndex;
-(AnimationKeyframe*)GetKeyframe:(int)inIndex;
-(BOOL)GetFinished;

-(void)Update:(CFTimeInterval)inTimeInterval;
-(void)SetTime:(CFTimeInterval)inTime;

@end

typedef enum
{
    ANIMATION_PLAYBACK_STATE_STOPPED,
    ANIMATION_PLAYBACK_STATE_PLAYING,
    ANIMATION_PLAYBACK_STATE_SEEK,
    ANIMATION_PLAYBACK_STATE_COMPLETED
} AnimationPlaybackState;

@interface AnimationClip : NSObject
{
    NSMutableArray*         mAnimations;
    BOOL                    mFinished;
    Skeleton*               mSkeleton;
    
    AnimationPlaybackState  mAnimationPlaybackState;
    AnimationPlaybackState  mPrevAnimationPlaybackState;
    
    NSString*               mName;
    CFTimeInterval          mTime;
    CFTimeInterval          mDestTime;
    
    BOOL                    mLoop;
    
    float                   mDuration;
}

-(AnimationClip*)Init;
-(AnimationClip*)InitWithAnimationClip:(AnimationClip*)inAnimationClip transformer:(AnimationTransformer*)inTransformer;
-(AnimationClip*)InitWithData:(NSData*)inData skeleton:(Skeleton*)inSkeleton;
-(void)CommonInit;

-(void)dealloc;

-(void)ParseAnimationData:(NSData*)inData;

-(void)AddAnimation:(Animation*)inAnimation;

-(void)Play;
-(void)Pause;
-(BOOL)GetFinished;

-(void)Update:(CFTimeInterval)inTimeInterval;

-(CFTimeInterval)GetTime;
-(float)GetDuration;

-(void)SetLoop:(BOOL)inLoop;

@end

void AnimationClip_SetTime(AnimationClip* inClip, CFTimeInterval inTime);