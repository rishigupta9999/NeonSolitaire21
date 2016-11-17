//
//  RegenerationManager.h
//  Neon21
//
//  (c) 2013, Neon Games LLC
//

#define SECONDS_UNTIL_NEXT_LIVE_UNREGISTERED    3600 - 1    // 59m 59s
#define SECONDS_UNTIL_NEXT_LIVE_REGISTERED      2700        // 45m 00s
#define SECONDS_UNTIL_NEXT_LIVE_DEVELOPER       91          // 01m 31s ( Developer mode )

#define SECONDS_UNTIL_NEXT_ROOM_UNLOCK              14400       // 4 hours
#define SECONDS_UNTIL_NEXT_ROOM_UNLOCK_SHORT        7200        // 2 hours
#define SECONDS_UNTIL_NEXT_ROOM_UNLOCK_DEVELOPER    60          // 30 seconds

typedef enum
{
    ROOM_UNLOCK_STATE_IDLE,
    ROOM_UNLOCK_STATE_COUNTDOWN,
    ROOM_UNLOCK_STATE_NUM
} RoomUnlockState;

@interface RegenerationManager : NSObject<MessageChannelListener>
{
    RoomUnlockState mRoomUnlockState;
}

-(RegenerationManager*)Init;
-(void)dealloc;
-(void)Update:(CFTimeInterval)inTimeStep;

+(void)CreateInstance;
+(void)DestroyInstance;

+(RegenerationManager*)GetInstance;

-(void)ProcessMessage:(Message*)inMsg;

-(void)UpdateHealthRegen;
-(int)GetHealthRegenRate;
-(NSString*)GetHealthRegenTimeString;   // 4 or 5 characters; @"FULL" or @"MM:SS" form.

-(int)GetMaxLives;                              // Get Max Lives
-(void)SetNumLives_Full;                        // Restore all lives.
-(void)SetNumLives_LevelStart;                  // Starting a level loses a life
-(void)SetNumLives_LevelWin;                    // Reclaim life if lost in-game
-(void)SetNumLives_Regen:(int)livesRegened;     // Number of lives regened.

-(void)UpdateRoomUnlock;
-(CFTimeInterval)GetRoomUnlockTimeRemaining;
-(void)SetRoomUnlockState:(RoomUnlockState)inRoomUnlockState;
-(RoomUnlockState)GetRoomUnlockState;

-(int)GetRoomUnlockSeconds;
-(void)EvaluateBadge;

@end