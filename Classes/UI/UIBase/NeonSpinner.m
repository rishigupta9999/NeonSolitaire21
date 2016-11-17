//
//  NeonSpinner.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "NeonSpinner.h"
#import "TextureManager.h"
#import "ModelManager.h"
#import "PNGTexture.h"
#import "ResourceManager.h"
#import "GameStateMgr.h"
#import "MainMenu.h"

#define DEFAULT_TILE_SIZE   (   8)
#define MIN_SCALE_VALUE         (0.25)
#define DEFAULT_COMET_SIZE      (1.0)
#define DEFAULT_COMET_DURATION  (1.0)

static const char* COMET_TEXTURE_NAME = "Comet.png";
static const char  NEONSPINNER_IDENTIFIER[] = "NeonSpinner_Image";

@implementation NeonSpinnerEntry

-(NeonSpinnerEntry*)Init
{
    mX = 0;
    mY = 0;
    
    mDistance = 0;
    mXMajor = FALSE;
    
    mScale.mVector[x] = 0;
    mScale.mVector[y] = 0;
    
    mColor[0] = 1.0;
    mColor[1] = 1.0;
    mColor[2] = 1.0;
    mColor[3] = 1.0;
    
    return self;
}

@end

@implementation NeonSpinner

-(NeonSpinner*)initWithParams:(NeonSpinnerParams*)inParams
{
    [super InitWithUIGroup:inParams->mUIGroup];

    TextureParams textureParams;
    [Texture InitDefaultParams:&textureParams];
    
    textureParams.mTexDataLifetime = TEX_DATA_DISPOSE;
    
    UIObjectTextureLoadParams params;
    [UIObject InitDefaultTextureLoadParams:&params];
    
    params.mTexDataLifetime = TEX_DATA_DISPOSE;
    params.mTextureName = [NSString stringWithUTF8String:COMET_TEXTURE_NAME];
    
    mTexture = [self LoadTextureWithParams:&params];
    [mTexture retain];
    
    mOrtho = TRUE;
    
    mWidth = 0;
    mHeight = 0;
    
    memcpy(&mParams, inParams, sizeof(NeonSpinnerParams));

    mPulsePath = [(Path*)[Path alloc] Init];
    mSpinnerEntries = [[NSMutableArray alloc] init];
    
    return self;
}

-(void)dealloc
{
    [mTexture release];
    [mPulsePath release];
    [mSpinnerEntries release];
    
    [super dealloc];
}

+(void)InitDefaultParams:(NeonSpinnerParams*)outParams
{
    outParams->mUIGroup = NULL;
    outParams->mTileSize = DEFAULT_TILE_SIZE;
    outParams->mCometSize = DEFAULT_COMET_SIZE;
    outParams->mCometDuration = DEFAULT_COMET_DURATION;
}

+(TextureAtlas*)CreateTextureAtlas
{
    TextureAtlasParams atlasParams;
    
    [TextureAtlas InitDefaultParams:&atlasParams];
    TextureAtlas* cometAtlas = [[TextureAtlas alloc] InitWithParams:&atlasParams];
    
    TextureParams params;
    
    [Texture InitDefaultParams:&params];
    
    params.mTexDataLifetime = TEX_DATA_DISPOSE;
    params.mMinFilter = GL_LINEAR;
    params.mTextureAtlas = cometAtlas;
    
    NSNumber* cometTextureHandle = [[ResourceManager GetInstance] LoadAssetWithName:[NSString stringWithUTF8String:COMET_TEXTURE_NAME]];
    NSData* cometTextureData = [[ResourceManager GetInstance] GetDataForHandle:cometTextureHandle];
    
    Texture* cometTexture = [(PNGTexture*)[PNGTexture alloc] InitWithData:cometTextureData textureParams:&params];
    
    [cometAtlas AddTexture:cometTexture];
    [cometAtlas CreateAtlas];
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:cometTextureHandle];
    
    return cometAtlas;
}

-(void)SetSizeWidth:(int)inWidth height:(int)inHeight
{
    mWidth = inWidth;
    mHeight = inHeight;
    
    [self CreateSpinnerEntries];
    
    [mPulsePath Reset];
    [mPulsePath AddNodeScalar:0 atTime:0.0f];
    [mPulsePath AddNodeScalar:(float)[mSpinnerEntries count] atTime:mParams.mCometDuration];
    
    [mPulsePath SetPeriodic:TRUE];
}

