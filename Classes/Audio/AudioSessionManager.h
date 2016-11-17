//
//  AudioSessionManager.h
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

@interface AudioSessionManager : NSObject
{
}

-(AudioSessionManager*)Init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;

+(AudioSessionManager*)GetInstance;

@end