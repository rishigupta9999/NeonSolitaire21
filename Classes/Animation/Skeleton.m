//
//  Neon21AppDelegate.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "Skeleton.h"
#import "ModelExporterDefines.h"

#if CPU_SKINNING
#define USE_MATRIX_PALETTE      (0)
#else
#define USE_MATRIX_PALETTE      (1)
#endif

static const char* ROTATION_TRANSFORM_NAMES[3] = { "rotateX", "rotateY", "rotateZ" };

@implementation Skeleton

-(Skeleton*)InitWithData:(NSData*)inData
{
    [self CommonInit];
    
    unsigned char* stream = (unsigned char*)[inData bytes];
    int readOffset = 0;
    
    SkeletonHeader header;
    
    memcpy(&header, stream, sizeof(SkeletonHeader));
    readOffset += sizeof(SkeletonHeader);
    
    NSAssert(header.mMajorVersion == NEON21_MODELEXPORTER_MAJOR_VERSION, @"Incompatible major version");
    NSAssert(header.mMinorVersion == NEON21_MODELEXPORTER_MINOR_VERSION, @"Incompatible minor version");
    
    NSAssert(header.mFileType == NEON21_MODEL_SKELETON, @"File type is not skeleton");
    
    mJoints = [[NSMutableArray alloc] initWithCapacity:header.mNumJoints];
    
    for (int curJoint = 0; curJoint < header.mNumJoints; curJoint++)
    {
        JointEntry curJointEntry;
        Joint*     curJoint = [(Joint*)[Joint alloc] Init];
        
        memcpy(&curJointEntry, stream + readOffset, sizeof(JointEntry));
        readOffset += sizeof(JointEntry);
        
        [curJoint SetName:[NSString stringWithUTF8String:curJointEntry.mName]];
        [curJoint SetInverseBindPoseTransform:&curJointEntry.mInverseBindPoseTransform];
        [curJoint SetID:curJointEntry.mJointID];
        
        for (int curTransform = 0; curTransform < curJointEntry.mNumTransforms; curTransform++)
        {
            TransformRecord currentRecord;
            
            memcpy(&currentRecord, stream + readOffset, sizeof(TransformRecord));
            readOffset += sizeof(TransformRecord);
            
            [curJoint AddTransformRecord:&currentRecord];
        }
        
        for (int curChild = 0; curChild < curJointEntry.mNumChildren; curChild++)
        {
            int curChildIndex = 0;
            
            memcpy(&curChildIndex, stream + readOffset, sizeof(int));
            readOffset += sizeof(int);
            
            [curJoint AddChildIndex:[NSNumber numberWithInt:curChildIndex]];
        }
        
        [mJoints addObject:curJoint];
        [curJoint release];
    }

#if 0    
    [self PrintHierarchy:0 level:0];
#endif
    
    return self;
}

-(Skeleton*)InitWithSkeleton:(Skeleton*)inSkeleton;
{
    [self CommonInit];
    
    int numJoints = [inSkeleton GetNumJoints];
    
    mJoints = [[NSMutableArray alloc] initWithCapacity:numJoints];
    
    for (int i = 0; i < numJoints; i++)
    {
        Joint* joint = [[Joint alloc] InitWithJoint:[inSkeleton GetJointAtIndex:i]];
        [mJoints addObject:joint];
        [joint release];
    }
    
    return self;
}

-(void)CommonInit
{
    mSkeletonTransform = SKELETON_TRANSFORM_NONE;
    mJoints = NULL;
}

-(void)dealloc
{
    [mJoints release];
    [super dealloc];
}