-(void)CreateSpinnerEntries
{
    [mSpinnerEntries removeAllObjects];
    
    int numWidthSegments = (mWidth + (mParams.mTileSize - 1)) / mParams.mTileSize;
    int numHeightSegments = (mHeight + (mParams.mTileSize - 1)) / mParams.mTileSize;
    
    int x = 0;
    int y = 0;
    
    NeonSpinnerEntry* curEntry = NULL;
    int curDistance = 0;
    
    for (x = 0; x < numWidthSegments; x++)
    {
        curEntry = [(NeonSpinnerEntry*)[NeonSpinnerEntry alloc] Init];
        
        curEntry->mX = x;
        curEntry->mY = y;
        
        curEntry->mXMajor = TRUE;
        
        curEntry->mDistance = curDistance++;
        
        [mSpinnerEntries addObject:curEntry];
        [curEntry release];
    }
    
    x = (numWidthSegments - 1);
    y = 0;
    
    for (y = 1; y < (numHeightSegments - 1); y++)
    {
        curEntry = [(NeonSpinnerEntry*)[NeonSpinnerEntry alloc] Init];
        
        curEntry->mX = x;
        curEntry->mY = y;
        
        curEntry->mXMajor = FALSE;
        
        curEntry->mDistance = curDistance++;
        
        [mSpinnerEntries addObject:curEntry];
        [curEntry release];
    }

    x = (numWidthSegments - 1);
    y = (numHeightSegments - 1);
    
    for (x = (numWidthSegments - 1); x >= 0; x--)
    {
        curEntry = [(NeonSpinnerEntry*)[NeonSpinnerEntry alloc] Init];
        
        curEntry->mX = x;
        curEntry->mY = y;
        
        curEntry->mXMajor = TRUE;
        
        curEntry->mDistance = curDistance++;
        
        [mSpinnerEntries addObject:curEntry];
        [curEntry release];
    }
    
    x = 0;
    y = (numHeightSegments - 1);
    
    for (y = (numHeightSegments - 2); y > 0; y--)
    {
        curEntry = [(NeonSpinnerEntry*)[NeonSpinnerEntry alloc] Init];
        
        curEntry->mX = x;
        curEntry->mY = y;
        
        curEntry->mXMajor = FALSE;
        
        curEntry->mDistance = curDistance++;
        
        [mSpinnerEntries addObject:curEntry];
        [curEntry release];
    }
    
    return;
}

-(u32)GetWidth
{
    u32 width = 0;
    
    if (mTexture != NULL)
    {
        width = [mTexture GetEffectiveWidth];
    }
    else
    {
        width = [super GetWidth];
    }
    
    return width;
}

-(u32)GetHeight
{
    u32 height = 0;
    
    if (mTexture != NULL)
    {
        height = [mTexture GetEffectiveWidth];
    }
    else
    {
        height = [super GetHeight];
    }
    
    return height;
}

-(Texture*)GetTexture
{
    return mTexture;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if ((mWidth == 0) || (mHeight == 0))
    {
        return;
    }
    
    [mPulsePath Update:inTimeStep];
    
    float location = 0;
    [mPulsePath GetValueScalar:&location];
    
    int halfDistance = [mSpinnerEntries count] / 2;
    int maxDistance = 2 * halfDistance;
    
    for (NeonSpinnerEntry* curEntry in mSpinnerEntries)
    {
        float distance = fabs(curEntry->mDistance - location);
        
        if (distance > halfDistance)
        {
            distance = fabs(maxDistance - distance);
        }
        
        float scaledDistance = distance / (float)halfDistance;
        
        float scaleVal = powf(mParams.mCometSize - (mParams.mCometSize * (distance / (float)halfDistance)), 4.0);
        
        if (scaleVal < MIN_SCALE_VALUE)
        {
            scaleVal = MIN_SCALE_VALUE;
        }
        
        if (!curEntry->mXMajor)
        {
            curEntry->mScale.mVector[x] = scaleVal;
            curEntry->mScale.mVector[y] = 1.0f;
        }
        else
        {
            curEntry->mScale.mVector[y] = scaleVal;
            curEntry->mScale.mVector[x] = 1.0f;
        }
        
        curEntry->mColor[0] = powf(scaledDistance, 0.25);
        curEntry->mColor[1] = 1.0f - powf(scaledDistance, 0.75);
        curEntry->mColor[2] = 0.0f;
        curEntry->mColor[3] = 1.0 - powf(scaledDistance, 1.5f);
    }
}

