//
//  TextureManager.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "TextureManager.h"
#import "ResourceManager.h"

#import "PNGTexture.h"
#import "PVRTCTexture.h"
#import "JPEGTexture.h"

static TextureManager* sInstance = NULL;

@implementation TextureManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Trying to create TextureManager when one already exists.");
    
    sInstance = [TextureManager alloc];
    [sInstance Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"No texture manager exists.");
    
    [sInstance Term];
    [sInstance release];
}

+(TextureManager*)GetInstance
{
    return sInstance;
}

-(void)Init
{
    mLoadingQueue = dispatch_queue_create("com.neongames.textureloader.bgqueue", NULL);
}

-(void)Term
{
    dispatch_release(mLoadingQueue);
}

-(Texture*)TextureWithName:(NSString*)inName
{
    TextureParams params;
    
    [Texture InitDefaultParams:&params];
    
    return [self TextureWithName:inName textureParams:&params];
}

-(Texture*)TextureWithName:(NSString*)inName textureParams:(TextureParams*)inParams
{
    if (inParams->mTextureAtlas != NULL)
    {
        Texture* testTexture = [inParams->mTextureAtlas GetTextureWithIdentifier:inName];
        
        if (testTexture != NULL)
        {
            return testTexture;
        }
    }
    
	ResourceLoadParams resourceLoadParams;
	[ResourceManager InitDefaultParams:&resourceLoadParams];
	
	resourceLoadParams.mAttemptRetina = GetScreenRetina() || GetDevicePad();
	
    NSNumber*   resourceHandle = [[ResourceManager GetInstance] LoadAssetWithName:inName params:&resourceLoadParams];
    NSData*     texData = [[ResourceManager GetInstance] GetDataForHandle:resourceHandle];

    Texture*    retTexture = NULL;
    
    if ([[inName pathExtension] caseInsensitiveCompare:@"PNG"] == NSOrderedSame)
    {
        retTexture = [(PNGTexture*)[PNGTexture alloc] InitWithData:texData textureParams:inParams];
        [retTexture autorelease];
    }
    else if ([[inName pathExtension] caseInsensitiveCompare:@"PAPNG"] == NSOrderedSame)
    {
        retTexture = [(PNGTexture*)[PNGTexture alloc] InitWithData:texData textureParams:inParams];
        [retTexture autorelease];
        
        retTexture->mPremultipliedAlpha = TRUE;
    }
    else if (([[inName pathExtension] caseInsensitiveCompare:@"JPG"] == NSOrderedSame) || ([[inName pathExtension] caseInsensitiveCompare:@"PAPNG"] == NSOrderedSame))
    {
        retTexture = [(JPEGTexture*)[JPEGTexture alloc] InitWithData:texData textureParams:inParams];
        [retTexture autorelease];
    }
#if TARGET_OS_IPHONE
    else if ([[inName pathExtension] caseInsensitiveCompare:@"PVRTC"] == NSOrderedSame)
    {
        retTexture = [(PVRTCTexture*)[PVRTCTexture alloc] InitWithData:texData textureParams:inParams];
        [retTexture autorelease];
    }
#endif
    else
    {
        NSAssert(FALSE, @"Unknown texture type");
    }
    
    [retTexture SetIdentifier:inName];
	
	if ([[ResourceManager GetInstance] GetResourceFamily:resourceHandle] == RESOURCEFAMILY_PHONE_RETINA)
	{
		[retTexture SetScaleFactor:GetRetinaScaleFactor()];
	}
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:resourceHandle];
    
    return retTexture;
}

-(dispatch_queue_t)GetLoadingQueue
{
    return mLoadingQueue;
}

@end