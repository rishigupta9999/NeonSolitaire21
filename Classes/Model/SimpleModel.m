//
//  StaticModel.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "SimpleModel.h"
#import "ModelExporterDefines.h"
#import "TextureManager.h"

#define MAX_INFLUENCES_PER_VERTEX   (2)

@implementation SimpleModel

-(SimpleModel*)InitWithData:(NSData*)inData
{
    [super Init];
    
    ModelHeader header;
    u8*         fileData = (u8*)[inData bytes];
    
    memcpy(&header, fileData, sizeof(ModelHeader));
    
    NSAssert(header.mMajorVersion == NEON21_MODELEXPORTER_MAJOR_VERSION, @"Static Model: Major version number mismatch");
    NSAssert(header.mMinorVersion == NEON21_MODELEXPORTER_MINOR_VERSION, @"Static Model: Minor version number mismatch");
    
    mPositionStride = header.mPositionStride;
    mNormalStride = header.mNormalStride;
    mTexcoordStride = header.mTexcoordStride;
    mNumMatricesPerVertex = header.mNumMatricesPerVertex;
    
    mNumVertices = header.mNumVertices;
    
    // Joint indices are one byte (hence the addition at the end).  Weights are one float per joint (the mNumMatricesPerVertex
    // that's being multiplied by sizeof(float))
    mStride = (mPositionStride + mNormalStride + mTexcoordStride + mNumMatricesPerVertex) * sizeof(float) + mNumMatricesPerVertex;
    
    // Exporter 4 byte aligns each vertex for us
    mStride = (mStride + 3) & 0xFFFFFFFC;
    
    mStream = malloc(mStride * mNumVertices);
    
    memcpy(mStream, fileData + sizeof(ModelHeader), mStride * mNumVertices);


#if !CPU_SKINNING

#if NEON_DEBUG
    if (mNumMatricesPerVertex > MAX_INFLUENCES_PER_VERTEX)
    {
        for (int curVertex = 0; curVertex < mNumVertices; curVertex++)
        {
            unsigned char* readBase = mStream + (mStride * curVertex);
            
            // Check if we have more than 2 non-zero influences for this vertex
            
            int numInfluences = 0;
            float* influenceBase = (float*)(readBase + (mPositionStride + mNormalStride + mTexcoordStride) * sizeof(float));

            for (int curInfluence = 0; curInfluence < mNumMatricesPerVertex; curInfluence++)
            {
                if (influenceBase[curInfluence] > 0.0f)
                {
                    numInfluences++;
                }
            }
            
            if (numInfluences > MAX_INFLUENCES_PER_VERTEX)
            {
                float* positionBase = (float*)readBase;
                NSLog(@"Vertex at %f, %f, %f has %d influences", positionBase[0], positionBase[1], positionBase[2], numInfluences);
            }
        }
        
        NSAssert(FALSE, @"Matrix palette only supports two influences per vertex");

    }
#endif
#endif

#if 0        
    if (header.mTextureFilename[0] != 0)
    {
        mTexture = [[TextureManager GetInstance] TextureWithName:[NSString stringWithUTF8String:header.mTextureFilename]];
        [mTexture retain];
    }
    else
#endif
    {
        mTexture = NULL;
    }
    
    memcpy(&mBindShapeMatrix.mMatrix, header.mBindShapeMatrix, sizeof(float) * 16);

#if CPU_SKINNING     
    if (mNumMatricesPerVertex > 0)
    {
        mSkinnedPositions = malloc(sizeof(float) * 3 * mNumVertices);
        mSkinnedNormals = malloc(sizeof(float) * 3 * mNumVertices);
    }
    else
    {
        mSkinnedPositions = NULL;
        mSkinnedNormals = NULL;
        [self GenerateVBO];
    }
#else
    [self GenerateVBO];
#endif
    
    [self GenerateGLBoundingBox];
    
    mJointMatrices = NULL;
    mJointMatricesInverseTranspose = NULL;
    
    return self;
}

