//
//  AdvertisingManager.h
//  Neon21
//
//  Copyright Neon Games 2012. All rights reserved.
//
#import "TextureManager.h"
#import "JPEGTexture.h"

@protocol AdvertisingManagerListener

-(void)AdvertisingManagerRequestComplete:(BOOL)success;

@end

@interface AdvertisingManager : NSObject<MessageChannelListener>
{
    BOOL    mSkipOneAd;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(AdvertisingManager*)GetInstance;
-(AdvertisingManager*)init;
-(void)dealloc;
-(void)Update:(CFTimeInterval)inTimeInterval;
-(void)ProcessMessage:(Message*)inMsg;

-(BOOL)ShouldShowAds;
-(void)DontShowAdOnce;

-(void)ShowAd;


@end