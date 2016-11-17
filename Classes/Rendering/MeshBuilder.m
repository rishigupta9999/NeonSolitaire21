//
//  MeshBuilder.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "MeshBuilder.h"
#import "Texture.h"
#import "TextureAtlas.h"
#import "ModelManager.h"

#define INITIAL_MESH_BUILDER_ENTRIES    (32)

void InitializeAttribute(MeshBuilderVertexAttribute* outAttribute)
{
    outAttribute->mNumComponentsPerVertex = 0;
    outAttribute->mNumVertices = 0;
    outAttribute->mAttributeData = NULL;
    outAttribute->mDataOwner = FALSE;
}

@implementation MeshBuilderEntry

-(MeshBuilderEntry*)Init
{
    InitializeAttribute(&mPositionInfo);
    InitializeAttribute(&mNormalInfo);
    InitializeAttribute(&mTexcoordInfo);
    InitializeAttribute(&mColorInfo);
            
    mNumVertices = 0;
    
    SetIdentity(&mTransform);
    
    mTexture = NULL;
    
    mBlendEnabled = FALSE;
    mSrcBlend = GL_SRC_ALPHA;
    mDestBlend = GL_ONE_MINUS_SRC_ALPHA;
    
    mPrimitiveType = GL_TRIANGLES;
    
    mOwnerObject = NULL;
    mOwnerIdentifier = NULL;
    
    return self;
}

-(void)dealloc
{
    if ((mPositionInfo.mAttributeData != NULL) && (mPositionInfo.mDataOwner))
    {
        free(mPositionInfo.mAttributeData);
    }
    
    if ((mNormalInfo.mAttributeData != NULL) && (mNormalInfo.mDataOwner))
    {
        free(mNormalInfo.mAttributeData);
    }
    
    if ((mTexcoordInfo.mAttributeData != NULL) && (mTexcoordInfo.mDataOwner))
    {
        free(mTexcoordInfo.mAttributeData);
    }
    
    if ((mColorInfo.mAttributeData != NULL) && (mColorInfo.mDataOwner))
    {
        free(mColorInfo.mAttributeData);
    }
    
    [mOwnerIdentifier release];
    
    [super dealloc];
}

@end

@implementation MeshBuilder

@synthesize startViewport = mStartViewport;
@synthesize endViewport = mEndViewport;

-(MeshBuilder*)Init
{
    mEntries = [[NSMutableArray alloc] initWithCapacity:INITIAL_MESH_BUILDER_ENTRIES];
    mCurEntry = NULL;
        
    InitializeAttribute(&mPositionStream);
    InitializeAttribute(&mNormalStream);
    InitializeAttribute(&mTexcoordStream);
    InitializeAttribute(&mColorStream);
    
    mIndexBuffer = NULL;
    
    mTextureAtlas = NULL;
    
    mBlendingEnabled = FALSE;
    mSrcBlendFunc = GL_SRC_ALPHA;
    mDestBlendFunc = GL_ONE_MINUS_SRC_ALPHA;
    
    mNumVertices = 0;
    
    mIncrementDepth = FALSE;
    
    mStartViewport = MODELMANAGER_VIEWPORT_INVALID;
    mEndViewport = MODELMANAGER_VIEWPORT_INVALID;
    
    return self;
}

-(void)dealloc
{
    [mEntries release];
    
    if (mPositionStream.mAttributeData != NULL)
    {
        free(mPositionStream.mAttributeData);
    }
    
    if (mNormalStream.mAttributeData != NULL)
    {
        free(mNormalStream.mAttributeData);
    }
    
    if (mTexcoordStream.mAttributeData != NULL)
    {
        free(mTexcoordStream.mAttributeData);
    }
    
    if (mColorStream.mAttributeData != NULL)
    {
        free(mColorStream.mAttributeData);
    }
    
    if (mIndexBuffer != NULL)
    {
        free(mIndexBuffer);
    }
    
    [mTextureAtlas release];
    
    NSAssert(mCurEntry == NULL, @"Unfinished mesh entry, this should never happen");
    
    [super dealloc];
}

-(void)SetIncrementDepth:(BOOL)inIncrementDepth
{
    mIncrementDepth = inIncrementDepth;
}

