//
//  MixingDebugger.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "MixingDebugger.h"
#import "NeonMusicPlayer.h"
#import "SoundPlayer.h"
#import "UISounds.h"
#import "UIList.h"
#import "SoundSource.h"
#import "SoundPlayer.h"

#import "GameObjectManager.h"

#import "TextBox.h"
#import "TextTextureBuilder.h"

#import "CameraStateMgr.h"
#import "DebugCamera.h"
#import "CameraUVN.h"

#define MUSIC_DECREASE_VOLUME   ('MUDV')
#define MUSIC_PLAY_PAUSE        ('MUPP')
#define MUSIC_INCREASE_VOLUME   ('MUIV')

#define UI_SOUND_DECREASE_VOLUME ('UIDV')
#define UI_SOUND_PLAY_PAUSE      ('UIPP')
#define UI_SOUND_INCREASE_VOLUME ('UIIV')

#define MOVE_CAMERA             ('MCAM')
#define MOVE_LISTENER           ('MLIS')
#define MANIPULATE_3D_SOUNDS    ('M3DS')

#define MUSIC_PLAYER_VOLUME_STEP        (0.025f)
#define UI_SOUND_VOLUME_STEP            (0.025f)
#define THREE_D_SOUND_VOLUME_STEP       (0.025f)
#define THREE_D_SOUND_REFERENCE_STEP    (0.10f)
#define THREE_D_SOUND_ROLLOFF_STEP      (0.10f)

static const char* PLAY_STRING = ">";
static const char* PAUSE_STRING = "//";
static const char* DEFAULT_UI_SOUND_FILENAME = "n21sting_win.wav";

static MixingButtonInitParams sRootButtons[] = {{ 110.0f, 10.0f, "-", MUSIC_DECREASE_VOLUME },
                                                { 160.0f, 10.0f, ">", MUSIC_PLAY_PAUSE },
                                                { 210.0f, 10.0f, "+", MUSIC_INCREASE_VOLUME },
                                                { 110.0f, 60.0f, "-", UI_SOUND_DECREASE_VOLUME },
                                                { 160.0f, 60.0f, ">", UI_SOUND_PLAY_PAUSE },
                                                { 210.0f, 60.0f, "+", UI_SOUND_INCREASE_VOLUME},
                                                { 10.0f, 110.0f, "Move Camera", MOVE_CAMERA},
                                                { 10.0f, 135.0f, "Move Listener", MOVE_LISTENER},
                                                { 10.0f, 160.0f, "3D Sounds", MANIPULATE_3D_SOUNDS} };
                                                                    
#define MID_BUTTON_LENGTH       (4)
#define LONG_BUTTON_LENGTH      (10)

#define GetStateMachine()   ((MixingDebuggerStateMachine*)mStateMachine)


@implementation UISoundButtonListener

-(UISoundButtonListener*)InitWithRootState:(MixingDebuggerRootState*)inState
{
    mRootState = inState;
    
    return self;
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    [mRootState SetUISoundPath:(NSString*)(inButton->mIdentifier)];
}

@end

@implementation MixingState

-(void)Startup
{
    mButtons = [[NSMutableArray alloc] initWithCapacity:0];
}

-(void)Resume
{
}

-(void)Shutdown
{
    [mButtons release];
}

-(void)Suspend
{
}

-(void)Draw
{
}

-(void)DrawOrtho
{
}

-(Button*)GetButtonWithIdentifier:(u32)inIdentifier
{
    for (Button* curButton in mButtons)
    {
        if (curButton->mIdentifier == inIdentifier)
        {
            return curButton;
        }
    }
    
    return NULL;
}

@end


@implementation MixingDebuggerRootState

-(void)Startup
{
    [super Startup];
    [self CommonInit];
}

-(void)Resume
{
    [super Resume];
    [self CommonInit];
}

-(void)Shutdown
{    
    [self CommonDeinit];
    [super Shutdown];
}

-(void)Suspend
{
    [self CommonDeinit];
    [super Suspend];
}

