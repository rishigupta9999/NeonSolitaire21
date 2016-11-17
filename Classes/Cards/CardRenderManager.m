//
//  CardRenderManager.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "ResourceManager.h"

#import "CardRenderManager.h"
#import "BigFile.h"
#import "Card.h"
#import "Flow.h"
#import "GameObjectBatch.h"
#import "PNGTexture.h"
#import "LevelDefinitions.h"

static CardRenderManager* sInstance = NULL;
		
// Kking - Order is different in game and here.		//  T, 2, 3, 4, 5, 6, 7, 8, 9, A, J,  K,  Q,  X		-> 10 2 3 4 5 6 7 8 9 a j k q x
static int sCardLabelToLabelIndex[CardLabel_Num]	= { 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 11, 13 };

// Alphabetical Order (KK)							//  s  h  d  c    ->   c d h s 
static int sCardSuitToSuitIndex[CARDSUIT_NumSuits]	= { 3, 2, 1, 0 };

static int sFlowCasinoToFileCasinoIndex[CasinoID_Family1_Last - CasinoID_Family1_Start + 1] = { 2, 0, 1 };

#define NUM_MIPMAP_LEVELS    (1)

@implementation CardRenderManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Calling CreateInstance on CardRenderManager, but sInstance isn't NULL");
    
    sInstance = [[CardRenderManager alloc] init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Calling DestroyInstance on a NULL CardRenderManager");
    
    [sInstance release];
}

+(CardRenderManager*)GetInstance
{
    return sInstance;
}

-(CardRenderManager*)init
{
    NSNumber* cardTextureBigFile = [[ResourceManager GetInstance] LoadAssetWithName:[NSString stringWithUTF8String:"cardtextures.fag"]];
    NSNumber* cardTextureXRayBigFile = [[ResourceManager GetInstance] LoadAssetWithName:[NSString stringWithUTF8String:"cardtextures_xray.fag"]];
    
    BigFile* bigFile = [[ResourceManager GetInstance] GetBigFile:cardTextureBigFile];
    BigFile* xrayBigFile = [[ResourceManager GetInstance] GetBigFile:cardTextureXRayBigFile];
    
    TextureAtlasParams textureAtlasParams;
    [TextureAtlas InitDefaultParams:&textureAtlasParams];
    
    textureAtlasParams.mPaddingSize = 1;
    
    mTextureAtlas = [[TextureAtlas alloc] InitWithParams:&textureAtlasParams];
    
    int numFiles = [bigFile GetNumFiles];
    int numXrayFiles = [xrayBigFile GetNumFiles];
    
    NSAssert(numFiles == numXrayFiles, @"We must have an x-ray version of every card");
    
    mNumCards = numFiles;
    
    mTextures = [[NSMutableArray alloc] initWithCapacity:numFiles];
    
    for (int i = 0; i < numFiles; i++)
    {
        Texture* texture = [self PreloadTextureByIndex:i bigFile:bigFile];
        
        [mTextureAtlas AddTexture:texture];
        [mTextures addObject:texture];
        
        [texture release];
    }
    
    for (int i = 0; i < numFiles; i++)
    {
        Texture* texture = [self PreloadTextureByIndex:i bigFile:xrayBigFile];
        
        [mTextureAtlas AddTexture:texture];
        [mTextures addObject:texture];
        
        [texture release];
    }
    
    [mTextureAtlas CreateAtlas];
    
    [[self GetBackTextureAtIndex:0] SetMagFilter:GL_LINEAR minFilter:GL_LINEAR_MIPMAP_LINEAR];
    
    // Create GameObjectBatch to store all CardEntities
    GameObjectBatchParams batchParams;
    
    [GameObjectBatch InitDefaultParams:&batchParams];
    
    mCardBatch = [[GameObjectBatch alloc] InitWithParams:&batchParams];
    
    [mCardBatch SetTextureAtlas:mTextureAtlas];
    [mTextureAtlas release];
    
    [[GameObjectManager GetInstance] Add:mCardBatch withRenderBin:RENDERBIN_CARDS];
    [mCardBatch release];
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:cardTextureBigFile];
    [[ResourceManager GetInstance] UnloadAssetWithHandle:cardTextureXRayBigFile];

    return self;
}

-(void)dealloc
{
    [mTextures release];
    [mTextureAtlas release];
    
    [[GameObjectManager GetInstance] Remove:mCardBatch];
    [mGameEnvironment release];
    
    [super dealloc];
}

-(Texture*)GetBackTexture
{
    CasinoID casinoId = [[Flow GetInstance] GetCasinoId];
    return [mTextures objectAtIndex:sFlowCasinoToFileCasinoIndex[(casinoId - CasinoID_Family1_Start)]];
}

-(Texture*)GetBackTextureAtIndex:(int)inIndex
{
    return [mTextures objectAtIndex:0];
}

-(Texture*)GetTextureForCard:(Card*)inCard
{
    int assetOffset = [self GetAssetOffsetForCard:inCard];
    return [mTextures objectAtIndex:assetOffset];
}

-(Texture*)GetXRayTextureForCard:(Card*)inCard
{
    int assetOffset = [self GetAssetOffsetForCard:inCard];
    assetOffset += mNumCards;
    
    return [mTextures objectAtIndex:assetOffset];
}

-(Texture*)PreloadTextureByIndex:(int)inIndex bigFile:(BigFile*)inBigFile
{
    NSData* textureData = [inBigFile GetFileAtIndex:inIndex];
    NSAssert(textureData != NULL, @"No corresponding texture was found in the card texture bigfile\n");
    
    TextureParams params;
    
    [Texture InitDefaultParams:&params];
    
    params.mTexDataLifetime = TEX_DATA_DISPOSE;
    params.mMinFilter = GL_LINEAR;
    params.mTextureAtlas = mTextureAtlas;
        
    Texture* texture = [(PNGTexture*)[PNGTexture alloc] InitWithData:textureData textureParams:&params];
    
    NSString* debugName = [NSString stringWithFormat:@"%d", inIndex];
    [texture SetIdentifier:debugName];
    
    return texture;
}

-(int)GetAssetOffsetForCard:(Card*)inCard
{
    int assetOffset = (sCardSuitToSuitIndex[[inCard GetSuit]] * (CardLabel_Num - 1)) + (sCardLabelToLabelIndex[[inCard GetLabel]]);
    
	if ( [inCard GetLabel ] == CardLabel_Joker )
	{
		// Offset for Jokers is done by rank first, while cards are done in suit first
		assetOffset = CardLabel_Joker * CARDSUIT_NumSuits + [inCard GetSuit]; 
	}
	
    assetOffset += (CasinoID_Family1_Last - CasinoID_Family1_Start + 1);

    return assetOffset;
}

-(void)AddCardEntity:(CardEntity*)inCardEntity
{
    [mCardBatch addObject:inCardEntity];
}

-(void)RemoveCardEntity:(CardEntity*)inCardEntity
{
    [mCardBatch removeObject:inCardEntity];
}

-(GameEnvironment*)GetGameEnvironment
{
    return mGameEnvironment;
}

-(void)SetGameEnvironment:(GameEnvironment*)inEnvironment
{
    [mGameEnvironment release];
    mGameEnvironment = inEnvironment;
    [mGameEnvironment retain];
}
    
@end