-(void)StartMeshWithOwner:(GameObject*)inOwnerObject identifier:(const char*)inIdentifier
{
    if (true)//(mState == MESH_BUILDER_UNINITIALIZED)
    {
#if NEON_DEBUG
        // Ensure that no other objects are using the same combination of OwnerObject / Identifier.
        for (MeshBuilderEntry* curEntry in mEntries)
        {
            if ((curEntry->mOwnerObject == inOwnerObject) && 
                ([curEntry->mOwnerIdentifier compare:[NSString stringWithUTF8String:inIdentifier]] == NSOrderedSame))
            {
                NSAssert(FALSE, @"There already exists an entry with the same owner and identifier");
            }
        }
#endif

        mCurEntry = [(MeshBuilderEntry*)[MeshBuilderEntry alloc] Init];
        
        mCurEntry->mOwnerObject = inOwnerObject;
        mCurEntry->mOwnerIdentifier = [[NSString alloc] initWithUTF8String:inIdentifier];
    }
    else
    {
        for (MeshBuilderEntry* curEntry in mEntries)
        {
            if ((curEntry->mOwnerObject == inOwnerObject) && ([curEntry->mOwnerIdentifier compare:[NSString stringWithUTF8String:inIdentifier]] == NSOrderedSame))
            {
                mCurEntry = curEntry;
                break;
            }
        }
        
        NSAssert(mCurEntry != NULL, @"Couldn't find mesh entry corresponding to the passed in owner.");
    }
}

-(void)EndMesh
{
    NSAssert(mCurEntry->mOwnerObject != NULL, @"No owner was specified for this mesh builder entry");
    NSAssert(mCurEntry->mOwnerIdentifier != NULL, @"No owner identifier was specified for this mesh builder entry");
    
    if (true)//(mState == MESH_BUILDER_UNINITIALIZED)
    {
        [mEntries addObject:mCurEntry];
        [mCurEntry release];
    }
    
    mCurEntry = NULL;
}

-(void)SetPositionPointer:(u8*)inPosition numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData
{
#if 0
    if (mState == MESH_BUILDER_INITIALIZED)
    {
        NSAssert(inNumComponents == mCurEntry->mPositionInfo.mNumComponentsPerVertex, @"Mismatch");
        NSAssert(inNumVertices == mCurEntry->mPositionInfo.mNumVertices, @"Mismatch");
        NSAssert(inCopyData == mCurEntry->mPositionInfo.mDataOwner, @"Mismatch");
    }
#endif
    
    [self SetAttributePointer:&mCurEntry->mPositionInfo data:inPosition numComponents:inNumComponents numVertices:inNumVertices copyData:inCopyData];
}

-(void)SetNormalPointer:(u8*)inNormal numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData
{
#if 0
    if (mState == MESH_BUILDER_INITIALIZED)
    {
        NSAssert(inNumComponents == mCurEntry->mNormalInfo.mNumComponentsPerVertex, @"Mismatch");
        NSAssert(inNumVertices == mCurEntry->mNormalInfo.mNumVertices, @"Mismatch");
        NSAssert(inCopyData == mCurEntry->mNormalInfo.mDataOwner, @"Mismatch");
    }
#endif    
    [self SetAttributePointer:&mCurEntry->mNormalInfo data:inNormal numComponents:inNumComponents numVertices:inNumVertices copyData:inCopyData];
}

-(void)SetTexcoordPointer:(u8*)inTexcoord numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData
{
#if 0
    if (mState == MESH_BUILDER_INITIALIZED)
    {
        NSAssert(inNumComponents == mCurEntry->mTexcoordInfo.mNumComponentsPerVertex, @"Mismatch");
        NSAssert(inNumVertices == mCurEntry->mTexcoordInfo.mNumVertices, @"Mismatch");
        NSAssert(inCopyData == mCurEntry->mTexcoordInfo.mDataOwner, @"Mismatch");
    }
#endif    
    [self SetAttributePointer:&mCurEntry->mTexcoordInfo data:inTexcoord numComponents:inNumComponents numVertices:inNumVertices copyData:inCopyData];
}

