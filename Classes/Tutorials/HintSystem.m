//
//  HintSystem.m
//  Neon21
//
//  Copyright Neon Games 2013. All rights reserved.
//

#import "HintSystem.h"
#import "Event.h"
#import "GameStateMgr.h"
#import "Flow.h"
#import "TextBox.h"
#import "TextureButton.h"
#import "SplitTestingSystem.h"
#import "LevelDefinitions.h"
#import "SaveSystem.h"

typedef enum
{
    HintCondition_Equals,
    HintCondition_GreaterEquals
} HintCondition;

typedef struct
{
    NSString*       mKey;
    
    EventId         mTriggerEvent;
    GameModeType    mTriggerGameMode;
    int             mTriggerLevel;
    
    EventId         mTerminateEvent;
    CFTimeInterval  mMinimumDuration;
    
    HintCondition   mHintCondition;
    HintType        mHintType;
    NSString*       mHintEvaluator;
    
    int             mFontSize;
    u32             mFontColor;
    char*           mString;
} HintInfo;

HintInfo    sHintInfo[HINT_ID_NUM]  = { { @"HINT_ID_PLACE_CARD",    EVENT_RUN21_PLACE_CARD,             GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_4,    EVENT_EMPTY,   3.0f,   HintCondition_Equals,        HINTTYPE_ONCE_LIFETIME,  NULL,                          17,  0xFFFFFFFF, "LS_Tip_MoveCard"   },
                                        { @"HINT_ID_CHARLIE",       EVENT_RUN21_CHARLIE_DISPLAYED,      GAMEMODE_TYPE_INVALID,    0,                EVENT_EMPTY,   3.0f,   HintCondition_Equals,        HINTTYPE_ONCE_LIFETIME,  NULL,                          17,  0xFFFFFFFF, "LS_Tip_Charlie"    },
                                        { @"HINT_ID_LEVEL_2",       EVENT_RUN21_RUNNING_RAINBOW,        GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_2,    EVENT_EMPTY,   4.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,   NULL,                          17,  0xFFFFFFFF, "LS_Tip_LowCards"   },
                                        { @"HINT_ID_LEVEL_4",       EVENT_RUN21_RUNNING_RAINBOW,        GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_4,    EVENT_EMPTY,   5.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,   NULL,                          17,  0xFFFFFFFF, "LS_Tip_3_Runners"  },
                                        { @"HINT_ID_LEVEL_5",       EVENT_RUN21_RUNNING_RAINBOW,        GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_6,    EVENT_EMPTY,   5.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,   NULL,                          15,  0xFFE845FF, "LS_Tip_High_Cards" },
                                        { @"HINT_ID_LEVEL_8",       EVENT_RUN21_RUNNING_RAINBOW,        GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_8,    EVENT_EMPTY,   4.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,   NULL,                          17,  0xFFFFFFFF, "LS_Tip_4_Runners"  },
                                        { @"HINT_ID_LEVEL_12",      EVENT_RUN21_RUNNING_RAINBOW,        GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_12,   EVENT_EMPTY,   6.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,   NULL,                          13,  0xFFE845FF, "LS_Tip_No_Jokers"  },
                                        { @"HINT_ID_UNLOCK_ROOM",   EVENT_MAIN_MENU_ENTER_LEVEL_SELECT, GAMEMODE_TYPE_INVALID,    0,                EVENT_EMPTY,   0.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,  @"EvaluateHintUnlockRoom:",     0,   0x00000000, NULL                },
                                        { @"HINT_ID_LEVEL_SELECT",  EVENT_MAIN_MENU_ENTER_LEVEL_SELECT, GAMEMODE_TYPE_INVALID,    0,                EVENT_EMPTY,   0.0f,   HintCondition_Equals,        HINTTYPE_ONCE_LIFETIME,  NULL,                          0,   0x00000000, NULL                },
                                        { @"HINT_ID_BUST",          EVENT_RUN21_BUST,                   GAMEMODE_TYPE_INVALID,    0,                EVENT_EMPTY,   4.0f,   HintCondition_Equals,        HINTTYPE_ONCE_LIFETIME,  NULL,                          20,  0xFFFFFFFF, "LS_Tip_Bust"       },
                                        { @"HINT_ID_ACE",           EVENT_RUN21_PLACE_CARD,             GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_2,    EVENT_EMPTY,   4.0f,   HintCondition_Equals,        HINTTYPE_ONCE_LIFETIME,  NULL,                          20,  0xFFFFFFFF, "LS_Tip_Ace"        },
                                        { @"HINT_ID_TORNADO",       EVENT_RUN21_PLACE_CARD,             GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_7,    EVENT_EMPTY,   4.0f,   HintCondition_Equals,        HINTTYPE_ONCE_LIFETIME,  NULL,                          20,  0xFFFFFFFF, "LS_Tip_Tornado"    },
                                        { @"HINT_ID_SUDDEN_DEATH",  EVENT_RUN21_SUDDEN_DEATH,           GAMEMODE_TYPE_INVALID,    0,                EVENT_EMPTY,   4.0f,   HintCondition_Equals,        HINTTYPE_ONCE_SESSION,   NULL,                          20,  0xFFE845FF, "LS_Tip_SuddenDeath"},
                                        { @"HINT_ID_TORNADOTIME",   EVENT_RUN21_CRITICAL_TIME,          GAMEMODE_TYPE_RUN21,      RUN21_LEVEL_14,   EVENT_EMPTY,   4.0f,   HintCondition_GreaterEquals, HINTTYPE_ONCE_SESSION,   NULL,                          16,  0xFFE845FF, "LS_Tip_TornadoTime"} };

