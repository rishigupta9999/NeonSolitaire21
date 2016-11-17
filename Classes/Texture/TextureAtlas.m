//
//  TextureAtlas.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#define TEXTURE_ATLAS_DEFAULT_CAPACITY  (4)

#define DUMP_TEXTURE_NAMES              (0)
#define DUMP_SCANLINE_INFO              (0)

#define UNLIMITED_HEIGHT                (-1)
#define UNLIMITED_WIDTH                 (-1)

#import "TextureAtlas.h"
#import "Texture.h"
#import "TextTextureBuilder.h"
#import "NeonMath.h"
#import "PNGUtilities.h"
#import "GLExtensionManager.h"

@implementation ScanlineEntry

-(void)dealloc
{
    [mTextures release];
    [super dealloc];
}

@end

@implementation TextureAtlasEntry

-(TextureAtlasEntry*)Init
{
    mTexture = NULL;
    return self;
}

-(void)SetTexture:(Texture*)inTexture
{
    mTexture = inTexture;
}

-(void)dealloc
{
    [super dealloc];
}

-(NSComparisonResult)CompareEntryWidth:(TextureAtlasEntry*)inCompare
{
    int compareWidth = [inCompare->mTexture GetMaxWidth];
    int myWidth = [mTexture GetMaxWidth];
    
    if (compareWidth < myWidth)
    {
        return NSOrderedAscending;
    }
    else if (compareWidth > myWidth)
    {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}


@end

@implementation TextureAtlas

-(TextureAtlas*)InitWithParams:(TextureAtlasParams*)inParams
{
    mTextureList = [[NSMutableArray alloc] initWithCapacity:TEXTURE_ATLAS_DEFAULT_CAPACITY];
    mTextureObject = 0;
    mAtlasWidth = 0;
    mAtlasHeight = 0;
    mAtlasPadding = inParams->mPaddingSize;
    
    mGeneratedMipmaps = FALSE;
    mMipmapGenerationEnabled = TRUE;
    
    mDumpDebugImages = FALSE;
    mAtlasState = TEXTURE_ATLAS_STATE_COMPLETE;
    
    NeonGLGetIntegerv(GL_MAX_TEXTURE_SIZE, &mMaxDimension);
    
    mLock = [[NSLock alloc] init];
    
    return self;
}

-(void)dealloc
{
    [mTextureList release];
    [mLock release];
    
    NeonGLDeleteTextures(1, &mTextureObject);
    
    [super dealloc];
}

+(void)InitDefaultParams:(TextureAtlasParams*)outParams
{
    outParams->mPaddingSize = 0;
}

-(void)InitFromExistingParams:(TextureAtlasParams*)outParams
{
    [TextureAtlas InitDefaultParams:outParams];
    
    outParams->mPaddingSize = mAtlasPadding;
}

+(void)InitTextureAtlasInfo:(TextureAtlasInfo*)outInfo
{
    outInfo->mX = 0;
    outInfo->mY = 0;
    
    outInfo->mSMin = 0.0f;
    outInfo->mTMin = 0.0f;
    
    outInfo->mSMax = 0.0f;
    outInfo->mTMax = 0.0f;
    
    outInfo->mPlaced = FALSE;
}

-(void)AddTexture:(Texture*)inTexture
{
    NSAssert(![self AtlasCreated], @"Can't add a texture to an a TextureAtlas where the atlas has already been created");
    
    for (TextureAtlasEntry* curEntry in mTextureList)
    {
        if (curEntry->mTexture == inTexture)
        {
            return;
        }
    }

    TextureAtlasEntry* atlasEntry = [(TextureAtlasEntry*)[TextureAtlasEntry alloc] Init];
    
    [atlasEntry SetTexture:inTexture];

    [(NSMutableArray*)mTextureList addObject:atlasEntry];
    [atlasEntry release];
}

-(void)CreateAtlas
{
#if DUMP_TEXTURE_NAMES
    [self DumpTextureNames];
#endif

    while (true)
    {
        BOOL success = TRUE;
        
        for (TextureAtlasEntry* entry in mTextureList)
        {
            if ([entry->mTexture GetStatus] != TEXTURE_STATUS_DECODING_COMPLETE)
            {
                success = FALSE;
                break;
            }
        }
        
        if (success)
        {
            break;
        }
        
        [NSThread sleepForTimeInterval:0.001f];
    }

    NSArray* newList = [mTextureList sortedArrayUsingSelector:@selector(CompareEntryWidth:)];
    
    [mTextureList release];
    mTextureList = [newList retain];
    
    // Create context for storing current state while placing textures in the atlas
    TextureFitterContext* context = malloc(sizeof(TextureFitterContext));
    
    context->mPlacedTextures = [[NSMutableArray alloc] initWithCapacity:[mTextureList count]];
    context->mScanlineEntries = [[NSMutableArray alloc] initWithCapacity:([mTextureList count] * 2)];

    // Calculate the area of all textures, plus maximum dimension
    
    int area = 0;
    int maxWidth = 0;
    int maxHeight = 0;
        
    for (TextureAtlasEntry* curTextureEntry in mTextureList)
    {
        Texture* curTexture = curTextureEntry->mTexture;
        
        area += ([self GetTexturePaddedMaxWidth:curTexture] * [self GetTexturePaddedMaxHeight:curTexture]);
        
        if ([self GetTexturePaddedMaxHeight:curTexture] >= maxHeight)
        {
            maxHeight = [self GetTexturePaddedMaxHeight:curTexture];
        }
        
        if ([self GetTexturePaddedMaxWidth:curTexture] >= maxWidth)
        {
            maxWidth = [self GetTexturePaddedMaxWidth:curTexture];
        }
        
        NSAssert((maxWidth < mMaxDimension && maxHeight < mMaxDimension), @"Attempting to use a texture larger than maximum supported texture size");
    }
    
    // Now let's try and determine a good starting size
        
    // Round width up to next power of two
    int potWidth = RoundUpPOT(maxWidth);
    
    // Round height up to next power of two
    int potHeight = RoundUpPOT(maxHeight);

    while ((potWidth < maxWidth) || (potHeight < maxHeight) || ((potWidth * potHeight) < area))
    {
        if (potWidth < maxWidth)
        {
            potWidth *= 2;
        }
        
        if (potHeight < maxHeight)
        {
            potHeight *= 2;
        }
        
        if ((potWidth * potHeight) < area)
        {
            if (potWidth < potHeight)
            {
                potWidth *= 2;
            }
            else
            {
                potHeight *= 2;
            }
        }
    }
        
    while (![self FitIntoAtlasWithWidth:potWidth height:potHeight context:context])
    {
        NSAssert(potWidth <= mMaxDimension, @"Width is larger than max texture size");
        NSAssert(potHeight <= mMaxDimension, @"Height is larger than max texture size");
        
        [self ReinitContext:context];
        
        if (potWidth < potHeight)
        {
            potWidth *= 2;
        }
        else
        {
            potHeight *= 2;
        }
    }
        
    // Now that all textures have assigned texture atlas information, time to actually create the texture.
    [self CreateGLTexture:context];
    
    [context->mPlacedTextures release];
    [context->mScanlineEntries release];
    free(context);
    
    // Now that the atlas texture has been created, free all texture data that's no longer needed.
    
    for (TextureAtlasEntry* curEntry in mTextureList)
    {
        if (curEntry->mTexture->mParams.mTexDataLifetime == TEX_DATA_DISPOSE)
        {
            [curEntry->mTexture FreeClientData];
        }
    }
}

-(void)CreateGLTexture:(TextureFitterContext*)inContext
{
    glGenTextures(1, &mTextureObject);
    NeonGLBindTexture(GL_TEXTURE_2D, mTextureObject);
    
    // Currently, texture atlases are only used for UI.  So hardcoded nearest filtering is fine.
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, mAtlasWidth, mAtlasHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    for (Texture* curTexture in inContext->mPlacedTextures)
    {
        glTexSubImage2D(    GL_TEXTURE_2D, 0, curTexture->mTextureAtlasInfo.mX, curTexture->mTextureAtlasInfo.mY,
                            [curTexture GetRealWidth], [curTexture GetRealHeight], GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)curTexture->mTexBytes);
    }
    
    NeonGLBindTexture(GL_TEXTURE_2D, 0);
    
    NeonGLError();
}

