//
//  ImageWell.h
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.

#import "UIObject.h"

typedef struct
{
    NSString*  mTextureName;
    Texture*   mTexture;
    UIGroup*   mUIGroup;
} ImageWellParams;

@interface ImageWell : UIObject
{
    Texture*            mTexture;
}

-(ImageWell*)InitWithParams:(ImageWellParams*)inParams;
-(ImageWell*)InitWithImageWell:(ImageWell*)inImageWell;
-(void)dealloc;
+(void)InitDefaultParams:(ImageWellParams*)outParams;

-(void)DrawOrtho;

-(Texture*)GetTexture;

@end