-(void)SetColorPointer:(u8*)inColor numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData
{
#if 0
    if (mState == MESH_BUILDER_INITIALIZED)
    {
        NSAssert(inNumComponents == mCurEntry->mColorInfo.mNumComponentsPerVertex, @"Mismatch");
        NSAssert(inNumVertices == mCurEntry->mColorInfo.mNumVertices, @"Mismatch");
        NSAssert(inCopyData == mCurEntry->mColorInfo.mDataOwner, @"Mismatch");
    }
#endif    
    [self SetAttributePointer:&mCurEntry->mColorInfo data:inColor numComponents:inNumComponents numVertices:inNumVertices copyData:inCopyData];
}

-(void)SetNumVertices:(u32)inNumVertices
{
#if 0
    if (mState == MESH_BUILDER_INITIALIZED)
    {
        NSAssert(inNumVertices == mCurEntry->mNumVertices, @"Mismatch");
    }
#endif    
    mCurEntry->mNumVertices = inNumVertices;
}

-(void)SetPrimitiveType:(GLenum)inPrimitiveType
{
    // Changing the primitive type (eg: from GL_TRIANGLES to GL_TRIANGLE_STRIP)
    // may require us to reallocate the vertex attribute streams and shuffle things
    // around.  That's simply more trouble than it's worth.
    //
    // That's purely academic at the moment, since we only support triangle strips
    // at the moment (more convenient for the UI).
    
    NSAssert(inPrimitiveType == GL_TRIANGLE_STRIP, @"We only support GL_TRIANGLE_STRIP at the moment");
#if 0    
    if (mState == MESH_BUILDER_INITIALIZED)
    {
        NSAssert(inPrimitiveType == mCurEntry->mPrimitiveType, @"Mismatch");
    }
#endif    
    mCurEntry->mPrimitiveType = inPrimitiveType;
}

-(void)SetTransform:(Matrix44*)inTransform
{
    CloneMatrix44(inTransform, &mCurEntry->mTransform);
    
    InverseTranspose(&mCurEntry->mTransform, &mCurEntry->mInverseTransposeTransform);
}

-(void)SetTexture:(Texture*)inTexture
{
    mCurEntry->mTexture = inTexture;
}

-(void)SetBlendEnabled:(BOOL)inBlendEnabled
{
    mCurEntry->mBlendEnabled = inBlendEnabled;
}

-(void)SetBlendFunc:(GLenum)inSrcBlend dest:(GLenum)inDestBlend
{
    mCurEntry->mSrcBlend = inSrcBlend;
    mCurEntry->mDestBlend = inDestBlend;
}

-(void)SetAttributePointer:(MeshBuilderVertexAttribute*)inAttribute data:(u8*)data numComponents:(u8)inNumComponents numVertices:(u32)inNumVertices copyData:(BOOL)inCopyData
{
    inAttribute->mNumComponentsPerVertex = inNumComponents;
    inAttribute->mNumVertices = inNumVertices;
    
    NSAssert(inAttribute->mAttributeData == NULL, @"We have attribute data even though the MeshBuilder is on the first frame and hasn't collected any.");
    
    if (inCopyData)
    {
        inAttribute->mAttributeData = malloc(inAttribute->mNumComponentsPerVertex * inAttribute->mNumVertices * sizeof(float));
        inAttribute->mDataOwner = TRUE;
        
        memcpy(inAttribute->mAttributeData, data, inAttribute->mNumComponentsPerVertex * inAttribute->mNumVertices * sizeof(float));
    }
    else
    {
        inAttribute->mAttributeData = data;
    }
}