-(void)Bind
{
    NSAssert(mTextureObject != 0, @"There is no OpenGL texture object associated with this texture atlas");
    
    while(true)
    {
        if ([self GetAtlasState] == TEXTURE_ATLAS_STATE_COMPLETE)
        {
            break;
        }
        
        [NSThread sleepForTimeInterval:0.001f];
    }
    
    NeonGLEnable(GL_TEXTURE_2D);
	NeonGLBindTexture(GL_TEXTURE_2D, mTextureObject);
}

-(BOOL)AtlasCreated
{
    return (mTextureObject != 0);
}

-(void)SetPaddingSize:(u32)inPaddingSize
{
    mAtlasPadding = inPaddingSize;
}

-(GLuint)GetTextureObject
{
    return mTextureObject;
}

-(BOOL)FitIntoAtlasWithWidth:(int)width height:(int)height context:(TextureFitterContext*)inContext
{    
    mAtlasWidth = width;
    mAtlasHeight = height;
    
    int counter = 0;
    
    for (TextureAtlasEntry* curTextureEntry in mTextureList)
    {
        Texture* curTexture = curTextureEntry->mTexture;
        
        if (![self PackTexture:curTexture context:inContext])
        {
            return FALSE;
        }
        
        counter++;
    }
        
    return TRUE;
}