static HintSystem* sInstance = NULL;

static const float START_X = 10.0f;
static const float START_Y = -100.0f;
static const float END_Y = 30.0f;

static const float BAR_PADDING = 20.0f;

static const float ANIMATION_DURATION = 0.5f;

static const float TIP_CONTENT_SPACING = 6.0f;

static const float HINT_OPACITY = 0.8f;


static const char* APP_VERSION = "App Version";

@interface HintMutableNumber : NSObject
{
}
@property int Value;

-(HintMutableNumber*)init;

@end

@implementation HintMutableNumber

@synthesize Value = mValue;

-(HintMutableNumber*)init
{
    mValue = 0;
    return self;
}

@end

@implementation HintSystem

+(void)CreateInstance
{
    NSAssert(sInstance == NULL, @"Attempting to double-create HintSystem");
    sInstance = [(HintSystem*)[HintSystem alloc] Init];
}

+(void)DestroyInstance
{
    NSAssert(sInstance != NULL, @"Attempting to double-delete HintSystem");
    [sInstance release];
    sInstance = NULL;
}

+(HintSystem*)GetInstance
{
    return sInstance;
}

-(HintSystem*)Init
{
    mActiveHint = HINT_ID_INVALID;
    
    [GetGlobalMessageChannel() AddListener:self];
    [[[GameStateMgr GetInstance] GetMessageChannel] AddListener:self];
    
    GameState* activeState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
    [[activeState GetMessageChannel] AddListener:self];
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    
    SetColorFloat(&tbParams.mColor, 1.0, 0.91, 0.27, 1.0);
    SetColorFloat(&tbParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= NSLocalizedString(@"LS_Tip", NULL);
    tbParams.mFontSize		= 24;
    tbParams.mFontType		= NEON_FONT_STYLISH;
    
    mTipText = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [mTipText SetVisible:FALSE];
    
    mTipContentText = NULL;
    
    tbParams.mFontSize  = 11.5;
    tbParams.mString    = @"<B><color=0xFFE845>These tips will automatically go away. You can keep playing while they're on screen.</color></B>";
    tbParams.mWidth     = GetScreenVirtualWidth() - (START_X * 2.0f);
    tbParams.mFontType  = NEON_FONT_NORMAL;
    
    mTipDescriptionText = [[TextBox alloc] InitWithParams:&tbParams];
    
    [mTipDescriptionText SetVisible:FALSE];

    TextureButtonParams textureButtonParams;
    
    [TextureButton InitDefaultParams:&textureButtonParams];
    SetColorFloat(&textureButtonParams.mColor, 0.0, 0.0, 0.0, HINT_OPACITY);
    
    mBar = [(TextureButton*)[TextureButton alloc] InitWithParams:&textureButtonParams];
    
    [mBar SetVisible:FALSE];
    
    [[GameObjectManager GetInstance] Add:mBar];
    [[GameObjectManager GetInstance] Add:mTipText];
    [[GameObjectManager GetInstance] Add:mTipDescriptionText];
    
    mHintStartTime = 0.0f;
    mAnyHintDisplayed = FALSE;
    
    [self SetState:HINTSYSTEM_STATE_IDLE];
    
    [self AnalyzeHintFile];
    
    return self;
}

-(void)dealloc
{
    [[[GameStateMgr GetInstance] GetMessageChannel] RemoveListener:(NSObject<MessageChannelListener>*)self];
    [GetGlobalMessageChannel() RemoveListener:(NSObject<MessageChannelListener>*)self];
    
    [mBar Remove];
    [mTipText Remove];
    [mTipContentText Remove];
    [mTipDescriptionText Remove];
    
    [mHintFilePath release];

    [super dealloc];
}

-(void)AnalyzeHintFile
{
    static const char* sHintSystemFile = "HintSystem.plist";

    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = [paths objectAtIndex:0];
    mHintFilePath = [[NSString alloc] initWithFormat:@"%@/%s", documentsPath, sHintSystemFile];
 
    if ([[NSFileManager defaultManager] fileExistsAtPath:mHintFilePath])
    {
        mHintDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:mHintFilePath];
        BOOL valid = [self ValidateHintFile];
        
        if (!valid)
        {
            [mHintDictionary writeToFile:mHintFilePath atomically:YES];
        }
        
        for (int i = 0; i < HINT_ID_NUM; i++)
        {
            if (sHintInfo[i].mHintType == HINTTYPE_ONCE_SESSION)
            {
                [mHintDictionary setObject:[NSNumber numberWithInt:0] forKey:sHintInfo[i].mKey];
            }
        }
    }
    else
    {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObject:[[NeonMetrics GetInstance] GetVersion] forKey:[NSString stringWithUTF8String:APP_VERSION]];
        
        for (int i = 0; i < HINT_ID_NUM; i++)
        {
            [dictionary setObject:[NSNumber numberWithInt:0] forKey:sHintInfo[i].mKey];
        }
        
        [dictionary writeToFile:mHintFilePath atomically:YES];
        
        mHintDictionary = [dictionary retain];
    }
}

