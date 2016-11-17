//
//  MusicPlayer.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "DebugManager.h"

#define MUSIC_PLAYER_NUM_PLAYBACK_BUFFERS   (5)
#define MUSIC_GAIN  (1.0)

typedef enum
{
    MUSIC_PLAYER_FADE_IN,
    MUSIC_PLAYER_PLAYING,
    MUSIC_PLAYER_FADE_OUT,
    MUSIC_PLAYER_INTERRUPTED,
    MUSIC_PLAYER_RESUMED,
    MUSIC_PLAYER_INACTIVE,
    MUSIC_PLAYER_STATE_NUM
} MusicPlayerState;

typedef struct
{
    NSString*       mFilename;
    CFTimeInterval  mFadeInTime;
    CFTimeInterval  mFadeOutTime;
    BOOL            mLoop;
    BOOL            mTrimSilence;
} MusicPlayerParams;

typedef struct
{
    AudioFileID                     mAudioFileID;
    AudioStreamBasicDescription     mAudioFileDataFormat;
    AudioQueueRef                   mAudioQueue;
    UInt32                          mNumPacketsToRead;
    AudioStreamPacketDescription*   mPacketDescriptions;
    SInt64                          mCurrentPacket;
    UInt32                          mBufferSize;
    AudioQueueBufferRef             mBuffers[MUSIC_PLAYER_NUM_PLAYBACK_BUFFERS];
    bool                            mFileCompleted;
    CFTimeInterval                  mAudioFileDuration;
    bool                            mLooped;
    AudioFilePacketTableInfo        mPacketTableInfo;
    bool                            mPacketTableValid;
    MusicPlayerParams*              mMusicPlayerParams;
} MusicPlayerSongState;

@interface MusicPlayerOperation : NSObject
{
    @public
        MusicPlayerParams   mParams;
}
-(MusicPlayerOperation*)InitWithParams:(MusicPlayerParams*)inParams;

@end

@class Queue;

@interface NeonMusicPlayer : NSObject<DebugMenuCallback>
{
    MusicPlayerSongState    mSongState;
    MusicPlayerState        mMusicPlayerState;
    
    CFTimeInterval          mStateTime;
    CFTimeInterval          mTotalTime;
    CFTimeInterval          mSongStartTime;
    
    MusicPlayerParams       mParams;
    Queue*                  mMusicPlayerOperationQueue;
    
    float                   mMaxGain;
    
    BOOL                    mDisplayDebugText;
    BOOL                    mMusicEnabled;
    
    SInt64                  mResumePacket;
    int                     mResumeCounter;
}

-(NeonMusicPlayer*)Init;
+(void)CreateInstance;
+(void)DestroyInstance;
+(NeonMusicPlayer*)GetInstance;
+(void)InitDefaultParams:(MusicPlayerParams*)outParams;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;
-(void)PlaySongWithParams:(MusicPlayerParams*)inParams;
-(void)Stop:(CFTimeInterval)inFadeOutTime;

-(void)ResetSongState:(MusicPlayerSongState*)inSongState;
-(void)DestroyCurrentAudioQueueState;
-(void)ProcessOperationQueue;

-(float)GetGain;
-(void)SetGain:(float)inGain;

-(void)DerivePlaybackBufferSize:(AudioStreamBasicDescription*)inAudioStreamDescription maxPacketSize:(UInt32)inMaxPacketSize
                                seconds:(Float64)inSeconds bufferSize:(UInt32*)outBufferSize numPacketsToRead:(UInt32*)outNumPacketsToRead;
                                
-(void)SetMusicPlayerState:(MusicPlayerState)inMusicPlayerState;
-(MusicPlayerState)GetMusicPlayerState;

+(void)CopyMusicPlayerParams:(MusicPlayerParams*)inSource to:(MusicPlayerParams*)outDest;
+(void)ReleaseMusicPlayerParams:(MusicPlayerParams*)inParams;

-(void)DebugMenuItemPressed:(NSString*)inName;

-(void)SetMusicEnabled:(BOOL)inEnabled;
-(BOOL)GetMusicEnabled;

-(void)HandleInterruption:(BOOL)inInterruption;

-(NSString*) getCurrentSongName;

@end