-(BOOL)PackTexture:(Texture*)inTexture context:(TextureFitterContext*)inContext
{
    for (ScanlineEntry* curEntry in inContext->mScanlineEntries)
    {
        for (Texture* testTexture in curEntry->mTextures)
        {
            // If the texture has its top on the scanline, then 
            int width, height;
            int useX = (testTexture->mTextureAtlasInfo.mX + [self GetTexturePaddedMaxWidth:testTexture]);
            int useY = curEntry->mY;
                        
            // If this is the bottom of the texture, then try left aligning the textures.
            if (testTexture->mTextureAtlasInfo.mY != curEntry->mY)
            {
                useX = testTexture->mTextureAtlasInfo.mX;
            }
            
            [self DetermineRectAtX:useX y:useY width:&width height:&height context:inContext];
            
            if ((width >= [self GetTexturePaddedMaxWidth:inTexture]) && (height >= [self GetTexturePaddedMaxHeight:inTexture]))
            {
                BOOL success = [self PlaceTexture:inTexture x:useX y:useY context:inContext];
                NSAssert(success == TRUE, @"We should have been able to place the texture at this location");
                success = success;
                return TRUE;
            }
        }
    }
    
    ScanlineEntry* lastEntry = (ScanlineEntry*)([inContext->mScanlineEntries lastObject]);
    
    if (lastEntry != NULL)
    {
        // Necessarily, the last entry will be the bottom of a texture.  If we couldn't place a texture on that
        // scanline in the loop above, then we should increment by 1
        if ((mAtlasHeight - (lastEntry->mY + 1)) >= (s32)[self GetTexturePaddedMaxHeight:inTexture])
        {
            BOOL success = [self PlaceTexture:inTexture x:0 y:(lastEntry->mY + 1) context:inContext];
            NSAssert(success == TRUE, @"We should have been able to place the texture at this location");
            success=success;
            return TRUE;
        }
        else
        {
            return FALSE;
        }
    }
    else
    {
        BOOL success = [self PlaceTexture:inTexture x:0 y:0 context:inContext];
        NSAssert(success == TRUE, @"We should have been able to place the texture at this location");
        success=success;
        return TRUE;
    }

    return FALSE;
}

