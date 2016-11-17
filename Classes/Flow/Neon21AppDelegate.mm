//
//  Neon21AppDelegate.m
//  Neon21
//
//  Copyright Neon Games 2008. All rights reserved.
//

#import "Neon21AppDelegate.h"
#import "EAGLView.h"

#import "GameStateMgr.h"
#import "ResourceManager.h"
#import "SaveSystem.h"
#import "ExperienceManager.h"
#import "TextureManager.h"
#import "ModelManager.h"
#import "GameObjectManager.h"
#import "TextTextureBuilder.h"
#import "DebugManager.h"
#import "CardManager.h"
#import "LightManager.h"
#import "CameraStateMgr.h"
#import "Flow.h"
#import "TouchSystem.h"
#import "CompanionRenderManager.h"
#import "CompanionSelect.h"
#import "GLExtensionManager.h"
#import "Fader.h"
#import "NeonMusicPlayer.h"
#import "MusicDirector.h"
#import "SoundPlayer.h"
#import "AudioSessionManager.h"
#import "LocalizationManager.h"
#import "RenderGroupManager.h"
#import "AdvertisingManager.h"
#import "RegenerationManager.h"
#import "InAppPurchaseManager.h"
#import "AchievementManager.h"

#import "MainMenu.h"
#import "AnimationDebugState.h"
#import "GameTwentyOneSquared.h"
#import "DebugCameraState.h"
#import "AnimationDebugState.h"
#import "GameRun21.h"
#import "GameCutscene.h"
#import "GameTripleSwitch.h"
#import "LightingEditorState.h"
#import "MixingDebugger.h"
#import "NeonViewController.h"
#import "NeonAccountManager.h"
#import "NeonGL.h"
#import "HintSystem.h"

#include <CoreFoundation/CFDate.h>

#import "NeonMetrics.h"

#if PRINT_IOS_BOOT_INFO
#import <sys/utsname.h>
#endif

#import "ft2build.h"
#import "freetype.h"

#import "KISSMetricsAPI.h"

#import <Parse/Parse.h>
#import "SplitTestingSystem.h"
#import "NeonChartboostDelegate.h"

typedef enum
{
    GameStateID_Menu_Main,
    GameStateID_Debug_Camera,
    GameStateID_Debug_Animation,
    GameStateID_Debug_Lighting,
    GameStateID_Debug_Mixing,
    GameStateID_Game_Cutscene,
    GameStateID_Game_Neon21,
    GameStateID_Game_Run21,
    GameStateID_Game_TripleSwitch,
    GameStateID_Game_TwentyOneSquared,
    GameStateID_ChooseCompanions,
} GameStateID;

// Neon21_Prefix.pch
#define OVERRIDE_STARTSTATE_ID     ( GameStateID_Debug_Animation )
#define OVERRIDE_STARTPROGRESS_ID  ( NeonEngine_MainMenu ) // ENeonEscapeProgress , in Flow.h

UIView* gAppView = NULL;

@implementation Neon21AssertionHandler

- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format,...
{
    NSLog(@"%@", format);
    
    int* foo = NULL;
    *foo = 8;
    
    //abort();  // Abort kills the callstack, so write to NULL instead.
}

- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format,...
{
    NSLog(@"%@", format);
    
    int* foo = NULL;
    *foo = 8;
    
    // abort(); // Abort kills the callstack, so write to NULL instead.
}

@end


@implementation Neon21AppDelegate

@synthesize window;
@synthesize glView;

// NSApplication Methods
- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	[self Init];
    
	mAnimationInterval = 1.0 / 60.0;    
    mLastFrameTime = CACurrentMediaTime();
    
    mFrameNumber = 0;
    
    // Setup custom assert handler
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    Neon21AssertionHandler* handler = [Neon21AssertionHandler alloc];
    
    [threadDictionary setObject:handler forKey:@"NSAssertionHandler"];
    
    if (GetDeviceiPhoneTall())
    {
        [window setFrame:[[UIScreen mainScreen] bounds]];
    }
    
    mViewController = [[NeonViewController alloc] init];
    
    mViewController.view = glView;
    
    window.rootViewController = mViewController;
    
    mChartboostDelegate = [(NeonChartboostDelegate*)[NeonChartboostDelegate alloc] Init];
        
    [Flurry setDebugLogEnabled:ADVERTISING_FLURRY_DEBUG];
        
