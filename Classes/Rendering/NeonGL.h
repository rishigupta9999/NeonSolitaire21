//
//  NeonGL.h
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#define NEON_GL_NUM_TEXTURE_UNITS   (8)

@interface NeonGL : NSObject
{
    BOOL    mBlendEnabled;
    BOOL    mDepthEnabled;
    
    BOOL    mTextureEnabled[NEON_GL_NUM_TEXTURE_UNITS];
    int     mCurTexture[NEON_GL_NUM_TEXTURE_UNITS];
    
    BOOL    mCullingEnabled;
    BOOL    mLightingEnabled;
    
    GLenum  mSrcBlend;
    GLenum  mDestBlend;
    
    int     mViewport[4];
    int     mActiveTextureUnit;
    
    GLenum  mMatrixMode;
    
    float   mClearColor[4];
    
    int     mFramebuffer;
    int     mDrawFramebuffer;
    int     mReadFramebuffer;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(NeonGL*)GetInstance;

-(NeonGL*)Init;
-(void)dealloc;

-(void)Enable:(GLenum)inEnable;
-(void)Disable:(GLenum)inDisable;

-(void)BlendFuncSrc:(GLenum)inSrcBlend dest:(GLenum)inDestBlend;

-(void)GetIntegerv:(GLenum)inEnum value:(int*)outInteger;

-(void)ViewportX:(int)inX y:(int)inY width:(int)inWidth height:(int)inHeight;

-(void)ActiveTexture:(GLenum)inActiveTexture;
-(void)BindTexture:(GLenum)inTarget texName:(int)inTextureName;
-(void)DeleteTextures:(int)inNumTextures ids:(u32*)inTextureIds;

-(void)MatrixMode:(GLenum)inMatrixMode;

-(void)ClearColorR:(float)inR g:(float)inG b:(float)inB a:(float)inA;

-(void)BindFramebuffer:(GLenum)inTarget identifier:(int)inIdentifier;

@end

void NeonGLEnable(GLenum inEnable);
void NeonGLDisable(GLenum inDisable);

void NeonGLBlendFunc(GLenum inSrcBlend, GLenum inDestBlend);

void NeonGLGetIntegerv(GLenum inEnum, int* outValue);

void NeonGLViewport(int inX, int inY, int inWidth, int inHeight);

void NeonGLActiveTexture(GLenum inTextureUnit);
void NeonGLBindTexture(GLenum inTarget, int inTexture);
void NeonGLDeleteTextures(int inNumTextures, u32* inTextureIds);

void NeonGLMatrixMode(GLenum inMatrixMode);

void NeonGLClearColor(float inR, float inG, float inB, float inA);

void NeonGLBindFramebuffer(GLenum inTarget, int inIdentifier);