-(void)dealloc
{
    free(mStream);
    
#if CPU_SKINNING
    free(mSkinnedPositions);
    free(mSkinnedNormals);
#endif

    if (mJointMatrices != NULL)
    {
        free(mJointMatrices);
        mJointMatrices = NULL;
    }
    
    if (mJointMatricesInverseTranspose != NULL)
    {
        free(mJointMatricesInverseTranspose);
        mJointMatricesInverseTranspose = NULL;
    }
    
    [super dealloc];
}

-(void)GenerateGLBoundingBox
{
    NSAssert(mPositionStride >= 3, @"Position data is not 3 component.  Cannot generate a bounding box");
    
    mBoundingBox.mMinX = ((float*)mStream)[0];
    mBoundingBox.mMaxX = ((float*)mStream)[0];
    
    mBoundingBox.mMinY = ((float*)mStream)[1];
    mBoundingBox.mMaxY = ((float*)mStream)[1];
    
    mBoundingBox.mMinZ = ((float*)mStream)[2];
    mBoundingBox.mMaxZ = ((float*)mStream)[2];
    
    for (int i = 1; i < mNumVertices; i++)
    {
        unsigned char* readData = mStream + (mStride * i);
        
        float x = ((float*)readData)[0];
        float y = ((float*)readData)[1];
        float z = ((float*)readData)[2];
        
        if (x < mBoundingBox.mMinX)
        {
            mBoundingBox.mMinX = x;
        }
        
        if (x > mBoundingBox.mMaxX)
        {
            mBoundingBox.mMaxX = x;
        }
        
        if (y < mBoundingBox.mMinY)
        {
            mBoundingBox.mMinY = y;
        }
        
        if (y > mBoundingBox.mMaxY)
        {
            mBoundingBox.mMaxY = y;
        }
        
        if (z < mBoundingBox.mMinZ)
        {
            mBoundingBox.mMinZ = z;
        }
        
        if (z > mBoundingBox.mMaxZ)
        {
            mBoundingBox.mMaxZ = z;
        }
    }
}

