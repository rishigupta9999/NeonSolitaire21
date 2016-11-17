//
//  GLExtensionManager.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GLExtensionManager.h"

static GLExtensionManager* sInstance = NULL;

const char* sExtensionStrings[GL_EXTENSION_MAX] = { "GL_APPLE_texture_max_level",
                                                    "GL_APPLE_framebuffer_multisample",
                                                    "GL_OES_packed_depth_stencil",
                                                    "GL_OES_stencil8" };

@implementation GLExtensionManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to create GLExtensionManager twice");
    
    sInstance = [(GLExtensionManager*)[GLExtensionManager alloc] Init];
}

+(void)DestroyInstance
{
    [sInstance release];
    sInstance = NULL;
}

+(GLExtensionManager*)GetInstance
{
    return sInstance;
}

-(GLExtensionManager*)Init
{
    const char* extensions = (char*)glGetString(GL_EXTENSIONS);
    
    memset(mExtensions, 0, sizeof(BOOL) * GL_EXTENSION_NUM);
    
    for (int i = 0; i < GL_EXTENSION_NUM; i++)
    {
    
#if TARGET_IPHONE_SIMULATOR
        // Don't do MSAA on the simulator since it's too slow.
        if (i == GL_EXTENSION_APPLE_FRAMEBUFFER_MULTISAMPLE)
        {
            continue;
        }
#endif

        if (strstr(extensions, sExtensionStrings[i]) != NULL)
        {
            mExtensions[i] = TRUE;
        }
        else
        {
            mExtensions[i] = FALSE;
        }
    }
    
    const char* renderer = (char*)glGetString(GL_RENDERER);
    
    mGPUVersion = 0;

    if (strstr(renderer, "MBX") != NULL)
    {
        mGPUClass = GPU_CLASS_MBX;
    }
    else if (strstr(renderer, "SGX") != NULL)
    {
        mGPUClass = GPU_CLASS_SGX;
        
        char* version = strstr(renderer, "SGX");
        
        // Move past "SGX"
        version += 3;
        
        sscanf(version, "%d", &mGPUVersion);
    }
    else if (strstr(renderer, "Apple A7 GPU") != NULL)
    {
        mGPUClass = GPU_CLASS_RGX;
    }
    else
    {
        mGPUClass = GPU_CLASS_OTHER;
    }
    
    // Initialize whether we're using a Retina display
    float scale = [[UIScreen mainScreen] scale];
    SetScreenRetina(scale > 1.0f);
    
    // Initialize whether we're using a stencil buffer in the default drawable framebuffer.  Default is false.
    mUsingStencil = FALSE;

    return self;
}

-(BOOL)IsExtensionSupported:(GLExtension)inExtension
{
    NSAssert( ((inExtension >= 0) && (inExtension < GL_EXTENSION_NUM)), @"Invalid extension passed in" );
        
    return mExtensions[inExtension];
}

-(GPUClass)GetGPUClass
{
    return mGPUClass;
}

-(u32)GetGPUVersion
{
    return mGPUVersion;
}

-(BOOL)GetUsingStencil
{
    return mUsingStencil;
}

-(void)SetUsingStencil:(BOOL)inUsingStencil
{
    mUsingStencil = inUsingStencil;
}

@end