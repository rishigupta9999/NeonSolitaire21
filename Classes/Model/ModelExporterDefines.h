//
//  ModelExporterDefines.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#pragma once

#include "NeonMath.h"

#define NEON21_MODELEXPORTER_MAJOR_VERSION          (1)
#define NEON21_MODELEXPORTER_MINOR_VERSION          (0)

enum Neon21ModelType
{
    NEON21_MODEL_MESH,
    NEON21_MODEL_SKELETON,
    NEON21_MODEL_MAX
};

enum KeyframeType
{
    NEON21_ANIMATION_KEYFRAME_BEZIER,
    NEON21_ANIMATION_KEYFRAME_MAX
};

#define NEON21_MODELEXPORTER_MESH_EXTENSION         ("STM")
#define NEON21_MODELEXPORTER_SKELETON_EXTENSION     ("SKEL")
#define NEON21_MODELEXPORTER_ANIMATION_EXTENSION    ("ANIM")

#define NEON21_MODELEXPORTER_TEXTURE_NAME_LENGTH            (32)
#define NEON21_MODELEXPORTER_JOINT_NAME_LENGTH              (32)
#define NEON21_MODELEXPORTER_TARGET_TRANSFORM_NAME_LENGTH   (32)
#define NEON21_MODELEXPORTER_TRANSFORM_NAME_LENGTH          (32)
#define NEON21_MODELEXPORTER_ANIMATION_CLIP_NAME_LENGTH     (64)
#define NEON21_MODELEXPORTER_ANIMATION_NAME_LENGTH          (128)

#define NEON21_MODELEXPORTER_INVALID_JOINT_INDEX    (0xFFFFFFFF)

typedef enum
{
    TRANSFORM_TYPE_INVALID,
    TRANSFORM_TYPE_ROTATION,
    TRANSFORM_TYPE_TRANSLATION,
    TRANSFORM_TYPE_MATRIX,
    TRANSFORM_TYPE_MAX
} TransformType;

typedef struct
{
    int     mMajorVersion;
    int     mMinorVersion;
    
    int     mFileType;
        
    int     mPositionStride;
    int     mNormalStride;
    int     mTexcoordStride;
    int     mNumMatricesPerVertex;
    
    int     mNumVertices;
    
    float   mBindShapeMatrix[16];
    
    char    mTextureFilename[NEON21_MODELEXPORTER_TEXTURE_NAME_LENGTH];
} ModelHeader;

typedef struct
{
    int     mMajorVersion;
    int     mMinorVersion;
    
    int     mFileType;
    
    int     mNumJoints;
} SkeletonHeader;

typedef struct
{
    char        mName[NEON21_MODELEXPORTER_JOINT_NAME_LENGTH];
    Matrix44    mInverseBindPoseTransform;
    int         mJointID;
    int         mNumTransforms;
    int         mNumChildren;
    // TransformsRecords follow
    // Children indices follow
} JointEntry;

typedef struct
{
    TransformType   mTransformType;
    Matrix44        mTransformData;
    char            mTransformName[NEON21_MODELEXPORTER_TRANSFORM_NAME_LENGTH];
} TransformRecord;

typedef struct
{
    int         mMajorVersion;
    int         mMinorVersion;
    
    char        mName[NEON21_MODELEXPORTER_ANIMATION_CLIP_NAME_LENGTH];
    int         mNumAnimations;
    // Animation header follows
} AnimationClipHeader;

typedef struct
{
    char        mName[NEON21_MODELEXPORTER_ANIMATION_NAME_LENGTH];
    char        mJointName[NEON21_MODELEXPORTER_JOINT_NAME_LENGTH];
    char        mTargetTransformName[NEON21_MODELEXPORTER_TARGET_TRANSFORM_NAME_LENGTH];
    char        mComponent;
    int         mNumCurves;
    // Animation curve header follows
} AnimationHeader;

typedef struct
{
    int         mNumKeyframes;
} AnimationCurveHeader;

// After header is the common keyframe data

typedef struct
{
    int         mKeyframeType;
    float       mKeyframeTime;
    float       mKeyframeValue;
} AnimationKeyframeCommon;

typedef struct
{
    float       mInTangentX;
    float       mInTangentY;
    float       mOutTangentX;
    float       mOutTangentY;
} BezierKeyframeData;