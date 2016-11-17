//
//  MixingDebugger.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameState.h"
#import "Button.h"
#import "StateMachine.h"

#import "PositionDirectionNavigator.h"

typedef struct
{
    float   mX;
    float   mY;
    char*   mText;
    u32     mButtonIdentifier;
} MixingButtonInitParams;

@class TextBox;
@class SoundSource;
@class DebugCamera;
@class UIList;
@class MixingDebuggerRootState;

@interface UISoundButtonListener : NSObject<ButtonListenerProtocol>
{
    MixingDebuggerRootState* mRootState;
}

-(UISoundButtonListener*)InitWithRootState:(MixingDebuggerRootState*)inState;
-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

@end

@interface MixingState : State
{
    NSMutableArray* mButtons;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Draw;
-(void)DrawOrtho;

-(Button*)GetButtonWithIdentifier:(u32)inIdentifier;

@end


@interface MixingDebuggerRootState : MixingState<ButtonListenerProtocol>
{
    TextBox* mMusicTextBox;
    TextBox* mMusicGainTextBox;
    
    TextBox* mUISoundTextBox;
    TextBox* mUISoundGainTextBox;
    
    TextBox* mCurrentlyPlayingLabel;
    TextBox* mCurrentlyPlayingFilename;
    
    UIList*  mUISoundList;
    UISoundButtonListener* mUISoundListener;
    
    NSString* mCurUISoundPath;
    
    u32      mActiveButtonIdentifier;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)CommonInit;
-(void)CommonDeinit;

-(void)PlaySong;
-(void)StopSong;

-(void)PlayUISound;
-(void)StopUISound;

-(void)SetUISoundPath:(NSString*)inPath;

-(void)CreateUISoundList;

-(void)Update:(CFTimeInterval)inTimeStep;

@end


@interface MixingDebuggerManipulateCamera : MixingState<ButtonListenerProtocol>
{
    DebugCamera*                mDebugCamera;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)Update:(CFTimeInterval)inTimeStep;

@end


@interface MixingDebuggerManipulate3DSound : MixingState<ButtonListenerProtocol>
{
    u32         mActiveButtonIdentifier;
    
    TextBox*    m3DSoundLabel;
    TextBox*    m3DSoundGainLabel;
    TextBox*    m3DSoundRefDistanceLabel;
    TextBox*    m3DSoundRefDistance;
    TextBox*    m3DSoundRolloffFactorLabel;
    TextBox*    m3DSoundRolloffFactor;
        
    PositionDirectionNavigator*    m3DSoundNavigator;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(void)Play3DSound;
-(void)Stop3DSound;

-(void)Hide3DSoundUI;
-(void)Show3DSoundUI;

@end


@interface MixingDebuggerStateMachine : StateMachine
{
    SoundSource* mUISoundSource;
    SoundSource* m3DSoundSource;
    
    BOOL     mMusicPlaying;
    BOOL     mUISoundPlaying;
    BOOL     m3DSoundPlaying;
}

-(MixingDebuggerStateMachine*)Init;
-(void)dealloc;

-(SoundSource*)GetUISoundSource;
-(void)SetUISoundSource:(SoundSource*)inSoundSource;

-(SoundSource*)Get3DSoundSource;
-(void)Set3DSoundSource:(SoundSource*)inSoundSource;

-(BOOL)GetMusicPlaying;
-(void)SetMusicPlaying:(BOOL)inPlaying;

-(BOOL)GetUISoundPlaying;
-(void)SetUISoundPlaying:(BOOL)inPlaying;

-(BOOL)Get3DSoundPlaying;
-(void)Set3DSoundPlaying:(BOOL)inPlaying;

+(void)CreateButtons:(MixingButtonInitParams*)inButtonParams numButtons:(int)inNumButtons
        referenceArray:(NSMutableArray*)inReferenceArray listener:(NSObject<ButtonListenerProtocol>*)inListener;
+(void)RemoveButtons:(NSMutableArray*)inButtonArray;

-(void)DrawOrtho;
-(void)Draw3DSoundSource;
-(void)Draw;

@end



@interface MixingDebugger : GameState
{            
    MixingDebuggerStateMachine* mMixingDebuggerStateMachine;
}

-(void)Startup;
-(void)Resume;
-(void)Shutdown;
-(void)Suspend;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;
-(void)Draw;

@end