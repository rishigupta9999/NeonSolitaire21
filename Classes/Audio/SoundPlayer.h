//
//  SoundPlayer.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "SoundSource.h"

@class SoundSourceManager;

typedef enum
{
    SOUNDPLAYER_STATE_ON,
    SOUNDPLAYER_STATE_INTERRUPTED,
    SOUNDPLAYER_STATE_OFF
} SoundPlayerState;

@interface SoundPlayer : NSObject
{
    ALCdevice*  mALDevice;
    ALCcontext* mALContext;
    
    SoundSourceManager*     mSoundSourceManager;
    
    Vector3                 mListenerPosition;
    Vector3                 mListenerLookAt;
    
    float                   mMasterGain[SOUND_SOURCE_TYPE_NUM];
    
    SoundPlayerState        mSoundPlayerState;
}

-(SoundPlayer*)Init;
-(void)dealloc;

+(void)CreateInstance;
+(void)DestroyInstance;
+(SoundPlayer*)GetInstance;

-(void)InitListener;
-(void)UpdateListener:(CFTimeInterval)inTimeStep;

-(void)Update:(CFTimeInterval)inTimeStep;

-(SoundSource*)PlaySoundWithParams:(SoundSourceParams*)inParams;
-(void)StopSound:(SoundSource*)inSoundSource;

-(void)GetPosition:(Vector3*)outPosition;

-(void)SetMasterGain:(float)inGain sourceType:(SoundSourceType)inSoundSourceType;

-(void)SetSoundEnabled:(BOOL)inSoundEnabled;
-(BOOL)GetSoundEnabled;

-(void)HandleInterruption:(BOOL)inInterrupted;

@end