//
//  AnimationTransformer.h
//  Neon21
//
//  Copyright 2011 Neon Games. All rights reserved.
//

@class AnimationKeyframe;

@interface AnimationTransformerModifier : NSObject
{
    @public
        Joint*  mTargetJoint;
        Vector3 mModifier;
        Vector2 mTimeRange;
}

-(AnimationTransformerModifier*)Init;
-(void)dealloc;

@end

@interface AnimationTransformerModifierList : NSObject
{
    NSMutableArray* mModifierArray;
}

-(AnimationTransformerModifierList*)Init;
-(void)dealloc;

-(void)AddTransformerModifier:(AnimationTransformerModifier*)inModifier;
-(AnimationTransformerModifier*)FindModifierForTime:(float)inTime;

@end

@interface AnimationTransformer : NSObject
{
}

-(AnimationTransformer*)Init;
-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe;
-(void)PostOperate:(NSMutableArray*)inKeyframeArray withAnimation:(Animation*)inAnimation;

@end


@interface MirrorXAnimationTransformer : AnimationTransformer
{
}

-(MirrorXAnimationTransformer*)Init;
-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe;

@end

@interface ReverseAnimationTransformer : AnimationTransformer
{
}

-(ReverseAnimationTransformer*)Init;
-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe;
-(void)PostOperate:(NSMutableArray*)inKeyframeArray withAnimation:(Animation*)inAnimation;

@end


@interface ReverseAnimationTransformerAngleOffset : ReverseAnimationTransformer
{
    AnimationTransformerModifierList*   mModifierList;
}

-(ReverseAnimationTransformerAngleOffset*)InitWithModifierList:(AnimationTransformerModifierList*)inModifierList;
-(void)dealloc;
-(void)Operate:(AnimationKeyframe*)inAnimationKeyframe;

@end