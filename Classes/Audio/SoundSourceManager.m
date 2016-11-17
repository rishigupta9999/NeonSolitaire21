//
//  SoundSourceManager.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "SoundSourceManager.h"
#import "ResourceManager.h"
#import "WAVSoundSource.h"

#define DEFAULT_NUM_SOUNDS_SOURCES      (32)

// The maximum cache size, before the SoundSourceManager starts releasing old sounds
#define SOUND_SOURCE_MANAGER_CACHE_SIZE (256 * 1024)

// The watermark to which the SoundSourceManager will free sounds
#define SOUND_SOURCE_MANAGER_CACHE_WATERMARK (96 * 1024)

@implementation SoundSourceManager

-(SoundSourceManager*)Init
{
    mActiveSoundSources = [[NSMutableArray alloc] initWithCapacity:DEFAULT_NUM_SOUNDS_SOURCES];
    mInactiveSoundSources = [[NSMutableArray alloc] initWithCapacity:DEFAULT_NUM_SOUNDS_SOURCES];
    
    return self;
}

-(void)dealloc
{
    [mActiveSoundSources release];
    [mInactiveSoundSources release];
    
    [super dealloc];
}

-(void)Update:(CFTimeInterval)inTimeStep
{    
    NeonALError();
    
    int numActiveSoundSources = [mActiveSoundSources count];

    for (int curSoundSourceIndex = 0; curSoundSourceIndex < numActiveSoundSources; curSoundSourceIndex++)
    {
        SoundSource* curSoundSource = [mActiveSoundSources objectAtIndex:curSoundSourceIndex];

        NeonALError();
        [curSoundSource Update:inTimeStep];
        NeonALError();
        
        if ([curSoundSource GetSoundSourceState] == SOUND_SOURCE_STATE_FINISHED)
        {
            [curSoundSource retain];
            
            [mActiveSoundSources removeObjectAtIndex:curSoundSourceIndex];
            [mInactiveSoundSources insertObject:curSoundSource atIndex:0];
            
            [curSoundSource release];
            
            numActiveSoundSources--;
            curSoundSourceIndex--;
        }
    }
    
    NeonALError();
    
    int inactiveSizeBytes = 0;
    int numInactiveSoundSources = [mInactiveSoundSources count];
    
    for (int curSoundSourceIndex = 0; curSoundSourceIndex < numInactiveSoundSources; curSoundSourceIndex++)
    {
        SoundSource* curSoundSource = [mInactiveSoundSources objectAtIndex:curSoundSourceIndex];
        
        inactiveSizeBytes += [curSoundSource GetSizeBytes];
    }
    
    NeonALError();
    
    if (inactiveSizeBytes > SOUND_SOURCE_MANAGER_CACHE_SIZE)
    {
        for (int curSoundSourceIndex = (numInactiveSoundSources - 1); curSoundSourceIndex >= 0; curSoundSourceIndex--)
        {
            SoundSource* curSoundSource = [mInactiveSoundSources objectAtIndex:curSoundSourceIndex];
            
            inactiveSizeBytes -= [curSoundSource GetSizeBytes];
            
            NeonALError();
            [mInactiveSoundSources removeObjectAtIndex:curSoundSourceIndex];
            NeonALError();
            
            if (inactiveSizeBytes < SOUND_SOURCE_MANAGER_CACHE_WATERMARK)
            {
                break;
            }
        }
    }
    
    NeonALError();
}

-(SoundSource*)SoundSourceWithParams:(SoundSourceParams*)inParams
{
    // First check and see if any of the inactive sounds match.  If so, we can re-use it.
        
    int numInactiveSounds = [mInactiveSoundSources count];
    
    for (int curSoundSourceIndex = 0; curSoundSourceIndex < numInactiveSounds; curSoundSourceIndex++)
    {
        SoundSource* curSoundSource = [mInactiveSoundSources objectAtIndex:curSoundSourceIndex];
        
        SoundSourceParams* soundSourceParams = [curSoundSource GetSoundSourceParams];
        
        if ([soundSourceParams->mFilename caseInsensitiveCompare:inParams->mFilename] == NSOrderedSame)
        {
            [curSoundSource ResetWithParams:inParams initialCreation:FALSE];
            [curSoundSource SetSoundSourceState:SOUND_SOURCE_STATE_LOADED_ZOMBIE];
            
            [curSoundSource retain];
            
            [mInactiveSoundSources removeObjectAtIndex:curSoundSourceIndex];
            [mActiveSoundSources addObject:curSoundSource];
            
            [curSoundSource autorelease];
            
            return curSoundSource;
        }
    }
    
    NSNumber*   resourceHandle = [[ResourceManager GetInstance] LoadAssetWithName:inParams->mFilename];
    NSData*     soundData = [[ResourceManager GetInstance] GetDataForHandle:resourceHandle];

    SoundSource* retSoundSource = NULL;
    NSString* pathExtension = [inParams->mFilename pathExtension];
    
    if ([pathExtension caseInsensitiveCompare:@"wav"] == NSOrderedSame)
    {
        retSoundSource = [(WAVSoundSource*)[WAVSoundSource alloc] InitWithData:soundData params:inParams];
    }
    else
    {
        NSAssert(FALSE, @"Unknown sound source type");
    }
    
    [mActiveSoundSources addObject:retSoundSource];
    
    // The SoundSource manager already maintains a reference to this through the mSoundSources array.  So the caller
    // does not need to retain this to make sure it stays around.
    [retSoundSource autorelease];
    
    [[ResourceManager GetInstance] UnloadAssetWithHandle:resourceHandle];
    
    return retSoundSource;
}

-(void)StopSound:(SoundSource*)inSoundSource
{
    [inSoundSource retain];
    
    int index = [mActiveSoundSources indexOfObject:inSoundSource];
    NSAssert(index != NSNotFound, @"Sound source not found");
    
    [mActiveSoundSources removeObjectAtIndex:index];
    [mInactiveSoundSources insertObject:inSoundSource atIndex:0];
    
    [inSoundSource release];
    
    [inSoundSource SetSoundSourceState:SOUND_SOURCE_STATE_FINISHED];
    alSourceStop([inSoundSource GetSoundSourceId]);
}

-(void)StopAllSounds
{
    BOOL complete = FALSE;
    
    while(!complete)
    {
        if ([mActiveSoundSources count] > 0)
        {
            SoundSource* curSound = [mActiveSoundSources objectAtIndex:0];
            [self StopSound:curSound];
        }
        else
        {
            complete = TRUE;
        }
    }
}

@end