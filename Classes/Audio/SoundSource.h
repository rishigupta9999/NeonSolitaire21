//
//  SoundSource.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

typedef enum
{   SOUND_SOURCE_STATE_INVALID,
    SOUND_SOURCE_STATE_LOADED,
    SOUND_SOURCE_STATE_LOADED_ZOMBIE,
    SOUND_SOURCE_STATE_PLAYING,
    SOUND_SOURCE_STATE_FINISHED,
} SoundSourceState;

typedef enum
{
    SOUND_SOURCE_TYPE_UI,
    SOUND_SOURCE_TYPE_3D,
    SOUND_SOURCE_TYPE_NUM
} SoundSourceType;

@class GameObject;

typedef struct
{
    NSString*       mFilename;
    SoundSourceType mSoundSourceType;
    Vector3         mPosition;
    float           mGain;
    BOOL            mLoop;
    GameObject*     mGameObject;
} SoundSourceParams;

@interface SoundSource : NSObject
{
    @public
        Vector3     mPosition;
        Vector3     mDirection;
    
    @protected
        ALuint      mSoundSourceId;
        ALuint      mBufferId;
        
        u32         mSampleRate;
        u32         mBitsPerSample;
        u32         mNumSamples;
        u32         mNumChannels;
        ALenum      mFormat;
            
        SoundSourceState    mSoundSourceState;
        SoundSourceParams   mSoundSourceParams;
}

-(SoundSource*)InitWithData:(NSData*)inData params:(SoundSourceParams*)inParams;
-(void)ResetWithParams:(SoundSourceParams*)inParams initialCreation:(BOOL)inInitialCreation;
-(void)dealloc;
-(void)Cleanup;

+(void)InitDefaultParams:(SoundSourceParams*)outParams;

-(void)CreateALBuffer:(unsigned char*)inBuffer size:(u32)inSize;
-(void)Play;
-(void)Update:(CFTimeInterval)inTimeStep;

-(float)GetGain;
-(float)GetAbsoluteGain;
-(void)SetGain:(float)inGain;
-(void)SetAbsoluteGain:(float)inGain;

-(float)GetReferenceDistance;
-(void)SetReferenceDistance:(float)inReferenceDistance;

-(float)GetRolloffFactor;
-(void)SetRolloffFactor:(float)inRolloffFactor;

-(SoundSourceState)GetSoundSourceState;
-(void)SetSoundSourceState:(SoundSourceState)inSoundSourceState;

-(ALuint)GetSoundSourceId;

-(u32)GetSizeBytes;

-(SoundSourceParams*)GetSoundSourceParams;

@end

extern float sSoundSourceGain[];