-(void)CommonInit
{
    TextBoxParams textBoxParams;
    
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mString = @"Music";
    textBoxParams.mFontType = NEON_FONT_STYLISH;
    textBoxParams.mFontSize = 18;
    textBoxParams.mStrokeSize = 2;
    SetColorFloat(&textBoxParams.mColor, 1.0f, 1.0f, 1.0f, 1.0f);
    SetColorFloat(&textBoxParams.mStrokeColor, 0.0f, 0.0f, 0.0f, 1.0f);
    
    mMusicTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [mMusicTextBox SetPositionX:10.0f Y:10.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:mMusicTextBox];
    [mMusicTextBox release];
    
    
    textBoxParams.mString = [NSString stringWithFormat:@"Gain: %.3f", [[NeonMusicPlayer GetInstance] GetGain]];
    mMusicGainTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [mMusicGainTextBox SetPositionX:10.0f Y:35.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:mMusicGainTextBox];
    [mMusicGainTextBox release];
    
    
    textBoxParams.mString = @"UI Snd";
    mUISoundTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [mUISoundTextBox SetPositionX:10.0f Y:60.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:mUISoundTextBox];
    [mUISoundTextBox release];
    
    float gain = sSoundSourceGain[SOUND_SOURCE_TYPE_UI];
    SoundSource* uiSoundSource = [GetStateMachine() GetUISoundSource];
    
    if (uiSoundSource != NULL)
    {
        gain = [uiSoundSource GetAbsoluteGain];
    }
    
    textBoxParams.mString = [NSString stringWithFormat:@"Gain: %.3f", gain];
    mUISoundGainTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [mUISoundGainTextBox SetPositionX:10.0f Y:85.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:mUISoundGainTextBox];
    [mUISoundGainTextBox release];
    
    
    textBoxParams.mFontType = NEON_FONT_NORMAL;
    textBoxParams.mFontSize = 12;
    textBoxParams.mStrokeSize = 1;
    textBoxParams.mString = [NSString stringWithFormat:@"Cur UI Snd: %f", gain];
    mCurrentlyPlayingLabel = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [mCurrentlyPlayingLabel SetPositionX:220.0f Y:60.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:mCurrentlyPlayingLabel];
    [mCurrentlyPlayingLabel release];

    
    textBoxParams.mString = [NSString stringWithUTF8String:DEFAULT_UI_SOUND_FILENAME];
    mCurrentlyPlayingFilename = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [mCurrentlyPlayingFilename SetPositionX:220.0f + [mCurrentlyPlayingLabel GetWidth] Y:60.0f Z:0.0f];

    [[GameObjectManager GetInstance] Add:mCurrentlyPlayingFilename];
    [mCurrentlyPlayingFilename release];

    
    [MixingDebuggerStateMachine CreateButtons:sRootButtons numButtons:(sizeof(sRootButtons) / sizeof(MixingButtonInitParams))
                                    referenceArray:mButtons listener:self];
    
    if (![GetStateMachine() GetMusicPlaying])
    {
        [[self GetButtonWithIdentifier:MUSIC_DECREASE_VOLUME] Disable];
        [[self GetButtonWithIdentifier:MUSIC_INCREASE_VOLUME] Disable];
    }
    else
    {
        [(TextureButton*)[self GetButtonWithIdentifier:MUSIC_PLAY_PAUSE] SetText:[NSString stringWithUTF8String:PAUSE_STRING]];
    }
    
    if (![GetStateMachine() GetUISoundPlaying])
    {
        [[self GetButtonWithIdentifier:UI_SOUND_DECREASE_VOLUME] Disable];
        [[self GetButtonWithIdentifier:UI_SOUND_INCREASE_VOLUME] Disable];
    }
    else
    {
        [(TextureButton*)[self GetButtonWithIdentifier:UI_SOUND_PLAY_PAUSE] SetText:[NSString stringWithUTF8String:PAUSE_STRING]];
    }

    mActiveButtonIdentifier = 0;
    
    mUISoundListener = [[UISoundButtonListener alloc] InitWithRootState:self];
    [self CreateUISoundList];
    mCurUISoundPath = [[NSString alloc] initWithUTF8String:DEFAULT_UI_SOUND_FILENAME];
}

-(void)CommonDeinit
{
    [mMusicGainTextBox Remove];
    [mMusicTextBox Remove];
    
    [mUISoundTextBox Remove];
    [mUISoundGainTextBox Remove];
    
    // All buttons corresponding to UISounds are holding a reference to the pathname of that sound
    u32 numObjects = [mUISoundList GetNumObjects];
    
    for (int i = 0; i < numObjects; i++)
    {
        UIObject* curObject = [mUISoundList GetObjectAtIndex:i];
        [((NSString*)curObject->mIdentifier) release];
    }
    
    [mUISoundList Remove];
    [mUISoundListener release];
    
    [mCurUISoundPath release];
    
    [mCurrentlyPlayingLabel Remove];
    [mCurrentlyPlayingFilename Remove];
    
    [MixingDebuggerStateMachine RemoveButtons:mButtons];
    [mButtons removeAllObjects];
}

-(void)CreateUISoundList
{
    NSMutableArray* filesArray = [[ResourceManager GetInstance] FilesWithExtension:@"wav"];
    
    UIListParams listParams;
    
    [UIList InitDefaultParams:&listParams];
    
    listParams.mBoundingDims.mVector[x] = 200.0f;
    listParams.mBoundingDims.mVector[y] = 200.0f;
    
    mUISoundList = [(UIList*)[UIList alloc] InitWithParams:&listParams];
    [mUISoundList SetPositionX:0.0 Y:0.0 Z:0];
    
    TextureButtonParams buttonParams;
    
    [TextureButton InitDefaultParams:&buttonParams];
    
    buttonParams.mButtonTexBaseName = @"editorbutton_large.png";
    buttonParams.mButtonTexHighlightedName = @"editorbutton_large_lit.png";
    buttonParams.mFontSize = 14;
    buttonParams.mFontColor = 0xFF000000;
    
    int count = 0;
    
    for (NSString* curFile in filesArray)
    {
        buttonParams.mButtonText = [curFile lastPathComponent];
        TextureButton* newButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
        
        [newButton SetPositionX:200 Y:(200 + (count * 20.0)) Z:0.0];
        newButton->mIdentifier = (u32)curFile;
        [curFile retain];
        
        [newButton SetListener:mUISoundListener];
        
        [mUISoundList AddObject:newButton];
        
        count++;
    }
    
    [mUISoundList SetPositionX:220.0f Y:85.0f Z:0.0f];
    
    [mUISoundList SetVisible:TRUE];
    [mUISoundList Enable];
    
    [[GameObjectManager GetInstance] Add:mUISoundList];
    [mUISoundList release];
}

-(void)PlaySong
{
    MusicPlayerParams musicPlayerParams;
    [NeonMusicPlayer InitDefaultParams:&musicPlayerParams];
    
    musicPlayerParams.mFilename = @"BG_MainMenu.mp3";
    musicPlayerParams.mLoop = TRUE;
    musicPlayerParams.mFadeInTime = 0.0f;
    musicPlayerParams.mTrimSilence = TRUE;
    
    [[NeonMusicPlayer GetInstance] PlaySongWithParams:&musicPlayerParams];
    
    [[self GetButtonWithIdentifier:MUSIC_INCREASE_VOLUME] Enable];
    [[self GetButtonWithIdentifier:MUSIC_DECREASE_VOLUME] Enable];
}

-(void)StopSong
{
    [[NeonMusicPlayer GetInstance] Stop:1.0f];
    
    [[self GetButtonWithIdentifier:MUSIC_INCREASE_VOLUME] Disable];
    [[self GetButtonWithIdentifier:MUSIC_DECREASE_VOLUME] Disable];
}

