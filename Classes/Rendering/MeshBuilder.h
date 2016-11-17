//
//  MeshBuilder.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "NeonMath.h"
#import "ModelManagerTypes.h"

@class Texture;
@class TextureAtlas;
@class GameObject;

typedef struct
{
    u8      mNumComponentsPerVertex;
    u32     mNumVertices;
    u8*     mAttributeData;
    BOOL    mDataOwner;
} MeshBuilderVertexAttribute;

@interface MeshBuilderEntry : NSObject
{
    @public
        MeshBuilderVertexAttribute  mPositionInfo;
        MeshBuilderVertexAttribute  mNormalInfo;
        MeshBuilderVertexAttribute  mTexcoordInfo;
        MeshBuilderVertexAttribute  mColorInfo;
        
        u32                     mNumVertices;
        
        Matrix44                mTransform;
        Matrix44                mInverseTransposeTransform;
        
        Texture*                mTexture;
        
        BOOL                    mBlendEnabled;
        GLenum                  mSrcBlend;
        GLenum                  mDestBlend;
        
        GLenum                  mPrimitiveType;
        
        GameObject*             mOwnerObject;
        NSString*               mOwnerIdentifier;
}

-(MeshBuilderEntry*)Init;
-(void)dealloc;

@end

@interface MeshBuilder : NSObject
{
    NSMutableArray*     mEntries;
    MeshBuilderEntry*   mCurEntry;
    
    MeshBuilderVertexAttribute  mPositionStream;
    MeshBuilderVertexAttribute  mNormalStream;
    MeshBuilderVertexAttribute  mTexcoordStream;
    MeshBuilderVertexAttribute  mColorStream;

    u16*                        mIndexBuffer;
    
    TextureAtlas*       mTextureAtlas;
    BOOL                mBlendingEnabled;
    GLenum              mSrcBlendFunc;
    GLenum              mDestBlendFunc;
    
    GLenum              mPrimitiveType;
    
    u32                 mNumVertices;
    
    BOOL                mIncrementDepth;
}

@property ModelManagerViewport startViewport;
@property ModelManagerViewport endViewport;

-(MeshBuilder*)Init;
-(void)dealloc;

-(void)SetIncrementDepth:(BOOL)inIncrementDepth;

-(void)StartMeshWithOwner:(GameObject*)inOwnerObject identifier:(const char*)inIdentifier;
-(void)EndMesh;

-(void)SetPositionPointer:(u8*)inPosition numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData;
-(void)SetNormalPointer:(u8*)inNormal numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData;
-(void)SetTexcoordPointer:(u8*)inTexcoord numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData;
-(void)SetColorPointer:(u8*)inColor numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData;

-(void)SetNumVertices:(u32)inNumVertices;
-(void)SetPrimitiveType:(GLenum)inPrimitiveType;

-(void)SetTransform:(Matrix44*)inTransform;
-(void)SetTexture:(Texture*)inTexture;

-(void)SetBlendEnabled:(BOOL)inBlendEnabled;
-(void)SetBlendFunc:(GLenum)inSrcBlend dest:(GLenum)inDestBlend;

-(void)SetAttributePointer:(MeshBuilderVertexAttribute*)inAttribute data:(u8*)data numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData;

-(void)FinishPass;
-(void)CleanupPass;
-(void)SetupMeshProperties;
-(void)AllocateStreams;
-(void)DrawCoalescedMesh;

@end