-(void)PrintHierarchy:(int)inJointIndex level:(int)inLevel verbose:(BOOL)inVerbose
{
    NEON_PRINT_TABS(inLevel);
    
    Joint* curJoint = [mJoints objectAtIndex:inJointIndex];
    
    printf("Joint %s, id %d\n", [[curJoint GetName] UTF8String], [curJoint GetID]);
    
    if (inVerbose)
    {
        NEON_PRINT_TABS(inLevel);

        int numElements = NeonArray_GetNumElements(curJoint->mTransforms);
        printf("Num Transforms: %d\n", numElements);
                
        for (int i = 0; i < numElements; i++)
        {
            NEON_PRINT_TABS(inLevel);
            printf("----\n");
            
            JointTransform* transform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curJoint->mTransforms, i);
            
            // Base transform matrix
            PrintMatrix44(&transform->mTransform, inLevel);
            
            // Transform type
            NEON_PRINT_TABS(inLevel);
            printf("Transform Type: %d\n", transform->mTransformType);
            
            // Transform name
            NEON_PRINT_TABS(inLevel);
            printf("Transform Name: %s\n", transform->mTransformName);
            
            // Transform parameters
            NEON_PRINT_TABS(inLevel);
            printf("Transform Parameters: %f, %f, %f, %f\n", transform->mTransformParameters.mVector[x], transform->mTransformParameters.mVector[y],
                                                                transform->mTransformParameters.mVector[z], transform->mTransformParameters.mVector[w]);
                                                                
            // Transform modifier
            NEON_PRINT_TABS(inLevel);
            printf("Transform Modifier: %f, %f, %f\n", transform->mTransformModifier.mVector[x], transform->mTransformModifier.mVector[y],
                                                        transform->mTransformModifier.mVector[z] );
                                                        
            // Modifier dirty
            NEON_PRINT_TABS(inLevel);
            printf("Modifier Dirty: %d\n", transform->mModifierDirty);
        }
        
        NEON_PRINT_TABS(inLevel);
        printf("----\n");
    }
    
    for (NSNumber* curChildIndex in curJoint->mChildren)
    {
        [self PrintHierarchy:[curChildIndex intValue] level:(inLevel + 1) verbose:inVerbose];
    }
}

-(Joint*)GetJointAtIndex:(int)inIndex
{
    return [mJoints objectAtIndex:inIndex];
}

-(int)GetNumJointNodes
{
    return [mJoints count];
}

-(int)GetNumJoints
{
    int count = 0;
    
    for (Joint* curJoint in mJoints)
    {
        if (curJoint->mID != JOINT_INVALID_INDEX)
        {
            count++;
        }
    }
    
    return count;
}

-(void)SetSkeletonTransform:(SkeletonTransform)inSkeletonTransform
{
    NSAssert(   ((inSkeletonTransform >= SKELETON_TRANSFORM_NONE) && (inSkeletonTransform < SKELETON_TRANSFORM_NUM)),
                @"Invalid SkeletonTransform passed in"  );
                
    mSkeletonTransform = inSkeletonTransform;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    Matrix44 identity;
    
    SetIdentity(&identity);
    
    [self ResolveSkeleton:0 withTransform:&identity];
}

-(void)ResolveSkeleton:(int)inJointIndex withTransform:(Matrix44*)inTransform;
{
    Joint*   curJoint = [self GetJointAtIndex:inJointIndex];
    
    Matrix44 jointTransform;
    Joint_GetTransform(curJoint, &jointTransform);
    
    MatrixMultiply(inTransform, &jointTransform, &jointTransform);
    
    [curJoint SetNetTransform:&jointTransform skeleton:self skeletonTransform:mSkeletonTransform];
    
    for (int curChild = 0; curChild < [curJoint GetNumChildren]; curChild++)
    {
        int childIndex = [curJoint GetChild:curChild];
        
        [self ResolveSkeleton:childIndex withTransform:&jointTransform];
    }
}

-(void)Reset
{
    for (Joint* curJoint in mJoints)
    {
        int numTransforms = NeonArray_GetNumElements(curJoint->mTransforms);
        
        for (int curTransformIndex = 0; curTransformIndex < numTransforms; curTransformIndex++)
        {
            JointTransform* curTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(curJoint->mTransforms, curTransformIndex);
            curTransform->mModifierDirty = FALSE;
        }
    }
}

-(Joint*)GetJointWithName:(const char*)inName
{
    for (Joint* curJoint in mJoints)
    {
        if ([curJoint->mName compare:[NSString stringWithUTF8String:inName]] == NSOrderedSame)
        {
            return curJoint;
        }
    }
    
    NSAssert(FALSE, @"Joint not found");
    
    return NULL;
}

