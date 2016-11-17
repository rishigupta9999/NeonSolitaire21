//
//  GameObjectBatch.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "GameObjectBatch.h"
#import "UIObject.h"
#import "TextureAtlas.h"
#import "MeshBuilder.h"
#import "GameObjectManager.h"

#define GAMEOBJECT_BATCH_INITIAL_CAPACITY   (8)
#define TEXTURE_ATLAS_PADDING_SIZE          (2)

@implementation GameObjectBatch

@synthesize finalized = mFinalized;

-(GameObjectBatch*)InitWithParams:(GameObjectBatchParams*)inParams
{
    [super Init];
    
    memcpy(&mParams, inParams, sizeof(GameObjectBatchParams));
    
    mGameObjects = [[NSMutableArray alloc] initWithCapacity:GAMEOBJECT_BATCH_INITIAL_CAPACITY];
    
    [self InitTextureAtlasWithParams:NULL];
            
    mFinalized = FALSE;
    mVisible = TRUE;
    
    return self;
}

-(void)dealloc
{    
    [mGameObjects release];
    [mTextureAtlas release];
    [mMeshBuilder release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(GameObjectBatchParams*)outParams
{
    outParams->mUseAtlas = FALSE;
    outParams->mAtlasHeightHint = TEXTURE_ATLAS_DIMENSION_INVALID;
    outParams->mAtlasWidthHint = TEXTURE_ATLAS_DIMENSION_INVALID;
}

-(void)InitTextureAtlasWithParams:(TextureAtlasParams*)inParams
{
    if (mParams.mUseAtlas)
    {
        if (inParams == NULL)
        {
            TextureAtlasParams textureAtlasParams;
            [TextureAtlas InitDefaultParams:&textureAtlasParams];
            
            mTextureAtlas = [(TextureAtlas*)[TextureAtlas alloc] InitWithParams:&textureAtlasParams];
        }
        else
        {
            mTextureAtlas = [(TextureAtlas*)[TextureAtlas alloc] InitWithParams:inParams];
        }
        
        // We also need a mesh builder if we're using a texture atlas (to build a mesh that indexes into the texture atlas)
        
        mMeshBuilder = [(MeshBuilder*)[MeshBuilder alloc] Init];
    }
    else
    {
        mTextureAtlas = NULL;
        mMeshBuilder = NULL;
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    int numObjects = [mGameObjects count];
        
    for (int i = 0; i < numObjects; i++)
    {
        GameObject* obj = [mGameObjects objectAtIndex:i];
        BOOL objectDeleted = GameObjectCollection_UpdateObject([GameObjectManager GetInstance], obj, inTimeStep);
        
        if (objectDeleted)
        {
            i--;
            numObjects--;
        }
    }
}

-(void)Draw
{
    // TODO: Only do this if there is no mesh builder, and we're not combining renders.
    
    RenderStateParams renderStateParams;
    [GameObject InitDefaultRenderStateParams:&renderStateParams];

    if ((mTextureAtlas == NULL) || (mMeshBuilder == NULL))
    {
        for (GameObject* curObject in mGameObjects)
        { 
            if ([curObject GetVisible])
            {
                [curObject SetupRenderState:&renderStateParams];
                
                NeonGLMatrixMode(GL_MODELVIEW);
                glPushMatrix();

                Matrix44 ltwTransform;
                
                [curObject GetLocalToWorldTransform:&ltwTransform];
#if 0            
                if (inTransform != NULL)
                {
                    glMultMatrixf(inTransform->mMatrix);
                }
#endif            
                glMultMatrixf(ltwTransform.mMatrix);
                                        
                NeonGLError();
                [curObject Draw];
                NeonGLError();
#if 0                    
                if (mShowBoundingBoxes)
                {
                    [inObject DrawBoundingBox];
                }
#endif            
                [curObject TeardownRenderState:&renderStateParams];
                
                NeonGLMatrixMode(GL_MODELVIEW);
                glPopMatrix();  // Model transformation matrix
            }
        }
    }
    else
    {
        GameObject* renderStateObj = NULL;

        for (GameObject* curObject in mGameObjects)
        { 
            // Go by the assumption that all objects will be modifying the same render state.
            // When we have some concept of materials, we can actually compare all the objects
            // in this batch (and anyways, they shouldn't be in the same batch if they don't share
            // a material)
            
            if ([curObject GetVisible])
            {
                // Setup render state exactly once.  And save the object this corresponds to.
                if (renderStateObj == NULL)
                {
                    [curObject SetupRenderState:&renderStateParams];
                    renderStateObj = curObject;
                }
                
                [curObject Draw];
            }
        }
        
        [mMeshBuilder FinishPass];
        
        if (renderStateObj != NULL)
        {
            [renderStateObj TeardownRenderState:&renderStateParams];
        }
    }
}

-(void)DrawOrtho
{
    if ((mTextureAtlas == NULL) || (mMeshBuilder == NULL))
    {
        for (GameObject* curObject in mGameObjects)
        { 
            if ([curObject GetVisible])
            {
                glPushMatrix();
                
                Matrix44 ltwTransform;
                [curObject GetLocalToWorldTransform:&ltwTransform];
                
                glMultMatrixf(ltwTransform.mMatrix);
                [curObject DrawOrtho];
                
                glPopMatrix();
            }
        }
    }
    else
    {
        if ([mGameObjects count] > 0)
        {
            for (GameObject* curObject in mGameObjects)
            {
                if ([curObject GetVisible])
                {
                    [curObject DrawOrtho];
                }
            }
            
            [mMeshBuilder FinishPass];
        }
    }
}

-(void)addObject:(GameObject*)inObject
{
#if NEON_DEBUG
    for (GameObject* curObject in mGameObjects)
    {
        if (curObject == inObject)
        {
            NSAssert(FALSE, @"Trying to add the same object to a GameObjectBatch more than once");
        }
    }
#endif
    
    [mGameObjects addObject:inObject];
    
    [inObject SetGameObjectBatch:self];
}

-(void)removeObject:(GameObject*)inObject
{
    [mGameObjects removeObject:inObject];
}

-(void)removeAllObjectsFinal:(BOOL)inFinal
{
    for (GameObject* curObject in mGameObjects)
    {
        [(GameObject*)curObject SetGameObjectBatch:NULL];
        
        if (inFinal)
        {
            [curObject Remove];
        }
    }
    
    TextureAtlasParams savedParams;
    
    [mTextureAtlas InitFromExistingParams:&savedParams];
    [mTextureAtlas release];
    mTextureAtlas = NULL;
    
    [mMeshBuilder release];
    mMeshBuilder = NULL;
    
    mFinalized = FALSE;
    
    [mGameObjects removeAllObjects];
    
    [self InitTextureAtlasWithParams:&savedParams];
}

-(void)removeAllObjects
{
    [self removeAllObjectsFinal:FALSE];
}

-(GameObject*)objectAtIndex:(NSUInteger)inIndex
{
    return [mGameObjects objectAtIndex:inIndex];
}

-(NSUInteger)count
{
    return [mGameObjects count];
}

-(BOOL)BatchCompleted
{
    for (GameObject* curObject in mGameObjects)
    {
        if ((curObject->mGameObjectState != GAMEOBJECT_COMPLETED) && ([curObject AnyPropertyIsAnimating]))
        {
            return FALSE;
        }
    }
    
    return TRUE;
}

-(void)SetTextureAtlas:(TextureAtlas*)inTextureAtlas
{
    [mTextureAtlas release];
    mTextureAtlas = inTextureAtlas;
    [mTextureAtlas retain];
    
    if (mMeshBuilder == NULL)
    {
        mMeshBuilder = [(MeshBuilder*)[MeshBuilder alloc] Init];
    }
    
    // Assume atlas is created for now
    mFinalized = TRUE;
}

-(TextureAtlas*)GetTextureAtlas
{
    return mTextureAtlas;
}

-(void)CreateMeshBuilder
{
    NSAssert(mMeshBuilder == NULL, @"Attempting to call CreateMeshBuilder on a GameObjectBatch that already has a MeshBuilder");
    
    mMeshBuilder = [(MeshBuilder*)[MeshBuilder alloc] Init];
}

-(MeshBuilder*)GetMeshBuilder
{
    return mMeshBuilder;
}

-(void)Finalize
{
    if (!mFinalized)
    {
        if (mTextureAtlas != NULL)
        {
            [mTextureAtlas CreateAtlas];
        }
    }
    
    mFinalized = TRUE;
}

-(void)SetProjected:(BOOL)inProjected
{
    [super SetProjected:inProjected];
    
    if (mMeshBuilder != NULL)
    {
        // This property ensures that each successive triangle is "higher" than the previous one.  For projected UI on a table,
        // this ensures that everything is visible - even with depth testing on (since we still want other geometry to be able to
        // occlude the projected UI)
        
        [mMeshBuilder SetIncrementDepth:inProjected];
    }
    
    if (mTextureAtlas != NULL)
    {
        // Since projected UI uses bilinear filtering, we need to pad out the textures, otherwise textures bleed into each other
        // when filtered.
        
        [mTextureAtlas SetPaddingSize:(inProjected ? TEXTURE_ATLAS_PADDING_SIZE: 0)];
    }
}

@end