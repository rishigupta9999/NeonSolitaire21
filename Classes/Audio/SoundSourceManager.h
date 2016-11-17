//
//  SoundSourceManager.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "SoundSource.h"

@class SoundSource;

@interface SoundSourceManager : NSObject
{
    NSMutableArray* mActiveSoundSources;
    NSMutableArray* mInactiveSoundSources;
}

-(SoundSourceManager*)Init;
-(void)dealloc;

-(void)Update:(CFTimeInterval)inTimeStep;
-(SoundSource*)SoundSourceWithParams:(SoundSourceParams*)inParams;
-(void)StopSound:(SoundSource*)inSoundSource;
-(void)StopAllSounds;

@end