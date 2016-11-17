#import "PNGTexture.h"
#import "TextureManager.h"
#import "PNGUtilities.h"

#import "PauseMenu.h"
#import "GameStateMgr.h"
#import "SplitTestingSystem.h"

static void PngReadFunction(png_struct* inPngPtr, png_byte* outData, png_size_t inLength);

@implementation PNGTexture

-(Texture*)InitWithBytes:(unsigned char*)inBytes bufferSize:(u32)inBufferSize textureParams:(TextureParams*)inParams
{
    [super InitWithBytes:inBytes bufferSize:inBufferSize textureParams:inParams];
    
    [self SetStatus:TEXTURE_STATUS_DECODING];
    
    if (inParams->mTextureAtlas)
    {
        dispatch_async([[TextureManager GetInstance] GetLoadingQueue],
        ^{
            [self LoadPNGBytes:inBytes];
         } );
    }
    else
    {
        [self LoadPNGBytes:inBytes];
    }
    
    return self;
}

-(Texture*)InitWithData:(NSData*)inData textureParams:(TextureParams*)inParams
{
    [super InitWithData:inData textureParams:inParams];
    
    [self SetStatus:TEXTURE_STATUS_DECODING];
    
    if (inParams->mTextureAtlas)
    {
        dispatch_async([[TextureManager GetInstance] GetLoadingQueue],
        ^{
            [self LoadPNGData:inData];
         } );
    }
    else
    {
        [self LoadPNGData:inData];
    }
    
    return self;
}

-(void)LoadPNGBytes:(unsigned char*)inBytes
{
    PNGInfo pngInfo;
    BOOL success = ReadPNGBytes(inBytes, &pngInfo);
    NSAssert(success, @"Invalid PNG file");
    success = success;
        
    mWidth = pngInfo.mWidth;
    mHeight = pngInfo.mHeight;
    mTexBytes = pngInfo.mImageData;
    
    [self CreateGLTexture];
    [self SetStatus:TEXTURE_STATUS_DECODING_COMPLETE];
}

-(void)LoadPNGData:(NSData*)inData
{
    PNGInfo pngInfo;
    BOOL success = ReadPNGData(inData, &pngInfo);
	NSAssert(success, @"Invalid PNG file");
    success = success;
    
    mWidth = pngInfo.mWidth;
    mHeight = pngInfo.mHeight;
    mTexBytes = pngInfo.mImageData;
    
    [self CreateGLTexture];
    [self SetStatus:TEXTURE_STATUS_DECODING_COMPLETE];
}

-(Texture*)InitWithMipMapData:(NSMutableArray*)inData textureParams:(TextureParams*)inParams
{
    [super InitWithMipMapData:inData textureParams:inParams];
    
    for (int curLevel = 0; curLevel < [inData count]; curLevel++)
    {
        PNGInfo pngInfo;
        ReadPNGData((NSData*)[inData objectAtIndex:curLevel], &pngInfo);

        if (curLevel == 0)
        {
            mWidth = pngInfo.mWidth;
            mHeight = pngInfo.mHeight;
            
#if NEON_DEBUG
            int numLevels = max(log(mWidth) / log(2.0), log(mHeight) / log(2.0)) + 1;
            NSAssert(numLevels == [inData count], @"Invalid number of mipmap levels provided");
#endif
        }
        
        [self SetMipMapData:pngInfo.mImageData level:curLevel];
    }
    
    [self CreateGLTexture];

    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end
