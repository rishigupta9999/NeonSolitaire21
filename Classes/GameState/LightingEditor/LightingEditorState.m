//
//  LightEditorState.m
//  Neon21
//
//  Copyright Neon Games 2009. All rights reserved.
//

#import "LightingEditorState.h"
#import "LightManager.h"

#import "GameObjectManager.h"

#define DEFAULT_LIGHT_BUTTON_ARRAY_CAPACITY     (8)
#define MOVE_LIGHT_INCREMENT_AMOUNT             (0.1)
#define ATTENUATION_INCREMENT_AMOUNT            (0.05)

#define LIGHT_INVALID_INDEX                     (-1)

#define SMALL_BUTTON_TEXT_LENGTH                (4)

@implementation LightingEditorStateMachine

-(LightingEditorStateMachine*)Init
{
    [super Init];
    
    mActiveLightIndex = LIGHT_INVALID_INDEX;
    mVisible = TRUE;
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(void)SetActiveLight:(int)inLightIndex
{
    mActiveLightIndex = inLightIndex;
}

-(int)GetActiveLight
{
    return mActiveLightIndex;
}

-(void)SetVisible:(int)inVisible
{
    mVisible = inVisible;
}

-(int)GetVisible
{
    return mVisible;
}

@end

@implementation LightingEditorRootState

-(void)Startup
{
    mLightButtons = [[NSMutableArray alloc] initWithCapacity:DEFAULT_LIGHT_BUTTON_ARRAY_CAPACITY];
    
    int numLights = [[LightManager GetInstance] GetNumLights];
        
    for (int i = 0; i < numLights; i++)
    {
        Light* curLight = [[LightManager GetInstance] GetLight:i];
        
        TextureButtonParams buttonParams;
        
        [TextureButton InitDefaultParams:&buttonParams];
        
        buttonParams.mButtonTexBaseName = @"editorbutton_large.png";
        buttonParams.mButtonTexHighlightedName = @"editorbutton_large_lit.png";
        buttonParams.mFontSize = 18;
        buttonParams.mFontColor = 0xFF000000;
        buttonParams.mButtonText = [NSString stringWithFormat:@"Light %d", curLight->mGLIdentifier - GL_LIGHT0];
        
        Button* curButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&buttonParams];
        [[GameObjectManager GetInstance] Add:curButton];
        
        [curButton SetPositionX:10.0 Y:(50.0 + (20.0 * i)) Z:0.0];
        [curButton SetListener:self];
        
        curButton->mIdentifier = i;
        
        [mLightButtons addObject:curButton];
        [curButton release];
    }
}

-(void)Resume
{
    for (Button* curButton in mLightButtons)
    {
        [curButton SetVisible:TRUE];
        [curButton Enable];
    }
}

-(void)Shutdown
{
    for (Button* curButton in mLightButtons)
    {
        [curButton Remove];
        [[GameObjectManager GetInstance] Remove:curButton];
    }
    
    [mLightButtons removeAllObjects];
    [mLightButtons release];
}

-(void)Suspend
{
    for (Button* curButton in mLightButtons)
    {
        [curButton SetVisible:FALSE];
        [curButton Disable];
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        [(LightingEditorStateMachine*)mStateMachine SetActiveLight:inButton->mIdentifier];

        [mStateMachine Push:[LightingEditorEditState alloc]];
    }
}

@end

@implementation LightingEditorEditState

#define BUTTON_PLUS_X           '+X__'
#define BUTTON_MINUS_X          '-X__'
#define BUTTON_PLUS_Y           '+Y__'
#define BUTTON_MINUS_Y          '-Y__'
#define BUTTON_PLUS_Z           '+Z__'
#define BUTTON_MINUS_Z          '-Z__'
#define BUTTON_LIGHT_SWITCH     'SWCH'
#define BUTTON_CA_PLUS          'CA+_'
#define BUTTON_CA_MINUS         'CA-_'
#define BUTTON_LA_PLUS          'LA+_'
#define BUTTON_LA_MINUS         'LA-_'
#define BUTTON_QA_PLUS          'QA+_'
#define BUTTON_QA_MINUS         'QA-_'
#define BUTTON_BACK             'BACK'
#define BUTTON_INVALID          '----'

#define NUM_LIGHTING_EDITOR_BUTTONS (14)

typedef struct
{
    float   mX;
    float   mY;
    char*   mText;
    u32     mButtonIdentifier;
} ButtonInitParams;