-(void)GenerateVBO
{
    glGenBuffers(1, &mVBO);
    glBindBuffer(GL_ARRAY_BUFFER, mVBO);
    glBufferData(GL_ARRAY_BUFFER, mStride * mNumVertices, mStream, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

-(void)Update:(u32)inFrameTime
{
    if (mSkeleton != NULL)
    {
        [mSkeleton Update:inFrameTime];
    }
}

-(void)Draw
{
    if (mUseOverride)
    {
        NeonGLEnable(GL_BLEND);
        glEnable(GL_COLOR_MATERIAL);

        glColor4f(  mRenderStateOverride.mColor.mVector[x], mRenderStateOverride.mColor.mVector[y],
                    mRenderStateOverride.mColor.mVector[z], mRenderStateOverride.mColor.mVector[w]  );
    }
    
    
#if CPU_SKINNING
    [self DrawCPUSkinned];
#else
    [self DrawGPUSkinned];
#endif

    if (mUseOverride)
    {
        glDisable(GL_COLOR_MATERIAL);
        NeonGLDisable(GL_BLEND);
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    }
}

-(void)DrawGPUSkinned
{
    glBindBuffer(GL_ARRAY_BUFFER, mVBO);
    
    [self SetupSkinningState];
    
    if (mClipPlaneEnabled)
    {
        if (mNumMatricesPerVertex > 0)
        {
            glEnable(GL_CLIP_PLANE1);
                        
            float planeEquation[4];
            
            planeEquation[0] = mClipPlane.mNormal.mVector[x];
            planeEquation[1] = mClipPlane.mNormal.mVector[y];
            planeEquation[2] = mClipPlane.mNormal.mVector[z];
            planeEquation[3] = mClipPlane.mDistance;
            
            glClipPlanef(GL_CLIP_PLANE1, planeEquation);
        }
        else
        {
            NSAssert(FALSE, @"We don't have clip plane support implemented for this scenario.");
        }
    }
    
    [self SetupTextureState];
    [self SetupVertexBuffers];

    glDrawArrays(GL_TRIANGLES, 0, mNumVertices);
    
    if (mClipPlaneEnabled)
    {
        glDisable(GL_CLIP_PLANE1);
    }
    
    [self CleanupDrawState];

    NeonGLError();
}

#if CPU_SKINNING
-(void)DrawCPUSkinned
{
    // This relies on the ModelManager setting the modelview matrix.  So don't clobber this until after this function is called.
    [self SetupSkinningState];
    
    Matrix44 modelViewMatrix, inverseTransposeModelView;
    glGetFloatv(GL_MODELVIEW_MATRIX, modelViewMatrix.mMatrix);
    
    InverseTranspose(&modelViewMatrix, &inverseTransposeModelView);
    
    if (mNumMatricesPerVertex == 0)
    {
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
    }
    else
    {
        NeonGLMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glLoadIdentity();
    }
    
    if (mClipPlaneEnabled)
    {
        if (mNumMatricesPerVertex > 0)
        {
            glEnable(GL_CLIP_PLANE1);
            
            Vector4 normalVec4, pointVec4;
            
            SetVec4From3(&normalVec4, &mClipPlane.mNormal, 0.0f);
            
            // Find an arbitrary point on our untransformed plane.  For ax + by + cz + d = 0, set x and y to zero and solve for z.  z = -d / c which is what the below corresponds to.
            pointVec4.mVector[x] = 0.0f;
            pointVec4.mVector[y] = 0.0f;
            pointVec4.mVector[z] = -(mClipPlane.mDistance / mClipPlane.mNormal.mVector[z]);
            pointVec4.mVector[w] = 1.0f;
            
            Vector4 transformedNormal, transformedPoint;
            
            // Transform the clip plane into eye space.  glClipPlane multiplies by the current modelview matrix (which in this case is identity).
            
            // Normals need to be transformed by inverse tranpose modelview matrix
            TransformVector4x4(&inverseTransposeModelView, &normalVec4, &transformedNormal);
            TransformVector4x4(&modelViewMatrix, &pointVec4, &transformedPoint);
            
            transformedNormal.mVector[w] = 0.0f;
            Normalize4(&transformedNormal);
            
            float planeEquation[4];
            
            planeEquation[0] = transformedNormal.mVector[x];
            planeEquation[1] = transformedNormal.mVector[y];
            planeEquation[2] = transformedNormal.mVector[z];
            planeEquation[3] = -(transformedNormal.mVector[x] * transformedPoint.mVector[x] + transformedNormal.mVector[y] * transformedPoint.mVector[y] + transformedNormal.mVector[z] * transformedPoint.mVector[z]);
            
            glClipPlanef(GL_CLIP_PLANE1, planeEquation);
        }
        else
        {
            NSAssert(FALSE, @"We don't have clip plane support implemented for this scenario.");
        }
    }
    
    [self SetupTextureState];
    [self SetupVertexBuffers];

    glDrawArrays(GL_TRIANGLES, 0, mNumVertices);
    
    [self CleanupDrawState];
    
    if (mNumMatricesPerVertex > 0)
    {
        glPopMatrix();
    }
    
    if (mClipPlaneEnabled)
    {
        glDisable(GL_CLIP_PLANE1);
    }
     
    NeonGLError();
}
#endif

-(void)SetupSkinningState
{
#if CPU_SKINNING
    [self SetupCPUSkinningState];
#else
    [self SetupGPUSkinningState];
#endif 
}

-(void)SetupGPUSkinningState
{
    if ((mNumMatricesPerVertex > 0) && (mSkeleton != NULL))
    {
        Matrix44 modelViewMatrix;
        glGetFloatv(GL_MODELVIEW_MATRIX, modelViewMatrix.mMatrix);
        
#if NEON_DEBUG
        GLint maxPaletteMatrices;
         
        NeonGLGetIntegerv(GL_MAX_PALETTE_MATRICES_OES, &maxPaletteMatrices);
        
        NSAssert([mSkeleton GetNumJoints] <= maxPaletteMatrices, @"Too many joints for Matrix Palette, set CPU_SKINNING=1");
#endif

        u32 numJoints = [mSkeleton GetNumJoints];
        
        // Set mJointMatrices to the matrices we'll put in the MatrixPalette, or use for CPU skinning
        for (int curJointIndex = 0; curJointIndex < numJoints; curJointIndex++)
        {
            Joint*      curJoint = [mSkeleton GetJointWithIdentifier:curJointIndex];
            Matrix44*   jointTransform = [curJoint GetNetTransform];
            Matrix44*   inverseBindPoseMatrix = [curJoint GetInverseBindPoseTransform];

            Matrix44 paletteMatrix;
        
            MatrixMultiply(&modelViewMatrix, jointTransform, &paletteMatrix);
            MatrixMultiply(&paletteMatrix, inverseBindPoseMatrix, &mJointMatrices[curJointIndex]);
            MatrixMultiply(&mJointMatrices[curJointIndex], &mBindShapeMatrix, &mJointMatrices[curJointIndex]);
        }
    
        glEnableClientState(GL_WEIGHT_ARRAY_OES);
        glEnableClientState(GL_MATRIX_INDEX_ARRAY_OES);
    
        glEnable(GL_MATRIX_PALETTE_OES);
        
        NeonGLMatrixMode(GL_MATRIX_PALETTE_OES);
                
        for (int curJointIndex = 0; curJointIndex < [mSkeleton GetNumJoints]; curJointIndex++)
        {
            glCurrentPaletteMatrixOES(curJointIndex);            
            glLoadMatrixf(mJointMatrices[curJointIndex].mMatrix);
        }
        
        // There appears to be a bug in the simulator.  If you want to use n matrices, n + 1 matrices must
        // be specified.  Possibly an allocation bug or something somewhere in the simulator (allocating n - 1
        // matrices of storage perhaps).
        
        glCurrentPaletteMatrixOES([mSkeleton GetNumJoints]);
        NeonGLMatrixMode(GL_MODELVIEW);
        
        glWeightPointerOES(mNumMatricesPerVertex, GL_FLOAT, mStride, (GLvoid*)((mPositionStride + mNormalStride + mTexcoordStride) * sizeof(float)));
        glMatrixIndexPointerOES(mNumMatricesPerVertex, GL_UNSIGNED_BYTE, mStride,
                                (GLvoid*)((mPositionStride + mNormalStride + mTexcoordStride + mNumMatricesPerVertex) * sizeof(float)));
    }
}

#if CPU_SKINNING
-(void)SetupCPUSkinningState
{
    if ((mNumMatricesPerVertex > 0) && (mSkeleton != NULL))
    {
        u32 numJoints = [mSkeleton GetNumJoints];
        
        Matrix44 modelViewMatrix;
        glGetFloatv(GL_MODELVIEW_MATRIX, modelViewMatrix.mMatrix);
        
        // Set mJointMatrices to the matrices we'll put in the MatrixPalette, or use for CPU skinning
        for (int curJointIndex = 0; curJointIndex < numJoints; curJointIndex++)
        {
            Joint*      curJoint = [mSkeleton GetJointWithIdentifier:curJointIndex];
            Matrix44*   jointTransform = [curJoint GetNetTransform];
            Matrix44*   inverseBindPoseMatrix = [curJoint GetInverseBindPoseTransform];

            Matrix44 paletteMatrix;
        
            MatrixMultiply(&modelViewMatrix, jointTransform, &paletteMatrix);
            MatrixMultiply(&paletteMatrix, inverseBindPoseMatrix, &mJointMatrices[curJointIndex]);
            MatrixMultiply(&mJointMatrices[curJointIndex], &mBindShapeMatrix, &mJointMatrices[curJointIndex]);
            InverseTranspose(&mJointMatrices[curJointIndex], &mJointMatricesInverseTranspose[curJointIndex]);
            
            mJointMatricesInverseTranspose[curJointIndex].mMatrix[12] = 0.0f;
            mJointMatricesInverseTranspose[curJointIndex].mMatrix[13] = 0.0f;
            mJointMatricesInverseTranspose[curJointIndex].mMatrix[14] = 0.0f;
        }
            
        for (int curVertex = 0; curVertex < mNumVertices; curVertex++)
        {
            float* vertexBase = (float*)(mStream + (mStride * curVertex));
            float* normalBase = (float*)(mStream + mNormalStride * sizeof(float) + (mStride * curVertex));
            unsigned char* jointIndexBase = (unsigned char*)(&mStream[(mPositionStride + mNormalStride + mTexcoordStride + mNumMatricesPerVertex) * sizeof(float)]) + (mStride * curVertex);
            float* weightBase = (float*)((&mStream[(mPositionStride + mNormalStride + mTexcoordStride) * sizeof(float)]) + (mStride * curVertex));
            
            float* writeStream = &mSkinnedPositions[curVertex * 3];
            float* normalStream = &mSkinnedNormals[curVertex * 3];
            
            Vector4 transformedVertex = { { 0.0, 0.0, 0.0, 0.0 } };
            Vector4 transformedNormal = { { 0.0, 0.0, 0.0, 0.0 } };
            
            Vector3 sourceVertex = { { vertexBase[0], vertexBase[1], vertexBase[2] } };
            Vector3 sourceNormal = { { normalBase[0], normalBase[1], normalBase[2] } };
            
            for (int curWeight = 0; curWeight < mNumMatricesPerVertex; curWeight++)
            {
                Vector4 partialVertex, partialNormal;
                                
                TransformVector4x3(&mJointMatrices[jointIndexBase[curWeight]], &sourceVertex, &partialVertex);                                
                TransformVector4x3(&mJointMatricesInverseTranspose[jointIndexBase[curWeight]], &sourceNormal, &partialNormal);
                                
                Scale4(&partialVertex, weightBase[curWeight]);
                Scale4(&partialNormal, weightBase[curWeight]);
                                
                Add4(&partialVertex, &transformedVertex, &transformedVertex);
                Add4(&partialNormal, &transformedNormal, &transformedNormal);
            }
            
            writeStream[0] = transformedVertex.mVector[x];
            writeStream[1] = transformedVertex.mVector[y];
            writeStream[2] = transformedVertex.mVector[z];
            
            normalStream[0] = transformedNormal.mVector[x];
            normalStream[1] = transformedNormal.mVector[y];
            normalStream[2] = transformedNormal.mVector[z];
        }
    }
}
#endif

-(void)SetupTextureState
{
    if (mTexture != NULL)
    {
        [mTexture Bind];

#if !TARGET_IPHONE_SIMULATOR
        if (mGlowEnabled)
        {
            // Set up texture unit 1.
            
            NeonGLActiveTexture(GL_TEXTURE1);
            glClientActiveTexture(GL_TEXTURE1);
            
            NeonGLEnable(GL_TEXTURE_2D);
            
            [mTexture Bind];
            
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                      
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
            glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD);
            
            glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
            glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_CONSTANT);
            
            glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
            glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);

            glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_ADD);
            
            glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
            glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_CONSTANT);
            
            glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
            glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);

            Vector4 unit2Color = { { mGlowAmount, mGlowAmount, mGlowAmount, 0.0 } };
            glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, unit2Color.mVector);
            
            glTexCoordPointer(mTexcoordStride, GL_FLOAT, mStride, (GLvoid*)((mPositionStride + mNormalStride) * sizeof(float)));
            
            NeonGLActiveTexture(GL_TEXTURE0);
            glClientActiveTexture(GL_TEXTURE0);
        }