-(Joint*)GetJointWithIdentifier:(int)inIdentifier
{
    for (Joint* curJoint in mJoints)
    {
        if (curJoint->mID == inIdentifier)
        {
            return curJoint;
        }
    }
    
    NSAssert(FALSE, @"Joint not found");
    
    return NULL;
}

-(int)GetIndexForJoint:(Joint*)inJoint
{
    int numJoints = [mJoints count];
    
    for (int curJointIndex = 0; curJointIndex < numJoints; curJointIndex++)
    {
        Joint* curJoint = [mJoints objectAtIndex:curJointIndex];
        
        if (curJoint == inJoint)
        {
            return curJointIndex;
        }
    }
    
    NSAssert(FALSE, @"Joint not found");
    
    return JOINT_INVALID_INDEX;
}

-(void)DrawJointHierarchy:(int)inActiveJoint
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
#if USE_MATRIX_PALETTE
    glEnableClientState(GL_WEIGHT_ARRAY_OES);
    glEnableClientState(GL_MATRIX_INDEX_ARRAY_OES);
    
    glEnable(GL_MATRIX_PALETTE_OES);
    
    float weightArray[6] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };
    unsigned char matrixIndexArray[6] = { 0 };
#endif    
    float vertexArray[9] = { 0.0, 0.0, 0.0, 1.5, 0.0, 0.0, 0.0, 1.5, 0.0 };
    float colorArray[12] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 };

    
    // Preload the matrices into the matrix palette

    Matrix44 modelViewMatrix;
    glGetFloatv(GL_MODELVIEW_MATRIX, modelViewMatrix.mMatrix);
    
#if USE_MATRIX_PALETTE
  
    NeonGLMatrixMode(GL_MATRIX_PALETTE_OES);
    for (int curJointIndex = 0; curJointIndex < [self GetNumJoints]; curJointIndex++)
    {
        Joint*      curJoint = [self GetJointWithIdentifier:curJointIndex];
        Matrix44*   jointTransform = [curJoint GetNetTransform];
        //Matrix44    netJointMatrix;
        Matrix44*   inverseBindPoseMatrix = [curJoint GetInverseBindPoseTransform];
        Matrix44    bindPoseMatrix;
        
        Inverse(inverseBindPoseMatrix, &bindPoseMatrix);
        
        glCurrentPaletteMatrixOES(curJointIndex);

        Matrix44 paletteMatrix;
        //Matrix44 vertexTransform;
        Matrix44 identity;
        
        SetIdentity(&identity);
        
        //MatrixMultiply([curJoint GetInitialJointTransform], jointTransform, &netJointMatrix);
        //MatrixMultiply(jointTransform, &bindPoseMatrix, &vertexTransform);
        
        MatrixMultiply(&modelViewMatrix, jointTransform, &paletteMatrix);
        
        glLoadMatrixf(paletteMatrix.mMatrix);
    }
    
    // There appears to be a bug in the simulator.  If you want to use n matrices, n + 1 matrices must
    // be specified.  Possibly an allocation bug or something somewhere in the simulator (allocating n - 1
    // matrices of storage perhaps).
    
    glCurrentPaletteMatrixOES([self GetNumJoints]);
