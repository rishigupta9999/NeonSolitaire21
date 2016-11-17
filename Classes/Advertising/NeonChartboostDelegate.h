//
//  NeonChartboostDelegate.h
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import "Chartboost.h"

@interface NeonChartboostDelegate : NSObject<ChartboostDelegate, MessageChannelListener>
{
    BOOL    mAdClicked;
}

-(NeonChartboostDelegate*)Init;
-(void)StartSession;

- (BOOL)shouldRequestInterstitial:(NSString *)location;
- (BOOL)shouldRequestInterstitialsInFirstSession:(NSString *)location;
- (BOOL)shouldDisplayInterstitial:(NSString *)location;
- (void)didCacheInterstitial:(NSString *)location;
- (void)didFailToLoadInterstitial:(NSString *)location;
- (void)didDismissInterstitial:(NSString *)location;
- (void)didCloseInterstitial:(NSString *)location;
- (void)didClickInterstitial:(NSString *)location;

-(void)SetAdClicked:(BOOL)inClicked;
-(BOOL)GetAdClicked;

-(void)ProcessMessage:(Message*)inMsg;

@end