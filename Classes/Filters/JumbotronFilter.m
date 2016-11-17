//
//  JumbotronFilter.m
//
//  Copyright 2013 Neon Games. All rights reserved.
//

#import "JumbotronFilter.h"
#import "Texture.h"
#import "TextureManager.h"
#import "CameraOrtho.h"
#import "Framebuffer.h"
#import "Path.h"
#include <stdlib.h>

static const NSString* CIRCLE_PIXEL_TEXTURE_FILENAME = @"Run21_Tablet_CirclePixel.png";
static const NSString* NOISE_TEXTURE_FILENAME = @"Run21_Tablet_Noise.png";

static float OVERBRIGHT_CHANNEL_BRIGHTNESS = 0.55f;

static float NOISE_MIN_DURATION = 10.0f;
static float NOISE_MAX_DURATION = 30.0f;
static float NOISE_TRANSITION_DURATION = 1.0f;

static float FLICKER_DELAY_MIN  = 15.0f;
static float FLICKER_DELAY_MAX  = 25.0f;
static float FLICKER_NUM_MIN    = 3;
static float FLICKER_NUM_MAX    = 6;
static float FLICKER_PERIOD_MIN = 0.05f;
static float FLICKER_PERIOD_MAX = 0.07f;
static float FLICKER_BRIGHTNESS_VAL = 0.8f;

@implementation JumbotronFilter

-(JumbotronFilter*)InitWithParams:(JumbotronFilterParams*)inParams
{
    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    
    mCirclePixelTexture = [[TextureManager GetInstance] TextureWithName:CIRCLE_PIXEL_TEXTURE_FILENAME textureParams:&textureParams];
    [mCirclePixelTexture retain];
    
    [mCirclePixelTexture SetWrapModeS:GL_REPEAT T:GL_REPEAT];
    
    mNoiseTexture = [[TextureManager GetInstance] TextureWithName:NOISE_TEXTURE_FILENAME textureParams:&textureParams];
    [mNoiseTexture retain];
    
    mDestFramebuffer = inParams->mDestFramebuffer;
    
    mSourceTexture = inParams->mSourceTexture;
    
    mCameraOrtho = [(CameraOrtho*)[CameraOrtho alloc] Init];
    
    FramebufferParams framebufferParams;
    [Framebuffer InitDefaultParams:&framebufferParams];
    
    framebufferParams.mWidth = [mSourceTexture GetRealWidth];
    framebufferParams.mHeight = [mSourceTexture GetRealHeight];
    
    mCompositingFramebuffer = [[Framebuffer alloc] InitWithParams:&framebufferParams];
    
    mNoiseEffect.mLowerAmount = inParams->mMinNoise;
    mNoiseEffect.mUpperAmount = inParams->mMaxNoise;
    
    mNoiseEffect.mNoisePath = [(Path*)[Path alloc] Init];
    
    [self InitNoiseEffect:TRUE];
    
    mFlickerEffect.mFlickerPath = [(Path*)[Path alloc] Init];
    [self InitFlickerEffect:TRUE];
    
    mFlickerEnabled = inParams->mFlickerEnabled;
    mUseColorOffsets = inParams->mUseColorOffsets;
        
    return self;
}

