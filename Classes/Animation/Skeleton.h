//
//  Neon21AppDelegate.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "NeonMath.h"
#import "ModelExporterDefines.h"
#import "NeonArray.h"

#define JOINT_INVALID_INDEX (-1)

typedef enum
{
    JOINT_FIRST,
    JOINT_ROOT = JOINT_FIRST,
    JOINT_NECK,
    JOINT_L_SHOULDER,
    JOINT_L_ELBOW,
    JOINT_L_WRIST,
    JOINT_R_SHOULDER,
    JOINT_R_ELBOW,
    JOINT_R_WRIST,
    JOINT_MAX
} JointType;

typedef enum
{
    SKELETON_TRANSFORM_NONE,
    SKELETON_TRANSFORM_MIRROR_X,
    SKELETON_TRANSFORM_NUM
} SkeletonTransform;

@class Joint;

@interface Skeleton : NSObject
{
    NSMutableArray*     mJoints;
    SkeletonTransform   mSkeletonTransform;
}

-(Skeleton*)InitWithSkeleton:(Skeleton*)inSkeleton;
-(Skeleton*)InitWithData:(NSData*)inData;
-(void)CommonInit;
-(void)dealloc;

-(Joint*)GetJointAtIndex:(int)inIndex;
-(Joint*)GetJointWithIdentifier:(int)inIdentifier;
-(Joint*)GetJointWithName:(const char*)inName;
-(int)GetIndexForJoint:(Joint*)inJoint;

-(int)GetNumJoints;

-(void)SetSkeletonTransform:(SkeletonTransform)inSkeletonTransform;

-(void)DrawJointHierarchy:(int)inActiveJoint;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)ResolveSkeleton:(int)inJointIndex withTransform:(Matrix44*)inTransform;

-(void)Reset;

-(void)PrintHierarchy:(int)inJointIndex level:(int)inLevel verbose:(BOOL)inVerbose;

@end

@interface JointTransform : NSObject
{
    @public
        Matrix44        mTransform;
        TransformType   mTransformType;
        char            mTransformName[NEON21_MODELEXPORTER_TRANSFORM_NAME_LENGTH];
        Vector4         mTransformParameters;
        Vector3         mTransformModifier;
        
        BOOL            mModifierDirty;
}

-(JointTransform*)Init;
-(JointTransform*)InitWithJointTransform:(JointTransform*)inJointTransform;

@end

@interface Joint : NSObject
{
    @public
        // Static data - never changes over the lifetime of the joint
        NSMutableString*    mName;
        Matrix44            mInverseBindPoseTransform;
        NSMutableArray*     mChildren;
        int                 mID;
        
        // Dynamic data - this can change
        NeonArray*          mTransforms;
        Matrix44            mNetTransform;
}

-(Joint*)Init;
-(Joint*)InitWithJoint:(Joint*)inJoint;
-(void)dealloc;

#if !FUNCTION_DISPATCH_OPTIMIZATION
-(void)GetTransform:(Matrix44*)outTransform;
#endif

-(Matrix44*)GetNetTransform;
-(void)SetNetTransform:(Matrix44*)inNetTransform skeleton:(Skeleton*)inSkeleton skeletonTransform:(SkeletonTransform)inSkeletonTransform;

-(int)GetNumChildren;
-(int)GetChild:(int)inChildIndex;

-(NSString*)GetName;
-(void)SetName:(NSString*)inString;

-(void)GetInitialJointTransform:(Matrix44*)outTransform;

-(void)SetInverseBindPoseTransform:(Matrix44*)inInversBindPoseTransform;
-(Matrix44*)GetInverseBindPoseTransform;

-(void)GetLocalSpacePosition:(Vector3*)outPosition;

-(void)AddChildIndex:(NSNumber*)inNumber;
-(void)AddTransformRecord:(TransformRecord*)inTransformRecord;

-(void)SetID:(int)inID;
-(int)GetID;

-(void)GetJointRotationTransforms:(JointTransform**)outTransforms;

#if FUNCTION_DISPATCH_OPTIMIZATION
void Joint_GetTransform(Joint* inJoint, Matrix44* outTransform);
#endif

@end