-(BOOL)ValidateHintFile
{
    BOOL valid = TRUE;

    NSArray* allKeys = [mHintDictionary allKeys];
    
    // First check if we have any keys that aren't current.  If so, remove them
    
    int numKeys = [allKeys count];

    for (int i = 0; i < numKeys; i++)
    {
        NSString* curKey = [allKeys objectAtIndex:i];
        BOOL keyFound = FALSE;
        
        if (strcmp([curKey UTF8String], APP_VERSION) == 0)
        {
            NSString* curVersion = [[NeonMetrics GetInstance] GetVersion];
            
            if ([(NSString*)[mHintDictionary objectForKey:curKey] compare:curVersion] != NSOrderedSame)
            {
                [mHintDictionary setObject:curVersion forKey:curKey];
                valid = FALSE;
            }
            
            continue;
        }

        for (int ref = 0; ref < HINT_ID_NUM; ref++)
        {
            if ([curKey compare:sHintInfo[ref].mKey] == NSOrderedSame)
            {
                keyFound = TRUE;
                break;
            }
        }
        
        if (!keyFound)
        {
            [mHintDictionary removeObjectForKey:curKey];
            valid = FALSE;
        }
    }

    // Now add keys that don't exist
    for (int i = 0; i < HINT_ID_NUM; i++)
    {
        NSString* curKey = sHintInfo[i].mKey;
        
        if ([mHintDictionary objectForKey:curKey] == NULL)
        {
            [mHintDictionary setObject:[NSNumber numberWithInt:0] forKey:curKey];
            valid = FALSE;
        }
    }

    return valid;
}