-(void)PlayUISound
{
    UISoundParams params;
    [UISounds InitDefaultParams:&params];
    
    params.mLoop = TRUE;
    
    SoundSource* uiSoundSource = [UISounds PlayUISoundWithFilename:[mCurUISoundPath lastPathComponent] withParams:&params];
    
    [GetStateMachine() SetUISoundSource:uiSoundSource];
    
    float gain = [uiSoundSource GetAbsoluteGain];
    
    if (gain < 1.0f)
    {
        [[self GetButtonWithIdentifier:UI_SOUND_INCREASE_VOLUME] Enable];
    }
    
    if (gain > 0.0f)
    {
        [[self GetButtonWithIdentifier:UI_SOUND_DECREASE_VOLUME] Enable];
    }
}

-(void)StopUISound
{
    [[SoundPlayer GetInstance] StopSound:[GetStateMachine() GetUISoundSource]];
    
    [[self GetButtonWithIdentifier:UI_SOUND_INCREASE_VOLUME] Disable];
    [[self GetButtonWithIdentifier:UI_SOUND_DECREASE_VOLUME] Disable];
}

-(void)SetUISoundPath:(NSString*)inPath
{
    [mCurUISoundPath release];
    mCurUISoundPath = inPath;
    
    [mCurrentlyPlayingFilename SetString:[inPath lastPathComponent]];
    
    [mCurUISoundPath retain];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        mActiveButtonIdentifier = 0;
        switch(inButton->mIdentifier)
        {
            case MUSIC_PLAY_PAUSE:
            {
                if (![GetStateMachine() GetMusicPlaying])
                {
                    [GetStateMachine() SetMusicPlaying:TRUE];
                    [self PlaySong];
                    
                    TextureButton* playPauseButton = (TextureButton*)[self GetButtonWithIdentifier:MUSIC_PLAY_PAUSE];
                    [playPauseButton SetText:[NSString stringWithUTF8String:PAUSE_STRING]];
                }
                else
                {
                    [GetStateMachine() SetMusicPlaying:FALSE];
                    [self StopSong];
                    
                    TextureButton* playPauseButton = (TextureButton*)[self GetButtonWithIdentifier:MUSIC_PLAY_PAUSE];
                    [playPauseButton SetText:[NSString stringWithUTF8String:PLAY_STRING]];
                }
                
                break;
            }
            
            case UI_SOUND_PLAY_PAUSE:
            {
                if (![GetStateMachine() GetUISoundPlaying])
                {
                    [GetStateMachine() SetUISoundPlaying:TRUE];
                    [self PlayUISound];
                    
                    TextureButton* playPauseButton = (TextureButton*)[self GetButtonWithIdentifier:UI_SOUND_PLAY_PAUSE];
                    [playPauseButton SetText:[NSString stringWithUTF8String:PAUSE_STRING]];
                }
                else
                {
                    [GetStateMachine() SetUISoundPlaying:FALSE];
                    [self StopUISound];
                    
                    TextureButton* playPauseButton = (TextureButton*)[self GetButtonWithIdentifier:UI_SOUND_PLAY_PAUSE];
                    [playPauseButton SetText:[NSString stringWithUTF8String:PLAY_STRING]];
                }
                
                break;
            }
            
            case MOVE_CAMERA:
            {
                [GetStateMachine() Push:[MixingDebuggerManipulateCamera alloc]];
                break;
            }
            
            case MANIPULATE_3D_SOUNDS:
            {
                [GetStateMachine() Push:[MixingDebuggerManipulate3DSound alloc]];
                break;
            }
        }
    }
    else if (inEvent == BUTTON_EVENT_DOWN)
    {
        switch(inButton->mIdentifier)
        {
            case MUSIC_INCREASE_VOLUME:
            case MUSIC_DECREASE_VOLUME:
            case UI_SOUND_INCREASE_VOLUME:
            case UI_SOUND_DECREASE_VOLUME:
            {
                mActiveButtonIdentifier = inButton->mIdentifier;
                break;
            }
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    SoundSource* uiSoundSource = [GetStateMachine() GetUISoundSource];

    if (mActiveButtonIdentifier != 0)
    {
        switch(mActiveButtonIdentifier)
        {
            case MUSIC_INCREASE_VOLUME:
            {
                float curGain = [[NeonMusicPlayer GetInstance] GetGain];
                float newGain = curGain + MUSIC_PLAYER_VOLUME_STEP;
                
                [[NeonMusicPlayer GetInstance] SetGain:newGain];
                [mMusicGainTextBox SetString:[NSString stringWithFormat:@"Gain: %.3f", newGain]];
                
                break;
            }
            
            case MUSIC_DECREASE_VOLUME:
            {
                float curGain = [[NeonMusicPlayer GetInstance] GetGain];
                float newGain = max(0.0f, curGain - MUSIC_PLAYER_VOLUME_STEP);
                
                [[NeonMusicPlayer GetInstance] SetGain:newGain];
                [mMusicGainTextBox SetString:[NSString stringWithFormat:@"Gain: %.3f", newGain]];
                
                break;
            }
            
            case UI_SOUND_INCREASE_VOLUME:
            {
                float curGain = [uiSoundSource GetGain];
                float newGain = curGain + UI_SOUND_VOLUME_STEP;
                
                [uiSoundSource SetAbsoluteGain:newGain];
                [mUISoundGainTextBox SetString:[NSString stringWithFormat:@"Gain: %.3f", [uiSoundSource GetAbsoluteGain]]];
                break;
            }
            
            case UI_SOUND_DECREASE_VOLUME:
            {
                float curGain = [uiSoundSource GetGain];
                float newGain = max(0.0f, curGain - UI_SOUND_VOLUME_STEP);
                
                [uiSoundSource SetAbsoluteGain:newGain];
                [mUISoundGainTextBox SetString:[NSString stringWithFormat:@"Gain: %.3f", [uiSoundSource GetAbsoluteGain]]];
                break;
            }
        }
    
        Button* increaseVolumeButton = [self GetButtonWithIdentifier:UI_SOUND_INCREASE_VOLUME];
        Button* decreaseVolumeButton = [self GetButtonWithIdentifier:UI_SOUND_DECREASE_VOLUME];

        if ((uiSoundSource != NULL) && ([GetStateMachine() GetUISoundPlaying]))
        {
            if ([uiSoundSource GetAbsoluteGain] >= 1.0)
            {
                if ([increaseVolumeButton GetState] != UI_OBJECT_STATE_DISABLED)
                {
                    [increaseVolumeButton Disable];
                }
            }
            else
            {
                // Guard these calls because if the state is highlighted, we don't want to call Enable again.
                if ([increaseVolumeButton GetState] == UI_OBJECT_STATE_DISABLED)
                {
                    [increaseVolumeButton Enable];
                }
            }
            
            if ([uiSoundSource GetAbsoluteGain] <= 0.0)
            {
                if ([decreaseVolumeButton GetState] != UI_OBJECT_STATE_DISABLED)
                {
                    [decreaseVolumeButton Disable];
                }
            }
            else
            {
                if ([decreaseVolumeButton GetState] == UI_OBJECT_STATE_DISABLED)
                {
                    [decreaseVolumeButton Enable];
                }
            }
        }
    }
}

@end

#define CAMERA_BACK ('CABA')

static MixingButtonInitParams sCameraButtons[] = { { 325.0f, 295.0f, "Back", CAMERA_BACK } };

@implementation MixingDebuggerManipulateCamera

-(void)Startup
{
    [super Startup];
    
    [MixingDebuggerStateMachine CreateButtons:sCameraButtons numButtons:(sizeof(sCameraButtons) / sizeof(MixingButtonInitParams))
        referenceArray:mButtons listener:self];
        
	Camera* activeCamera = [[[CameraStateMgr GetInstance] GetActiveState] GetActiveCamera];
	NSAssert(([activeCamera class] == [CameraUVN class]), @"Active camera must be a UVN camera");
	
    mDebugCamera = [[DebugCamera alloc] InitWithCamera:(CameraUVN*)activeCamera];
}

-(void)Resume
{
    [super Resume];
}

-(void)Shutdown
{
    [MixingDebuggerStateMachine RemoveButtons:mButtons];
    [mDebugCamera release];
    
    [super Shutdown];
}

-(void)Suspend
{
    [super Suspend];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            switch(inButton->mIdentifier)
            {
                case CAMERA_BACK:
                {
                    [GetStateMachine() Pop];
                    break;
                }
            }
        }
        
        default:
        {
            break;
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mDebugCamera Update:inTimeStep];
}