-(BOOL)PlaceTexture:(Texture*)inTexture x:(int)inX y:(int)inY context:(TextureFitterContext*)inContext
{
    BOOL success = FALSE;
    
    if (((inX + [self GetTexturePaddedMaxWidth:inTexture]) <= mAtlasWidth) &&
        ((inY + [self GetTexturePaddedMaxHeight:inTexture]) <= mAtlasHeight)    )
    {
        success = TRUE;
        
        inTexture->mTextureAtlasInfo.mPlaced = TRUE;
        
        inTexture->mTextureAtlasInfo.mX = inX;
        inTexture->mTextureAtlasInfo.mY = inY;
        
        inTexture->mTextureAtlasInfo.mSMin = (float)(inX ) / (float)mAtlasWidth;
        inTexture->mTextureAtlasInfo.mTMin = (float)(inY ) / (float)mAtlasHeight;
        
        inTexture->mTextureAtlasInfo.mSMax = (float)(inX  + [inTexture GetRealWidth]) / (float)mAtlasWidth;
        inTexture->mTextureAtlasInfo.mTMax = (float)(inY  + [inTexture GetRealHeight]) / (float)mAtlasHeight;
        
        [inContext->mPlacedTextures addObject:inTexture];
        
        [self AddTexture:inTexture toScanline:inY context:inContext];
        
        NSAssert([inTexture GetMaxHeight] > 1, @"There may be a few small modifications necessary for 1 pixel high textures");
        [self AddTexture:inTexture toScanline:(inY + [self GetTexturePaddedMaxHeight:inTexture]) context:inContext];
        
#if DUMP_SCANLINE_INFO
        [self DumpScanlineInfo:inContext];
#endif
        if ((TEXTURE_ATLAS_DUMP_DEBUG_IMAGE) || (mDumpDebugImages))
        {
                [self DumpDebugImage:inContext];
        }
    }
    
    return success;
}

-(void)AddTexture:(Texture*)inTexture toScanline:(int)inY context:(TextureFitterContext*)inContext
{
    NSAssert(mTextureObject == 0, @"You can't add a texture to a TextureAtlas that has already had CreateAtlas called on it.");
    
    BOOL foundScanline = FALSE;
    
    for (ScanlineEntry* curEntry in inContext->mScanlineEntries)
    {
        if (curEntry->mY == inY)
        {
            // We add the textures in left to right order on this scanline
            
            int addIndex = 0;
            
            for (Texture* curTexture in curEntry->mTextures)
            {
                if (inTexture->mTextureAtlasInfo.mX < curTexture->mTextureAtlasInfo.mX)
                {
                    break;
                }
                
                addIndex++;
            }
            
            [curEntry->mTextures insertObject:inTexture atIndex:addIndex];
            foundScanline = TRUE;
            break;
        }
    }
    
    if (!foundScanline)
    {
        ScanlineEntry* newEntry = [ScanlineEntry alloc];
        
        newEntry->mY = inY;
        newEntry->mTextures = [[NSMutableArray alloc] initWithCapacity:0];
        [newEntry->mTextures addObject:inTexture];
        
        [self AddScanline:newEntry context:inContext];
        [newEntry release];
    }
}

-(BOOL)ContainsTexture:(Texture*)inTexture
{
    for (TextureAtlasEntry* curEntry in mTextureList)
    {
        if (inTexture == curEntry->mTexture)
        {
            return TRUE;
        }
    }
    
    return FALSE;
}

-(int)GetNumTextures
{
    return [mTextureList count];
}

-(Texture*)GetTexture:(int)inIndex
{
    return ((TextureAtlasEntry*)[mTextureList objectAtIndex:inIndex])->mTexture;
}

-(void)AddScanline:(ScanlineEntry*)inScanline context:(TextureFitterContext*)inContext
{
    int addIndex = 0;
    
    for (ScanlineEntry* curScanline in inContext->mScanlineEntries)
    {
        if (curScanline->mY == inScanline->mY)
        {
            NSAssert(FALSE, @"We should have checked to see if the scanline existed earlier (in the calling function most likely)");
        }
        else if (curScanline->mY > inScanline->mY)
        {
            break;
        }
        
        addIndex++;
    }
    
    [inContext->mScanlineEntries insertObject:inScanline atIndex:addIndex];
}

