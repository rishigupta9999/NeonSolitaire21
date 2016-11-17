//
//  AudioSessionManager.m
//  Neon21
//
//  Copyright Neon Games 2011. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "AudioSessionManager.h"
#import "NeonMusicPlayer.h"
#import "SoundPlayer.h"

static AudioSessionManager* sInstance = NULL;

void interruptionListener(	void *	inClientData,
							UInt32	inInterruptionState)
{
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
        [[NeonMusicPlayer GetInstance] HandleInterruption:TRUE];
        [[SoundPlayer GetInstance] HandleInterruption:TRUE];
        
        OSStatus result = AudioSessionSetActive(false);
        
        if (result != kAudioSessionNoError)
        {
            NSLog(@"Error setting the audio session inactive! %ld\n", result);
        }
	}
	else if (inInterruptionState == kAudioSessionEndInterruption)
	{
        OSStatus result = AudioSessionSetActive(true);
        
		if (result != kAudioSessionNoError)
        {
            NSLog(@"Error setting audio session active! %ld\n", result);
        }
        
        [[NeonMusicPlayer GetInstance] HandleInterruption:FALSE];
        [[SoundPlayer GetInstance] HandleInterruption:FALSE];
	}
}

@implementation AudioSessionManager

-(AudioSessionManager*)Init
{
    OSStatus result = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
    NSAssert(result == kAudioSessionNoError, @"There was an error initialing the audio session");
    
    u32 category = kAudioSessionCategory_AmbientSound;	
    result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
	NSAssert(result == kAudioSessionNoError, @"There was an error setting the audio category");
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create AudioSessionManager");
    sInstance = [(AudioSessionManager*)[AudioSessionManager alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to delete AudioSession when it is already destroyed");
    [sInstance release];
}

+(AudioSessionManager*)GetInstance
{
    return sInstance;
}


@end