//
//  SoundPlayer.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "SoundPlayer.h"
#import "SoundSourceManager.h"
#import "SoundSource.h"

#import "CameraStateMgr.h"

static SoundPlayer* sInstance = NULL;
static const float sDefaultGain[SOUND_SOURCE_TYPE_NUM] = { 1.0f, 1.0f };

@implementation SoundPlayer

-(SoundPlayer*)Init
{
	mALDevice = alcOpenDevice(NULL);
    NSAssert(mALDevice != NULL, @"Could not open OpenAL device");
    
    mALContext = alcCreateContext(mALDevice, 0);
    NSAssert(mALContext != NULL, @"Could not create OpenAL context");
    
    alcMakeContextCurrent(mALContext);

    [self InitListener];
    
    mSoundSourceManager = [(SoundSourceManager*)[SoundSourceManager alloc] Init];
    
    for (int i = 0; i < SOUND_SOURCE_TYPE_NUM; i++)
    {
        mMasterGain[i] = sDefaultGain[i];
    }
    
    Set(&mListenerPosition, 0.0f, 0.0f, 0.0f);
    Set(&mListenerLookAt, 0.0f, 0.0f, 0.0f);
    
    mSoundPlayerState = SOUNDPLAYER_STATE_ON;
    
	NeonALError();
    	
    return self;
}

-(void)dealloc
{
    alcCloseDevice(mALDevice);
    
    alcDestroyContext(mALContext);
    alcMakeContextCurrent(NULL);
    
    [mSoundSourceManager release];
    
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create SoundPlayer");
    sInstance = [(SoundPlayer*)[SoundPlayer alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double-delete SoundPlayer");
    [sInstance release];
}

+(SoundPlayer*)GetInstance
{
    return sInstance;
}

-(void)InitListener
{   
    Set(&mListenerPosition, 0.0f, 0.0f, 0.0f);
    [self UpdateListener:0.0f];
}

-(void)UpdateListener:(CFTimeInterval)inTimeStep
{
    if (mSoundPlayerState == SOUNDPLAYER_STATE_ON)
    {
        NeonALError();
        
        Set(&mListenerPosition, 0.0f, 0.0f, 0.0f);
        Set(&mListenerLookAt, 0.0f, 0.0f, 0.0f);
        
        if ([[CameraStateMgr GetInstance] GetActiveState] != NULL)
        {
            [[CameraStateMgr GetInstance] GetPosition:&mListenerPosition];
            [[CameraStateMgr GetInstance] GetLookAt:&mListenerLookAt];
        }
        
        float orientation[6];
        
        memcpy(orientation, mListenerLookAt.mVector, sizeof(float) * 3);
        orientation[3] = 0.0f;
        orientation[4] = 1.0f;
        orientation[5] = 0.0f;
            
        alListenerfv(AL_POSITION, mListenerPosition.mVector);
        alListenerfv(AL_ORIENTATION, orientation);
        
        NeonALError();
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    NeonALError();
    
    [self UpdateListener:inTimeStep];
    
    [mSoundSourceManager Update:inTimeStep];
    
    NeonALError();
}

-(SoundSource*)PlaySoundWithParams:(SoundSourceParams*)inParams
{
    if (mSoundPlayerState == SOUNDPLAYER_STATE_ON)
    {
        NSAssert(   (inParams->mSoundSourceType >= 0) && (inParams->mSoundSourceType < SOUND_SOURCE_TYPE_NUM),
                    @"Invalid sound source type"    );
        
        inParams->mGain *= mMasterGain[inParams->mSoundSourceType];
        
        SoundSource* newSoundSource = [mSoundSourceManager SoundSourceWithParams:inParams];
        [newSoundSource Play];
        
        NeonALError();
        
        return newSoundSource;
    }
    else
    {
        return NULL;
    }
}

-(void)StopSound:(SoundSource*)inSoundSource
{
    [mSoundSourceManager StopSound:inSoundSource];
    
    NeonALError();
}

-(void)GetPosition:(Vector3*)outPosition
{
    CloneVec3(&mListenerPosition, outPosition);
    
    NeonALError();
}

-(void)SetMasterGain:(float)inGain sourceType:(SoundSourceType)inSoundSourceType
{
    NSAssert(   (inSoundSourceType >= 0) && (inSoundSourceType < SOUND_SOURCE_TYPE_NUM),
                @"Invalid sound source type"    );
                
    mMasterGain[inSoundSourceType] = inGain;
}

-(void)SetSoundEnabled:(BOOL)inSoundEnabled
{
    if (inSoundEnabled)
    {
        mSoundPlayerState = SOUNDPLAYER_STATE_ON;
    }
    else
    {
        mSoundPlayerState = SOUNDPLAYER_STATE_OFF;
    }
}

-(BOOL)GetSoundEnabled
{
    return (mSoundPlayerState == SOUNDPLAYER_STATE_ON);
}

-(void)HandleInterruption:(BOOL)inInterrupted
{
    if (inInterrupted)
    {
        [mSoundSourceManager StopAllSounds];
        alcMakeContextCurrent(NULL);
        
        mSoundPlayerState = SOUNDPLAYER_STATE_INTERRUPTED;
    }
    else
    {
        alcMakeContextCurrent(mALContext);
        
        mSoundPlayerState = SOUNDPLAYER_STATE_ON;
    }
}

@end