-(void)DetermineRectAtX:(int)inX y:(int)inY width:(int*)outWidth height:(int*)outHeight context:(TextureFitterContext*)inContext
{
    int heightRemaining = mAtlasHeight - inY;
    int widthRemaining = mAtlasWidth - inX;
    
    for (Texture* curTexture in inContext->mPlacedTextures)
    {
        // Determine if a placed texture intersects with rays shooting to the right and down from <inX, inY>
        
        // 1) Check if Y-Span of the texture interesects the x-ray shooting to the right, and if the texture is to the right of inX
        
        if (curTexture->mTextureAtlasInfo.mX >= inX)
        {
            if ((inY >= curTexture->mTextureAtlasInfo.mY) && (inY < (curTexture->mTextureAtlasInfo.mY + [self GetTexturePaddedMaxHeight:curTexture])))
            {
                int width = curTexture->mTextureAtlasInfo.mX - inX;
                
                if ((width < widthRemaining) || (width < widthRemaining))
                {
                    widthRemaining = width;
                }
            }
        }
        
        // 2) Check if X-Span of the texture interesects the y-ray shooting downwards, and if the texture is below inY
        
        if (curTexture->mTextureAtlasInfo.mY >= inY)
        {
            if ((inX >= curTexture->mTextureAtlasInfo.mX) && (inX < (curTexture->mTextureAtlasInfo.mX + [self GetTexturePaddedMaxWidth:curTexture])))
            {
                int height = curTexture->mTextureAtlasInfo.mY - inY;
                
                if ((heightRemaining == UNLIMITED_HEIGHT) || (height < heightRemaining))
                {
                    heightRemaining = height;
                }
            }
        }
        
        // If either dimension is zero, then there is no room at this location
        if ((widthRemaining == 0) || (heightRemaining == 0))
        {
            break;
        }
    }
    
    *outWidth = widthRemaining;
    *outHeight = heightRemaining;
}

-(void)ReinitContext:(TextureFitterContext*)context
{
    [context->mPlacedTextures removeAllObjects];
    [context->mScanlineEntries removeAllObjects];
}

-(void)UpdateTexture:(Texture*)inTexture
{
    NSAssert(mTextureObject != 0, @"Can't call UpdateTexture if we haven't created the texture object yet.");
    NSAssert( ([inTexture GetRealWidth] <= [inTexture GetMaxWidth]) && ([inTexture GetRealHeight] <= [inTexture GetMaxHeight]),
                @"Trying to add a texture bigger than the max size specified");

    NeonGLBindTexture(GL_TEXTURE_2D, mTextureObject);
    
    glTexSubImage2D(GL_TEXTURE_2D, 0, inTexture->mTextureAtlasInfo.mX, inTexture->mTextureAtlasInfo.mY,
                            [inTexture GetRealWidth], [inTexture GetRealHeight], GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)inTexture->mTexBytes);
    
    if ([[GLExtensionManager GetInstance] GetGPUClass] == GPU_CLASS_RGX)
    {
        glFinish();
    }
    
    if ((mGeneratedMipmaps) && (mMipmapGenerationEnabled))
    {
        // Possible performance issue.  It might make more sense to manually generate mipmaps for the subregion we're updating,
        // and update the region of each mipmap level ourself.
        glGenerateMipmapOES(GL_TEXTURE_2D);
    }
    
    inTexture->mTextureAtlasInfo.mSMax = (float)(inTexture->mTextureAtlasInfo.mX + [inTexture GetRealWidth]) / (float)mAtlasWidth;
    inTexture->mTextureAtlasInfo.mTMax = (float)(inTexture->mTextureAtlasInfo.mY + [inTexture GetRealHeight]) / (float)mAtlasHeight;
}

-(BOOL)GetGeneratedMipmaps
{
    return mGeneratedMipmaps;
}

-(void)SetGeneratedMipmaps:(BOOL)inGeneratedMipmaps
{
    mGeneratedMipmaps = inGeneratedMipmaps;
}

-(void)SetMipmapGenerationEnabled:(BOOL)inEnable
{
    mMipmapGenerationEnabled = inEnable;
}

