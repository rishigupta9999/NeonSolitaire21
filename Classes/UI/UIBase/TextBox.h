//
//  TextBox.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.

#import "UIObject.h"
#import "Color.h"
#import "LocalizationManager.h"

@class CharMap;

typedef enum
{
    TEXTBOX_UNINITIALIZED,
    TEXTBOX_INITIALIZED
} TextBoxState;

typedef enum
{
    TEXTBOX_ALIGNMENT_LEFT,
    TEXTBOX_ALIGNMENT_CENTER
} TextBoxAlignment;

typedef struct
{
    NSString*       mString;
    NeonFontType    mFontType;
    u32             mFontSize;
    u32             mWidth;
    Color           mColor;
    u32             mStrokeSize;
    Color           mStrokeColor;
    
    int             mMaxWidth;
    int             mMaxHeight;
    BOOL            mMutable;
    
    int             mHorizontalPadding;
    
    CharMap*        mCharMap;
    float           mCharMapSpacing;
    
    TextBoxAlignment    mAlignment;
    
    UIGroup*        mUIGroup;
} TextBoxParams;

@interface TextBox : UIObject
{
    TextBoxParams   mParams;
    Texture*        mTexture;
    TextBoxState    mState;
    
    float           mScaleFactor;
    
    int             mHAlignOffset;
    int             mVAlignOffset;
}

+(void)InitDefaultParams:(TextBoxParams*)outParams;
-(void)InitFromExistingParams:(TextBoxParams*)outParams;

-(TextBox*)InitWithParams:(TextBoxParams*)inParams;
-(void)SetString:(NSString*)inString;
-(void)SetParams:(TextBoxParams*)inParams;

-(u32)GetHeight;
-(u32)GetWidth;

-(void)dealloc;
-(void)DrawOrtho;
-(void)EvaluateParams:(TextBoxParams*)inParams;

-(void)EvaluateCharMap;

-(void)SetProjected:(BOOL)inProjected;

@end