@end

#define THREE_D_SOUND_DECREASE_VOLUME       ('3DDV')
#define THREE_D_SOUND_PLAY_PAUSE            ('3DPP')
#define THREE_D_SOUND_INCREASE_VOLUME       ('3DIV')
#define THREE_D_SOUND_ZERO_DIRECTION        ('3DZD')
#define THREE_D_SOUND_INCREASE_REF_DISTANCE ('3DIR')
#define THREE_D_SOUND_DECREASE_REF_DISTANCE ('3DDR')
#define THREE_D_SOUND_INCREASE_ROLLOFF      ('3DIF')
#define THREE_D_SOUND_DECREASE_ROLLOFF      ('3DDF')
#define THREE_D_SOUND_BACK                  ('3DBA')

MixingButtonInitParams  s3DSoundParams[] = {{ 140.0f, 10.0f, "-", THREE_D_SOUND_DECREASE_VOLUME },
                                            { 190.0f, 10.0f, ">", THREE_D_SOUND_PLAY_PAUSE },
                                            { 240.0f, 10.0f, "+", THREE_D_SOUND_INCREASE_VOLUME },
                                            { 140.0f, 60.0f, "-", THREE_D_SOUND_DECREASE_REF_DISTANCE },
                                            { 240.0f, 60.0f, "+", THREE_D_SOUND_INCREASE_REF_DISTANCE },
                                            { 140.0f, 85.0f, "-", THREE_D_SOUND_DECREASE_ROLLOFF },
                                            { 240.0f, 85.0f, "+", THREE_D_SOUND_INCREASE_ROLLOFF },
                                            { 10.0f,  110.0f, "Zero Direction", THREE_D_SOUND_ZERO_DIRECTION },
                                            { 325.0f, 295.0f, "Back", THREE_D_SOUND_BACK }};

@implementation MixingDebuggerManipulate3DSound

