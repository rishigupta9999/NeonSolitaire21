//
//  MusicDirector.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "MusicDirector.h"
#import "GameStateMgr.h"
#import "LevelDefinitions.h"

static MusicDirector* sInstance = NULL;
static const int MUSIC_DIRECTOR_NUM_DELAY_FRAMES = 3;

@implementation MusicDirector

-(MusicDirector*)Init
{
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    [GetGlobalMessageChannel() AddListener:self];
    
    mLastLevel = LEVEL_INDEX_INVALID;
    mLastGameMode = GAMEMODE_TYPE_INVALID;
    
    mState = MUSIC_DIRECTOR_STATE_AWAITING_COMMANDS;
    mNumPendingFrames = 0;
    
    memset(&mPendingParams, 0, sizeof(mPendingParams));
    
    return self;
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create MusicDirector");
    sInstance = [(MusicDirector*)[MusicDirector alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double-delete MusicDirector");
    
    [[[GameStateMgr GetInstance] GetMessageChannel] RemoveListener:(NSObject<MessageChannelListener>*)self];
    [GetGlobalMessageChannel() RemoveListener:(NSObject<MessageChannelListener>*)self];
    
    [sInstance release];
    sInstance = NULL;
}

+(MusicDirector*)GetInstance
{
    return sInstance;
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_STATE_STARTED:
        {
            [self EvaluateMusicForState:TRUE];
            break;
        }
        
        case EVENT_STATE_RESUMED:
        {
            [self EvaluateMusicForState:FALSE];
            break;
        }
        
        case EVENT_MAIN_MENU_PENDING_TERMINATE:
        {
            [[NeonMusicPlayer GetInstance] Stop:0.5f];
            break;
        }
        
        case EVENT_RUN21_SCORING_COMPLETE:
        {
            if ( [[Flow GetInstance] GetGameMode] != GAMEMODE_TYPE_RUN21_MARATHON)
            {
                [[NeonMusicPlayer GetInstance] Stop:0.5f];
            }
            break;
        }
        
        case EVENT_MUSIC_ENABLED:
        {
            u32 musicEnabled = (u32)inMsg->mData;
            
            if (musicEnabled)
            {
                [self EvaluateMusicForState:TRUE];
            }
            
            break;
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mState)
    {
        case MUSIC_DIRECTOR_STATE_PENDING_START:
        {
            mNumPendingFrames--;
            
            if (mNumPendingFrames <= 0)
            {
                [[NeonMusicPlayer GetInstance] PlaySongWithParams:&mPendingParams];
                [mPendingParams.mFilename release];
                memset(&mPendingParams, 0, sizeof(mPendingParams));
                
                mNumPendingFrames = 0;
                mState = MUSIC_DIRECTOR_STATE_AWAITING_COMMANDS;
            }
            
            break;
        }
        
        case MUSIC_DIRECTOR_STATE_AWAITING_COMMANDS:
        default:
        {
            break;
        }
    }
}

-(void)EvaluateMusicForState:(BOOL)inForceEvaluate
{
	Flow	*gameFlow = [Flow GetInstance];
    NeonMusicPlayer *musicPlayer = [NeonMusicPlayer GetInstance];
    
    if (([gameFlow GetLevel] != mLastLevel) || ([gameFlow GetGameMode] != mLastGameMode) || (inForceEvaluate) )
    {
        mLastGameMode = [gameFlow GetGameMode];
        mLastLevel = [gameFlow GetLevel];
		
		NSString *bgm_next = [[gameFlow GetLevelDefinitions] GetBGMusicFilename];       // Song we are about to play
        NSString *bgm_current = [musicPlayer getCurrentSongName];  // Song we are currently playing
		
        //if we do not have a song to play we should stop the music
		if ( !bgm_next )
		{
			[musicPlayer Stop:5.0f];
		}
        //otherwise, play the song, as long as it is a different track
		else if( !bgm_current || [bgm_next compare: bgm_current] != NSOrderedSame || [musicPlayer GetMusicPlayerState] == MUSIC_PLAYER_INACTIVE)
		{
			[NeonMusicPlayer InitDefaultParams:&mPendingParams];
			
			mPendingParams.mFilename    = [bgm_next retain];
			mPendingParams.mLoop        = TRUE;
			mPendingParams.mFadeInTime	= 3.0f;
			mPendingParams.mTrimSilence	= FALSE;
            
            mState = MUSIC_DIRECTOR_STATE_PENDING_START;
            mNumPendingFrames = MUSIC_DIRECTOR_NUM_DELAY_FRAMES;
		}
	}
}

@end