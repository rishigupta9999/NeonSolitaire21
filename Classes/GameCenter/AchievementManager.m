//
//  AchievementManager.m
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#if !NEON_SOLITAIRE_21

#import "AchievementManager.h"
#import "Chartboost.h"
#import "SaveSystem.h"
#import <FacebookSDK/FacebookSDK.h>
#import "NeonAccountManager.h"
#import "AdvertisingManager.h"
#import "Flow.h"
#import "GameStateMgr.h"
#import "FacebookLoginMenu.h"
#import "SplitTestingSystem.h"

#define GAME_ORIENTATION UIInterfaceOrientationLandscapeRight


static NSString* leaderboardIDs[LEADERBOARD_NUM] = {    @"com.neongames.NeonRun21Free.Marathon" };  // LEADERBOARD_RUN21_MARATHON

static NSString* achievementIDs[ACHIEVEMENT_NUM] = {    @"com.neongames.NeonRun21Free.BronzeStar",    // ACHIEVEMENT_RUN21_BRONZE
                                                        @"com.neongames.NeonRun21Free.SilverStar",    // ACHIEVEMENT_RUN21_SILVER
                                                        @"com.neongames.NeonRun21Free.GoldStar",      // ACHIEVEMENT_RUN21_GOLD
                                                        @"com.neongames.NeonRun21Free.DiamondStar"};  // ACHIEVEMENT_RUN21_DIAMOND
#if FACEBOOK_POST_ACHIEVEMENTS

static NSString* sAchievementNames[ACHIEVEMENT_NUM] = { @"LS_BronzeAchievement",
                                                        @"LS_SilverAchievement",
                                                        @"LS_GoldAchievement",
                                                        @"LS_DiamondAchievement",
};

static NSString* sAcheivementImageLocation = @"http://neongames.us/fb/achievements/";
static NSString* sAcheivementImageNames[ACHIEVEMENT_NUM] = {    @"Achievement_Bronze.png",
                                                                @"Achievement_Silver.png",
                                                                @"Achievement_Gold.png",
                                                                @"Achievement_Diamond.png",
};

#endif
static NSString* sStarAchievementIDBaseString =  @"com.neongames.NeonRun21Free.Level%dStars%d";

static AchievementManager* sInstance = NULL;

@implementation AchievementManager

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create AchievementManager");
    sInstance = [[AchievementManager alloc] init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to delete AchievementManager when one doesn't exist");
    [sInstance release];
}

+(AchievementManager*)GetInstance
{
    return sInstance;
}

-(AchievementManager*)init
{
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(void)AuthenticateLocalPlayer
{

    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    NSLog(@"Game Center ID: %@",localPlayer.playerID);
    //wait until the local player is authenticated to show the ad
    
    BOOL blockAd = [[SplitTestingSystem GetInstance] GetFirstLaunch];
    
    if (!blockAd)
    {
        [[AdvertisingManager GetInstance] WaitToShowAdWithReason:ADLOCK_GameCenter];
    }
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error)
    {
        if (viewController != nil)
        {
          [ [UIApplication sharedApplication].keyWindow.rootViewController presentViewController: viewController animated: YES completion:nil];
        }
        else
        {
            if (localPlayer.isAuthenticated)
            {
                mCurrentPlayer = localPlayer;
            }
            else
            {
                mCurrentPlayer = NULL;
            }
            
            // Don't show ads on Facebook login screen
            if ([[[GameStateMgr GetInstance] GetActiveStateAfterOperations] class] == [FacebookLoginMenu class])
            {
                return;
            }
            
            if (!blockAd)
            {
                [[AdvertisingManager GetInstance] ShowAdWithReason:ADLOCK_GameCenter];
            }
        }
    };
}

-(void)ReportScore:(int)score forLeaderboard:(NEON_LEADERBOARD)leaderboardNumber
{
    //if there isn't a player logged in, we should not report any score, early return
    if (mCurrentPlayer == NULL)
    {
        return;
    }
    // Create the scoreReporter and set the relevant fields
    GKScore *scoreReporter = [[GKScore alloc] initWithCategory:leaderboardIDs[leaderboardNumber]];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    //Send the scoreReporter to the game center
    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"Error in reporting score: %@", error);
         }
     }];
}

-(void)ReportProgress:(float)percent towardsAchievement:(NEON_ACHIEVEMENT)achievementNumber
{
#if FACEBOOK_POST_ACHIEVEMENTS
    if([FBSession activeSession].isOpen && percent >= 100.0)
    {
        if([[NeonAccountManager GetInstance] GetAllowFacebookAchievements] == FACEBOOK_ACHIEVEMENTS_ALLOW)
        {
            NSString* titleString = NSLocalizedString(sAchievementNames[achievementNumber],NULL);
            NSString* imageString = [sAcheivementImageLocation stringByAppendingString:sAcheivementImageNames[achievementNumber]];
            [self PostAchievementToFacebookUsingSharedLinkWithTitleString: titleString withImage:imageString];
        }
    }
#endif
    //if there isn't a player logged in, we should not report any score, early return
    if(mCurrentPlayer == NULL)
    {
        return;
    }
    
    // create the progressReporter request and set relevent fields
    GKAchievement *progressReporter = [[GKAchievement alloc] initWithIdentifier: achievementIDs[achievementNumber]];
    progressReporter.percentComplete = percent;
    progressReporter.showsCompletionBanner = TRUE;
    
    //send the progressReporter to the Game Center
    [progressReporter reportAchievementWithCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"Error in reporting achievements: %@", error);
         }
     }];
    

}

