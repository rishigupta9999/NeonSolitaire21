//
//  UIGroup.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameObjectBatch.h"

@class UIObject;
@class TextureAtlas;
@class MeshBuilder;

@interface UIGroup : GameObjectBatch
{
}

-(UIGroup*)InitWithParams:(GameObjectBatchParams*)inParams;

-(void)addObject:(UIObject*)inObject;
-(UIObject*)objectAtIndex:(NSUInteger)inIndex;
-(BOOL)GroupCompleted;

@end