#if PRINT_IOS_BOOT_INFO
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *subclassDevice    = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSLog(@"iOS Device Info");
    NSLog(@"Model: %@ ; Subclass: %@", [[UIDevice currentDevice] model], subclassDevice );
    NSLog(@"Localized Model: %@", [[UIDevice currentDevice] localizedModel] );
    NSLog(@"System: %@ ; Versions: %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion] );
#endif

    [CardManager CreateInstance];
    [HintSystem CreateInstance];
}

- (void)dealloc 
{
    [mViewController release];
	[window release];
	[glView release];
	[super dealloc];
}

// Stuff that may resemble a proper game.  Game Loop, startup, etc
-(void)Init
{
    NeonStartTimer();
    
    mGlobalMessageChannel = [(MessageChannel*)[MessageChannel alloc] Init];

    [ResourceManager CreateInstance];
    [NeonMetrics CreateInstance];
    [SplitTestingSystem CreateInstance];
    [LocalizationManager CreateInstance];
    [TouchSystem CreateInstance];
    [GameStateMgr CreateInstance];
    [NeonGL CreateInstance];
    [GLExtensionManager CreateInstance];
    [NeonAccountManager CreateInstance];
    [SaveSystem CreateInstance];
    [ExperienceManager CreateInstance];
    [TextureManager CreateInstance];
#if !NEON_PRODUCTION
    [DebugManager CreateInstance];
#endif
    [ModelManager CreateInstance];
    [GameObjectManager CreateInstance];
    [LightManager CreateInstance];
    [CameraStateMgr CreateInstance];
    [Flow CreateInstance];
    [RenderGroupManager CreateInstance];
    [AudioSessionManager CreateInstance];
    [CompanionRenderManager CreateInstance];
#if MUSIC_ENABLED
    [NeonMusicPlayer CreateInstance];
    [MusicDirector CreateInstance];
#endif

#if SOUND_ENABLED
    [SoundPlayer CreateInstance];
#endif

    [AdvertisingManager CreateInstance];

    [InAppPurchaseManager CreateInstance];
#if !NEON_SOLITAIRE_21
    [AchievementManager CreateInstance];
#endif
    [RegenerationManager CreateInstance];
    
    [CompanionManager InitCompanionInfo];
    [TextTextureBuilder CreateInstance];
    [Fader CreateInstance];
    
    // Initialize a sensible starting timeStep (before we can calculate an actual timeStep)
    mTimeStep = 1.0f / 60.0f;
    
    mUsingDisplayLink = FALSE;

    // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
    // class is used as fallback when it isn't available.
    NSString *reqSysVer = @"3.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
    {
        mUsingDisplayLink = TRUE;
    }
    
    mAnimationInterval = 1.0f / 60.0f;
            
    if (!mUsingDisplayLink)
    {
        // Start the timer that calls our game loop 60 times per second
        mAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:mAnimationInterval target:self selector:@selector(GameLoop) userInfo:nil repeats:YES];
        
        mDisplayLink = NULL;
    }
    else
    {
        mAnimationTimer = NULL;
        mAnimationInterval = 0.0;
        
        mDisplayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(GameLoop)];
        [mDisplayLink setFrameInterval:mAnimationInterval];
        [mDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    // Link app's view to the touch system
    [[TouchSystem GetInstance] SetAppView:glView];
    
    // Add app version for KISSMetrics in particular
    NSDictionary* appVersionDictionary = [NSDictionary dictionaryWithObject:[[NeonMetrics GetInstance] GetVersion] forKey:@"App Version"];
    [[NeonMetrics GetInstance] logEvent:@"Application Started" withParameters:appVersionDictionary];
	
    [[Flow GetInstance] EnterGameMode:START_FLOW_MODE level:START_FLOW_LEVEL];
    
    if (START_DEBUG_STATE != 0)
    {
        [[DebugManager GetInstance] ToggleDebugGameState:[NSClassFromString([NSString stringWithUTF8String:START_DEBUG_STATE]) class]];
    }

	[[SoundPlayer GetInstance] SetSoundEnabled:[[SaveSystem GetInstance] GetSoundOn]];
	[[NeonMusicPlayer GetInstance] SetMusicEnabled:[[SaveSystem GetInstance] GetMusicOn]];

    mSuspended = FALSE;
    
    return;
}