#endif
    }
    else
    {
        NeonGLDisable(GL_TEXTURE_2D);
    }
}

-(void)SetupVertexBuffers
{
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

#if CPU_SKINNING
    [self SetupCPUVertexBuffers];
#else
    [self SetupGPUVertexBuffers];
#endif 
}

-(void)SetupGPUVertexBuffers
{
    glVertexPointer(mPositionStride, GL_FLOAT, mStride, (GLvoid*)(0));
    glNormalPointer(GL_FLOAT, mStride, (GLvoid*)(mPositionStride * sizeof(float)));
    
    [self SetupTextureBufferState];
}

#if CPU_SKINNING
-(void)SetupCPUVertexBuffers
{
    if (mNumMatricesPerVertex > 0)
    {
        if (mSkeleton != NULL)
        {
            glVertexPointer(mPositionStride, GL_FLOAT, 0, mSkinnedPositions);
        }
        else
        {
            glVertexPointer(mPositionStride, GL_FLOAT, mStride, mStream);
        }
    }
    else
    {
        glVertexPointer(mPositionStride, GL_FLOAT, mStride, (GLvoid*)(0));
    }

    if (mNumMatricesPerVertex == 0)
    {
        glNormalPointer(GL_FLOAT, mStride, (GLvoid*)(mPositionStride * sizeof(float)));
    }
    else
    {
        if (mSkeleton != NULL)
        {
            glNormalPointer(GL_FLOAT, 0, mSkinnedNormals);
        }
        else
        {
            glNormalPointer(GL_FLOAT, mStride, (GLvoid*)((mPositionStride * sizeof(float)) + mStream));
        }
    }
    
    [self SetupTextureBufferState];
}
#endif