-(void)DrawOrtho
{
    BOOL useOrthoViewport = [[[GameStateMgr GetInstance] GetActiveState] class] != [MainMenu class];
    
    if (useOrthoViewport)
    {
        [self SetupViewportStart:MODELMANAGER_VIEWPORT_ORTHO end:MODELMANAGER_VIEWPORT_UI];
    }
    
    QuadParams  quadParams;
    
    [UIObject InitQuadParams:&quadParams];
    
    quadParams.mColorMultiplyEnabled = TRUE;
    quadParams.mBlendEnabled = TRUE;
    quadParams.mTexture = mTexture;
    
    quadParams.mScaleType = QUAD_PARAMS_SCALE_BOTH;
    
    for (int i = 0; i < 4; i++)
    {
        SetColorFloat(&quadParams.mColor[i], 1.0, 1.0, 1.0, mAlpha);
    }
    
    int excessSpace = ((float)mParams.mTileSize * ((1.0 - MIN_SCALE_VALUE) / 2.0f)) * 2.0;
    int numHeightSegments = (mHeight + (mParams.mTileSize - 1)) / mParams.mTileSize - 2;
    
    excessSpace += mParams.mTileSize / 4;
    
    float extraSpacePerTile = (float)excessSpace / (float)numHeightSegments;
    float yScaleAdd = 1.0 + (extraSpacePerTile / ((float)(mParams.mTileSize)));
    float modifiedTileSize = yScaleAdd * (float)mParams.mTileSize;
    
    float startY = ((float)mParams.mTileSize / 2.0) + ((MIN_SCALE_VALUE / 2.0f) * (float)mParams.mTileSize);
    
    startY -= mParams.mTileSize / 8;
    
    float rotatedTexCoords[8] = {   0, 1,
                                    1, 1,
                                    0, 0,
                                    1, 0  };
    
    for (NeonSpinnerEntry* curEntry in mSpinnerEntries)
    {
        float yOffset = [self OffsetForScale:curEntry->mScale.mVector[1]];
        float xOffset = [self OffsetForScale:curEntry->mScale.mVector[0]];
        
        if (curEntry->mXMajor)
        {
            xOffset = 0;
            quadParams.mTranslation.mVector[1] = curEntry->mY * mParams.mTileSize + yOffset;
        }
        else
        {
            quadParams.mTranslation.mVector[1] = startY + ((curEntry->mY - 1) * modifiedTileSize);
        }
        
        quadParams.mTranslation.mVector[0] = curEntry->mX * mParams.mTileSize + xOffset;
        
        quadParams.mScale.mVector[0] = curEntry->mScale.mVector[0] * mParams.mTileSize;
        quadParams.mScale.mVector[1] = curEntry->mScale.mVector[1] * mParams.mTileSize;
        
        quadParams.mTexCoordEnabled = FALSE;
        
        if (!curEntry->mXMajor)
        {
            quadParams.mScale.mVector[1] *= yScaleAdd;
            
            if (curEntry->mX == 0)
            {
                quadParams.mTranslation.mVector[0] -= ((1.0 - MIN_SCALE_VALUE) / 2.0f) * (float)mParams.mTileSize;
                quadParams.mTranslation.mVector[0] -= mParams.mTileSize / 16;
            }
            else
            {
                quadParams.mTranslation.mVector[0] += ((1.0 - MIN_SCALE_VALUE) / 2.0f) * (float)mParams.mTileSize;
                quadParams.mTranslation.mVector[0] += mParams.mTileSize / 16;
            }
            
            quadParams.mTexCoordEnabled = TRUE;
            memcpy(quadParams.mTexCoords, rotatedTexCoords, sizeof(float) * 8);
        }
        
        quadParams.mColorMultiplyEnabled = TRUE;
        
        for (int i = 0; i < 4; i++)
        {
            SetColorFloat(&quadParams.mColor[i], curEntry->mColor[0], curEntry->mColor[1], curEntry->mColor[2], curEntry->mColor[3]);
        }
        
        [self DrawQuad:&quadParams withIdentifier:[[NSString stringWithFormat:@"%s_%d", NEONSPINNER_IDENTIFIER, curEntry->mDistance] UTF8String]];
    }
    
    if (useOrthoViewport)
    {
        [self SetupViewportEnd:MODELMANAGER_VIEWPORT_UI];
    }
}

-(float)OffsetForScale:(float)inScale
{
    return (1.0f - inScale) * (mParams.mTileSize / 2);
}

@end