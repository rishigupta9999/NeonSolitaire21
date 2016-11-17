//
//  UIObject.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "UIObject.h"
#import "UIGroup.h"
#import "TextureAtlas.h"
#import "TextureManager.h"
#import "MeshBuilder.h"
#import "GLExtensionManager.h"
#import "ModelManager.h"

#import "TextBox.h"

#define FADE_SPEED_DEFAULT  (5.0)

@implementation UIObject

@synthesize FadeWhenInactive = mFadeWhenInactive;

-(void)InitWithUIGroup:(UIGroup*)inUIGroup
{    
    [super Init];
    
    mVisibilityState = VISIBILITY_STATE_CONSTANT;
    mFadeSpeed = FADE_SPEED_DEFAULT;
    
    mFadeInPath = [(Path*)[Path alloc] Init];
    mFadeOutPath = [(Path*)[Path alloc] Init];
    mFadeToInactivePath = [(Path*)[Path alloc] Init];
    mFadeToActivePath = [(Path*)[Path alloc] Init];
    
    mUIObjectState = UI_OBJECT_STATE_ENABLED;
    mUIObjectPrevState = UI_OBJECT_STATE_ENABLED;
    
    mGameObjectBatch = inUIGroup;
    [mGameObjectBatch retain];
    
    if (mGameObjectBatch != NULL)
    {
        [mGameObjectBatch addObject:self];
    }
    
    mDirtyBits = UIOBJECT_NONE;
    
    mPlacementStatus = UI_OBJECT_PLACEMENT_STATUS_UNINITIALIZED;
    
    // By default, texture scale isn't honored for projected UI in the DrawQuad function.  Set this to force it for projected UI
    mForceTextureScale = FALSE;

    [self InitFadePaths];
    
    mFadeWhenInactive = TRUE;
}

