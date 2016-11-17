//
//  GameObjectManager.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "GameObjectManager.h"

static GameObjectManager*   sInstance = NULL;

@implementation GameObjectManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Trying to create the GameObjectManager twice");
    
    sInstance = [GameObjectManager alloc];
	[sInstance Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Trying to destroy a null GameObjectManager");
    
    [sInstance release];
    sInstance = NULL;
}

+(GameObjectManager*)GetInstance
{
    return sInstance;
}

@end