-(void)FinishPass
{
    int numEntries = [mEntries count];
    
    if (numEntries > 0)
    {
        [self SetupMeshProperties];

        int numTriangles = 0;
        
        for (MeshBuilderEntry* curEntry in mEntries)
        {
            numTriangles += curEntry->mNumVertices - 2;
        }
        
        switch(mPrimitiveType)
        {
            case GL_TRIANGLES:
            {
                NSAssert(FALSE, @"This is unsupported presently, but should be easy to add.");
                break;
            }
            
            case GL_TRIANGLE_STRIP:
            {
                mNumVertices = numTriangles * 3;
                break;
            }
        }
        
        [self AllocateStreams];
        
        int totalVertexIndex = 0;
        int totalTriangleIndex = 0;
        
        for (int curEntryIndex = 0; curEntryIndex < numEntries; curEntryIndex++)
        {
            MeshBuilderEntry* curEntry = [mEntries objectAtIndex:curEntryIndex];
                        
            if (mPositionStream.mAttributeData != NULL)
            {
                int writeIndex = 0;
                
                for (int readIndex = 0; readIndex < curEntry->mNumVertices; readIndex++)
                {
                    Vector4 outputVertex;
                    
                    u32 readOffsetBytes = readIndex * curEntry->mPositionInfo.mNumComponentsPerVertex * sizeof(float); 

                    float* readBase = (float*)(curEntry->mPositionInfo.mAttributeData + readOffsetBytes);
                                                
                    if (mPositionStream.mNumComponentsPerVertex == 3)
                    {
                        Vector3 inputVertex = { { readBase[0], readBase[1], readBase[2] } };
                        
                        TransformVector4x3(&curEntry->mTransform, &inputVertex, &outputVertex);
                        
                        if (mIncrementDepth)
                        {
							// Strictly speaking, the incrementing should pull successive triangles closer to the camera (instead of raising vertically).
							// We can use an even smaller epsilon that way, but that takes more work to calculate.

                            outputVertex.mVector[y] += curEntryIndex * SMALL_EPSILON;
                        }
                    }
                    else
                    {
                        NSAssert(FALSE, @"Only 3 component positions are currently supported.");
                    }
                    
                    memcpy( mPositionStream.mAttributeData + ((writeIndex + totalVertexIndex) * mPositionStream.mNumComponentsPerVertex * sizeof(float)),
                            outputVertex.mVector,
                            mPositionStream.mNumComponentsPerVertex * sizeof(float));
                    
                    writeIndex++;
                }
            }
            
            if (mNormalStream.mAttributeData != NULL)
            {
                int writeIndex = 0;
                
                for (int readIndex = 0; readIndex < curEntry->mNumVertices; readIndex++)
                {
                    Vector4 outputVertex;
                    
                    u32 readOffsetBytes = readIndex * curEntry->mNormalInfo.mNumComponentsPerVertex * sizeof(float); 

                    float* readBase = (float*)(curEntry->mNormalInfo.mAttributeData + readOffsetBytes);
                                                
                    if (mNormalStream.mNumComponentsPerVertex == 3)
                    {
                        Vector3 inputVertex = { { readBase[0], readBase[1], readBase[2] } };
                        
                        TransformVector4x3(&curEntry->mInverseTransposeTransform, &inputVertex, &outputVertex);
                    }
                    else
                    {
                        NSAssert(FALSE, @"Only 3 component normals are currently supported.");
                    }
                    
                    memcpy( mNormalStream.mAttributeData + ((writeIndex + totalVertexIndex) * mNormalStream.mNumComponentsPerVertex * sizeof(float)),
                            outputVertex.mVector,
                            mNormalStream.mNumComponentsPerVertex * sizeof(float));
                    
                    writeIndex++;
                }
            }
            
            if (mTexcoordStream.mAttributeData != NULL)
            {
                // Actual triangles
                memcpy( mTexcoordStream.mAttributeData + (totalVertexIndex * mTexcoordStream.mNumComponentsPerVertex * sizeof(float)),
                        curEntry->mTexcoordInfo.mAttributeData,
                        mTexcoordStream.mNumComponentsPerVertex * sizeof(float) * curEntry->mNumVertices);
            }

            if (mColorStream.mAttributeData != NULL)
            {
                memcpy( mColorStream.mAttributeData + (totalVertexIndex * mColorStream.mNumComponentsPerVertex * sizeof(float)),
                        curEntry->mColorInfo.mAttributeData,
                        mColorStream.mNumComponentsPerVertex * sizeof(float) * curEntry->mNumVertices);
            }
                        
            int numTriangles = 0;
            
            switch(mPrimitiveType)
            {
                case GL_TRIANGLE_STRIP:
                {
                    numTriangles = curEntry->mNumVertices - 2;
                    break;
                }
                
                case GL_TRIANGLES:
                {
                    NSAssert(FALSE, @"GL_TRIANGLES is currently unsupported");
                    break;
                }
            }
                        
            for (int curTriangle = 0; curTriangle < numTriangles; curTriangle++)
            {
                for (int curVertex = 0; curVertex < 3; curVertex++)
                {
                    int writeOffset = ((totalTriangleIndex + curTriangle) * 3) + curVertex;
                    
                    switch(mPrimitiveType)
                    {
                        case GL_TRIANGLE_STRIP:
                        {
                            int useVertex = curVertex;
                            
                            if (curTriangle > 0)
                            {
                                if (curVertex <= 1)
                                {
                                    useVertex = 1 - useVertex;
                                }
                            }
                            
                            mIndexBuffer[writeOffset] = totalVertexIndex + useVertex + curTriangle;
                            break;
                        }
                        
                        case GL_TRIANGLES:
                        {
                            NSAssert(FALSE, @"GL_TRIANGLES is currently unsupported");
                            break;
                        }
                    }
                }
            }
            
            totalTriangleIndex += numTriangles;
            totalVertexIndex += curEntry->mNumVertices;
        }
    }
    
    [self DrawCoalescedMesh];
    [self CleanupPass];
}

