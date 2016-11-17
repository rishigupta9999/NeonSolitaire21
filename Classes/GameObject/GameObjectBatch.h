//
//  GameObjectBatch.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import "GameObject.h"

@class UIObject;
@class TextureAtlas;
@class MeshBuilder;

typedef struct
{
    BOOL    mUseAtlas;
    int     mAtlasHeightHint;
    int     mAtlasWidthHint;
} GameObjectBatchParams;

@interface GameObjectBatch : GameObject
{
    NSMutableArray*         mGameObjects;
    GameObjectBatchParams   mParams;
    TextureAtlas*           mTextureAtlas;
    MeshBuilder*            mMeshBuilder;
}

@property(readonly) BOOL finalized;

-(GameObjectBatch*)InitWithParams:(GameObjectBatchParams*)inParams;
-(void)dealloc;
+(void)InitDefaultParams:(GameObjectBatchParams*)outParams;
-(void)InitTextureAtlasWithParams:(TextureAtlasParams*)inParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)Draw;
-(void)DrawOrtho;

-(void)addObject:(GameObject*)inObject;
-(void)removeObject:(GameObject*)inObject;

-(void)removeAllObjects;
-(void)removeAllObjectsFinal:(BOOL)inFinal;
-(GameObject*)objectAtIndex:(NSUInteger)inIndex;
-(NSUInteger)count;

-(void)Finalize;

-(BOOL)BatchCompleted;

-(void)SetTextureAtlas:(TextureAtlas*)inTextureAtlas;
-(TextureAtlas*)GetTextureAtlas;

-(void)CreateMeshBuilder;

-(MeshBuilder*)GetMeshBuilder;

@end