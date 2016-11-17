//
//  NeonAccountManager.h
//
//  Copyright Neon Games 2013. All rights reserved.
//
#import "SaveSystem.h"
#import <Parse/Parse.h>

@interface NeonAccountManager : NSObject<NSURLConnectionDelegate>
{
    NSLock*             mLock;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(NeonAccountManager*)GetInstance;

-(NeonAccountManager*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)Lock;
-(void)Unlock;

-(void)UnlockAllLevels;

@end