#endif
    glLoadMatrixf(modelViewMatrix.mMatrix);
            
    for (int curJointIndex = 0; curJointIndex < ([self GetNumJoints]); curJointIndex++)
    {
        if (curJointIndex == inActiveJoint)
        {
            colorArray[0] = 1.0;
            colorArray[1] = 0.0;
            colorArray[2] = 0.0;
        }
        else
        {
            colorArray[0] = 0.0;
            colorArray[1] = 1.0;
            colorArray[2] = 0.0;
        }
                
        glPointSize(3.0);
 
#if !USE_MATRIX_PALETTE
        Joint* curJoint = [self GetJointAtIndex:curJointIndex];

        NeonGLMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        
        glMultMatrixf([curJoint GetNetTransform]->mMatrix);
#else
        for (int i = 0; i < sizeof(matrixIndexArray); i++)
        {
            matrixIndexArray[i] = curJointIndex;
        }
#endif
    
#if USE_MATRIX_PALETTE
        glWeightPointerOES(1, GL_FLOAT, 0, weightArray);
        glMatrixIndexPointerOES(1, GL_UNSIGNED_BYTE, 0, matrixIndexArray);

        // Draw joint axes
        for (int axis = 0; axis <= 2; axis++)
        {
            float lineColorArray[24] = {    1.0, 1.0, 0.0, 1.0,
                                            1.0, 1.0, 0.0, 1.0,
                                            0.0, 1.0, 0.0, 1.0,
                                            0.0, 1.0, 0.0, 1.0,
                                            0.0, 0.0, 1.0, 1.0,
                                            0.0, 0.0, 1.0, 1.0  };
                                            
            float linePositionArray[18] = { 0.0, 0.0, 0.0, 1.5, 0.0, 0.0,
                                            0.0, 0.0, 0.0, 0.0, 1.5, 0.0,
                                            0.0, 0.0, 0.0, 0.0, 0.0, 1.5 };
                                            
            glVertexPointer(3, GL_FLOAT, 0, linePositionArray);
            glColorPointer(4, GL_FLOAT, 0, lineColorArray);
            
            glLineWidth(2.0);
            
            glDrawArrays(GL_LINES, 0, 6);
        }
#endif        
        // Draw joint origin
        glColorPointer(4, GL_FLOAT, 0, colorArray);
        glVertexPointer(3, GL_FLOAT, 0, vertexArray);

        glDrawArrays(GL_POINTS, 0, 1);
#if !USE_MATRIX_PALETTE        
        glPopMatrix();
#endif
    }
            
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
#if USE_MATRIX_PALETTE
    glDisableClientState(GL_WEIGHT_ARRAY_OES);
    glDisableClientState(GL_MATRIX_INDEX_ARRAY_OES);
    glDisable(GL_MATRIX_PALETTE_OES);
#endif

    NeonGLError();
}

@end

@implementation JointTransform

-(JointTransform*)Init
{
    SetIdentity(&mTransform);
    mTransformType = TRANSFORM_TYPE_INVALID;
    mTransformName[0] = 0;
    SetVec4(&mTransformParameters, 0.0, 0.0, 0.0, 0.0);
    Set(&mTransformModifier, 0.0, 0.0, 0.0);
    
    mModifierDirty = FALSE;
    
    return self;
}

-(JointTransform*)InitWithJointTransform:(JointTransform*)inJointTransform
{
    CloneMatrix44(&inJointTransform->mTransform, &mTransform);
    mTransformType = inJointTransform->mTransformType;
    strncpy(mTransformName, inJointTransform->mTransformName, NEON21_MODELEXPORTER_TRANSFORM_NAME_LENGTH);
    CloneVec4(&inJointTransform->mTransformParameters, &mTransformParameters);
    CloneVec3(&inJointTransform->mTransformModifier, &mTransformModifier);
    
    mModifierDirty = inJointTransform->mModifierDirty;
    
    return self;
}

@end

#define JOINT_CHILD_ARRAY_CAPACITY  (5)
#define JOINT_TRANSFORM_ARRAY_CAPACITY  (5)

@implementation Joint

-(Joint*)Init
{
    mName = [[NSMutableString alloc] initWithCapacity:NEON21_MODELEXPORTER_JOINT_NAME_LENGTH];
    mChildren = [[NSMutableArray alloc] initWithCapacity:JOINT_CHILD_ARRAY_CAPACITY];
    
    SetIdentity(&mInverseBindPoseTransform);
    
    NeonArrayParams arrayParams;
    NeonArray_InitParams(&arrayParams);
    
    arrayParams.mInitialNumElements = JOINT_TRANSFORM_ARRAY_CAPACITY;
    arrayParams.mElementSize = sizeof(JointTransform*);
        
    mTransforms = NeonArray_Create(&arrayParams);
    
    return self;
}

