//
//  AnimatedButton.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "AnimatedIcon.h"
#import "ResourceManager.h"
#import "BigFile.h"
#import "UIGroup.h"
#import "PNGTexture.h"

#define DEFAULT_TIME_PER_FRAME  (0.5)

@implementation AnimatedIcon

-(AnimatedIcon*)InitWithParams:(AnimatedIconParams*)inParams
{
    NSAssert( (inParams->mUIGroup == NULL), @"Animated icons do not support UIGroups since they use intermediate render targets");
    
    [super InitWithUIGroup:inParams->mUIGroup];
    
    memcpy(&mParams, inParams, sizeof(AnimatedIconParams));
    
    [mParams.mTextureBigFileName retain];
    
    NSNumber* iconTextures = [[ResourceManager GetInstance] LoadAssetWithName:inParams->mTextureBigFileName];
    BigFile* bigFile = [[ResourceManager GetInstance] GetBigFile:iconTextures];
    int numFiles = [bigFile GetNumFiles];
    
    mTextures = [[NSMutableArray alloc] initWithCapacity:numFiles];
    
    TextureParams textureParams;
    
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    textureParams.mTextureAtlas = (inParams->mUIGroup != NULL) ? ([inParams->mUIGroup GetTextureAtlas]) : (NULL);
    
    for (int curTextureIndex = 0; curTextureIndex < numFiles; curTextureIndex++)
    {
        Texture* curTexture = [(PNGTexture*)[PNGTexture alloc] InitWithData:[bigFile GetFileAtIndex:curTextureIndex] textureParams:&textureParams];
        
        [self RegisterTexture:curTexture];
        [mTextures addObject:curTexture];
        
        if ([[ResourceManager GetInstance] GetResourceFamily:iconTextures] == RESOURCEFAMILY_PHONE_RETINA)
        {
            [curTexture SetScaleFactor:GetRetinaScaleFactor()];
        }
        
        [curTexture release];
    }
    
#if NEON_DEBUG
    Texture* testTexture = [mTextures objectAtIndex:0];
    int testWidth = [testTexture GetRealWidth];
    int testHeight = [testTexture GetRealHeight];
    
    for (int i = 1; i < [mTextures count]; i++)
    {
        Texture* curTexture = [mTextures objectAtIndex:i];
        
        if ((testWidth != [curTexture GetRealWidth]) || (testHeight != [curTexture GetRealHeight]))
        {
            NSAssert(FALSE, @"All textures in an AnimatedIcon must be the same size");
            break;
        }
    }
#endif
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:iconTextures];
    
    mOrtho = TRUE;
    mRenderBinId = RENDERBIN_UI;
    mTime = 0.0f;
    
    mLoopDirection = ANIMATED_ICON_LOOP_DIRECTION_FORWARD;
            
    return self;
}

