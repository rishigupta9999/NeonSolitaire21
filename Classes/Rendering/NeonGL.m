//
//  NeonGL.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "NeonGL.h"

#define TEXTURE_INVALID (-1)

static NeonGL* sInstance = NULL;

@implementation NeonGL

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create NeonGL");
    sInstance = [(NeonGL*)[NeonGL alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double-delete NeonGL");
    [sInstance release];
    
    sInstance = NULL;
}

+(NeonGL*)GetInstance
{
    return sInstance;
}

-(NeonGL*)Init
{
    mSrcBlend = GL_ZERO;
    mDestBlend = GL_ZERO;
    
    mBlendEnabled = FALSE;
    mDepthEnabled = FALSE;
    mCullingEnabled = FALSE;
    mLightingEnabled = FALSE;
    
    memset(mViewport, 0, sizeof(mViewport));
    
    mActiveTextureUnit = 0;
    memset(mTextureEnabled, 0, sizeof(mTextureEnabled));
    
    mMatrixMode = GL_MODELVIEW;
    
    for (int i = 0; i < NEON_GL_NUM_TEXTURE_UNITS; i++)
    {
        mCurTexture[i] = TEXTURE_INVALID;
    }
    
    memset(mClearColor, 0, sizeof(mClearColor));
    
    mFramebuffer = TEXTURE_INVALID;
    mDrawFramebuffer = TEXTURE_INVALID;
    mReadFramebuffer = TEXTURE_INVALID;
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(void)Enable:(GLenum)inEnable
{
    switch(inEnable)
    {
        case GL_BLEND:
        {
            if (mBlendEnabled)
            {
                return;
            }
            
            mBlendEnabled = TRUE;
            break;
        }
        
        case GL_DEPTH_TEST:
        {
            if (mDepthEnabled)
            {
                return;
            }
            
            mDepthEnabled = TRUE;
            
            break;
        }
        
        case GL_TEXTURE_2D:
        {
            if (mTextureEnabled[mActiveTextureUnit])
            {
                return;
            }
            
            mTextureEnabled[mActiveTextureUnit] = TRUE;
            
            break;
        }
        
        case GL_CULL_FACE:
        {
            if (mCullingEnabled)
            {
                return;
            }
            
            mCullingEnabled = TRUE;
            
            break;
        }
        
        case GL_LIGHTING:
        {
            if (mLightingEnabled)
            {
                return;
            }
            
            mLightingEnabled = TRUE;
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unsupported enable");
            break;
        }
    }
    
    glEnable(inEnable);
}

-(void)Disable:(GLenum)inDisable
{
    switch(inDisable)
    {
        case GL_BLEND:
        {
            if (!mBlendEnabled)
            {
                return;
            }
            
            mBlendEnabled = FALSE;
            break;
        }
        
        case GL_DEPTH_TEST:
        {
            if (!mDepthEnabled)
            {
                return;
            }
            
            mDepthEnabled = FALSE;
            
            break;
        }
        
        case GL_TEXTURE_2D:
        {
            if (!mTextureEnabled[mActiveTextureUnit])
            {
                return;
            }
            
            mTextureEnabled[mActiveTextureUnit] = FALSE;
        
            break;
        }
        
        case GL_CULL_FACE:
        {
            if (!mCullingEnabled)
            {
                return;
            }
            
            mCullingEnabled = FALSE;
            
            break;
        }
        
        case GL_LIGHTING:
        {
            if (!mLightingEnabled)
            {
                return;
            }
            
            mLightingEnabled = FALSE;
            
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unsupported disable");
            break;
        }
    }
    
    glDisable(inDisable);
}

-(void)BlendFuncSrc:(GLenum)inSrcBlend dest:(GLenum)inDestBlend
{
    if ((mSrcBlend == inSrcBlend) && (mDestBlend == inDestBlend))
    {
        return;
    }
    
    mSrcBlend = inSrcBlend;
    mDestBlend = inDestBlend;
    
    glBlendFunc(inSrcBlend, inDestBlend);
}

-(void)GetIntegerv:(GLenum)inEnum value:(int*)outInteger
{
    switch(inEnum)
    {
        case GL_BLEND:
        {
            *outInteger = mBlendEnabled;
            break;
        }
        
        case GL_BLEND_SRC:
        {
            *outInteger = mSrcBlend;
            break;
        }
        
        case GL_BLEND_DST:
        {
            *outInteger = mDestBlend;
            break;
        }
        
        case GL_DEPTH_TEST:
        {
            *outInteger = mDepthEnabled;
            break;
        }
        
        case GL_VIEWPORT:
        {
            memcpy(outInteger, mViewport, sizeof(mViewport));
            break;
        }
        
        default:
        {
            glGetIntegerv(inEnum, outInteger);
            break;
        }
    }
}

-(void)ViewportX:(int)inX y:(int)inY width:(int)inWidth height:(int)inHeight
{
    if ((mViewport[0] == inX) && (mViewport[1] == inY) && (mViewport[2] == inWidth) && (mViewport[3] == inHeight))
    {
        return;
    }
    
    mViewport[0] = inX;
    mViewport[1] = inY;
    mViewport[2] = inWidth;
    mViewport[3] = inHeight;
    
    glViewport(inX, inY, inWidth, inHeight);
}

-(void)ActiveTexture:(GLenum)inActiveTexture
{
    NSAssert((inActiveTexture >= GL_TEXTURE0) && (inActiveTexture <= GL_TEXTURE7), @"Invalid texture unit");
    
    int activeTexture = inActiveTexture - GL_TEXTURE0;
    
    if (mActiveTextureUnit != activeTexture)
    {
        mActiveTextureUnit = activeTexture;
        glActiveTexture(inActiveTexture);
    }
}

-(void)BindTexture:(GLenum)inTarget texName:(int)inTextureName
{
    NSAssert(inTarget == GL_TEXTURE_2D, @"We only support GL_TEXTURE_2D texture targets");
    
    if (mCurTexture[mActiveTextureUnit] == inTextureName)
    {
        return;
    }
    
    mCurTexture[mActiveTextureUnit] = inTextureName;
    glBindTexture(inTarget, inTextureName);
}

-(void)DeleteTextures:(int)inNumTextures ids:(u32*)inTextureIds
{
    NSAssert(inNumTextures == 1, @"This function should work with more than 1 texture, but has never been tested.  Please verify functionality.");
    
    glDeleteTextures(inNumTextures, inTextureIds);
    
    for (int curTexture = 0; curTexture < inNumTextures; curTexture++)
    {
        for (int i = 0; i < NEON_GL_NUM_TEXTURE_UNITS; i++)
        {
            if (mCurTexture[i] == inTextureIds[curTexture])
            {
                mCurTexture[i] = TEXTURE_INVALID;
            }
        }
    }
}

-(void)MatrixMode:(GLenum)inMatrixMode
{
    if (mMatrixMode == inMatrixMode)
    {
        return;
    }
    
    mMatrixMode = inMatrixMode;
    glMatrixMode(inMatrixMode);
}

-(void)ClearColorR:(float)inR g:(float)inG b:(float)inB a:(float)inA
{
    if ((inR != mClearColor[0]) || (inG != mClearColor[1]) || (inB != mClearColor[2]) || (inA != mClearColor[3]))
    {
        mClearColor[0] = inR;
        mClearColor[1] = inG;
        mClearColor[2] = inB;
        mClearColor[3] = inA;
        
        NeonGLClearColor(inR, inG, inB, inA);
    }
}

-(void)BindFramebuffer:(GLenum)inTarget identifier:(int)inIdentifier
{
    NSAssert(   (inTarget == GL_FRAMEBUFFER_OES) || (inTarget == GL_READ_FRAMEBUFFER_APPLE) || (inTarget = GL_DRAW_FRAMEBUFFER_APPLE),
                @"Only the GL_FRAMEBUFFER target is currently supported");
    
    switch(inTarget)
    {
        case GL_FRAMEBUFFER_OES:
        {
            if (mFramebuffer == inIdentifier)
            {
                return;
            }
            
            mFramebuffer = inIdentifier;
            mDrawFramebuffer = inIdentifier;
            mReadFramebuffer = inIdentifier;
            
            break;
        }
        
        case GL_READ_FRAMEBUFFER_APPLE:
        {
            if (mReadFramebuffer == inIdentifier)
            {
                return;
            }
            
            mReadFramebuffer = inIdentifier;
            
            break;
        }
        
        case GL_DRAW_FRAMEBUFFER_APPLE:
        {
            if (mDrawFramebuffer == inIdentifier)
            {
                return;
            }
            
            mDrawFramebuffer = inIdentifier;
            
            break;
        }
    }

    glBindFramebuffer(inTarget, inIdentifier);
}

@end

void NeonGLEnable(GLenum inEnable)
{
    [[NeonGL GetInstance] Enable:inEnable];
}

void NeonGLDisable(GLenum inDisable)
{
    [[NeonGL GetInstance] Disable:inDisable];
}

void NeonGLBlendFunc(GLenum inSrcBlend, GLenum inDestBlend)
{
    [[NeonGL GetInstance] BlendFuncSrc:inSrcBlend dest:inDestBlend];
}

void NeonGLGetIntegerv(GLenum inEnum, int* outValue)
{
    [[NeonGL GetInstance] GetIntegerv:inEnum value:outValue];
}

void NeonGLViewport(int inX, int inY, int inWidth, int inHeight)
{
    [[NeonGL GetInstance] ViewportX:inX y:inY width:inWidth height:inHeight];
}

void NeonGLActiveTexture(GLenum inTextureUnit)
{
    [[NeonGL GetInstance] ActiveTexture:inTextureUnit];
}

void NeonGLBindTexture(GLenum inTarget, int inTexture)
{
    [[NeonGL GetInstance] BindTexture:inTarget texName:inTexture];
}

void NeonGLDeleteTextures(int inNumTextures, u32* inTextureIds)
{
    [[NeonGL GetInstance] DeleteTextures:inNumTextures ids:inTextureIds];
}

void NeonGLMatrixMode(GLenum inMatrixMode)
{
    [[NeonGL GetInstance] MatrixMode:inMatrixMode];
}

void NeonGLClearColor(float inR, float inG, float inB, float inA)
{
    [[NeonGL GetInstance] ClearColorR:inR g:inG b:inB a:inA];
}

void NeonGLBindFramebuffer(GLenum inTarget, int inIdentifier)
{
    [[NeonGL GetInstance] BindFramebuffer:inTarget identifier:inIdentifier];
}