-(void)Startup
{
    [super Startup];
            
    TextBoxParams textBoxParams;
    
    [TextBox InitDefaultParams:&textBoxParams];
    
    textBoxParams.mString = @"3D Sound";
    textBoxParams.mFontType = NEON_FONT_STYLISH;
    textBoxParams.mFontSize = 18;
    textBoxParams.mStrokeSize = 2;
    SetColorFloat(&textBoxParams.mColor, 1.0f, 1.0f, 1.0f, 1.0f);
    SetColorFloat(&textBoxParams.mStrokeColor, 0.0f, 0.0f, 0.0f, 1.0f);
    
    m3DSoundLabel = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [m3DSoundLabel SetPositionX:10.0f Y:10.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:m3DSoundLabel];
    [m3DSoundLabel release];
    
    
    textBoxParams.mString = @"Ref Dist";
    
    m3DSoundRefDistanceLabel = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [m3DSoundRefDistanceLabel SetPositionX:10.0f Y:60.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:m3DSoundRefDistanceLabel];
    [m3DSoundRefDistanceLabel release];
    
    
    textBoxParams.mString = @"Rolloff";
    
    m3DSoundRolloffFactorLabel = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [m3DSoundRolloffFactorLabel SetPositionX:10.0f Y:85.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:m3DSoundRolloffFactorLabel];
    [m3DSoundRolloffFactorLabel release];

    
    float gain = sSoundSourceGain[SOUND_SOURCE_TYPE_3D];
    SoundSource* threeDSoundSource = [GetStateMachine() Get3DSoundSource];
    
    if (threeDSoundSource != NULL)
    {
        gain = [threeDSoundSource GetAbsoluteGain];
    }
    
    textBoxParams.mString = [NSString stringWithFormat:@"Gain: %.3f", gain];
    m3DSoundGainLabel = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [m3DSoundGainLabel SetPositionX:10.0f Y:35.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:m3DSoundGainLabel];
    [m3DSoundGainLabel release];
    
    
    float refDistance = 1.0f;
    
    if (threeDSoundSource != NULL)
    {
        refDistance = [threeDSoundSource GetReferenceDistance];
    }
    
    textBoxParams.mFontSize = 12;
    textBoxParams.mString = [NSString stringWithFormat:@"%.1f", refDistance];
    m3DSoundRefDistance = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [m3DSoundRefDistance SetPositionX:190.0f Y:65.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:m3DSoundRefDistance];
    [m3DSoundRefDistance release];
    
    
    float rolloff = 1.0f;
    
    if (threeDSoundSource != NULL)
    {
        rolloff = [threeDSoundSource GetRolloffFactor];
    }
    
    textBoxParams.mFontSize = 12;
    textBoxParams.mString = [NSString stringWithFormat:@"%.1f", refDistance];
    m3DSoundRolloffFactor = [(TextBox*)[TextBox alloc] InitWithParams:&textBoxParams];
    
    [m3DSoundRolloffFactor SetPositionX:190.0f Y:90.0f Z:0.0f];
    
    [[GameObjectManager GetInstance] Add:m3DSoundRolloffFactor];
    [m3DSoundRolloffFactor release];


    [MixingDebuggerStateMachine CreateButtons:s3DSoundParams numButtons:(sizeof(s3DSoundParams) / sizeof(MixingButtonInitParams))
        referenceArray:mButtons listener:self];

    if (![GetStateMachine() Get3DSoundPlaying])
    {
        [self Hide3DSoundUI];
    }
    else
    {
        [(TextureButton*)[self GetButtonWithIdentifier:THREE_D_SOUND_PLAY_PAUSE]
            SetText:[NSString stringWithUTF8String:PAUSE_STRING]];
    }
    
    mActiveButtonIdentifier = 0;
    
    SoundSource* soundSource = [GetStateMachine() Get3DSoundSource];
    
    if (soundSource != NULL)
    {
        PositionDirectionNavigatorParams navigatorParams;
        [PositionDirectionNavigator InitDefaultParams:&navigatorParams];
        
        navigatorParams.mTargetPosition = &soundSource->mPosition;
        navigatorParams.mTargetDirection = &soundSource->mDirection;

        m3DSoundNavigator = [(PositionDirectionNavigator*)[PositionDirectionNavigator alloc] InitWithParams:&navigatorParams];
    }
    else
    {
        m3DSoundNavigator = NULL;
    }
}

-(void)Resume
{
    [super Resume];
}

-(void)Shutdown
{
    [MixingDebuggerStateMachine RemoveButtons:mButtons];
    [[GameObjectManager GetInstance] Remove:m3DSoundLabel];
    [[GameObjectManager GetInstance] Remove:m3DSoundGainLabel];
    [[GameObjectManager GetInstance] Remove:m3DSoundRefDistanceLabel];
    [[GameObjectManager GetInstance] Remove:m3DSoundRefDistance];
    [[GameObjectManager GetInstance] Remove:m3DSoundRolloffFactorLabel];
    [[GameObjectManager GetInstance] Remove:m3DSoundRolloffFactor];

    [m3DSoundNavigator release];
    
    [super Shutdown];
}

