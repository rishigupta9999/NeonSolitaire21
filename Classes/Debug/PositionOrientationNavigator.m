//
//  PositionOrientationNavigator.m
//  Neon21
//
//  Copyright Neon Games 2010. All rights reserved.
//

#import "PositionOrientationNavigator.h"
#import "GameObjectManager.h"
#import "TextureButton.h"

#import "DebugManager.h"

static const char*  sButtonNames[POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS] = { "Pos F", "Pos B", "Pos L", "Pos R", "Pos U", "Pos D",
                                                                                 "Ori +X", "Ori -X", "Ori +Y", "Ori -Y", "Ori +Z", "Ori -Z" };

static Vector2      sButtonCoords[POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS] = {{ 40.0f, 240.0f },
                                                                            { 40.0f, 270.0f },
                                                                            { 110.0f, 240.0f },
                                                                            { 110.0f, 270.0f },
                                                                            { 180.0f, 240.0f },
                                                                            { 180.0f, 270.0f },
                                                                            { 250.0f, 240.0f },
                                                                            { 250.0f, 270.0f },
                                                                            { 320.0f, 240.0f },
                                                                            { 320.0f, 270.0f },
                                                                            { 390.0f, 240.0f },
                                                                            { 390.0f, 270.0f }, } ;
                                                                                    
static const float  MOVE_AMOUNT = 0.2f;

@implementation PositionOrientationNavigator

-(PositionOrientationNavigator*)InitWithParams:(PositionOrientationNavigatorParams*)inParams
{
    NSAssert(FALSE, @"PositionOrientationNavigator is untested.  Please do a sanity check before relying on its functionality");
    
    TextureButtonParams    params;
    
    // Get the default values set up for the parameters.
    [TextureButton InitDefaultParams:&params];
        
    params.mButtonTexBaseName = @"editorbutton.png";
    params.mButtonTexHighlightedName = @"editorbutton_lit.png";
    params.mFontSize = 18;
    params.mFontColor = 0xFF000000;
    
    for (int i = 0; i < POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS; i++)
    {
        params.mButtonText = [NSString stringWithUTF8String:sButtonNames[i]];
        
        mButtons[i] = [(TextureButton*)[TextureButton alloc] InitWithParams:&params];
        [mButtons[i] SetListener:self];
        
        [[GameObjectManager GetInstance] Add:mButtons[i]];
        
        [mButtons[i] SetPositionX:sButtonCoords[i].mVector[x] Y:sButtonCoords[i].mVector[y] Z:0.0f];
    }
    
    mActiveButtonIndex = POSITION_ORIENTATION_NAVIGATOR_INVALID_INDEX;
    
    memcpy(&mParams, inParams, sizeof(PositionOrientationNavigatorParams));

    return self;
}

-(void)dealloc
{
    for (int i = 0; i < POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS; i++)
    {
        [mButtons[i] Remove];
        [[GameObjectManager GetInstance] Remove:mButtons[i]];
    }
    
    [super dealloc];
}

+(void)InitDefaultParams:(PositionOrientationNavigatorParams*)outParams
{
    SetVec2(&outParams->mBaseButtonPosition, 0.0f, 0.0f);
    outParams->mTargetPosition = NULL;
    outParams->mTargetOrientation = NULL;
    outParams->mCallback = NULL;
}

-(void)Update:(CFTimeInterval)inTimeStep
{
    switch(mActiveButtonIndex)
    {
        case POSITION_ORIENTATION_NAVIGATOR_POS_FORWARD:
        {
            mParams.mTargetPosition->mVector[z] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_POS_BACKWARD:
        {
            mParams.mTargetPosition->mVector[z] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_POS_LEFT:
        {
            mParams.mTargetPosition->mVector[x] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_POS_RIGHT:
        {
            mParams.mTargetPosition->mVector[x] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_POS_DOWN:
        {
            mParams.mTargetOrientation->mVector[y] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_POS_UP:
        {
            mParams.mTargetOrientation->mVector[y] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_X:
        {
            mParams.mTargetOrientation->mVector[x] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_X:
        {
            mParams.mTargetOrientation->mVector[x] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_Y:
        {
            mParams.mTargetOrientation->mVector[y] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_Y:
        {
            mParams.mTargetOrientation->mVector[y] += MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_Z:
        {
            mParams.mTargetOrientation->mVector[z] -= MOVE_AMOUNT;
            break;
        }
        
        case POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_Z:
        {
            mParams.mTargetOrientation->mVector[z] += MOVE_AMOUNT;
            break;
        }

        case POSITION_ORIENTATION_NAVIGATOR_INVALID_INDEX:
        {
            // Don't do anything here.
            break;
        }
    }
    
    // If a callback object was provided, then inform it if there were any changes
    if (mParams.mCallback != NULL)
    {
        if (mActiveButtonIndex != POSITION_ORIENTATION_NAVIGATOR_INVALID_INDEX)
        {
            if ((mActiveButtonIndex >= POSITION_ORIENTATION_NAVIGATOR_POS_FORWARD) && (mActiveButtonIndex <= POSITION_ORIENTATION_NAVIGATOR_POS_DOWN))
            {
                [mParams.mCallback PositionModified:mParams.mTargetPosition];
            }
            else if ((mActiveButtonIndex >= POSITION_ORIENTATION_NAVIGATOR_ORI_PLUS_X) && (mActiveButtonIndex <= POSITION_ORIENTATION_NAVIGATOR_ORI_MINUS_Z))
            {
                [mParams.mCallback OrientationModified:mParams.mTargetOrientation];
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
                                                        
    [[DebugManager GetInstance] DrawString:[NSString    stringWithFormat:@"Orientation: %f, %f, %f",
                                                        mParams.mTargetOrientation->mVector[x],
                                                        mParams.mTargetOrientation->mVector[y],
                                                        mParams.mTargetOrientation->mVector[z]]
                                                        locX:10 locY:70];
}

-(BOOL)ButtonEvent:(ButtonEvent)inEvent Button:(Button*)inButton
{
    if ((inEvent == BUTTON_EVENT_DOWN) || (inEvent == BUTTON_EVENT_RESUMED))
    {
        mActiveButtonIndex = [self GetButtonIndex:inButton];
    }
    else if ((inEvent == BUTTON_EVENT_UP) || (inEvent == BUTTON_EVENT_CANCELLED))
    {
        mActiveButtonIndex = POSITION_ORIENTATION_NAVIGATOR_INVALID_INDEX;
    }
    
    return TRUE;
}

-(s32)GetButtonIndex:(Button*)inButton
{
    s32 retVal = POSITION_ORIENTATION_NAVIGATOR_INVALID_INDEX;
    
    for (int i = 0; i < POSITION_ORIENTATION_NAVIGATOR_NUM_BUTTONS; i++)
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