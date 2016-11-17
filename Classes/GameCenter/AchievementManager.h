//
//  AchievementManager.h
//  Neon21
//
//  Copyright (c) 2013 Neon Games.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

typedef enum
{
    LEADERBOARD_RUN21_MARATHON,
    LEADERBOARD_NUM
} NEON_LEADERBOARD;

typedef enum
{
    ACHIEVEMENT_RUN21_BRONZE,
    ACHIEVEMENT_RUN21_SILVER,
    ACHIEVEMENT_RUN21_GOLD,
    ACHIEVEMENT_RUN21_DIAMOND,
    ACHIEVEMENT_NUM
}NEON_ACHIEVEMENT;


@interface AchievementManager : NSObject <GKGameCenterControllerDelegate>
{
    @private
        GKPlayer*                       mCurrentPlayer;
        BOOL                            bHasAuthenticated;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(AchievementManager*)GetInstance;
-(AchievementManager*)init;
-(void)dealloc;

-(void)AuthenticateLocalPlayer;
-(void)ReportScore:(int)score forLeaderboard:(NEON_LEADERBOARD)leaderboardNumber;
-(void)ReportProgress:(float)percent towardsAchievement:(NEON_ACHIEVEMENT)achievementNumber;
-(void)ReportStars:(int)numStars forLevel:(int)levelNum;
-(void)ShowLeaderboard: (NEON_LEADERBOARD)leaderboardNumber;
-(void)ShowAchievements;

-(void)PostAchievementToFacebookUsingSharedLinkWithTitleString:(NSString*)titleString withImage:(NSString*)imageString;


-(BOOL)HasAuthenticated;

@end
