//
//  Fader.h
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "GameObject.h"

typedef enum
{
    FADER_STATE_WAITING,
    FADER_STATE_FADING_OUT,
    FADER_STATE_FADED_OUT,
    FADER_STATE_FADING_IN,
    FADER_STATE_INACTIVE,
} FaderState;

typedef enum
{
    FADE_FROM_BLACK,
    FADE_TO_BLACK,
    FADE_TO_BLACK_HOLD,
    FADE_CYCLE
} FadeType;

@protocol FaderCallback

-(void)FadeComplete:(NSObject*)inObject;

@end

typedef struct
{
    BOOL                        mHoldAfterCompletion;
    float                       mDuration;
    FadeType                    mFadeType;
    int                         mFrameDelay;
    NSObject<FaderCallback>*    mCallback;
    NSObject*                   mCallbackObject;
    BOOL                        mCancelFades;
} FaderParams;

@class Queue;

@interface FaderQueueEntry : NSObject
{
    @public
        FaderParams mParams;
}
-(FaderQueueEntry*)InitWithParams:(FaderParams*)inParams;

@end

@class TextBox;

@interface Fader : NSObject<MessageChannelListener>
{
    FaderParams mParams;
    float       mTimeRemaining;
    FaderState  mFaderState;
    int         mFrameDelayRemaining;
    
    Queue*      mFaderOperationQueue;
    BOOL        mActive;
    
    TextBox*    mLoadingTextBox;
}

-(Fader*)Init;
-(void)StartWithParams:(FaderParams*)inParams;
-(void)StartWithParams:(FaderParams*)inParams deferred:(BOOL)inDeferred;
-(void)dealloc;
+(void)InitDefaultParams:(FaderParams*)outParams;

+(void)CreateInstance;
+(void)DestroyInstance;
+(Fader*)GetInstance;

-(void)Update:(CFTimeInterval)inTimeStep;
-(void)DrawOrtho;

-(void)ProcessMessage:(Message*)inMsg;

@end