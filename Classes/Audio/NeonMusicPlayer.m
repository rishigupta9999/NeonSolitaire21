//
//  MusicPlayer.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "NeonMusicPlayer.h"
#import "ResourceManager.h"
#import "MixingDebugger.h"

#import "Queue.h"

#define MUSIC_PLAYER_FADE_IN_TIME_SECONDS  (1.0f)
#define MUSIC_PLAYER_FADE_OUT_TIME_SECONDS (1.0f);

#define MUSIC_PLAYER_RESUME_DELAY_FRAMES   (30)

#if !NEON_PRODUCTION
static const char* STATUS_STRINGS[MUSIC_PLAYER_STATE_NUM] = { "Fade In", "Playing", "Fade Out", "Inactive" };
#endif

#if NEON_PRODUCTION
#ifdef assert
#undef assert
#endif
#define assert(x)   (0)
#endif

static NeonMusicPlayer* sInstance = NULL;

static void MusicPlayerAudioQueueOutputCallback(void* inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
static void CalculateTrimValues(MusicPlayerSongState* inSongState, UInt32 inNumPacketsRead, UInt32* outStartTrim, UInt32* outEndTrim);

@implementation MusicPlayerOperation

-(MusicPlayerOperation*)InitWithParams:(MusicPlayerParams*)inParams
{
    [NeonMusicPlayer CopyMusicPlayerParams:inParams to:&mParams];    
    return self;
}

-(void)dealloc
{
    [NeonMusicPlayer ReleaseMusicPlayerParams:&mParams];
    [super dealloc];
}

@end

@implementation NeonMusicPlayer

-(NeonMusicPlayer*)Init
{
    [self ResetSongState:&mSongState];
    
    mMusicPlayerState = MUSIC_PLAYER_INACTIVE;
    mStateTime = 0;
    
    memset(&mParams, 0, sizeof(MusicPlayerParams));
    
    mMusicPlayerOperationQueue = [(Queue*)[Queue alloc] Init];
    
    mTotalTime = 0.0f;
    mSongStartTime = 0.0f;
    
    mMaxGain = MUSIC_GAIN;
    
    mResumePacket = 0;
    
    [[DebugManager GetInstance] RegisterDebugMenuItem:@"Music Status" WithCallback:self];
    [[DebugManager GetInstance] RegisterDebugMenuItem:@"Mixing Debugger" WithCallback:self];
    
    mDisplayDebugText = FALSE;
    mMusicEnabled = TRUE;
    
    return self;
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create MusicPlayer");
    sInstance = [(NeonMusicPlayer*)[NeonMusicPlayer alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double-delete MusicPlayer");
    [sInstance release];
}

+(NeonMusicPlayer*)GetInstance
{
    return sInstance;
}

+(void)InitDefaultParams:(MusicPlayerParams*)outParams
{
    outParams->mFilename = NULL;
    outParams->mLoop = FALSE;
    outParams->mFadeInTime = MUSIC_PLAYER_FADE_IN_TIME_SECONDS;
    outParams->mFadeOutTime = MUSIC_PLAYER_FADE_OUT_TIME_SECONDS;
    outParams->mTrimSilence = FALSE;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mMusicPlayerState != MUSIC_PLAYER_INACTIVE)
    {
        if (mSongState.mFileCompleted)
        {
            [self DestroyCurrentAudioQueueState];            
            [self ResetSongState:&mSongState];
            [self SetMusicPlayerState:MUSIC_PLAYER_INACTIVE];
            [self ProcessOperationQueue];
        }
        
        switch(mMusicPlayerState)
        {
            case MUSIC_PLAYER_FADE_IN:
            {
                float logarithmicGain = 1.0f;
                
                if (mParams.mFadeInTime != 0.0f)
                {
                    float linearGain = mStateTime / mParams.mFadeInTime;
                    logarithmicGain = pow(linearGain, 10.0f) * mMaxGain;
                    
                    logarithmicGain = ClampFloat(logarithmicGain, 0.0f, mMaxGain);
                }
                                    
                OSStatus result = AudioQueueSetParameter(mSongState.mAudioQueue, kAudioQueueParam_Volume, logarithmicGain);
                NSAssert(result == noErr, @"There was an error setting the gain of the AudioQueue");
                result=result;
                                
                if (mStateTime >= mParams.mFadeInTime)
                {
                    [self SetMusicPlayerState:MUSIC_PLAYER_PLAYING];
                }
                
                break;
            }
            
            case MUSIC_PLAYER_PLAYING:
            {
                if ((mTotalTime >= (mSongState.mAudioFileDuration - mParams.mFadeOutTime)) && (!mParams.mLoop))
                {
                    [self SetMusicPlayerState:MUSIC_PLAYER_FADE_OUT];
                }
                
                break;
            }
            
            case MUSIC_PLAYER_FADE_OUT:
            {
                float logarithmicGain = 0.0f;
                
                if (mParams.mFadeOutTime != 0.0f)
                {
                    float linearGain = 1.0f - (mStateTime / mParams.mFadeOutTime);
                    logarithmicGain = pow(linearGain, 10.0f) * mMaxGain;
                    
                    logarithmicGain = ClampFloat(logarithmicGain, 0.0f, mMaxGain);
                }
                                
                OSStatus result = AudioQueueSetParameter(mSongState.mAudioQueue, kAudioQueueParam_Volume, logarithmicGain);
                NSAssert(result == noErr, @"There was an error setting the gain of the AudioQueue");
                result=result;
                
                if (mStateTime >= mParams.mFadeOutTime)
                {
                    [self DestroyCurrentAudioQueueState];
                    [self SetMusicPlayerState:MUSIC_PLAYER_INACTIVE];
                    [self ProcessOperationQueue];
                }
                                
                break;
            }
            
            case MUSIC_PLAYER_RESUMED:
            {
                mResumeCounter--;
                
                if (mResumeCounter == 0)
                {
                    [self PlaySongWithParams:&mParams];
                }
                
                break;
            }
            
            default:
            {
                break;
            }
        }
    }
    
    mStateTime += inTimeStep;
    mTotalTime += inTimeStep;
}

-(void)DrawOrtho
{
#if !NEON_PRODUCTION
    if (mDisplayDebugText)
    {
        if (mMusicPlayerState != MUSIC_PLAYER_INACTIVE)
        {
            [[DebugManager GetInstance] DrawString:[NSString stringWithFormat:@"%s, %@",
                                                        STATUS_STRINGS[mMusicPlayerState], mSongState.mMusicPlayerParams->mFilename]
                                                    locX:10 locY:10];
                                                    
            float elapsedSeconds = (mSongState.mCurrentPacket * mSongState.mAudioFileDataFormat.mFramesPerPacket) / mSongState.mAudioFileDataFormat.mSampleRate;
            
            [[DebugManager GetInstance] DrawString:[NSString stringWithFormat:@"%@/%@",
                                                        NeonFormatTime(elapsedSeconds, 2),
                                                        NeonFormatTime(mSongState.mAudioFileDuration, 2)]
                                                    locX:10 locY:30];

        }
    }
#endif
}

-(void)PlaySongWithParams:(MusicPlayerParams*)inParams;
{
    if (!mMusicEnabled)
    {
        return;
    }
    
    if ((mMusicPlayerState != MUSIC_PLAYER_INACTIVE) && (mMusicPlayerState != MUSIC_PLAYER_RESUMED))
    {
        MusicPlayerOperation* musicPlayerOperation = [(MusicPlayerOperation*)[MusicPlayerOperation alloc] InitWithParams:inParams];
        
        [mMusicPlayerOperationQueue Enqueue:musicPlayerOperation];
        [musicPlayerOperation release];
        
        [self SetMusicPlayerState:MUSIC_PLAYER_FADE_OUT];
        
        return;
    }
    
    if (inParams != &mParams)
    {
        [NeonMusicPlayer ReleaseMusicPlayerParams:&mParams];
        [NeonMusicPlayer CopyMusicPlayerParams:inParams to:&mParams];
    }
    
    FileNode* fileNode = [[ResourceManager GetInstance] FindFileWithName:inParams->mFilename];
    CFURLRef  fileURL = (CFURLRef)[NSURL fileURLWithPath:fileNode->mPath isDirectory:FALSE];
    
    // Reset the Audio state values to sensible defaults
    [self ResetSongState:&mSongState];
    OSStatus result = AudioFileOpenURL(fileURL, 0x01 /*fsRdPerm*/, 0, &mSongState.mAudioFileID);
    NSAssert(result == noErr, @"There was an error opening the file %@", inParams->mFilename);
    
    // Read a description of the audio data from the file (eg: sample rate, etc).
    UInt32 formatSize = sizeof(AudioStreamBasicDescription);
    result = AudioFileGetProperty(mSongState.mAudioFileID, kAudioFilePropertyDataFormat, &formatSize, &mSongState.mAudioFileDataFormat);
    NSAssert(result == noErr, @"There was an error attempting to get the file's data format.  Is it a valid audio file?");
    
    // Create a new audio queue for audio output.
    result = AudioQueueNewOutput(&mSongState.mAudioFileDataFormat, MusicPlayerAudioQueueOutputCallback, &mSongState,
                            CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &mSongState.mAudioQueue);
    NSAssert(result == noErr, @"There was an error attempting to create a new AudioQueue for playback.");
    
    // Determine the maximum size of a packet
    UInt32 maxPacketPropertySize = sizeof(UInt32);
    UInt32 maxPacketSize = 0;
    result = AudioFileGetProperty(mSongState.mAudioFileID, kAudioFilePropertyMaximumPacketSize, &maxPacketPropertySize, &maxPacketSize);
    NSAssert(result == noErr, @"There was an error attempting to get the maximum packet size");

    // Calculate a good size for playback buffers.
    [self DerivePlaybackBufferSize:&mSongState.mAudioFileDataFormat maxPacketSize:maxPacketSize seconds:1.0f
            bufferSize:&mSongState.mBufferSize numPacketsToRead:&mSongState.mNumPacketsToRead];
    
    // Create buffer to store packet descriptions for VBR
    BOOL isFormatVBR = (mSongState.mAudioFileDataFormat.mBytesPerPacket == 0 || mSongState.mAudioFileDataFormat.mFramesPerPacket == 0);
     
    if (isFormatVBR)
    {
        mSongState.mPacketDescriptions = (AudioStreamPacketDescription*)malloc(mSongState.mNumPacketsToRead * sizeof(AudioStreamPacketDescription));
    }
    else
    {
        mSongState.mPacketDescriptions = NULL;
    }

    // Get cookie property - this is necessary for certain formats.
    UInt32 cookieSize = sizeof(UInt32);
    result = AudioFileGetPropertyInfo(mSongState.mAudioFileID, kAudioFilePropertyMagicCookieData, &cookieSize, NULL);
 
    if ((result == noErr) && (cookieSize != 0))
    {
        char* magicCookie = (char *)malloc(cookieSize);
     
        result = AudioFileGetProperty(mSongState.mAudioFileID, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
        NSAssert(result == noErr, @"Could not get cookie size, even though cookie data exists");
        
        result = AudioQueueSetProperty(mSongState.mAudioQueue, kAudioQueueProperty_MagicCookie, magicCookie, cookieSize);
        NSAssert(result == noErr, @"Could not set cookie size for the AudioQueue");

        free(magicCookie);
    }
    
    mSongState.mMusicPlayerParams = &mParams;

    // Get number of valid audio frames in the file
    
    UInt32 packetTableSize = sizeof(AudioFilePacketTableInfo);
    result = AudioFileGetProperty(mSongState.mAudioFileID, kAudioFilePropertyPacketTableInfo, &packetTableSize, &mSongState.mPacketTableInfo);
    
    if (result == noErr)
    {
        mSongState.mAudioFileDuration = (Float64)mSongState.mPacketTableInfo.mNumberValidFrames / mSongState.mAudioFileDataFormat.mSampleRate;
        mSongState.mPacketTableValid = true;
    }
    else
    {
        UInt32 timeSize = sizeof(CFTimeInterval);
        result = AudioFileGetProperty(mSongState.mAudioFileID, kAudioFilePropertyEstimatedDuration, &timeSize, &mSongState.mAudioFileDuration);

        NSAssert(result == noErr, @"Could not get duration of the audio file");
        NSAssert(timeSize == sizeof(CFTimeInterval), @"Unexpected size of audio file");
    }
    
    if (mMusicPlayerState == MUSIC_PLAYER_RESUMED)
    {
        mSongState.mCurrentPacket = mResumePacket;
    }
    
    for (int i = 0; i < MUSIC_PLAYER_NUM_PLAYBACK_BUFFERS; ++i)
    {
        result = AudioQueueAllocateBuffer(mSongState.mAudioQueue, mSongState.mBufferSize, &mSongState.mBuffers[i]);
        NSAssert(result == noErr, @"There was an error allocating the audio queue buffer.");
        
        MusicPlayerAudioQueueOutputCallback(&mSongState, mSongState.mAudioQueue, mSongState.mBuffers[i]);
    }
            
    // Start the AudioQueue
    
    UInt32 numFramesPrepared;
    result = AudioQueuePrime(mSongState.mAudioQueue, 0, &numFramesPrepared);
    NSAssert(result == noErr, @"There was an error priming the AudioQueue");
    
    result = AudioQueueStart(mSongState.mAudioQueue, NULL);
    NSAssert(result == noErr, @"There was an error starting the AudioQueue");
    
    result = AudioQueueSetParameter(mSongState.mAudioQueue, kAudioQueueParam_Volume, 0);
    NSAssert(result == noErr, @"Error setting starting gain");
        
    [self SetMusicPlayerState:MUSIC_PLAYER_FADE_IN];
    
    mSongStartTime = CACurrentMediaTime();
    
    mTotalTime = 0.0f;
}

-(void)Stop:(CFTimeInterval)inFadeOutTime
{
    // If we're already fading out, then there's no need to do anything
    if ((mMusicPlayerState != MUSIC_PLAYER_FADE_OUT) && (mMusicPlayerState != MUSIC_PLAYER_INACTIVE))
    {
        mParams.mFadeOutTime = inFadeOutTime;
        [self SetMusicPlayerState:MUSIC_PLAYER_FADE_OUT];
    }
}

-(void)ResetSongState:(MusicPlayerSongState*)inSongState
{
    inSongState->mAudioFileID = 0;
    memset(&inSongState->mAudioFileDataFormat, 0, sizeof(AudioStreamBasicDescription));
    inSongState->mAudioQueue = NULL;
    inSongState->mBufferSize = 0;
    inSongState->mNumPacketsToRead = 0;
    inSongState->mPacketDescriptions = NULL;
    inSongState->mCurrentPacket = 0;
    inSongState->mFileCompleted = false;
    inSongState->mAudioFileDuration = 0.0f;
    inSongState->mLooped = false;
    memset(&inSongState->mPacketTableInfo, 0, sizeof(AudioFilePacketTableInfo));
    inSongState->mPacketTableValid = false;
    inSongState->mMusicPlayerParams = NULL;
}

-(void)DestroyCurrentAudioQueueState
{
    OSStatus error = AudioQueueStop(mSongState.mAudioQueue, false);
    NSAssert(error == kAudioSessionNoError, @"Error stopping audio queue");
    
    mSongState.mFileCompleted = true;
    
    error = AudioQueueDispose(mSongState.mAudioQueue, true);
    NSAssert(error == kAudioSessionNoError, @"Error disposing of audio queue");
    
    error = AudioFileClose(mSongState.mAudioFileID);
    NSAssert(error == kAudioSessionNoError, @"Error closing audio file");
    
    free(mSongState.mPacketDescriptions);
}

-(void)ProcessOperationQueue
{
    MusicPlayerOperation* musicPlayerOperation = (MusicPlayerOperation*)[mMusicPlayerOperationQueue Dequeue];
    
    if (musicPlayerOperation != NULL)
    {
        [self PlaySongWithParams:&musicPlayerOperation->mParams];
    }
}

-(void)DerivePlaybackBufferSize:(AudioStreamBasicDescription*)inAudioStreamDescription maxPacketSize:(UInt32)inMaxPacketSize
                                seconds:(Float64)inSeconds bufferSize:(UInt32*)outBufferSize numPacketsToRead:(UInt32*)outNumPacketsToRead
{
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
 
    if (inAudioStreamDescription->mFramesPerPacket != 0)
    {
        // Sample rate / frames per packet translates to packets / second.
        // Eg: 44000 sample rate (ie: 44000 samples/sec) / (1000 frames / packet) means that one second contains 44000 / 1000 or 44 packets.
        // 
        // Then multiply packets by time to get number of packets in a given amount of time.
        Float64 numPacketsForTime = (inAudioStreamDescription->mSampleRate / inAudioStreamDescription->mFramesPerPacket) * inSeconds;
        *outBufferSize = numPacketsForTime * inMaxPacketSize;
    }
    else
    {
        *outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize)
    {
        *outBufferSize = maxBufferSize;
    }
    else
    {
        if (*outBufferSize < minBufferSize)
        {
            *outBufferSize = minBufferSize;
        }
    }
 
    *outNumPacketsToRead = *outBufferSize / inMaxPacketSize;
}

-(void)SetMusicPlayerState:(MusicPlayerState)inMusicPlayerState
{
    if (mMusicPlayerState != inMusicPlayerState)
    {
        mMusicPlayerState = inMusicPlayerState;
        mStateTime = 0;
    }
}
-(MusicPlayerState) GetMusicPlayerState
{
    return mMusicPlayerState;
}

+(void)CopyMusicPlayerParams:(MusicPlayerParams*)inSource to:(MusicPlayerParams*)outDest
{
    memcpy(outDest, inSource, sizeof(MusicPlayerParams));
    [outDest->mFilename retain];
}

+(void)ReleaseMusicPlayerParams:(MusicPlayerParams*)inParams
{
    [inParams->mFilename release];
}

-(void)DebugMenuItemPressed:(NSString*)inName
{
    if ([inName compare:@"Music Status"] == NSOrderedSame)
    {
        mDisplayDebugText = !mDisplayDebugText;
    }
    else if ([inName compare:@"Mixing Debugger"] == NSOrderedSame)
    {
        [[DebugManager GetInstance] ToggleDebugGameState:[MixingDebugger class]];
    }
}

-(float)GetGain
{
    return mMaxGain;
}

-(void)SetGain:(float)inGain
{
    mMaxGain = inGain;
    
    if (mMusicPlayerState == MUSIC_PLAYER_PLAYING)
    {
        OSStatus result = AudioQueueSetParameter(mSongState.mAudioQueue, kAudioQueueParam_Volume, inGain);
        NSAssert(result == noErr, @"There was an error setting the gain of the AudioQueue");
        result=result;
    }
}

-(void)SetMusicEnabled:(BOOL)inEnabled
{
    mMusicEnabled = inEnabled;
    
    if (mMusicEnabled)
    {
        Message msg;
        
        msg.mId = EVENT_MUSIC_ENABLED;
        msg.mData = (void*)1;
        
        [GetGlobalMessageChannel() BroadcastMessageSync:&msg];
    }
    else
    {
        [self Stop:0.0f];
        
        // Force the Music Player to process the stop this frame.  That way if the user is button mashing, there should
        // be no ill-effects caused by operations piling up in the operation queue.
        
        [self Update:(1.0f / 60.0f)];
        
        Message msg;
        
        msg.mId = EVENT_MUSIC_ENABLED;
        msg.mData = (void*)0;
        
        [GetGlobalMessageChannel() BroadcastMessageSync:&msg];
    }
}

-(BOOL)GetMusicEnabled
{
    return mMusicEnabled;
}

void MusicPlayerAudioQueueOutputCallback(void* inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    MusicPlayerSongState* songState = (MusicPlayerSongState*)inUserData;
    
    if (songState->mFileCompleted)
    {
        return;
    }
    
    UInt32 numBytesRead = 0;
    UInt32 numPacketsRead = songState->mNumPacketsToRead;
    OSStatus result = noErr;
    
    result = AudioFileReadPackets(songState->mAudioFileID, false, &numBytesRead, songState->mPacketDescriptions,
                                    songState->mCurrentPacket, &numPacketsRead, inBuffer->mAudioData);
    
    assert(result == noErr);

    UInt32 startTrim = 0, endTrim = 0;
    CalculateTrimValues(songState, numPacketsRead, &startTrim, &endTrim);
    
    // The first time we're playing the song, don't trim anything off the beginning.  This is so that fades sound appropriate.
    if (!songState->mLooped)
    {
        startTrim = 0;
    }
    
    songState->mCurrentPacket += numPacketsRead;
    
    if (numPacketsRead > 0)
    {        
        inBuffer->mAudioDataByteSize = numBytesRead;
        
        result = AudioQueueEnqueueBufferWithParameters(songState->mAudioQueue, inBuffer,
                                                        ((songState->mPacketDescriptions != NULL) ? numPacketsRead : 0), songState->mPacketDescriptions,
                                                        startTrim, endTrim, 0, NULL, NULL, NULL);
        
        assert(result == noErr);
    }
    else
    {
        if (songState->mMusicPlayerParams->mLoop)
        {
            songState->mCurrentPacket = 0;
            songState->mLooped = true;
            
            numPacketsRead = songState->mNumPacketsToRead;
            
            result = AudioFileReadPackets(songState->mAudioFileID, false, &numBytesRead, songState->mPacketDescriptions,
                                    songState->mCurrentPacket, &numPacketsRead, inBuffer->mAudioData);
            assert(result == noErr);
            assert(numPacketsRead > 0);
 
            CalculateTrimValues(songState, numPacketsRead, &startTrim, &endTrim);
            
            if (songState->mCurrentPacket == 0)
            {
                startTrim = songState->mPacketTableInfo.mPrimingFrames;
            }

            songState->mCurrentPacket += numPacketsRead;

            result = AudioQueueEnqueueBufferWithParameters(songState->mAudioQueue, inBuffer,
                                                        ((songState->mPacketDescriptions != NULL) ? numPacketsRead : 0), songState->mPacketDescriptions,
                                                        startTrim, endTrim, 0, NULL, NULL, NULL);
            
            assert(result == noErr);
        }
        else
        {
            songState->mFileCompleted = TRUE;
        }
    }
    
    result=result;
}

void CalculateTrimValues(MusicPlayerSongState* inSongState, UInt32 inNumPacketsRead, UInt32* outStartTrim, UInt32* outEndTrim)
{
    UInt32 startTrim = 0;
    UInt32 endTrim = 0;

    if (inSongState->mPacketTableValid)
    {
        UInt32 framesPerPacket = inSongState->mAudioFileDataFormat.mFramesPerPacket;
        UInt32 startPadding = inSongState->mPacketTableInfo.mPrimingFrames;
        
        UInt32 curFrame = inSongState->mCurrentPacket * framesPerPacket;
        UInt32 endFrame = curFrame + (inNumPacketsRead * framesPerPacket);
        
        // Calculate start trim
        if ((startPadding > curFrame) && (startPadding < endFrame))
        {
            // Trim part of the read (the ending part has valid audio data, the first part has silence)
            startTrim = startPadding - curFrame;
        }
        else if ((startPadding > curFrame) && (startPadding > endFrame))
        {
            // Trim the entire read (no playback, since all the packets are in silence)
            startTrim = endFrame - curFrame;
        }
            
        // Calculate end trim
        
        UInt32 lastValidFrame = inSongState->mPacketTableInfo.mNumberValidFrames + startPadding;
        
        if (curFrame >= lastValidFrame)
        {
            // Trim everything
            endTrim = inNumPacketsRead * framesPerPacket;
        }
        else if ((curFrame < lastValidFrame) && (endFrame > lastValidFrame))
        {
            // Trim only the end part
            endTrim = endFrame - lastValidFrame;
        }
    }
    
    *outStartTrim = startTrim;
    *outEndTrim = endTrim;
}

-(void)HandleInterruption:(BOOL)inInterruption
{
    if (inInterruption)
    {
        if ((mMusicPlayerState != MUSIC_PLAYER_RESUMED) &&
            (mMusicPlayerState != MUSIC_PLAYER_INACTIVE) &&
            (mMusicPlayerState != MUSIC_PLAYER_INTERRUPTED))
        {
            mResumePacket = mSongState.mCurrentPacket;
            
            [self DestroyCurrentAudioQueueState];
            [self ResetSongState:&mSongState];
        }
        
        // If the MusicPlayer is inactive, then there's nothing to do here
        if (mMusicPlayerState != MUSIC_PLAYER_INACTIVE)
        {
            [self SetMusicPlayerState:MUSIC_PLAYER_INTERRUPTED];
        }
    }
    else
    {
        if (mMusicPlayerState != MUSIC_PLAYER_INACTIVE)
        {
            [self SetMusicPlayerState:MUSIC_PLAYER_RESUMED];
            mResumeCounter = MUSIC_PLAYER_RESUME_DELAY_FRAMES;
        }
    }
}

-(NSString*) getCurrentSongName
{
    NSString* retval = NULL;
    //Returns NULL if there is no song playing
    if(mParams.mFilename)
        retval = [NSString stringWithString: mParams.mFilename];

    return retval;
}

@end