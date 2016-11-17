//
//  AdvertisingManager.m
//  Neon21
//
//  (c) Neon Games LLC, 2012
//

#import "AdvertisingManager.h"
#import "InAppPurchaseManager.h"
#import "SplitTestingSystem.h"
#import "Neon21AppDelegate.h"
#import "GameStateMgr.h"
#import "CameraStateMgr.h"
#import "Event.h"
#import "Chartboost.h"
#import "LevelDefinitions.h"
#import "SaveSystem.h"

#define GAME_ORIENTATION UIInterfaceOrientationLandscapeRight

static AdvertisingManager* sInstance = NULL;

@implementation AdvertisingManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create AdvertisingManager");
    sInstance = [[AdvertisingManager alloc] init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to delete AdvertisingManager when one doesn't exist");
    [sInstance release];
}

+(AdvertisingManager*)GetInstance
{
    return sInstance;
}

-(AdvertisingManager*)init
{
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    [GetGlobalMessageChannel() AddListener:self];
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_STATE_STARTED:
        {
            GameState* activeState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
            [[activeState GetMessageChannel] AddListener:self];
            
            break;
        }

    }
}

-(BOOL)ShouldShowAds
{
    return (([[[Flow GetInstance] GetLevelDefinitions] GetJokerUnlocked]) && ([[SaveSystem GetInstance] GetNumTotalPurchases] == 0));
}

-(void)DontShowAdOnce
{
    mSkipOneAd = YES;
}

-(void)ShowAd
{
    if([self ShouldShowAds])
    {
        [[Chartboost sharedChartboost] showInterstitial];
    }
    else
    {
        mSkipOneAd = NO;
    }
}

@end