-(void)Term
{
    [HintSystem DestroyInstance];
    [NeonAccountManager DestroyInstance];
    [InAppPurchaseManager DestroyInstance];
#if !NEON_SOLITAIRE_21
    [AchievementManager DestroyInstance];
#endif
    [RegenerationManager DestroyInstance];
    [AdvertisingManager DestroyInstance];
    [LocalizationManager DestroyInstance];
    [Fader DestroyInstance];
	[RenderGroupManager DestroyInstance];
    [GLExtensionManager DestroyInstance];
    [CompanionRenderManager DestroyInstance];
    [TouchSystem DestroyInstance];
    [TextTextureBuilder DestroyInstance];
    [ModelManager DestroyInstance];
    [TextureManager DestroyInstance];
    [SaveSystem DestroyInstance];
    [ExperienceManager DestroyInstance];
    [ResourceManager DestroyInstance];
    [GameStateMgr DestroyInstance];
#if !NEON_PRODUCTION
	[DebugManager DestroyInstance];
#endif
	[CardManager DestroyInstance];
    [LightManager DestroyInstance];
    [CameraStateMgr DestroyInstance];
    [Flow DestroyInstance];
    [GameObjectManager DestroyInstance];
#if MUSIC_ENABLED
    [NeonMusicPlayer DestroyInstance];
    [MusicDirector DestroyInstance];
#endif

#if SOUND_ENABLED
    [SoundPlayer DestroyInstance];
#endif
    [AudioSessionManager DestroyInstance];
    
    [SplitTestingSystem DestroyInstance];
    [NeonGL DestroyInstance];

    [mGlobalMessageChannel release];
    [mChartboostDelegate release];
    
    [NeonMetrics DestroyInstance];
}

-(void)GameLoop
{
    if (mSuspended)
    {
        return;
    }
    
    // If we're here, the game state is initialized.
    u32 numObjects = [[GameObjectManager GetInstance] GetNumVisible3DObjects];

    [glView StartGLRender:(numObjects > 0)];
	
	//mTimeStep /= 5.0;	// Slow down the game by a constant factor to debug and detect abnormalities in animation or UI

    [[RegenerationManager GetInstance] Update:mTimeStep];
    [[ExperienceManager GetInstance] Update:mTimeStep];
    [[NeonAccountManager GetInstance] Update:mTimeStep];
    [[GameStateMgr GetInstance] Update:mTimeStep];
    [[GameObjectManager GetInstance] Update:mTimeStep];
	[[RenderGroupManager GetInstance] Update:mTimeStep];
    
    [[TouchSystem GetInstance] Update:mTimeStep];
    [[LightManager GetInstance] Update:mTimeStep];
    [[CameraStateMgr GetInstance] Update:mTimeStep];
    [[Fader GetInstance] Update:mTimeStep];
    [[HintSystem GetInstance] Update:mTimeStep];
    [[SaveSystem GetInstance] Update:mTimeStep];
#if MUSIC_ENABLED
    [[NeonMusicPlayer GetInstance] Update:mTimeStep];
    [[MusicDirector GetInstance] Update:mTimeStep];
#endif

#if SOUND_ENABLED
    [[SoundPlayer GetInstance] Update:mTimeStep];
#endif

	[[RenderGroupManager GetInstance] Draw];
	[[GameStateMgr GetInstance] Draw];
    
    ModelManagerDrawParams drawParams;
    [ModelManager InitDefaultDrawParams:&drawParams];

    // Start by drawing all 3D objects with less than or equal to default priority.  This is primarily the environment and skyboxes
    drawParams.mPriority = RENDERBIN_DEFAULT_PRIORITY;
    drawParams.mCondition = ModelManagerCondition_LessThanEquals;
    [[ModelManager GetInstance] DrawWithParams:&drawParams];
    
    drawParams.mProjected = TRUE;
    [[ModelManager GetInstance] DrawWithParams:&drawParams];
    
    // Draw cards in a separate pass since they're alpha blended on top of the 3D environment
    drawParams.mCondition = ModelManagerCondition_Equals;
    drawParams.mPriority = [[ModelManager GetInstance] GetPriorityForRenderBin:RENDERBIN_CARDS];
    drawParams.mProjected = FALSE;
    glDepthMask(FALSE);
    [[ModelManager GetInstance] DrawWithParams:&drawParams];
    glDepthMask(TRUE);
    
    // Draw projected UI with greater than default priority but less than UI priority.  This is projected UI that can be obscured by some 3D objects
    drawParams.mCondition = ModelManagerCondition_GreaterThan;
    drawParams.mPriority = RENDERBIN_DEFAULT_PRIORITY;
    drawParams.mProjected = TRUE;
    [[ModelManager GetInstance] DrawWithParams:&drawParams];
    
    // Now draw 3D objects that need to be drawn in front of the cards and some of the projected UI.  At the moment, this is companions and special effects
    drawParams.mCondition = ModelManagerCondition_GreaterThan;
    drawParams.mPriority = [[ModelManager GetInstance] GetPriorityForRenderBin:RENDERBIN_CARDS];
    drawParams.mProjected = FALSE;
    [[ModelManager GetInstance] DrawWithParams:&drawParams];
    
    [glView End3DRendering];
    
    drawParams.mPriority = [[ModelManager GetInstance] GetPriorityForRenderBin:RENDERBIN_UI];
    drawParams.mCondition = ModelManagerCondition_LessThanEquals;
    drawParams.mOrtho = TRUE;
    
    [[ModelManager GetInstance] DrawWithParams:&drawParams];
	
	// GameStates shouldn't need to have any knowledge of the ortho camera.  We should clean this up though.
	[[ModelManager GetInstance] SetupUICamera];
    [[GameStateMgr GetInstance] DrawOrtho];
	[[ModelManager GetInstance] TeardownUICamera];
	   
    [[Fader GetInstance] DrawOrtho];

    drawParams.mCondition = ModelManagerCondition_GreaterThan;
    [[ModelManager GetInstance] DrawWithParams:&drawParams];

    [[NeonMusicPlayer GetInstance] DrawOrtho];
#if !NEON_PRODUCTION && DRAW_DEBUGMANAGER
    [[DebugManager GetInstance] DrawOrtho:mTimeStep];
#endif

    [glView EndGLRender];

    NeonGLError();

    mTimeStep = CACurrentMediaTime() - mLastFrameTime;
    mLastFrameTime = CACurrentMediaTime();
    
    mFrameNumber++;
}
  