-(void)dealloc
{
    [mFadeInPath release];
    [mFadeOutPath release];
    [mFadeToInactivePath release];
    [mFadeToActivePath release];
    
    [mGameObjectBatch release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(UIObjectParams*)inParams
{
    SetAbsolutePlacement(&inParams->mPlacement, PLACEMENT_ALIGN_LEFT, PLACEMENT_ALIGN_LEFT);
}

-(void)SetPlacement:(PlacementValue*)inPlacement
{
    memcpy(&mPlacement, inPlacement, sizeof(PlacementValue));
    
    u32 outerWidth = [self GetWidth];
    u32 outerHeight = [self GetHeight];
    
    u32 innerWidth = 0;
    u32 innerHeight = 0;
    
    CalculatePlacement(&mPlacement, outerWidth, outerHeight, innerWidth, innerHeight);
}

-(UIObjectState)GetState
{
    return mUIObjectState;
}

-(UIObjectState)GetPrevState
{
    return mUIObjectPrevState;
}

-(void)SetState:(UIObjectState)inState
{
    mUIObjectPrevState = mUIObjectState;
    mUIObjectState = inState;
}

-(void)GetLocalToWorldTransform:(Matrix44*)outTransform
{
    // Tweak position, generate transform, then undo the tweak
    float hAlign = (float)GetHAlignPixels(&mPlacement);
    float vAlign = (float)GetVAlignPixels(&mPlacement);

    mPosition.mVector[x] -= hAlign;
    mPosition.mVector[y] -= vAlign;
    
    [super GetLocalToWorldTransform:outTransform];
    
    mPosition.mVector[x] += hAlign;
    mPosition.mVector[y] += vAlign;
}

-(void)GetPosition:(Vector3*)outPosition
{
    [super GetPosition:outPosition];
    
    outPosition->mVector[x] -= (float)GetHAlignPixels(&mPlacement);
    outPosition->mVector[y] -= (float)GetVAlignPixels(&mPlacement);
}

-(void)GetPositionWithoutPlacement:(Vector3*)outPosition
{
    [super GetPosition:outPosition];
}

-(void)GetProjectedCoordsForTexture:(Texture*)inTexture coords:(Rect3D*)outCoords
{
    [self GetProjectedCoordsForTexture:inTexture border:NULL coords:outCoords];
}

-(void)GetProjectedCoordsForTexture:(Texture*)inTexture border:(Vector2*)inBorder coords:(Rect3D*)outCoords
{
	Matrix44 scale;
    
    if (inTexture != NULL)
    {
        GenerateScaleMatrix([inTexture GetGLWidth], [inTexture GetGLHeight], 1.0, &scale);
    }
    else
    {
        SetIdentity(&scale);
    }
	
	Matrix44 ltwTransform;
	[self GetLocalToWorldTransform:&ltwTransform];
	
	Matrix44 transform;
	MatrixMultiply(&ltwTransform, &scale, &transform);
    
    float xOffset = 0;
    float yOffset = 0;
    
    if (inBorder != NULL)
    {
        xOffset = inBorder->mVector[x] / [inTexture GetGLWidth];
        yOffset = inBorder->mVector[y] / [inTexture GetGLHeight];
    }
	
	Vector3	vertexPositions[4] = {	{ { -xOffset,       1.0f + yOffset, 0.0f } },
									{ { 1.0f + xOffset, 1.0f + yOffset, 0.0f } },
									{ { 1.0f + xOffset, -yOffset,       0.0f } },
									{ { -xOffset,       -yOffset,       0.0f } }	};
				
	for (int i = 0; i < 4; i++)
	{
		Vector4 transformedVector;
		TransformVector4x3(&transform, &vertexPositions[i], &transformedVector);
		SetVec3From4(&outCoords->mVectors[i], &transformedVector);
	}
}

-(void)StatusChanged:(UIObjectState)inState
{
    // TODO - When we call AnimateProperty for the object's alpha, we need some way to cancel the existing animation.
    // otherwise, calling enable/disable in quick succession could result in jittery / discontinuous animation.
    // Eg: We are fading from 0 - 1.  Then at 0.8 we trigger a fade out.  The 0 - 1 animation completes, then the
    // fade out animation starts at 0.8.  So we have a discontinuity where we jump from 1 to 0.8 immediately.
    
    switch(inState)
    {
        case UI_OBJECT_STATE_ENABLED:
        {
            if ((!mVisible) || (mVisibilityState == VISIBILITY_STATE_FADE_OUT))
            {
                mAlpha = 0.0;
                
                [self SetVisible:TRUE];
                [self BuildFadeInPath];
                [self AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:mFadeInPath replace:TRUE];
                
                mVisibilityState = VISIBILITY_STATE_FADE_IN;
            }
            else if ((mUIObjectPrevState == UI_OBJECT_STATE_INACTIVE) && (mFadeWhenInactive))
            {
                [self BuildFadeToActivePath];
                [self AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:mFadeToActivePath replace:TRUE];
                
                mVisibilityState = VISIBILITY_STATE_FADE_IN;
            }
            
            break;
        }
        
        case UI_OBJECT_STATE_DISABLED:
        {
            if ((mVisible) || (mVisibilityState == VISIBILITY_STATE_FADE_IN))
            {                
                [self BuildFadeOutPath];
                [self AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:mFadeOutPath replace:TRUE];
                
                mVisibilityState = VISIBILITY_STATE_FADE_OUT;
            }
            
            break;
        }
        
        case UI_OBJECT_STATE_INACTIVE:
        {
            if ((mVisible) && (mFadeWhenInactive))
            {
                [self BuildFadeToInactivePath];
                [self AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:mFadeToInactivePath replace:TRUE];
                
                mVisibilityState = VISIBILITY_STATE_FADE_TO_INACTIVE;
            }
            
            break;
        }
    }
}

-(void)SetProjected:(BOOL)inProjected
{
    [super SetProjected:inProjected];
    
    mDirtyBits |= UIOBJECT_PROJECTED_STATE_DIRTY;
}

-(u32)GetWidth
{
    return 0;
}

-(u32)GetHeight
{
    return 0;
}

-(void)Disable
{
    [self SetState:UI_OBJECT_STATE_DISABLED];
    [self StatusChanged:mUIObjectState];
}

-(void)Enable
{
    [self SetState:UI_OBJECT_STATE_ENABLED];
    [self StatusChanged:mUIObjectState];
}

-(void)SetActive:(BOOL)inActive
{
    if (inActive)
    {
        [self SetState:UI_OBJECT_STATE_ENABLED];
    }
    else
    {
        [self SetState:UI_OBJECT_STATE_INACTIVE];
    }
    
    [self StatusChanged:mUIObjectState];
}

-(void)InitFadePaths
{
    [mFadeOutPath SetCallback:self withData:0];
    [mFadeInPath SetCallback:self withData:0];
}

-(void)BuildFadeInPath
{
    switch(mVisibilityState)
    {
        case VISIBILITY_STATE_FADE_IN:
        {
            return;
            break;
        }
        
        case VISIBILITY_STATE_CONSTANT:
        {
            break;
        }
    }
    
    [mFadeInPath Reset];
    [mFadeInPath AddNodeScalar:mAlpha atIndex:0 withSpeed:mFadeSpeed];
    [mFadeInPath AddNodeScalar:1.0 atIndex:1 withSpeed:mFadeSpeed];
}

-(void)BuildFadeOutPath
{
    switch(mVisibilityState)
    {
        case VISIBILITY_STATE_FADE_OUT:
        {
            return;
            break;
        }
        
        case VISIBILITY_STATE_CONSTANT:
        {
            if (!mVisible)
            {
                return;
            }
            
            break;
        }
    }
    
    [mFadeOutPath Reset];
    [mFadeOutPath AddNodeScalar:mAlpha atIndex:0 withSpeed:mFadeSpeed];
    [mFadeOutPath AddNodeScalar:0.0 atIndex:1 withSpeed:mFadeSpeed];
}

-(void)BuildFadeToActivePath
{
    switch(mVisibilityState)
    {
        case VISIBILITY_STATE_FADE_IN:
        {
            return;
            break;
        }
        
        case VISIBILITY_STATE_CONSTANT:
        {
            if (!mVisible)
            {
                return;
            }
            
            break;
        }
    }
    
    [mFadeToActivePath Reset];
    [mFadeToActivePath AddNodeScalar:mAlpha atIndex:0 withSpeed:mFadeSpeed / 2.0f];
    [mFadeToActivePath AddNodeScalar:1.0f atIndex:1 withSpeed:mFadeSpeed / 2.0f];
}

-(void)BuildFadeToInactivePath
{
    switch(mVisibilityState)
    {
        case VISIBILITY_STATE_FADE_TO_INACTIVE:
        {
            return;
            break;
        }
        
        case VISIBILITY_STATE_CONSTANT:
        {
            if (!mVisible)
            {
                return;
            }
            
            break;
        }
    }
    
    [mFadeToInactivePath Reset];
    [mFadeToInactivePath AddNodeScalar:mAlpha atIndex:0 withSpeed:mFadeSpeed / 2.0f];
    [mFadeToInactivePath AddNodeScalar:0.25 atIndex:1 withSpeed:mFadeSpeed / 2.0f];
}

-(void)BeginPulse
{
    Path* pulsePath = [[Path alloc] Init];
    
    [pulsePath AddNodeScalar:1.0 atIndex:0 withSpeed:(mFadeSpeed)];
    [pulsePath AddNodeScalar:0.25 atIndex:1 withSpeed:(mFadeSpeed)];
    [pulsePath AddNodeScalar:1.0 atIndex:2 withSpeed:(mFadeSpeed)];
    
    [pulsePath SetPeriodic:TRUE];
    
    [self AnimateProperty:GAMEOBJECT_PROPERTY_ALPHA withPath:pulsePath replace:FALSE];
    
    [pulsePath release];
}

-(void)EndPulse
{
    [self CancelAnimationForProperty:GAMEOBJECT_PROPERTY_ALPHA];
}

-(void)PathEvent:(PathEvent)inEvent withPath:(Path*)inPath userData:(u32)inData
{
    switch(mVisibilityState)
    {
        case VISIBILITY_STATE_FADE_OUT:
        {
            [self SetVisible:FALSE];
            break;
        }
    }
}

+(void)InitDefaultTextureLoadParams:(UIObjectTextureLoadParams*)outParams
{
    outParams->mTextureName = NULL;
    outParams->mTexDataLifetime = TEX_DATA_RETAIN;
}

-(Texture*)LoadTextureWithParams:(UIObjectTextureLoadParams*)inParams
{
    TextureAtlas* atlas = NULL;
    
    if (mGameObjectBatch != NULL)
    {
        atlas = [mGameObjectBatch GetTextureAtlas];
    }
    
    if ((atlas != NULL) && (mGameObjectBatch.finalized))
    {
        Texture* loadedTexture = [atlas GetTextureWithIdentifier:inParams->mTextureName];
        NSAssert(loadedTexture != NULL, @"Can't load a new texture into a finalized GameObject batch");
        
        return loadedTexture;
    }
    
    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTextureAtlas = atlas;
    textureParams.mMinFilter = GL_NEAREST;
    textureParams.mMagFilter = GL_NEAREST;
    textureParams.mTexDataLifetime = inParams->mTexDataLifetime;
    
    Texture* retTexture = [[TextureManager GetInstance] TextureWithName:inParams->mTextureName textureParams:&textureParams];
    
    if (atlas != NULL)
    {
        [atlas AddTexture:retTexture];
    }
    
    return retTexture;
}

// If the texture was not loaded from a file (eg: a dynamically created text texture), then use this function
// to specify that it will be used.
-(void)RegisterTexture:(Texture*)inTexture
{
    if ([self TextureRegistered:inTexture])
    {
        return;
    }
    
    TextureAtlas* atlas = NULL;
    
    if (mGameObjectBatch != NULL)
    {
        atlas = [mGameObjectBatch GetTextureAtlas];
    }
    
    NSAssert((inTexture->mTexName == 0) || (mGameObjectBatch == NULL) || ([mGameObjectBatch GetTextureAtlas] == NULL), @"Invalid texture atlas conditions");
    
    inTexture->mParams.mTextureAtlas = atlas;
    inTexture->mParams.mMinFilter = GL_NEAREST;
    inTexture->mParams.mMagFilter = GL_NEAREST;
    
    if (inTexture->mTexName != 0)
    {
        [inTexture Bind];
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        [Texture Unbind];
    }

    if (atlas != NULL)
    {
        [atlas AddTexture:inTexture];
    }
}

-(void)UpdateTexture:(Texture*)inTexture
{
    TextureAtlas* atlas = NULL;
    
    if (mGameObjectBatch != NULL)
    {
        atlas = [mGameObjectBatch GetTextureAtlas];
    }
    
    NSAssert((atlas != NULL) && ([atlas AtlasCreated] != 0), @"This function only makes sense if a Texture Atlas has already been created.");
    
    [atlas UpdateTexture:inTexture];
}

+(void)InitQuadParams:(QuadParams*)outQuadParams
{
    outQuadParams->mTexture = NULL;
    outQuadParams->mColorMultiplyEnabled = FALSE;
    outQuadParams->mBlendEnabled = TRUE;
    outQuadParams->mScaleType = QUAD_PARAMS_SCALE_NONE;
    outQuadParams->mTexCoordEnabled = FALSE;
    
    SetVec2(&outQuadParams->mTranslation, 0.0, 0.0);
    
    memset(outQuadParams->mTexCoords, 0, sizeof(outQuadParams->mTexCoords));
}

-(void)DrawQuad:(QuadParams*)inQuadParams withIdentifier:(const char*)inIdentifier
{
    NSAssert(inIdentifier != NULL, @"You must pass in an identifier");
    
    // Setup (no changes to GL state)
    
    float vertex[12] = {    0, 0, 0,
                            0, 1, 0,
                            1, 0, 0,
                            1, 1, 0 };
                            
    float texCoord[8] = {   0, 0,
                            0, 1,
                            1, 0,
                            1, 1  };
							                            
    float colorArray[16] = { 0 };

    NSAssert((inQuadParams->mTexture != NULL) || (mGameObjectBatch == NULL), @"We don't support drawing untextured quads if a UIGroup is being used.");
	
    if (mDirtyBits & UIOBJECT_PROJECTED_STATE_DIRTY)
    {
		BOOL gpuClassMBX = ([[GLExtensionManager GetInstance] GetGPUClass] == GPU_CLASS_MBX);

        if (mProjected)
        {
			if ((gpuClassMBX) || ([self class] == [TextBox class]))
			{
				[inQuadParams->mTexture SetMagFilter:GL_LINEAR minFilter:GL_LINEAR];
			}
			else
			{
				[inQuadParams->mTexture SetMagFilter:GL_LINEAR minFilter:GL_LINEAR_MIPMAP_LINEAR];
			}
        }
        else
        {
            [inQuadParams->mTexture SetMagFilter:GL_NEAREST minFilter:GL_NEAREST];
        }
        
        mDirtyBits ^= UIOBJECT_PROJECTED_STATE_DIRTY;
    }
    
    // We don't need to do any retina display stuff for projected UIObjects.  For non-projected, we need to
    // know this because we scale the UIObject based on the texture size (and this scale needs to be halved
    // in each dimension on the retina display)
    
	float scaleFactor = [inQuadParams->mTexture GetScaleFactor];
	
    if ((mProjected) && (!mForceTextureScale))
    {
        scaleFactor = 1.0f;
    }
    
    if (inQuadParams->mColorMultiplyEnabled)
    {                                
        for (int i = 0; i < 4; i++)
        {
            colorArray[(4 * i) + 0] = GetRedFloat(&inQuadParams->mColor[i]);
            colorArray[(4 * i) + 1] = GetGreenFloat(&inQuadParams->mColor[i]);
            colorArray[(4 * i) + 2] = GetBlueFloat(&inQuadParams->mColor[i]);
            colorArray[(4 * i) + 3] = GetAlphaFloat(&inQuadParams->mColor[i]);
            
            // If we're using premultiplied alpha and have disabled src alpha blend, we have
            // to premultiply the alpha ourselves here
            
            colorArray[(4 * i) + 0] *= colorArray[(4 * i) + 3];
            colorArray[(4 * i) + 1] *= colorArray[(4 * i) + 3];
            colorArray[(4 * i) + 2] *= colorArray[(4 * i) + 3];
        }
    }
    
    GLenum srcBlend = GL_SRC_ALPHA;
    GLenum destBlend = GL_ONE_MINUS_SRC_ALPHA;
    
    if (inQuadParams->mBlendEnabled)
    {
        if ((inQuadParams->mTexture != NULL) && (inQuadParams->mTexture->mPremultipliedAlpha))
        {
            srcBlend = GL_ONE;
            destBlend = GL_ONE_MINUS_SRC_ALPHA;
        }
    }

    Matrix44 translate, scale, transform;
    
    GenerateTranslationMatrix(  inQuadParams->mTranslation.mVector[x],
                                inQuadParams->mTranslation.mVector[y],
                                0.0f, &translate);
    
    float defaultXScale = [inQuadParams->mTexture GetGLWidth] / scaleFactor;
    float defaultYScale = [inQuadParams->mTexture GetGLHeight] / scaleFactor;
    
    if (inQuadParams->mScaleType == QUAD_PARAMS_SCALE_NONE)
    {
        if (inQuadParams->mTexture)
        {
            GenerateScaleMatrix(defaultXScale, defaultYScale, 1.0, &scale);
        }
        else
        {
            SetIdentity(&scale);
        }
    }
    else
    {
        float xScale = defaultXScale;
        float yScale = defaultYScale;
        
        switch(inQuadParams->mScaleType)
        {
            case QUAD_PARAMS_SCALE_X:
            {
                xScale = inQuadParams->mScale.mVector[x];
                break;
            }
            
            case QUAD_PARAMS_SCALE_Y:
            {
                yScale = inQuadParams->mScale.mVector[y];
                break;
            }
            
            case QUAD_PARAMS_SCALE_BOTH:
            {
                xScale = inQuadParams->mScale.mVector[x];
                yScale = inQuadParams->mScale.mVector[y];
                break;
            }
        }
        
        GenerateScaleMatrix(xScale, yScale, 1.0, &scale);
    }
    
    MatrixMultiply(&translate, &scale, &transform);
    
    if ((inQuadParams->mTexture != NULL) && (inQuadParams->mTexture->mParams.mTextureAtlas != NULL))
    {
        NSAssert(inQuadParams->mTexture->mParams.mTextureAtlas == [mGameObjectBatch GetTextureAtlas], @"Texture atlas mismatch");
        NSAssert([mGameObjectBatch GetMeshBuilder] != NULL, @"We have a texture atlas but no mesh builder.  Is this valid?");
        
        if (inQuadParams->mTexCoordEnabled)
        {
            memcpy(texCoord, inQuadParams->mTexCoords, sizeof(float) * 8);
        }
        else
        {
            texCoord[0] = inQuadParams->mTexture->mTextureAtlasInfo.mSMin;
            texCoord[1] = inQuadParams->mTexture->mTextureAtlasInfo.mTMin;
            texCoord[2] = inQuadParams->mTexture->mTextureAtlasInfo.mSMin;
            texCoord[3] = inQuadParams->mTexture->mTextureAtlasInfo.mTMax;
            texCoord[4] = inQuadParams->mTexture->mTextureAtlasInfo.mSMax;
            texCoord[5] = inQuadParams->mTexture->mTextureAtlasInfo.mTMin;
            texCoord[6] = inQuadParams->mTexture->mTextureAtlasInfo.mSMax;
            texCoord[7] = inQuadParams->mTexture->mTextureAtlasInfo.mTMax;
        }

        Matrix44 ltwTransform;
        
        [self GetLocalToWorldTransform:&ltwTransform];
        MatrixMultiply(&ltwTransform, &transform, &transform);
        
        MeshBuilder* meshBuilder = [mGameObjectBatch GetMeshBuilder];
        
        if (meshBuilder != NULL)
        {
            [meshBuilder StartMeshWithOwner:self identifier:inIdentifier];
            
            [meshBuilder SetPositionPointer:(u8*)vertex numComponents:3 numVertices:4 copyData:TRUE];
            [meshBuilder SetTexcoordPointer:(u8*)texCoord numComponents:2 numVertices:4 copyData:TRUE];
            [meshBuilder SetColorPointer:(u8*)colorArray numComponents:4 numVertices:4 copyData:TRUE];
            
            if (inQuadParams->mBlendEnabled)
            {
                [meshBuilder SetBlendEnabled:TRUE];
                [meshBuilder SetBlendFunc:srcBlend dest:destBlend];
            }
            
            [meshBuilder SetNumVertices:4];
            [meshBuilder SetTransform:&transform];
            [meshBuilder SetTexture:inQuadParams->mTexture];
            [meshBuilder SetPrimitiveType:GL_TRIANGLE_STRIP];
            
            [meshBuilder EndMesh];
        }
        
        // Don't thrash GL state.  We've told the mesh builder what we're planning on doing, now get out.
        return;
    }
        
    GLState glState;
    SaveGLState(&glState);
    
    if ([mGameObjectBatch GetTextureAtlas] != NULL)
    {
        // If there's no mesh builder to coalesce the draw calls, we have to draw immediately.
        [[mGameObjectBatch GetTextureAtlas] Bind];
    }
    else
    {
        [inQuadParams->mTexture Bind];
    }
    
    // Rendering
    
    if (inQuadParams->mTexture != NULL)
    {
        texCoord[4] = texCoord[6] = (float)[inQuadParams->mTexture GetRealWidth] / (float)[inQuadParams->mTexture GetGLWidth];
        texCoord[3] = texCoord[7] = (float)[inQuadParams->mTexture GetRealHeight] / (float)[inQuadParams->mTexture GetGLHeight];
        
        if (inQuadParams->mTexCoordEnabled)
        {
            memcpy(texCoord, inQuadParams->mTexCoords, sizeof(float) * 8);
        }
        
        Matrix44 textureScale;
        
        GenerateScaleMatrix(    (float)[inQuadParams->mTexture GetRealWidth] / (float)[inQuadParams->mTexture GetGLWidth],
                                (float)[inQuadParams->mTexture GetRealHeight] / (float)[inQuadParams->mTexture GetGLHeight],
                                1.0f, &textureScale);
        
        MatrixMultiply(&transform, &textureScale, &transform);
    }
    
    if (inQuadParams->mColorMultiplyEnabled)
    {
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        glEnableClientState(GL_COLOR_ARRAY);        
        glColorPointer(4, GL_FLOAT, 0, colorArray);
    }
    
    if (inQuadParams->mBlendEnabled)
    {
        NeonGLEnable(GL_BLEND);
        NeonGLBlendFunc(srcBlend, destBlend);
    }
    
    glEnableClientState(GL_VERTEX_ARRAY);
    
    if (inQuadParams->mTexture == NULL)
    {
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        NeonGLDisable(GL_TEXTURE_2D);
    }
    else
    {
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, texCoord);
    }
    
    glVertexPointer(3, GL_FLOAT, 0, vertex);
    	
    NeonGLMatrixMode(GL_MODELVIEW);
        
    glPushMatrix();
    {
        glMultMatrixf(transform.mMatrix);        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    glPopMatrix();
    
    [Texture Unbind];

    RestoreGLState(&glState);
}

-(void)SetFadeSpeed:(u32)inFadeSpeed
{
    mFadeSpeed = inFadeSpeed;
}

-(BOOL)TextureRegistered:(Texture*)inTexture
{
    TextureAtlas* atlas = NULL;
    
    if (mGameObjectBatch != NULL)
    {
        atlas = [mGameObjectBatch GetTextureAtlas];
    }

    if (atlas != NULL)
    {
        return [atlas ContainsTexture:inTexture];
    }
    
    return FALSE;
}

-(void)SetupViewportStart:(ModelManagerViewport)inStartViewport end:(ModelManagerViewport)inEndViewport
{
    if ([mGameObjectBatch GetMeshBuilder] != NULL)
    {
        NSAssert(([mGameObjectBatch GetMeshBuilder].startViewport == MODELMANAGER_VIEWPORT_INVALID) || ([mGameObjectBatch GetMeshBuilder].startViewport == inStartViewport), @"Can only assign one start viewport type to a MeshBuilder");
        NSAssert(([mGameObjectBatch GetMeshBuilder].endViewport == MODELMANAGER_VIEWPORT_INVALID) || ([mGameObjectBatch GetMeshBuilder].endViewport == inEndViewport), @"Can only assign one end viewport type to a MeshBuilder");
        
        [mGameObjectBatch GetMeshBuilder].startViewport = inStartViewport;
        [mGameObjectBatch GetMeshBuilder].endViewport = inEndViewport;
    }
    else
    {
        [[ModelManager GetInstance] SetupViewport:inStartViewport];
    }
}

-(void)SetupViewportEnd:(ModelManagerViewport)inEndViewport
{
    if ([mGameObjectBatch GetMeshBuilder] != NULL)
    {
        return;
    }
    
    [[ModelManager GetInstance] SetupViewport:inEndViewport];
}

-(Texture*)GetUseTexture
{
    return NULL;
}

@end