static ButtonInitParams   sEditButtonParams[NUM_LIGHTING_EDITOR_BUTTONS] = {    { 300, 220, "+X",   BUTTON_PLUS_X },
                                                                                { 300, 250, "-X",   BUTTON_MINUS_X },
                                                                                { 350, 220, "+Y",   BUTTON_PLUS_Y },
                                                                                { 350, 250, "-Y",   BUTTON_MINUS_Y },
                                                                                { 400, 220, "+Z",   BUTTON_PLUS_Z },
                                                                                { 400, 250, "-Z",   BUTTON_MINUS_Z },
                                                                                { 400, 300, "Back", BUTTON_BACK },
                                                                                { 300, 190, "Switch", BUTTON_LIGHT_SWITCH },
                                                                                { 300, 130, "CA+",  BUTTON_CA_PLUS },
                                                                                { 300, 160, "CA-",  BUTTON_CA_MINUS },
                                                                                { 350, 130, "LA+",  BUTTON_LA_PLUS },
                                                                                { 350, 160, "LA-",  BUTTON_LA_MINUS },
                                                                                { 400, 130, "QA+",  BUTTON_QA_PLUS },
                                                                                { 400, 160, "QA-",  BUTTON_QA_MINUS }   };

-(void)Startup
{
    mButtons = [[NSMutableArray alloc] initWithCapacity:NUM_LIGHTING_EDITOR_BUTTONS];
    
    mActiveButtonIdentifier = BUTTON_INVALID;
    
    for (int i = 0; i < NUM_LIGHTING_EDITOR_BUTTONS; i++)
    {
        TextureButtonParams params;
        
        [TextureButton InitDefaultParams:&params];
        
        params.mButtonText = [NSString stringWithUTF8String:sEditButtonParams[i].mText];
        
        if ([params.mButtonText length] <= SMALL_BUTTON_TEXT_LENGTH)
        {
            params.mButtonTexBaseName = @"editorbutton.png";
            params.mButtonTexHighlightedName = @"editorbutton_lit.png";
        }
        else
        {
            params.mButtonTexBaseName = @"editorbutton_mid.png";
            params.mButtonTexHighlightedName = @"editorbutton_mid_lit.png";
        }

        params.mFontColor = 0xFF000000;
        
        Button* curButton = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        
        [curButton SetPositionX:sEditButtonParams[i].mX Y:sEditButtonParams[i].mY Z:0.0];
        [[GameObjectManager GetInstance] Add:curButton];
        
        curButton->mIdentifier = sEditButtonParams[i].mButtonIdentifier;
        
        [mButtons addObject:curButton];
        [curButton release];
        
        [curButton SetListener:self];
    }
    
    [[TouchSystem GetInstance] AddListener:self];
}

-(void)Shutdown
{
    for (Button* curButton in mButtons)
    {
        [curButton Remove];
        [[GameObjectManager GetInstance] Remove:curButton];
    }
    
    [mButtons removeAllObjects];
    
    [[TouchSystem GetInstance] RemoveListener:self];
    
    [(LightingEditorStateMachine*)mStateMachine SetActiveLight:LIGHT_INVALID_INDEX];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    if (mActiveButtonIdentifier != BUTTON_INVALID)
    {
        Light* curLight = [[LightManager GetInstance] GetLight:[(LightingEditorStateMachine*)mStateMachine GetActiveLight]];
        LightParams* lightParams = [curLight GetParams];
        
        switch(mActiveButtonIdentifier)
        {
            case BUTTON_PLUS_X:
            {
                lightParams->mVector.mVector[x] += MOVE_LIGHT_INCREMENT_AMOUNT;
                break;
            }
            
            case BUTTON_MINUS_X:
            {
                lightParams->mVector.mVector[x] -= MOVE_LIGHT_INCREMENT_AMOUNT;
                break;
            }
            
            case BUTTON_PLUS_Y:
            {
                lightParams->mVector.mVector[y] += MOVE_LIGHT_INCREMENT_AMOUNT;
                break;
            }
            
            case BUTTON_MINUS_Y:
            {
                lightParams->mVector.mVector[y] -= MOVE_LIGHT_INCREMENT_AMOUNT;
                break;
            }
            
            case BUTTON_PLUS_Z:
            {
                lightParams->mVector.mVector[z] += MOVE_LIGHT_INCREMENT_AMOUNT;
                break;
            }
            
            case BUTTON_MINUS_Z:
            {
                lightParams->mVector.mVector[z] -= MOVE_LIGHT_INCREMENT_AMOUNT;
                break;
            }
        }
    }
}