-(void)ProcessMessage:(Message*)inMsg
{
    switch(inMsg->mId)
    {
        case EVENT_STATE_STARTED:
        {
            GameState* activeState = (GameState*)[[GameStateMgr GetInstance] GetActiveState];
            [[activeState GetMessageChannel] AddListener:self];
            
            break;
        }
    }
    
    int curLevel = [[Flow GetInstance] GetLevel];
    GameModeType curGameMode = [[Flow GetInstance] GetGameMode];

    switch(mState)
    {
        case HINTSYSTEM_STATE_IDLE:
        {
            for (int i = 0; i < HINT_ID_NUM; i++)
            {
                BOOL triggerLevel = (sHintInfo[i].mTriggerLevel == curLevel) || ((sHintInfo[i].mHintCondition == HintCondition_GreaterEquals) && (curLevel >= sHintInfo[i].mTriggerLevel));
                BOOL triggerGameMode = (sHintInfo[i].mTriggerGameMode == GAMEMODE_TYPE_INVALID) || (triggerLevel && (sHintInfo[i].mTriggerGameMode == curGameMode));

                if ((sHintInfo[i].mTriggerEvent == inMsg->mId) && (triggerGameMode) && (![self GetHintDisplayed:i]))
                {
                    BOOL triggerEvaluator = TRUE;
                    
                    if (sHintInfo[i].mHintEvaluator != NULL)
                    {
                        HintMutableNumber* retVal = [[HintMutableNumber alloc] init];
                        [self performSelector:NSSelectorFromString(sHintInfo[i].mHintEvaluator) withObject:retVal];
                        triggerEvaluator = retVal.Value;
                        
                        [retVal release];
                    }

                    if (triggerEvaluator)
                    {
                        if (sHintInfo[i].mString != NULL)
                        {
                            [self DisplayHint:i];
                            mActiveHint = i;
                        }
                        
                        Message msg;
                        
                        msg.mId = EVENT_HINT_TRIGGERED;
                        msg.mData = [NSNumber numberWithInt:i];
                        
                        [[[GameStateMgr GetInstance] GetMessageChannel] BroadcastMessageSync:&msg];
                        
                        [self SetHintDisplayed:i];
                        
                        break;
                    }
                    
                }
            }

            break;
        }
        
        case HINTSYSTEM_STATE_DISPLAYING_HINT:
        {
            if (sHintInfo[mActiveHint].mTerminateEvent == inMsg->mId)
            {
                if ((CACurrentMediaTime() - mHintStartTime) >= sHintInfo[mActiveHint].mMinimumDuration)
                {
                    [self TerminateHint];
                }
                else
                {
                    [self SetState:HINTSYSTEM_STATE_WAITING_FOR_TIMER];
                }
            }

            break;
        }
    }
}