-(Joint*)InitWithJoint:(Joint*)inJoint
{
    [self Init];
    
    // Copy the simple elements
    [mName setString:inJoint->mName];
    CloneMatrix44(&inJoint->mInverseBindPoseTransform, &mInverseBindPoseTransform);
    mID = inJoint->mID;
    
    // Deep copy transforms
    int numTransforms = NeonArray_GetNumElements(inJoint->mTransforms);
    
    for (int i = 0; i < numTransforms; i++)
    {
        JointTransform* sourceTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(inJoint->mTransforms, i);
        
        JointTransform* transform = [[JointTransform alloc] InitWithJointTransform:sourceTransform];
        NeonArray_InsertElementAtEnd(mTransforms, &transform);
    }
    
    // Copy child indices
    int numChildren = [inJoint GetNumChildren];
    
    for (int i = 0; i < numChildren; i++)
    {
        NSNumber* curChild = [inJoint->mChildren objectAtIndex:i];
        int childIndex = [curChild intValue];
        
        NSNumber* newChild = [[NSNumber alloc] initWithInt:childIndex];
        [mChildren addObject:newChild];
        [newChild release];
    }
    
    return self;
}

-(void)dealloc
{
    [mName release];
    [mChildren release];
    
    int numTransforms = NeonArray_GetNumElements(mTransforms);
    
    for (int curTransform = 0; curTransform < numTransforms; curTransform++)
    {
        JointTransform* transform = *(JointTransform**)NeonArray_GetElementAtIndexFast(mTransforms, curTransform);
        [transform release];
    }
    
    NeonArray_Destroy(mTransforms);
    
    [super dealloc];
}

-(void)GetInitialJointTransform:(Matrix44*)outTransform
{
    SetIdentity(outTransform);
    
    int numTransforms = NeonArray_GetNumElements(mTransforms);
    
    for (int curTransformIndex = 0; curTransformIndex < numTransforms; curTransformIndex++)
    {
        JointTransform* curTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(mTransforms, curTransformIndex);
        MatrixMultiply(outTransform, &curTransform->mTransform, outTransform);
    }
}

#if !FUNCTION_DISPATCH_OPTIMIZATION
-(void)GetTransform:(Matrix44*)outTransform
{
    SetIdentity(outTransform);

    for (JointTransform* transform in mTransforms)
    {
        Matrix44 currentMatrix;
        CloneMatrix44(&transform->mTransform, &currentMatrix);
        
        if (transform->mTransformType == TRANSFORM_TYPE_ROTATION)
        {            
            if ((transform->mTransformParameters.mVector[x] == 1.0) &&
                (transform->mTransformParameters.mVector[y] == 0.0) &&
                (transform->mTransformParameters.mVector[z] == 0.0))
            {
                float tw = transform->mTransformParameters.mVector[w];
                
                if (transform->mModifierDirty)
                {
                    tw = transform->mTransformModifier.mVector[x];
                }

                GenerateRotationMatrix(tw, 1.0, 0.0, 0.0, &currentMatrix);
            }
            else if ((transform->mTransformParameters.mVector[x] == 0.0) &&
                (transform->mTransformParameters.mVector[y] == 1.0) &&
                (transform->mTransformParameters.mVector[z] == 0.0))
            {
                float tw = transform->mTransformParameters.mVector[w];
                
                if (transform->mModifierDirty)
                {
                    tw = transform->mTransformModifier.mVector[y];
                }

                GenerateRotationMatrix(tw, 0.0, 1.0, 0.0, &currentMatrix);
            }
            else if ((transform->mTransformParameters.mVector[x] == 0.0) &&
                (transform->mTransformParameters.mVector[y] == 0.0) &&
                (transform->mTransformParameters.mVector[z] == 1.0))
            {
                float tw = transform->mTransformParameters.mVector[w];
                
                if (transform->mModifierDirty)
                {
                    tw = transform->mTransformModifier.mVector[z];
                }

                GenerateRotationMatrix(tw, 0.0, 0.0, 1.0, &currentMatrix);
            }
            else
            {
                NSAssert(FALSE, @"Unsupported rotation");
            }
        }
        else if (transform->mTransformType == TRANSFORM_TYPE_TRANSLATION)
        {
            float tx = transform->mTransformParameters.mVector[x];
            float ty = transform->mTransformParameters.mVector[y];
            float tz = transform->mTransformParameters.mVector[z];
            
            if (transform->mModifierDirty)
            {
                tx = transform->mTransformModifier.mVector[x];
                ty = transform->mTransformModifier.mVector[y];
                tz = transform->mTransformModifier.mVector[z];
            }
            
            GenerateTranslationMatrix(tx, ty, tz, &currentMatrix);
        }
        
        MatrixMultiply(outTransform, &currentMatrix, outTransform);
    }
}
#endif

