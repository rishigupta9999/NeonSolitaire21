//
//  NeonChartboostDelegate.m
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "NeonChartboostDelegate.h"
#import "InAppPurchaseManager.h"
#import "AchievementManager.h"
#import "SaveSystem.h"
#import "GameStateMgr.h"
#import "CameraStateMgr.h"

@implementation NeonChartboostDelegate

-(NeonChartboostDelegate*)Init
{
    [GetGlobalMessageChannel() AddListener:self];
    
    [Chartboost sharedChartboost].delegate = self;
    [self StartSession];
    
    return self;
}

-(void)StartSession
{
    Chartboost *cb  = [Chartboost sharedChartboost];
    
    // Test Chartboost's Campaign.
#if ADS_CBOOST_PRODUCTION
    cb.appId        = @"532a7f8e9ddc354e1e2c3ca0";
    cb.appSignature = @"fd6213288aa56457e9bc3051ec7e6daba20d9740";
    
    NSLog(@"Neon Chartboost SKU: Solitaire 21");
#else
    cb.appId        = @"4f21c409cd1cb2fb7000001b";
    cb.appSignature = @"92e2de2fd7070327bdeb54c15a5295309c6fcd2d";
    NSLog(@"Neon Chartboost SKU: Chartboost TEST App");
#endif
    
    cb.delegate     = self;
    [cb startSession];
    
    [cb cacheInterstitial];
    
    AdLog(@"Chartboost startSession with\n\
App Id#: %@\n\
App Sig: %@",cb.appId,cb.appSignature);

    mAdClicked = FALSE;
}

- (BOOL)shouldRequestInterstitial:(NSString *)location
{
    AdLog(@"%@", location);
    return TRUE;
}

- (BOOL)shouldRequestInterstitialsInFirstSession:(NSString *)location
{
    AdLog(@"%@", location);
    return FALSE;
}

// Called when an interstitial has been received, before it is presented on screen
// Return NO if showing an interstitial is currently innapropriate, for example if the user has entered the main game mode.
- (BOOL)shouldDisplayInterstitial:(NSString *)location
{
    [[GameStateMgr GetInstance] PauseProcessing];
    [[[CameraStateMgr GetInstance] GetStateMachine] PauseProcessing];

    return TRUE;
}

// Called when an interstitial has been received and cached.
- (void)didCacheInterstitial:(NSString *)location
{
    AdLog(@"%@", location);
}

// Called when an interstitial has failed to come back from the server
- (void)didFailToLoadInterstitial:(NSString *)location
{
    AdLog(@"%@", location);
}

// Called when the user dismisses the interstitial
// If you are displaying the add yourself, dismiss it now.
- (void)didDismissInterstitial:(NSString *)location
{
    [[GameStateMgr GetInstance] ResumeProcessing];
    [[[CameraStateMgr GetInstance] GetStateMachine] ResumeProcessing];
    
    [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;

#if ADS_CBOOST_INTERSTITIALS && ADVERTISING_CACHE_INTERSTITIALS
    [[Chartboost sharedChartboost] cacheInterstitial];
#endif
}

// Same as above, but only called when dismissed for a close
- (void)didCloseInterstitial:(NSString *)location
{
    AdLog(@"%@", location);
}

// Same as above, but only called when dismissed for a click
- (void)didClickInterstitial:(NSString *)location
{
    [[NeonMetrics GetInstance] logEvent:@"Clicked On Ad" withParameters:NULL];
    
    mAdClicked = TRUE;
}

-(void)SetAdClicked:(BOOL)inClicked
{
    mAdClicked = inClicked;
}

-(BOOL)GetAdClicked
{
    return mAdClicked;
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch (inMsg->mId)
    {
        case EVENT_APPLICATION_RESUMED:
        {
            [self StartSession];
            break;
        }
    }
}

@end