-(void)DisplayHint:(HintId)inHintId
{
    Path* tipPath = [(Path*)[Path alloc] Init];
    Path* tipContentPath = [(Path*)[Path alloc] Init];
    Path* barPath = [(Path*)[Path alloc] Init];
    
    [mTipText SetVisible:TRUE];
    
    int tipWidth = [mTipText GetWidth];
    
    [tipPath AddNodeX:START_X y:START_Y z:0.0f atTime:0.0f];
    [tipPath AddNodeX:START_X y:END_Y z:0.0f atTime:ANIMATION_DURATION];
    
    [tipContentPath AddNodeX:(START_X + tipWidth + TIP_CONTENT_SPACING) y:START_Y z:0.0f atTime:0.0f];
    [tipContentPath AddNodeX:(START_X + tipWidth + TIP_CONTENT_SPACING) y:END_Y z:0.0f atTime:ANIMATION_DURATION];
    
    [barPath AddNodeX:0.0 y:START_Y - BAR_PADDING z:0.0f atTime:0.0f];
    [barPath AddNodeX:0.0 y:END_Y - BAR_PADDING z:0.0f atTime:ANIMATION_DURATION];
    
    TextBoxParams tbParams;
    [TextBox InitDefaultParams:&tbParams];
    
    SetColorFloat(&tbParams.mColor, 1.0, 1.0, 1.0, 1.0);
    SetColorFloat(&tbParams.mStrokeColor, 0.0, 0.0, 0.0, 1.0);
    
    tbParams.mStrokeSize	= 2;
    tbParams.mString		= NSLocalizedString([NSString stringWithUTF8String:sHintInfo[inHintId].mString], NULL);
    tbParams.mFontSize		= sHintInfo[inHintId].mFontSize;
    tbParams.mFontType		= NEON_FONT_NORMAL;
    tbParams.mWidth         = GetScreenVirtualWidth() - (START_X * 2.0f) - tipWidth - START_X - TIP_CONTENT_SPACING;
    SetColorFromU32(&tbParams.mColor, sHintInfo[inHintId].mFontColor);
    
    mTipContentText = [(TextBox*)[TextBox alloc] InitWithParams:&tbParams];
    [mTipContentText SetVisible:TRUE];
    
    [mBar SetVisible:TRUE];
    [mBar SetScaleX:GetScreenVirtualWidth() Y:([mTipContentText GetHeight]) Z:1.0];

    [[GameObjectManager GetInstance] Add:mTipContentText];
    [mTipContentText release];
    
    [mTipText SetPositionX:START_X Y:START_Y Z:0.0f];
    [mTipContentText SetPositionX:(START_X + tipWidth) Y:START_Y Z:0.0f];
    [mBar SetPositionX:0.0f Y:START_Y Z:0.0f];
    
    [mBar SetScaleX:GetScreenVirtualWidth() Y:([mTipContentText GetHeight] + (BAR_PADDING * 2.0f)) Z:1.0];
    
    [mTipText AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:tipPath];
    [mTipContentText AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:tipContentPath];
    [mBar AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:barPath];
    
    if (!mAnyHintDisplayed)
    {
        int tipHeight = [mTipContentText GetHeight];
        
        Path* tipDescriptionPath = [[Path alloc] Init];
        
        [tipDescriptionPath AddNodeX:START_X y:(START_Y + tipHeight) z:0.0f atTime:0.0f];
        [tipDescriptionPath AddNodeX:START_X y:(END_Y + tipHeight) z:0.0f atTime:ANIMATION_DURATION];
        [mTipDescriptionText AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:tipDescriptionPath];
        
        [mTipDescriptionText SetVisible:TRUE];
        [tipDescriptionPath release];
    }
 
    [tipPath release];
    [tipContentPath release];
    [barPath release];
    
    if (sHintInfo[inHintId].mTerminateEvent == EVENT_EMPTY)
    {
        [self SetState:HINTSYSTEM_STATE_WAITING_FOR_TIMER];
    }
    else
    {
        [self SetState:HINTSYSTEM_STATE_DISPLAYING_HINT];
    }
    
    
    mHintStartTime = CACurrentMediaTime();
}

