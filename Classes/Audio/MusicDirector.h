//
//  MusicDirector.h
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "MessageChannel.h"
#import "MenuFlowTypes.h"
#import "NeonMusicPlayer.h"
#import "Flow.h"

typedef enum
{
    MUSIC_DIRECTOR_STATE_AWAITING_COMMANDS,
    MUSIC_DIRECTOR_STATE_PENDING_START,
} MusicDirectorState;

@interface MusicDirector : NSObject<MessageChannelListener>
{
    GameModeType        mLastGameMode;
    int                 mLastLevel;
    
    MusicDirectorState  mState;
    int                 mNumPendingFrames;
    MusicPlayerParams   mPendingParams;
}

-(MusicDirector*)Init;
+(void)CreateInstance;
+(void)DestroyInstance;
+(MusicDirector*)GetInstance;

-(void)ProcessMessage:(Message*)inMsg;
-(void)Update:(CFTimeInterval)inTimeStep;

-(void)EvaluateMusicForState:(BOOL)inForceEvaluate;

@end