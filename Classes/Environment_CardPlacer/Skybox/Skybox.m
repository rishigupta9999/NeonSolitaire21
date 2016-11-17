//
//  Skybox.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Skybox.h"
#import "TextureManager.h"
#import "CameraStateMgr.h"

#define SKYBOX_EXTENT   (25.0f)

static const float sVertexBuffers[SKYBOX_NUM][12] = {
    { SKYBOX_EXTENT, 0.0, -SKYBOX_EXTENT, SKYBOX_EXTENT, 0.0, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT },
    { -SKYBOX_EXTENT, 0.0, SKYBOX_EXTENT, -SKYBOX_EXTENT, 0.0, -SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT },
    { -SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT },
    { -SKYBOX_EXTENT, 0.0, SKYBOX_EXTENT, SKYBOX_EXTENT, 0.0, SKYBOX_EXTENT, -SKYBOX_EXTENT, 0.0, -SKYBOX_EXTENT, SKYBOX_EXTENT, 0.0, -SKYBOX_EXTENT },
    { SKYBOX_EXTENT, 0.0, SKYBOX_EXTENT, -SKYBOX_EXTENT, 0.0, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT },
    { -SKYBOX_EXTENT, 0.0, -SKYBOX_EXTENT, SKYBOX_EXTENT, 0.0, -SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT, SKYBOX_EXTENT, SKYBOX_EXTENT, -SKYBOX_EXTENT },
};

static const float sTexcoordBuffer[8] = { 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0 };

@implementation Skybox

-(Skybox*)InitWithParams:(SkyboxParams*)inParams
{
    [super Init];
    
    TextureParams textureParams;
    
    [Texture InitDefaultParams:&textureParams];
    
    for (int curFace = 0; curFace < SKYBOX_NUM; curFace++)
    {
        if (inParams->mFiles[curFace] != NULL)
        {
            mTextures[curFace] = [[TextureManager GetInstance] TextureWithName:inParams->mFiles[curFace] textureParams:&textureParams];
            [mTextures[curFace] retain];
        }
        else
        {
            mTextures[curFace] = NULL;
        }
    }
    
    memcpy(&mParams, inParams, sizeof(SkyboxParams));
    
    // Don't care about the skybox file names anymore.  Set these to NULL to prevent anyone from trying to access them and crashing
    // in an unpredictable way.
    
    memset(mParams.mFiles, 0, sizeof(NSString*) * SKYBOX_NUM);
    
    return self;
}

-(void)dealloc
{
    for (int curFace = 0; curFace < SKYBOX_NUM; curFace++)
    {
        [mTextures[curFace] release];
    }
    
    [super dealloc];
}

+(void)InitDefaultParams:(SkyboxParams*)outParams
{
    memset(outParams->mFiles, 0, sizeof(NSString*) * SKYBOX_NUM);
    
    for (int i = 0; i < SKYBOX_NUM; i++)
    {
        outParams->mTranslateFace[i] = TRUE;
    }
    
    for (int i = 0; i < 3; i++)
    {
        outParams->mTranslateAxis[i] = TRUE;
    }
}

-(void)Draw
{        
    GLState glState;
    
    SaveGLState(&glState);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glTexCoordPointer(2, GL_FLOAT, 0, sTexcoordBuffer);
    
    // We need to translate by the camera's position.
    // Eg: If camera is at <a, b, c>, then translate by <a, b, c>
    //
    // There are some cases where we *don't* want to do this.
    // Eg: When we can see where the floor and walls join, and
    // the objects have to stay in a consistent spot relative to
    // the floor (pretty much always, except for a constant colored floor)
    
    Vector3 position;
    Matrix44 translate;
    
    [[CameraStateMgr GetInstance] GetPosition:&position];
    
    float t[3] = { 0.0, 0.0, 0.0 };
        
    for (int i = 0; i < 3; i++)
    {
        if (mParams.mTranslateAxis[i])
        {
            t[i] = position.mVector[i];
        }
    }
    
    GenerateTranslationMatrix( t[0], t[1], t[2], &translate );
                                
    NeonGLMatrixMode(GL_MODELVIEW);
                
    for (int curFace = 0; curFace < SKYBOX_NUM; curFace++)
    {
        if (mTextures[curFace] != NULL)
        {
            if (mParams.mTranslateFace[curFace])
            {
                glPushMatrix();
                glMultMatrixf(translate.mMatrix);
            }
            
            [mTextures[curFace] Bind];
            glVertexPointer(3, GL_FLOAT, 0, &sVertexBuffers[curFace][0]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            if (mParams.mTranslateFace[curFace])
            {
                glPopMatrix();
            }
        }
    }
            
    [Texture Unbind];
    RestoreGLState(&glState);
}

@end