-(int)GetFrameNumber
{
    return mFrameNumber;
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    [GetGlobalMessageChannel() SendEvent:EVENT_APPLICATION_WILL_TERMINATE withData:NULL];
    [self Term];
}

-(void)applicationWillResignActive:(UIApplication *)application
{
    mSuspended = TRUE;
    
    if (!mUsingDisplayLink)
    {
        [mAnimationTimer invalidate];
    }
    else
    {
       [mDisplayLink setPaused:TRUE];
    }
    
    [[ExperienceManager GetInstance] StopTimer];
    
    [GetGlobalMessageChannel() SendEvent:EVENT_APPLICATION_SUSPENDED withData:NULL];
    
    glFinish();
}

-(void)applicationDidEnterBackground:(UIApplication*)application
{
    UIApplicationState state = [application applicationState];
    
    if (state == UIApplicationStateInactive)
    {
        [[NeonMetrics GetInstance] logEvent:@"Lock Screen Pressed" withParameters:NULL type:NEON_METRIC_TYPE_KISS];
    }
    else if (state == UIApplicationStateBackground)
    {
        [[NeonMetrics GetInstance] logEvent:@"Home Button Pressed" withParameters:NULL type:NEON_METRIC_TYPE_KISS];
    }

    [GetGlobalMessageChannel() SendEvent:EVENT_APPLICATION_ENTERED_BACKGROUND withData:NULL];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [GetGlobalMessageChannel() SendEvent:EVENT_APPLICATION_ENTERED_FOREGROUND withData:NULL];
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!mUsingDisplayLink)
    {
        mAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:mAnimationInterval target:self selector:@selector(GameLoop) userInfo:nil repeats:YES];
    }
    else
    {
        [mDisplayLink setPaused:FALSE];
    }

#if !NEON_SOLITAIRE_21
    [[AchievementManager GetInstance] AuthenticateLocalPlayer];
#endif

#if !NEON_SOLITAIRE_21
    [[NeonAccountManager GetInstance] applicationDidBecomeActive];
#endif
    [[ExperienceManager GetInstance] StartTimer];
    
    if (mSuspended)
    {
        [GetGlobalMessageChannel() SendEvent:EVENT_APPLICATION_RESUMED withData:NULL];
    }
    
    [[NeonMetrics GetInstance] logEvent:@"Application Resumed" withParameters:NULL];
    
    mSuspended = FALSE;
}

-(UIViewController*)GetViewController
{
    return mViewController;
}

@end