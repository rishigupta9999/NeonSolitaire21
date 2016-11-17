//
//  IntroState.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <CoreGraphics/CoreGraphics.h>

#import "FMVState.h"
#import "ResourceManager.h"
#import "Flow.h"
#import "EAGLView.h"
#import "Neon21AppDelegate.h"
#import "NeonMath.h"


typedef enum
{
	SKU_Run21,
	SKU_21Squared,
	SKU_Escape1,
	SKU_HiLo,
	SKU_PokerSquared,
	SKU_Escape2,
	SKU_NUM,
} SKU_Arrays;

@implementation FMVState

-(void)Startup
{
    NSString* fmvName = NULL;
    
    // fmvName needs to populated with filename
    
    FileNode* fileNode = [[ResourceManager GetInstance] FindFileWithName:fmvName];
        
    mMovieController = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:fileNode->mPath isDirectory:FALSE]];
    mMovieController.controlStyle = MPMovieControlStyleNone;
    
    [mMovieController setFullscreen:TRUE animated:FALSE];
    
    [mMovieController prepareToPlay];
        
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(DegreesToRadians(90.0));
    
    if (GetDevicePad())
    {
        [mMovieController.view setCenter:CGPointMake(384.0f, 512.0f)];
        [mMovieController.view setTransform:rotationTransform];
        [mMovieController.view setBounds:CGRectMake(0.0, 0.0f, 1024.0f, 768.0f)];
    }
    else
    {
        [mMovieController.view setCenter:CGPointMake((float)GetScreenAbsoluteHeight() / 2.0f, ((float)GetScreenAbsoluteWidth() / 2.0f))];
        [mMovieController.view setTransform:rotationTransform];
        [mMovieController.view setBounds:CGRectMake(0.0, 0.0f, GetScreenAbsoluteWidth(), GetScreenAbsoluteHeight())];
    }
    
    if (GetScreenRetina())
    {
        mMovieController.view.contentScaleFactor = GetScreenScaleFactor();
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
					selector:@selector(moviePlayBackDidStart:) 
					name:MPMoviePlayerLoadStateDidChangeNotification 
					object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self 
					selector:@selector(moviePlayBackDidFinish:) 
					name:MPMoviePlayerPlaybackDidFinishNotification 
					object:nil];
                    
    [[TouchSystem GetInstance] AddListener:self];
    
    mFlowStateAdvanced = FALSE;
    mFMVLoadState = FMV_LOAD_STATE_WAITING;
    mHackFrameDelay = 2;
}


-(void)Shutdown
{
    [[TouchSystem GetInstance] RemoveListener:self];

    [mMovieController release];
}

-(void)moviePlayBackDidStart:(NSNotification*)notification
{
    if ([mMovieController loadState] & MPMovieLoadStatePlayable)
    {
        mFMVLoadState = FMV_LOAD_STATE_COUNTDOWN;
    }
}

-(void)moviePlayBackDidFinish:(NSNotification*)notification
{
    if (!mFlowStateAdvanced)
    {
        mFlowStateAdvanced = TRUE;

        [mMovieController.view removeFromSuperview];
        [mMovieController stop];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                          name:MPMoviePlayerPlaybackDidFinishNotification
                          object:nil];
                          
        [[NSNotificationCenter defaultCenter] removeObserver:self
                          name:MPMoviePlayerLoadStateDidChangeNotification
                          object:nil];

        [[Flow GetInstance] AdvanceLevel];
    }
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
//#if !NEON_PRODUCTION
    if (inData->mTouchType == TOUCHES_ENDED)
    {
        if (mFMVLoadState == FMV_LOAD_STATE_WAITING)
        {
            [[Flow GetInstance] AdvanceLevel];
        }
        else
        {
            [mMovieController stop];
        }
    }
//#endif

    return TOUCHSYSTEM_CONSUME_NONE;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    // Have a small two frame delay before we display the movie.  There appears to be a bug where the last FMV
    // is displayed briefly, if the movie is terminated.
    
    if (mFMVLoadState == FMV_LOAD_STATE_COUNTDOWN)
    {
        mHackFrameDelay--;
        
        if (mHackFrameDelay == 0)
        {
            [mMovieController play];
            EAGLView* appView = ((Neon21AppDelegate*)[[UIApplication sharedApplication] delegate]).glView;
            [appView addSubview:mMovieController.view];
            
            mFMVLoadState = FMV_LOAD_STATE_COMPLETED;
        }
    }
    
    MPMoviePlaybackState state = [mMovieController playbackState];
    
    if (state == MPMoviePlaybackStatePaused)
    {
        [mMovieController play];
    }
}

@end