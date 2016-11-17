//
//  GLExtensionManager.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

typedef enum
{
    GL_EXTENSION_APPLE_TEXTURE_MAX_LEVEL,
    GL_EXTENSION_APPLE_FRAMEBUFFER_MULTISAMPLE,
    GL_EXTENSION_OES_PACKED_DEPTH_STENCIL,
    GL_EXTENSION_OES_STENCIL_8,
    GL_EXTENSION_MAX,
    GL_EXTENSION_NUM = GL_EXTENSION_MAX
} GLExtension;

typedef enum
{
    GPU_CLASS_MBX,
    GPU_CLASS_SGX,
    GPU_CLASS_RGX,
    GPU_CLASS_OTHER
} GPUClass;

@interface GLExtensionManager : NSObject
{
    BOOL        mExtensions[GL_EXTENSION_NUM];
    GPUClass    mGPUClass;
    u32         mGPUVersion;
    BOOL        mUsingStencil;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(GLExtensionManager*)GetInstance;

-(GLExtensionManager*)Init;
-(BOOL)IsExtensionSupported:(GLExtension)inExtension;
-(GPUClass)GetGPUClass;
-(u32)GetGPUVersion;

-(BOOL)GetUsingStencil;
-(void)SetUsingStencil:(BOOL)inUsingStencil;

@end