//
//  Texture.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "TextureAtlas.h"

typedef enum
{
    TEX_DATA_RETAIN,
    TEX_DATA_DISPOSE
} TexDataLifetime;

typedef enum
{
    TEXTURE_STATUS_UNINITIALIZED,
    TEXTURE_STATUS_DECODING,
    TEXTURE_STATUS_DECODING_COMPLETE,
    TEXTURE_STATUS_COMPLETE,
} TextureStatus;

typedef struct
{
    TexDataLifetime mTexDataLifetime;
    TextureAtlas*   mTextureAtlas;
    GLenum          mMagFilter;
    GLenum          mMinFilter;
    s32             mMaxLevel;
} TextureParams;

@interface Texture : NSObject
{
    @public
        u32             mTexName;
        u8*             mTexBytes;
        int             mFileLength;
                                
        GLenum          mFormat;
        GLenum          mType;
        
        BOOL            mPremultipliedAlpha;
        
        TextureParams   mParams;
        
        TextureAtlasInfo   mTextureAtlasInfo;
        
        u8**           mSrcMipMapTexBytes;
        u8**           mMipMapTexBytes;
    
    @protected
        // If a texture's contents can be respecified later, then these will indicate
        // the maximum dimensions.  Otherwise these will remain at 0 (meaning the fields
        // are to be ignored).
        
        u32			mMaxHeight;
        u32			mMaxWidth;
		
		u32			mHeight;
        u32			mWidth;
		
		u32			mGLHeight;
        u32			mGLWidth;
        
        BOOL		mGeneratedMipmaps;
        
        NSString*	mIdentifier;
		
		// If a retina display version of the asset is loaded, this will be 2.0.  Otherwise 1.0
		float		mScaleFactor;
    
        TextureStatus   mTextureStatus;
        NSLock*         mLock;
}

-(Texture*)Init;
+(void)InitDefaultParams:(TextureParams*)outParams;
+(void)RoundToValidDimensionsWidth:(u32)inWidth Height:(u32)inHeight ValidWidth:(u32*)outWidth ValidHeight:(u32*)outHeight;

-(void)dealloc;
-(void)FreeMipMapLayers;

-(void)Bind;
+(void)Unbind;
-(void)CreateGLTexture;

-(Texture*)InitWithBytes:(unsigned char*)inBytes bufferSize:(u32)inBufferSize textureParams:(TextureParams*)inParams;
-(Texture*)InitWithData:(NSData*)inData textureParams:(TextureParams*)inParams;
-(Texture*)InitWithMipMapData:(NSMutableArray*)inData textureParams:(TextureParams*)inParams;

-(u32)GetRealWidth;
-(u32)GetRealHeight;
-(u32)GetEffectiveWidth;
-(u32)GetEffectiveHeight;
-(u32)GetGLWidth;
-(u32)GetGLHeight;

-(void)SetRealWidth:(u32)inWidth;
-(void)SetRealHeight:(u32)inHeight;

-(void)VerifyDimensions;

-(u8*)PadTextureData:(u8*)inTexData srcWidth:(u32)inSrcWidth srcHeight:(u32)inSrcHeight destWidth:(u32)inDestWidth destHeight:(u32)inDestHeight;

-(u32)GetSizeBytes;

-(u32)GetTexel:(CGPoint*)inPoint;
-(void)FreeClientData;

-(void)WritePPM:(NSString*)inFileName;

-(void)SetMaxWidth:(u32)inWidth;
-(u32)GetMaxWidth;

-(void)SetMaxHeight:(u32)inHeight;
-(u32)GetMaxHeight;

-(void)SetMipMapData:(u8*)inData level:(u32)inLevel;

-(void)SetMagFilter:(GLenum)inMagFilter minFilter:(GLenum)inMinFilter;
-(void)SetWrapModeS:(GLenum)s T:(GLenum)t;

-(u32)GetNumMipMapLevels;
-(u32)GetNumSrcMipMapLevels;
-(u32)GetTextureLayerIndexForMipMapLevel:(u32)inMipMapLevel;

-(NSString*)GetIdentifier;
-(void)SetIdentifier:(NSString*)inString;

-(void)SetScaleFactor:(float)inScaleFactor;
-(float)GetScaleFactor;

-(void)SetStatus:(TextureStatus)inStatus;
-(TextureStatus)GetStatus;

@end