-(void)SetupTextureBufferState
{
#if CPU_SKINNING   
    if (mNumMatricesPerVertex == 0)
#endif
    {
        glTexCoordPointer(mTexcoordStride, GL_FLOAT, mStride, (GLvoid*)((mPositionStride + mNormalStride) * sizeof(float)));
    }
#if CPU_SKINNING
    else
    {
        glTexCoordPointer(mTexcoordStride, GL_FLOAT, mStride, (GLvoid*)(((mPositionStride + mNormalStride) * sizeof(float)) + mStream));
    }
#endif
}

-(void)CleanupDrawState
{
    if (mGlowEnabled)
    {
        NeonGLActiveTexture(GL_TEXTURE1);
        glClientActiveTexture(GL_TEXTURE1);
        
        NeonGLBindTexture(GL_TEXTURE_2D, 0);
        NeonGLDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        [Texture Unbind];
    
        // Restore texture unit 0 as the active texture unit - then the rest of the game engine proceeds as normal.
        NeonGLActiveTexture(GL_TEXTURE0);
        glClientActiveTexture(GL_TEXTURE0);
    }
           
    [Texture Unbind];
    
    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);

#if !CPU_SKINNING
    if ((mNumMatricesPerVertex > 0) && (mSkeleton != NULL))
    {
        glDisableClientState(GL_WEIGHT_ARRAY_OES);
        glDisableClientState(GL_MATRIX_INDEX_ARRAY_OES);
    
        glDisable(GL_MATRIX_PALETTE_OES);
    }
