//
//  CardEntity.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameObjectManager.h"
#import "TextureManager.h"

@class Card;

typedef enum
{
    CARDENTITYMODE_NORMAL,
    CARDENTITYMODE_XRAY
} CardEntityMode;

@class PlayerHand;

@interface CardEntity : GameObject
{
    @public
        Card*       mCard;
        Texture*    mTexture;
        PlayerHand* mParentHand;
        
        float       mAspect;
}

@property(readonly) CardEntityMode cardEntityMode;

-(CardEntity*)InitWithCard:(Card*)inCard;

-(void)Remove;
-(void)Reset;

-(void)Draw;
-(void)SetVisible:(BOOL)inVisible;

-(void)dealloc;

+(void)GetLocalToWorldTransform:(Matrix44*)outLTWTransform;

-(void)SetupRenderState:(RenderStateParams*)inParams;
-(void)TeardownRenderState:(RenderStateParams*)inParams;

-(void)UpdateCardMode;

@end