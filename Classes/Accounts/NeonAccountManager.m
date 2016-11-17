//
//  NeonAccountManager.m
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import <Parse/Parse.h>
#import "NeonAccountManager.h"
#import "SaveSystem.h"
#import "RegenerationManager.h"
#import "KissMetricsAPI.h"
#import "GameStateMgr.h"

#import "AdvertisingManager.h"
#import "SaveSystem.h"
#import "LevelDefinitions.h"

static NeonAccountManager* sInstance = NULL;

@implementation NeonAccountManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double create NeonAccountManager");
    sInstance = [(NeonAccountManager*)[NeonAccountManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double delete NeonAccountManager");
    [sInstance release];
}

+(NeonAccountManager*)GetInstance
{
    return sInstance;
}

-(NeonAccountManager*)Init
{
    mLock = [[NSLock alloc] init];

    [Parse setApplicationId:@"jLU2jFUuyKIZBX3kJp54n95tjtWqaHgTG9iMgXF3"
                  clientKey:@"9LrIi4hWfeDFjuJDGHE2TZjrs1jgqFSlGliTkZJm"];
    
#if (UNLOCK_LEVELS == 0)
    PFQuery *query = [PFQuery queryWithClassName:@"Redemption"];
    
    [query whereKey:@"Key" equalTo:@"UnlockAllLevels"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error)
        {
            BOOL unlockLevels = FALSE;
            
            for (PFObject *object in objects)
            {
                unlockLevels = [[object objectForKey:@"Value"] boolValue];
            }

            if (unlockLevels)
            {
                //[self performSelectorOnMainThread:@selector(UnlockAllLevels) withObject:NULL waitUntilDone:FALSE];
            }
        }
        else
        {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
#endif

    return self;
}

-(void)dealloc
{
    [mLock release];
    
    [super dealloc];
}

-(void)Lock
{
    [mLock lock];
}

-(void)Unlock
{
    [mLock unlock];
}


-(void)Update:(CFTimeInterval)inTimeStep
{
}

-(void)UnlockAllLevels
{
    [[SaveSystem GetInstance] SetMaxLevel:RUN21_LEVEL_NUM];
    [[SaveSystem GetInstance] SetMaxLevelStarted:RUN21_LEVEL_LAST];
    [[SaveSystem GetInstance] SetMaxRoomUnlocked:[NSNumber numberWithInt:LEVELSELECT_ROOM_DIAMOND]];
    
    for (int level = 0; level < RUN21_LEVEL_NUM; level++)
    {
        [[SaveSystem GetInstance] SetStarsForLevel:level withStars:1];
    }
}

@end