-(void)Suspend
{
    [super Suspend];
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    switch(inEvent)
    {
        case BUTTON_EVENT_UP:
        {
            mActiveButtonIdentifier = 0;

            switch(inButton->mIdentifier)
            {
                case THREE_D_SOUND_PLAY_PAUSE:
                {
                    if (![GetStateMachine() Get3DSoundPlaying])
                    {
                        [self Play3DSound];
                        
                        TextureButton* playPauseButton = (TextureButton*)[self GetButtonWithIdentifier:THREE_D_SOUND_PLAY_PAUSE];
                        [playPauseButton SetText:[NSString stringWithUTF8String:PAUSE_STRING]];

                    }
                    else
                    {
                        [self Stop3DSound];
                        
                        TextureButton* playPauseButton = (TextureButton*)[self GetButtonWithIdentifier:THREE_D_SOUND_PLAY_PAUSE];
                        [playPauseButton SetText:[NSString stringWithUTF8String:PLAY_STRING]];
                    }
                    
                    break;
                }
                
                case THREE_D_SOUND_ZERO_DIRECTION:
                {
                    SoundSource* soundSource = [GetStateMachine() Get3DSoundSource];
                    Set(&soundSource->mDirection, 0.0f, 0.0f, 0.0f);
                    
                    // Indicate that we have changed what the navigator is driving out from under it.  It will need
                    // to resync its state to the target vectors.
                    [m3DSoundNavigator Resync];
                    
                    break;
                }
                
                case THREE_D_SOUND_BACK:
                {
                    [GetStateMachine() Pop];
                    break;
                }
            }
            
            break;
        }
        
        case BUTTON_EVENT_DOWN:
        {
            switch(inButton->mIdentifier)
            {
                case THREE_D_SOUND_INCREASE_VOLUME:
                case THREE_D_SOUND_DECREASE_VOLUME:
                case THREE_D_SOUND_DECREASE_REF_DISTANCE:
                case THREE_D_SOUND_INCREASE_REF_DISTANCE:
                case THREE_D_SOUND_DECREASE_ROLLOFF:
                case THREE_D_SOUND_INCREASE_ROLLOFF:
                {
                    mActiveButtonIdentifier = inButton->mIdentifier;
                    break;
                }
            }
            
            break;
        }
        
        default:
        {
            break;
        }
    }
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    SoundSource* threeDSoundSource = [GetStateMachine() Get3DSoundSource];
    
    if (mActiveButtonIdentifier != 0)
    {
        switch(mActiveButtonIdentifier)
        {
            case THREE_D_SOUND_INCREASE_VOLUME:
            {
                float curGain = [threeDSoundSource GetGain];
                float newGain = curGain + THREE_D_SOUND_VOLUME_STEP;
                
                [threeDSoundSource SetAbsoluteGain:newGain];
                [m3DSoundGainLabel SetString:[NSString stringWithFormat:@"Gain: %.3f", [threeDSoundSource GetAbsoluteGain]]];
                break;
            }
            
            case THREE_D_SOUND_DECREASE_VOLUME:
            {
                float curGain = [threeDSoundSource GetGain];
                float newGain = max(0.0f, curGain - THREE_D_SOUND_VOLUME_STEP);
                
                [threeDSoundSource SetAbsoluteGain:newGain];
                [m3DSoundGainLabel SetString:[NSString stringWithFormat:@"Gain: %.3f", [threeDSoundSource GetAbsoluteGain]]];
                break;
            }
            
            case THREE_D_SOUND_INCREASE_REF_DISTANCE:
            {
                float curRefDistance = [threeDSoundSource GetReferenceDistance];
                [threeDSoundSource SetReferenceDistance:(curRefDistance + THREE_D_SOUND_REFERENCE_STEP)];
                
                [m3DSoundRefDistance SetString:[NSString stringWithFormat:@"%.1f", curRefDistance]];
                break;
            }
            
            case THREE_D_SOUND_DECREASE_REF_DISTANCE:
            {
                float curRefDistance = [threeDSoundSource GetReferenceDistance];
                float newRefDistance = max(0.0f, curRefDistance - THREE_D_SOUND_REFERENCE_STEP);
                [threeDSoundSource SetReferenceDistance:newRefDistance];
                
                [m3DSoundRefDistance SetString:[NSString stringWithFormat:@"%.1f", curRefDistance]];
                break;
            }
            
            case THREE_D_SOUND_INCREASE_ROLLOFF:
            {
                float curRolloff = [threeDSoundSource GetRolloffFactor];
                [threeDSoundSource SetRolloffFactor:(curRolloff + THREE_D_SOUND_ROLLOFF_STEP)];
                
                [m3DSoundRolloffFactor SetString:[NSString stringWithFormat:@"%.1f", curRolloff + THREE_D_SOUND_ROLLOFF_STEP]];
                break;
            }
            
            case THREE_D_SOUND_DECREASE_ROLLOFF:
            {
                float curRolloff = [threeDSoundSource GetRolloffFactor];
                float newRolloff = max(0.0f, curRolloff - THREE_D_SOUND_ROLLOFF_STEP);
                
                [threeDSoundSource SetRolloffFactor:newRolloff];
                
                [m3DSoundRolloffFactor SetString:[NSString stringWithFormat:@"%.1f", newRolloff]];
                break;
            }
        }
    
        Button* increaseVolumeButton = [self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_VOLUME];
        Button* decreaseVolumeButton = [self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_VOLUME];

        if ((threeDSoundSource != NULL) && ([GetStateMachine() Get3DSoundPlaying]))
        {
            if ([threeDSoundSource GetAbsoluteGain] >= 1.0)
            {
                if ([increaseVolumeButton GetState] != UI_OBJECT_STATE_DISABLED)
                {
                    [increaseVolumeButton Disable];
                }
            }
            else
            {
                // Guard these calls because if the state is highlighted, we don't want to call Enable again.
                if ([increaseVolumeButton GetState] == UI_OBJECT_STATE_DISABLED)
                {
                    [increaseVolumeButton Enable];
                }
            }
            
            if ([threeDSoundSource GetAbsoluteGain] <= 0.0)
            {
                if ([decreaseVolumeButton GetState] != UI_OBJECT_STATE_DISABLED)
                {
                    [decreaseVolumeButton Disable];
                }
            }
            else
            {
                if ([decreaseVolumeButton GetState] == UI_OBJECT_STATE_DISABLED)
                {
                    [decreaseVolumeButton Enable];
                }
            }
        }
    }
    
    if (m3DSoundNavigator != NULL)
    {
        [m3DSoundNavigator Update:inTimeStep];
    }
}

-(void)Play3DSound
{
    SoundSourceParams soundSourceParams;
    
    [SoundSource InitDefaultParams:&soundSourceParams];
    
    soundSourceParams.mFilename = @"dummysound.wav";
    soundSourceParams.mSoundSourceType = SOUND_SOURCE_TYPE_3D;
    soundSourceParams.mLoop = TRUE;
    
    SoundSource* threeDSound = [[SoundPlayer GetInstance] PlaySoundWithParams:&soundSourceParams];
    
    [GetStateMachine() Set3DSoundSource:threeDSound];
    [GetStateMachine() Set3DSoundPlaying:TRUE];
    
    float gain = [threeDSound GetAbsoluteGain];
    
    if (gain < 1.0f)
    {
        [[self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_VOLUME] Enable];
    }
    
    if (gain > 0.0f)
    {
        [[self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_VOLUME] Enable];
    }
        
    SoundSource* soundSource = [GetStateMachine() Get3DSoundSource];
    
    PositionDirectionNavigatorParams navigatorParams;
    [PositionDirectionNavigator InitDefaultParams:&navigatorParams];
    
    navigatorParams.mTargetPosition = &soundSource->mPosition;
    navigatorParams.mTargetDirection = &soundSource->mDirection;

    m3DSoundNavigator = [(PositionDirectionNavigator*)[PositionDirectionNavigator alloc] InitWithParams:&navigatorParams];
    [self Show3DSoundUI];
}

-(void)Stop3DSound
{
    [[SoundPlayer GetInstance] StopSound:[GetStateMachine() Get3DSoundSource]];
    
    [self Hide3DSoundUI];
    
    [GetStateMachine() Set3DSoundPlaying:FALSE];
    [GetStateMachine() Set3DSoundSource:NULL];
    
    [m3DSoundNavigator release];
    m3DSoundNavigator = NULL;
}

-(void)DrawOrtho
{
    if (m3DSoundNavigator != NULL)
    {
        [m3DSoundNavigator DrawOrtho];
    }
}