-(Matrix44*)GetNetTransform
{
    return &mNetTransform;
}

-(void)SetNetTransform:(Matrix44*)inNetTransform skeleton:(Skeleton*)inSkeleton skeletonTransform:(SkeletonTransform)inSkeletonTransform
{
    switch(inSkeletonTransform)
    {   
        case SKELETON_TRANSFORM_MIRROR_X:
        {
            Matrix44 xInvert;
            GenerateScaleMatrix(-1.0f, 1.0f, 1.0f, &xInvert);
            
            MatrixMultiply(&xInvert, inNetTransform, &mNetTransform);

            break;
        }
                
        case SKELETON_TRANSFORM_NONE:
        {
            CloneMatrix44(inNetTransform, &mNetTransform);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown skeleton transform");
        }
    }
}

-(int)GetNumChildren
{
    return [mChildren count];
}

-(int)GetChild:(int)inChildIndex
{
    return [[mChildren objectAtIndex:inChildIndex] intValue];
}

-(NSString*)GetName
{
    return mName;
}

-(void)SetName:(NSString*)inString
{
    [mName setString:inString];
}

-(void)SetInverseBindPoseTransform:(Matrix44*)inInverseBindPoseTransform
{
    CloneMatrix44(inInverseBindPoseTransform, &mInverseBindPoseTransform);
}

-(Matrix44*)GetInverseBindPoseTransform
{
    return &mInverseBindPoseTransform;
}

-(void)GetLocalSpacePosition:(Vector3*)outPosition
{
    Matrix44* jointMatrix = [self GetNetTransform];
    Vector3 point = { 0.0, 0.0, 0.0 };
    Vector4 jointPosition4;
    
    TransformVector4x3(jointMatrix, &point, &jointPosition4);
    
    SetVec3From4(outPosition, &jointPosition4);
}

-(void)AddTransformRecord:(TransformRecord*)inTransformRecord;
{
    JointTransform* newTransform = [(JointTransform*)[JointTransform alloc] Init];
    
    strncpy(newTransform->mTransformName, inTransformRecord->mTransformName, NEON21_MODELEXPORTER_TRANSFORM_NAME_LENGTH);
    newTransform->mTransformType = inTransformRecord->mTransformType;
    
    if ((inTransformRecord->mTransformType == TRANSFORM_TYPE_TRANSLATION) || (inTransformRecord->mTransformType == TRANSFORM_TYPE_ROTATION))
    {
        memcpy(&newTransform->mTransformParameters.mVector, &inTransformRecord->mTransformData, sizeof(float) * 4);
    }
    else
    {
        SetVec4(&newTransform->mTransformParameters, 0.0, 0.0, 0.0, 0.0);
    }
    
    switch(inTransformRecord->mTransformType)
    {
        case TRANSFORM_TYPE_TRANSLATION:
        {
            GenerateTranslationMatrix(  inTransformRecord->mTransformData.mMatrix[0],
                                        inTransformRecord->mTransformData.mMatrix[1],
                                        inTransformRecord->mTransformData.mMatrix[2],
                                        &newTransform->mTransform);
            break;
        }
        
        case TRANSFORM_TYPE_ROTATION:
        {
            GenerateRotationMatrix(     inTransformRecord->mTransformData.mMatrix[3],
                                        inTransformRecord->mTransformData.mMatrix[0],
                                        inTransformRecord->mTransformData.mMatrix[1],
                                        inTransformRecord->mTransformData.mMatrix[2],
                                        &newTransform->mTransform);
            break;
        }
        
        case TRANSFORM_TYPE_MATRIX:
        {
            CloneMatrix44(&inTransformRecord->mTransformData, &newTransform->mTransform);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unsupported transformation type was specified.");
            break;
        }
    }
    
    NeonArray_InsertElementAtEnd(mTransforms, &newTransform);
}

-(void)AddChildIndex:(NSNumber*)inNumber
{
    [mChildren addObject:inNumber];
}

