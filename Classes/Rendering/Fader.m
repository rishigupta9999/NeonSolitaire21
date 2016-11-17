//
//  Fader.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "Fader.h"
#import "Queue.h"
#import "ModelManager.h"
#import "EAGLView.h"
#import "TextBox.h"
#import "GameObjectManager.h"
#import "GameStateMgr.h"

static Fader* sInstance = NULL;

@implementation FaderQueueEntry

-(FaderQueueEntry*)InitWithParams:(FaderParams*)inParams
{
    memcpy(&mParams, inParams, sizeof(FaderParams));
    return self;
}

@end

@implementation Fader

-(Fader*)Init
{
    [Fader InitDefaultParams:&mParams];
    
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    [GetGlobalMessageChannel() AddListener:self];
    
    mTimeRemaining = 0.0;
    mFaderState = FADER_STATE_INACTIVE;
    mFrameDelayRemaining = 0;
    
    mFaderOperationQueue = [(Queue*)[Queue alloc] Init];
    
    mActive = FALSE;
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    
    SetColorFloat(&tbParams.mColor, 1.0, 1.0, 1.0, 1.0);
    SetColorFloat(&tbParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= NSLocalizedString(@"LS_Loading", NULL);
    tbParams.mFontSize		= 24;
    tbParams.mFontType		= NEON_FONT_STYLISH;
    
    mLoadingTextBox = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [mLoadingTextBox SetVisible:FALSE];
    [mLoadingTextBox SetPositionX:350 Y:280 Z:0.0];
    
    [[GameObjectManager GetInstance] Add:mLoadingTextBox withRenderBin:RENDERBIN_FOREMOST];
    [mLoadingTextBox release];
    
    return self;
}

-(void)StartWithParams:(FaderParams*)inParams
{
    [self StartWithParams:inParams deferred:FALSE];
}

-(void)StartWithParams:(FaderParams*)inParams deferred:(BOOL)inDeferred
{
    // We already retained these once before for a deferred fade call
    if (!inDeferred)
    {
        [inParams->mCallbackObject retain];
        [inParams->mCallback retain];
    }
    
    if ((inParams->mCancelFades) && (!mActive))
    {
        [mParams.mCallbackObject release];
        [mParams.mCallback release];
        
        mFaderState = FADER_STATE_INACTIVE;
        
        while(true)
        {
            FaderQueueEntry* faderQueueEntry = (FaderQueueEntry*)[mFaderOperationQueue Dequeue];
            
            if (faderQueueEntry != NULL)
            {
                [faderQueueEntry->mParams.mCallbackObject release];
                [faderQueueEntry->mParams.mCallback release];
            }
            else
            {
                break;
            }
        }
    }
    
    if (((mFaderState == FADER_STATE_INACTIVE) || (mFaderState == FADER_STATE_FADED_OUT)) && (!mActive))
    {
        memcpy(&mParams, inParams, sizeof(FaderParams));
        
        mTimeRemaining = mParams.mDuration;
        mFaderState = FADER_STATE_FADING_OUT;
        
        if (inParams->mFrameDelay == 0)
        {
            if (inParams->mFadeType == FADE_FROM_BLACK)
            {
                mFaderState = FADER_STATE_FADING_IN;
            }
        }
        else
        {
            mFaderState = FADER_STATE_WAITING;
            mFrameDelayRemaining = inParams->mFrameDelay;
        }
    }
    else
    {
        FaderQueueEntry* faderQueueEntry = [(FaderQueueEntry*)[FaderQueueEntry alloc] InitWithParams:inParams];
        [mFaderOperationQueue Enqueue:faderQueueEntry];
        [faderQueueEntry release];
    }
}

-(void)dealloc
{
    [mFaderOperationQueue release];
    [mLoadingTextBox Remove];
    
    [super dealloc];
}

+(void)InitDefaultParams:(FaderParams*)outParams
{
    outParams->mDuration = 1.0f;
    outParams->mFadeType = FADE_CYCLE;
    outParams->mFrameDelay = 0;
    outParams->mCallback = NULL;
    outParams->mCallbackObject = NULL;
    outParams->mCancelFades = FALSE;
}

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create Fader");
    
    sInstance = [(Fader*)[Fader alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double delete Fader");
    [sInstance release];
}

+(Fader*)GetInstance
{
    return sInstance;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mFaderState == FADER_STATE_INACTIVE)
    {
        return;
    }
    
    if (mFaderState == FADER_STATE_WAITING)
    {
        if (mFrameDelayRemaining <= 0)
        {
            switch(mParams.mFadeType)
            {
                case FADE_FROM_BLACK:
                {
                    mFaderState = FADER_STATE_FADING_IN;
                    break;
                }
                    
                case FADE_CYCLE:
                {
                    mFaderState = FADER_STATE_FADING_OUT;
                    break;
                }
                
                default:
                {
                    NSAssert(FALSE, @"Unhandled fade type");
                    break;
                }
            }
        }
    }
        
    if (mFaderState == FADER_STATE_WAITING)
    {
        mFrameDelayRemaining--;
        return;
    }
    else
    {
        mTimeRemaining -= inTimeStep;
    }
    
    if ((mTimeRemaining <= 0.0f) && (mFaderState != FADER_STATE_FADED_OUT))
    {
        mActive = TRUE;
        [mParams.mCallback FadeComplete:mParams.mCallbackObject];
        [mLoadingTextBox SetVisible:FALSE];
        mActive = FALSE;
        
        [mParams.mCallback release];
        [mParams.mCallbackObject release];
        
        mParams.mCallback = NULL;
        mParams.mCallbackObject = NULL;
        
        if (mParams.mFadeType == FADE_TO_BLACK_HOLD)
        {
            mFaderState = FADER_STATE_FADED_OUT;
        }
        else
        {
            mFaderState = FADER_STATE_INACTIVE;
        }
        
        FaderQueueEntry* faderQueueEntry = (FaderQueueEntry*)[mFaderOperationQueue Dequeue];
        
        if (faderQueueEntry != NULL)
        {
            [self StartWithParams:&faderQueueEntry->mParams deferred:TRUE];
        }
    }
}

-(void)DrawOrtho
{
    if (mFaderState == FADER_STATE_INACTIVE)
    {
        return;
    }
	
	[[ModelManager GetInstance] SetupOrthoCamera];
    
    if ((mFaderState == FADER_STATE_FADING_OUT) && (mParams.mFadeType != FADE_TO_BLACK_HOLD))
    {
        if (mTimeRemaining < (mParams.mDuration / 2.0f))
        {
            mFaderState = FADER_STATE_FADING_IN;
        }
    }
    
    float alpha = 0.0f;
    
    switch(mFaderState)
    {
        case FADER_STATE_FADING_OUT:
        {
            float timeRemainingInPhase = mTimeRemaining - (mParams.mDuration / 2.0f);
            
            alpha = 1.0 - (timeRemainingInPhase / (mParams.mDuration / 2.0f));            
            break;
        }
        
        case FADER_STATE_FADING_IN:
        {
            switch(mParams.mFadeType)
            {
                case FADE_FROM_BLACK:
                {
                    alpha = mTimeRemaining / mParams.mDuration;
                    break;
                }
                
                default:
                {
                    alpha = mTimeRemaining / (mParams.mDuration / 2.0f);
                    break;
                }
            }
            
            break;
        }
        
        case FADER_STATE_WAITING:
        {
            switch(mParams.mFadeType)
            {
                case FADE_FROM_BLACK:
                {
                    alpha = 1.0f;
                    break;
                }
                
                default:
                {
                    break;
                }
            }
            
            break;
        }
        
        case FADER_STATE_FADED_OUT:
        {
            alpha = 1.0f;
            break;
        }
        
        default:
        {
            NSAssert(FALSE, @"Unknown Fader state");
            break;
        }
    }
    
    alpha = ClampFloat(alpha, 0.0, 1.0);
    
    float screenWidth = [GetEAGLView() GetBackingHeight];
    float screenHeight = [GetEAGLView() GetBackingWidth];
    
    float positions[8] = { 0.0f, 0.0f, screenWidth, 0.0, 0.0, screenHeight, screenWidth, screenHeight };
    float colors[16];
    
    for (int v = 0; v < 4; v++)
    {
        colors[4*v + 0] = 0.0f;
        colors[4*v + 1] = 0.0f;
        colors[4*v + 2] = 0.0f;
        colors[4*v + 3] = alpha;
    }
    
    GLState glState;
    SaveGLState(&glState);
    
    NeonGLEnable(GL_BLEND);
    NeonGLBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    NeonGLDisable(GL_DEPTH_TEST);
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    
    glVertexPointer(2, GL_FLOAT, 0, positions);
    glColorPointer(4, GL_FLOAT, 0, colors);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    RestoreGLState(&glState);
	
	[[ModelManager GetInstance] TeardownOrthoCamera];
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_MAIN_MENU_PENDING_TERMINATE:
        case EVENT_RUN21_PENDING_TERMINATE:
        case EVENT_MAIN_MENU_LEVEL_SELECT_PENDING:
        {
            [mLoadingTextBox SetVisible:TRUE];
            break;
        }
        
        case EVENT_MAIN_MENU_ENTER_LEVEL_SELECT:
        {
            [mLoadingTextBox SetVisible:FALSE];
            break;
        }
    }
}

@end