-(void)dealloc
{
    [mParams.mTextureBigFileName release];
    [mTextures release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(AnimatedIconParams*)outParams
{
    outParams->mTextureBigFileName = NULL;
    outParams->mTimePerFrame = DEFAULT_TIME_PER_FRAME;
    outParams->mUIGroup = NULL;
    outParams->mLoopType = ANIMATED_ICON_LOOP_REPEAT;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [super Update:inTimeStep];
    
    switch(mLoopDirection)
    {
        case ANIMATED_ICON_LOOP_DIRECTION_FORWARD:
        {
            mTime += inTimeStep;
            break;
        }
        
        case ANIMATED_ICON_LOOP_DIRECTION_BACKWARD:
        {
            mTime -= inTimeStep;
            break;
        }
    }
    
    if (mParams.mLoopType == ANIMATED_ICON_LOOP_PING_PONG)
    {
        if ((mLoopDirection == ANIMATED_ICON_LOOP_DIRECTION_FORWARD) && (mTime > (mParams.mTimePerFrame * ([mTextures count] - 1))))
        {
            float excess = mTime - (mParams.mTimePerFrame * ([mTextures count] - 1));
            mTime -= excess;
            
            mLoopDirection = 1 - mLoopDirection;
            
            mTime = ClampFloat(mTime, 0.0, (mParams.mTimePerFrame * ([mTextures count] - 1)));
        }
        else if ((mLoopDirection == ANIMATED_ICON_LOOP_DIRECTION_BACKWARD) && (mTime < 0))
        {
            mTime = -mTime;
            mLoopDirection = 1 - mLoopDirection;
            
            mTime = ClampFloat(mTime, 0.0, (mParams.mTimePerFrame * ([mTextures count] - 1)));
        }
    }
}

-(void)DrawOrtho
{
    // Determine the two textures we're drawing with
    Texture*    srcTexture;
    Texture*    destTexture;
    float       srcBlend;
    float       destBlend;
    
    [self GetSrcTexture:&srcTexture destTexture:&destTexture srcBlend:&srcBlend destBlend:&destBlend];
        
    GLState glState;
    
    SaveGLState(&glState);
    
    float vertex[12] = {    0, 0, 0,
                            0, 1, 0,
                            1, 0, 0,
                            1, 1, 0 };
                            
    float texCoord[8] = {   0, 0,
                            0, 1,
                            1, 0,
                            1, 1  };

    glEnableClientState(GL_VERTEX_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, 0, vertex);
    
    NeonGLEnable(GL_BLEND);
    NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Set up texture combiner state for crossfade
    
    // Set up texture unit 0.  This is a regular texture map
    NeonGLActiveTexture(GL_TEXTURE0);
    glClientActiveTexture(GL_TEXTURE0);
    
    NeonGLEnable(GL_TEXTURE_2D);
    NeonGLBindTexture(GL_TEXTURE_2D, srcTexture->mTexName);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoord);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

    // Set up texture unit 1.  This combines with the result of the previous texture unit.
    // The purpose of the below code is to mix the results of srcTexture and destTexture.
    // (Interpolate between the texel values using srcBlend as a blend factor)
    
    NeonGLActiveTexture(GL_TEXTURE1);
    glClientActiveTexture(GL_TEXTURE1);
    
    NeonGLEnable(GL_TEXTURE_2D);
    NeonGLBindTexture(GL_TEXTURE_2D, destTexture->mTexName);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoord);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_INTERPOLATE);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB, GL_CONSTANT);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_RGB, GL_SRC_COLOR);

    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_INTERPOLATE);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_ALPHA, GL_CONSTANT);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_ALPHA, GL_SRC_ALPHA);
    
    Vector4 unit1Color = { { srcBlend, srcBlend, srcBlend, srcBlend } };
    glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, unit1Color.mVector);
    
    // Set up texture unit 2.  This multiplies the result (alpha only) of the texture interpolation
    // by the alpha value of the AnimatedIcon.
    
    NeonGLActiveTexture(GL_TEXTURE2);
    glClientActiveTexture(GL_TEXTURE2);
    NeonGLEnable(GL_TEXTURE_2D);
    
    NeonGLBindTexture(GL_TEXTURE_2D, destTexture->mTexName);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoord);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_CONSTANT);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);

    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
    glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_CONSTANT);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
    
    Vector4 unit2Color = { { 1.0, 1.0, 1.0, mAlpha } };
    glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, unit2Color.mVector);
    
    NeonGLMatrixMode(GL_MODELVIEW);
    
    glPushMatrix();
    {
        Matrix44 scaleMatrix;
        GenerateScaleMatrix([srcTexture GetGLWidth] / [srcTexture GetScaleFactor], [srcTexture GetGLHeight] / [srcTexture GetScaleFactor], 1.0, &scaleMatrix);
        
        glMultMatrixf(scaleMatrix.mMatrix);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    glPopMatrix();
    
    // This is the only part of the game that uses texture combiners.  So we have to manually disable
    // all of this state.
    for (int i = 2; i >= 1; i--)
    {
        NeonGLActiveTexture(GL_TEXTURE0 + i);
        glClientActiveTexture(GL_TEXTURE0 + i);
        
        NeonGLBindTexture(GL_TEXTURE_2D, 0);
        NeonGLDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    
    // Restore texture unit 0 as the active texture unit - then the rest of the game engine proceeds as normal.
    NeonGLActiveTexture(GL_TEXTURE0);
    glClientActiveTexture(GL_TEXTURE0);
    [Texture Unbind];
    
    RestoreGLState(&glState);

    NeonGLError();
}

-(u32)GetWidth
{
    Texture* testTexture = [mTextures objectAtIndex:0];
    
    return [testTexture GetEffectiveWidth];
}

-(u32)GetHeight
{
    Texture* testTexture = [mTextures objectAtIndex:0];
    
    return [testTexture GetEffectiveHeight];
}

-(void)GetSrcTexture:(Texture**)outSrcTexture destTexture:(Texture**)outDestTexture srcBlend:(float*)outSrcBlend destBlend:(float*)outDestBlend
{
    int numTextures = [mTextures count];
    
    if (numTextures == 1)
    {
        Texture* firstTexture = [mTextures objectAtIndex:0];
        
        *outSrcTexture = firstTexture;
        *outDestTexture = firstTexture;
        *outSrcBlend = 1.0;
        *outDestBlend = 0.0;
    }
    else
    {
        if (mTime > (mParams.mTimePerFrame * (numTextures - 1)))
        {
            int useTime = mTime - (mParams.mTimePerFrame * (numTextures - 1));

            switch(mParams.mLoopType)
            {
                case ANIMATED_ICON_LOOP_REPEAT:
                {                    
                    *outSrcTexture = [mTextures objectAtIndex:(numTextures - 1)];
                    *outDestTexture = [mTextures objectAtIndex:0];
                    
                    *outSrcBlend = 1.0 - (useTime / mParams.mTimePerFrame);
                    *outDestBlend = 1.0 - *outSrcBlend;
                    
                    if (mTime >= (mParams.mTimePerFrame * numTextures))
                    {
                        mTime -= mParams.mTimePerFrame * numTextures;
                    }
                    
                    break;
                }
                
                default:
                {
                    NSAssert(FALSE, @"Don't know how to handle this case");
                    break;
                }
            }
        }
        else if (mTime == (mParams.mTimePerFrame * (numTextures - 1)))
        {
            *outSrcTexture = [mTextures objectAtIndex:(numTextures - 1)];
            *outDestTexture = [mTextures objectAtIndex:(numTextures - 1)];
            
            *outSrcBlend = 1.0;
            *outDestBlend = 1.0 - *outSrcBlend;
        }
        else if (mTime == 0)
        {
            *outSrcTexture = [mTextures objectAtIndex:0];
            *outDestTexture = [mTextures objectAtIndex:0];
            
            *outSrcBlend = 1.0;
            *outDestBlend = 1.0 - *outSrcBlend;
        }
        else
        {
            if (mLoopDirection == ANIMATED_ICON_LOOP_DIRECTION_FORWARD)
            {
                int startFrame = mTime / mParams.mTimePerFrame;
                
                *outSrcTexture = [mTextures objectAtIndex:startFrame];
                *outDestTexture = [mTextures objectAtIndex:(startFrame + 1)];
                
                float segmentStartTime = (float)startFrame * mParams.mTimePerFrame;
                
                *outSrcBlend = 1.0 - ((mTime - segmentStartTime) / mParams.mTimePerFrame);
                *outDestBlend = 1.0 - *outSrcBlend;
            }
            else
            {
                int startFrame = (mTime / mParams.mTimePerFrame) + 1;
                
                *outSrcTexture = [mTextures objectAtIndex:startFrame];
                *outDestTexture = [mTextures objectAtIndex:(startFrame - 1)];
                
                float segmentStartTime = (float)startFrame * mParams.mTimePerFrame;
                
                *outSrcBlend = 1.0 - ((segmentStartTime - mTime) / mParams.mTimePerFrame);
                *outDestBlend = 1.0 - *outSrcBlend;

            }
        }
    }
}

@end