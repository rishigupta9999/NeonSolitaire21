//
//  SoundSource.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "SoundSource.h"
#import "SoundPlayer.h"
#import "GameObject.h"

float sSoundSourceGain[SOUND_SOURCE_TYPE_NUM] = { 1.0f,      // UI
                                                  1.0f };    // 3D

@implementation SoundSource

-(SoundSource*)InitWithData:(NSData*)inData params:(SoundSourceParams*)inParams
{
    alGenBuffers(1, &mBufferId);
    alGenSources(1, &mSoundSourceId);
        
    mSoundSourceState = SOUND_SOURCE_STATE_INVALID;
    
    mSampleRate = 0;
    mBitsPerSample = 0;
    mNumSamples = 0;
    mNumChannels = 0;
    mFormat = 0;
        
    [self ResetWithParams:inParams initialCreation:TRUE];
            
    return self;
}

-(void)ResetWithParams:(SoundSourceParams*)inParams initialCreation:(BOOL)inInitialCreation
{
    if (!inInitialCreation)
    {
        [self Cleanup];
    }
    
    memcpy(&mSoundSourceParams, inParams, sizeof(SoundSourceParams));
    [mSoundSourceParams.mFilename retain];
    
    if (inParams->mGameObject == NULL)
    {
        CloneVec3(&inParams->mPosition, &mPosition);
    }
    else
    {
        [inParams->mGameObject retain];
        
        Vector3 entityPosition;
        [inParams->mGameObject GetPositionWorld:&entityPosition current:TRUE];
        
        CloneVec3(&entityPosition, &mPosition);
    }
    
    Set(&mDirection, 0.0f, 0.0f, 0.0f);
    
    switch(mSoundSourceParams.mSoundSourceType)
    {
        case SOUND_SOURCE_TYPE_UI:
        {
            // UI sounds should always be at the listener's location
            alSourcei(mSoundSourceId, AL_SOURCE_RELATIVE, AL_TRUE);
            alSource3f(mSoundSourceId, AL_POSITION, 0.0f, 0.0f, 0.0f);
            
            break;
        }
        
        case SOUND_SOURCE_TYPE_3D:
        {
            alSource3f(mSoundSourceId, AL_POSITION, mPosition.mVector[x], mPosition.mVector[y], mPosition.mVector[z]);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown sound source type");
            break;
        }
    }
    
    NeonALError();
}

-(void)dealloc
{
    alDeleteSources(1, &mSoundSourceId);
    alDeleteBuffers(1, &mBufferId);
    
    [self Cleanup];
    
    [super dealloc];
}

-(void)Cleanup
{
    [mSoundSourceParams.mFilename release];
    mSoundSourceParams.mFilename = NULL;
    
    [mSoundSourceParams.mGameObject release];
    mSoundSourceParams.mGameObject = NULL;
}

+(void)InitDefaultParams:(SoundSourceParams*)outParams
{
    outParams->mFilename = NULL;
    outParams->mSoundSourceType = SOUND_SOURCE_TYPE_UI;
    Set(&outParams->mPosition, 0, 0, 0);
    outParams->mGain = 1.0f;
    outParams->mLoop = FALSE;
    outParams->mGameObject = NULL;
}

-(void)CreateALBuffer:(unsigned char*)inBuffer size:(u32)inSize
{
    NSAssert((mFormat == AL_FORMAT_STEREO16 || mFormat == AL_FORMAT_MONO16 || mFormat == AL_FORMAT_STEREO8 || mFormat == AL_FORMAT_MONO8),
                @"Unexpected PCM format");
    
    NSAssert(inSize == ((mBitsPerSample / 8) * mNumSamples * mNumChannels), @"Unexpected buffer size passed in");
    alBufferData(mBufferId, mFormat, inBuffer, inSize, mSampleRate);
    
    NeonALError();
    
    mSoundSourceState = SOUND_SOURCE_STATE_LOADED;
}

