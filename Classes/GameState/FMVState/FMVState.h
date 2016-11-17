//
//  IntroState.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameState.h"
#import "TouchSystem.h"

@class MPMoviePlayerController;

typedef enum
{
    FMV_LOAD_STATE_WAITING,
    FMV_LOAD_STATE_COUNTDOWN,
    FMV_LOAD_STATE_COMPLETED
} FMVLoadState;

@interface FMVState : GameState<TouchListenerProtocol>
{
    MPMoviePlayerController* mMovieController;
    BOOL                     mFlowStateAdvanced;
    
    FMVLoadState             mFMVLoadState;
    int                      mHackFrameDelay;
}

-(void)Startup;
-(void)Shutdown;

-(void)moviePlayBackDidFinish:(NSNotification*)notification;
-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData;

@end