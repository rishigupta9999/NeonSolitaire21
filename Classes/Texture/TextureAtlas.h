//
//  TextureAtlas.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

@class Texture;

#define TEXTURE_ATLAS_DIMENSION_INVALID    (-1)

typedef struct
{
    u32     mPaddingSize;
} TextureAtlasParams;

typedef struct
{
    int     mX;
    int     mY;
    
    float   mSMin;
    float   mTMin;
    
    float   mSMax;
    float   mTMax;
    
    BOOL    mPlaced;
} TextureAtlasInfo;

typedef struct
{
    NSMutableArray* mPlacedTextures;        // All placed textures.  No particular order
    NSMutableArray* mScanlineEntries;       // These are sorted in ascending order by scanline
} TextureFitterContext;


@interface ScanlineEntry : NSObject
{
    @public
        int             mY;
        NSMutableArray* mTextures;          // These are sorted left to right within a scanline
}

-(void)dealloc;

@end

@interface TextureAtlasEntry : NSObject
{
    @public
        Texture*        mTexture;
}

-(TextureAtlasEntry*)Init;
-(void)SetTexture:(Texture*)inTexture;

@end

typedef enum
{
    TEXTURE_ATLAS_STATE_COMPLETE,
    TEXTURE_ATLAS_STATE_GENERATING_MIPMAPS
} TextureAtlasState;

@interface TextureAtlas : NSObject
{
    // This array is sorted by width
    NSArray* mTextureList;
    
    GLuint  mTextureObject;
    
    int     mAtlasWidth;
    int     mAtlasHeight;
    int     mAtlasPadding;
    
    BOOL    mGeneratedMipmaps;
    BOOL    mMipmapGenerationEnabled;
    
    int     mMaxDimension;
    
    BOOL    mDumpDebugImages;
    
    TextureAtlasState   mAtlasState;
    NSLock*             mLock;
}
-(TextureAtlas*)InitWithParams:(TextureAtlasParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(TextureAtlasParams*)outParams;
-(void)InitFromExistingParams:(TextureAtlasParams*)outParams;

+(void)InitTextureAtlasInfo:(TextureAtlasInfo*)outInfo;

-(void)AddTexture:(Texture*)inTexture;
-(BOOL)ContainsTexture:(Texture*)inTexture;

-(int)GetNumTextures;
-(Texture*)GetTexture:(int)inIndex;

-(void)CreateAtlas;
-(void)CreateGLTexture:(TextureFitterContext*)inContext;
-(void)Bind;
-(BOOL)AtlasCreated;

-(void)SetPaddingSize:(u32)inPaddingSize;

-(GLuint)GetTextureObject;

-(BOOL)FitIntoAtlasWithWidth:(int)width height:(int)height context:(TextureFitterContext*)inContext;
-(BOOL)PackTexture:(Texture*)inTexture context:(TextureFitterContext*)inContext;
-(BOOL)PlaceTexture:(Texture*)inTexture x:(int)inX y:(int)inY context:(TextureFitterContext*)inContext;

-(void)AddTexture:(Texture*)inTexture toScanline:(int)inY context:(TextureFitterContext*)inContext;
-(void)AddScanline:(ScanlineEntry*)inScanline context:(TextureFitterContext*)inContext;
-(void)DetermineRectAtX:(int)inX y:(int)inY width:(int*)outWidth height:(int*)outHeight context:(TextureFitterContext*)inContext;

-(void)ReinitContext:(TextureFitterContext*)context;

-(void)UpdateTexture:(Texture*)inTexture;

-(BOOL)GetGeneratedMipmaps;
-(void)SetGeneratedMipmaps:(BOOL)inGeneratedMipmaps;
-(void)SetMipmapGenerationEnabled:(BOOL)inEnable;

-(void)DumpTextureNames;
-(void)DumpScanlineInfo:(TextureFitterContext*)inContext;
-(void)DumpDebugImage:(TextureFitterContext*)inContext;
-(void)DumpTextureObject:(NSString*)inFilename;

-(void)SetDumpDebugImages:(BOOL)inDumpDebugImages;

-(void)SetAtlasState:(TextureAtlasState)inAtlasState;
-(TextureAtlasState)GetAtlasState;

-(Texture*)GetTextureWithIdentifier:(NSString*)inIdentifier;

-(u32)GetTexturePaddedWidth:(Texture*)inTexture;
-(u32)GetTexturePaddedHeight:(Texture*)inTexture;
-(u32)GetTexturePaddedMaxWidth:(Texture*)inTexture;
-(u32)GetTexturePaddedMaxHeight:(Texture*)inTexture;


@end