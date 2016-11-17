//
//  ExperienceManager.h
//  Neon21
//
//  (c) 2013, Neon Games LLC
//
#define MAX_PLAYER_LEVEL    40

typedef enum
{
    STREAK_TYPE_WIN,
    STREAK_TYPE_LOSE
} StreakType;

@interface ExperienceManager : NSObject<MessageChannelListener>
{
    CFTimeInterval  mTimePlayed;
    CFTimeInterval  mStartTime;
    
    StreakType      mStreakType;
    int             mStreakLength;
}

-(ExperienceManager*)Init;
-(void)dealloc;
-(void)Update:(CFTimeInterval)inTimeStep;

+(void)CreateInstance;
+(void)DestroyInstance;

+(ExperienceManager*)GetInstance;

-(void)GetPlayerWithLevel:(int*)outLevel WithPercent:(float*)outPercent;
-(void)AwardLevelUpPrizesFromLevel:(int)startLevel toLevel:(int)endLevel;

-(void)StartTimer;
-(void)StopTimer;

-(void)ProcessMessage:(Message*)inMsg;

@end