-(void)SetID:(int)inID
{
    mID = inID;
}

-(int)GetID
{
    return mID;
}

-(void)GetJointRotationTransforms:(JointTransform**)outTransforms
{
    memset(outTransforms, 0, sizeof(JointTransform*) * 3);
    
    int numJointTransforms = NeonArray_GetNumElements(mTransforms);
    
    for (int curTransformIndex = 0; curTransformIndex < numJointTransforms; curTransformIndex++)
    {
        JointTransform* curTransform = *(JointTransform**)NeonArray_GetElementAtIndexFast(mTransforms, curTransformIndex);
        
        if (strcmp(curTransform->mTransformName, ROTATION_TRANSFORM_NAMES[x]) == 0)
        {
            outTransforms[0] = curTransform;
        }
        else if (strcmp(curTransform->mTransformName, ROTATION_TRANSFORM_NAMES[y]) == 0)
        {
            outTransforms[1] = curTransform;
        }
        else if (strcmp(curTransform->mTransformName, ROTATION_TRANSFORM_NAMES[z]) == 0)
        {
            outTransforms[2] = curTransform;
        }
    }
}

#if FUNCTION_DISPATCH_OPTIMIZATION
void Joint_GetTransform(Joint* inJoint, Matrix44* outTransform)
{
    SetIdentity(outTransform);

    int numJointTransforms = NeonArray_GetNumElements(inJoint->mTransforms);

    for (int curTransformIndex = 0; curTransformIndex < numJointTransforms; curTransformIndex++)
    {
        JointTransform* transform = *(JointTransform**)NeonArray_GetElementAtIndexFast(inJoint->mTransforms, curTransformIndex);

        Matrix44 currentMatrix;
        CloneMatrix44(&transform->mTransform, &currentMatrix);
        
        if (transform->mTransformType == TRANSFORM_TYPE_ROTATION)
        {            
            if ((transform->mTransformParameters.mVector[x] == 1.0) &&
                (transform->mTransformParameters.mVector[y] == 0.0) &&
                (transform->mTransformParameters.mVector[z] == 0.0))
            {
                float tw = transform->mTransformParameters.mVector[w];
                
                if (transform->mModifierDirty)
                {
                    tw = transform->mTransformModifier.mVector[x];
                }

                GenerateRotationMatrix(tw, 1.0, 0.0, 0.0, &currentMatrix);
            }
            else if ((transform->mTransformParameters.mVector[x] == 0.0) &&
                (transform->mTransformParameters.mVector[y] == 1.0) &&
                (transform->mTransformParameters.mVector[z] == 0.0))
            {
                float tw = transform->mTransformParameters.mVector[w];
                
                if (transform->mModifierDirty)
                {
                    tw = transform->mTransformModifier.mVector[y];
                }

                GenerateRotationMatrix(tw, 0.0, 1.0, 0.0, &currentMatrix);
            }
            else if ((transform->mTransformParameters.mVector[x] == 0.0) &&
                (transform->mTransformParameters.mVector[y] == 0.0) &&
                (transform->mTransformParameters.mVector[z] == 1.0))
            {
                float tw = transform->mTransformParameters.mVector[w];
                
                if (transform->mModifierDirty)
                {
                    tw = transform->mTransformModifier.mVector[z];
                }

                GenerateRotationMatrix(tw, 0.0, 0.0, 1.0, &currentMatrix);
            }
            else
            {
                // Unsupported rotation
                assert(FALSE);
            }
        }
        else if (transform->mTransformType == TRANSFORM_TYPE_TRANSLATION)
        {
            float tx = transform->mTransformParameters.mVector[x];
            float ty = transform->mTransformParameters.mVector[y];
            float tz = transform->mTransformParameters.mVector[z];
            
            if (transform->mModifierDirty)
            {
                tx = transform->mTransformModifier.mVector[x];
                ty = transform->mTransformModifier.mVector[y];
                tz = transform->mTransformModifier.mVector[z];
            }
            
            GenerateTranslationMatrix(tx, ty, tz, &currentMatrix);
        }
        
        MatrixMultiply(outTransform, &currentMatrix, outTransform);
    }
}
#endif

@end