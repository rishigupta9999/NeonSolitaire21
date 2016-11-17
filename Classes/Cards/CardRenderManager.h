//
//  CardRenderManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "TextureManager.h"
#import "Card.h"

@class GameObjectBatch;
@class GameEnvironment;
@class BigFile;

@interface CardRenderManager : NSObject
{
    float       mAspect;
    
    NSMutableArray*     mTextures;
    int                 mNumCards;
    u32                 mNumMipMapLevels;
    
    TextureAtlas*       mTextureAtlas;
    
    GameObjectBatch*    mCardBatch;
    
    GameEnvironment*    mGameEnvironment;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(CardRenderManager*)GetInstance;

-(CardRenderManager*)init;
-(void)dealloc;

-(Texture*)GetBackTexture;
-(Texture*)GetBackTextureAtIndex:(int)inIndex;

-(Texture*)GetTextureForCard:(Card*)inCard;
-(Texture*)GetXRayTextureForCard:(Card*)inCard;
-(Texture*)PreloadTextureByIndex:(int)inIndex bigFile:(BigFile*)inBigFile;

-(int)GetAssetOffsetForCard:(Card*)inCard;

-(void)AddCardEntity:(CardEntity*)inCardEntity;
-(void)RemoveCardEntity:(CardEntity*)inCardEntity;

-(GameEnvironment*)GetGameEnvironment;
-(void)SetGameEnvironment:(GameEnvironment*)inEnvironment;

@end