-(void)Play
{
    NSAssert( ((mSoundSourceState == SOUND_SOURCE_STATE_LOADED) || (mSoundSourceState == SOUND_SOURCE_STATE_LOADED_ZOMBIE)),
              @"Attempting to play a sound source with no buffer" );
    
    if (mSoundSourceState == SOUND_SOURCE_STATE_LOADED)
    {
        alSourceQueueBuffers(mSoundSourceId, 1, &mBufferId);
    }
    
    alSourcef(mSoundSourceId, AL_GAIN, mSoundSourceParams.mGain);
    alSourcei(mSoundSourceId, AL_LOOPING, mSoundSourceParams.mLoop ? AL_TRUE : AL_FALSE);
    
    alSourcePlay(mSoundSourceId);
    
    mSoundSourceState = SOUND_SOURCE_STATE_PLAYING;
    
    NeonALError();
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    ALint state = AL_INITIAL;
    alGetSourcei(mSoundSourceId, AL_SOURCE_STATE, &state);
    
    if (state == AL_STOPPED)
    {
        mSoundSourceState = SOUND_SOURCE_STATE_FINISHED;
    }
    
    switch(mSoundSourceParams.mSoundSourceType)
    {
        case SOUND_SOURCE_TYPE_UI:
        {
            NSAssert( ((mPosition.mVector[x] == 0.0f) && (mPosition.mVector[y] == 0.0f) && (mPosition.mVector[z] == 0.0f)),
                      @"A UI sound source's position was set to a non-zero value.  Was this desired?" );
                      
            NSAssert( ((mPosition.mVector[x] == 0.0f) && (mPosition.mVector[y] == 0.0f) && (mPosition.mVector[z] == 0.0f)),
                      @"A UI sound source's position was set to a non-zero value.  Was this desired?" );
            break;
        }
        
        case SOUND_SOURCE_TYPE_3D:
        {
            if (mSoundSourceParams.mGameObject != NULL)
            {
                Vector3 entityPosition;
                [mSoundSourceParams.mGameObject GetPositionWorld:&entityPosition current:TRUE];
                
                CloneVec3(&entityPosition, &mPosition);
            }
            
            alSource3f(mSoundSourceId, AL_POSITION, mPosition.mVector[x], mPosition.mVector[y], mPosition.mVector[z]);
            alSource3f(mSoundSourceId, AL_DIRECTION, mDirection.mVector[x], mDirection.mVector[y], mDirection.mVector[z]);
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown sound source type");
            break;
        }
    }
    
    NeonALError();
}

-(float)GetGain
{
    NSAssert( (mSoundSourceParams.mSoundSourceType >= 0) && (mSoundSourceParams.mSoundSourceType < SOUND_SOURCE_TYPE_NUM),
              @"Invalid sound source type" );

    return [self GetAbsoluteGain] / sSoundSourceGain[mSoundSourceParams.mSoundSourceType];
}

-(float)GetAbsoluteGain
{
    float retGain;
    
    alGetSourcef(mSoundSourceId, AL_GAIN, &retGain);
    NeonALError();
    
    // Callers never know about us tweaking the gain behind their back
    
    NSAssert( (mSoundSourceParams.mSoundSourceType >= 0) && (mSoundSourceParams.mSoundSourceType < SOUND_SOURCE_TYPE_NUM),
              @"Invalid sound source type" );
                  
    return retGain;
}

-(void)SetGain:(float)inGain
{
    NSAssert( (mSoundSourceParams.mSoundSourceType >= 0) && (mSoundSourceParams.mSoundSourceType < SOUND_SOURCE_TYPE_NUM),
              @"Invalid sound source type" );
   
    // Callers never know about us tweaking the gain behind their back
    inGain *= sSoundSourceGain[mSoundSourceParams.mSoundSourceType];
    
    [self SetAbsoluteGain:inGain];
}

-(void)SetAbsoluteGain:(float)inGain
{
    NSAssert( (mSoundSourceParams.mSoundSourceType >= 0) && (mSoundSourceParams.mSoundSourceType < SOUND_SOURCE_TYPE_NUM),
              @"Invalid sound source type" );
              
    // For OpenAL, you cannot set the gain to greater than 1.0 (OpenAL will just do attenuation, no amplification)
    
    inGain = min(inGain, 1.0f);
              
    alSourcef(mSoundSourceId, AL_GAIN, inGain);
    NeonALError();
}

-(float)GetReferenceDistance
{
    float retDistance;
    
    alGetSourcef(mSoundSourceId, AL_REFERENCE_DISTANCE, &retDistance);
    NeonALError();
    
    return retDistance;
}

-(void)SetReferenceDistance:(float)inReferenceDistance
{
    alSourcef(mSoundSourceId, AL_REFERENCE_DISTANCE, inReferenceDistance);
    NeonALError();
}

-(float)GetRolloffFactor
{
    float retFactor;
    
    alGetSourcef(mSoundSourceId, AL_ROLLOFF_FACTOR, &retFactor);
    NeonALError();
    
    return retFactor;
}

-(void)SetRolloffFactor:(float)inRolloffFactor
{
    alSourcef(mSoundSourceId, AL_ROLLOFF_FACTOR, inRolloffFactor);
    NeonALError();
}

-(u32)GetSizeBytes
{
    return (mNumSamples * (mBitsPerSample / 8) * mNumChannels);
}

-(SoundSourceState)GetSoundSourceState
{
    return mSoundSourceState;
}

-(void)SetSoundSourceState:(SoundSourceState)inSoundSourceState
{
    mSoundSourceState = inSoundSourceState;
}

-(ALuint)GetSoundSourceId
{
    return mSoundSourceId;
}

-(SoundSourceParams*)GetSoundSourceParams
{
    return &mSoundSourceParams;
}

@end