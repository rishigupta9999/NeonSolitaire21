//
//  PositionLookAtNavigator.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "PositionLookAtNavigator.h"
#import "GameObjectManager.h"
#import "TextureButton.h"

#import "DebugManager.h"

static const char*  sButtonNames[POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS] = { "Pos F", "Pos B", "Pos L", "Pos R", "Pos U", "Pos D",
                                                                            "LA F", "LA B", "LA L", "LA R", "LA U", "LA D", "FOV +", "FOV -" };

static Vector2      sButtonCoords[POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS] = {{ 40.0f, 240.0f },
                                                                            { 40.0f, 270.0f },
                                                                            { 100.0f, 240.0f },
                                                                            { 100.0f, 270.0f },
                                                                            { 160.0f, 240.0f },
                                                                            { 160.0f, 270.0f },
                                                                            { 220.0f, 240.0f },
                                                                            { 220.0f, 270.0f },
                                                                            { 280.0f, 240.0f },
                                                                            { 280.0f, 270.0f },
                                                                            { 340.0f, 240.0f },
                                                                            { 340.0f, 270.0f },
                                                                            { 400.0f, 240.0f },
                                                                            { 400.0f, 270.0f }} ;
                                                                                    
static const float MOVE_AMOUNT = 0.2f;
static const float FOV_MOVE_AMOUNT = 1.0f;

@implementation PositionLookAtNavigator

-(PositionLookAtNavigator*)InitWithParams:(PositionLookAtNavigatorParams*)inParams
{
    TextureButtonParams    params;
    
    // Get the default values set up for the parameters.
    [TextureButton InitDefaultParams:&params];
        
    params.mButtonTexBaseName = NULL;
    params.mButtonTexHighlightedName = NULL;
    params.mFontSize = 14;
    params.mFontColor = 0xFFFFFFFF;
    params.mFontStrokeColor = 0x000000FF;
    params.mFontStrokeSize = 1;
    params.mFontType = NEON_FONT_NORMAL;
    
    for (int i = 0; i < POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS; i++)
    {
        params.mButtonText = [NSString stringWithUTF8String:sButtonNames[i]];
        
        mButtons[i] = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [mButtons[i] SetListener:self];
        
        [[GameObjectManager GetInstance] Add:mButtons[i]];
        
        [mButtons[i] SetPositionX:sButtonCoords[i].mVector[x] Y:sButtonCoords[i].mVector[y] Z:0.0f];
    }
    
    mActiveButtonIndex = POSITION_LOOKAT_NAVIGATOR_INVALID_INDEX;
    
    memcpy(&mParams, inParams, sizeof(PositionLookAtNavigatorParams));

    return self;
}

-(void)dealloc
{
    for (int i = 0; i < POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS; i++)
    {
        [mButtons[i] Remove];
        [[GameObjectManager GetInstance] Remove:mButtons[i]];
    }
    
    [super dealloc];
}

+(void)InitDefaultParams:(PositionLookAtNavigatorParams*)outParams
{
    SetVec2(&outParams->mBaseButtonPosition, 0.0f, 0.0f);
    outParams->mTargetPosition = NULL;
    outParams->mTargetLookAt = NULL;
    outParams->mCallback = NULL;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mActiveButtonIndex)
    {
        case POSITION_LOOKAT_NAVIGATOR_POS_FORWARD:
        {
            mParams.mTargetPosition->mVector[z] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_POS_BACKWARD:
        {
            mParams.mTargetPosition->mVector[z] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_POS_LEFT:
        {
            mParams.mTargetPosition->mVector[x] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_POS_RIGHT:
        {
            mParams.mTargetPosition->mVector[x] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_POS_DOWN:
        {
            mParams.mTargetPosition->mVector[y] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_POS_UP:
        {
            mParams.mTargetPosition->mVector[y] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_LA_FORWARD:
        {
            mParams.mTargetLookAt->mVector[z] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_LA_BACKWARD:
        {
            mParams.mTargetLookAt->mVector[z] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_LA_LEFT:
        {
            mParams.mTargetLookAt->mVector[x] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_LA_RIGHT:
        {
            mParams.mTargetLookAt->mVector[x] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_LA_DOWN:
        {
            mParams.mTargetLookAt->mVector[y] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_LA_UP:
        {
            mParams.mTargetLookAt->mVector[y] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_FOV_PLUS:
        {
            *(mParams.mTargetFovDegrees) += FOV_MOVE_AMOUNT;
            break;
        }
        
        case POSITION_LOOKAT_NAVIGATOR_FOV_MINUS:
        {
            *(mParams.mTargetFovDegrees) -= FOV_MOVE_AMOUNT;
            break;
        }

        case POSITION_LOOKAT_NAVIGATOR_INVALID_INDEX:
        {
            // Don't do anything here.
            break;
        }
    }
    
    // If a callback object was provided, then inform it if there were any changes
    if (mParams.mCallback != NULL)
    {
        if (mActiveButtonIndex != POSITION_LOOKAT_NAVIGATOR_INVALID_INDEX)
        {
            if ((mActiveButtonIndex >= POSITION_LOOKAT_NAVIGATOR_POS_FORWARD) && (mActiveButtonIndex <= POSITION_LOOKAT_NAVIGATOR_POS_DOWN))
            {
                [mParams.mCallback PositionModified:mParams.mTargetPosition];
            }
            else if ((mActiveButtonIndex >= POSITION_LOOKAT_NAVIGATOR_LA_FORWARD) && (mActiveButtonIndex <= POSITION_LOOKAT_NAVIGATOR_LA_DOWN))
            {
                [mParams.mCallback LookAtModified:mParams.mTargetLookAt];
            }
        }
    }
}

-(void)DrawOrtho
{
    [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"Position: %f, %f, %f",
                                                        mParams.mTargetPosition->mVector[x],
                                                        mParams.mTargetPosition->mVector[y],
                                                        mParams.mTargetPosition->mVector[z]]
                                                        locX:10 locY:50];
                                                        
    [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"LookAt: %f, %f, %f",
                                                        mParams.mTargetLookAt->mVector[x],
                                                        mParams.mTargetLookAt->mVector[y],
                                                        mParams.mTargetLookAt->mVector[z]]
                                                        locX:10 locY:70];
    
    [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"FOV: %f degrees",
                                                        *mParams.mTargetFovDegrees]
                                                        locX:10 locY:90];
}

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if ((inEvent == BUTTON_EVENT_DOWN) || (inEvent == BUTTON_EVENT_RESUMED))
    {
        mActiveButtonIndex = [self GetButtonIndex:inButton];
    }
    else if ((inEvent == BUTTON_EVENT_UP) || (inEvent == BUTTON_EVENT_CANCELLED))
    {
        mActiveButtonIndex = POSITION_LOOKAT_NAVIGATOR_INVALID_INDEX;
    }
    
    return TRUE;
}

-(s32)GetButtonIndex:(Button*)inButton
{
    s32 retVal = POSITION_LOOKAT_NAVIGATOR_INVALID_INDEX;
    
    for (int i = 0; i < POSITION_LOOKAT_NAVIGATOR_NUM_BUTTONS; i++)
    {
        if (inButton == mButtons[i])
        {
            retVal = i;
            break;
        }
    }
    
    return retVal;
}

@end