-(void)DumpTextureNames
{
    for (TextureAtlasEntry* curTexture in mTextureList)
    {
        printf("%s, width %d, height %d\n", [[curTexture->mTexture GetIdentifier] UTF8String], [curTexture->mTexture GetMaxWidth], [curTexture->mTexture GetMaxHeight]);
    }
}

-(void)DumpScanlineInfo:(TextureFitterContext*)inContext
{
    for (ScanlineEntry* curEntry in inContext->mScanlineEntries)
    {
        printf("Scanline %d:\n", curEntry->mY);
        
        for (Texture* curTexture in curEntry->mTextures)
        {
            printf("\tTexture %s %s, x: %d\n",  [[curTexture GetIdentifier] UTF8String], (curTexture->mTextureAtlasInfo.mY == curEntry->mY) ? "TOP" : "BOTTOM",
                                                curTexture->mTextureAtlasInfo.mX  );
        }
    }
}

-(void)DumpDebugImage:(TextureFitterContext*)inContext
{
    unsigned char* buffer = malloc(mAtlasWidth * mAtlasHeight * 4);
    
    // Init to black background with zero alpha
    memset(buffer, 0, mAtlasWidth * mAtlasHeight * 4);
    
    TextureAtlasParams atlasParams;
    [TextureAtlas InitDefaultParams:&atlasParams];
    
    TextureAtlas* dummyAtlas = [[TextureAtlas alloc] InitWithParams:&atlasParams];
    
    for (Texture* curTexture in inContext->mPlacedTextures)
    {
        // Rasterize each texture individually
        
        TextTextureParams textTextureParams;
        
        [TextTextureBuilder InitDefaultParams:&textTextureParams];
        
        textTextureParams.mFontName =[NSString stringWithString:[[LocalizationManager GetInstance] GetFontForType:NEON_FONT_NORMAL]];
        textTextureParams.mColor = 0xFF;
        textTextureParams.mString = [curTexture GetIdentifier];
        textTextureParams.mTextureAtlas = dummyAtlas;
        textTextureParams.mPointSize = 9;
        
        NSAssert(textTextureParams.mString != NULL, @"NULL debug name");
                
        Texture* textureNameTexture = [[TextTextureBuilder GetInstance] GenerateTextureWithParams:&textTextureParams];
        
        // Rasterize a block indicating the position of the texture in the atlas
        for (int y = curTexture->mTextureAtlasInfo.mY; y < (curTexture->mTextureAtlasInfo.mY + [curTexture GetMaxHeight]); y++)
        {
            for (int x = curTexture->mTextureAtlasInfo.mX; x < (curTexture->mTextureAtlasInfo.mX + [curTexture GetMaxWidth]); x++)
            {
                unsigned char* writeBase = &buffer[(x + (y * mAtlasWidth)) * 4];
                
                if  ((x == curTexture->mTextureAtlasInfo.mX) || (y == curTexture->mTextureAtlasInfo.mY) || 
                    (x == (curTexture->mTextureAtlasInfo.mX + [curTexture GetMaxWidth] - 1)) ||
                    (y == (curTexture->mTextureAtlasInfo.mY + [curTexture GetMaxHeight] - 1) ))
                {
                    writeBase[0] = 0xFF;
                    writeBase[1] = 0x00;
                    writeBase[2] = 0x00;
                    writeBase[3] = 0xFF;
                }
                else
                {
                    writeBase[0] = 0xA0;
                    writeBase[1] = 0xA0;
                    writeBase[2] = 0xA0;
                    writeBase[3] = 0xFF;
                }
            }
        }
        
        // Rasterize the text indicating the texture name
        
        int startX = 0;
        int startY = 0;
        
        if ([textureNameTexture GetRealWidth] < [curTexture GetMaxWidth])
        {
            startX = ([curTexture GetMaxWidth] - [textureNameTexture GetRealWidth]) / 2;
        }
        
        if ([textureNameTexture GetRealHeight] < [curTexture GetMaxHeight])
        {
            startY = ([curTexture GetMaxHeight] - [textureNameTexture GetRealHeight]) / 2;
        }
        
        int maxX = min([curTexture GetMaxWidth], [textureNameTexture GetRealWidth]);
        int maxY = min([curTexture GetMaxHeight], [textureNameTexture GetRealHeight]);
        
        for (int y = 0; y < maxY; y++)
        {
            for (int x = 0; x < maxX; x++)
            {
                int useX = curTexture->mTextureAtlasInfo.mX + startX + x;
                int useY = curTexture->mTextureAtlasInfo.mY + startY + y;
                
                unsigned char* writeBase = &buffer[(useX + (useY * mAtlasWidth)) * 4];
                unsigned char* readBase = &(((unsigned char*)(textureNameTexture->mTexBytes))[(x + (y * [textureNameTexture GetMaxWidth])) * 4]);
                
                // Alpha blend the text onto the debug texture (emulate OpenGL GL_SRC_ALPHA/GL_ONE_MINUS_SRC_ALPHA blend mode)
                float srcR = readBase[0] / 255.0f;
                float srcG = readBase[1] / 255.0f;
                float srcB = readBase[2] / 255.0f;
                float srcA = readBase[3] / 255.0f;
                
                float destR = writeBase[0] / 255.0f;
                float destG = writeBase[1] / 255.0f;
                float destB = writeBase[2] / 255.0f;
                float destA = writeBase[3] / 255.0f;
                
                writeBase[0] = (unsigned char)(((srcR * srcA) + (destR * (1.0f - srcA))) * 255.0f);
                writeBase[1] = (unsigned char)(((srcG * srcA) + (destG * (1.0f - srcA))) * 255.0f);
                writeBase[2] = (unsigned char)(((srcB * srcA) + (destB * (1.0f - srcA))) * 255.0f);
                writeBase[3] = (unsigned char)(((srcA * srcA) + (destA * (1.0f - srcA))) * 255.0f);
            }
        }
    }
    
    WritePNG(buffer, [NSString stringWithFormat:@"%d.png", [inContext->mPlacedTextures count]], mAtlasWidth, mAtlasHeight);
    
    free(buffer);
    [dummyAtlas release];
}