#endif
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

-(void)BindSkeleton:(Skeleton*)inSkeleton
{
    [super BindSkeleton:inSkeleton];
    
    if (mJointMatrices != NULL)
    {
        free(mJointMatrices);
    }
    
    if (mJointMatricesInverseTranspose != NULL)
    {
        free(mJointMatricesInverseTranspose);
    }
    
    mJointMatrices = (Matrix44*)malloc(sizeof(Matrix44) * [inSkeleton GetNumJoints]);
    mJointMatricesInverseTranspose = (Matrix44*)malloc(sizeof(Matrix44) * [inSkeleton GetNumJoints]);
}

-(void)BindSkeletonWithFilename:(NSString*)inFilename
{
    [super BindSkeletonWithFilename:inFilename];
    
    if (mJointMatrices != NULL)
    {
        free(mJointMatrices);
    }
    
    if (mJointMatricesInverseTranspose != NULL)
    {
        free(mJointMatricesInverseTranspose);
    }    
    
    mJointMatrices = (Matrix44*)malloc(sizeof(Matrix44) * [mSkeleton GetNumJoints]);
    mJointMatricesInverseTranspose = (Matrix44*)malloc(sizeof(Matrix44) * [mSkeleton GetNumJoints]);
}

-(int)CalculateNumJointsIndexed
{
    int retVal = -1;
    
    if (mNumMatricesPerVertex != 0)
    {
        unsigned char* matrixIndexBase = mStream + ((mPositionStride + mNormalStride + mTexcoordStride + mNumMatricesPerVertex) * sizeof(float));
        
        for (int curVertexIndex = 0; curVertexIndex < mNumVertices; curVertexIndex++)
        {
            for (int curMatrix = 0; curMatrix < mNumMatricesPerVertex; curMatrix++)
            {
                int testMatrix = (int)matrixIndexBase[mStride * curVertexIndex + curMatrix];
                
                retVal = max(retVal, testMatrix);
            }
        }
    }
    
    return (retVal + 1);
}

@end