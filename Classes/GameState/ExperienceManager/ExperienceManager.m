//
//  ExperienceManager.m
//  Neon21
//
//  (c) 2013, Neon Games LLC
//

#import "ExperienceManager.h"
#import "SaveSystem.h"
#import "RegenerationManager.h"
#import "Event.h"
#import "GameStateMgr.h"
#import "IAPStore.h"
#import "LevelDefinitions.h"

static ExperienceManager* sInstance = NULL;

#define TIER_NUM    7

static int sScoreMultiplier         = 1000;
static int sLevelDelta[TIER_NUM]    = { 2,5,10,20,25,50,100 };
static int sLevelTiers[TIER_NUM]    = { 0,6,10,20,26,32,38  };

@implementation ExperienceManager

-(ExperienceManager*)Init
{
    mTimePlayed = 0;
    mStartTime = 0;
    
    mStreakType = STREAK_TYPE_WIN;
    mStreakLength = 0;
    
    [GetGlobalMessageChannel() AddListener:self];
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create ExperienceManager");
    sInstance = [(ExperienceManager*)[ExperienceManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to delete ExperienceManager when it is already destroyed");
    [sInstance release];
    
    [GetGlobalMessageChannel() RemoveListener:sInstance];
    [[[GameStateMgr GetInstance] GetMessageChannel] RemoveListener:sInstance];
}

+(ExperienceManager*)GetInstance
{
    return sInstance;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
}

-(int)GetXPAmountForLevel:(int)levelID
{
    int ret = sLevelDelta[TIER_NUM - 1] * sScoreMultiplier;
    
    for ( int i = 0 ; i < TIER_NUM - 1 ; i++ )
    {
        if ( levelID >= sLevelTiers[i] && levelID < sLevelTiers[i + 1] )
        {
            ret = sLevelDelta[i] * sScoreMultiplier;
            break;
        }
    }
    
    return ret;
}

-(void)GetPlayerWithLevel:(int*)outLevel WithPercent:(float*)outPercent;
{
    SaveSystem *saveFile = [ SaveSystem GetInstance ];
    
    int xp = [saveFile GetExperience];
    int nextLevelAmount = 0;
    
    // Figure out which level we are on.
    *outLevel = 0;
    
    do
    {
        (*outLevel)++;
        nextLevelAmount = [self GetXPAmountForLevel:*outLevel];
        xp -= nextLevelAmount;
    } while ( xp > 0 && *outLevel <= MAX_PLAYER_LEVEL );
    
    NSAssert(*outLevel > 0 && *outLevel <= MAX_PLAYER_LEVEL, @"Level of Player not in range");
    
    // Todo, see the leftover delta of the xp vs. the next tier.
    float toNextLevel = nextLevelAmount;
    float xpInLevel = xp * -1.0;
    *outPercent = (toNextLevel - xpInLevel) / toNextLevel;

    // Edge case: if MAX_PLAYER_LEVEL, fill to 1.0f;
    if (*outLevel >= MAX_PLAYER_LEVEL)
    {
        *outPercent = 1.0;
    }
    
   // return level;
}

-(void)AwardLevelUpPrizesFromLevel:(int)startLevel toLevel:(int)endLevel
{
#if USE_LIVES
    // set the string for what powerups the player recieved
    NSString* msg = [NSString stringWithFormat: NSLocalizedString(@"LS_Lives",NULL)];

    [UIApplication sharedApplication].statusBarOrientation = UIInterfaceOrientationLandscapeRight;
    //set and show a UI Alert notifying the player that they leveled up, and what thier rewards are
    UIAlertView* LevelUpAwards = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"LS_LevelUp", NULL)
                                                            message: msg
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"LS_OK", NULL)
                                                  otherButtonTitles: nil];
    [LevelUpAwards show];
    [[RegenerationManager GetInstance] SetNumLives_Full];
#endif
}

-(void)StartTimer
{
    mStartTime = CACurrentMediaTime();
}

-(void)StopTimer
{
    CFTimeInterval timeSpent = CACurrentMediaTime() - mStartTime;
    
    mStartTime = 0;
    
    CFTimeInterval prevTimeSpent = [[SaveSystem GetInstance] GetTimePlayed];
    [[SaveSystem GetInstance] SetTimePlayed:(timeSpent + prevTimeSpent)];
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch (inMsg->mId)
    {
        case EVENT_CONCLUSION_BROKETHEBANK:
        {
            switch(mStreakType)
            {
                case STREAK_TYPE_WIN:
                {
                    mStreakLength++;
                    break;
                }
                
                case STREAK_TYPE_LOSE:
                {
                    mStreakLength = 1;
                    mStreakType = STREAK_TYPE_WIN;
                    break;
                }
            }
            
            break;
        }
        
        case EVENT_CONCLUSION_BANKRUPT:
        {
            switch(mStreakType)
            {
                case STREAK_TYPE_WIN:
                {
                    mStreakType = STREAK_TYPE_LOSE;
                    mStreakLength = 1;
                    break;
                }
                
                case STREAK_TYPE_LOSE:
                {
                    mStreakLength++;
                    break;
                }
            }

            break;
        }
        
        case EVENT_RUN21_SCORING_COMPLETE:
        {
            if (mStreakType == STREAK_TYPE_LOSE)
            {
                LevelDefinitions* levelDefinitions = [[Flow GetInstance] GetLevelDefinitions];
                
                if ([levelDefinitions GetXrayUnlocked] || [levelDefinitions GetTornadoUnlocked])
                {
                    if (([[SaveSystem GetInstance] GetNumXrays] == 0) || ([[SaveSystem GetInstance] GetNumTornadoes] == 0))
                    {
                        if (((mStreakLength % 2) == 0) && (mStreakLength > 1))
                        {
                            [[NeonMetrics GetInstance] logEvent:@"IAPStore Force" withParameters:NULL];
                            
                            IAPStoreParams* params = [[IAPStoreParams alloc] init];
                            params.MessageString = NSLocalizedString(@"LS_LosingStreak", NULL);
                            params.StoreMode = IAPSTORE_MODE_POWERUP;
                            
                            [[GameStateMgr GetInstance] Push:[IAPStore alloc] withParams:params];
                            [params release];
                        }
                    }
                }
            }

            break;
        }
    }
}

@end