//
//  SimpleModel.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "Model.h"

@interface SimpleModel : Model
{
    unsigned char*  mStream;
    u32     mNumVertices;
    
    u32     mPositionStride;
    u32     mNormalStride;
    u32     mTexcoordStride;
    u32     mNumMatricesPerVertex;
    u32     mStride;
    
    Matrix44*   mJointMatrices;
    Matrix44*   mJointMatricesInverseTranspose;
    
    Matrix44    mBindShapeMatrix;
    
    GLuint  mVBO;
    
#if CPU_SKINNING
    float*   mSkinnedPositions;
    float*   mSkinnedNormals;
#endif
}

-(SimpleModel*)InitWithData:(NSData*)inData;
-(void)dealloc;

-(void)Draw;
-(void)DrawGPUSkinned;

-(void)SetupSkinningState;
-(void)SetupGPUSkinningState;

-(void)SetupVertexBuffers;
-(void)SetupGPUVertexBuffers;

#if CPU_SKINNING
-(void)DrawCPUSkinned;
-(void)SetupCPUSkinningState;
-(void)SetupCPUVertexBuffers;
#endif

-(void)SetupTextureState;
-(void)SetupTextureBufferState;

-(void)CleanupDrawState;

-(void)Update:(u32)inFrameTime;

-(void)GenerateGLBoundingBox;
-(void)GenerateVBO;

-(void)BindSkeleton:(Skeleton*)inSkeleton;
-(void)BindSkeletonWithFilename:(NSString*)inFilename;

-(int)CalculateNumJointsIndexed;

@end