-(void)dealloc
{
    [mCirclePixelTexture release];
    [mNoiseTexture release];
    [mCameraOrtho release];
    [mCompositingFramebuffer release];
    
    [mNoiseEffect.mNoisePath release];
    [mFlickerEffect.mFlickerPath release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(JumbotronFilterParams*)outParams
{
    outParams->mSourceTexture = NULL;
    outParams->mDestFramebuffer = NULL;
    outParams->mMinNoise = 0.0f;
    outParams->mMaxNoise = 1.0f;
    outParams->mFlickerEnabled = TRUE;
    outParams->mUseColorOffsets = TRUE;
}

-(void)InitNoiseEffect:(BOOL)inFirst
{
    float startVal = 0.0f;
    
    if (!inFirst)
    {
        [mNoiseEffect.mNoisePath GetValueScalar:&startVal];
    }
    
    [mNoiseEffect.mNoisePath Reset];

    float newNoise = RandFloat(mNoiseEffect.mLowerAmount, mNoiseEffect.mUpperAmount);
    float newDuration = RandFloat(NOISE_MIN_DURATION, NOISE_MAX_DURATION);
    
    newNoise -= 0.1f;
    newNoise = LClampFloat(newNoise, 0.0f);
    
    newNoise = sqrt(newNoise);
    
    [mNoiseEffect.mNoisePath AddNodeScalar:startVal atTime:0.0f];
    [mNoiseEffect.mNoisePath AddNodeScalar:newNoise atTime:NOISE_TRANSITION_DURATION];
    [mNoiseEffect.mNoisePath AddNodeScalar:newNoise atTime:(newDuration + NOISE_TRANSITION_DURATION)];
}

-(void)InitFlickerEffect:(BOOL)inFirst
{
    [mFlickerEffect.mFlickerPath Reset];

    float flickerDelay = RandFloat(FLICKER_DELAY_MIN, FLICKER_DELAY_MAX);
    
    [mFlickerEffect.mFlickerPath AddNodeScalar:1.0f atTime:0.0f];
    [mFlickerEffect.mFlickerPath AddNodeScalar:1.0f atTime:flickerDelay];
    
    int numFlickers = arc4random_uniform(FLICKER_NUM_MAX - FLICKER_NUM_MIN) + FLICKER_NUM_MIN;
    float curTime = flickerDelay;
    
    flickerDelay = RandFloat(FLICKER_PERIOD_MIN, FLICKER_PERIOD_MAX);
    
    for (int i = 0; i < numFlickers; i++)
    {
        [mFlickerEffect.mFlickerPath AddNodeScalar:FLICKER_BRIGHTNESS_VAL atTime:(curTime + EPSILON)];
        [mFlickerEffect.mFlickerPath AddNodeScalar:FLICKER_BRIGHTNESS_VAL atTime:(curTime + flickerDelay)];
        [mFlickerEffect.mFlickerPath AddNodeScalar:1.0f atTime:(curTime + flickerDelay + EPSILON)];
        [mFlickerEffect.mFlickerPath AddNodeScalar:1.0f atTime:(curTime + (flickerDelay * 2))];
        [mFlickerEffect.mFlickerPath AddNodeScalar:1.0f atTime:(curTime + (flickerDelay * 3))];
        
        curTime += (flickerDelay * 3);
    }
}

static float sSubPixelOffsets[6] = {  -1.5f, 0.0f,
                                      1.5f, 0.0f,
                                      0.0f, 1.5f };

static bool sColorMasks[9] = {  true, false, false,
                                false, true, false,
                                false, false, true };

-(void)Draw
{
    GLState glState;
    SaveGLState(&glState);
    
    GLint viewport[4];
    NeonGLGetIntegerv(GL_VIEWPORT, viewport);
    
    int width = [mSourceTexture GetRealWidth];
    int height = [mSourceTexture GetRealHeight];

	NeonGLViewport(0, 0, width, height);

	GLint oldFb;
	NeonGLGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &oldFb);
    
    NeonGLEnable(GL_BLEND);
		
    [mCameraOrtho SetFrameLeft:-(width / 2)
					right:width / 2
					top:height / 2
					bottom:-(height / 2)];
    
	NeonGLMatrixMode(GL_PROJECTION);
    glPushMatrix();
    
	Matrix44 projectionMatrix;
	[mCameraOrtho GetProjectionMatrix:&projectionMatrix];
	
	glLoadMatrixf(projectionMatrix.mMatrix);
	
	NeonGLDisable(GL_DEPTH_TEST);
	NeonGLClearColor(0.0, 0.0, 0.0, 1.0);
    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
	{
		Matrix44 viewMatrix;
		[mCameraOrtho GetViewMatrix:&viewMatrix];
        
        Matrix44 scaleMatrix;
        GenerateScaleMatrix(width, height, 1.0f, &scaleMatrix);
        
        Matrix44 transform;
        MatrixMultiply(&viewMatrix, &scaleMatrix, &transform);
		
		glLoadMatrixf(transform.mMatrix);
		
        float vertex[12] = {    0, 0, 0,
                                0, 1, 0,
                                1, 0, 0,
                                1, 1, 0 };
        
        float sMax = (float)[mSourceTexture GetRealWidth] / (float)[mSourceTexture GetGLWidth];
        float tMax = (float)[mSourceTexture GetRealHeight] / (float)[mSourceTexture GetGLHeight];
                                
        float texCoord[8] = {   0,      0,
                                0,      tMax,
                                sMax,   0,
                                sMax,   tMax  };
        
        [mSourceTexture Bind];
        [mCompositingFramebuffer Bind];
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        glClientActiveTexture(GL_TEXTURE0);
        
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, texCoord);
        
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, vertex);
    	
        Matrix44 tweakTranslate;
        
        NeonGLBlendFunc(GL_ONE, GL_ONE);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        
        float flickerColor = 1.0f;
        
        [mFlickerEffect.mFlickerPath GetValueScalar:&flickerColor];
        
        if (!mFlickerEnabled)
        {
            flickerColor = 1.0f;
        }
        
        // Loop over each channel twice to make the jumbotron extra bright (saturate to white).
        
        int numChannels = mUseColorOffsets ? 3 : 1;
        
        for (int i = 0; i < numChannels; i++)
        {
            for (int pass = 0; pass < 2; pass++)
            {
                glPushMatrix();
                
                GenerateTranslationMatrix(sSubPixelOffsets[i * 2], sSubPixelOffsets[i * 2 + 1], 0.0f, &tweakTranslate);
                
                MatrixMultiply(&viewMatrix, &tweakTranslate, &transform);
                MatrixMultiply(&transform, &scaleMatrix, &transform);
                
                glLoadMatrixf(transform.mMatrix);
                
                if (mUseColorOffsets)
                {
                    glColorMask(sColorMasks[i*3], sColorMasks[i*3 + 1], sColorMasks[i*3 + 2], true);
                }
                
                glColor4f(OVERBRIGHT_CHANNEL_BRIGHTNESS * flickerColor, OVERBRIGHT_CHANNEL_BRIGHTNESS * flickerColor, OVERBRIGHT_CHANNEL_BRIGHTNESS * flickerColor, 1.0);
                
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                glPopMatrix();
            }
        }
 
        NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glColorMask(true, true, true, true);
                
        [mNoiseTexture Bind];
        
        int noiseWidth = [mNoiseTexture GetRealWidth];
        int noiseHeight = [mNoiseTexture GetRealHeight];
                
        int xMin = arc4random() % (noiseWidth - (width * 2));
        int yMin = arc4random() % (noiseHeight - (height * 2));
        
        int xMax = xMin + (width * 2);
        int yMax = yMin + (height * 2);
        
        float sMin = (float)(xMin) / (float)noiseWidth;
        float tMin = (float)(yMin) / (float)noiseHeight;
        
        sMax = (float)(xMax) / (float)noiseWidth;
        tMax = (float)(yMax) / (float)noiseHeight;

        
        float texCoordNoise[8] = {  sMin,   tMin,
                                    sMin,   tMax,
                                    sMax,   tMin,
                                    sMax,   tMax    };
        
        float noiseVal = 0;
        [mNoiseEffect.mNoisePath GetValueScalar:&noiseVal];
        
        glTexCoordPointer(2, GL_FLOAT, 0, texCoordNoise);
        glColor4f(1.0f, 1.0f, 1.0f, noiseVal);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        [[mCompositingFramebuffer GetColorAttachment] Bind];
        [mDestFramebuffer Bind];
        
        glTexCoordPointer(2, GL_FLOAT, 0, texCoord);

        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
        NeonGLActiveTexture(GL_TEXTURE1);
        glClientActiveTexture(GL_TEXTURE1);

        [mCirclePixelTexture Bind];

        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);

        glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
        glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
        glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
        
        sMax = (float)[mCirclePixelTexture GetRealWidth] / (float)[mCirclePixelTexture GetGLWidth];
        tMax = (float)[mCirclePixelTexture GetRealHeight] / (float)[mCirclePixelTexture GetGLHeight];
                
        float texCoordCircle[8] = { 0.0f,   0.0f,
                                    0.0f,   tMax,
                                    sMax,   0.0f,
                                    sMax,   tMax    };
                        
        glTexCoordPointer(2, GL_FLOAT, 0, texCoordCircle);

        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, vertex);
    	
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        NeonGLDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        
        NeonGLActiveTexture(GL_TEXTURE0);
        glClientActiveTexture(GL_TEXTURE0);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	}
	glPopMatrix();

	NeonGLEnable(GL_DEPTH_TEST);
	
    NeonGLMatrixMode(GL_PROJECTION);
    glPopMatrix();
	
	NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, oldFb);
	
	NeonGLViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    
    RestoreGLState(&glState);
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [self UpdateNoiseEffect:inTimeStep];
    [self UpdateFlickerEffect:inTimeStep];
}

-(void)UpdateNoiseEffect:(CFTimeInterval)inTimeStep
{
    [mNoiseEffect.mNoisePath Update:inTimeStep];
    
    if ([mNoiseEffect.mNoisePath Finished])
    {
        [self InitNoiseEffect:FALSE];
    }
}

-(void)UpdateFlickerEffect:(CFTimeInterval)inTimeStep
{
    [mFlickerEffect.mFlickerPath Update:inTimeStep];
    
    if ([mFlickerEffect.mFlickerPath Finished])
    {
        [self InitFlickerEffect:FALSE];
    }
}

-(float)GetFlickerAmount
{
    float flickerAmount;
    
    [mFlickerEffect.mFlickerPath GetValueScalar:&flickerAmount];

    return flickerAmount;
}

@end