-(void)CleanupPass
{
    [mEntries removeAllObjects];
    
    if (mIndexBuffer != NULL)
    {
        free(mIndexBuffer);
        mIndexBuffer = NULL;
    }
    
    [mTextureAtlas release];
    mTextureAtlas = NULL;
    
    mNumVertices = 0;
}

-(void)SetupMeshProperties
{
    // Make sure all entries have matching attributes so that they can be rendered in a single pass
    MeshBuilderEntry* firstEntry = [mEntries objectAtIndex:0];
    
    u32 positionNumComponents = firstEntry->mPositionInfo.mNumComponentsPerVertex;;
    u32 normalNumComponents = firstEntry->mNormalInfo.mNumComponentsPerVertex;
    u32 texcoordNumComponents = firstEntry->mTexcoordInfo.mNumComponentsPerVertex;
    u32 colorNumComponents = firstEntry->mColorInfo.mNumComponentsPerVertex;
    
    Texture* refTexture = firstEntry->mTexture;

#if NEON_DEBUG
    TextureAtlas* refAtlas = firstEntry->mTexture->mParams.mTextureAtlas;
#endif

    BOOL refBlendEnabled = firstEntry->mBlendEnabled;
    GLenum refSrcBlend = firstEntry->mSrcBlend;
    GLenum refDestBlend = firstEntry->mDestBlend;
    
    GLenum refPrimitiveType = firstEntry->mPrimitiveType;
        
#if NEON_DEBUG        
    int numEntries = [mEntries count];

    for (int curEntryIndex = 1; curEntryIndex < numEntries; curEntryIndex++)
    {
        MeshBuilderEntry* curEntry = [mEntries objectAtIndex:curEntryIndex];
        
        if (    (curEntry->mTexture->mParams.mTextureAtlas != refAtlas) || ((refAtlas == NULL) && (curEntry->mTexture != refTexture)) ||
                (curEntry->mBlendEnabled != refBlendEnabled) ||
                (curEntry->mSrcBlend != refSrcBlend) ||
                (curEntry->mDestBlend != refDestBlend) ||
                (curEntry->mPositionInfo.mNumComponentsPerVertex != positionNumComponents) ||
                (curEntry->mNormalInfo.mNumComponentsPerVertex != normalNumComponents) ||
                (curEntry->mTexcoordInfo.mNumComponentsPerVertex != texcoordNumComponents) ||
                (curEntry->mColorInfo.mNumComponentsPerVertex != colorNumComponents) ||
                (curEntry->mPrimitiveType != refPrimitiveType)  )
        {
            NSAssert(FALSE, @"Mesh builder entries do not have the same parameters.  The drawing cannot be done in one pass.");
        }
    }
#endif

    mTextureAtlas = refTexture->mParams.mTextureAtlas;
    [mTextureAtlas retain];
    
    mBlendingEnabled = refBlendEnabled;
    mSrcBlendFunc = refSrcBlend;
    mDestBlendFunc = refDestBlend;
    
    mPrimitiveType = refPrimitiveType;
    
    if (positionNumComponents > 0)
    {
        mPositionStream.mNumComponentsPerVertex = positionNumComponents;
    }
    
    if (normalNumComponents > 0)
    {
        mNormalStream.mNumComponentsPerVertex = normalNumComponents;
    }

    if (texcoordNumComponents > 0)
    {
        mTexcoordStream.mNumComponentsPerVertex = texcoordNumComponents;
    }

    if (colorNumComponents > 0)
    {
        mColorStream.mNumComponentsPerVertex = colorNumComponents;
    }
}