-(void)Hide3DSoundUI
{
    [[self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_VOLUME] Disable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_VOLUME] Disable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_ZERO_DIRECTION] Disable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_REF_DISTANCE] Disable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_REF_DISTANCE] Disable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_ROLLOFF] Disable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_ROLLOFF] Disable];
    
    [m3DSoundGainLabel Disable];
    [m3DSoundRefDistanceLabel Disable];
    [m3DSoundRefDistance Disable];
    [m3DSoundRolloffFactorLabel Disable];
    [m3DSoundRolloffFactor Disable];
}

-(void)Show3DSoundUI
{
    [[self GetButtonWithIdentifier:THREE_D_SOUND_ZERO_DIRECTION] Enable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_REF_DISTANCE] Enable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_REF_DISTANCE] Enable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_DECREASE_ROLLOFF] Enable];
    [[self GetButtonWithIdentifier:THREE_D_SOUND_INCREASE_ROLLOFF] Enable];

    [m3DSoundGainLabel Enable];
    [m3DSoundRefDistanceLabel Enable];
    [m3DSoundRefDistance Enable];
    [m3DSoundRolloffFactorLabel Enable];
    [m3DSoundRolloffFactor Enable];
}

@end

@implementation MixingDebuggerStateMachine

-(MixingDebuggerStateMachine*)Init
{
    [super Init];
    
    mMusicPlaying = FALSE;
    mUISoundPlaying = FALSE;
    mUISoundSource = NULL;
    m3DSoundPlaying = FALSE;
    m3DSoundSource = NULL;
    
    [[NeonMusicPlayer GetInstance] Stop:0.0];
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(SoundSource*)GetUISoundSource
{
    return mUISoundSource;
}

-(void)SetUISoundSource:(SoundSource*)inSoundSource
{
    mUISoundSource = inSoundSource;
}

-(SoundSource*)Get3DSoundSource
{
    return m3DSoundSource;
}

-(void)Set3DSoundSource:(SoundSource*)inSoundSource
{
    m3DSoundSource = inSoundSource;
}

-(BOOL)GetMusicPlaying
{
    return mMusicPlaying;
}

-(void)SetMusicPlaying:(BOOL)inPlaying
{
    mMusicPlaying = inPlaying;
}

-(BOOL)GetUISoundPlaying
{
    return mUISoundPlaying;
}

-(void)SetUISoundPlaying:(BOOL)inPlaying
{
    mUISoundPlaying = inPlaying;
}

-(BOOL)Get3DSoundPlaying
{
    return m3DSoundPlaying;
}

-(void)Set3DSoundPlaying:(BOOL)inPlaying
{
    m3DSoundPlaying = inPlaying;
}

+(void)CreateButtons:(MixingButtonInitParams*)inButtonParams numButtons:(int)inNumButtons
                        referenceArray:(NSMutableArray*)inReferenceArray listener:(NSObject<ButtonListenerProtocol>*)inListener;
{
    TextureButtonParams buttonParams;
    
    [TextureButton InitDefaultParams:&buttonParams];
    
    buttonParams.mFontSize = 18;
    buttonParams.mFontColor = 0xFF000000;
        
    buttonParams.mButtonTexBaseName = @"editorbutton.png";
    buttonParams.mButtonTexHighlightedName = @"editorbutton_lit.png";
    
    for (int i = 0; i < inNumButtons; i++)
    {
        buttonParams.mButtonText = [NSString stringWithUTF8String:inButtonParams[i].mText];
        
        if ([buttonParams.mButtonText length] >= LONG_BUTTON_LENGTH)
        {
            buttonParams.mButtonTexBaseName = @"editorbutton_large.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_large_lit.png";
        }
        else if ([buttonParams.mButtonText length] >= MID_BUTTON_LENGTH)
        {
            buttonParams.mButtonTexBaseName = @"editorbutton_mid.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_mid_lit.png";
        }
        else
        {
            buttonParams.mButtonTexBaseName = @"editorbutton.png";
            buttonParams.mButtonTexHighlightedName = @"editorbutton_lit.png";
        }
        
        SetRelativePlacement(&buttonParams.mTextPlacement, PLACEMENT_ALIGN_CENTER, PLACEMENT_ALIGN_CENTER);
        
        TextureButton* newButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
        
        [newButton SetPositionX:inButtonParams[i].mX Y:inButtonParams[i].mY Z:0.0];
        newButton->mIdentifier = inButtonParams[i].mButtonIdentifier;
        
        [newButton SetListener:inListener];
        
        [[GameObjectManager GetInstance] Add:newButton];
        [inReferenceArray addObject:newButton];
        [newButton release];
    }
}

+(void)RemoveButtons:(NSMutableArray*)inButtonArray
{
    for (Button* curButton in inButtonArray)
    {
        [[GameObjectManager GetInstance] Remove:curButton];
        [curButton Remove];
    }
}

-(void)DrawOrtho
{
    [(MixingState*)mActiveState DrawOrtho];
}

-(void)Draw
{
    GLState glState;
    SaveGLState(&glState);
        
#if LANDSCAPE_MODE
    Matrix44 viewMatrix, projMatrix;
    
    [[CameraStateMgr GetInstance] GetViewMatrix:&viewMatrix];
    [[CameraStateMgr GetInstance] GetProjectionMatrix:&projMatrix];
        
    NeonGLMatrixMode(GL_PROJECTION);
    glLoadMatrixf(projMatrix.mMatrix);

    NeonGLMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    
    Matrix44 screenRotation;
    GenerateRotationMatrix(-90.0f, 0.0f, 0.0f, 1.0f, &screenRotation);
    
    glLoadIdentity();
    glMultMatrixf(screenRotation.mMatrix);
    glMultMatrixf(viewMatrix.mMatrix);
#endif
    [self Draw3DSoundSource];

#if LANDSCAPE_MODE    
    NeonGLMatrixMode(GL_MODELVIEW);
    glPopMatrix();
#endif
    
    RestoreGLState(&glState);
}

#define SOUND_DIRECTION_NUM_VERTICES (6)
#define SOUND_CUBE_NUM_VERTICES      (8)
#define SOUND_CUBE_EXTENT            (0.2)

-(void)Draw3DSoundSource
{
    SoundSource* soundSource = [self Get3DSoundSource];
    
    if (soundSource != NULL)
    {
        float soundDirection[SOUND_DIRECTION_NUM_VERTICES * 3];
        float soundDirectionColor[(SOUND_DIRECTION_NUM_VERTICES * 4)] = {   0.0f, 1.0f, 0.0f, 1.0f,
                                                                            0.0f, 1.0f, 0.0f, 1.0f,
                                                                            0.0f, 1.0f, 0.0f, 1.0f,
                                                                            0.0f, 1.0f, 0.0f, 1.0f,
                                                                            0.0f, 1.0f, 0.0f, 1.0f,
                                                                            0.0f, 1.0f, 0.0f, 1.0f };
                                                                    
        float soundCube[SOUND_CUBE_NUM_VERTICES * 3] = { -SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT,
                                                          SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT,
                                                          SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT,
                                                         -SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT,
                                                         -SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT,
                                                          SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT, -SOUND_CUBE_EXTENT,
                                                          SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT,
                                                         -SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT,  SOUND_CUBE_EXTENT };
                                                         
        unsigned short soundCubeIndices[6 * 6] = {  0, 1, 2, 0, 2, 3,   // Bottom
                                                    4, 5, 6, 4, 6, 7,   // Top
                                                    3, 2, 7, 2, 7, 6,   // Front
                                                    0, 1, 4, 1, 4, 5,   // Back 
                                                    2, 1, 6, 1, 6, 5,   // Right 
                                                    0, 3, 4, 3, 4, 7    // Left
                                                  };
                                                                                                            
                                                    
        float soundCubeColors[SOUND_CUBE_NUM_VERTICES * 4];
        
        for (int i = 0; i < SOUND_CUBE_NUM_VERTICES; i++)
        {
            soundCubeColors[(i * 4) + 0] = (1.0f / (float)(SOUND_CUBE_NUM_VERTICES)) * i;
            soundCubeColors[(i * 4) + 1] = (1.0f / (float)(SOUND_CUBE_NUM_VERTICES)) * i;
            soundCubeColors[(i * 4) + 2] = 0.0f;
            soundCubeColors[(i * 4) + 3] = 1.0f;
        }
        
        glEnableClientState(GL_VERTEX_ARRAY);
        glEnableClientState(GL_COLOR_ARRAY);
                                
        glVertexPointer(3, GL_FLOAT, 0, soundCube);
        glColorPointer(4, GL_FLOAT, 0, soundCubeColors);
        
        Matrix44 translate;
        GenerateTranslationMatrixFromVector(&soundSource->mPosition, &translate);

        NeonGLMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        {
            glMultMatrixf(translate.mMatrix);
            
            // Draw the sound source location
            glDrawElements(GL_TRIANGLES, sizeof(soundCubeIndices) / sizeof(unsigned short), GL_UNSIGNED_SHORT, soundCubeIndices);
        }
        glPopMatrix();
        
        // Draw an arrow representing the direction vector
        Vector3 endPoint;
        Add3(&soundSource->mPosition, &soundSource->mDirection, &endPoint);
                
        soundDirection[0] = soundSource->mPosition.mVector[0];
        soundDirection[1] = soundSource->mPosition.mVector[1];
        soundDirection[2] = soundSource->mPosition.mVector[2];

        soundDirection[3] = endPoint.mVector[0];
        soundDirection[4] = endPoint.mVector[1];
        soundDirection[5] = endPoint.mVector[2];
        
        unsigned short indexList[10] = { 0, 1, 1, 2, 1, 3, 1, 4, 1, 5 };
        
        if (Length3(&soundSource->mDirection) != 0.0f)
        {
            // First draw the arrow for (1.0, 0.0, 0.0)
            
            Vector3 baseDirection = { { 1.0f, 0.0f, 0.0f } };
            Vector3 arrowLine[4];
            
            Set(&arrowLine[0], 0.7, 0.0, 0.2);
            Set(&arrowLine[1], 0.7, 0.0, -0.2);
            Set(&arrowLine[2], 0.7, 0.2, 0.0);
            Set(&arrowLine[3], 0.7, -0.2, 0.0);
            
            Matrix44 transform;
            GenerateVectorToVectorTransform(&baseDirection, &soundSource->mDirection, &transform);
            
            Matrix44 translation;
            GenerateTranslationMatrixFromVector(&soundSource->mPosition, &translation);
            
            MatrixMultiply(&translation, &transform, &transform);
                        
            Vector4 arrowLineTransformed[4];
            
            // Now transform the arrow from (1.0, 0.0, 0.0) to the proper rotation
            for (int i = 0; i < 4; i++)
            {
                TransformVector4x3(&transform, &arrowLine[i], &arrowLineTransformed[i]);
                
                soundDirection[6 + (i * 3)] = arrowLineTransformed[i].mVector[0];
                soundDirection[6 + (i * 3) + 1] = arrowLineTransformed[i].mVector[1];
                soundDirection[6 + (i * 3) + 2] = arrowLineTransformed[i].mVector[2];
            }
            
            glVertexPointer(3, GL_FLOAT, 0, soundDirection);
            glColorPointer(4, GL_FLOAT, 0, soundDirectionColor);
            
            glDrawElements(GL_LINES, 10, GL_UNSIGNED_SHORT, indexList);
        }
        

        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisable(GL_POINT_SMOOTH);
    }
    
    NeonGLError();
}

@end


@implementation MixingDebugger

-(void)Startup
{
    mMixingDebuggerStateMachine = [(MixingDebuggerStateMachine*)[MixingDebuggerStateMachine alloc] Init];
    
    [mMixingDebuggerStateMachine Push:[MixingDebuggerRootState alloc]];
}

-(void)Resume
{
}

-(void)Shutdown
{
    [mMixingDebuggerStateMachine release];
}

-(void)Suspend
{
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mMixingDebuggerStateMachine Update:inTimeStep];
}

-(void)DrawOrtho
{
    [mMixingDebuggerStateMachine DrawOrtho];
}

-(void)Draw
{
    [mMixingDebuggerStateMachine Draw];
}

@end