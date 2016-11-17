//
//  AnimatedButton.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.

#import "UIObject.h"

typedef enum
{
    ANIMATED_ICON_LOOP_REPEAT,
    ANIMATED_ICON_LOOP_PING_PONG
} AnimatedIconLoopType;

typedef enum
{
    ANIMATED_ICON_LOOP_DIRECTION_FORWARD,
    ANIMATED_ICON_LOOP_DIRECTION_BACKWARD
} AnimatedIconLoopDirection;

typedef struct
{   
    NSString*               mTextureBigFileName;
    CFTimeInterval          mTimePerFrame;
    UIGroup*                mUIGroup;
    AnimatedIconLoopType    mLoopType;
} AnimatedIconParams;

@interface AnimatedIcon : UIObject
{
    AnimatedIconParams      mParams;
    NSMutableArray*         mTextures;
    CFTimeInterval          mTime;
    
    AnimatedIconLoopDirection   mLoopDirection;
}

-(AnimatedIcon*)InitWithParams:(AnimatedIconParams*)inParams;
-(void)dealloc;

+(void)InitDefaultParams:(AnimatedIconParams*)outParams;
-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(u32)GetWidth;
-(u32)GetHeight;

-(void)GetSrcTexture:(Texture**)outSrcTexture destTexture:(Texture**)outDestTexture srcBlend:(float*)outSrcBlend destBlend:(float*)outDestBlend;

@end