-(void)AllocateStreams
{
    if (mPositionStream.mNumComponentsPerVertex > 0)
    {
        mPositionStream.mNumVertices = mNumVertices;
        
        if (mPositionStream.mAttributeData != NULL)
        {
            free(mPositionStream.mAttributeData);
            mPositionStream.mAttributeData = NULL;
        }
        
        mPositionStream.mAttributeData = malloc(mPositionStream.mNumComponentsPerVertex * mPositionStream.mNumVertices * sizeof(float));
    }
    
    if (mNormalStream.mNumComponentsPerVertex > 0)
    {
        mNormalStream.mNumVertices = mNumVertices;
        
        if (mNormalStream.mAttributeData != NULL)
        {
            free(mNormalStream.mAttributeData);
            mNormalStream.mAttributeData = NULL;
        }

        mNormalStream.mAttributeData = malloc(mNormalStream.mNumComponentsPerVertex * mNormalStream.mNumVertices * sizeof(float));
    }

    if (mTexcoordStream.mNumComponentsPerVertex > 0)
    {
        mTexcoordStream.mNumVertices = mNumVertices;
        
        if (mTexcoordStream.mAttributeData != NULL)
        {
            free(mTexcoordStream.mAttributeData);
            mTexcoordStream.mAttributeData = NULL;
        }

        mTexcoordStream.mAttributeData = malloc(mTexcoordStream.mNumComponentsPerVertex * mTexcoordStream.mNumVertices * sizeof(float));
    }

    if (mColorStream.mNumComponentsPerVertex > 0)
    {
        mColorStream.mNumVertices = mNumVertices;
        
        if (mColorStream.mAttributeData != NULL)
        {
            free(mColorStream.mAttributeData);
            mColorStream.mAttributeData = NULL;
        }
        
        mColorStream.mAttributeData = malloc(mColorStream.mNumComponentsPerVertex * mColorStream.mNumVertices * sizeof(float));
    }
    
    mIndexBuffer = malloc(sizeof(u16) * mNumVertices);
}

-(void)DrawCoalescedMesh
{
    // Don't thrash OpenGL state if we have nothing to draw.
    
    if (mNumVertices == 0)
    {
        return;
    }
    
    GLState glState;
    SaveGLState(&glState);
    
    if (mStartViewport != MODELMANAGER_VIEWPORT_INVALID)
    {
        [[ModelManager GetInstance] SetupViewport:mStartViewport];
    }
    
    if (mPositionStream.mAttributeData != NULL)
    {
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(mPositionStream.mNumComponentsPerVertex, GL_FLOAT, 0, mPositionStream.mAttributeData);
		
		static BOOL printVertexPositions = FALSE;
		
		if (printVertexPositions)
		{
			for (int i = 0; i < mPositionStream.mNumVertices; i++)
			{
				float* base = (float*)&mPositionStream.mAttributeData[i * sizeof(float) * 3];
				
				NSLog(@"%f, %f, %f\n", base[0], base[1], base[2]);
			}
		}
    }
    
    glDisableClientState(GL_NORMAL_ARRAY);
    
    if (mNormalStream.mAttributeData != NULL)
    {
        glEnableClientState(GL_NORMAL_ARRAY);
        glNormalPointer(GL_FLOAT, 0, mNormalStream.mAttributeData);
    }

    if (mTexcoordStream.mAttributeData != NULL)
    {
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(mTexcoordStream.mNumComponentsPerVertex, GL_FLOAT, 0, mTexcoordStream.mAttributeData);
    }

    if (mColorStream.mAttributeData != NULL)
    {
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(mColorStream.mNumComponentsPerVertex, GL_FLOAT, 0, mColorStream.mAttributeData);
    }
    
    if (mTextureAtlas != NULL)
    {
        [mTextureAtlas Bind];
    }
    else
    {
        MeshBuilderEntry* entry = [mEntries objectAtIndex:0];
        
        [entry->mTexture Bind];
    }
    
    if (mBlendingEnabled)
    {
        NeonGLEnable(GL_BLEND);
        NeonGLBlendFunc(mSrcBlendFunc, mDestBlendFunc);
    }
    
    glDrawElements(GL_TRIANGLES, mNumVertices, GL_UNSIGNED_SHORT, mIndexBuffer);
    
    NeonGLError();

    RestoreGLState(&glState);
}

@end