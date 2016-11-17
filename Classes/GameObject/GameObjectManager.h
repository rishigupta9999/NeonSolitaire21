//
//  GameObjectManager.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameObjectCollection.h"

@interface GameObjectManager : GameObjectCollection
{
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(GameObjectManager*)GetInstance;

@end
