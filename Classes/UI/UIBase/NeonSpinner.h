//
//  NeonSpinner.h
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "UIObject.h"

typedef struct
{
    UIGroup*        mUIGroup;
    int             mTileSize;
    float           mCometSize;
    float           mCometDuration;
} NeonSpinnerParams;

@interface NeonSpinnerEntry : NSObject
{
    @public
        int mX;
        int mY;
        int mDistance;
    
        BOOL mXMajor;
        
        Vector2 mScale;
        float   mColor[4];
}

-(NeonSpinnerEntry*)Init;

@end

@interface NeonSpinner : UIObject
{
    NeonSpinnerParams   mParams;
    Texture*            mTexture;
    
    int                 mWidth;
    int                 mHeight;
    
    Path*               mPulsePath;
    NSMutableArray*     mSpinnerEntries;
}

-(NeonSpinner*)initWithParams:(NeonSpinnerParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(NeonSpinnerParams*)outParams;

+(TextureAtlas*)CreateTextureAtlas;

-(void)SetSizeWidth:(int)inWidth height:(int)inHeight;
-(void)CreateSpinnerEntries;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(float)OffsetForScale:(float)inScale;

@end