-(void)TerminateHint
{
    int tipWidth = [mTipText GetWidth];

    Path* tipPath = [(Path*)[Path alloc] Init];
    
    [tipPath AddNodeX:START_X y:END_Y z:0.0f atTime:0.0f];
    [tipPath AddNodeX:START_X y:START_Y z:0.0f atTime:ANIMATION_DURATION];
    
    Path* tipContentPath = [(Path*)[Path alloc] Init];
    
    [tipContentPath AddNodeX:(START_X + TIP_CONTENT_SPACING + tipWidth) y:END_Y z:0.0f atTime:0.0f];
    [tipContentPath AddNodeX:(START_X + TIP_CONTENT_SPACING + tipWidth) y:START_Y z:0.0f atTime:ANIMATION_DURATION];
    
    Path* barPath = [(Path*)[Path alloc] Init];
    
    [barPath AddNodeX:0.0f y:(END_Y - BAR_PADDING) z:0.0f atTime:0.0f];
    [barPath AddNodeX:0.0f y:(START_Y - BAR_PADDING) z:0.0f atTime:ANIMATION_DURATION];
    
    if (!mAnyHintDisplayed)
    {
        Path* tipDescriptionPath = [[Path alloc] Init];
        int tipHeight = [mTipContentText GetHeight];
        
        [tipDescriptionPath AddNodeX:START_X y:(END_Y + tipHeight) z:0.0f atTime:0.0f];
        [tipDescriptionPath AddNodeX:START_X y:(START_Y + tipHeight) z:0.0f atTime:ANIMATION_DURATION];
        [mTipDescriptionText AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:tipDescriptionPath];
    
        [tipDescriptionPath release];
        
        mAnyHintDisplayed = TRUE;
    }
    
    [mTipText AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:tipPath];
    [mTipContentText AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:tipContentPath];
    [mBar AnimateProperty:GAMEOBJECT_PROPERTY_POSITION withPath:barPath];
    
    [tipPath release];
    [tipContentPath release];
    [barPath release];
    
    [tipPath SetCallback:self withData:0];
    
    [self SetState:HINTSYSTEM_STATE_WAITING_FOR_TERMINATE];
}

-(BOOL)GetHintDisplayed:(HintId)inHintId
{
    NSString* key = sHintInfo[inHintId].mKey;
    NSNumber* value = [mHintDictionary objectForKey:key];
    NSAssert(value != NULL, @"Hint isn't in hint dictionary.  This should have been added on initailization");
    
    return [value intValue];
}

-(BOOL)SetHintDisplayed:(HintId)inHintId
{
    [mHintDictionary setObject:[NSNumber numberWithInt:1] forKey:sHintInfo[inHintId].mKey];
    [mHintDictionary writeToFile:mHintFilePath atomically:YES];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mState)
    {
        case HINTSYSTEM_STATE_WAITING_FOR_TIMER:
        {
            float waitTime = sHintInfo[mActiveHint].mMinimumDuration;
            
            if (!mAnyHintDisplayed)
            {
                waitTime += 3.0f;
            }
            
            if ((CACurrentMediaTime() - mHintStartTime) >= waitTime)
            {
                [self TerminateHint];
            }
            
            break;
        }
    }
}

-(void)PathEvent:(PathEvent)inEvent withPath:(Path*)inPath userData:(u32)inData
{
    [mTipText SetVisible:FALSE];
    [mTipContentText Remove];
    [mBar SetVisible:FALSE];
    
    mActiveHint = HINT_ID_INVALID;
    [self SetState:HINTSYSTEM_STATE_IDLE];
    
    mTipContentText = NULL;
}

-(void)SetState:(HintSystemState)inState
{
    mState = inState;
}

-(HintSystemState)GetState
{
    return mState;
}

-(void)EvaluateHintUnlockRoom:(HintMutableNumber*)outRetVal
{
    if ([[SaveSystem GetInstance] GetMaxLevel] == RUN21_LEVEL_7)
    {
        if ([[SaveSystem GetInstance] GetMaxRoomUnlocked] < [[[Flow GetInstance] GetLevelDefinitions] GetRoomForLevel:RUN21_LEVEL_7])
        {
            outRetVal.Value = 1;
        }
    }
}

@end