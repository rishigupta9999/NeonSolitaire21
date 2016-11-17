//
//  Light.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Light.h"

@implementation Light

-(Light*)InitWithIdentifier:(int)inIdentifier
{
    mGLIdentifier = inIdentifier;
    
    glEnable(mGLIdentifier);
    
    mEnabled = TRUE;
    
    [Light InitDefaultParams:&mParams];
    [self ApplyParams];
    
    return self;
}

-(void)dealloc
{
    glDisable(mGLIdentifier);
    
    [super dealloc];
}

-(void)ApplyParams
{
    Vector4 argVector;
    glLightfv(mGLIdentifier, GL_POSITION, SetVec4From3(&argVector, &mParams.mVector, mParams.mDirectional ? 0.0f : 1.0f )->mVector);
    
    glLightfv(mGLIdentifier, GL_AMBIENT,  SetVec4From3(&argVector, &mParams.mAmbientRGB, 1.0f)->mVector);
    glLightfv(mGLIdentifier, GL_DIFFUSE,  SetVec4From3(&argVector, &mParams.mDiffuseRGB, 1.0f)->mVector);
    glLightfv(mGLIdentifier, GL_SPECULAR, SetVec4From3(&argVector, &mParams.mSpecularRGB, 1.0f)->mVector);
    
    glLightfv(mGLIdentifier, GL_SPOT_DIRECTION, SetVec4From3(&argVector, &mParams.mSpotDirection, 1.0f)->mVector);
    glLightf(mGLIdentifier,  GL_SPOT_CUTOFF,    mParams.mSpotCutoff);
    glLightf(mGLIdentifier,  GL_SPOT_EXPONENT,  mParams.mSpotExponent);

    glLightf(mGLIdentifier, GL_CONSTANT_ATTENUATION,    mParams.mConstantAttenuation);
    glLightf(mGLIdentifier, GL_LINEAR_ATTENUATION,      mParams.mLinearAttenuation);
    glLightf(mGLIdentifier, GL_QUADRATIC_ATTENUATION,   mParams.mQuadraticAttenuation);
    
    NeonGLError();
}

-(LightParams*)GetParams
{
    return &mParams;
}

+(void)InitDefaultParams:(LightParams*)inParams
{
    inParams->mDirectional = TRUE;
    
    Set(&inParams->mVector, 0.0f, 0.0f, 1.0f);
    
    Set(&inParams->mAmbientRGB, 0.0f, 0.0f, 0.0f);
    Set(&inParams->mDiffuseRGB, 1.0f, 1.0f, 1.0f);
    Set(&inParams->mSpecularRGB, 1.0f, 1.0f, 1.0f);
    
    Set(&inParams->mSpotDirection, 0.0f, 0.0f, -1.0f);
    
    inParams->mSpotCutoff = 180.0f;
    inParams->mSpotExponent = 0.0f;
    
    inParams->mConstantAttenuation = 1.0f;
    inParams->mLinearAttenuation = 0.0f;
    inParams->mQuadraticAttenuation = 0.0f;
}

-(void)SetLightActive:(BOOL)inActive
{
    mEnabled = inActive;
    
    if (inActive)
    {
        glEnable(mGLIdentifier);
    }
    else
    {
        glDisable(mGLIdentifier);
    }
}

-(BOOL)GetLightActive
{
    return mEnabled;
}

@end