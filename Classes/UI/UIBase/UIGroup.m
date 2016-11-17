//
//  UIGroup.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "UIGroup.h"
#import "UIObject.h"
#import "TextureAtlas.h"
#import "MeshBuilder.h"
#import "GameObjectManager.h"

#define UIGROUP_INITIAL_CAPACITY        (8)
#define TEXTURE_ATLAS_PADDING_SIZE      (2)

@implementation UIGroup

-(UIGroup*)InitWithParams:(GameObjectBatchParams*)inParams
{
    [super InitWithParams:inParams];
    
    mOrtho = TRUE;
        
    return self;
}

-(void)addObject:(UIObject*)inObject
{
    [super addObject:inObject];
}

-(UIObject*)objectAtIndex:(NSUInteger)inIndex
{
    return (UIObject*)[super objectAtIndex:inIndex];
}

-(BOOL)GroupCompleted
{
    return [super BatchCompleted];
}


@end