-(void)ReportStars:(int)numStars forLevel:(int)levelNum
{
    NSString* starString;
    NSString* achievementTitle;
    
    if (numStars == 1)
    {
        starString = NSLocalizedString(@"LS_Star",NULL);
    }
    else
    {
        starString = NSLocalizedString(@"LS_Stars",NULL);
    }
    
    achievementTitle = [NSString stringWithFormat:NSLocalizedString(@"LS_StarAchievement",NULL),numStars, starString,levelNum ];

#if FACEBOOK_POST_ACHIEVEMENTS
    if([FBSession activeSession].isOpen)
    {
        if([[NeonAccountManager GetInstance] GetAllowFacebookAchievements] == FACEBOOK_ACHIEVEMENTS_ALLOW)
        {
            NSString *imageString = nil;
            switch([[Flow GetInstance] GetRoomStarForLevel: Tutorial_Run21_HowToPlay +  levelNum])
            {
                case STAR_BRONZE:
                    imageString = [sAcheivementImageLocation stringByAppendingString:sAcheivementImageNames[ACHIEVEMENT_RUN21_BRONZE]];
                    break;
                case STAR_SILVER:
                    imageString = [sAcheivementImageLocation stringByAppendingString:sAcheivementImageNames[ACHIEVEMENT_RUN21_SILVER]];
                    break;
                case STAR_GOLD:
                    imageString = [sAcheivementImageLocation stringByAppendingString:sAcheivementImageNames[ACHIEVEMENT_RUN21_GOLD]];
                    break;
                case STAR_SHOOTING:
                    imageString = [sAcheivementImageLocation stringByAppendingString:sAcheivementImageNames[ACHIEVEMENT_RUN21_DIAMOND]];
                    break;
                default:
                    NSAssert(FALSE,@"unknown room number for star");
                    
            }
            [self PostAchievementToFacebookUsingSharedLinkWithTitleString:achievementTitle withImage:imageString];
        }
    }
#endif
    
    //if there isn't a player logged in, we should not report any score, early return
    if(mCurrentPlayer == NULL)
    {
        return;
    }
    
    //We need to give achievement for all the stars up to the number of stars they earned
    for (int i = 1; i <= numStars; i ++)
    {
        GKAchievement *progressReporter = [[GKAchievement alloc] initWithIdentifier: [NSString stringWithFormat:sStarAchievementIDBaseString,levelNum,i ]];
        progressReporter.percentComplete = 100;
        progressReporter.showsCompletionBanner = i==numStars;
        
        //send the progressReporter to the Game Center
        [progressReporter reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 NSLog(@"Error in reporting achievements: %@", error);
             }
         }];
    }

    
    

}
- (void)ShowLeaderboard: (NEON_LEADERBOARD)leaderboardNumber
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        gameCenterController.leaderboardTimeScope = GKLeaderboardTimeScopeToday;
        gameCenterController.leaderboardCategory = leaderboardIDs[leaderboardNumber];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController: gameCenterController animated: YES completion:nil];
    }
}

- (void)ShowAchievements
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;
        [ [UIApplication sharedApplication].keyWindow.rootViewController presentViewController: gameCenterController animated: YES completion:nil];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)HasAuthenticated
{
    return bHasAuthenticated;
}

-(void)PostAchievementToFacebookUsingOpenGraphWithIDString:(NSString*)idString
{
    NeonAccountManager* accountMan = [NeonAccountManager GetInstance];
    if([accountMan GetLoginStatus] == FACEBOOK_LOGIN_STATUS_LOGGED_IN)
    {
        [accountMan FB_RequestWritePermissions];
        
        NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys: idString, @"achievement", nil];
        //TODO: Figure out what the users id number is
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%llu/achievements", (long long unsigned int)1] parameters:params HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {}];
    }
}

-(void)PostAchievementToFacebookUsingSharedLinkWithTitleString:(NSString*)titleString withImage:(NSString*)imageString
{
    NSString* GetAchievementString = [NSString stringWithFormat:NSLocalizedString(@"LS_AchievementGet",NULL), NSLocalizedString(@"LS_AppStore_Title_A" , NULL) ];
    
    NSMutableDictionary* postParams = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
     @"https://www.facebook.com/SolitaireVsBlackjackCommunity", @"link",
     imageString, @"picture",
     GetAchievementString, @"name",
     titleString, @"description",
     nil];
    
    [[NeonAccountManager GetInstance] FB_PublishStoryWithParameters:postParams];
    
    
}

@end

#endif