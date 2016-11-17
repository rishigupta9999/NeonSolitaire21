//
//  NeonArrow.h
//  Neon21
//
//  Copyright Neon Games 2014. All rights reserved.
//

#import "UIObject.h"

typedef struct
{
    UIGroup*    mUIGroup;
    int         mLength;
} NeonArrowParams;

@interface NeonArrow : UIObject
{
    Texture*    mHeadTexture;
    Texture*    mCenterTexture;
    Texture*    mTailTexture;
    
    NeonArrowParams mParams;
}

-(NeonArrow*)initWithParams:(NeonArrowParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(NeonArrowParams*)outParams;

-(void)DrawOrtho;

@end