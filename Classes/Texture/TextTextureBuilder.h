//
//  TextTextureBuilder.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import <CoreText/CoreText.h>

#import "Texture.h"
#import "ResourceManager.h"
#import "LocalizationManager.h"

#include "ft2build.h"
#include "freetype.h"

#include "Color.h"

@class TextureAtlas;

typedef struct
{
    // Input
    NeonFontType    mFontType;
    NSString*       mFontName;
    NSString*       mSystemFontName;
    
    u32             mPointSize;
    NSString*       mString;
    u32             mColor;
    u32             mStrokeColor;
    u32             mWidth;
    u32             mLeadWidth;
    u32             mLeadHeight;
    u32             mTrailWidth;
    u32             mTrailHeight;
    u32             mStrokeSize;    // That's what she said
    BOOL            mPremultipliedAlpha;
    TextureAtlas*   mTextureAtlas;
    Texture*        mTexture;
    CTTextAlignment mAlignment;
    
    // Output
    u32             mStartX;
    u32             mStartY;
    u32             mEndX;
    u32             mEndY;
} TextTextureParams;


@interface TextTextureBuilder : NSObject
{
    @public
        FT_Library mLibrary;
        
        NSMutableArray* mFontNodes;    
        CGColorSpaceRef mColorSpaceRef;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(TextTextureBuilder*)GetInstance;

-(TextTextureBuilder*)Init;
-(void)dealloc;

+(void)InitDefaultParams:(TextTextureParams*)outParams;

-(CGFontRef)FindFont:(NSString*)inName traits:(int)inTraits;
-(void)PreloadFonts;

-(Texture*)GenerateTextureWithFont:(NSString*)inFontName PointSize:(u32)inPointSize String:(NSString*)inString Color:(u32)inColor;
-(Texture*)GenerateTextureWithFont:(NSString*)inFontName PointSize:(u32)inPointSize String:(NSString*)inString Color:(u32)inColor Width:(u32)inWidth;
-(Texture*)GenerateTextureWithParams:(TextTextureParams*)inParams;

-(BOOL)SupportsCoreGraphicsGeneration:(TextTextureParams*)inParams;
-(BOOL)RenderWithParams_CoreGraphics:(TextTextureParams*)inParams texture:(Texture*)inTexture;

-(void)ApplyAttribute:(CFStringRef)inAttribute spans:(NSMutableArray*)inSpans params:(TextTextureParams*)inParams strippedString:inStrippedString attrString:(CFMutableAttributedStringRef)inAttrString;

-(NSMutableArray*)GenerateTextSpans:(TextTextureParams*)inParams strippedString:(NSString**)outStrippedString;
-(CGSize)MeasureFrame:(CTFrameRef)frame startX:(u32*)outStartX startY:(u32*)outStartY endX:(u32*)outEndX endY:(u32*)outEndY;

-(CGColorRef)ColorRefFromU32:(u32)inColorVal;

@end