-(u32)GetTexturePaddedWidth:(Texture*)inTexture
{
    return ([inTexture GetRealWidth] + mAtlasPadding);
}

-(u32)GetTexturePaddedHeight:(Texture*)inTexture
{
    return ([inTexture GetRealHeight] + mAtlasPadding);
}

-(u32)GetTexturePaddedMaxWidth:(Texture*)inTexture
{
    return ([inTexture GetMaxWidth] + mAtlasPadding);
}

-(u32)GetTexturePaddedMaxHeight:(Texture*)inTexture
{
    return ([inTexture GetMaxHeight] + mAtlasPadding);
}

-(void)DumpTextureObject:(NSString*)inFilename
{
    GLuint fb;
    
    glGenFramebuffersOES(1, &fb);
    NeonGLBindFramebuffer(GL_FRAMEBUFFER_OES, fb);
    
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, mTextureObject, 0);
    
    SaveScreenRect(inFilename, mAtlasWidth, mAtlasHeight);
}

-(void)SetDumpDebugImages:(BOOL)inDumpDebugImages
{
    mDumpDebugImages = TRUE;
}

-(void)SetAtlasState:(TextureAtlasState)inAtlasState
{
    [mLock lock];
    mAtlasState = inAtlasState;
    [mLock unlock];
}

-(TextureAtlasState)GetAtlasState
{
    TextureAtlasState retState = TEXTURE_ATLAS_STATE_COMPLETE;
    
    [mLock lock];
    retState = mAtlasState;
    [mLock unlock];
    
    return retState;
}

-(Texture*)GetTextureWithIdentifier:(NSString*)inIdentifier
{
    int numTextures = [self GetNumTextures];
    
    for (int i = 0; i < numTextures; i++)
    {
        Texture* testTexture = [self GetTexture:i];
        
        if ([[testTexture GetIdentifier] caseInsensitiveCompare:inIdentifier] == NSOrderedSame)
        {
            return testTexture;
        }
    }
    
    return NULL;

}

@end