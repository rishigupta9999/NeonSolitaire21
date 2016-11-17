//
//  TextureButton.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "Button.h"
#import "UISounds.h"
#import "LocalizationManager.h"

typedef struct
{
    NSString*       mButtonTexBaseName;
    NSString*       mButtonTexHighlightedName;
	NSString*       mButtonTexDisabledName;
    NSString*       mButtonText;
    BOOL            mBoundingBoxCollision;
    Vector2         mBoundingBoxBorderSize;
    
    int             mFontSize;
    u32             mFontColor;
    u32             mFontStrokeColor;
    NeonFontType    mFontType;
    u32             mFontStrokeSize;
    
    Color           mColor;
    UIGroup*        mUIGroup;
    PlacementValue  mTextPlacement;
    
    UISoundId       mUISoundId;
} TextureButtonParams;

@interface TextureButton : Button
{
    TextureButtonParams mParams;
    Texture*            mBaseTexture;
    Texture*            mHighlightedTexture;
	Texture*            mDisabledTexture;
    Texture*            mTextTexture;
    
    u32                 mTextStartX;
    u32                 mTextStartY;
    u32                 mTextEndX;
    u32                 mTextEndY;
}

-(TextureButton*)InitWithParams:(TextureButtonParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(TextureButtonParams*)inParams;

-(void)SetText:(NSString*)inString;
-(Texture*)GetUseTexture;

-(void)DrawOrtho;

-(BOOL)HitTestWithPoint:(CGPoint*)inPoint;

-(void)StatusChanged:(UIObjectState)inState;

-(u32)GetWidth;
-(u32)GetHeight;

-(void)CalculateTextPlacement;

@end