-(void)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if (inEvent == BUTTON_EVENT_UP)
    {
        int activeLightIndex = [(LightingEditorStateMachine*)mStateMachine GetActiveLight];
        Light* activeLight = [[LightManager GetInstance] GetLight:activeLightIndex];

        LightParams* lightParams = [activeLight GetParams];

        switch(inButton->mIdentifier)
        {
            case BUTTON_PLUS_X:
            case BUTTON_MINUS_X:
            case BUTTON_PLUS_Y:
            case BUTTON_MINUS_Y:
            case BUTTON_PLUS_Z:
            case BUTTON_MINUS_Z:
            {
                mActiveButtonIdentifier = BUTTON_INVALID;
                break;
            }
            
            case BUTTON_LIGHT_SWITCH:
            {
                [activeLight SetLightActive:![activeLight GetLightActive]];
                break;
            }
            
            case BUTTON_CA_PLUS:
            {
                lightParams->mConstantAttenuation = FloorToMultipleFloat(   lightParams->mConstantAttenuation + ATTENUATION_INCREMENT_AMOUNT,
                                                                            ATTENUATION_INCREMENT_AMOUNT);
                break;
            }
            
            case BUTTON_CA_MINUS:
            {
                lightParams->mConstantAttenuation = LClampFloat(lightParams->mConstantAttenuation - ATTENUATION_INCREMENT_AMOUNT, 0.0);
                break;
            }
            
            case BUTTON_LA_PLUS:
            {
                lightParams->mLinearAttenuation = FloorToMultipleFloat(   lightParams->mLinearAttenuation + ATTENUATION_INCREMENT_AMOUNT,
                                                                            ATTENUATION_INCREMENT_AMOUNT);
                break;
            }
            
            case BUTTON_LA_MINUS:
            {
                lightParams->mLinearAttenuation = LClampFloat(lightParams->mLinearAttenuation - ATTENUATION_INCREMENT_AMOUNT, 0.0);
                break;
            }

            case BUTTON_QA_PLUS:
            {
                lightParams->mQuadraticAttenuation = FloorToMultipleFloat(   lightParams->mQuadraticAttenuation + ATTENUATION_INCREMENT_AMOUNT,
                                                                            ATTENUATION_INCREMENT_AMOUNT);
                break;
            }
            
            case BUTTON_QA_MINUS:
            {
                lightParams->mQuadraticAttenuation = LClampFloat(lightParams->mQuadraticAttenuation - ATTENUATION_INCREMENT_AMOUNT, 0.0);
                break;
            }

            case BUTTON_BACK:
            {
                [mStateMachine Pop];
                break;
            }
        }
    }
    else if (inEvent == BUTTON_EVENT_DOWN)
    {
        switch(inButton->mIdentifier)
        {
            case BUTTON_PLUS_X:
            case BUTTON_MINUS_X:
            case BUTTON_PLUS_Y:
            case BUTTON_MINUS_Y:
            case BUTTON_PLUS_Z:
            case BUTTON_MINUS_Z:
            {
                mActiveButtonIdentifier = inButton->mIdentifier;
                break;
            }
        }
    }
}

-(TouchSystemConsumeType)TouchEventWithData:(TouchData*)inData
{
    switch(inData->mTouchType)
    {
        case TOUCHES_BEGAN:
        {
            if ((inData->mTouchLocation.x < 300) || (inData->mTouchLocation.y > 400))
            {
                for (Button* curButton in mButtons)
                {
                    [curButton SetVisible:FALSE];
                }
                
                [(LightingEditorStateMachine*)mStateMachine SetVisible:FALSE];
            }
            
            break;
        }
        
        case TOUCHES_ENDED:
        {
            for (Button* curButton in mButtons)
            {
                [curButton SetVisible:TRUE];
            }
            
            [(LightingEditorStateMachine*)mStateMachine SetVisible:TRUE];
            break;
        }
    }
    
    return TOUCHSYSTEM_CONSUME_NONE;
}

@end

@implementation LightingEditorState

-(void)Startup
{
    mLightingEditorStateMachine = (LightingEditorStateMachine*)[(LightingEditorStateMachine*)[LightingEditorStateMachine alloc] Init];
    
    [mLightingEditorStateMachine Push:[LightingEditorRootState alloc]];
}

-(void)Shutdown
{
    [mLightingEditorStateMachine release];
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    [mLightingEditorStateMachine Update:inTimeStep];
}

-(void)DrawOrtho
{
    if ([mLightingEditorStateMachine GetVisible])
    {
        if ([mLightingEditorStateMachine GetActiveLight] != LIGHT_INVALID_INDEX)
        {
            int lightIndex  = [mLightingEditorStateMachine GetActiveLight];
            Light* curLight = [[LightManager GetInstance] GetLight:lightIndex];
            LightParams* lightParams = [curLight GetParams];
            
            [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"Position: %0.3f, %0.3f, %0.3f",
                                                    lightParams->mVector.mVector[x], lightParams->mVector.mVector[y], lightParams->mVector.mVector[z]]
                                                    locX:10 locY:50];

            [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"CA: %0.3f LA: %0.3f QA: %0.3f",
                                                    lightParams->mConstantAttenuation, lightParams->mLinearAttenuation, lightParams->mQuadraticAttenuation]
                                                    locX:10 locY:80];

        }
    }
}

@end