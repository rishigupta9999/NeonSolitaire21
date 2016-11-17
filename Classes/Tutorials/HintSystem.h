//
//  HintSystem.h
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "Path.h"

typedef enum
{
    HINT_ID_PLACE_CARD,
    HINT_ID_CHARLIE,
    HINT_ID_LEVEL_2,
    HINT_ID_LEVEL_4,
    HINT_ID_LEVEL_5,
    HINT_ID_LEVEL_8,
    HINT_ID_LEVEL_12,
    HINT_ID_UNLOCK_ROOM,
    HINT_ID_LEVEL_SELECT,
    HINT_ID_BUST,
    HINT_ID_ACE,
    HINT_ID_TORNADO,
    HINT_ID_SUDDEN_DEATH,
    HINT_ID_TORNADO_TIME,
    HINT_ID_NUM,
    HINT_ID_INVALID = HINT_ID_NUM
} HintId;

typedef enum
{
    HINTTYPE_ALWAYS,
    HINTTYPE_ONCE_SESSION,
    HINTTYPE_ONCE_LIFETIME
} HintType;

typedef enum
{
    HINTSYSTEM_STATE_IDLE,
    HINTSYSTEM_STATE_DISPLAYING_HINT,
    HINTSYSTEM_STATE_WAITING_FOR_TIMER,
    HINTSYSTEM_STATE_WAITING_FOR_TERMINATE,
} HintSystemState;

@class TextBox;
@class TextureButton;
@class HintMutableNumber;

@interface HintSystem : NSObject<MessageChannelListener, PathCallback>
{
    HintId          mActiveHint;
    CFTimeInterval  mHintStartTime;
    TextBox*        mTipText;
    TextBox*        mTipContentText;
    TextBox*        mTipDescriptionText;
    
    TextureButton*  mBar;
    
    NSMutableDictionary*    mHintDictionary;
    NSArray*                mHintRecords;
    
    NSString*               mHintFilePath;
    
    BOOL                    mAnyHintDisplayed;
    
    HintSystemState mState;
}

+(void)CreateInstance;
+(void)DestroyInstance;
+(HintSystem*)GetInstance;

-(HintSystem*)Init;
-(void)dealloc;

-(void)AnalyzeHintFile;
-(BOOL)ValidateHintFile;

-(void)ProcessMessage:(Message*)inMsg;

-(void)DisplayHint:(HintId)inHintId;
-(void)TerminateHint;
-(BOOL)GetHintDisplayed:(HintId)inHintId;
-(BOOL)SetHintDisplayed:(HintId)inHintId;

-(void)Update:(CFTimeInterval)inTimeStep;

-(void)PathEvent:(PathEvent)inEvent withPath:(Path*)inPath userData:(u32)inData;

-(void)SetState:(HintSystemState)inState;
-(HintSystemState)GetState;

-(void)EvaluateHintUnlockRoom:(HintMutableNumber*)outRetVal;

@end